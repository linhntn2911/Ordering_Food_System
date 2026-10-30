import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class FoodNinjaLogo extends StatelessWidget {
  final double iconSize;
  final double titleFontSize;
  final bool showSubtitle;

  const FoodNinjaLogo({
    super.key,
    this.iconSize = 80.0,
    this.titleFontSize = 32.0,
    this.showSubtitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Food Ninja Icon
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryEnd.withValues(alpha: 0.25),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.restaurant_rounded,
              color: Colors.white,
              size: iconSize * 0.52,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.p12),

        // FoodNinja Gradient Text
        ShaderMask(
          shaderCallback: (bounds) =>
              AppColors.primaryGradient.createShader(bounds),
          child: Text(
            'Ngô Chicken',
            style: AppTextStyles.headlineLarge.copyWith(
              fontSize: titleFontSize,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),

        // Subtitle
        if (showSubtitle) ...[
          const SizedBox(height: AppSpacing.p4),
          Text(
            'Deliver Favorite Food',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ],
    );
  }
}
