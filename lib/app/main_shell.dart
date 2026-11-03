import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_radii.dart';
import '../core/theme/app_shadows.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../features/auth/presentation/viewmodels/auth_providers.dart';
import '../features/cart/presentation/views/cart_screen.dart';
import '../features/checkout/presentation/views/checkout_screen.dart';
import '../features/menu/presentation/views/home_view.dart';
import '../features/order_history/presentation/views/order_history_view.dart';
import '../features/profile/presentation/views/profile_view.dart';
import 'router.dart';
import 'main_shell_controller.dart';

/// Customer app shell with the bottom tabs Home, Cart, Orders and Profile.
///
/// The Cart tab is shown only to a signed-in user. Tabs live in an
/// [IndexedStack] so Home keeps its scroll position and selection while
/// another tab is shown.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  static const tabs = [
    _ShellTab('Trang chủ', Icons.home_rounded),
    _ShellTab('Giỏ hàng', Icons.shopping_cart_rounded),
    _ShellTab('Đơn hàng', Icons.receipt_long_rounded),
    _ShellTab('Tài khoản', Icons.person_rounded),
  ];

  /// Index of the Cart tab in [tabs].
  static const cartTab = 1;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(authStateProvider).value != null;
    final index = ref.watch(mainShellTabProvider);
    final visibleTabs = [
      for (var i = 0; i < MainShell.tabs.length; i++)
        if (signedIn || i != MainShell.cartTab) i,
    ];
    final selected = visibleTabs.contains(index) ? index : MainShellTab.home;

    return Scaffold(
      body: IndexedStack(
        index: selected,
        children: [
          const HomeView(),
          CartScreen(
            onNavigateToCheckout: _openCheckout,
            onBrowseMenu: () => ref
                .read(mainShellTabProvider.notifier)
                .select(MainShellTab.home),
          ),
          const OrderHistoryView(),
          const ProfileView(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.p16,
            0,
            AppSpacing.p16,
            AppSpacing.p16,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.large),
              boxShadow: const [AppShadows.card],
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.p8),
              child: Row(
                children: [
                  for (final i in visibleTabs)
                    Expanded(
                      flex: i == selected ? 2 : 1,
                      child: _TabButton(
                        key: ValueKey('shell-tab-$i'),
                        tab: MainShell.tabs[i],
                        selected: i == selected,
                        onTap: () =>
                            ref.read(mainShellTabProvider.notifier).select(i),
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

  Future<void> _openCheckout() async {
    final action = await Navigator.of(context)
        .pushNamed<CheckoutSuccessAction>(AppRoutes.checkout);
    if (!mounted || action == null) return;

    ref
        .read(mainShellTabProvider.notifier)
        .select(
          action == CheckoutSuccessAction.viewOrders
              ? MainShellTab.orders
              : MainShellTab.cart,
        );
  }
}

class _ShellTab {
  const _ShellTab(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    super.key,
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final _ShellTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.medium);
    final color = selected ? AppColors.primaryEnd : AppColors.textMuted;

    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: selected ? AppColors.primarySoft : AppColors.surface,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: SizedBox(
            height: AppSpacing.minTouchTarget,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(tab.icon, size: 24, color: color),
                if (selected) ...[
                  const SizedBox(width: AppSpacing.p8),
                  Flexible(
                    child: Text(
                      tab.label,
                      style: AppTextStyles.labelLarge.copyWith(color: color),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
