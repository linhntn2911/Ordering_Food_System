import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:oder_food/core/constants/app_colors.dart';
import 'package:oder_food/core/widgets/app_empty_state.dart';
import 'package:oder_food/features/review/providers/review_provider.dart';

class MyReviewsScreen extends ConsumerWidget {
  const MyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(myReviewsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary)),
        title: const Text('Đánh giá của tôi', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: reviewsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('Lỗi: $err')),
        data: (reviews) {
          if (reviews.isEmpty) {
            return const AppEmptyState(icon: Icons.rate_review_outlined, title: 'Chưa có đánh giá', message: 'Đánh giá của bạn sau khi hoàn thành đơn hàng sẽ hiển thị tại đây');
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.refresh(myReviewsProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reviews.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final review = reviews[index];
                return Container(
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Đơn hàng ${review.orderId}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Text(DateFormat('dd/MM/yyyy').format(review.createdAt), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(5, (i) => Icon(i < review.rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 18)),
                      ),
                      const SizedBox(height: 10),
                      Text(review.comment, style: const TextStyle(color: AppColors.textPrimary)),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
