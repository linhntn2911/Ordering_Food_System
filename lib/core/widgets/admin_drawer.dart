import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router.dart';
import '../../features/auth/presentation/viewmodels/auth_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum AdminDestination {
  dashboard,
  categories,
  menuItems,
  orders,
  salesReport,
  broadcasts,
}

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({required this.currentDestination, super.key});

  final AdminDestination currentDestination;

  void _navigate(BuildContext context, AdminDestination destination) {
    if (destination == currentDestination) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pop();

    final targetRoute = switch (destination) {
      AdminDestination.dashboard => AppRoutes.adminDashboard,
      AdminDestination.categories => AppRoutes.adminCategories,
      AdminDestination.menuItems => AppRoutes.adminMenuItems,
      AdminDestination.orders => AppRoutes.adminOrders,
      AdminDestination.salesReport => AppRoutes.adminSalesReport,
      AdminDestination.broadcasts => AppRoutes.adminBroadcast,
    };

    if (destination == AdminDestination.dashboard) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil(targetRoute, (route) => false);
    } else if (currentDestination == AdminDestination.dashboard) {
      Navigator.of(context).pushNamed(targetRoute);
    } else {
      Navigator.of(context).pushReplacementNamed(targetRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 300,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          right: Radius.circular(AppRadii.dialog),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppGradients.primary,
                      borderRadius: BorderRadius.circular(AppRadii.card),
                    ),
                    child: const Icon(
                      Icons.restaurant_rounded,
                      color: AppColors.surface,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ngô Chicken',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryEnd,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Flexible(
                              child: Text(
                                'Admin Workspace',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close menu',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.surfaceMuted, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                children: [
                  _DrawerItem(
                    key: const ValueKey('admin-drawer-dashboard'),
                    icon: Icons.dashboard_rounded,
                    title: 'Dashboard',
                    subtitle: 'Overview & metrics',
                    isSelected:
                        currentDestination == AdminDestination.dashboard,
                    onTap: () => _navigate(context, AdminDestination.dashboard),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Divider(color: AppColors.surfaceMuted, height: 1),
                  const SizedBox(height: AppSpacing.xs),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    child: Text(
                      'CATALOG',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textMuted,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _DrawerItem(
                    key: const ValueKey('admin-drawer-categories'),
                    icon: Icons.category_rounded,
                    title: 'Categories',
                    subtitle: 'Organize menu sections',
                    isSelected:
                        currentDestination == AdminDestination.categories,
                    onTap: () =>
                        _navigate(context, AdminDestination.categories),
                  ),
                  const SizedBox(height: 4),
                  _DrawerItem(
                    key: const ValueKey('admin-drawer-menu-items'),
                    icon: Icons.restaurant_menu_rounded,
                    title: 'Menu Items',
                    subtitle: 'Dishes, prices & availability',
                    isSelected:
                        currentDestination == AdminDestination.menuItems,
                    onTap: () => _navigate(context, AdminDestination.menuItems),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    child: Text(
                      'OPERATIONS',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textMuted,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _DrawerItem(
                    key: const ValueKey('admin-drawer-orders'),
                    icon: Icons.receipt_long_rounded,
                    title: 'Live Orders',
                    subtitle: 'Queue & kitchen progress',
                    isSelected: currentDestination == AdminDestination.orders,
                    onTap: () => _navigate(context, AdminDestination.orders),
                  ),
                  const SizedBox(height: 4),
                  _DrawerItem(
                    key: const ValueKey('admin-drawer-sales-report'),
                    icon: Icons.bar_chart_rounded,
                    title: 'Sales Report',
                    subtitle: 'Revenue, orders & top sellers',
                    isSelected:
                        currentDestination == AdminDestination.salesReport,
                    onTap: () =>
                        _navigate(context, AdminDestination.salesReport),
                  ),
                  const SizedBox(height: 4),
                  _DrawerItem(
                    key: const ValueKey('admin-drawer-broadcasts'),
                    icon: Icons.campaign_rounded,
                    title: 'Broadcasts',
                    subtitle: 'Promo & system notices',
                    isSelected:
                        currentDestination == AdminDestination.broadcasts,
                    onTap: () =>
                        _navigate(context, AdminDestination.broadcasts),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    child: Text(
                      'ACCOUNT',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textMuted,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _DrawerItem(
                    key: const ValueKey('admin-drawer-profile'),
                    icon: Icons.person_outline_rounded,
                    title: 'Profile',
                    subtitle: 'View admin profile',
                    isSelected: false,
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed(AppRoutes.profile);
                    },
                  ),
                  const SizedBox(height: 4),
                  _DrawerItem(
                    key: const ValueKey('admin-drawer-logout'),
                    icon: Icons.logout_rounded,
                    title: 'Sign Out',
                    subtitle: 'Exit admin workspace',
                    isSelected: false,
                    onTap: () async {
                      Navigator.of(context).pop();
                      try {
                        await ProviderScope.containerOf(
                          context,
                          listen: false,
                        ).read(authRepositoryProvider).signOut();
                      } catch (_) {}
                      if (context.mounted) {
                        AppRoutes.openLoginOverHome(Navigator.of(context));
                      }
                    },
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.surfaceMuted, height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  const Icon(
                    Icons.storefront_rounded,
                    color: AppColors.primaryEnd,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Ngô Chicken',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primarySoft : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryEnd
                      : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadii.medium),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected ? AppColors.surface : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected
                            ? AppColors.primaryEnd
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.primaryEnd,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
