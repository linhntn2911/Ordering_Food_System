import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/menu_category.dart';

/// Horizontal single-select cards: "Tất cả" followed by published categories.
class CategoryCardList extends StatelessWidget {
  const CategoryCardList({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
    required this.horizontalPadding,
  });

  static const allLabel = 'Tất cả';

  final List<MenuCategory> categories;

  /// `null` selects "Tất cả".
  final String? selectedCategoryId;
  final ValueChanged<String?> onSelected;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        AppSpacing.xs,
        horizontalPadding,
        AppSpacing.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategoryCard(
            key: const ValueKey('category-chip-all'),
            label: allLabel,
            icon: Icons.restaurant_menu_rounded,
            selected: selectedCategoryId == null,
            onTap: () => onSelected(null),
          ),
          for (final category in categories)
            CategoryCard(
              key: ValueKey('category-chip-${category.id}'),
              label: category.name,
              icon: categoryIcon(category.name),
              selected: selectedCategoryId == category.id,
              onTap: () => onSelected(category.id),
            ),
        ],
      ),
    );
  }

  /// Picks an icon from keywords in the category name.
  static IconData categoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('combo')) return Icons.fastfood_rounded;
    if (lower.contains('gà')) return Icons.set_meal_rounded;
    if (lower.contains('cơm')) return Icons.rice_bowl_rounded;
    if (lower.contains('mỳ') || lower.contains('mì')) {
      return Icons.ramen_dining_rounded;
    }
    if (lower.contains('ăn vặt')) return Icons.tapas_rounded;
    if (lower.contains('trà') || lower.contains('latte')) {
      return Icons.emoji_food_beverage_rounded;
    }
    if (lower.contains('sữa')) return Icons.icecream_rounded;
    if (lower.contains('uống') ||
        lower.contains('nước') ||
        lower.contains('sinh tố')) {
      return Icons.local_drink_rounded;
    }
    return Icons.restaurant_rounded;
  }
}

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  static const double width = 96;

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.card);

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.md),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        onTap: onTap,
        child: Material(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: radius,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Ink(
              width: width,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: selected ? AppColors.primaryEnd : AppColors.surface,
                  width: 1.5,
                ),
                boxShadow: const [AppShadows.card],
              ),
              child: Column(
                children: [
                  Container(
                    width: AppSpacing.minTouchTarget,
                    height: AppSpacing.minTouchTarget,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.surface
                          : AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 24, color: AppColors.primaryEnd),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    label,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: selected
                          ? AppColors.primaryEnd
                          : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
