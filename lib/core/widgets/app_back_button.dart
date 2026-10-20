import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const AppBackButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed ?? () => Navigator.of(context).maybePop(),
      borderRadius: AppSpacing.roundedMedium,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: AppColors.warningSurface,
          borderRadius: AppSpacing.roundedMedium,
        ),
        child: const Center(
          child: Icon(
            Icons.chevron_left_rounded,
            color: AppColors.foodAccentDark,
            size: 28,
          ),
        ),
      ),
    );
  }
}
