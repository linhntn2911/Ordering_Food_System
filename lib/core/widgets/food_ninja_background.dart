import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Renders the signature Food Ninja organic background decoration
/// found across 1.1 Onboarding, 1.4 Sign Up, and 1.5 Sign In in the Figma UI kit.
class FoodNinjaBackground extends StatelessWidget {
  final Widget child;

  const FoodNinjaBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top-right subtle green decorative blur glow
        Positioned(
          top: -100,
          right: -80,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primaryStart.withValues(alpha: 0.18),
                  AppColors.primaryEnd.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),

        // Top-left subtle warm accent blur glow
        Positioned(
          top: -60,
          left: -80,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.warningSoft.withValues(alpha: 0.15),
                  AppColors.warningSurface.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),

        // Screen content
        child,
      ],
    );
  }
}
