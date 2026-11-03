import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/firebase/firebase_providers.dart';
import '../core/theme/app_colors.dart';
import '../features/auth/presentation/viewmodels/auth_providers.dart';
import 'router.dart';

/// Shows [child] only to an active Admin and sends anyone else to login,
/// opened over Home so the login back button leads to the storefront.
///
/// On web an admin URL can be reopened after sign-out or a restart, so the
/// screen must not assume the Admin session still exists. Firestore rules
/// still enforce access; this only avoids a screen of permission errors.
class AdminGate extends ConsumerWidget {
  const AdminGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    final firebaseUser = ref.watch(firebaseAuthProvider).currentUser;

    if (firebaseUser != null &&
        user != null &&
        user.id == firebaseUser.uid &&
        user.isAdmin &&
        user.isActive) {
      return child;
    }
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryEnd),
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        AppRoutes.openLoginOverHome(Navigator.of(context));
      }
    });
    return const Scaffold(body: SizedBox.shrink());
  }
}
