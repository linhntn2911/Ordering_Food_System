import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_time_formatter.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../domain/entities/food_order.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/entities/order_status.dart';
import '../../domain/entities/order_status_event.dart';
import '../viewmodels/admin_order_details_view_model.dart';
import '../widgets/order_status_chip.dart';

class AdminOrderDetailsScreen extends ConsumerWidget {
  const AdminOrderDetailsScreen({required this.initialOrder, super.key});

  final FoodOrder initialOrder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(adminOrderProvider(initialOrder.id));
    final order = orderAsync.value ?? initialOrder;
    final action = ref.watch(adminOrderActionProvider);

    ref.listen(adminOrderActionProvider, (_, next) {
      if (!next.hasError) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyError(next.error!)),
          backgroundColor: AppColors.error,
        ),
      );
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: RefreshIndicator(
              color: AppColors.primaryEnd,
              onRefresh: () async {
                ref.invalidate(adminOrderProvider(order.id));
                ref.invalidate(adminOrderItemsProvider(order.id));
                ref.invalidate(adminOrderEventsProvider(order.id));
                await ref.read(adminOrderProvider(order.id).future);
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.md,
                      AppSpacing.xl,
                      AppSpacing.xxl,
                    ),
                    sliver: SliverList.list(
                      children: [
                        _TopBar(orderCode: order.orderCode),
                        const SizedBox(height: AppSpacing.xl),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Order details',
                                style: AppTextStyles.headlineLarge,
                              ),
                            ),
                            OrderStatusChip(status: order.status),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Placed ${DateTimeFormatter.orderTime(order.createdAt)}',
                          style: AppTextStyles.bodySmall,
                        ),
                        if (orderAsync.hasError) ...[
                          const SizedBox(height: AppSpacing.md),
                          _InlineError(
                            onRetry: () =>
                                ref.invalidate(adminOrderProvider(order.id)),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        _CustomerCard(order: order),
                        const SizedBox(height: AppSpacing.md),
                        _SectionCard(
                          title: 'Order items',
                          icon: Icons.fastfood_rounded,
                          child: ref
                              .watch(adminOrderItemsProvider(order.id))
                              .when(
                                loading: () => const _ItemsLoading(),
                                error: (_, _) => _InlineError(
                                  onRetry: () => ref.invalidate(
                                    adminOrderItemsProvider(order.id),
                                  ),
                                ),
                                data: (items) => items.isEmpty
                                    ? const Text(
                                        'No item snapshots were found.',
                                      )
                                    : Column(
                                        children: [
                                          for (
                                            var index = 0;
                                            index < items.length;
                                            index++
                                          ) ...[
                                            _OrderItemRow(item: items[index]),
                                            if (index < items.length - 1)
                                              const Divider(height: 24),
                                          ],
                                        ],
                                      ),
                              ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _PaymentCard(order: order),
                        const SizedBox(height: AppSpacing.md),
                        _SectionCard(
                          title: 'Status timeline',
                          icon: Icons.timeline_rounded,
                          child: ref
                              .watch(adminOrderEventsProvider(order.id))
                              .when(
                                loading: () => const LinearProgressIndicator(),
                                error: (_, _) => _InlineError(
                                  onRetry: () => ref.invalidate(
                                    adminOrderEventsProvider(order.id),
                                  ),
                                ),
                                data: (events) => events.isEmpty
                                    ? const Text('No status history yet.')
                                    : _StatusTimeline(events: events),
                              ),
                        ),
                        if (order.rejectionReason.isNotEmpty ||
                            order.cancellationReason.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          _ReasonCard(
                            label: order.status == OrderStatus.rejected
                                ? 'Rejection reason'
                                : 'Cancellation reason',
                            reason: order.rejectionReason.isNotEmpty
                                ? order.rejectionReason
                                : order.cancellationReason,
                          ),
                        ],
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar:
          order.status.nextFulfillmentStatus == null &&
              order.status != OrderStatus.pending
          ? null
          : _OrderActions(
              order: order,
              loading: action.isLoading,
              onTransition: (target, reason) =>
                  _transition(context, ref, order, target, reason),
            ),
    );
  }

  Future<void> _transition(
    BuildContext context,
    WidgetRef ref,
    FoodOrder order,
    OrderStatus target,
    String reason,
  ) async {
    final success = await ref
        .read(adminOrderActionProvider.notifier)
        .transition(order, target, reason: reason);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order moved to ${target.label}.'),
          backgroundColor: AppColors.primaryEnd,
        ),
      );
    }
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.orderCode});
  final String orderCode;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        tooltip: 'Back to orders',
        onPressed: () => Navigator.of(context).pop(),
        style: IconButton.styleFrom(
          foregroundColor: AppColors.primaryEnd,
          backgroundColor: AppColors.primarySoft,
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.medium),
          ),
        ),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ngô Chicken', style: AppTextStyles.titleMedium),
            Text(orderCode, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    ],
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.card),
      boxShadow: const [AppShadows.card],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primaryEnd, size: 20),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    ),
  );
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.order});
  final FoodOrder order;

  @override
  Widget build(BuildContext context) => _SectionCard(
    title: 'Customer & delivery',
    icon: Icons.location_on_rounded,
    child: Column(
      children: [
        _InfoRow(
          icon: Icons.person_rounded,
          title: order.customerName,
          subtitle: order.customerPhone,
        ),
        const SizedBox(height: AppSpacing.sm),
        _InfoRow(
          icon: Icons.home_rounded,
          title: order.deliveryAddress,
          subtitle: order.deliveryDistanceKm > 0
              ? '${order.deliveryDistanceKm.toStringAsFixed(1)} km from restaurant'
              : 'Delivery address',
        ),
        if (order.customerNote.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(
            icon: Icons.sticky_note_2_rounded,
            title: 'Customer note',
            subtitle: order.customerNote,
          ),
        ],
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: AppColors.primarySoft,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primaryEnd, size: 19),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            Text(subtitle, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    ],
  );
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});
  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final options = [
      if (item.selectedSize.isNotEmpty) 'Size ${item.selectedSize}',
      ...item.selectedToppings,
      if (item.note.isNotEmpty) 'Note: ${item.note}',
    ].join(' · ');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.warningSurface,
            borderRadius: BorderRadius.circular(AppRadii.medium),
          ),
          child: Text(
            '${item.quantity}×',
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.warning),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: AppTextStyles.titleMedium),
              if (options.isNotEmpty)
                Text(options, style: AppTextStyles.bodySmall),
              Text(
                '${CurrencyFormatter.vnd(item.unitPrice)} each',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          CurrencyFormatter.vnd(item.lineTotal),
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryEnd),
        ),
      ],
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.order});
  final FoodOrder order;

  @override
  Widget build(BuildContext context) => _SectionCard(
    title: 'Payment summary',
    icon: Icons.payments_rounded,
    child: Column(
      children: [
        _MoneyRow(
          label: 'Subtotal',
          value: order.subtotal > 0
              ? order.subtotal
              : order.totalAmount - order.deliveryFee,
        ),
        const SizedBox(height: AppSpacing.xs),
        _MoneyRow(label: 'Delivery fee', value: order.deliveryFee),
        const Divider(height: 24),
        _MoneyRow(label: 'Total', value: order.totalAmount, emphasized: true),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            const Icon(
              Icons.money_rounded,
              size: 18,
              color: AppColors.primaryEnd,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                'Cash on delivery · ${order.paymentStatus}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });
  final String label;
  final int value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: emphasized
              ? AppTextStyles.titleMedium
              : AppTextStyles.bodyMedium,
        ),
      ),
      Text(
        CurrencyFormatter.vnd(value),
        style:
            (emphasized ? AppTextStyles.titleLarge : AppTextStyles.labelLarge)
                .copyWith(
                  color: emphasized
                      ? AppColors.primaryEnd
                      : AppColors.textPrimary,
                ),
      ),
    ],
  );
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.events});
  final List<OrderStatusEvent> events;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var index = 0; index < events.length; index++)
        _TimelineRow(event: events[index], last: index == events.length - 1),
    ],
  );
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.event, required this.last});
  final OrderStatusEvent event;
  final bool last;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 28,
          child: Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppColors.primaryEnd,
                  shape: BoxShape.circle,
                ),
              ),
              if (!last)
                Expanded(
                  child: Container(width: 2, color: AppColors.primarySoft),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: last ? 0 : AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.toStatus.label,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${DateTimeFormatter.orderTime(event.createdAt)} · ${event.actorRole}',
                  style: AppTextStyles.bodySmall,
                ),
                if (event.reason.isNotEmpty)
                  Text(event.reason, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _ReasonCard extends StatelessWidget {
  const _ReasonCard({required this.label, required this.reason});
  final String label;
  final String reason;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.errorSoft,
      borderRadius: BorderRadius.circular(AppRadii.card),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline_rounded, color: AppColors.error),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.titleMedium),
              Text(reason, style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ],
    ),
  );
}

class _OrderActions extends StatelessWidget {
  const _OrderActions({
    required this.order,
    required this.loading,
    required this.onTransition,
  });
  final FoodOrder order;
  final bool loading;
  final void Function(OrderStatus, String) onTransition;

  @override
  Widget build(BuildContext context) {
    final next = order.status.nextFulfillmentStatus;
    final label = switch (next) {
      OrderStatus.confirmed => 'Confirm order',
      OrderStatus.preparing => 'Start preparing',
      OrderStatus.outForDelivery => 'Send for delivery',
      OrderStatus.completed => 'Mark completed',
      _ => 'Update order',
    };
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [AppShadows.card],
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  if (order.status == OrderStatus.pending) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const ValueKey('reject-order-button'),
                        onPressed: loading ? null : () => _showReject(context),
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          minimumSize: const Size(0, 56),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    flex: 2,
                    child: GradientButton(
                      label: label,
                      isLoading: loading,
                      icon: Icons.arrow_forward_rounded,
                      onPressed: next == null || loading
                          ? null
                          : () => _confirm(context, next),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirm(BuildContext context, OrderStatus target) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Move to ${target.label}?'),
        content: const Text('This update will be added to the order history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (approved == true) onTransition(target, '');
  }

  Future<void> _showReject(BuildContext context) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject order'),
        content: TextField(
          key: const ValueKey('rejection-reason-field'),
          controller: controller,
          maxLength: 200,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Reason',
            hintText: 'Example: Item is sold out',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(context, controller.text.trim());
            },
            child: const Text('Reject order'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason != null && reason.isNotEmpty) {
      onTransition(OrderStatus.rejected, reason);
    }
  }
}

class _ItemsLoading extends StatelessWidget {
  const _ItemsLoading();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
    child: Center(child: CircularProgressIndicator()),
  );
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Text('This information could not be loaded.')),
      TextButton(onPressed: onRetry, child: const Text('Retry')),
    ],
  );
}

String _friendlyError(Object error) {
  final value = error.toString().toLowerCase();
  if (value.contains('permission-denied') || value.contains('sign-in')) {
    return 'Admin sign-in is required to update this order.';
  }
  if (value.contains('updated by another') ||
      value.contains('updated. refresh')) {
    return 'The order changed. Refresh it before trying again.';
  }
  if (error is ArgumentError) {
    return error.message?.toString() ?? 'Check the order update.';
  }
  return 'The order could not be updated. Please try again.';
}
