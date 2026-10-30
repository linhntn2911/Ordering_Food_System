import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/menu_category.dart';
import '../../domain/entities/menu_search_query.dart';

/// Opens the filter sheet and resolves to the filters confirmed with
/// "Áp dụng", or null when the sheet is dismissed (FR-016).
///
/// [categories] is listenable so the sheet follows category updates while
/// it is open.
Future<MenuSearchFilters?> showSearchFilterSheet(
  BuildContext context, {
  required MenuSearchFilters initial,
  required ValueListenable<List<MenuCategory>> categories,
}) {
  return showModalBottomSheet<MenuSearchFilters>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.85,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadii.dialog),
      ),
    ),
    builder: (_) => ValueListenableBuilder<List<MenuCategory>>(
      valueListenable: categories,
      builder: (_, categories, _) =>
          SearchFilterSheet(initial: initial, categories: categories),
    ),
  );
}

/// Category, availability and sort choices. Choices stay a draft until
/// "Áp dụng"; "Đặt lại" only resets the draft.
class SearchFilterSheet extends StatefulWidget {
  const SearchFilterSheet({
    super.key,
    required this.initial,
    required this.categories,
  });

  final MenuSearchFilters initial;
  final List<MenuCategory> categories;

  @override
  State<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<SearchFilterSheet> {
  late MenuSearchFilters _draft = widget.initial;

  void _update(MenuSearchFilters draft) => setState(() => _draft = draft);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.p24,
              0,
              AppSpacing.p24,
              AppSpacing.p16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: const Text('Bộ lọc', style: AppTextStyles.titleLarge),
                ),
                const SizedBox(height: AppSpacing.p20),
                const _SectionTitle('Danh mục'),
                Wrap(
                  spacing: AppSpacing.p8,
                  runSpacing: AppSpacing.p8,
                  children: [
                    _Choice(
                      key: const ValueKey('filter-category-all'),
                      label: 'Tất cả',
                      selected: _draft.categoryId == null,
                      onSelected: () =>
                          _update(_draft.copyWith(clearCategory: true)),
                    ),
                    for (final category in widget.categories)
                      _Choice(
                        key: ValueKey('filter-category-${category.id}'),
                        label: category.name,
                        selected: _draft.categoryId == category.id,
                        onSelected: () =>
                            _update(_draft.copyWith(categoryId: category.id)),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.p20),
                const _SectionTitle('Tình trạng'),
                SwitchListTile(
                  key: const ValueKey('filter-available'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Chỉ món còn hàng',
                    style: AppTextStyles.bodyLarge,
                  ),
                  value: _draft.availableOnly,
                  activeThumbColor: AppColors.surface,
                  activeTrackColor: AppColors.primaryEnd,
                  onChanged: (value) =>
                      _update(_draft.copyWith(availableOnly: value)),
                ),
                const SizedBox(height: AppSpacing.p16),
                const _SectionTitle('Sắp xếp'),
                Wrap(
                  spacing: AppSpacing.p8,
                  runSpacing: AppSpacing.p8,
                  children: [
                    for (final order in MenuSortOrder.values)
                      _Choice(
                        key: ValueKey('filter-sort-${order.name}'),
                        label: order.label,
                        selected: _draft.sortOrder == order,
                        onSelected: () =>
                            _update(_draft.copyWith(sortOrder: order)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.p24,
              AppSpacing.p8,
              AppSpacing.p24,
              AppSpacing.p16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('filter-reset'),
                    onPressed: () => _update(MenuSearchFilters.defaults),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, AppSpacing.minTouchTarget),
                      foregroundColor: AppColors.primaryEnd,
                      side: const BorderSide(color: AppColors.primaryEnd),
                      textStyle: AppTextStyles.labelLarge,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.input),
                      ),
                    ),
                    child: const Text('Đặt lại'),
                  ),
                ),
                const SizedBox(width: AppSpacing.p12),
                Expanded(
                  child: _GradientButton(
                    key: const ValueKey('filter-apply'),
                    label: 'Áp dụng',
                    onTap: () => Navigator.of(context).pop(_draft),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.p8),
      child: Text(text, style: AppTextStyles.titleMedium),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      labelStyle: AppTextStyles.labelLarge.copyWith(
        color: selected ? AppColors.primaryEnd : AppColors.textPrimary,
      ),
      side: BorderSide(
        color: selected ? AppColors.primaryEnd : AppColors.border,
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.input);

    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppGradients.primary,
            borderRadius: radius,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSpacing.minTouchTarget,
              ),
              child: Center(
                child: Text(
                  label,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.surface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
