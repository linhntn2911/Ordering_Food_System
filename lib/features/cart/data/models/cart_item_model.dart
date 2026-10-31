import 'package:flutter/foundation.dart';

/// Represents an option selection item (e.g., Size, Topping)
@immutable
class CartOptionItem {
  final String id;
  final String name;
  final double additionalPrice;

  const CartOptionItem({
    required this.id,
    required this.name,
    this.additionalPrice = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'additionalPrice': additionalPrice};
  }

  factory CartOptionItem.fromMap(Map<String, dynamic> map) {
    return CartOptionItem(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      additionalPrice: (map['additionalPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartOptionItem &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          additionalPrice == other.additionalPrice;

  @override
  int get hashCode => name.hashCode ^ additionalPrice.hashCode;

  @override
  String toString() => '$name (+${additionalPrice.toStringAsFixed(0)}đ)';
}

/// Cart line item model adhering to FR-011, BR-006, BR-012, BR-013, FR-013
@immutable
class CartItemModel {
  final String id;
  final String menuItemId;
  final String name;
  final String imageUrl;
  final double basePrice;
  final CartOptionItem selectedSize; // Required size (BR-012)
  final List<CartOptionItem> selectedToppings; // Selected toppings
  final String? note; // Optional note (BR-012)
  final int quantity; // Valid quantity >= 1
  final bool isAvailable; // Real-time food availability status (FR-013)
  final bool isSelected; // Shopee-style selection flag for checkout
  final DateTime createdAt;

  const CartItemModel({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.imageUrl,
    required this.basePrice,
    required this.selectedSize,
    this.selectedToppings = const [],
    this.note,
    this.quantity = 1,
    this.isAvailable = true,
    this.isSelected = true,
    required this.createdAt,
  });

  /// Single item price with size and toppings added
  double get unitPrice {
    final double toppingsTotal = selectedToppings.fold(
      0.0,
      (sum, item) => sum + item.additionalPrice,
    );
    return basePrice + selectedSize.additionalPrice + toppingsTotal;
  }

  /// Line subtotal = unitPrice * quantity (FR-012, BR-013)
  double get subtotal => unitPrice * quantity;

  /// Check whether two cart items have an IDENTICAL configuration (BR-006 & BR-013).
  /// A cart line is identical only when menuItemId, size, toppings, and note are identical.
  bool isIdenticalConfiguration(CartItemModel other) {
    if (menuItemId != other.menuItemId) return false;

    // Check size
    if (selectedSize.name != other.selectedSize.name ||
        selectedSize.additionalPrice != other.selectedSize.additionalPrice) {
      return false;
    }

    // Check toppings (order-independent comparison)
    if (!_areToppingsEqual(selectedToppings, other.selectedToppings)) {
      return false;
    }

    // Check note (trimmed comparison)
    final thisNote = (note ?? '').trim().toLowerCase();
    final otherNote = (other.note ?? '').trim().toLowerCase();
    if (thisNote != otherNote) return false;

    return true;
  }

  static bool _areToppingsEqual(
    List<CartOptionItem> a,
    List<CartOptionItem> b,
  ) {
    if (a.length != b.length) return false;
    final listA = List<CartOptionItem>.from(a)
      ..sort((x, y) => x.name.compareTo(y.name));
    final listB = List<CartOptionItem>.from(b)
      ..sort((x, y) => x.name.compareTo(y.name));

    for (int i = 0; i < listA.length; i++) {
      if (listA[i].name != listB[i].name ||
          listA[i].additionalPrice != listB[i].additionalPrice) {
        return false;
      }
    }
    return true;
  }

  /// Validates whether this line is valid for checkout (FR-013)
  bool get isValidForCheckout {
    return isAvailable && quantity > 0 && selectedSize.name.isNotEmpty;
  }

  /// Returns user-friendly validation error message if invalid
  String? get validationErrorMessage {
    if (!isAvailable) {
      return 'Món "$name" hiện đang tạm hết hàng.';
    }
    if (quantity <= 0) {
      return 'Số lượng của món "$name" không hợp lệ.';
    }
    if (selectedSize.name.isEmpty) {
      return 'Món "$name" chưa được chọn kích cỡ.';
    }
    return null;
  }

  CartItemModel copyWith({
    String? id,
    String? menuItemId,
    String? name,
    String? imageUrl,
    double? basePrice,
    CartOptionItem? selectedSize,
    List<CartOptionItem>? selectedToppings,
    String? note,
    int? quantity,
    bool? isAvailable,
    bool? isSelected,
    DateTime? createdAt,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      menuItemId: menuItemId ?? this.menuItemId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      basePrice: basePrice ?? this.basePrice,
      selectedSize: selectedSize ?? this.selectedSize,
      selectedToppings: selectedToppings ?? this.selectedToppings,
      note: note ?? this.note,
      quantity: quantity ?? this.quantity,
      isAvailable: isAvailable ?? this.isAvailable,
      isSelected: isSelected ?? this.isSelected,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'menuItemId': menuItemId,
      'name': name,
      'imageUrl': imageUrl,
      'basePrice': basePrice,
      'selectedSize': selectedSize.toMap(),
      'selectedToppings': selectedToppings.map((e) => e.toMap()).toList(),
      'note': note,
      'quantity': quantity,
      'isAvailable': isAvailable,
      'isSelected': isSelected,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      id: map['id'] as String? ?? '',
      menuItemId: map['menuItemId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      basePrice: (map['basePrice'] as num?)?.toDouble() ?? 0.0,
      selectedSize: CartOptionItem.fromMap(
        map['selectedSize'] as Map<String, dynamic>? ?? {},
      ),
      selectedToppings:
          (map['selectedToppings'] as List<dynamic>?)
              ?.map((e) => CartOptionItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          const [],
      note: map['note'] as String?,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      isAvailable: map['isAvailable'] as bool? ?? true,
      isSelected: map['isSelected'] as bool? ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItemModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          quantity == other.quantity &&
          isAvailable == other.isAvailable &&
          isSelected == other.isSelected &&
          isIdenticalConfiguration(other);

  @override
  int get hashCode =>
      id.hashCode ^
      menuItemId.hashCode ^
      quantity.hashCode ^
      isAvailable.hashCode ^
      isSelected.hashCode;
}
