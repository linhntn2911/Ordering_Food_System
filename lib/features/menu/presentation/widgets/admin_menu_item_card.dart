import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/menu_item.dart';

class AdminMenuItemCard extends StatelessWidget {
  const AdminMenuItemCard({
    required this.item,
    required this.categoryName,
    required this.actionsEnabled,
    required this.onAvailabilityChanged,
    required this.onPublishedChanged,
    required this.onEdit,
    super.key,
  });

  final MenuItem item;
  final String categoryName;
  final bool actionsEnabled;
  final ValueChanged<bool> onAvailabilityChanged;
  final ValueChanged<bool> onPublishedChanged;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: actionsEnabled ? 1 : 0.62,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MenuImage(imageUrl: item.imageUrl),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        categoryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        CurrencyFormatter.vnd(item.basePrice),
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.primaryEnd,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit ${item.name}',
                  onPressed: actionsEnabled ? onEdit : null,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primarySoft,
                    foregroundColor: AppColors.primaryEnd,
                  ),
                  icon: const Icon(Icons.edit_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1, color: AppColors.surfaceMuted),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _StatusButton(
                    label: item.isAvailable ? 'Available' : 'Sold out',
                    icon: item.isAvailable
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    active: item.isAvailable,
                    enabled: actionsEnabled,
                    onPressed: () => onAvailabilityChanged(!item.isAvailable),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _StatusButton(
                    label: item.isPublished ? 'Published' : 'Hidden',
                    icon: item.isPublished
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    active: item.isPublished,
                    enabled: actionsEnabled,
                    onPressed: () => onPublishedChanged(!item.isPublished),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool active;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: active ? AppColors.primaryEnd : AppColors.textMuted,
        backgroundColor: active
            ? AppColors.primarySoft
            : AppColors.surfaceMuted,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
        ),
      ),
      icon: Icon(icon, size: 17),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.labelSmall,
      ),
    );
  }
}

class _MenuImage extends StatelessWidget {
  const _MenuImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    Widget fallback() => const DecoratedBox(
      decoration: BoxDecoration(color: AppColors.warningSurface),
      child: Center(
        child: Icon(Icons.fastfood_rounded, size: 30, color: AppColors.warning),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.medium),
      child: SizedBox.square(
        dimension: 80,
        child: imageUrl.isEmpty
            ? fallback()
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback(),
              ),
      ),
    );
  }
}
