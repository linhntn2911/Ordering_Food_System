import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ordering_food_system/core/errors/failures.dart';
import 'package:ordering_food_system/core/firebase/firestore_paths.dart';
import 'package:ordering_food_system/features/notifications/models/notification_model.dart';

abstract class NotificationRepository {
  Future<List<NotificationModel>> getNotifications();
  Stream<List<NotificationModel>> watchNotifications();
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead();

  /// Customer broadcast delivery is a trusted backend/FCM responsibility.
  Future<NotificationModel> broadcastNotification({
    required String title,
    required String body,
    required NotificationType type,
  });
}

/// Reads the signed-in customer's notification documents in real time.
class FirestoreNotificationRepository implements NotificationRepository {
  FirestoreNotificationRepository(this._firestore, this._userId);

  final FirebaseFirestore _firestore;
  final String? _userId;

  CollectionReference<Map<String, dynamic>> _notifications() {
    final userId = _userId;
    if (userId == null || userId.trim().isEmpty) {
      throw const AuthFailure('Bạn cần đăng nhập để xem thông báo.');
    }
    return _firestore.collection(FirestorePaths.notifications(userId));
  }

  NotificationModel _fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    final rawType = data['type']?.toString() ?? '';
    final createdAt = data['createdAt'];
    return NotificationModel(
      id: document.id,
      title: data['title']?.toString() ?? 'Cập nhật từ Ngô Chicken',
      body: data['body']?.toString() ?? '',
      type: switch (rawType) {
        'promo' => NotificationType.promo,
        'system' => NotificationType.system,
        _ => NotificationType.orderUpdate,
      },
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      orderId: data['orderId']?.toString(),
      isRead: data['isRead'] == true,
    );
  }

  List<NotificationModel> _map(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return List.unmodifiable(snapshot.docs.map(_fromDocument));
  }

  Query<Map<String, dynamic>> _query() {
    return _notifications().orderBy('createdAt', descending: true);
  }

  @override
  Future<List<NotificationModel>> getNotifications() async {
    try {
      return _map(await _query().get());
    } on Failure {
      rethrow;
    } catch (error) {
      throw NotificationFailure('Không thể tải thông báo: $error');
    }
  }

  @override
  Stream<List<NotificationModel>> watchNotifications() {
    try {
      return _query().snapshots().map(_map);
    } on Failure catch (failure) {
      return Stream<List<NotificationModel>>.error(failure);
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notifications().doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw NotificationFailure('Không thể đánh dấu đã đọc: $error');
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      final unread = await _notifications()
          .where('isRead', isEqualTo: false)
          .get();
      if (unread.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final document in unread.docs) {
        batch.update(document.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (error) {
      throw NotificationFailure('Không thể đánh dấu tất cả đã đọc: $error');
    }
  }

  @override
  Future<NotificationModel> broadcastNotification({
    required String title,
    required String body,
    required NotificationType type,
  }) async {
    if (type == NotificationType.orderUpdate) {
      throw const NotificationFailure(
        'Thông báo đơn hàng được tạo tự động khi trạng thái đơn thay đổi.',
      );
    }

    final senderId = _userId;
    if (senderId == null || senderId.trim().isEmpty) {
      throw const AuthFailure('Admin cần đăng nhập để phát thông báo.');
    }

    try {
      final customers = await _firestore
          .collection(FirestorePaths.users)
          .where('role', isEqualTo: 'customer')
          .get();
      final targets =
          customers.docs
              .where((document) => document.data()['status'] == 'active')
              .map((document) => document.id)
              .toSet()
            ..add(senderId);

      for (final chunk in _chunks(targets.toList(growable: false), 450)) {
        final batch = _firestore.batch();
        for (final userId in chunk) {
          batch.set(
            _firestore.collection(FirestorePaths.notifications(userId)).doc(),
            {
              'type': type.name,
              'title': title.trim(),
              'body': body.trim(),
              'orderId': '',
              'isRead': false,
              'createdAt': FieldValue.serverTimestamp(),
            },
          );
        }
        await batch.commit();
      }

      return NotificationModel(
        id: 'broadcast-${DateTime.now().millisecondsSinceEpoch}',
        title: title.trim(),
        body: body.trim(),
        type: type,
        createdAt: DateTime.now(),
      );
    } catch (error) {
      if (error is Failure) rethrow;
      throw NotificationFailure('Không thể phát thông báo: $error');
    }
  }

  Iterable<List<T>> _chunks<T>(List<T> values, int size) sync* {
    for (var index = 0; index < values.length; index += size) {
      yield values.sublist(
        index,
        index + size > values.length ? values.length : index + size,
      );
    }
  }
}
