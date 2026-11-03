import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ordering_food_system/app/router.dart';
import 'package:ordering_food_system/core/theme/app_colors.dart';
import 'package:ordering_food_system/core/theme/app_radii.dart';
import 'package:ordering_food_system/core/theme/app_shadows.dart';
import 'package:ordering_food_system/core/theme/app_spacing.dart';
import 'package:ordering_food_system/core/theme/app_text_styles.dart';
import 'package:ordering_food_system/core/utils/navigation_extensions.dart';
import 'package:ordering_food_system/features/notifications/models/notification_model.dart';
import 'package:ordering_food_system/features/notifications/providers/notification_provider.dart';

class NotificationListScreen extends ConsumerWidget {
  const NotificationListScreen({super.key});

  _NotificationVisual _visual(NotificationType type) => switch (type) {
    NotificationType.orderUpdate => const _NotificationVisual(
      icon: Icons.receipt_long_rounded,
      color: AppColors.primaryEnd,
      background: AppColors.primarySoft,
    ),
    NotificationType.promo => const _NotificationVisual(
      icon: Icons.local_offer_rounded,
      color: AppColors.warning,
      background: AppColors.warningSurface,
    ),
    NotificationType.system => const _NotificationVisual(
      icon: Icons.info_outline_rounded,
      color: AppColors.info,
      background: Color(0x1A25A0B0),
    ),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsListProvider);
    final actions = ref.watch(notificationActionsProvider);
    final unread = ref.watch(unreadCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thông báo', style: AppTextStyles.headlineMedium),
        leading: IconButton(
          tooltip: 'Quay lại',
          onPressed: context.pop,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        actions: [
          if (unread > 0)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.s12),
              child: TextButton(
                onPressed: () async {
                  try {
                    await actions.markAllAsRead();
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error.toString())));
                    }
                  }
                },
                child: const Text('Đánh dấu đã đọc'),
              ),
            ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryEnd),
        ),
        error: (error, _) => _ErrorState(
          message: 'Không thể tải thông báo. Vui lòng thử lại.',
          onRetry: () => ref.invalidate(notificationsListProvider),
        ),
        data: (notifications) {
          if (notifications.isEmpty) return const _EmptyNotifications();
          return RefreshIndicator(
            color: AppColors.primaryEnd,
            onRefresh: () async => ref.invalidate(notificationsListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s24,
                AppSpacing.s16,
                AppSpacing.s24,
                AppSpacing.s32,
              ),
              itemCount: notifications.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.s12),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final visual = _visual(notification.type);
                return Semantics(
                  button: true,
                  label: notification.title,
                  child: InkWell(
                    borderRadius: AppRadii.radiusCard,
                    onTap: () async {
                      if (!notification.isRead) {
                        await actions.markAsRead(notification.id);
                      }
                      if (!context.mounted) return;
                      final orderId = notification.orderId;
                      final suffix = orderId == null || orderId.isEmpty
                          ? ''
                          : '&orderId=$orderId';
                      context.push(
                        '${AppRoutes.notificationDetail}?notificationId=${notification.id}$suffix',
                      );
                    },
                    child: Ink(
                      padding: const EdgeInsets.all(AppSpacing.s16),
                      decoration: BoxDecoration(
                        color: notification.isRead
                            ? AppColors.surface
                            : AppColors.primaryTint,
                        borderRadius: AppRadii.radiusCard,
                        border: Border.all(
                          color: notification.isRead
                              ? AppColors.borderLight
                              : AppColors.primaryEnd.withValues(alpha: 0.38),
                        ),
                        boxShadow: const [AppShadows.card],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: visual.background,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(visual.icon, color: visual.color),
                          ),
                          const SizedBox(width: AppSpacing.s12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notification.title,
                                        style: AppTextStyles.titleMedium,
                                      ),
                                    ),
                                    if (!notification.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primaryEnd,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.s4),
                                Text(
                                  notification.body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.s8),
                                Text(
                                  DateFormat('HH:mm · dd/MM/yyyy')
                                      .format(notification.createdAt),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationVisual {
  const _NotificationVisual({
    required this.icon,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final Color color;
  final Color background;
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 42,
                color: AppColors.primaryEnd,
              ),
            ),
            const SizedBox(height: AppSpacing.s20),
            const Text('Chưa có thông báo', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Cập nhật về đơn hàng của bạn sẽ xuất hiện tại đây.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 44,
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.s16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
