import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_radii.dart';
import '../core/theme/app_shadows.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/coming_soon_view.dart';
import '../features/menu/presentation/views/home_view.dart';

/// Customer app shell with the bottom tabs Home, Cart, Orders and Profile.
///
/// Tabs live in an [IndexedStack] so Home keeps its scroll position and
/// selection while another tab is shown.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static const tabs = [
    _ShellTab('Trang chủ', Icons.home_rounded),
    _ShellTab('Giỏ hàng', Icons.shopping_cart_rounded),
    _ShellTab('Đơn hàng', Icons.receipt_long_rounded),
    _ShellTab('Tài khoản', Icons.person_rounded),
  ];

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          const HomeView(),
          for (final tab in MainShell.tabs.skip(1))
            ComingSoonView(title: tab.label, icon: tab.icon),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.large),
              boxShadow: const [AppShadows.card],
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  for (var i = 0; i < MainShell.tabs.length; i++)
                    Expanded(
                      flex: i == _index ? 2 : 1,
                      child: _TabButton(
                        key: ValueKey('shell-tab-$i'),
                        tab: MainShell.tabs[i],
                        selected: i == _index,
                        onTap: () => setState(() => _index = i),
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
                  const SizedBox(width: AppSpacing.sm),
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
