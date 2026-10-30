import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// "Tìm món bạn yêu thích" title with the notification bell, plus a login
/// button for guests. Signed-in users reach their profile from the
/// "Tài khoản" tab instead.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.onNotificationsTap,
    this.onLoginTap,
  });

  final VoidCallback onNotificationsTap;

  /// Shows the login button when not null.
  final VoidCallback? onLoginTap;

  @override
  Widget build(BuildContext context) {
    // Narrow screens show the login button as an icon only.
    final compact = MediaQuery.sizeOf(context).width < 360;
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
        if (onLoginTap case final onLoginTap?) ...[
          const SizedBox(width: AppSpacing.p12),
          _LoginButton(onTap: onLoginTap, compact: compact),
        ],
        const SizedBox(width: AppSpacing.p12),
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

class _LoginButton extends StatelessWidget {
  const _LoginButton({required this.onTap, required this.compact});

  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Đăng nhập',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.pill)),
          boxShadow: [AppShadows.primary],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: const ValueKey('home-login'),
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: AppSpacing.minTouchTarget,
                minHeight: AppSpacing.minTouchTarget,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 0 : AppSpacing.p16,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.login_rounded,
                      size: 20,
                      color: AppColors.surface,
                    ),
                    if (!compact) ...[
                      const SizedBox(width: AppSpacing.p8),
                      Text(
                        'Đăng nhập',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.surface,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
