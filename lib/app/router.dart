import 'package:flutter/material.dart';
import 'package:ordering_food_system/features/auth/presentation/views/forgot_password_view.dart';
import 'package:ordering_food_system/features/auth/presentation/views/login_view.dart';
import 'package:ordering_food_system/features/auth/presentation/views/register_view.dart';
import 'package:ordering_food_system/features/onboarding/presentation/views/onboarding_view.dart';
import 'package:ordering_food_system/features/profile/presentation/views/profile_view.dart';

abstract final class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String profile = '/profile';
  static const String home = '/home';
  static const String adminDashboard = '/admin-dashboard';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingView());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginView());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterView());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordView());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileView());
      case home:
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Food Ninja Home')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Customer Home Screen (Member 2)'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pushNamed(profile),
                    child: const Text('Go to Profile'),
                  ),
                ],
              ),
            ),
          ),
        );
      case adminDashboard:
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Admin Dashboard')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Admin Order Management (Member 5)'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pushNamed(profile),
                    child: const Text('Admin Profile'),
                  ),
                ],
              ),
            ),
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
