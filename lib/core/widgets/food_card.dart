import 'package:flutter/material.dart';

import '../../features/menu/domain/entities/menu_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/vnd_format.dart';

/// Shared menu item card for Home, Search, Favorites and Admin lists.
///
/// Follows the Food Ninja "Popular Menu" row: image on the left; name,
/// rating and sold-out label in the middle; price right-aligned.
class FoodCard extends StatelessWidget {
  const FoodCard({super.key, required this.item, this.onTap});

  static const double imageSize = 64;
  static const double priceWidth = 88;

  final MenuItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final range = item.priceRange;
    final price = formatVndRange(range.min, range.max);
    final rating = ratingLabel(item);
    final availability = item.isAvailable ? 'Còn hàng' : 'Hết hàng';

    return Semantics(
      button: onTap != null,
      onTap: onTap,
      label: '${item.name}, $price, $rating, $availability',
      excludeSemantics: true,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.card),
              boxShadow: const [AppShadows.card],
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSpacing.minTouchTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    _FoodImage(url: item.imageUrl),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: AppTextStyles.titleMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              if (item.hasRating) ...[
                                const Icon(
                                  Icons.star_rounded,
                                  size: 20,
                                  color: AppColors.warning,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                              ],
                              Flexible(
                                child: Text(
                                  rating,
                                  style: AppTextStyles.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (!item.isAvailable) ...[
                            const SizedBox(height: AppSpacing.sm),
                            const SoldOutLabel(),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Right-aligned price that may wrap but is never clipped.
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: priceWidth),
                      child: Text(
                        price,
                        style: AppTextStyles.price,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// "4,6 (23)" or "Chưa có đánh giá".
  static String ratingLabel(MenuItem item) {
    if (!item.hasRating) {
      return 'Chưa có đánh giá';
    }
    final average = item.ratingAverage.toStringAsFixed(1).replaceAll('.', ',');
    return '$average (${item.reviewCount})';
  }
}

/// Text label for sold-out items; never relies on color alone.
class SoldOutLabel extends StatelessWidget {
  const SoldOutLabel({super.key, this.text = 'Hết hàng'});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(color: AppColors.error),
      ),
    );
  }
}

class _FoodImage extends StatelessWidget {
  const _FoodImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.medium),
      child: SizedBox.square(
        dimension: FoodCard.imageSize,
        child: url.isEmpty
            ? const FoodImagePlaceholder()
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const FoodImagePlaceholder(),
              ),
      ),
    );
  }
}

/// Shown when an item has no image or the image fails to load.
class FoodImagePlaceholder extends StatelessWidget {
  const FoodImagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.surfaceMuted,
      child: Center(
        child: Icon(
          Icons.restaurant_rounded,
          size: 28,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
