import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ordering_food_system/core/config/restaurant_config.dart';
import 'package:ordering_food_system/core/errors/failures.dart';
import 'package:ordering_food_system/core/firebase/firebase_providers.dart';
import 'package:ordering_food_system/core/firebase/firestore_paths.dart';
import 'package:ordering_food_system/features/address/data/models/address_model.dart';
import 'package:ordering_food_system/features/cart/data/cart_repository.dart';
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

      final distanceKm = RestaurantConfig.calculateDistanceToRestaurant(
        lat,
        lng,
      );
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

  @override
  Future<OrderModel?> getOrderById(String orderId) async {
    return _orders[orderId];
  }

  @override
  Future<List<OrderModel>> getCustomerOrders(String customerId) async {
    final database = firestore;
    final remote = database == null
        ? const <OrderModel>[]
        : await _fetchCustomerOrdersFromFirestore(database, customerId);
    final byId = <String, OrderModel>{
      for (final order in _orders.values)
        if (order.customerId == customerId) order.id: order,
      for (final order in remote) order.id: order,
    };
    final list = byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(list);
  }

  Future<List<OrderModel>> _fetchCustomerOrdersFromFirestore(
    FirebaseFirestore database,
    String customerId,
  ) async {
    final snapshot = await database
        .collection(FirestorePaths.orders)
        .where('customerId', isEqualTo: customerId)
        .get();
    final orders = <OrderModel>[];
    for (final doc in snapshot.docs) {
      final itemsSnapshot = await doc.reference.collection('items').get();
      orders.add(
        _orderFromFirestore(
          doc.id,
          doc.data(),
          itemsSnapshot.docs.map((item) => item.data()).toList(),
        ),
      );
    }
    return orders;
  }

  OrderModel _orderFromFirestore(
    String id,
    Map<String, dynamic> data,
    List<Map<String, dynamic>> items,
  ) {
    return OrderModel(
      id: id,
      orderCode: data['orderCode'] as String? ?? id,
      customerId: data['customerId'] as String? ?? '',
      items: items.map(_itemFromFirestore).toList(growable: false),
      addressSnapshot: OrderAddressSnapshot.fromMap(
        data['addressSnapshot'] as Map<String, dynamic>? ?? const {},
      ),
      deliveryDistanceKm:
          (data['deliveryDistanceKm'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (data['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0.0,
      total: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: 'COD',
      status: OrderStatusExtension.fromDbString(
        (data['orderStatus'] ?? data['status']) as String?,
      ),
      cancellationReason: data['cancellationReason'] as String?,
      rejectionReason: data['rejectionReason'] as String?,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  OrderItemSnapshot _itemFromFirestore(Map<String, dynamic> data) {
    final sizeName = data['selectedSize'] as String? ?? '';
    final toppingNames = data['selectedToppings'] as List<dynamic>? ?? const [];
    return OrderItemSnapshot(
      menuItemId: data['menuItemId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      basePrice: (data['basePrice'] as num?)?.toDouble() ?? 0.0,
      selectedSize: CartOptionItem(id: sizeName, name: sizeName),
      selectedToppings: toppingNames
          .map((name) => CartOptionItem(id: name as String, name: name))
          .toList(growable: false),
      note: data['note'] as String?,
      unitPrice: (data['unitPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      subtotal: (data['lineTotal'] as num?)?.toDouble() ?? 0.0,
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
