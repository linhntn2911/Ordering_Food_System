import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:oder_food/core/constants/app_colors.dart';
import 'package:oder_food/core/constants/app_routes.dart';
import 'package:oder_food/features/order_history/data/models/order_model.dart';

class OrderHistoryCard extends StatelessWidget {
  const OrderHistoryCard({super.key, required this.order});
  final OrderModel order;

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.preparing:
        return AppColors.info;
      case OrderStatus.delivering:
        return AppColors.primary;
      case OrderStatus.completed:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('HH:mm - dd/MM/yyyy');
    final statusColor = _statusColor(order.status);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push('${AppRoutes.orderDetail}?orderId=${order.orderId}'),
      child: Container(
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Mã đơn: ${order.orderId}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
                    child: Text(order.status.label, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
                  )
                ],
              ),
              const SizedBox(height: 6),
              Text(dateFormat.format(order.createdAt), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const Divider(height: 24, color: AppColors.border),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      order.items.first.imageUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(width: 56, height: 56, color: AppColors.greyLight, alignment: Alignment.center, child: const Icon(Icons.fastfood, color: AppColors.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.items.first.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text(order.items.length == 1 ? '${order.itemCount} món' : '+${order.items.length - 1} món khác • ${order.itemCount} món', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  Text(NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(order.totalPrice), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary))
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => context.push('${AppRoutes.orderDetail}?orderId=${order.orderId}'), style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Xem chi tiết', style: TextStyle(color: AppColors.textPrimary)))),
                  const SizedBox(width: 10),
                  if (order.status.isCompleted)
                    Expanded(child: ElevatedButton(onPressed: () => context.push('${AppRoutes.writeReview}?orderId=${order.orderId}'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0), child: const Text('Đánh giá'))),
                  if (order.status.isOngoing)
                    Expanded(child: ElevatedButton(onPressed: () => context.push('${AppRoutes.orderTracking}?orderId=${order.orderId}'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0), child: const Text('Theo dõi đơn'))),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
