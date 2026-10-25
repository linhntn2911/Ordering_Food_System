import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oder_food/core/constants/app_colors.dart';
import 'package:oder_food/features/review/providers/review_provider.dart';

class WriteReviewScreen extends ConsumerWidget {
  const WriteReviewScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(reviewFormProvider);
    final notifier = ref.read(reviewFormProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary)),
        title: const Text('Viết đánh giá', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('Bạn đánh giá đơn hàng như thế nào?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      return IconButton(
                        onPressed: () => notifier.setRating(star),
                        icon: Icon(star <= form.rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 36),
                      );
                    }),
                  ),
                  Text('${form.rating}/5', style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nhận xét', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  TextField(
                    maxLines: 5,
                    onChanged: notifier.setComment,
                    decoration: InputDecoration(
                      hintText: 'Chia sẻ trải nghiệm của bạn về món ăn, dịch vụ giao hàng...',
                      hintStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: form.submitting
                    ? null
                    : () async {
                        final ok = await notifier.submit(orderId);
                        if (context.mounted) {
                          if (ok) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đánh giá thành công')));
                            context.pop();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Có lỗi xảy ra, vui lòng thử lại')));
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                child: Text(form.submitting ? 'Đang gửi...' : 'Gửi đánh giá'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
