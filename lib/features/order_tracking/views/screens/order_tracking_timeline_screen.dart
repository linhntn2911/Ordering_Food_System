import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:oder_food/core/constants/app_colors.dart';
import 'package:oder_food/features/order_history/models/order_model.dart';
import 'package:oder_food/features/order_history/providers/order_history_provider.dart';

class OrderTrackingTimelineScreen extends ConsumerWidget {
  const OrderTrackingTimelineScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailByIdProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary)),
        title: const Text('Theo dõi đơn hàng', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('Lỗi: $err')),
        data: (order) {
          if (order == null) return const Center(child: Text('Không tìm thấy đơn hàng'));
          final steps = _buildSteps(order.status);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Đơn hàng ${order.orderId}', style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text('Trạng thái: ${order.status.label}', style: const TextStyle(color: AppColors.textSecondary)),
                            if (order.estimatedDeliveryTime != null)
                              Text('Dự kiến: ${DateFormat('HH:mm - dd/MM/yyyy').format(order.estimatedDeliveryTime!)}', style: const TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: List.generate(steps.length, (index) {
                      final step = steps[index];
                      final isLast = index == steps.length - 1;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(color: step.active ? AppColors.primary : AppColors.border, shape: BoxShape.circle),
                                child: Icon(step.active ? Icons.check : Icons.circle, size: 16, color: step.active ? Colors.white : AppColors.textSecondary),
                              ),
                              if (!isLast)
                                Container(width: 2, height: 56, color: step.active && steps[index + 1].active ? AppColors.primary : AppColors.border),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(step.title, style: TextStyle(fontWeight: FontWeight.w600, color: step.active ? AppColors.textPrimary : AppColors.textSecondary)),
                                  const SizedBox(height: 4),
                                  Text(step.subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                ],
                              ),
                            ),
                          )
                        ],
                      );
                    }),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  List<_Step> _buildSteps(OrderStatus status) {
    final steps = [
      _Step(title: 'Đặt hàng thành công', subtitle: 'Đơn hàng đã được ghi nhận', active: true),
      _Step(title: 'Đang chuẩn bị', subtitle: 'Nhà hàng đang chuẩn bị món ăn', active: status == OrderStatus.preparing || status == OrderStatus.delivering || status == OrderStatus.completed),
      _Step(title: 'Đang giao hàng', subtitle: 'Shipper đang trên đường giao', active: status == OrderStatus.delivering || status == OrderStatus.completed),
      _Step(title: 'Đã giao thành công', subtitle: 'Đơn hàng đã được giao', active: status == OrderStatus.completed),
    ];
    if (status == OrderStatus.cancelled) {
      return [
        _Step(title: 'Đặt hàng thành công', subtitle: 'Đơn hàng đã được ghi nhận', active: true),
        _Step(title: 'Đơn hàng đã hủy', subtitle: 'Đơn hàng đã bị hủy', active: true),
      ];
    }
    return steps;
  }
}

class _Step {
  _Step({required this.title, required this.subtitle, required this.active});
  final String title;
  final String subtitle;
  final bool active;
}
