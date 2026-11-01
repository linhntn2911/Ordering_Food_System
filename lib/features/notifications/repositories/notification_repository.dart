import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ordering_food_system/features/notifications/models/notification_model.dart';

abstract class NotificationRepository {
  Future<List<NotificationModel>> getNotifications();
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead();
  Future<NotificationModel> broadcastNotification({
    required String title,
    required String body,
    required NotificationType type,
  });
}

class MockNotificationRepository implements NotificationRepository {
  final List<NotificationModel> _notifications = [
    NotificationModel(
      id: 'NT-1',
      title: 'Đơn hàng đang giao',
      body: 'Shipper đang trên đường giao đơn ORD-1001 của bạn.',
      type: NotificationType.orderUpdate,
      createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      orderId: 'ORD-1001',
    ),
    NotificationModel(
      id: 'NT-2',
      title: 'Đơn hàng đang chuẩn bị',
      body: 'Nhà hàng đã xác nhận và đang chuẩn bị đơn ORD-1003.',
      type: NotificationType.orderUpdate,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      orderId: 'ORD-1003',
    ),
    NotificationModel(
      id: 'NT-3',
      title: 'Ưu đãi hôm nay',
      body: 'Giảm 20% cho đơn hàng từ 150.000đ. Áp dụng đến hết ngày.',
      type: NotificationType.promo,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    NotificationModel(
      id: 'NT-4',
      title: 'Đơn hàng đã giao thành công',
      body: 'Đơn hàng ORD-1002 đã được giao thành công. Hãy đánh giá để nhận ưu đãi.',
      type: NotificationType.orderUpdate,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      orderId: 'ORD-1002',
    ),
  ];

  @override
  Future<List<NotificationModel>> getNotifications() async {
    return List.of(_notifications);
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((e) => e.id == notificationId);
    if (index >= 0) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }

  @override
  Future<void> markAllAsRead() async {
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
  }

  @override
  Future<NotificationModel> broadcastNotification({
    required String title,
    required String body,
    required NotificationType type,
  }) async {
    final newNotification = NotificationModel(
      id: 'NT-${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      body: body.trim(),
      type: type,
      createdAt: DateTime.now(),
      isRead: false,
    );
    _notifications.insert(0, newNotification);

    try {
      await FirebaseFirestore.instance.collection('broadcast_notifications').add({
        'title': newNotification.title,
        'body': newNotification.body,
        'type': newNotification.type.name,
        'createdAt': FieldValue.serverTimestamp(),
        'isBroadcast': true,
      });
    } catch (_) {
      // Soft-fail in mock/test environment
    }

    return newNotification;
  }
}
