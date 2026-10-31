import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:ordering_food_system/features/address/data/models/address_model.dart';
import 'package:ordering_food_system/features/cart/data/models/cart_item_model.dart';

/// Permitted sequential and terminal order statuses (BR-001, BR-002)
enum OrderStatus {
  pending,
  confirmed,
  preparing,
  outForDelivery,
  completed,
  cancelled,
  rejected,
}

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Chờ xác nhận';
      case OrderStatus.confirmed:
        return 'Đã xác nhận';
      case OrderStatus.preparing:
        return 'Đang chuẩn bị';
      case OrderStatus.outForDelivery:
        return 'Đang giao hàng';
      case OrderStatus.completed:
        return 'Hoàn thành';
      case OrderStatus.cancelled:
        return 'Đã hủy';
      case OrderStatus.rejected:
        return 'Bị từ chối';
    }
  }

  String toDbString() {
    return name;
  }

  static OrderStatus fromDbString(String? value) {
    return OrderStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == (value ?? '').toLowerCase(),
      orElse: () => OrderStatus.pending,
    );
  }
}

/// Immutable snapshot of delivery address at the time of order creation (FR-016, FR-026, BR-004)
@immutable
class OrderAddressSnapshot {
  final String label;
  final String recipientName;
  final String phoneNumber;
  final String streetAddress;
  final String fullAddress;
  final double? latitude;
  final double? longitude;

  const OrderAddressSnapshot({
    required this.label,
    required this.recipientName,
    required this.phoneNumber,
    required this.streetAddress,
    required this.fullAddress,
    this.latitude,
    this.longitude,
  });

  factory OrderAddressSnapshot.fromAddressModel(AddressModel address) {
    return OrderAddressSnapshot(
      label: address.label,
      recipientName: address.recipientName,
      phoneNumber: address.phoneNumber,
      streetAddress: address.streetAddress,
      fullAddress: address.fullAddress,
      latitude: address.latitude,
      longitude: address.longitude,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'recipientName': recipientName,
      'phoneNumber': phoneNumber,
      'streetAddress': streetAddress,
      'fullAddress': fullAddress,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory OrderAddressSnapshot.fromMap(Map<String, dynamic> map) {
    return OrderAddressSnapshot(
      label: map['label'] as String? ?? 'Nhà riêng',
      recipientName: map['recipientName'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      streetAddress: map['streetAddress'] as String? ?? '',
      fullAddress: map['fullAddress'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}

/// Immutable snapshot of an ordered food item at checkout time (FR-016, FR-026)
@immutable
class OrderItemSnapshot {
  final String menuItemId;
  final String name;
  final String imageUrl;
  final double basePrice;
  final CartOptionItem selectedSize;
  final List<CartOptionItem> selectedToppings;
  final String? note;
  final double unitPrice;
  final int quantity;
  final double subtotal;

  const OrderItemSnapshot({
    required this.menuItemId,
    required this.name,
    required this.imageUrl,
    required this.basePrice,
    required this.selectedSize,
    this.selectedToppings = const [],
    this.note,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderItemSnapshot.fromCartItem(CartItemModel item) {
    return OrderItemSnapshot(
      menuItemId: item.menuItemId,
      name: item.name,
      imageUrl: item.imageUrl,
      basePrice: item.basePrice,
      selectedSize: item.selectedSize,
      selectedToppings: List.from(item.selectedToppings),
      note: item.note,
      unitPrice: item.unitPrice,
      quantity: item.quantity,
      subtotal: item.subtotal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'imageUrl': imageUrl,
      'basePrice': basePrice,
      'selectedSize': selectedSize.toMap(),
      'selectedToppings': selectedToppings.map((e) => e.toMap()).toList(),
      'note': note,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }

  factory OrderItemSnapshot.fromMap(Map<String, dynamic> map) {
    return OrderItemSnapshot(
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
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Order model adhering to FR-014, FR-015, FR-016, FR-046, FR-047, FR-049, FR-050, BR-004, BR-005
@immutable
class OrderModel {
  final String id;
  final String orderCode; // Structured code: ORD-YYYYMMDD-XXXX (FR-050)
  final String customerId;
  final List<OrderItemSnapshot> items;
  final OrderAddressSnapshot addressSnapshot;
  final double deliveryDistanceKm; // FR-046
  final double deliveryFee; // Authoritative fee: 15k, 20k, 30k (FR-047, BR-014)
  final double subtotal; // Validated item subtotals (BR-005)
  final double total; // Subtotal + deliveryFee (FR-049, BR-005)
  final String paymentMethod; // Only 'COD' supported (FR-015)
  final OrderStatus status; // Initial status is Pending (FR-016, BR-001)
  final String? cancellationReason;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const OrderModel({
    required this.id,
    required this.orderCode,
    required this.customerId,
    required this.items,
    required this.addressSnapshot,
    required this.deliveryDistanceKm,
    required this.deliveryFee,
    required this.subtotal,
    required this.total,
    this.paymentMethod = 'COD',
    this.status = OrderStatus.pending,
    this.cancellationReason,
    this.rejectionReason,
    required this.createdAt,
    this.updatedAt,
  });

  /// Generates a structured collision-safe order code: ORD-YYYYMMDD-XXXX (FR-050)
  static String generateOrderCode([DateTime? date]) {
    final now = date ?? DateTime.now();
    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final randomSuffix = (math.Random().nextInt(9000) + 1000).toString();
    return 'ORD-$year$month$day-$randomSuffix';
  }

  OrderModel copyWith({
    String? id,
    String? orderCode,
    String? customerId,
    List<OrderItemSnapshot>? items,
    OrderAddressSnapshot? addressSnapshot,
    double? deliveryDistanceKm,
    double? deliveryFee,
    double? subtotal,
    double? total,
    String? paymentMethod,
    OrderStatus? status,
    String? cancellationReason,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderCode: orderCode ?? this.orderCode,
      customerId: customerId ?? this.customerId,
      items: items ?? this.items,
      addressSnapshot: addressSnapshot ?? this.addressSnapshot,
      deliveryDistanceKm: deliveryDistanceKm ?? this.deliveryDistanceKm,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      subtotal: subtotal ?? this.subtotal,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderCode': orderCode,
      'customerId': customerId,
      'items': items.map((e) => e.toMap()).toList(),
      'addressSnapshot': addressSnapshot.toMap(),
      'deliveryDistanceKm': deliveryDistanceKm,
      'deliveryFee': deliveryFee,
      'subtotal': subtotal,
      'total': total,
      'paymentMethod': paymentMethod,
      'status': status.toDbString(),
      'cancellationReason': cancellationReason,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] as String? ?? '',
      orderCode: map['orderCode'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      items:
          (map['items'] as List<dynamic>?)
              ?.map((e) => OrderItemSnapshot.fromMap(e as Map<String, dynamic>))
              .toList() ??
          const [],
      addressSnapshot: OrderAddressSnapshot.fromMap(
        map['addressSnapshot'] as Map<String, dynamic>? ?? {},
      ),
      deliveryDistanceKm:
          (map['deliveryDistanceKm'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] as String? ?? 'COD',
      status: OrderStatusExtension.fromDbString(map['status'] as String?),
      cancellationReason: map['cancellationReason'] as String?,
      rejectionReason: map['rejectionReason'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          orderCode == other.orderCode &&
          customerId == other.customerId &&
          total == other.total &&
          status == other.status;

  @override
  int get hashCode =>
      id.hashCode ^
      orderCode.hashCode ^
      customerId.hashCode ^
      total.hashCode ^
      status.hashCode;
}
