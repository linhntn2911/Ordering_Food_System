import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'router.dart';

class FoodOrderingApp extends StatelessWidget {
  const FoodOrderingApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Onboarding is currently skipped so users go straight to authentication.
    const initialRoute = AppRoutes.login;

    return MaterialApp(
      title: 'Ngô Chicken',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      initialRoute: initialRoute,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
