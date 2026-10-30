import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/food_card.dart';
import '../../domain/entities/menu_item.dart';

/// Vertical "Phổ biến" list; renders nothing when [items] is empty.
class PopularSection extends StatelessWidget {
  const PopularSection({super.key, required this.items, this.onItemTap});

  final List<MenuItem> items;
  final ValueChanged<MenuItem>? onItemTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final onItemTap = this.onItemTap;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: const Text('Phổ biến', style: AppTextStyles.titleLarge),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: FoodCard(
              key: ValueKey('popular-${item.id}'),
              item: item,
              onTap: onItemTap == null ? null : () => onItemTap(item),
            ),
          ),
      ],
    );
  }
}
