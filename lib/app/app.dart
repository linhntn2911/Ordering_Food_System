import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'router.dart';

class FoodOrderingApp extends StatelessWidget {
  const FoodOrderingApp({
    this.showPreviewBanner = false,
    this.initialHome,
    this.initialRoute,
    super.key,
  });

  final bool showPreviewBanner;
  final Widget? initialHome;
  final String? initialRoute;

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
      home: initialHome,
      initialRoute: initialHome == null
          ? (initialRoute ?? AppRoutes.login)
          : null,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
