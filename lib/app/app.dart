import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/restaurant_info.dart';
import '../core/services/preferences_service.dart';
import '../core/theme/app_theme.dart';
import 'app_startup_gate.dart';
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
    var isOnboardingCompleted = true;
    if (initialHome == null && initialRoute == null) {
      try {
        final prefs = ref.watch(preferencesServiceProvider);
        isOnboardingCompleted = prefs.isOnboardingCompleted;
      } catch (_) {
        // Tests or previews without SharedPreferences skip onboarding.
        isOnboardingCompleted = true;
      }
    }

    final startupHome =
        initialHome ??
        (initialRoute == null
            ? AppStartupGate(isOnboardingCompleted: isOnboardingCompleted)
            : null);

    return MaterialApp(
      title: RestaurantInfo.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      locale: const Locale('vi', 'VN'),
      supportedLocales: const [Locale('vi', 'VN')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) {
        if (child == null) {
          return const SizedBox.shrink();
        }
        if (!showPreviewBanner) {
          return child;
        }
        return Banner(
          message: 'DỮ LIỆU XEM TRƯỚC',
          location: BannerLocation.topEnd,
          child: child,
        );
      },
      home: startupHome,
      initialRoute: startupHome == null ? initialRoute : null,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
