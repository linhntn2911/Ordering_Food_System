import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ordering_food_system/core/theme/app_colors.dart';
import 'package:ordering_food_system/core/theme/app_radii.dart';
import 'package:ordering_food_system/core/theme/app_shadows.dart';
import 'package:ordering_food_system/core/theme/app_spacing.dart';
import 'package:ordering_food_system/core/theme/app_text_styles.dart';
import 'package:ordering_food_system/core/utils/navigation_extensions.dart';
import 'package:ordering_food_system/core/widgets/gradient_button.dart';
import 'package:ordering_food_system/features/review/providers/review_provider.dart';

class WriteReviewScreen extends ConsumerWidget {
  const WriteReviewScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(reviewFormProvider);
    final notifier = ref.read(reviewFormProvider.notifier);
    final requiresComment = form.rating <= 2;
    final missingRequiredComment =
        requiresComment && form.comment.trim().isEmpty;
    final alreadyReviewed = ref
        .watch(reviewedOrderIdsProvider)
        .contains(orderId);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontal = AppSpacing.screenHorizontalFor(
                  constraints.maxWidth,
                );
                return Column(
                  children: [
                    _Header(onBack: context.pop),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          horizontal,
                          AppSpacing.sm,
                          horizontal,
                          AppSpacing.xxl,
                        ),
                        children: [
                          _RatingCard(
                            rating: form.rating,
                            onSelected: notifier.setRating,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _CommentCard(
                            comment: form.comment,
                            required: requiresComment,
                            showError: missingRequiredComment,
                            onChanged: notifier.setComment,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          GradientButton(
                            label: alreadyReviewed
                                ? 'Đã đánh giá'
                                : 'Gửi đánh giá',
                            icon: Icons.send_rounded,
                            isLoading: form.submitting,
                            onPressed:
                                form.submitting ||
                                    missingRequiredComment ||
                                    alreadyReviewed
                                ? null
                                : () => _submit(context, notifier),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Đánh giá của bạn giúp Ngô Chicken cải thiện món ăn và dịch vụ.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(
    BuildContext context,
    ReviewFormNotifier notifier,
  ) async {
    final success = await notifier.submit(orderId);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Đánh giá đã được gửi thành công.'
              : 'Không thể gửi đánh giá. Vui lòng thử lại.',
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.md),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadii.radiusMedium,
        ),
      ),
    );
    if (success) context.pop();
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.sm,
      AppSpacing.xl,
      AppSpacing.sm,
    ),
    child: Row(
      children: [
        IconButton(
          tooltip: 'Quay lại',
          onPressed: onBack,
          style: IconButton.styleFrom(
            foregroundColor: AppColors.primaryEnd,
            backgroundColor: AppColors.primarySoft,
            minimumSize: const Size(48, 48),
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadii.radiusMedium,
            ),
          ),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: AppSpacing.sm),
        const Expanded(
          child: Text('Viết đánh giá', style: AppTextStyles.titleLarge),
        ),
      ],
    ),
  );
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.rating, required this.onSelected});

  final int rating;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.xl),
    decoration: const BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadii.radiusCard,
      boxShadow: [AppShadows.card],
    ),
    child: Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: AppColors.warningSurface,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.star_rounded,
            color: AppColors.warning,
            size: 36,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'Bạn thấy đơn hàng thế nào?',
          textAlign: TextAlign.center,
          style: AppTextStyles.titleLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          _ratingMessage(rating),
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          label: 'Đánh giá $rating trên 5 sao',
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 1; index <= 5; index++)
                  IconButton(
                    tooltip: '$index sao',
                    onPressed: () => onSelected(index),
                    constraints: const BoxConstraints.tightFor(
                      width: 48,
                      height: 48,
                    ),
                    icon: Icon(
                      index <= rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: AppColors.warning,
                      size: 36,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: const BoxDecoration(
            color: AppColors.warningSurface,
            borderRadius: AppRadii.radiusPill,
          ),
          child: Text(
            '$rating/5 sao',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.foodAccentDark,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({
    required this.comment,
    required this.required,
    required this.showError,
    required this.onChanged,
  });

  final String comment;
  final bool required;
  final bool showError;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: const BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadii.radiusCard,
      boxShadow: [AppShadows.card],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.rate_review_rounded,
              color: AppColors.primaryEnd,
              size: 22,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                required ? 'Nhận xét *' : 'Nhận xét (không bắt buộc)',
                style: AppTextStyles.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          maxLength: 500,
          maxLines: 6,
          minLines: 4,
          onChanged: onChanged,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Chia sẻ về món ăn, cách đóng gói hoặc trải nghiệm giao hàng...',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMuted,
            ),
            filled: true,
            fillColor: AppColors.surface,
            counterText: '${comment.length}/500',
            counterStyle: AppTextStyles.bodySmall,
            errorText: showError
                ? 'Vui lòng nhập nhận xét khi đánh giá 1–2 sao.'
                : null,
            errorStyle: AppTextStyles.bodySmall.copyWith(
              color: AppColors.error,
            ),
            contentPadding: const EdgeInsets.all(AppSpacing.md),
            enabledBorder: const OutlineInputBorder(
              borderRadius: AppRadii.radiusInput,
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: AppRadii.radiusInput,
              borderSide: BorderSide(color: AppColors.primaryEnd, width: 1.5),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: AppRadii.radiusInput,
              borderSide: BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: AppRadii.radiusInput,
              borderSide: BorderSide(color: AppColors.error, width: 1.5),
            ),
          ),
        ),
      ],
    ),
  );
}

String _ratingMessage(int rating) => switch (rating) {
  1 => 'Rất tiếc vì trải nghiệm chưa tốt',
  2 => 'Ngô Chicken sẽ cố gắng cải thiện',
  3 => 'Cảm ơn góp ý của bạn',
  4 => 'Rất vui vì bạn hài lòng',
  _ => 'Tuyệt vời! Cảm ơn bạn rất nhiều',
};
