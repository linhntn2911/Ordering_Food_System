import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Shown on customer tabs that need an account, such as Orders and Profile,
/// when nobody is signed in.
class SignInRequiredView extends StatelessWidget {
  const SignInRequiredView({
    super.key,
    this.icon = Icons.person_off_outlined,
    this.onLoginClosed,
  });

  final IconData icon;

  /// Called after the Login screen closes, for example to refresh state.
  final VoidCallback? onLoginClosed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.p16),
          const Text(
            'Không có phiên đăng nhập',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.p16),
          ElevatedButton(
            key: const ValueKey('sign-in-required-login'),
            onPressed: () async {
              await Navigator.of(context).pushNamed(AppRoutes.login);
              onLoginClosed?.call();
            },
            child: const Text('Đi đến Đăng nhập'),
          ),
        ],
      ),
    );
  }
}
