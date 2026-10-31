import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ordering_food_system/core/config/restaurant_config.dart';
import 'package:ordering_food_system/core/errors/failures.dart';
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
  });

  /// Retrieve order by ID
  Future<OrderModel?> getOrderById(String orderId);

  /// Retrieve all orders placed by the customer
  Future<List<OrderModel>> getCustomerOrders(String customerId);
}

/// Implementation of CheckoutRepository with atomic verification and idempotency guard
class CheckoutRepositoryImpl implements CheckoutRepository {
  final CartRepository cartRepository;

  // In-memory backing store for demo/offline and fast validation
  final Map<String, OrderModel> _orders = {};
  final Set<String> _processedIdempotencyKeys = {};
  final Map<String, OrderModel> _idempotentOrderCache = {};

  CheckoutRepositoryImpl({required this.cartRepository});

  @override
  Future<OrderModel> placeOrder({
    required String customerId,
    required AddressModel deliveryAddress,
    required List<CartItemModel> cartItems,
    required String idempotencyKey,
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
        (sum, item) => sum + item.subtotal,
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

  @override
  Future<OrderModel?> getOrderById(String orderId) async {
    return _orders[orderId];
  }

  @override
  Future<List<OrderModel>> getCustomerOrders(String customerId) async {
    final list =
        _orders.values.where((order) => order.customerId == customerId).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(list);
  }
}

/// Provider for CheckoutRepository
final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  final cartRepo = ref.watch(cartRepositoryProvider);
  return CheckoutRepositoryImpl(cartRepository: cartRepo);
});
