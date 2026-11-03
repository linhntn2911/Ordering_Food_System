import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ordering_food_system/core/theme/app_colors.dart';
import 'package:ordering_food_system/core/theme/app_radii.dart';
import 'package:ordering_food_system/core/theme/app_shadows.dart';
import 'package:ordering_food_system/core/theme/app_spacing.dart';
import 'package:ordering_food_system/core/theme/app_text_styles.dart';
import 'package:ordering_food_system/core/utils/navigation_extensions.dart';
import 'package:ordering_food_system/features/order_history/data/models/order_model.dart';
import 'package:ordering_food_system/features/order_history/presentation/viewmodels/order_history_viewmodel.dart';

class OrderTrackingTimelineScreen extends ConsumerWidget {
  const OrderTrackingTimelineScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailByIdProvider(orderId));

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
                      child: orderAsync.when(
                        loading: () => const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryEnd,
                          ),
                        ),
                        error: (_, _) => _ErrorState(
                          onRetry: () =>
                              ref.invalidate(orderDetailByIdProvider(orderId)),
                        ),
                        data: (order) {
                          if (order == null) {
                            return const Center(
                              child: Text(
                                'Không tìm thấy đơn hàng',
                                style: AppTextStyles.bodyMedium,
                              ),
                            );
                          }
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
                                _OrderOverview(order: order),
                                const SizedBox(height: AppSpacing.xl),
                                Text(
                                  'Tiến trình đơn hàng',
                                  style: AppTextStyles.titleLarge,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                _TimelineCard(status: order.status),
                                const SizedBox(height: AppSpacing.xl),
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primarySoft,
                                    borderRadius: AppRadii.radiusCard,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.notifications_active_rounded,
                                        color: AppColors.primaryEnd,
                                        size: 22,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Text(
                                          'Trạng thái sẽ tự động cập nhật khi nhà hàng xử lý đơn.',
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
          child: Text('Theo dõi đơn hàng', style: AppTextStyles.titleLarge),
        ),
      ],
    ),
  );
}

class _OrderOverview extends StatelessWidget {
  const _OrderOverview({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final visual = _statusVisual(order.status);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.radiusCard,
        boxShadow: [AppShadows.card],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delivery_dining_rounded,
              color: AppColors.primaryEnd,
              size: 28,
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
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${order.itemCount} món · ${order.paymentMethod.toUpperCase()}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Container(
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
              style: AppTextStyles.labelSmall.copyWith(
                color: visual.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final steps = _steps(status);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.radiusCard,
        boxShadow: [AppShadows.card],
      ),
      child: Column(
        children: [
          for (var index = 0; index < steps.length; index++)
            _TimelineRow(step: steps[index], isLast: index == steps.length - 1),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.step, required this.isLast});

  final _Step step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = step.isReached ? AppColors.primaryEnd : AppColors.border;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 36,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: step.isCurrent
                      ? AppColors.primaryEnd
                      : step.isReached
                      ? AppColors.primarySoft
                      : AppColors.surfaceMuted,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(
                  step.isReached ? Icons.check_rounded : step.icon,
                  color: step.isCurrent
                      ? AppColors.surface
                      : step.isReached
                      ? AppColors.primaryEnd
                      : AppColors.textMuted,
                  size: 18,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 60,
                  color: step.isReached
                      ? AppColors.primaryEnd
                      : AppColors.borderLight,
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              top: AppSpacing.xxs,
              bottom: isLast ? 0 : AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        step.title,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: step.isReached
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                    if (step.isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: AppRadii.radiusPill,
                        ),
                        child: Text(
                          'Hiện tại',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primaryEnd,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(step.subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

List<_Step> _steps(OrderStatus status) {
  if (status == OrderStatus.cancelled) {
    return const [
      _Step(
        title: 'Đặt hàng thành công',
        subtitle: 'Đơn hàng đã được ghi nhận',
        icon: Icons.receipt_long_rounded,
        isReached: true,
      ),
      _Step(
        title: 'Đơn hàng đã hủy',
        subtitle: 'Đơn hàng không tiếp tục được xử lý',
        icon: Icons.close_rounded,
        isReached: true,
        isCurrent: true,
      ),
    ];
  }

  final currentIndex = switch (status) {
    OrderStatus.pending => 0,
    OrderStatus.confirmed => 1,
    OrderStatus.preparing => 2,
    OrderStatus.delivering => 3,
    OrderStatus.completed => 4,
    OrderStatus.cancelled => 0,
  };
  const definitions = [
    (
      'Đặt hàng thành công',
      'Đơn hàng đã được ghi nhận',
      Icons.receipt_long_rounded,
    ),
    ('Đã xác nhận', 'Nhà hàng đã tiếp nhận đơn hàng', Icons.verified_rounded),
    (
      'Đang chuẩn bị',
      'Nhà hàng đang chuẩn bị món ăn',
      Icons.restaurant_rounded,
    ),
    (
      'Đang giao hàng',
      'Đơn hàng đang trên đường giao đến bạn',
      Icons.delivery_dining_rounded,
    ),
    (
      'Đã giao thành công',
      'Đơn hàng đã được hoàn thành',
      Icons.check_circle_rounded,
    ),
  ];
  return [
    for (var index = 0; index < definitions.length; index++)
      _Step(
        title: definitions[index].$1,
        subtitle: definitions[index].$2,
        icon: definitions[index].$3,
        isReached: index <= currentIndex,
        isCurrent: index == currentIndex,
      ),
  ];
}

class _Step {
  const _Step({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isReached,
    this.isCurrent = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isReached;
  final bool isCurrent;
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
            'Không thể tải trạng thái đơn',
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
