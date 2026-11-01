import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ordering_food_system/core/config/restaurant_config.dart';
import 'package:ordering_food_system/core/errors/failures.dart';
import 'package:ordering_food_system/features/address/data/models/address_model.dart';
import 'package:ordering_food_system/features/address/presentation/controllers/address_controller.dart';
import 'package:ordering_food_system/features/cart/data/models/cart_item_model.dart';
import 'package:ordering_food_system/features/cart/presentation/controllers/cart_controller.dart';
import 'package:ordering_food_system/features/checkout/data/checkout_repository.dart';
import 'package:ordering_food_system/features/checkout/data/models/order_model.dart';

/// Immutable UI State for the Checkout process
@immutable
class CheckoutState {
  final AddressModel? selectedAddress;
  final List<CartItemModel> cartItems;
  final bool isSubmitting; // Duplicate tap lock (SC-005)
  final String? errorMessage;
  final OrderModel? lastCreatedOrder;
  final String deliveryNote;

  const CheckoutState({
    this.selectedAddress,
    this.cartItems = const [],
    this.isSubmitting = false,
    this.errorMessage,
    this.lastCreatedOrder,
    this.deliveryNote = '',
  });

  /// Total sum of all cart lines (FR-049, BR-005)
  double get subtotal => cartItems.fold(0.0, (sum, e) => sum + e.subtotal);

  /// Calculated distance from restaurant to selected delivery address (FR-046)
  double? get deliveryDistanceKm => selectedAddress?.distanceToRestaurant;

  /// Whether coordinates can be determined from the address (FR-048)
  bool get isDistanceResolvable =>
      selectedAddress?.latitude != null && selectedAddress?.longitude != null;

  /// Checks if address is within 8km allowable limit (FR-048, BR-015)
  bool get isServiceable {
    final dist = deliveryDistanceKm;
    return dist != null && dist <= RestaurantConfig.maxDeliveryDistanceKm;
  }

  /// Authoritative delivery fee based on 3 bands: 15k, 20k, 30k (FR-047, BR-014)
  double? get deliveryFee =>
      RestaurantConfig.calculateDeliveryFee(deliveryDistanceKm);

  /// Total amount = subtotal + deliveryFee (FR-049, BR-005)
  double? get total {
    final fee = deliveryFee;
    if (fee == null) return null;
    return subtotal + fee;
  }

  /// Whether any items in cart are unavailable (FR-013)
  bool get hasUnavailableItems => cartItems.any((e) => !e.isAvailable);

  /// Overall gate to enable the Confirm Order button (FR-014, FR-048, SC-005)
  bool get canSubmitOrder {
    return !isSubmitting &&
        cartItems.isNotEmpty &&
        !hasUnavailableItems &&
        selectedAddress != null &&
        isDistanceResolvable &&
        isServiceable &&
        deliveryFee != null;
  }

  /// Formatted explanation if order placement is currently blocked (FR-048)
  String? get validationErrorMessage {
    if (cartItems.isEmpty) {
      return 'Giỏ hàng của bạn đang trống.';
    }
    if (hasUnavailableItems) {
      return 'Có món trong giỏ hàng hiện tạm hết, vui lòng quay lại giỏ để cập nhật.';
    }
    if (selectedAddress == null) {
      return 'Vui lòng chọn một địa chỉ nhận hàng (FR-014).';
    }
    if (!isDistanceResolvable) {
      return 'Không thể xác định khoảng cách giao hàng từ địa chỉ này (FR-048). Vui lòng cập nhật tọa độ địa chỉ.';
    }
    if (!isServiceable) {
      final dist = (deliveryDistanceKm ?? 0).toStringAsFixed(1);
      return 'Khoảng cách giao hàng là ${dist}km, vượt quá bán kính phục vụ 8km (FR-048). Vui lòng chọn địa chỉ khác.';
    }
    return null;
  }

  CheckoutState copyWith({
    AddressModel? selectedAddress,
    List<CartItemModel>? cartItems,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    OrderModel? lastCreatedOrder,
    String? deliveryNote,
  }) {
    return CheckoutState(
      selectedAddress: selectedAddress ?? this.selectedAddress,
      cartItems: cartItems != null
          ? List.unmodifiable(cartItems)
          : this.cartItems,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastCreatedOrder: lastCreatedOrder ?? this.lastCreatedOrder,
      deliveryNote: deliveryNote ?? this.deliveryNote,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckoutState &&
          runtimeType == other.runtimeType &&
          selectedAddress == other.selectedAddress &&
          listEquals(cartItems, other.cartItems) &&
          isSubmitting == other.isSubmitting &&
          errorMessage == other.errorMessage &&
          lastCreatedOrder == other.lastCreatedOrder &&
          deliveryNote == other.deliveryNote;

  @override
  int get hashCode =>
      selectedAddress.hashCode ^
      cartItems.hashCode ^
      isSubmitting.hashCode ^
      errorMessage.hashCode ^
      lastCreatedOrder.hashCode ^
      deliveryNote.hashCode;
}

/// CheckoutController managing order validation, fee calculation, and atomic placement
class CheckoutController extends Notifier<CheckoutState> {
  late CheckoutRepository _checkoutRepository;

  @override
  CheckoutState build() {
    _checkoutRepository = ref.watch(checkoutRepositoryProvider);

    // Watch cart items from CartController (only items with isSelected == true)
    final cartState = ref.watch(cartControllerProvider);
    final selectedCartItems = cartState.selectedItems;

    // Watch address book from AddressController to auto-select default address
    final addressState = ref.watch(addressControllerProvider);
    final initialAddress =
        addressState.selectedAddress ?? addressState.defaultAddress;

    return CheckoutState(
      selectedAddress: initialAddress,
      cartItems: selectedCartItems,
    );
  }

  /// Change delivery address and immediately recalculate distance & fee (FR-046)
  void selectAddress(AddressModel address) {
    state = state.copyWith(selectedAddress: address, clearError: true);
  }

  /// Update optional delivery note
  void updateDeliveryNote(String note) {
    state = state.copyWith(deliveryNote: note);
  }

  /// Places order atomically with duplicate tap prevention (FR-016, SC-005, NFR-003)
  Future<OrderModel?> placeOrder() async {
    // SC-005: Guard against duplicate taps
    if (state.isSubmitting) return null;

    final customerId = ref.read(currentCustomerIdProvider);
    if (customerId == null || customerId.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: 'Vui lòng đăng nhập để tiến hành đặt hàng.',
      );
      throw const AuthFailure('Vui lòng đăng nhập để tiến hành đặt hàng.');
    }

    // Validate checkout prerequisites (FR-014, FR-048)
    final validationError = state.validationErrorMessage;
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      return null;
    }

    // Lock submission state
    state = state.copyWith(isSubmitting: true, clearError: true);

    final idempotencyKey =
        'idemp_${DateTime.now().millisecondsSinceEpoch}_${state.selectedAddress!.id}';

    try {
      final order = await _checkoutRepository.placeOrder(
        customerId: customerId,
        deliveryAddress: state.selectedAddress!,
        cartItems: state.cartItems,
        idempotencyKey: idempotencyKey,
      );

      // User Requirement:
      // "Khi bấm 'Xác nhận đặt hàng' thành công: CHỈ XÓA các món đã được thanh toán ra khỏi giỏ hàng.
      // Các món còn lại chưa tick chọn PHẢI ĐƯỢC GIỮ NGUYÊN trong CartState."
      final purchasedIds = state.cartItems.map((e) => e.id).toList();
      await ref
          .read(cartControllerProvider.notifier)
          .removePurchasedItems(purchasedIds);

      state = state.copyWith(
        isSubmitting: false,
        lastCreatedOrder: order,
        clearError: true,
      );

      return order;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e is Failure ? e.message : e.toString(),
      );
      return null;
    }
  }

  /// Clear active error banner
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider for CheckoutController
final checkoutControllerProvider =
    NotifierProvider<CheckoutController, CheckoutState>(CheckoutController.new);
