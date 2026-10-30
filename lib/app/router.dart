import 'package:flutter/material.dart';

import '../features/auth/presentation/views/forgot_password_view.dart';
import '../features/auth/presentation/views/login_view.dart';
import '../features/auth/presentation/views/register_view.dart';
import '../features/category/presentation/views/category_management_screen.dart';
import '../features/menu/presentation/views/admin_menu_item_list_screen.dart';
import '../features/onboarding/presentation/views/onboarding_view.dart';
import '../features/order/presentation/views/admin_dashboard_screen.dart';
import '../features/order/presentation/views/admin_order_list_screen.dart';
import '../features/order/presentation/views/sales_report_screen.dart';
import '../features/profile/presentation/views/profile_view.dart';

abstract final class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String profile = '/profile';
  static const String home = '/home';
  static const String adminDashboard = '/admin-dashboard';
  static const String adminCategories = '/admin/categories';
  static const String adminMenuItems = '/admin/menu-items';
  static const String adminOrders = '/admin/orders';
  static const String adminSalesReport = '/admin/sales-report';

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
            appBar: AppBar(title: const Text('Ngô Chicken')),
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
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
      case adminCategories:
        return MaterialPageRoute(
          builder: (_) => const CategoryManagementScreen(),
        );
      case adminMenuItems:
        return MaterialPageRoute(
          builder: (_) => const AdminMenuItemListScreen(),
        );
      case adminOrders:
        return MaterialPageRoute(
          builder: (_) => const AdminOrderListScreen(),
        );
      case adminSalesReport:
        return MaterialPageRoute(
          builder: (_) => const SalesReportScreen(),
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
