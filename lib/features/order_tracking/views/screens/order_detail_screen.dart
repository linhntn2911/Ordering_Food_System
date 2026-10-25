import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:oder_food/core/constants/app_colors.dart';
import 'package:oder_food/core/constants/app_routes.dart';
import 'package:oder_food/features/order_history/providers/order_history_provider.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  String _getStatusLabel(dynamic status) {
    try {
      final s = status.toString();
      if (s.contains('pending')) return 'Đã đặt';
      if (s.contains('preparing')) return 'Đang chuẩn bị';
      if (s.contains('delivering')) return 'Đang giao';
      if (s.contains('completed')) return 'Đã giao';
      if (s.contains('cancelled')) return 'Đã hủy';
    } catch (_) {}
    return status.toString();
  }

  bool _isOngoing(dynamic status) {
    final s = status.toString();
    return s.contains('pending') || s.contains('preparing') || s.contains('delivering');
  }

  bool _isCompleted(dynamic status) {
    return status.toString().contains('completed');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailByIdProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary)),
        title: const Text('Chi tiết đơn hàng', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('Lỗi: $err')),
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Không tìm thấy đơn hàng'));
          }
          final dateFormat = DateFormat('HH:mm - dd/MM/yyyy');
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.receipt_long, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text('Mã đơn: ${order.orderId}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Text(_getStatusLabel(order.status), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(dateFormat.format(order.createdAt), style: const TextStyle(color: AppColors.textSecondary)),
                      if (order.estimatedDeliveryTime != null) ...[
                        const SizedBox(height: 6),
                        Text('Dự kiến giao: ${dateFormat.format(order.estimatedDeliveryTime!)}', style: const TextStyle(color: AppColors.textSecondary)),
                      ]
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
                      const Text('Sản phẩm', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 12),
                      ...order.items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(item.imageUrl, width: 56, height: 56, fit: BoxFit.cover),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      Text('x${item.quantity}', style: const TextStyle(color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                Text(NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(item.subtotal), style: const TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          )),
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
                      const Text('Thanh toán', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 10),
                      _row('Tạm tính', order.subtotal),
                      _row('Phí giao hàng', order.deliveryFee),
                      _row('Giảm giá', -order.discount),
                      const Divider(height: 20, color: AppColors.border),
                      _row('Tổng cộng', order.totalPrice, bold: true),
                      const SizedBox(height: 6),
                      Text('Phương thức: ${order.paymentMethod}', style: const TextStyle(color: AppColors.textSecondary)),
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
                      const Text('Giao hàng', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(order.address, style: const TextStyle(color: AppColors.textPrimary)),
                      if (order.note != null && order.note!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Ghi chú: ${order.note}', style: const TextStyle(color: AppColors.textSecondary)),
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_isOngoing(order.status))
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.push('${AppRoutes.orderTracking}?orderId=${order.orderId}'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text('Theo dõi đơn hàng'),
                    ),
                  ),
                if (_isCompleted(order.status))
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.push('${AppRoutes.writeReview}?orderId=${order.orderId}'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text('Viết đánh giá'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _row(String label, double value, {bool bold = false}) {
    final nf = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: bold ? AppColors.textPrimary : AppColors.textSecondary, fontWeight: bold ? FontWeight.w600 : FontWeight.normal)),
          const Spacer(),
          Text(nf.format(value), style: TextStyle(color: bold ? AppColors.textPrimary : AppColors.textSecondary, fontWeight: bold ? FontWeight.w700 : FontWeight.normal)),
        ],
      ),
    );
  }
}
