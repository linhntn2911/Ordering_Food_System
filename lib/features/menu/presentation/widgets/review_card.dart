import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/food_card.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../../reviews/domain/entities/review.dart';
import 'review_image_viewer.dart';

/// One review: author label, stars, date, edited label, comment folded to
/// four lines and image thumbnails.
class ReviewCard extends StatefulWidget {
  const ReviewCard({super.key, required this.review});

  static const int collapsedLines = 4;
  static const double thumbnailSize = 64;

  final Review review;

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final review = widget.review;

    return Container(
      key: ValueKey('review-${review.id}'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.surfaceMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(review.authorLabel, style: AppTextStyles.titleMedium),
              Text(
                formatReviewDate(review.createdAt),
                style: AppTextStyles.bodySmall,
              ),
              if (review.isEdited)
                Text(
                  'Đã chỉnh sửa',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          RatingStars(rating: review.rating.toDouble(), size: 14),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _Comment(
              text: review.comment,
              expanded: _expanded,
              onToggle: () => setState(() => _expanded = !_expanded),
            ),
          ],
          if (review.imageUrls.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (var i = 0; i < review.imageUrls.length; i++)
                  _Thumbnail(
                    key: ValueKey('review-${review.id}-image-$i'),
                    url: review.imageUrls[i],
                    label: 'Ảnh ${i + 1} của đánh giá',
                    onTap: () => showReviewImageViewer(
                      context,
                      imageUrls: review.imageUrls,
                      initialIndex: i,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Comment extends StatelessWidget {
  const _Comment({
    required this.text,
    required this.expanded,
    required this.onToggle,
  });

  final String text;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final style = AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        );
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: ReviewCard.collapsedLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;
        painter.dispose();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: style,
              maxLines: expanded ? null : ReviewCard.collapsedLines,
              overflow: expanded ? null : TextOverflow.ellipsis,
            ),
            if (overflows)
              TextButton(
                onPressed: onToggle,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryEnd,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, AppSpacing.minTouchTarget),
                  textStyle: AppTextStyles.labelLarge,
                ),
                child: Text(expanded ? 'Thu gọn' : 'Xem thêm'),
              ),
          ],
        );
      },
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    super.key,
    required this.url,
    required this.label,
    required this.onTap,
  });

  final String url;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.medium);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: ClipRRect(
          borderRadius: radius,
          child: SizedBox.square(
            dimension: ReviewCard.thumbnailSize,
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const FoodImagePlaceholder(),
            ),
          ),
        ),
      ),
    );
  }
}
