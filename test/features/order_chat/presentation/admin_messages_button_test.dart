import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/app/router.dart';
import 'package:ordering_food_system/core/theme/app_theme.dart';
import 'package:ordering_food_system/features/auth/domain/entities/app_user.dart';
import 'package:ordering_food_system/features/auth/presentation/viewmodels/auth_providers.dart';
import 'package:ordering_food_system/features/order/presentation/viewmodels/admin_order_list_view_model.dart';
import 'package:ordering_food_system/features/order/presentation/views/admin_dashboard_screen.dart';
import 'package:ordering_food_system/features/order_chat/presentation/viewmodels/admin_unread_count_provider.dart';
import 'package:ordering_food_system/features/order_chat/presentation/viewmodels/order_chat_providers.dart';
import 'package:ordering_food_system/features/order_chat/presentation/widgets/admin_messages_button.dart';

import '../../../support/fake_order_chat_repository.dart';

const admin = AppUser(
  id: 'admin',
  fullName: 'Admin',
  email: '',
  phone: '',
  role: 'admin',
  status: 'active',
);

class CountRepository extends FakeOrderChatRepository {
  final counts = StreamController<int>.broadcast(sync: true);
  int subscriptions = 0;
  @override
  Stream<int> watchAdminUnreadCount() {
    subscriptions++;
    return counts.stream;
  }

  @override
  Future<void> close() async {
    await counts.close();
    await super.close();
  }
}

void main() {
  test('combines live counts across both kinds without inbox paging or read side effects', () async {
    final general = CountRepository(), orders = CountRepository();
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith((ref) => Stream.value(admin)),
        generalChatRepositoryProvider.overrideWithValue(general),
        orderChatRepositoryProvider.overrideWithValue(orders),
      ],
    );
    final sub = container.listen(adminUnreadCountProvider, (_, _) {});
    addTearDown(() async {
      sub.close();
      container.dispose();
      await general.close();
      await orders.close();
    });
    await container.read(authStateProvider.future);
    await container.pump();
    final loaded = Future.wait([
      container.read(adminUnreadCountByKindProvider(true).future),
      container.read(adminUnreadCountByKindProvider(false).future),
    ]);
    general.counts.add(2);
    orders.counts.add(3);
    await loaded;
    await container.pump();
    expect(container.read(adminUnreadCountProvider).requireValue, 5);
    general.counts.add(120);
    orders.counts.add(7);
    await Future<void>.delayed(Duration.zero);
    await container.pump();
    expect(container.read(adminUnreadCountProvider).requireValue, 127);
    general.counts.add(0);
    orders.counts.add(0);
    await Future<void>.delayed(Duration.zero);
    await container.pump();
    expect(container.read(adminUnreadCountProvider).requireValue, 0);
    expect(general.reads, isEmpty);
    expect(orders.reads, isEmpty);
  });

  for (final user in <AppUser?>[
    null,
    admin.copyWith(role: 'customer'),
    admin.copyWith(status: 'disabled'),
  ]) {
    test(
      'unauthorized session never subscribes to unread counts: ${user?.role}/${user?.status}',
      () async {
        final repository = CountRepository();
        final container = ProviderContainer(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(user)),
            generalChatRepositoryProvider.overrideWithValue(repository),
            orderChatRepositoryProvider.overrideWithValue(repository),
          ],
        );
        final sub = container.listen(adminUnreadCountProvider, (_, _) {});
        addTearDown(() async {
          sub.close();
          container.dispose();
          await repository.close();
        });
        await container.read(authStateProvider.future);
        await container.pump();
        expect(container.read(adminUnreadCountProvider).requireValue, 0);
        expect(repository.subscriptions, 0);
      },
    );
  }

  Future<void> pumpButton(
    WidgetTester tester,
    AsyncValue<int> count, {
    bool dashboard = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(admin)),
          adminUnreadCountProvider.overrideWithValue(count),
          adminOrdersProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: dashboard
              ? const AdminDashboardScreen()
              : const Scaffold(body: AdminMessagesButton()),
          routes: {
            AppRoutes.adminMessages: (_) =>
                const Scaffold(body: Text('Hộp tin nhắn')),
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets(
    'Dashboard has labelled shortcut with badge and opens inbox without drawer',
    (tester) async {
      await pumpButton(tester, const AsyncData(5), dashboard: true);
      expect(find.text('Tin nhắn'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('dashboard-messages-badge')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('dashboard-messages-button')));
      await tester.pumpAndSettle();
      expect(find.text('Hộp tin nhắn'), findsOneWidget);
    },
  );

  testWidgets('zero hides badge and 99+ fits 320px at scale 1.3', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpButton(tester, const AsyncData(0), dashboard: true);
    expect(
      find.byKey(const ValueKey('dashboard-messages-badge')),
      findsNothing,
    );
    await pumpButton(tester, const AsyncData(127), dashboard: true);
    expect(find.text('99+'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'loading and failure show status while keeping navigation enabled',
    (tester) async {
      await pumpButton(tester, const AsyncLoading());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await pumpButton(
        tester,
        AsyncError(Exception('unavailable'), StackTrace.current),
      );
      expect(find.byTooltip('Thử tải lại số chưa đọc'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('dashboard-messages-button')));
      await tester.pumpAndSettle();
      expect(find.text('Hộp tin nhắn'), findsOneWidget);
    },
  );
}
