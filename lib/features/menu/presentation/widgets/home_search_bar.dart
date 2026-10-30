import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Read-only search entry and filter button.
///
/// Home opens the search screen from [onSearchTap], and the same screen with
/// the filter sheet open from [onFilterTap] (`specs/003-menu-search` FR-002).
class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({
    super.key,
    required this.onSearchTap,
    required this.onFilterTap,
  });

  static const double height = 56;

  final VoidCallback onSearchTap;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.input);

    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: 'Tìm kiếm món',
            excludeSemantics: true,
            child: Material(
              color: AppColors.warningSurface,
              borderRadius: radius,
              child: InkWell(
                key: const ValueKey('home-search'),
                onTap: onSearchTap,
                borderRadius: radius,
                child: SizedBox(
                  height: height,
                  child: Row(
                    children: [
                      const SizedBox(width: AppSpacing.lg),
                      const Icon(
                        Icons.search_rounded,
                        size: 24,
                        color: AppColors.foodAccentDark,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Bạn muốn ăn gì?',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Material(
          color: AppColors.warningSurface,
          borderRadius: radius,
          child: InkWell(
            key: const ValueKey('home-filter'),
            onTap: onFilterTap,
            borderRadius: radius,
            child: const SizedBox.square(
              dimension: height,
              child: Icon(
                Icons.tune_rounded,
                size: 24,
                color: AppColors.foodAccentDark,
                semanticLabel: 'Bộ lọc',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
