import 'order_status.dart';

class OrderStatusEvent {
  const OrderStatusEvent({
    required this.id,
    required this.toStatus,
    required this.actorId,
    required this.actorRole,
    required this.createdAt,
    this.fromStatus,
    this.reason = '',
  });

  final String id;
  final OrderStatus? fromStatus;
  final OrderStatus toStatus;
  final String actorId;
  final String actorRole;
  final String reason;
  final DateTime createdAt;
}
