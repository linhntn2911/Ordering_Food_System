import 'package:equatable/equatable.dart';

enum OrderStatus { pending, preparing, delivering, completed, cancelled }

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Đã đặt';
      case OrderStatus.preparing:
        return 'Đang chuẩn bị';
      case OrderStatus.delivering:
        return 'Đang giao';
      case OrderStatus.completed:
        return 'Đã giao';
      case OrderStatus.cancelled:
        return 'Đã hủy';
    }
  }

  bool get isOngoing {
    return this == OrderStatus.pending || this == OrderStatus.preparing || this == OrderStatus.delivering;
  }

  bool get isCompleted => this == OrderStatus.completed;
  bool get isCancelled => this == OrderStatus.cancelled;
}

class OrderItem extends Equatable {
  const OrderItem({required this.id, required this.name, required this.imageUrl, required this.quantity, required this.price});

  final String id;
  final String name;
  final String imageUrl;
  final int quantity;
  final double price;

  double get subtotal => price * quantity;

  @override
  List<Object?> get props => [id, name, imageUrl, quantity, price];
}

class OrderModel extends Equatable {
  const OrderModel({
    required this.orderId,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.address,
    required this.paymentMethod,
    this.note,
    this.estimatedDeliveryTime,
  });

  final String orderId;
  final String userId;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double totalPrice;
  final OrderStatus status;
  final DateTime createdAt;
  final String address;
  final String paymentMethod;
  final String? note;
  final DateTime? estimatedDeliveryTime;

  int get itemCount => items.fold(0, (sum, e) => sum + e.quantity);

  @override
  List<Object?> get props => [orderId, userId, items, subtotal, deliveryFee, discount, totalPrice, status, createdAt, address, paymentMethod, note, estimatedDeliveryTime];
}
