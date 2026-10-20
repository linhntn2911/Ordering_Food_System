import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/preferences_service.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

class FoodOrderingApp extends ConsumerWidget {
  const FoodOrderingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesServiceProvider);
    final initialRoute = prefs.isOnboardingCompleted
        ? AppRoutes.login
        : AppRoutes.onboarding;

    return MaterialApp(
      title: 'Food Ninja',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      initialRoute: initialRoute,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
