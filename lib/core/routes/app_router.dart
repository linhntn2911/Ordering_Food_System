import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:oder_food/core/constants/app_routes.dart';
import 'package:oder_food/features/notifications/views/screens/notification_detail_screen.dart';
import 'package:oder_food/features/notifications/views/screens/notification_list_screen.dart';
import 'package:oder_food/features/order_history/views/screens/order_history_screen.dart';
import 'package:oder_food/features/order_tracking/views/screens/order_detail_screen.dart';
import 'package:oder_food/features/order_tracking/views/screens/order_tracking_timeline_screen.dart';
import 'package:oder_food/features/review/views/screens/my_reviews_screen.dart';
import 'package:oder_food/features/review/views/screens/write_review_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(path: AppRoutes.home, name: 'home', builder: (context, state) => const OrderHistoryScreen()),
      GoRoute(path: AppRoutes.orderHistory, name: 'orderHistory', builder: (context, state) => const OrderHistoryScreen()),
      GoRoute(path: AppRoutes.orderDetail, name: 'orderDetail', builder: (context, state) {
        final orderId = state.uri.queryParameters['orderId'] ?? '';
        return OrderDetailScreen(orderId: orderId);
      }),
      GoRoute(path: AppRoutes.orderTracking, name: 'orderTracking', builder: (context, state) {
        final orderId = state.uri.queryParameters['orderId'] ?? '';
        return OrderTrackingTimelineScreen(orderId: orderId);
      }),
      GoRoute(path: AppRoutes.writeReview, name: 'writeReview', builder: (context, state) {
        final orderId = state.uri.queryParameters['orderId'] ?? '';
        return WriteReviewScreen(orderId: orderId);
      }),
      GoRoute(path: AppRoutes.myReviews, name: 'myReviews', builder: (context, state) => const MyReviewsScreen()),
      GoRoute(path: AppRoutes.notifications, name: 'notifications', builder: (context, state) => const NotificationListScreen()),
      GoRoute(path: AppRoutes.notificationDetail, name: 'notificationDetail', builder: (context, state) {
        final notificationId = state.uri.queryParameters['notificationId'] ?? '';
        final orderId = state.uri.queryParameters['orderId'] ?? '';
        return NotificationDetailScreen(notificationId: notificationId, orderId: orderId);
      }),
    ],
    errorBuilder: (context, state) => Scaffold(body: Center(child: Text('Page not found: ${state.error}'))),
  );
}
