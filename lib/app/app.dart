import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/restaurant_info.dart';
import '../core/services/preferences_service.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

class FoodOrderingApp extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    String defaultRoute = AppRoutes.login;
    if (initialHome == null && initialRoute == null) {
      try {
        final prefs = ref.watch(preferencesServiceProvider);
        defaultRoute = prefs.isOnboardingCompleted
            ? AppRoutes.login
            : AppRoutes.onboarding;
      } catch (_) {
        defaultRoute = AppRoutes.login;
      }
    }

    return MaterialApp(
      title: RestaurantInfo.name,
      debugShowCheckedModeBanner: false,
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
      initialRoute: initialHome == null ? (initialRoute ?? defaultRoute) : null,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
