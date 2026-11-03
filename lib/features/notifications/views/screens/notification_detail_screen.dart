import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ordering_food_system/app/router.dart';
import 'package:ordering_food_system/core/theme/app_colors.dart';
import 'package:ordering_food_system/core/theme/app_gradients.dart';
import 'package:ordering_food_system/core/theme/app_radii.dart';
import 'package:ordering_food_system/core/theme/app_shadows.dart';
import 'package:ordering_food_system/core/theme/app_spacing.dart';
import 'package:ordering_food_system/core/theme/app_text_styles.dart';
import 'package:ordering_food_system/core/utils/navigation_extensions.dart';
import 'package:ordering_food_system/features/notifications/models/notification_model.dart';
import 'package:ordering_food_system/features/notifications/providers/notification_provider.dart';

class NotificationDetailScreen extends ConsumerWidget {
  const NotificationDetailScreen({
    super.key,
    required this.notificationId,
    this.orderId = '',
  });

  final String notificationId;
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Chi tiết thông báo',
          style: AppTextStyles.headlineMedium,
        ),
        leading: IconButton(
          tooltip: 'Quay lại',
          onPressed: context.pop,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: notificationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryEnd),
        ),
        error: (_, _) => const Center(child: Text('Không thể tải thông báo.')),
        data: (notifications) {
          final notification = notifications
              .where((item) => item.id == notificationId)
              .firstOrNull;
          if (notification == null) {
            return const Center(child: Text('Thông báo không còn tồn tại.'));
          }
          return _NotificationDetailBody(
            notification: notification,
            fallbackOrderId: orderId,
          );
        },
      ),
    );
  }
}

class _NotificationDetailBody extends StatelessWidget {
  const _NotificationDetailBody({
    required this.notification,
    required this.fallbackOrderId,
  });

  final NotificationModel notification;
  final String fallbackOrderId;

  @override
  Widget build(BuildContext context) {
    final orderId = notification.orderId?.isNotEmpty == true
        ? notification.orderId!
        : fallbackOrderId;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: AppColors.primaryEnd,
              size: 30,
            ),
          ),
          const SizedBox(height: AppSpacing.s20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.s20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadii.radiusCard,
              boxShadow: const [AppShadows.card],
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification.title, style: AppTextStyles.titleLarge),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  DateFormat('HH:mm · dd/MM/yyyy')
                      .format(notification.createdAt),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.s16),
                  child: Divider(height: 1, color: AppColors.borderLight),
                ),
                Text(notification.body, style: AppTextStyles.bodyLarge),
              ],
            ),
          ),
          if (orderId.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s24),
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: AppRadii.radiusInput,
                ),
                child: ElevatedButton.icon(
                  onPressed: () =>
                      context.push('${AppRoutes.orderDetail}?orderId=$orderId'),
                  icon: const Icon(Icons.receipt_long_rounded),
                  label: const Text('Xem đơn hàng liên quan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
