import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ordering_food_system/app/router.dart';
import 'package:ordering_food_system/core/theme/app_colors.dart';
import 'package:ordering_food_system/core/theme/app_radii.dart';
import 'package:ordering_food_system/core/theme/app_shadows.dart';
import 'package:ordering_food_system/core/theme/app_spacing.dart';
import 'package:ordering_food_system/core/theme/app_text_styles.dart';
import 'package:ordering_food_system/core/utils/currency_formatter.dart';
import 'package:ordering_food_system/core/utils/navigation_extensions.dart';
import 'package:ordering_food_system/core/widgets/gradient_button.dart';
import 'package:ordering_food_system/features/order_history/data/models/order_model.dart';
import 'package:ordering_food_system/features/order_history/presentation/viewmodels/order_history_viewmodel.dart';
import 'package:ordering_food_system/features/review/providers/review_provider.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailByIdProvider(orderId));
    final reviewedIds = ref.watch(reviewedOrderIdsProvider);

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
                    _PageHeader(
                      title: 'Chi tiết đơn hàng',
                      onBack: context.pop,
                    ),
                    Expanded(
                      child: orderAsync.when(
                        loading: () => const _LoadingState(),
                        error: (_, _) => _ErrorState(
                          onRetry: () =>
                              ref.invalidate(orderDetailByIdProvider(orderId)),
                        ),
                        data: (order) {
                          if (order == null) return const _NotFoundState();
                          return RefreshIndicator(
                            color: AppColors.primaryEnd,
                            onRefresh: () async => ref.invalidate(
                              orderDetailByIdProvider(orderId),
                            ),
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                horizontal,
                                AppSpacing.sm,
                                horizontal,
                                AppSpacing.xxl,
                              ),
                              children: [
                                _OrderSummaryCard(order: order),
                                const SizedBox(height: AppSpacing.md),
                                _SectionCard(
                                  icon: Icons.restaurant_menu_rounded,
                                  title: 'Món đã đặt',
                                  child: Column(
                                    children: [
                                      for (
                                        var index = 0;
                                        index < order.items.length;
                                        index++
                                      ) ...[
                                        _OrderItemRow(item: order.items[index]),
                                        if (index < order.items.length - 1)
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: AppSpacing.sm,
                                            ),
                                            child: Divider(
                                              height: 1,
                                              color: AppColors.borderLight,
                                            ),
                                          ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                _PaymentCard(order: order),
                                const SizedBox(height: AppSpacing.md),
                                _SectionCard(
                                  icon: Icons.location_on_rounded,
                                  title: 'Thông tin giao hàng',
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        order.address,
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(
                                              color: AppColors.textPrimary,
                                            ),
                                      ),
                                      if (order.note != null &&
                                          order.note!.trim().isNotEmpty) ...[
                                        const SizedBox(height: AppSpacing.sm),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(
                                            AppSpacing.sm,
                                          ),
                                          decoration: const BoxDecoration(
                                            color: AppColors.surfaceMuted,
                                            borderRadius: AppRadii.radiusMedium,
                                          ),
                                          child: Text(
                                            'Ghi chú: ${order.note}',
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (order.status.isOngoing ||
                                    order.status.isCompleted) ...[
                                  const SizedBox(height: AppSpacing.xl),
                                  GradientButton(
                                    label: order.status.isCompleted
                                        ? (reviewedIds.contains(order.orderId)
                                            ? 'Đã đánh giá'
                                            : 'Viết đánh giá')
                                        : 'Theo dõi đơn hàng',
                                    icon: order.status.isCompleted
                                        ? Icons.star_rounded
                                        : Icons.local_shipping_rounded,
                                    onPressed:
                                        order.status.isCompleted &&
                                            reviewedIds.contains(order.orderId)
                                        ? null
                                        : () => context.push(
                                            order.status.isCompleted
                                                ? '${AppRoutes.writeReview}?orderId=${order.orderId}'
                                                : '${AppRoutes.orderTracking}?orderId=${order.orderId}',
                                          ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
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
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.title, required this.onBack});

  final String title;
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
        Expanded(child: Text(title, style: AppTextStyles.titleLarge)),
      ],
    ),
  );
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final status = _statusVisual(order.status);
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.primaryEnd,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMedium,
                    ),
                    Text(
                      DateFormat('HH:mm · dd/MM/yyyy').format(order.createdAt),
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              _StatusChip(visual: status),
            ],
          ),
          if (order.estimatedDeliveryTime != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: const BoxDecoration(
                color: AppColors.warningSurface,
                borderRadius: AppRadii.radiusMedium,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Dự kiến giao ${DateFormat('HH:mm · dd/MM/yyyy').format(order.estimatedDeliveryTime!)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => _SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primaryEnd, size: 22),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: Text(title, style: AppTextStyles.titleMedium)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    ),
  );
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: const BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadii.radiusCard,
      boxShadow: [AppShadows.card],
    ),
    child: child,
  );
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      ClipRRect(
        borderRadius: AppRadii.radiusMedium,
        child: Image.network(
          item.imageUrl,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            width: 64,
            height: 64,
            color: AppColors.primarySoft,
            alignment: Alignment.center,
            child: const Icon(
              Icons.restaurant_rounded,
              color: AppColors.primaryEnd,
            ),
          ),
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text('Số lượng: ${item.quantity}', style: AppTextStyles.bodySmall),
          ],
        ),
      ),
      const SizedBox(width: AppSpacing.xs),
      Text(
        CurrencyFormatter.formatVND(item.subtotal),
        style: AppTextStyles.price.copyWith(color: AppColors.primaryEnd),
      ),
    ],
  );
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) => _SectionCard(
    icon: Icons.payments_rounded,
    title: 'Thanh toán',
    child: Column(
      children: [
        _MoneyRow(label: 'Tạm tính', value: order.subtotal),
        const SizedBox(height: AppSpacing.xs),
        _MoneyRow(label: 'Phí giao hàng', value: order.deliveryFee),
        if (order.discount > 0) ...[
          const SizedBox(height: AppSpacing.xs),
          _MoneyRow(label: 'Giảm giá', value: -order.discount),
        ],
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Divider(height: 1, color: AppColors.border),
        ),
        _MoneyRow(label: 'Tổng cộng', value: order.totalPrice, isTotal: true),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Thanh toán khi nhận hàng · ${order.paymentMethod.toUpperCase()}',
            style: AppTextStyles.bodySmall,
          ),
        ),
      ],
    ),
  );
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final double value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: isTotal ? AppTextStyles.titleMedium : AppTextStyles.bodyMedium,
        ),
      ),
      Text(
        CurrencyFormatter.formatVND(value),
        style: (isTotal ? AppTextStyles.titleLarge : AppTextStyles.price)
            .copyWith(
              color: isTotal ? AppColors.primaryEnd : AppColors.textPrimary,
            ),
      ),
    ],
  );
}

class _StatusVisual {
  const _StatusVisual(this.label, this.foreground, this.background);

  final String label;
  final Color foreground;
  final Color background;
}

_StatusVisual _statusVisual(OrderStatus status) => switch (status) {
  OrderStatus.pending => const _StatusVisual(
    'Đã đặt',
    AppColors.warning,
    AppColors.warningSurface,
  ),
  OrderStatus.confirmed => const _StatusVisual(
    'Đã xác nhận',
    AppColors.primaryEnd,
    AppColors.primarySoft,
  ),
  OrderStatus.preparing => const _StatusVisual(
    'Đang chuẩn bị',
    AppColors.primaryEnd,
    AppColors.primarySoft,
  ),
  OrderStatus.delivering => const _StatusVisual(
    'Đang giao',
    AppColors.info,
    AppColors.primarySoft,
  ),
  OrderStatus.completed => const _StatusVisual(
    'Đã hoàn thành',
    AppColors.success,
    AppColors.successSoft,
  ),
  OrderStatus.cancelled => const _StatusVisual(
    'Đã hủy',
    AppColors.error,
    AppColors.errorSoft,
  ),
};

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.visual});

  final _StatusVisual visual;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: visual.background,
      borderRadius: AppRadii.radiusPill,
    ),
    child: Text(
      visual.label,
      style: AppTextStyles.labelSmall.copyWith(color: visual.foreground),
    ),
  );
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator(color: AppColors.primaryEnd),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 44,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Không thể tải đơn hàng',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    ),
  );
}

class _NotFoundState extends StatelessWidget {
  const _NotFoundState();

  @override
  Widget build(BuildContext context) => const Center(
    child: Text('Không tìm thấy đơn hàng', style: AppTextStyles.bodyMedium),
  );
}
