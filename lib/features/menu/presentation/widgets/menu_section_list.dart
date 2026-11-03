import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/food_card.dart';
import '../../domain/entities/menu_item.dart';
import '../viewmodels/home_menu_state.dart';

/// Sliver list of menu items, optionally grouped under category headers.
class MenuSectionList extends StatelessWidget {
  const MenuSectionList({
    super.key,
    required this.sections,
    required this.showHeaders,
    required this.isLoadingMore,
    this.onItemTap,
  });

  final List<MenuSection> sections;
  final bool showHeaders;
  final bool isLoadingMore;
  final ValueChanged<MenuItem>? onItemTap;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    final onItemTap = this.onItemTap;

    for (final section in sections) {
      if (showHeaders) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.p24,
              bottom: AppSpacing.p12,
            ),
            child: Semantics(
              header: true,
              child: Text(
                section.title,
                style: AppTextStyles.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      }
      for (final item in section.items) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.p12),
            child: FoodCard(
              key: ValueKey('food-card-${item.id}'),
              item: item,
              onTap: onItemTap == null ? null : () => onItemTap(item),
            ),
          ),
        );
      }
    }

    if (isLoadingMore) {
      rows.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.p16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return SliverList.list(children: rows);
  }
}
