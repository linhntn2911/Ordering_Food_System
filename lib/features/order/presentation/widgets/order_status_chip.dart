import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/order_status.dart';

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({required this.status, super.key});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (foreground, background, icon) = switch (status) {
      OrderStatus.pending => (
        AppColors.warning,
        AppColors.warningSurface,
        Icons.schedule_rounded,
      ),
      OrderStatus.confirmed => (
        AppColors.primaryEnd,
        AppColors.primarySoft,
        Icons.check_circle_outline_rounded,
      ),
      OrderStatus.preparing => (
        AppColors.primarySolid,
        AppColors.primaryTint,
        Icons.soup_kitchen_rounded,
      ),
      OrderStatus.outForDelivery => (
        AppColors.info,
        AppColors.info.withValues(alpha: 0.12),
        Icons.delivery_dining_rounded,
      ),
      OrderStatus.completed => (
        AppColors.success,
        AppColors.successSoft,
        Icons.task_alt_rounded,
      ),
      OrderStatus.cancelled => (
        AppColors.error,
        AppColors.errorSoft,
        Icons.cancel_outlined,
      ),
      OrderStatus.rejected => (
        AppColors.error,
        AppColors.errorSoft,
        Icons.block_rounded,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: foreground),
          const SizedBox(width: AppSpacing.xxs),
          Flexible(
            child: Text(
              status.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
