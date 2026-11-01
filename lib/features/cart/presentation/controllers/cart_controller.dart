import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ordering_food_system/core/errors/failures.dart';
import 'package:ordering_food_system/features/cart/data/cart_repository.dart';
import 'package:ordering_food_system/features/cart/data/models/cart_item_model.dart';

/// Notifier for current authenticated Customer UID (BR-011)
/// Can be wired to Firebase Authentication or updated on login/logout
class CurrentCustomerIdNotifier extends Notifier<String?> {
  @override
  String? build() {
    // Default to a demo customer UID so screen works out-of-the-box
    return 'customer_demo_uid';
  }

  void setCustomerId(String? id) {
    state = id;
  }
}

/// Provider for current authenticated Customer UID
final currentCustomerIdProvider =
    NotifierProvider<CurrentCustomerIdNotifier, String?>(
      CurrentCustomerIdNotifier.new,
    );

/// Immutable UI State for Cart Screen
@immutable
class CartState {
  final List<CartItemModel> items;
  final bool isLoading;
  final String? errorMessage;
  final String? customerId;

  const CartState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
    this.customerId,
  });

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  /// Selected items for checkout (Shopee-style)
  List<CartItemModel> get selectedItems =>
      items.where((item) => item.isSelected).toList();

  /// Whether any items are selected
  bool get hasSelectedItems => selectedItems.isNotEmpty;

  /// Whether all items in the cart are selected
  bool get isAllSelected =>
      items.isNotEmpty && items.every((item) => item.isSelected);

  /// Total count of all items (sum of quantities)
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// Total count of selected items
  int get selectedItemCount =>
      selectedItems.fold(0, (sum, item) => sum + item.quantity);

  /// Line-item subtotal of all items in cart
  double get totalCartValue =>
      items.fold(0.0, (sum, item) => sum + item.subtotal);

  /// Authoritative line-item subtotal (FR-012, BR-013)
  /// User Requirement: "Tổng tiền món ăn" CHỈ TÍNH TIỀN trên các món có isSelected == true
  double get subtotal =>
      selectedItems.fold(0.0, (sum, item) => sum + item.subtotal);

  /// Check if any item in the cart is currently unavailable (FR-013)
  bool get hasUnavailableItems => items.any((item) => !item.isAvailable);

  /// Check if any SELECTED item in the cart is currently unavailable (FR-013)
  bool get hasSelectedUnavailableItems =>
      selectedItems.any((item) => !item.isAvailable);

  /// List of unavailable items requiring user resolution (FR-013)
  List<CartItemModel> get unavailableItems =>
      items.where((item) => !item.isAvailable).toList();

  /// List of selected unavailable items requiring user resolution (FR-013)
  List<CartItemModel> get selectedUnavailableItems =>
      selectedItems.where((item) => !item.isAvailable).toList();

  /// Checkout eligibility gate (FR-013, BR-011)
  /// Disabled if no item selected or selected item is unavailable
  bool get canProceedToCheckout =>
      isNotEmpty &&
      hasSelectedItems &&
      !hasSelectedUnavailableItems &&
      customerId != null &&
      !isLoading;

  /// Formatted validation message explaining why checkout cannot proceed (FR-013)
  String? get checkoutValidationMessage {
    if (customerId == null || customerId!.isEmpty) {
      return 'Vui lòng đăng nhập để tiến hành đặt hàng.';
    }
    if (isEmpty) {
      return 'Giỏ hàng của bạn đang trống.';
    }
    if (!hasSelectedItems) {
      return 'Vui lòng tick chọn ít nhất một món ăn để tiến hành đặt hàng.';
    }
    if (hasSelectedUnavailableItems) {
      final names = selectedUnavailableItems
          .map((e) => '"${e.name}"')
          .join(', ');
      return 'Món $names hiện đang tạm hết hàng. Vui lòng bỏ chọn hoặc xóa khỏi giỏ để tiếp tục thanh toán.';
    }
    return null;
  }

  CartState copyWith({
    List<CartItemModel>? items,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? customerId,
  }) {
    return CartState(
      items: items != null ? List.unmodifiable(items) : this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      customerId: customerId ?? this.customerId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartState &&
          runtimeType == other.runtimeType &&
          listEquals(items, other.items) &&
          isLoading == other.isLoading &&
          errorMessage == other.errorMessage &&
          customerId == other.customerId;

  @override
  int get hashCode =>
      items.hashCode ^
      isLoading.hashCode ^
      errorMessage.hashCode ^
      customerId.hashCode;
}

/// CartController managing Cart business logic with Riverpod Notifier
class CartController extends Notifier<CartState> {
  late CartRepository _repository;

  @override
  CartState build() {
    _repository = ref.watch(cartRepositoryProvider);
    final customerId = ref.watch(currentCustomerIdProvider);

    final initialItems = customerId != null && customerId.isNotEmpty
        ? _repository.getCachedCart(customerId)
        : const <CartItemModel>[];

    return CartState(customerId: customerId, items: initialItems);
  }

  /// Load cart items for customer
  Future<void> loadCart(String customerId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _repository.getCart(customerId);
      state = state.copyWith(
        items: items,
        isLoading: false,
        customerId: customerId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e is Failure ? e.message : e.toString(),
      );
    }
  }

  /// Ensure customer is authenticated before mutating cart (BR-011)
  String _requireCustomerAuth() {
    final uid = state.customerId;
    if (uid == null || uid.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: 'Bạn cần đăng nhập để thao tác với giỏ hàng.',
      );
      throw const AuthFailure('Bạn cần đăng nhập để thao tác với giỏ hàng.');
    }
    return uid;
  }

  /// FR-011 & BR-012: Add configured food item to cart
  /// BR-006 & BR-013: If an identical item configuration exists, increase quantity
  Future<void> addItem(CartItemModel newItem) async {
    final customerId = _requireCustomerAuth();

    // Validate item configuration
    if (newItem.selectedSize.name.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Vui lòng chọn kích cỡ (Size) bắt buộc cho món ăn.',
      );
      return;
    }
    if (newItem.quantity <= 0) {
      state = state.copyWith(errorMessage: 'Số lượng thêm vào phải lớn hơn 0.');
      return;
    }

    final currentList = List<CartItemModel>.from(state.items);

    // BR-006: Check identical configuration (item, size, toppings, note)
    final existingIndex = currentList.indexWhere(
      (element) => element.isIdenticalConfiguration(newItem),
    );

    if (existingIndex != -1) {
      // BR-013: Identical item exists -> increase quantity instead of creating duplicate
      final existing = currentList[existingIndex];
      final updatedQuantity = existing.quantity + newItem.quantity;
      currentList[existingIndex] = existing.copyWith(
        quantity: updatedQuantity,
        isAvailable: newItem.isAvailable, // Refresh latest availability
      );
    } else {
      currentList.add(newItem);
    }

    // Recalculate totals immediately & update state (FR-012, BR-013)
    state = state.copyWith(items: currentList, clearError: true);

    try {
      await _repository.saveCart(customerId, currentList);
    } catch (e) {
      state = state.copyWith(
        errorMessage: e is Failure ? e.message : e.toString(),
      );
    }
  }

  /// FR-012 & BR-013: Update quantity of a specific cart line
  Future<void> updateQuantity(String cartItemId, int newQuantity) async {
    final customerId = _requireCustomerAuth();

    if (newQuantity <= 0) {
      await removeItem(cartItemId);
      return;
    }

    final currentList = List<CartItemModel>.from(state.items);
    final index = currentList.indexWhere((item) => item.id == cartItemId);

    if (index == -1) return;

    currentList[index] = currentList[index].copyWith(quantity: newQuantity);

    // Update state and recalculate immediately
    state = state.copyWith(items: currentList, clearError: true);

    try {
      await _repository.saveCart(customerId, currentList);
    } catch (e) {
      state = state.copyWith(
        errorMessage: e is Failure ? e.message : e.toString(),
      );
    }
  }

  /// Increase quantity by 1
  Future<void> incrementQuantity(String cartItemId) async {
    final item = state.items.cast<CartItemModel?>().firstWhere(
      (element) => element?.id == cartItemId,
      orElse: () => null,
    );
    if (item != null) {
      await updateQuantity(cartItemId, item.quantity + 1);
    }
  }

  /// Decrease quantity by 1; removes line if quantity reaches 0
  Future<void> decrementQuantity(String cartItemId) async {
    final item = state.items.cast<CartItemModel?>().firstWhere(
      (element) => element?.id == cartItemId,
      orElse: () => null,
    );
    if (item != null) {
      await updateQuantity(cartItemId, item.quantity - 1);
    }
  }

  /// FR-012: Remove a specific cart item line
  Future<void> removeItem(String cartItemId) async {
    final customerId = _requireCustomerAuth();

    final currentList = state.items.where((e) => e.id != cartItemId).toList();

    // Recalculate immediately
    state = state.copyWith(items: currentList, clearError: true);

    try {
      await _repository.saveCart(customerId, currentList);
    } catch (e) {
      state = state.copyWith(
        errorMessage: e is Failure ? e.message : e.toString(),
      );
    }
  }

  /// Clear the entire cart
  Future<void> clearCart() async {
    final customerId = _requireCustomerAuth();

    state = state.copyWith(items: const [], clearError: true);

    try {
      await _repository.clearCart(customerId);
    } catch (e) {
      state = state.copyWith(
        errorMessage: e is Failure ? e.message : e.toString(),
      );
    }
  }

  /// Toggle selection state of a specific cart item line (Shopee-style)
  Future<void> toggleItemSelection(String cartItemId) async {
    final currentList = List<CartItemModel>.from(state.items);
    final index = currentList.indexWhere((e) => e.id == cartItemId);
    if (index == -1) return;

    currentList[index] = currentList[index].copyWith(
      isSelected: !currentList[index].isSelected,
    );
    state = state.copyWith(items: currentList, clearError: true);

    final customerId = state.customerId;
    if (customerId != null && customerId.isNotEmpty) {
      try {
        await _repository.saveCart(customerId, currentList);
      } catch (_) {}
    }
  }

  /// Set selection state of a specific cart item line
  Future<void> setItemSelection(String cartItemId, bool isSelected) async {
    final currentList = List<CartItemModel>.from(state.items);
    final index = currentList.indexWhere((e) => e.id == cartItemId);
    if (index == -1) return;

    currentList[index] = currentList[index].copyWith(isSelected: isSelected);
    state = state.copyWith(items: currentList, clearError: true);

    final customerId = state.customerId;
    if (customerId != null && customerId.isNotEmpty) {
      try {
        await _repository.saveCart(customerId, currentList);
      } catch (_) {}
    }
  }

  /// Select or deselect all items in the cart
  Future<void> toggleSelectAll(bool selectAll) async {
    final currentList = state.items
        .map((item) => item.copyWith(isSelected: selectAll))
        .toList();

    state = state.copyWith(items: currentList, clearError: true);

    final customerId = state.customerId;
    if (customerId != null && customerId.isNotEmpty) {
      try {
        await _repository.saveCart(customerId, currentList);
      } catch (_) {}
    }
  }

  /// Remove only the purchased items from the cart (preserving unselected items)
  Future<void> removePurchasedItems(List<String> purchasedItemIds) async {
    final customerId = _requireCustomerAuth();
    final remaining = state.items
        .where((item) => !purchasedItemIds.contains(item.id))
        .toList();

    state = state.copyWith(items: remaining, clearError: true);

    try {
      await _repository.saveCart(customerId, remaining);
    } catch (e) {
      state = state.copyWith(
        errorMessage: e is Failure ? e.message : e.toString(),
      );
    }
  }

  /// Reload the rich 4 demo items when cart is empty for testing
  Future<void> reloadDemoItems() async {
    final customerId = state.customerId ?? 'customer_demo_uid';
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final items = await _repository.reloadDemoItems(customerId);
      state = state.copyWith(
        items: items,
        isLoading: false,
        customerId: customerId,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e is Failure ? e.message : e.toString(),
      );
    }
  }

  /// FR-013: Validate cart before proceeding to checkout
  /// Returns true if valid, or false with error message set in state
  bool validateCartForCheckout() {
    final message = state.checkoutValidationMessage;
    if (message != null) {
      state = state.copyWith(errorMessage: message);
      return false;
    }
    return true;
  }

  /// Clear any error message in the state
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider for CartController
final cartControllerProvider = NotifierProvider<CartController, CartState>(
  CartController.new,
);
