import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/food_order.dart';
import '../../domain/entities/order_status.dart';

class FoodOrderModel {
  const FoodOrderModel({
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
    required this.subtotal,
    required this.deliveryFee,
    required this.deliveryDistanceKm,
    required this.customerNote,
    required this.cancellationReason,
    required this.rejectionReason,
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

  factory FoodOrderModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
    SnapshotOptions? _,
  ) {
    final data = document.data();
    if (data == null) throw StateError('Order ${document.id} has no data.');
    final createdAt = _date(data['createdAt']);
    return FoodOrderModel(
      id: document.id,
      orderCode: _string(data, 'orderCode', fallback: document.id),
      customerId: _string(data, 'customerId'),
      customerName: _string(data, 'customerName', fallback: 'Customer'),
      customerPhone: _string(data, 'customerPhone'),
      deliveryAddress: _string(data, 'deliveryAddress'),
      totalAmount: _int(data, 'totalAmount'),
      paymentMethod: _string(data, 'paymentMethod', fallback: 'cod'),
      paymentStatus: _string(data, 'paymentStatus', fallback: 'unpaid'),
      status: OrderStatus.parse(data['orderStatus']),
      createdAt: createdAt,
      updatedAt: _date(data['updatedAt'], fallback: createdAt),
      subtotal: _optionalInt(data['subtotal']),
      deliveryFee: _optionalInt(data['deliveryFee']),
      deliveryDistanceKm: _double(data['deliveryDistanceKm']),
      customerNote: _string(data, 'customerNote'),
      cancellationReason: _string(data, 'cancellationReason'),
      rejectionReason: _string(data, 'rejectionReason'),
    );
  }

  FoodOrder toEntity() => FoodOrder(
    id: id,
    orderCode: orderCode,
    customerId: customerId,
    customerName: customerName,
    customerPhone: customerPhone,
    deliveryAddress: deliveryAddress,
    totalAmount: totalAmount,
    paymentMethod: paymentMethod,
    paymentStatus: paymentStatus,
    status: status,
    createdAt: createdAt,
    updatedAt: updatedAt,
    subtotal: subtotal,
    deliveryFee: deliveryFee,
    deliveryDistanceKm: deliveryDistanceKm,
    customerNote: customerNote,
    cancellationReason: cancellationReason,
    rejectionReason: rejectionReason,
  );

  static String _string(
    Map<String, dynamic> data,
    String field, {
    String fallback = '',
  }) {
    final value = data[field];
    return value is String && value.trim().isNotEmpty ? value.trim() : fallback;
  }

  static int _int(Map<String, dynamic> data, String field) {
    final value = data[field];
    if (value is num) return value.toInt();
    throw FormatException('Missing or invalid $field.');
  }

  static int _optionalInt(Object? value) => value is num ? value.toInt() : 0;

  static double _double(Object? value) => value is num ? value.toDouble() : 0;

  static DateTime _date(Object? value, {DateTime? fallback}) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return fallback ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
}
