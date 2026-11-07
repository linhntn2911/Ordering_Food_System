import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/widgets/food_ninja_background.dart';
import '../core/widgets/food_ninja_logo.dart';
import '../features/auth/presentation/viewmodels/auth_providers.dart';
import '../features/auth/presentation/views/login_view.dart';
import '../features/onboarding/presentation/views/onboarding_view.dart';
import '../features/order/presentation/views/admin_dashboard_screen.dart';
import 'admin_gate.dart';
import 'main_shell.dart';

/// Resolves onboarding and the persisted Firebase session before choosing the
/// first screen. This prevents Login from flashing while Firebase restores a
/// previously authenticated Customer or Admin.
class AppStartupGate extends ConsumerWidget {
  const AppStartupGate({required this.isOnboardingCompleted, super.key});

  final bool isOnboardingCompleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isOnboardingCompleted) {
      return const OnboardingView();
    }

    final authState = ref.watch(authStateProvider);
    return authState.when(
      loading: () => const _AuthRestoringView(),
      error: (_, _) => const LoginView(),
      data: (user) {
        if (user == null) return const LoginView();
        if (user.isAdmin) {
          return const AdminGate(child: AdminDashboardScreen());
        }
        return const MainShell();
      },
    );
  }
}

class _AuthRestoringView extends StatelessWidget {
  const _AuthRestoringView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      key: ValueKey('auth-restoring'),
      backgroundColor: AppColors.background,
      body: FoodNinjaBackground(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FoodNinjaLogo(iconSize: 72, titleFontSize: 28),
                SizedBox(height: AppSpacing.p32),
                CircularProgressIndicator(color: AppColors.primaryEnd),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
