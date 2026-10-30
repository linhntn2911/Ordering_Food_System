import 'package:flutter/material.dart';

import '../core/config/restaurant_info.dart';
import '../core/theme/app_theme.dart';
import 'main_shell.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: RestaurantInfo.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      home: const MainShell(),
    );
  }
}
