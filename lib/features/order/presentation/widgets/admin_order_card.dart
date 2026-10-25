import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_time_formatter.dart';
import '../../domain/entities/food_order.dart';
import 'order_status_chip.dart';

class AdminOrderCard extends StatelessWidget {
  const AdminOrderCard({required this.order, this.onTap, super.key});

  final FoodOrder order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.orderCode, style: AppTextStyles.titleMedium),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          DateTimeFormatter.orderTime(order.createdAt),
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: OrderStatusChip(status: order.status),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1, color: AppColors.surfaceMuted),
              const SizedBox(height: AppSpacing.sm),
              _InfoLine(
                icon: Icons.person_outline_rounded,
                text: order.customerName,
              ),
              const SizedBox(height: AppSpacing.xs),
              _InfoLine(
                icon: Icons.phone_outlined,
                text: order.customerPhone.isEmpty
                    ? 'No phone number'
                    : order.customerPhone,
              ),
              const SizedBox(height: AppSpacing.xs),
              _InfoLine(
                icon: Icons.location_on_outlined,
                text: order.deliveryAddress.isEmpty
                    ? 'No delivery address'
                    : order.deliveryAddress,
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppRadii.small),
                    ),
                    child: Text(
                      order.paymentMethod.toUpperCase(),
                      style: AppTextStyles.labelSmall,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    CurrencyFormatter.vnd(order.totalAmount),
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.primaryEnd,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text, this.maxLines = 1});

  final IconData icon;
  final String text;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: maxLines > 1
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
