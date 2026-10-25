import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/admin_drawer.dart';
import '../../domain/entities/food_order.dart';
import '../../domain/entities/order_status.dart';
import '../viewmodels/admin_order_list_view_model.dart';
import '../widgets/admin_order_card.dart';
import 'admin_order_details_screen.dart';
import 'sales_report_screen.dart';

class AdminOrderListScreen extends ConsumerWidget {
  const AdminOrderListScreen({this.onOrderSelected, super.key});

  final ValueChanged<FoodOrder>? onOrderSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allOrders = ref.watch(adminOrdersProvider);
    final filteredOrders = ref.watch(filteredAdminOrdersProvider);
    final filter = ref.watch(adminOrderListFilterProvider);

    ref.listen(adminOrdersProvider, (previous, next) {
      final oldOrders = previous?.value;
      final newOrders = next.value;
      if (oldOrders == null || newOrders == null) return;
      final oldIds = oldOrders.map((order) => order.id).toSet();
      final arrived = newOrders
          .where(
            (order) =>
                !oldIds.contains(order.id) &&
                order.status == OrderStatus.pending,
          )
          .toList(growable: false);
      if (arrived.isEmpty) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              arrived.length == 1
                  ? 'New order ${arrived.first.orderCode} received.'
                  : '${arrived.length} new orders received.',
            ),
            backgroundColor: AppColors.primaryEnd,
          ),
        );
      });
    });

    return Scaffold(
      drawer: const AdminDrawer(
        currentDestination: AdminDestination.orders,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 360
                ? AppSpacing.md
                : AppSpacing.xl;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    AppSpacing.md,
                    horizontalPadding,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TopBar(
                        onBack: () => Navigator.of(context).pop(),
                        onRefresh: () => ref.invalidate(adminOrdersProvider),
                        onReport: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SalesReportScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text('Orders', style: AppTextStyles.headlineLarge),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Monitor incoming orders and kitchen progress in real time.',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      allOrders.maybeWhen(
                        data: (orders) => _OrderSummary(orders: orders),
                        orElse: () => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _SearchField(
                                onChanged: ref
                                    .read(adminOrderListFilterProvider.notifier)
                                    .setQuery,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            allOrders.maybeWhen(
                              data: (orders) => _StatusFilterMenu(
                                orders: orders,
                                selected: filter.status,
                                onSelected: ref
                                    .read(adminOrderListFilterProvider.notifier)
                                    .setStatus,
                              ),
                              orElse: () => const _StatusFilterMenu(
                                orders: [],
                                selected: null,
                                onSelected: null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (filter.status != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Chip(
                            key: const ValueKey('active-filter-chip'),
                            avatar: const Icon(
                              Icons.tune_rounded,
                              size: 14,
                              color: AppColors.primaryEnd,
                            ),
                            label: Text(
                              'Status: ${filter.status!.label}',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primaryEnd,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: AppColors.primarySoft,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadii.pill),
                            ),
                            deleteIcon: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: AppColors.primaryEnd,
                            ),
                            onDeleted: () => ref
                                .read(adminOrderListFilterProvider.notifier)
                                .setStatus(null),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      Expanded(
                        child: filteredOrders.when(
                          loading: () => const _LoadingState(),
                          error: (error, _) => _ErrorState(
                            message: _friendlyError(error),
                            onRetry: () => ref.invalidate(adminOrdersProvider),
                          ),
                          data: (orders) {
                            final rawOrders = allOrders.value ?? const [];
                            if (rawOrders.isEmpty) {
                              return const _EmptyState();
                            }
                            if (orders.isEmpty) {
                              return _NoResultsState(
                                onClear: ref
                                    .read(adminOrderListFilterProvider.notifier)
                                    .clearFilters,
                              );
                            }
                            return RefreshIndicator(
                              color: AppColors.primaryEnd,
                              onRefresh: () async {
                                ref.invalidate(adminOrdersProvider);
                                await ref.read(adminOrdersProvider.future);
                              },
                              child: ListView.separated(
                                key: const ValueKey('admin-order-list'),
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.xl,
                                ),
                                itemCount: orders.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: AppSpacing.sm),
                                itemBuilder: (context, index) {
                                  final order = orders[index];
                                  return AdminOrderCard(
                                    key: ValueKey(order.id),
                                    order: order,
                                    onTap: () {
                                      if (onOrderSelected != null) {
                                        onOrderSelected!(order);
                                        return;
                                      }
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              AdminOrderDetailsScreen(
                                                initialOrder: order,
                                              ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onBack,
    required this.onRefresh,
    required this.onReport,
  });

  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (Navigator.canPop(context)) ...[
          IconButton(
            tooltip: 'Back to admin workspace',
            onPressed: onBack,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceMuted,
              minimumSize: const Size(44, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.medium),
              ),
            ),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        Builder(
          builder: (scaffoldContext) => IconButton(
            key: const ValueKey('admin-drawer-button'),
            tooltip: 'Open navigation menu',
            onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
            style: IconButton.styleFrom(
              foregroundColor: AppColors.primaryEnd,
              backgroundColor: AppColors.primarySoft,
              minimumSize: const Size(44, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.medium),
              ),
            ),
            icon: const Icon(Icons.menu_rounded),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ngô Chicken', style: AppTextStyles.titleMedium),
              Text('Live order queue', style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Open sales report',
          onPressed: onReport,
          style: IconButton.styleFrom(
            foregroundColor: AppColors.primaryEnd,
            backgroundColor: AppColors.primarySoft,
            minimumSize: const Size(44, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.medium),
            ),
          ),
          icon: const Icon(Icons.bar_chart_rounded),
        ),
        const SizedBox(width: AppSpacing.xs),
        IconButton(
          tooltip: 'Refresh orders',
          onPressed: onRefresh,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surfaceMuted,
            minimumSize: const Size(44, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.medium),
            ),
          ),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.orders});

  final List<FoodOrder> orders;

  @override
  Widget build(BuildContext context) {
    final pending = orders
        .where((order) => order.status == OrderStatus.pending)
        .length;
    final active = orders
        .where(
          (order) => const {
            OrderStatus.confirmed,
            OrderStatus.preparing,
            OrderStatus.outForDelivery,
          }.contains(order.status),
        )
        .length;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Metric(value: '$pending', label: 'New orders'),
          ),
          const SizedBox(height: 36, child: VerticalDivider()),
          Expanded(
            child: _Metric(value: '$active', label: 'In progress'),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.primaryEnd,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTextStyles.titleLarge),
          Text(label, style: AppTextStyles.labelSmall),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.input),
        boxShadow: const [AppShadows.card],
      ),
      child: TextField(
        key: const ValueKey('admin-order-search'),
        onChanged: onChanged,
        decoration: const InputDecoration(
          hintText: 'Search order, customer, or phone',
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.primaryEnd),
        ),
      ),
    );
  }
}

class _StatusFilterMenu extends StatelessWidget {
  const _StatusFilterMenu({
    required this.orders,
    required this.selected,
    required this.onSelected,
  });

  final List<FoodOrder> orders;
  final OrderStatus? selected;
  final ValueChanged<OrderStatus?>? onSelected;

  @override
  Widget build(BuildContext context) {
    int count(OrderStatus? status) => status == null
        ? orders.length
        : orders.where((order) => order.status == status).length;

    final isFiltered = selected != null;

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: isFiltered ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.input),
          boxShadow: const [AppShadows.card],
          border: isFiltered
              ? Border.all(color: AppColors.primaryEnd, width: 1.5)
              : null,
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: PopupMenuButton<OrderStatus?>(
            key: const ValueKey('order-status-filters'),
            tooltip: 'Filter by status',
            enabled: onSelected != null,
            initialValue: selected,
            onSelected: onSelected,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
            color: AppColors.surface,
            elevation: 8,
            icon: Badge(
              isLabelVisible: isFiltered,
              backgroundColor: AppColors.primaryEnd,
              smallSize: 8,
              child: Icon(
                Icons.tune_rounded,
                color: isFiltered ? AppColors.primaryEnd : AppColors.textPrimary,
              ),
            ),
            itemBuilder: (context) => [
              PopupMenuItem<OrderStatus?>(
                key: const ValueKey('order-filter-all'),
                value: null,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'All (${count(null)})',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: selected == null
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: selected == null
                              ? AppColors.primaryEnd
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (selected == null)
                      const Icon(
                        Icons.check_rounded,
                        color: AppColors.primaryEnd,
                        size: 18,
                      ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              for (final status in OrderStatus.values)
                PopupMenuItem<OrderStatus?>(
                  key: ValueKey('order-filter-${status.name}'),
                  value: status,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${status.label} (${count(status)})',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: selected == status
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: selected == status
                                ? AppColors.primaryEnd
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (selected == status)
                        const Icon(
                          Icons.check_rounded,
                          color: AppColors.primaryEnd,
                          size: 18,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      key: const ValueKey('admin-order-loading'),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, _) => Container(
        height: 230,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('admin-order-empty'),
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
              color: AppColors.primaryEnd,
              size: 40,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('No orders yet', style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'New customer orders will appear here automatically.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  const _NoResultsState({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('admin-order-no-results'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.search_off_rounded,
            color: AppColors.textMuted,
            size: 52,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('No matching orders', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          TextButton(onPressed: onClear, child: const Text('Clear filters')),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('admin-order-error'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.error, size: 56),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

String _friendlyError(Object error) {
  final value = error.toString().toLowerCase();
  if (value.contains('permission-denied')) {
    return 'Admin sign-in is required to view the order queue.';
  }
  if (value.contains('network')) {
    return 'Check your internet connection and try again.';
  }
  return 'Orders could not be loaded. Please try again.';
}
