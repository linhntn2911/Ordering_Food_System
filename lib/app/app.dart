import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/order/presentation/views/admin_dashboard_screen.dart';

class FoodOrderingApp extends StatelessWidget {
  const FoodOrderingApp({
    this.showPreviewBanner = false,
    this.initialHome,
    super.key,
  });

  final bool showPreviewBanner;
  final Widget? initialHome;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ngô Chicken',
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      builder: (context, child) {
        if (child == null) {
          return const SizedBox.shrink();
        }
        if (!showPreviewBanner) {
          return child;
        }
        return Banner(
          message: 'PREVIEW DATA',
          location: BannerLocation.topEnd,
          child: child,
        );
      },
      home: initialHome ?? const AdminDashboardScreen(),
    );
  }
}
