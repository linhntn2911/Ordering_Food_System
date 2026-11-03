import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../viewmodels/menu_item_detail_state.dart';
import 'review_card.dart';

/// "Đánh giá" with its own loading, empty and error states, so a review
/// failure never hides the item information.
class ReviewSection extends StatelessWidget {
  const ReviewSection({
    super.key,
    required this.reviews,
    required this.reviewCount,
    required this.onLoadMore,
    required this.onRetry,
  });

  final ReviewSectionState reviews;

  /// Total stored on the item, shown next to the title.
  final int reviewCount;
  final VoidCallback onLoadMore;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            reviewCount > 0 ? 'Đánh giá ($reviewCount)' : 'Đánh giá',
            style: AppTextStyles.titleLarge,
          ),
        ),
        const SizedBox(height: AppSpacing.p12),
        ..._content(),
      ],
    );
  }

  List<Widget> _content() {
    switch (reviews.status) {
      case ReviewSectionStatus.loading:
        return [
          Semantics(
            label: 'Đang tải đánh giá',
            child: const Column(
              children: [
                _ReviewSkeleton(),
                SizedBox(height: AppSpacing.p12),
                _ReviewSkeleton(),
              ],
            ),
          ),
        ];
      case ReviewSectionStatus.error:
        return [
          Text(
            'Không tải được đánh giá.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const ValueKey('detail-reviews-retry'),
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryEnd,
                textStyle: AppTextStyles.labelLarge,
                minimumSize: const Size(0, AppSpacing.minTouchTarget),
              ),
              child: const Text('Thử lại'),
            ),
          ),
        ];
      case ReviewSectionStatus.ready when reviews.reviews.isEmpty:
        return [
          Text(
            'Chưa có đánh giá cho món này',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ];
      case ReviewSectionStatus.ready:
        return [
          for (final review in reviews.reviews) ...[
            ReviewCard(review: review),
            const SizedBox(height: AppSpacing.p12),
          ],
          if (reviews.isLoadingMore)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.p8),
                child: CircularProgressIndicator(
                  semanticsLabel: 'Đang tải thêm đánh giá',
                ),
              ),
            )
          else if (reviews.hasMore)
            OutlinedButton(
              key: const ValueKey('detail-more-reviews'),
              onPressed: onLoadMore,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, AppSpacing.minTouchTarget),
                foregroundColor: AppColors.primaryEnd,
                side: const BorderSide(color: AppColors.primaryEnd),
                textStyle: AppTextStyles.labelLarge,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.input),
                ),
              ),
              child: const Text('Xem thêm đánh giá'),
            ),
        ];
    }
  }
}

class _ReviewSkeleton extends StatelessWidget {
  const _ReviewSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
    );
  }
}
