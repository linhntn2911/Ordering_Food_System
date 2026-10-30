import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_empty_view.dart';

/// Placeholder for a tab whose feature has not been delivered yet.
class ComingSoonView extends StatelessWidget {
  const ComingSoonView({super.key, required this.title, required this.icon});

  static const message = 'Tính năng đang được phát triển';

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: AppEmptyView(title: title, message: message, icon: icon),
        ),
      ),
    );
  }
}
