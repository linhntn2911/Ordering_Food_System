import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/menu_search_query.dart';

/// Removable labels for the applied filters and sort order, followed by
/// "Xóa bộ lọc" (FR-009). Removing a label takes effect immediately.
class SearchFilterChips extends StatelessWidget {
  const SearchFilterChips({
    super.key,
    required this.filters,
    required this.categoryName,
    required this.onRemoveCategory,
    required this.onRemoveAvailable,
    required this.onRemoveSortOrder,
    required this.onClearAll,
    required this.horizontalPadding,
  });

  final MenuSearchFilters filters;

  /// Name of the selected category, when known.
  final String? categoryName;
  final VoidCallback onRemoveCategory;
  final VoidCallback onRemoveAvailable;
  final VoidCallback onRemoveSortOrder;
  final VoidCallback onClearAll;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final categoryName = this.categoryName;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        children: [
          if (filters.categoryId != null)
            _FilterChip(
              key: const ValueKey('search-chip-category'),
              label: categoryName ?? 'Danh mục',
              onRemove: onRemoveCategory,
            ),
          if (filters.availableOnly)
            _FilterChip(
              key: const ValueKey('search-chip-available'),
              label: 'Chỉ món còn hàng',
              onRemove: onRemoveAvailable,
            ),
          if (filters.sortOrder != MenuSortOrder.relevance)
            _FilterChip(
              key: const ValueKey('search-chip-sort'),
              label: filters.sortOrder.label,
              onRemove: onRemoveSortOrder,
            ),
          TextButton(
            key: const ValueKey('search-clear-filters'),
            onPressed: onClearAll,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryEnd,
              textStyle: AppTextStyles.labelLarge,
              minimumSize: const Size(0, AppSpacing.minTouchTarget),
            ),
            child: const Text('Xóa bộ lọc'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({super.key, required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.p8),
      child: InputChip(
        label: Text(label),
        labelStyle: AppTextStyles.labelLarge.copyWith(
          color: AppColors.primaryEnd,
        ),
        backgroundColor: AppColors.primarySoft,
        side: BorderSide.none,
        onDeleted: onRemove,
        deleteIcon: const Icon(Icons.close_rounded, size: 18),
        deleteIconColor: AppColors.primaryEnd,
        deleteButtonTooltipMessage: 'Bỏ bộ lọc $label',
      ),
    );
  }
}
