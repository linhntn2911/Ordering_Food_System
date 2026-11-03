import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ordering_food_system/app/router.dart';
import 'package:ordering_food_system/core/theme/app_colors.dart';
import 'package:ordering_food_system/core/theme/app_gradients.dart';
import 'package:ordering_food_system/core/theme/app_radii.dart';
import 'package:ordering_food_system/core/theme/app_shadows.dart';
import 'package:ordering_food_system/core/theme/app_spacing.dart';
import 'package:ordering_food_system/core/theme/app_text_styles.dart';
import 'package:ordering_food_system/core/utils/currency_formatter.dart';
import 'package:ordering_food_system/core/utils/navigation_extensions.dart';
import 'package:ordering_food_system/features/order_history/data/models/order_model.dart';

class OrderHistoryCard extends StatelessWidget {
  const OrderHistoryCard({super.key, required this.order, this.isReviewed = false});
  final bool isReviewed;

  final OrderModel order;

  _OrderStatusVisual _statusVisual(OrderStatus status) => switch (status) {
    OrderStatus.pending => const _OrderStatusVisual(
      label: 'Đã đặt',
      foreground: AppColors.warning,
      background: AppColors.warningSurface,
    ),
    OrderStatus.confirmed => const _OrderStatusVisual(
      label: 'Đã xác nhận',
      foreground: AppColors.primaryEnd,
      background: AppColors.primarySoft,
    ),
    OrderStatus.preparing => const _OrderStatusVisual(
      label: 'Đang chuẩn bị',
      foreground: AppColors.primaryEnd,
      background: AppColors.primarySoft,
    ),
    OrderStatus.delivering => const _OrderStatusVisual(
      label: 'Đang giao',
      foreground: AppColors.info,
      background: Color(0x1A25A0B0),
    ),
    OrderStatus.completed => const _OrderStatusVisual(
      label: 'Đã hoàn thành',
      foreground: AppColors.success,
      background: AppColors.successSoft,
    ),
    OrderStatus.cancelled => const _OrderStatusVisual(
      label: 'Đã hủy',
      foreground: AppColors.error,
      background: AppColors.errorSoft,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final status = _statusVisual(order.status);
    final primaryItem = order.items.isEmpty ? null : order.items.first;

    return InkWell(
      borderRadius: AppRadii.radiusCard,
      onTap: () =>
          context.push('${AppRoutes.orderDetail}?orderId=${order.orderId}'),
      child: Ink(
        padding: const EdgeInsets.all(AppSpacing.s16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.radiusCard,
          boxShadow: const [AppShadows.card],
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Mã đơn · ${order.orderId}',
                    style: AppTextStyles.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                _StatusChip(status: status),
              ],
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              DateFormat('HH:mm · dd/MM/yyyy').format(order.createdAt),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.s12),
              child: Divider(height: 1, color: AppColors.borderLight),
            ),
            Row(
              children: [
                ClipRRect(
                  borderRadius: AppRadii.radiusMedium,
                  child: Image.network(
                    primaryItem?.imageUrl ?? '',
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 64,
                      height: 64,
                      color: AppColors.primarySoft,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.restaurant_rounded,
                        color: AppColors.primaryEnd,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        primaryItem?.name ?? 'Đơn hàng Ngô Chicken',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        order.items.length == 1
                            ? '${order.itemCount} món'
                            : '+${order.items.length - 1} món khác · ${order.itemCount} món',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                Text(
                  CurrencyFormatter.formatVND(order.totalPrice),
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.primaryEnd,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push(
                      '${AppRoutes.orderDetail}?orderId=${order.orderId}',
                    ),
                    child: const Text('Xem chi tiết'),
                  ),
                ),
                if (order.status.isCompleted || order.status.isOngoing) ...[
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: isReviewed ? null : AppGradients.primary,
                        color: isReviewed ? AppColors.surfaceMuted : null,
                        borderRadius: AppRadii.radiusMedium,
                      ),
                      child: ElevatedButton(
                        onPressed: isReviewed
                            ? null
                            : () => context.push(
                                order.status.isCompleted
                                    ? '${AppRoutes.writeReview}?orderId=${order.orderId}'
                                    : '${AppRoutes.orderTracking}?orderId=${order.orderId}',
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                        ),
                        child: Text(
                          order.status.isCompleted
                              ? (isReviewed ? 'Đã đánh giá' : 'Đánh giá')
                              : 'Theo dõi đơn',
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderStatusVisual {
  const _OrderStatusVisual({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final _OrderStatusVisual status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: AppRadii.radiusPill,
      ),
      child: Text(
        status.label,
        style: AppTextStyles.labelSmall.copyWith(color: status.foreground),
      ),
    );
  }
}
