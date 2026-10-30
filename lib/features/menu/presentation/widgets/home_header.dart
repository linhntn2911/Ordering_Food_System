import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// "Tìm món bạn yêu thích" title with the notification bell.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.onNotificationsTap});

  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: const Text(
              'Tìm món\nbạn yêu thích',
              style: AppTextStyles.headlineLarge,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            boxShadow: [AppShadows.card],
          ),
          child: IconButton(
            key: const ValueKey('home-notifications'),
            tooltip: 'Thông báo',
            onPressed: onNotificationsTap,
            icon: const Icon(
              Icons.notifications_none_rounded,
              size: 24,
              color: AppColors.primaryEnd,
            ),
            constraints: const BoxConstraints.tightFor(
              width: AppSpacing.minTouchTarget,
              height: AppSpacing.minTouchTarget,
            ),
          ),
        ),
      ],
    );
  }
}
