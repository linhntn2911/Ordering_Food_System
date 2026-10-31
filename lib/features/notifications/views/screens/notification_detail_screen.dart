import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:oder_food/core/constants/app_colors.dart';
import 'package:oder_food/core/constants/app_routes.dart';
import 'package:oder_food/features/notifications/models/notification_model.dart';
import 'package:oder_food/features/notifications/providers/notification_provider.dart';

class NotificationDetailScreen extends ConsumerWidget {
  const NotificationDetailScreen({super.key, required this.notificationId, this.orderId = ''});
  final String notificationId;
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary)),
        title: const Text('Chi tiết thông báo', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('Lỗi: $err')),
        data: (notifications) {
          NotificationModel? n;
          for (final item in notifications) {
            if (item.id == notificationId) {
              n = item;
              break;
            }
          }
          if (n == null) {
            return const Center(child: Text('Không tìm thấy thông báo'));
          }
          final notification = n!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notification.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      Text(DateFormat('HH:mm - dd/MM/yyyy').format(notification.createdAt), style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      Text(notification.body, style: const TextStyle(color: AppColors.textPrimary, height: 1.5)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if ((notification.orderId != null && notification.orderId!.isNotEmpty) || orderId.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final id = notification.orderId ?? orderId;
                        context.push('${AppRoutes.orderDetail}?orderId=$id');
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text('Xem đơn hàng liên quan'),
                    ),
                  )
              ],
            ),
          );
        },
      ),
    );
  }
}
