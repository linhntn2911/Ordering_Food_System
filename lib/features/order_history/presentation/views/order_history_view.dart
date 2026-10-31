import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oder_food/core/constants/app_colors.dart';
import 'package:oder_food/core/constants/app_routes.dart';
import 'package:oder_food/core/widgets/app_empty_state.dart';
import 'package:oder_food/features/order_history/presentation/viewmodels/order_history_viewmodel.dart';
import 'package:oder_food/features/order_history/presentation/widgets/order_history_card.dart';

class OrderHistoryView extends ConsumerWidget {
  const OrderHistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(orderHistoryFilterProvider);
    final ordersAsync = ref.watch(orderHistoryListProvider);

    final filters = [
      {'key': 'all', 'label': 'Tất cả'},
      {'key': 'ongoing', 'label': 'Đang xử lý'},
      {'key': 'completed', 'label': 'Đã hoàn thành'},
      {'key': 'cancelled', 'label': 'Đã hủy'},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Lịch sử đơn hàng', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(onPressed: () => context.push(AppRoutes.notifications), icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary)),
          IconButton(onPressed: () => context.push(AppRoutes.myReviews), icon: const Icon(Icons.rate_review_outlined, color: AppColors.textPrimary)),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filters.map((f) {
                  final isSelected = filter == f['key'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f['label']!),
                      selected: isSelected,
                      onSelected: (_) => ref.read(orderHistoryFilterProvider.notifier).state = f['key']!,
                      selectedColor: AppColors.primary.withOpacity(0.12),
                      labelStyle: TextStyle(color: isSelected ? AppColors.primary : AppColors.textSecondary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999), side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border)),
                      backgroundColor: AppColors.surface,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ordersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Center(child: Text('Lỗi: $err')),
              data: (orders) {
                if (orders.isEmpty) {
                  return const AppEmptyState(icon: Icons.receipt_long_outlined, title: 'Chưa có đơn hàng', message: 'Các đơn hàng của bạn sẽ hiển thị tại đây');
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    ref.invalidate(orderHistoryListProvider);
                    await ref.read(orderHistoryListProvider.future);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return OrderHistoryCard(order: order);
                    },
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
