import 'package:equatable/equatable.dart';

enum NotificationType { orderUpdate, promo, system }

class NotificationModel extends Equatable {
  const NotificationModel({required this.id, required this.title, required this.body, required this.type, required this.createdAt, this.orderId, this.isRead = false});
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime createdAt;
  final String? orderId;
  final bool isRead;

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(id: id, title: title, body: body, type: type, createdAt: createdAt, orderId: orderId, isRead: isRead ?? this.isRead);
  }

  @override
  List<Object?> get props => [id, title, body, type, createdAt, orderId, isRead];
}
