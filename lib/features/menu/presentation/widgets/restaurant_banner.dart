import 'package:flutter/material.dart';

import '../../../../core/config/restaurant_info.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Restaurant introduction banner (not a promotion).
class RestaurantBanner extends StatelessWidget {
  const RestaurantBanner({super.key, required this.onViewMenu});

  final VoidCallback onViewMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.p20),
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(AppRadii.large),
        boxShadow: const [AppShadows.primary],
      ),
      child: Row(
        children: [
          const ExcludeSemantics(
            child: Icon(
              Icons.lunch_dining_rounded,
              size: 72,
              color: AppColors.surface,
            ),
          ),
          const SizedBox(width: AppSpacing.p16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  RestaurantInfo.name,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.surface,
                  ),
                ),
                const SizedBox(height: AppSpacing.p4),
                Text(
                  RestaurantInfo.tagline,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.surface,
                  ),
                ),
                const SizedBox(height: AppSpacing.p12),
                FilledButton(
                  key: const ValueKey('home-view-menu'),
                  onPressed: onViewMenu,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.primaryEnd,
                    minimumSize: const Size(0, AppSpacing.minTouchTarget),
                    textStyle: AppTextStyles.labelLarge,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.medium),
                    ),
                  ),
                  child: const Text('Mua ngay'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
