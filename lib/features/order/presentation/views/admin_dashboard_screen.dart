import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/admin_drawer.dart';
import '../../../category/presentation/viewmodels/category_management_view_model.dart';
import '../../../category/presentation/views/category_management_screen.dart';
import '../../../menu/presentation/views/admin_menu_item_list_screen.dart';
import '../../domain/entities/food_order.dart';
import '../../domain/entities/order_status.dart';
import '../viewmodels/admin_order_list_view_model.dart';
import '../widgets/admin_order_card.dart';
import 'admin_order_details_screen.dart';
import 'admin_order_list_screen.dart';
import 'sales_report_screen.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allOrdersAsync = ref.watch(adminOrdersProvider);

    return Scaffold(
      drawer: const AdminDrawer(currentDestination: AdminDestination.dashboard),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 360
                ? AppSpacing.md
                : AppSpacing.xl;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: RefreshIndicator(
                  color: AppColors.primaryEnd,
                  onRefresh: () async {
                    ref.invalidate(adminOrdersProvider);
                    ref.invalidate(categoriesProvider);
                    await ref.read(adminOrdersProvider.future);
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      AppSpacing.md,
                      horizontalPadding,
                      AppSpacing.xxl,
                    ),
                    children: [
                      _TopBar(
                        onRefresh: () {
                          ref.invalidate(adminOrdersProvider);
                          ref.invalidate(categoriesProvider);
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Good day, Admin 👋',
                        style: AppTextStyles.headlineLarge,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Here is what\'s happening at Ngô Chicken today.',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      allOrdersAsync.when(
                        loading: () => const _LoadingSummary(),
                        error: (_, _) => const SizedBox.shrink(),
                        data: (orders) => _PendingAlertBanner(orders: orders),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      allOrdersAsync.when(
                        loading: () => const _LoadingMetrics(),
                        error: (_, _) => const SizedBox.shrink(),
                        data: (orders) => _MetricsOverview(orders: orders),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text('Quick Actions', style: AppTextStyles.titleLarge),
                      const SizedBox(height: AppSpacing.sm),
                      _QuickActionGrid(
                        pendingCount:
                            allOrdersAsync.value
                                ?.where((o) => o.status == OrderStatus.pending)
                                .length ??
                            0,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Recent Orders',
                              style: AppTextStyles.titleLarge,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const AdminOrderListScreen(),
                              ),
                            ),
                            child: const Text('View queue →'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      allOrdersAsync.when(
                        loading: () => const _LoadingRecentOrders(),
                        error: (_, _) => const Center(
                          child: Text('Unable to load recent orders.'),
                        ),
                        data: (orders) => _RecentOrdersList(orders: orders),
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
  const _TopBar({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
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
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryEnd,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Text('Admin Dashboard', style: AppTextStyles.bodySmall),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Refresh dashboard',
          onPressed: onRefresh,
          style: IconButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
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

class _PendingAlertBanner extends StatelessWidget {
  const _PendingAlertBanner({required this.orders});

  final List<FoodOrder> orders;

  @override
  Widget build(BuildContext context) {
    final pendingOrders = orders
        .where((o) => o.status == OrderStatus.pending)
        .toList();

    if (pendingOrders.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.successSoft,
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.primaryEnd,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                'All orders up to date. Kitchen is clear!',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primaryEnd,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Material(
      color: AppColors.warningSurface,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AdminOrderListScreen()),
        ),
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: AppColors.warning,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${pendingOrders.length} pending order${pendingOrders.length > 1 ? 's' : ''} waiting!',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to review and accept incoming orders',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.warning,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricsOverview extends StatelessWidget {
  const _MetricsOverview({required this.orders});

  final List<FoodOrder> orders;

  @override
  Widget build(BuildContext context) {
    final completedOrders = orders
        .where((o) => o.status == OrderStatus.completed)
        .toList();
    final totalRevenue = completedOrders.fold<int>(
      0,
      (sum, o) => sum + o.totalAmount,
    );

    final activeOrders = orders.where((o) {
      return o.status == OrderStatus.pending ||
          o.status == OrderStatus.confirmed ||
          o.status == OrderStatus.preparing ||
          o.status == OrderStatus.outForDelivery;
    }).length;

    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            label: 'Total Revenue',
            value: CurrencyFormatter.vnd(totalRevenue),
            subLabel: '${completedOrders.length} completed',
            icon: Icons.monetization_on_rounded,
            iconColor: AppColors.primaryEnd,
            bgColor: AppColors.primarySoft,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MetricCard(
            label: 'Active Queue',
            value: '$activeOrders orders',
            subLabel: 'Needs attention',
            icon: Icons.outdoor_grill_rounded,
            iconColor: AppColors.warning,
            bgColor: AppColors.warningSurface,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.subLabel,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  final String label;
  final String value;
  final String subLabel;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: const [AppShadows.card],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(AppRadii.small),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subLabel,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid({required this.pendingCount});

  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                title: 'Live Orders',
                subtitle: 'Process queue',
                icon: Icons.receipt_long_rounded,
                badgeCount: pendingCount,
                gradient: AppGradients.primary,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AdminOrderListScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ActionCard(
                title: 'Sales Report',
                subtitle: 'Revenue & charts',
                icon: Icons.bar_chart_rounded,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SalesReportScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                title: 'Categories',
                subtitle: 'Food sections',
                icon: Icons.category_rounded,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CategoryManagementScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ActionCard(
                title: 'Menu Items',
                subtitle: 'Prices & availability',
                icon: Icons.restaurant_menu_rounded,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AdminMenuItemListScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
    this.gradient,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final hasGradient = gradient != null;

    return Material(
      color: hasGradient ? null : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Ink(
        decoration: BoxDecoration(
          color: hasGradient ? null : AppColors.surface,
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppRadii.card),
          boxShadow: const [AppShadows.card],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: hasGradient
                            ? AppColors.surface.withValues(alpha: 0.25)
                            : AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(AppRadii.medium),
                      ),
                      child: Icon(
                        icon,
                        size: 22,
                        color: hasGradient
                            ? AppColors.surface
                            : AppColors.primaryEnd,
                      ),
                    ),
                    if (badgeCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                        child: Text(
                          '$badgeCount',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.surface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: hasGradient
                        ? AppColors.surface
                        : AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: hasGradient
                        ? AppColors.surface.withValues(alpha: 0.85)
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentOrdersList extends StatelessWidget {
  const _RecentOrdersList({required this.orders});

  final List<FoodOrder> orders;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          boxShadow: const [AppShadows.card],
        ),
        child: Center(
          child: Text(
            'No orders yet.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ),
      );
    }

    final recent = orders.take(3).toList();

    return Column(
      children: [
        for (final order in recent) ...[
          AdminOrderCard(
            order: order,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => AdminOrderDetailsScreen(initialOrder: order),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _LoadingSummary extends StatelessWidget {
  const _LoadingSummary();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
    );
  }
}

class _LoadingMetrics extends StatelessWidget {
  const _LoadingMetrics();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
    );
  }
}

class _LoadingRecentOrders extends StatelessWidget {
  const _LoadingRecentOrders();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
    );
  }
}
