import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/category.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    required this.category,
    required this.position,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.actionsEnabled,
    required this.onEdit,
    required this.onViewItems,
    required this.onPublishedChanged,
    required this.onMoveUp,
    required this.onMoveDown,
    super.key,
  });

  final Category category;
  final int position;
  final bool canMoveUp;
  final bool canMoveDown;
  final bool actionsEnabled;
  final VoidCallback onEdit;
  final VoidCallback onViewItems;
  final ValueChanged<bool> onPublishedChanged;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: actionsEnabled ? 1 : 0.62,
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
              children: [
                _CategoryImage(imageUrl: category.imageUrl),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _PublicationChip(isPublished: category.isPublished),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Semantics(
                  label: category.isPublished
                      ? 'Unpublish ${category.name}'
                      : 'Publish ${category.name}',
                  child: Switch.adaptive(
                    value: category.isPublished,
                    onChanged: actionsEnabled ? onPublishedChanged : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1, color: AppColors.surfaceMuted),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: ValueKey('manage-items-${category.id}'),
                onPressed: actionsEnabled ? onViewItems : null,
                icon: const Icon(Icons.fastfood_rounded),
                label: const Text('Manage items & prices'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryEnd,
                  backgroundColor: AppColors.primarySoft,
                  side: BorderSide.none,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.medium),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Text('#$position', style: AppTextStyles.labelSmall),
                const Spacer(),
                const SizedBox(width: AppSpacing.xs),
                _CompactIconButton(
                  tooltip: 'Move ${category.name} up',
                  icon: Icons.keyboard_arrow_up_rounded,
                  onPressed: actionsEnabled && canMoveUp ? onMoveUp : null,
                ),
                const SizedBox(width: AppSpacing.xs),
                _CompactIconButton(
                  tooltip: 'Move ${category.name} down',
                  icon: Icons.keyboard_arrow_down_rounded,
                  onPressed: actionsEnabled && canMoveDown ? onMoveDown : null,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                key: ValueKey('edit-category-${category.id}'),
                onPressed: actionsEnabled ? onEdit : null,
                icon: const Icon(Icons.edit_rounded, size: 19),
                label: const Text('Edit category'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublicationChip extends StatelessWidget {
  const _PublicationChip({required this.isPublished});

  final bool isPublished;

  @override
  Widget build(BuildContext context) {
    final color = isPublished ? AppColors.success : AppColors.textMuted;
    final background = isPublished
        ? AppColors.successSoft
        : AppColors.surfaceMuted;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 120;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPublished
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                size: 14,
                color: color,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Flexible(
                child: Text(
                  compact
                      ? (isPublished ? 'On' : 'Off')
                      : (isPublished ? 'Published' : 'Hidden'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall.copyWith(color: color),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CompactIconButton extends StatelessWidget {
  const _CompactIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        backgroundColor: AppColors.surfaceMuted,
        disabledForegroundColor: AppColors.border,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
        ),
      ),
      icon: Icon(icon, size: 22),
    );
  }
}

class _CategoryImage extends StatelessWidget {
  const _CategoryImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    Widget fallback() => const DecoratedBox(
      decoration: BoxDecoration(color: AppColors.primarySoft),
      child: Center(
        child: Icon(
          Icons.restaurant_menu_rounded,
          size: 28,
          color: AppColors.primaryEnd,
        ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.medium),
      child: SizedBox.square(
        dimension: 68,
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
