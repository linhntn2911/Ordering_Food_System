import 'package:flutter/material.dart';

import '../features/auth/presentation/views/forgot_password_view.dart';
import '../features/auth/presentation/views/login_view.dart';
import '../features/auth/presentation/views/register_view.dart';
import '../features/category/presentation/views/category_management_screen.dart';
import '../features/menu/presentation/views/admin_menu_item_list_screen.dart';
import '../features/notifications/views/screens/notification_detail_screen.dart';
import '../features/notifications/views/screens/notification_list_screen.dart';
import '../features/onboarding/presentation/views/onboarding_view.dart';
import '../features/order/presentation/views/admin_dashboard_screen.dart';
import '../features/order/presentation/views/admin_order_list_screen.dart';
import '../features/order/presentation/views/sales_report_screen.dart';
import '../features/order_history/presentation/views/order_history_view.dart';
import '../features/order_tracking/views/screens/order_detail_screen.dart';
import '../features/order_tracking/views/screens/order_tracking_timeline_screen.dart';
import '../features/profile/presentation/views/profile_view.dart';
import '../features/review/views/screens/my_reviews_screen.dart';
import '../features/review/views/screens/write_review_screen.dart';
import 'admin_gate.dart';
import 'main_shell.dart';

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

  // Customer features from Member 4 (Tienpq)
  static const String orderHistory = '/order-history';
  static const String orderDetail = '/order-detail';
  static const String orderTracking = '/order-tracking';
  static const String writeReview = '/write-review';
  static const String myReviews = '/my-reviews';
  static const String notifications = '/notifications';
  static const String notificationDetail = '/notification-detail';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final uri = Uri.tryParse(settings.name ?? '') ?? Uri();
    final args = settings.arguments is Map<String, dynamic>
        ? (settings.arguments as Map<String, dynamic>)
        : null;

    switch (uri.path) {
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
      case Navigator.defaultRouteName:
      case '':
      case home:
        return MaterialPageRoute(builder: (_) => const MainShell());
      case adminDashboard:
        return _adminRoute(const AdminDashboardScreen());
      case adminCategories:
        return _adminRoute(const CategoryManagementScreen());
      case adminMenuItems:
        return _adminRoute(const AdminMenuItemListScreen());
      case adminOrders:
        return _adminRoute(const AdminOrderListScreen());
      case adminSalesReport:
        return _adminRoute(const SalesReportScreen());
      case orderHistory:
        return MaterialPageRoute(builder: (_) => const OrderHistoryView());
      case orderDetail: {
        final orderId = uri.queryParameters['orderId'] ??
            (args?['orderId'] as String?) ??
            (settings.arguments is String ? settings.arguments as String : '');
        return MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: orderId));
      }
      case orderTracking: {
        final orderId = uri.queryParameters['orderId'] ??
            (args?['orderId'] as String?) ??
            (settings.arguments is String ? settings.arguments as String : '');
        return MaterialPageRoute(builder: (_) => OrderTrackingTimelineScreen(orderId: orderId));
      }
      case writeReview: {
        final orderId = uri.queryParameters['orderId'] ??
            (args?['orderId'] as String?) ??
            (settings.arguments is String ? settings.arguments as String : '');
        return MaterialPageRoute(builder: (_) => WriteReviewScreen(orderId: orderId));
      }
      case myReviews:
        return MaterialPageRoute(builder: (_) => const MyReviewsScreen());
      case notifications:
        return MaterialPageRoute(builder: (_) => const NotificationListScreen());
      case notificationDetail: {
        final notificationId = uri.queryParameters['notificationId'] ??
            (args?['notificationId'] as String?) ??
            '';
        final orderId = uri.queryParameters['orderId'] ??
            (args?['orderId'] as String?) ??
            '';
        return MaterialPageRoute(
          builder: (_) => NotificationDetailScreen(
            notificationId: notificationId,
            orderId: orderId,
          ),
        );
      }
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }

  static Route<dynamic> _adminRoute(Widget screen) {
    return MaterialPageRoute(builder: (_) => AdminGate(child: screen));
  }
}
