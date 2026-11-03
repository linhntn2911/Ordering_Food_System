import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ordering_food_system/core/firebase/firebase_providers.dart';
import 'package:ordering_food_system/features/auth/presentation/viewmodels/auth_providers.dart';
import 'package:ordering_food_system/features/notifications/models/notification_model.dart';
import 'package:ordering_food_system/features/notifications/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return FirestoreNotificationRepository(
    ref.watch(firebaseFirestoreProvider),
    ref.watch(authStateProvider).value?.id,
  );
});

final notificationsListProvider = StreamProvider<List<NotificationModel>>((
  ref,
) {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.watchNotifications();
});

final unreadCountProvider = Provider<int>((ref) {
  final async = ref.watch(notificationsListProvider);
  return async.maybeWhen(
    data: (list) => list.where((e) => !e.isRead).length,
    orElse: () => 0,
  );
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
  }

  Future<void> markAllAsRead() async {
    await repo.markAllAsRead();
  }

  Future<NotificationModel> broadcastNotification({
    required String title,
    required String body,
    required NotificationType type,
  }) async {
    final result = await repo.broadcastNotification(
      title: title,
      body: body,
      type: type,
    );
    // Firestore streams refresh themselves; invalidating also lets an injected
    // in-memory test repository publish the newly created test notification.
    ref.invalidate(notificationsListProvider);
    return result;
  }
}
