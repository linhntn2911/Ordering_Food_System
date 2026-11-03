import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ordering_food_system/app/router.dart';
import 'package:ordering_food_system/core/theme/app_colors.dart';
import 'package:ordering_food_system/core/theme/app_spacing.dart';
import 'package:ordering_food_system/core/theme/app_text_styles.dart';
import 'package:ordering_food_system/core/utils/navigation_extensions.dart';
import 'package:ordering_food_system/features/auth/presentation/viewmodels/auth_providers.dart';
import 'package:ordering_food_system/features/order_history/presentation/viewmodels/order_history_viewmodel.dart';
import 'package:ordering_food_system/features/order_history/presentation/widgets/order_history_card.dart';
import 'package:ordering_food_system/features/review/providers/review_provider.dart';

class OrderHistoryView extends ConsumerWidget {
  const OrderHistoryView({super.key});

  static const _filters = <({String key, String label})>[
    (key: 'all', label: 'Tất cả'),
    (key: 'ongoing', label: 'Đang xử lý'),
    (key: 'completed', label: 'Đã hoàn thành'),
    (key: 'cancelled', label: 'Đã hủy'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    if (authState.value == null) {
      return _SignedOutOrders(isLoading: authState.isLoading);
    }

    final filter = ref.watch(orderHistoryFilterProvider);
    final ordersAsync = ref.watch(orderHistoryListProvider);
    final reviewedIds = ref.watch(reviewedOrderIdsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Lịch sử đơn hàng',
          style: AppTextStyles.headlineMedium,
        ),
        actions: [
          IconButton(
            tooltip: 'Thông báo',
            onPressed: () => context.push(AppRoutes.notifications),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            tooltip: 'Đánh giá của tôi',
            onPressed: () => context.push(AppRoutes.myReviews),
            icon: const Icon(Icons.rate_review_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s8),
              itemBuilder: (context, index) {
                final item = _filters[index];
                final selected = filter == item.key;
                return ChoiceChip(
                  label: Text(item.label),
                  selected: selected,
                  onSelected: (_) =>
                      ref.read(orderHistoryFilterProvider.notifier).state =
                          item.key,
                  selectedColor: AppColors.primarySoft,
                  backgroundColor: AppColors.surface,
                  side: BorderSide(
                    color: selected ? AppColors.primaryEnd : AppColors.border,
                  ),
                  labelStyle: AppTextStyles.labelLarge.copyWith(
                    color: selected
                        ? AppColors.primaryEnd
                        : AppColors.textSecondary,
                  ),
                  shape: const StadiumBorder(),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Expanded(
            child: ordersAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primaryEnd),
              ),
              error: (error, _) => _OrdersError(
                onRetry: () => ref.invalidate(orderHistoryListProvider),
              ),
              data: (orders) {
                if (orders.isEmpty) return const _EmptyOrders();
                return RefreshIndicator(
                  color: AppColors.primaryEnd,
                  onRefresh: () async =>
                      ref.invalidate(orderHistoryListProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s24,
                      AppSpacing.s8,
                      AppSpacing.s24,
                      AppSpacing.s32,
                    ),
                    itemCount: orders.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.s12),
                    itemBuilder: (context, index) =>
                        OrderHistoryCard(
                          order: orders[index],
                          isReviewed: reviewedIds.contains(orders[index].orderId),
                        ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 42,
                color: AppColors.primaryEnd,
              ),
            ),
            const SizedBox(height: AppSpacing.s20),
            const Text('Chưa có đơn hàng', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Đơn hàng của bạn sẽ xuất hiện tại đây sau khi xác nhận.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersError extends StatelessWidget {
  const _OrdersError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: OutlinedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Tải lại đơn hàng'),
      ),
    );
  }
}

class _SignedOutOrders extends StatelessWidget {
  const _SignedOutOrders({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lịch sử đơn hàng',
          style: AppTextStyles.headlineMedium,
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryEnd),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 44,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    const Text(
                      'Đăng nhập để xem đơn hàng',
                      style: AppTextStyles.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    OutlinedButton(
                      onPressed: () => context.push(AppRoutes.login),
                      child: const Text('Đi đến Đăng nhập'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
