import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ordering_food_system/core/config/restaurant_config.dart';
import 'package:ordering_food_system/core/errors/failures.dart';
import 'package:ordering_food_system/core/firebase/firebase_providers.dart';
import 'package:ordering_food_system/core/firebase/firestore_paths.dart';
import 'package:ordering_food_system/features/address/data/models/address_model.dart';
import 'package:ordering_food_system/features/cart/data/repositories/cart_repository.dart';
import 'package:ordering_food_system/features/cart/data/models/cart_item_model.dart';
import 'package:ordering_food_system/features/checkout/data/models/order_model.dart';

/// Abstract repository interface for checkout and order creation
abstract class CheckoutRepository {
  /// Places an order atomically, validates address/distance/fee, creates OrderModel and clears cart (FR-014, FR-015, FR-016, SC-005)
  Future<OrderModel> placeOrder({
    required String customerId,
    required AddressModel deliveryAddress,
    required List<CartItemModel> cartItems,
    required String idempotencyKey,
    String customerNote = '',
  });

  /// Retrieve order by ID
  Future<OrderModel?> getOrderById(String orderId);

  /// Retrieve all orders placed by the customer
  Future<List<OrderModel>> getCustomerOrders(String customerId);

  /// Watch all customer orders so Admin status changes appear immediately.
  Stream<List<OrderModel>> watchCustomerOrders(String customerId);

  /// Watch one customer-owned order by document ID or public order code.
  Stream<OrderModel?> watchCustomerOrder(String customerId, String orderId);
}

/// Implementation of CheckoutRepository with atomic verification and idempotency guard
class CheckoutRepositoryImpl implements CheckoutRepository {
  final CartRepository cartRepository;
  final FirebaseFirestore? firestore;

  // In-memory backing store for demo/offline and fast validation
  final Map<String, OrderModel> _orders = {};
  final Set<String> _processedIdempotencyKeys = {};
  final Map<String, OrderModel> _idempotentOrderCache = {};

  CheckoutRepositoryImpl({required this.cartRepository, this.firestore});

  @override
  Future<OrderModel> placeOrder({
    required String customerId,
    required AddressModel deliveryAddress,
    required List<CartItemModel> cartItems,
    required String idempotencyKey,
    String customerNote = '',
  }) async {
    // 1. Authenticated customer check (BR-008)
    if (customerId.trim().isEmpty) {
      throw const AuthFailure('Bạn cần đăng nhập để tiến hành đặt hàng.');
    }

    // 2. SC-005 & NFR-003: Idempotency protection against duplicate taps
    if (_processedIdempotencyKeys.contains(idempotencyKey)) {
      final existingOrder = _idempotentOrderCache[idempotencyKey];
      if (existingOrder != null) {
        return existingOrder;
      }
      throw const CheckoutFailure(
        'Yêu cầu đặt hàng đang được xử lý, vui lòng không nhấn liên tục.',
      );
    }
    _processedIdempotencyKeys.add(idempotencyKey);

    try {
      // 3. Cart items validation (FR-013, BR-012)
      if (cartItems.isEmpty) {
        throw const CheckoutFailure(
          'Giỏ hàng của bạn đang trống, không thể đặt hàng.',
        );
      }

      for (final item in cartItems) {
        if (!item.isAvailable) {
          throw CheckoutFailure(
            'Món "${item.name}" hiện đang tạm hết hàng. Vui lòng cập nhật giỏ hàng.',
          );
        }
        if (item.quantity <= 0) {
          throw CheckoutFailure(
            'Số lượng của món "${item.name}" không hợp lệ.',
          );
        }
      }

      // 4. Address & Recipient Phone Validation (FR-014)
      if (deliveryAddress.recipientName.trim().isEmpty) {
        throw const CheckoutFailure('Vui lòng cung cấp tên người nhận hàng.');
      }
      if (deliveryAddress.phoneNumber.trim().isEmpty ||
          !AddressModel.isValidPhone(deliveryAddress.phoneNumber)) {
        throw const CheckoutFailure(
          'Số điện thoại người nhận không hợp lệ (cần đúng 10 số đầu 03, 05, 07, 08, 09).',
        );
      }
      if (deliveryAddress.streetAddress.trim().isEmpty) {
        throw const CheckoutFailure(
          'Vui lòng cung cấp địa chỉ giao hàng chi tiết.',
        );
      }

      // 5. Distance and Serviceability Gate (FR-046, FR-048, BR-015)
      final lat = deliveryAddress.latitude;
      final lng = deliveryAddress.longitude;
      if (lat == null || lng == null) {
        throw const CheckoutFailure(
          'Không thể xác định tọa độ địa chỉ giao hàng để tính khoảng cách. Vui lòng chỉnh sửa lại địa chỉ.',
        );
      }

      // Prefer the driving-route distance resolved while the Customer confirms
      // the map pin; older addresses fall back to the Haversine calculation.
      final distanceKm =
          deliveryAddress.routeDistanceKm ??
          RestaurantConfig.calculateDistanceToRestaurant(lat, lng);
      if (distanceKm > RestaurantConfig.maxDeliveryDistanceKm) {
        throw CheckoutFailure(
          'Khoảng cách giao hàng là ${distanceKm.toStringAsFixed(1)}km, vượt quá bán kính phục vụ 8km của nhà hàng. Vui lòng chọn địa chỉ khác.',
        );
      }

      // 6. Authoritative Delivery Fee & Total Calculation (FR-047, FR-049, BR-005, BR-014)
      final deliveryFee = RestaurantConfig.calculateDeliveryFee(distanceKm);
      if (deliveryFee == null) {
        throw const CheckoutFailure(
          'Không thể tính phí giao hàng cho khoảng cách này.',
        );
      }

      final calculatedSubtotal = cartItems.fold(
        0.0,
        (runningTotal, item) => runningTotal + item.subtotal,
      );
      final calculatedTotal = calculatedSubtotal + deliveryFee;

      // 7. Structured Order Code Generation (FR-050)
      final orderCode = OrderModel.generateOrderCode();
      final orderId = 'order_${DateTime.now().millisecondsSinceEpoch}';

      // 8. Create Immutable Order Snapshot (FR-016, BR-004)
      final order = OrderModel(
        id: orderId,
        orderCode: orderCode,
        customerId: customerId,
        items: cartItems.map((e) => OrderItemSnapshot.fromCartItem(e)).toList(),
        addressSnapshot: OrderAddressSnapshot.fromAddressModel(deliveryAddress),
        deliveryDistanceKm: distanceKm,
        deliveryFee: deliveryFee,
        subtotal: calculatedSubtotal,
        total: calculatedTotal,
        paymentMethod: 'COD', // Cash on Delivery only (FR-015)
        status: OrderStatus.pending, // Initial Pending status (BR-001)
        createdAt: DateTime.now(),
      );

      // 9. Persist Order
      await _persistOrderToFirestore(order, customerNote.trim());
      _orders[orderId] = order;
      _idempotentOrderCache[idempotencyKey] = order;

      // 10. Remove only purchased items from Customer Cart (FR-016)
      final orderedIds = cartItems.map((e) => e.id).toSet();
      final currentCart = cartRepository.getCachedCart(customerId);
      final remainingCart = currentCart
          .where((e) => !orderedIds.contains(e.id))
          .toList();
      await cartRepository.saveCart(customerId, remainingCart);

      return order;
    } catch (e) {
      // On failure, remove key so user can retry
      _processedIdempotencyKeys.remove(idempotencyKey);
      if (e is Failure) rethrow;
      if (e is FirebaseException &&
          e.plugin == 'cloud_firestore' &&
          e.code == 'permission-denied') {
        throw const CheckoutFailure(
          'Không có quyền tạo đơn hàng. Vui lòng đăng nhập lại và thử lại.',
        );
      }
      throw CheckoutFailure('Đặt hàng thất bại: ${e.toString()}');
    }
  }

  Future<void> _persistOrderToFirestore(
    OrderModel order,
    String customerNote,
  ) async {
    final database = firestore;
    if (database == null) return;

    final orderRef = database.collection(FirestorePaths.orders).doc(order.id);
    final batch = database.batch();
    batch.set(orderRef, {
      'orderCode': order.orderCode,
      'customerId': order.customerId,
      'customerName': order.addressSnapshot.recipientName,
      'customerPhone': order.addressSnapshot.phoneNumber,
      'deliveryAddress': order.addressSnapshot.fullAddress,
      'addressSnapshot': order.addressSnapshot.toMap(),
      'totalAmount': order.total.round(),
      'subtotal': order.subtotal.round(),
      'deliveryFee': order.deliveryFee.round(),
      'deliveryDistanceKm': order.deliveryDistanceKm,
      'paymentMethod': 'cod',
      'paymentStatus': 'unpaid',
      'orderStatus': 'Pending',
      'customerNote': customerNote,
      'cancellationReason': '',
      'rejectionReason': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    for (var index = 0; index < order.items.length; index++) {
      final item = order.items[index];
      final itemRef = orderRef.collection('items').doc('item_$index');
      batch.set(itemRef, {
        'menuItemId': item.menuItemId,
        'name': item.name,
        'imageUrl': item.imageUrl,
        'basePrice': item.basePrice.round(),
        'selectedSize': item.selectedSize.name,
        'selectedToppings': item.selectedToppings
            .map((topping) => topping.name)
            .toList(growable: false),
        'quantity': item.quantity,
        'unitPrice': item.unitPrice.round(),
        'lineTotal': item.subtotal.round(),
        'note': item.note ?? '',
        'reviewed': false,
      });
    }
    await batch.commit();
  }

  Future<OrderModel> _fromFirestoreDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final data = document.data() ?? const <String, dynamic>{};
    final itemSnapshot = await document.reference.collection('items').get();
    final items = itemSnapshot.docs
        .map((itemDocument) {
          final item = itemDocument.data();
          final sizeName = item['selectedSize']?.toString() ?? '';
          final toppings =
              (item['selectedToppings'] as List<dynamic>? ?? const [])
                  .map(
                    (topping) => CartOptionItem(
                      id: topping.toString(),
                      name: topping.toString(),
                    ),
                  )
                  .toList(growable: false);
          final unitPrice = (item['unitPrice'] as num?)?.toDouble() ?? 0;
          final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
          return OrderItemSnapshot(
            menuItemId: item['menuItemId']?.toString() ?? '',
            name: item['name']?.toString() ?? 'Món ăn',
            imageUrl: item['imageUrl']?.toString() ?? '',
            basePrice: (item['basePrice'] as num?)?.toDouble() ?? unitPrice,
            selectedSize: CartOptionItem(id: sizeName, name: sizeName),
            selectedToppings: toppings,
            note: item['note']?.toString(),
            unitPrice: unitPrice,
            quantity: quantity,
            subtotal:
                (item['lineTotal'] as num?)?.toDouble() ??
                (unitPrice * quantity),
          );
        })
        .toList(growable: false);

    final addressData = data['addressSnapshot'];
    final createdAt = data['createdAt'];
    final updatedAt = data['updatedAt'];
    return OrderModel(
      id: document.id,
      orderCode: data['orderCode']?.toString() ?? document.id,
      customerId: data['customerId']?.toString() ?? '',
      items: items,
      addressSnapshot: OrderAddressSnapshot.fromMap(
        addressData is Map<String, dynamic>
            ? addressData
            : <String, dynamic>{
                'fullAddress': data['deliveryAddress']?.toString() ?? '',
              },
      ),
      deliveryDistanceKm: (data['deliveryDistanceKm'] as num?)?.toDouble() ?? 0,
      deliveryFee: (data['deliveryFee'] as num?)?.toDouble() ?? 0,
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0,
      total: (data['totalAmount'] as num?)?.toDouble() ?? 0,
      paymentMethod: data['paymentMethod']?.toString().toUpperCase() ?? 'COD',
      status: OrderStatusExtension.fromDbString(
        data['orderStatus']?.toString(),
      ),
      cancellationReason: data['cancellationReason']?.toString(),
      rejectionReason: data['rejectionReason']?.toString(),
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : null,
    );
  }

  @override
  Future<OrderModel?> getOrderById(String orderId) async {
    final database = firestore;
    if (database == null) return _orders[orderId];

    final direct = await database
        .collection(FirestorePaths.orders)
        .doc(orderId)
        .get();
    if (direct.exists) return _fromFirestoreDocument(direct);

    final byCode = await database
        .collection(FirestorePaths.orders)
        .where('orderCode', isEqualTo: orderId)
        .limit(1)
        .get();
    if (byCode.docs.isEmpty) return null;
    return _fromFirestoreDocument(byCode.docs.first);
  }

  @override
  Future<List<OrderModel>> getCustomerOrders(String customerId) async {
    final database = firestore;
    if (database != null) {
      final snapshot = await database
          .collection(FirestorePaths.orders)
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();
      final orders = await Future.wait(
        snapshot.docs.map(_fromFirestoreDocument),
      );
      for (final order in orders) {
        _orders[order.id] = order;
      }
      return List.unmodifiable(orders);
    }

    final list =
        _orders.values.where((order) => order.customerId == customerId).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(list);
  }

  @override
  Stream<List<OrderModel>> watchCustomerOrders(String customerId) {
    final database = firestore;
    if (database == null) {
      final orders =
          _orders.values
              .where((order) => order.customerId == customerId)
              .toList(growable: false)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Stream.value(List<OrderModel>.unmodifiable(orders));
    }

    return database
        .collection(FirestorePaths.orders)
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final orders = await Future.wait(
            snapshot.docs.map(_fromFirestoreDocument),
          );
          for (final order in orders) {
            _orders[order.id] = order;
          }
          return List<OrderModel>.unmodifiable(orders);
        });
  }

  @override
  Stream<OrderModel?> watchCustomerOrder(String customerId, String orderId) {
    return watchCustomerOrders(customerId).map(
      (orders) => orders
          .where((order) => order.id == orderId || order.orderCode == orderId)
          .firstOrNull,
    );
  }
}

/// Provider for CheckoutRepository
final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  final cartRepo = ref.watch(cartRepositoryProvider);
  final firestore = Firebase.apps.isEmpty
      ? null
      : ref.watch(firebaseFirestoreProvider);
  return CheckoutRepositoryImpl(cartRepository: cartRepo, firestore: firestore);
});
