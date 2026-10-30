import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/vnd_format.dart';
import '../../domain/entities/item_selection.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/entities/menu_option.dart';

/// "Chọn size" (single choice) and "Topping" (multiple choice) with their
/// extra prices (`contracts/food_details_ui.md`). Hidden when the item has
/// neither.
class ItemOptionSection extends StatelessWidget {
  const ItemOptionSection({
    super.key,
    required this.item,
    required this.selection,
    required this.enabled,
    required this.onSizeSelected,
    required this.onToppingToggled,
  });

  final MenuItem item;
  final ItemSelection selection;

  /// False for sold-out items: options stay visible but cannot be chosen.
  final bool enabled;
  final ValueChanged<String> onSizeSelected;
  final ValueChanged<String> onToppingToggled;

  @override
  Widget build(BuildContext context) {
    if (item.sizes.isEmpty && item.toppings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (item.sizes.isNotEmpty) ...[
          const _SectionTitle('Chọn size'),
          for (final size in item.sizes)
            _OptionRow(
              key: ValueKey('detail-size-${size.id}'),
              option: size,
              selected: selection.sizeId == size.id,
              multiple: false,
              enabled: enabled,
              onTap: () => onSizeSelected(size.id),
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (item.toppings.isNotEmpty) ...[
          const _SectionTitle('Topping'),
          for (final topping in item.toppings)
            _OptionRow(
              key: ValueKey('detail-topping-${topping.id}'),
              option: topping,
              selected: selection.toppingIds.contains(topping.id),
              multiple: true,
              enabled: enabled,
              onTap: () => onToppingToggled(topping.id),
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
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
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Semantics(
        header: true,
        child: Text(text, style: AppTextStyles.titleMedium),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    super.key,
    required this.option,
    required this.selected,
    required this.multiple,
    required this.enabled,
    required this.onTap,
  });

  final MenuOption option;
  final bool selected;
  final bool multiple;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = multiple
        ? (selected
              ? Icons.check_box_rounded
              : Icons.check_box_outline_blank_rounded)
        : (selected
              ? Icons.radio_button_checked_rounded
              : Icons.radio_button_unchecked_rounded);
    final color = !enabled
        ? AppColors.border
        : selected
        ? AppColors.primaryEnd
        : AppColors.textMuted;
    final extra = option.priceDelta == 0
        ? null
        : '+${formatVnd(option.priceDelta)}';

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: [option.name, ?extra, if (!enabled) 'không khả dụng'].join(', '),
      excludeSemantics: true,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          child: Row(
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  option.name,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: enabled
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                ),
              ),
              if (extra != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  extra,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: enabled
                        ? AppColors.textSecondary
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
