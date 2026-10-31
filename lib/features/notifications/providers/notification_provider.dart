import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oder_food/features/notifications/models/notification_model.dart';
import 'package:oder_food/features/notifications/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) => MockNotificationRepository());

final notificationsListProvider = FutureProvider<List<NotificationModel>>((ref) async {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getNotifications();
});

final unreadCountProvider = Provider<int>((ref) {
  final async = ref.watch(notificationsListProvider);
  return async.maybeWhen(data: (list) => list.where((e) => !e.isRead).length, orElse: () => 0);
});

final notificationActionsProvider = Provider<NotificationActions>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  return NotificationActions(ref, repo);
});

class NotificationActions {
  NotificationActions(this.ref, this.repo);
  final Ref ref;
  final NotificationRepository repo;

  Future<void> markAsRead(String id) async {
    await repo.markAsRead(id);
    ref.invalidate(notificationsListProvider);
  }

  Future<void> markAllAsRead() async {
    await repo.markAllAsRead();
    ref.invalidate(notificationsListProvider);
  }
}
