import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/core/theme/app_theme.dart';
import 'package:ordering_food_system/features/notifications/models/notification_model.dart';
import 'package:ordering_food_system/features/notifications/providers/notification_provider.dart';
import 'package:ordering_food_system/features/notifications/repositories/notification_repository.dart';
import 'package:ordering_food_system/features/notifications/viewmodels/admin_broadcast_view_model.dart';
import 'package:ordering_food_system/features/notifications/views/screens/admin_broadcast_screen.dart';

void main() {
  group('AdminBroadcastViewModel Tests', () {
    test('Validation fails when title is empty', () async {
      final container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(
            MockNotificationRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(
        adminBroadcastViewModelProvider.notifier,
      );

      final success = await notifier.sendBroadcast(
        title: '   ',
        body: 'Nội dung giảm giá',
        type: NotificationType.promo,
      );

      expect(success, isFalse);
      final state = container.read(adminBroadcastViewModelProvider);
      expect(state.errorMessage, contains('tiêu đề'));
      expect(state.isSuccess, isFalse);
    });

    test('Validation fails when body is empty', () async {
      final container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(
            MockNotificationRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(
        adminBroadcastViewModelProvider.notifier,
      );

      final success = await notifier.sendBroadcast(
        title: 'Siêu sale 50%',
        body: '   ',
        type: NotificationType.promo,
      );

      expect(success, isFalse);
      final state = container.read(adminBroadcastViewModelProvider);
      expect(state.errorMessage, contains('nội dung'));
      expect(state.isSuccess, isFalse);
    });

    test('Successfully broadcasts promo notification and adds to repository', () async {
      final repo = MockNotificationRepository();
      final container = ProviderContainer(
        overrides: [notificationRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(
        adminBroadcastViewModelProvider.notifier,
      );

      final success = await notifier.sendBroadcast(
        title: 'Siêu giảm giá gà rán 25%',
        body: 'Áp dụng cho toàn bộ combo gia đình hôm nay!',
        type: NotificationType.promo,
      );

      expect(success, isTrue);
      final state = container.read(adminBroadcastViewModelProvider);
      expect(state.isSuccess, isTrue);
      expect(state.errorMessage, isNull);

      final notifications = await repo.getNotifications();
      final added = notifications.first;
      expect(added.title, 'Siêu giảm giá gà rán 25%');
      expect(added.body, 'Áp dụng cho toàn bộ combo gia đình hôm nay!');
      expect(added.type, NotificationType.promo);
    });
  });

  group('AdminBroadcastScreen Widget Tests', () {
    testWidgets('Renders compose form, inputs, chips, and sends broadcast', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final repo = MockNotificationRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [notificationRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const AdminBroadcastScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Screen Header
      expect(find.text('Phát thông báo hệ thống'), findsOneWidget);
      expect(find.text('Tạo thông báo & ưu đãi mới'), findsOneWidget);

      // Verify Type Chips
      expect(find.text('Ưu đãi / Giảm giá'), findsOneWidget);
      expect(find.text('Hệ thống'), findsWidgets);

      // Verify Form inputs
      expect(find.byKey(const ValueKey('broadcast-title-input')), findsOneWidget);
      expect(find.byKey(const ValueKey('broadcast-body-input')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('broadcast-send-button')),
        findsOneWidget,
      );

      // Verify preloaded promo notifications in history
      expect(find.text('Ưu đãi hôm nay'), findsOneWidget);

      // Enter new broadcast info
      await tester.enterText(
        find.byKey(const ValueKey('broadcast-title-input')),
        'Khuyến mãi Combo Gà Ròn 49K',
      );
      await tester.enterText(
        find.byKey(const ValueKey('broadcast-body-input')),
        'Chỉ trong 2 giờ vàng từ 11h đến 13h trưa nay.',
      );

      // Tap Send Button
      await tester.tap(find.byKey(const ValueKey('broadcast-send-button')));
      await tester.pumpAndSettle();

      // Verify SnackBar success
      expect(
        find.text('Đã phát thông báo thành công đến khách hàng!'),
        findsOneWidget,
      );

      // Verify Form inputs are cleared
      final titleField = tester.widget<TextFormField>(
        find.byKey(const ValueKey('broadcast-title-input')),
      );
      expect(titleField.controller?.text, isEmpty);

      // Verify new broadcast appears in history list
      expect(find.text('Khuyến mãi Combo Gà Ròn 49K'), findsOneWidget);
      expect(
        find.text('Chỉ trong 2 giờ vàng từ 11h đến 13h trưa nay.'),
        findsOneWidget,
      );
    });
  });
}
