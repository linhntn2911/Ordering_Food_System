import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/core/theme/app_theme.dart';
import 'package:ordering_food_system/features/menu/presentation/widgets/home_header.dart';

void main() {
  Future<void> pumpHeader(
    WidgetTester tester, {
    VoidCallback? onLoginTap,
    double width = 400,
    int unreadNotificationCount = 0,
    bool hasUnreadMessages = false,
    VoidCallback? onMessagesTap,
  }) {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: HomeHeader(
            onNotificationsTap: () {},
            onMessagesTap: onMessagesTap ?? () {},
            onLoginTap: onLoginTap,
            unreadNotificationCount: unreadNotificationCount,
            hasUnreadMessages: hasUnreadMessages,
          ),
        ),
      ),
    );
  }

  testWidgets('guest sees a login button that opens login', (tester) async {
    var taps = 0;
    await pumpHeader(tester, onLoginTap: () => taps++);

    expect(find.text('Đăng nhập'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('home-login')));
    expect(taps, 1);
  });

  testWidgets('signed-in user sees only the notification bell', (tester) async {
    await pumpHeader(tester);

    expect(find.byKey(const ValueKey('home-login')), findsNothing);
    expect(find.byKey(const ValueKey('home-messages')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-notifications')), findsOneWidget);
  });

  testWidgets('message icon opens chat and shows its unread indicator', (
    tester,
  ) async {
    var taps = 0;
    await pumpHeader(
      tester,
      hasUnreadMessages: true,
      onMessagesTap: () => taps++,
    );

    expect(find.byKey(const ValueKey('home-general-unread')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('home-messages')));
    expect(taps, 1);
  });

  testWidgets('shows the unread notification count on the bell', (
    tester,
  ) async {
    await pumpHeader(tester, unreadNotificationCount: 3);

    expect(
      find.byKey(const ValueKey('notification-unread-badge')),
      findsOneWidget,
    );
    expect(find.text('3'), findsOneWidget);
    expect(find.bySemanticsLabel('Có 3 thông báo chưa đọc'), findsOneWidget);
  });

  testWidgets('hides the badge when every notification is read', (
    tester,
  ) async {
    await pumpHeader(tester);

    expect(
      find.byKey(const ValueKey('notification-unread-badge')),
      findsNothing,
    );
  });

  testWidgets('narrow screens show the login button as an icon', (
    tester,
  ) async {
    await pumpHeader(tester, onLoginTap: () {}, width: 320);

    expect(find.byKey(const ValueKey('home-login')), findsOneWidget);
    expect(find.text('Đăng nhập'), findsNothing);
    expect(find.bySemanticsLabel('Đăng nhập'), findsOneWidget);
  });
}
