import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Top bar of the search screen: back button, keyword field with a clear
/// button, and the filter button (`contracts/search_screen_ui.md`).
class SearchInputBar extends StatelessWidget {
  const SearchInputBar({
    super.key,
    required this.controller,
    required this.autofocus,
    required this.hasActiveFilters,
    required this.onBack,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.onFilterTap,
  });

  static const double height = 56;

  final TextEditingController controller;
  final bool autofocus;

  /// Shows a dot on the filter button when filters differ from the defaults.
  final bool hasActiveFilters;
  final VoidCallback onBack;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.input);
    final border = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide.none,
    );

    return Row(
      children: [
        _RoundButton(
          key: const ValueKey('search-back'),
          icon: Icons.arrow_back_ios_new_rounded,
          label: 'Quay lại',
          onTap: onBack,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Semantics(
            label: 'Tìm kiếm món',
            child: TextField(
              key: const ValueKey('search-input'),
              controller: controller,
              autofocus: autofocus,
              textInputAction: TextInputAction.search,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              cursorColor: AppColors.foodAccentDark,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.warningSurface,
                hintText: 'Bạn muốn ăn gì?',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.lg,
                ),
                constraints: const BoxConstraints(minHeight: height),
                border: border,
                enabledBorder: border,
                focusedBorder: border,
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 24,
                  color: AppColors.foodAccentDark,
                ),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) {
                    if (value.text.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return IconButton(
                      key: const ValueKey('search-clear'),
                      onPressed: onClear,
                      tooltip: 'Xóa từ khóa',
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textMuted,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: AppColors.warningSurface,
              borderRadius: radius,
              child: InkWell(
                key: const ValueKey('search-filter'),
                onTap: onFilterTap,
                borderRadius: radius,
                child: const SizedBox.square(
                  dimension: AppSpacing.minTouchTarget,
                  child: Icon(
                    Icons.tune_rounded,
                    size: 24,
                    color: AppColors.foodAccentDark,
                    semanticLabel: 'Bộ lọc',
                  ),
                ),
              ),
            ),
            if (hasActiveFilters)
              const Positioned(
                top: AppSpacing.xs,
                right: AppSpacing.xs,
                child: _ActiveDot(),
              ),
          ],
        ),
      ],
    );
  }
}

class _ActiveDot extends StatelessWidget {
  const _ActiveDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('search-filter-active'),
      width: AppSpacing.sm,
      height: AppSpacing.sm,
      decoration: const BoxDecoration(
        color: AppColors.primaryEnd,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [AppShadows.card],
      ),
      child: Material(
        color: AppColors.surface,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: AppSpacing.minTouchTarget,
            child: Icon(
              icon,
              size: 20,
              color: AppColors.foodAccentDark,
              semanticLabel: label,
            ),
          ),
        ),
      ),
    );
  }
}
