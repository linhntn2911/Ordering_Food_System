import 'order_status.dart';

class FoodOrder {
  const FoodOrder({
    required this.id,
    required this.orderCode,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.subtotal = 0,
    this.deliveryFee = 0,
    this.deliveryDistanceKm = 0,
    this.customerNote = '',
    this.cancellationReason = '',
    this.rejectionReason = '',
  });

  final String id;
  final String orderCode;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final int totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int subtotal;
  final int deliveryFee;
  final double deliveryDistanceKm;
  final String customerNote;
  final String cancellationReason;
  final String rejectionReason;

  FoodOrder copyWith({
    OrderStatus? status,
    DateTime? updatedAt,
    String? rejectionReason,
  }) {
    return FoodOrder(
      id: id,
      orderCode: orderCode,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      deliveryAddress: deliveryAddress,
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      deliveryDistanceKm: deliveryDistanceKm,
      customerNote: customerNote,
      cancellationReason: cancellationReason,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
