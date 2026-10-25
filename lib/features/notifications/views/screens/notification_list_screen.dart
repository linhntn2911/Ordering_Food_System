import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:oder_food/core/constants/app_colors.dart';
import 'package:oder_food/core/constants/app_routes.dart';
import 'package:oder_food/core/widgets/app_empty_state.dart';
import 'package:oder_food/features/notifications/models/notification_model.dart';
import 'package:oder_food/features/notifications/providers/notification_provider.dart';

class NotificationListScreen extends ConsumerWidget {
  const NotificationListScreen({super.key});

  IconData _icon(NotificationType type) {
    switch (type) {
      case NotificationType.orderUpdate:
        return Icons.local_shipping_outlined;
      case NotificationType.promo:
        return Icons.local_offer_outlined;
      case NotificationType.system:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsListProvider);
    final actions = ref.watch(notificationActionsProvider);
    final unread = ref.watch(unreadCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary)),
        title: const Text('Thông báo', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: actions.markAllAsRead,
              child: const Text('Đánh dấu tất cả đã đọc', style: TextStyle(color: AppColors.primary)),
            )
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('Lỗi: $err')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const AppEmptyState(icon: Icons.notifications_none, title: 'Chưa có thông báo', message: 'Thông báo về đơn hàng và ưu đãi sẽ hiển thị tại đây');
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.refresh(notificationsListProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final n = notifications[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    await actions.markAsRead(n.id);
                    if (n.orderId != null && n.orderId!.isNotEmpty) {
                      context.push('${AppRoutes.notificationDetail}?notificationId=${n.id}&orderId=${n.orderId}');
                    } else {
                      context.push('${AppRoutes.notificationDetail}?notificationId=${n.id}');
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(color: n.isRead ? AppColors.surface : AppColors.primary.withOpacity(0.04), borderRadius: BorderRadius.circular(16), border: Border.all(color: n.isRead ? AppColors.border : AppColors.primary.withOpacity(0.4))),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), shape: BoxShape.circle),
                          child: Icon(_icon(n.type), color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(n.title, style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                                  if (!n.isRead) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary)),
                              const SizedBox(height: 6),
                              Text(DateFormat('HH:mm - dd/MM/yyyy').format(n.createdAt), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        )
                      ],
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
