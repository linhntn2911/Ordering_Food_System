import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/core/theme/app_theme.dart';
import 'package:ordering_food_system/app/router.dart';
import 'package:ordering_food_system/features/auth/presentation/views/login_view.dart';
import 'package:ordering_food_system/features/auth/domain/entities/app_user.dart';
import 'package:ordering_food_system/features/auth/presentation/viewmodels/auth_providers.dart';
import 'package:ordering_food_system/features/order_chat/domain/entities/chat_failure.dart';
import 'package:ordering_food_system/features/order_chat/domain/entities/chat_role.dart';
import 'package:ordering_food_system/features/order_chat/presentation/viewmodels/order_chat_providers.dart';
import 'package:ordering_food_system/features/order_chat/presentation/viewmodels/admin_messages_view_model.dart';
import 'package:ordering_food_system/features/order_chat/presentation/views/general_chat_screen.dart';
import 'package:ordering_food_system/features/order_chat/presentation/views/admin_messages_screen.dart';
import 'package:ordering_food_system/features/order_chat/presentation/widgets/home_order_support_button.dart';

import '../../../support/fake_order_chat_repository.dart';
import '../../../support/order_chat_order_fixture.dart';

const customer = AppUser(
  id: 'customer',
  fullName: 'Khách',
  email: '',
  phone: '',
  role: 'customer',
  status: 'active',
);

void main() {
  late FakeOrderChatRepository general;
  late FakeOrderChatRepository orders;
  setUp(() {
    general = FakeOrderChatRepository();
    orders = FakeOrderChatRepository();
  });
  tearDown(() async {
    await general.close();
    await orders.close();
  });

  Widget app({
    AppUser? user = customer,
    Widget child = const GeneralChatScreen(),
  }) => ProviderScope(
    overrides: [
      authStateProvider.overrideWith((ref) => Stream.value(user)),
      generalChatRepositoryProvider.overrideWithValue(general),
      orderChatRepositoryProvider.overrideWithValue(orders),
      generalChatUnreadProvider.overrideWith((ref) => Stream.value(true)),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(1.3)),
        child: child!,
      ),
      home: child,
    ),
  );

  testWidgets(
    'Home opens general chat without an order and preserves retry ID',
    (tester) async {
      await tester.pumpWidget(
        app(
          child: const Scaffold(floatingActionButton: HomeOrderSupportButton()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('home-general-unread')), findsOneWidget);
      await tester.tap(find.byTooltip('Nhắn nhà hàng'));
      await tester.pumpAndSettle();
      expect(find.text('Hỗ trợ chung'), findsOneWidget);
      expect(find.text('Chi tiết đơn'), findsNothing);
      general.nextSendFailure = ChatFailure.unavailable;
      await tester.enterText(
        find.byKey(const ValueKey('chat-text')),
        'Quán mở đến mấy giờ?',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('chat-send')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('chat-send')));
      await tester.pumpAndSettle();
      expect(general.sends, hasLength(2));
      expect(general.sends.first.id, general.sends.last.id);
      expect(general.sends.first.orderId, customer.id);
      expect(orders.sends, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Guest and foreign customer cannot enter a general conversation',
    (tester) async {
      await tester.pumpWidget(app(user: null));
      await tester.pumpAndSettle();
      expect(find.text('Đăng nhập để nhắn nhà hàng'), findsOneWidget);
      expect(find.byKey(const ValueKey('chat-composer')), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        app(child: const GeneralChatScreen(customerId: 'foreign')),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Bạn không có quyền xem cuộc trò chuyện này.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('Admin inbox switches independent general/order histories', (
    tester,
  ) async {
    general.adminChats = [
      chatFixture(orderId: 'customer', unreadByAdmin: true),
    ];
    orders.adminChats = [chatFixture(orderId: 'order-one')];
    await tester.pumpWidget(
      app(
        user: customer.copyWith(id: 'admin', role: 'admin'),
        child: const AdminMessagesScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('inbox-true-customer')), findsOneWidget);
    await tester.tap(find.text('Theo đơn'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('inbox-false-order-one')), findsOneWidget);
    expect(find.byKey(const ValueKey('inbox-true-customer')), findsNothing);
  });

  testWidgets(
    'general chat sends at 320px with text scale 1.3 and marks only general read',
    (tester) async {
      tester.view.physicalSize = const Size(320, 680);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      general.chat = chatFixture(orderId: 'customer', unreadByCustomer: true);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('chat-text')),
        'Cho mình hỏi về món ăn',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('chat-send')));
      await tester.pumpAndSettle();
      expect(general.sends.single.role, ChatRole.customer);
      expect(general.reads.single.orderId, customer.id);
      expect(orders.reads, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('account switch discards general draft and binds the new UID', (
    tester,
  ) async {
    final accounts = StreamController<AppUser?>.broadcast();
    addTearDown(accounts.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => accounts.stream),
          generalChatRepositoryProvider.overrideWithValue(general),
          orderChatRepositoryProvider.overrideWithValue(orders),
        ],
        child: const MaterialApp(home: GeneralChatScreen()),
      ),
    );
    accounts.add(customer);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('chat-text')),
      'Bản nháp của khách cũ',
    );
    await tester.pump();
    accounts.add(customer.copyWith(id: 'second-customer'));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('chat-text')),
    );
    expect(field.controller!.text, isEmpty);
    await tester.enterText(
      find.byKey(const ValueKey('chat-text')),
      'Câu hỏi của khách mới',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('chat-send')));
    await tester.pumpAndSettle();
    expect(general.sends.single.orderId, 'second-customer');
    expect(orders.sends, isEmpty);
  });

  testWidgets('Guest login returns to the same general screen', (tester) async {
    final accounts = StreamController<AppUser?>.broadcast();
    addTearDown(accounts.close);
    LoginArgs? loginArgs;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => accounts.stream),
          generalChatRepositoryProvider.overrideWithValue(general),
        ],
        child: MaterialApp(
          home: const GeneralChatScreen(),
          onGenerateRoute: (settings) {
            expect(settings.name, AppRoutes.login);
            loginArgs = settings.arguments as LoginArgs;
            return MaterialPageRoute<void>(
              builder: (context) => Scaffold(
                body: FilledButton(
                  onPressed: () {
                    accounts.add(customer);
                    Navigator.pop(context);
                  },
                  child: const Text('Đăng nhập thử'),
                ),
              ),
            );
          },
        ),
      ),
    );
    accounts.add(null);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();
    expect(loginArgs!.returnToCaller, isTrue);
    await tester.tap(find.text('Đăng nhập thử'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('chat-composer')), findsOneWidget);
    expect(find.text('Hỗ trợ chung'), findsOneWidget);
  });

  testWidgets('disabled account has no general composer', (tester) async {
    await tester.pumpWidget(app(user: customer.copyWith(status: 'disabled')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('chat-composer')), findsNothing);
    expect(general.sends, isEmpty);
  });

  testWidgets(
    'Admin replies in general history and marks only that thread read',
    (tester) async {
      general.chat = chatFixture(orderId: customer.id, unreadByAdmin: true);
      await tester.pumpWidget(
        app(
          user: customer.copyWith(id: 'admin', role: 'admin'),
          child: GeneralChatScreen(customerId: customer.id),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('chat-text')),
        'Quán mở đến 22 giờ.',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('chat-send')));
      await tester.pumpAndSettle();
      expect(general.sends.single.role, ChatRole.admin);
      expect(general.reads.single.role, ChatRole.admin);
      expect(orders.sends, isEmpty);
      expect(orders.reads, isEmpty);
    },
  );

  testWidgets('Admin can load conversations beyond the initial hundred', (
    tester,
  ) async {
    general.adminChats = List.generate(
      101,
      (i) => chatFixture(orderId: 'customer-$i'),
    );
    await tester.pumpWidget(
      app(
        user: customer.copyWith(id: 'admin', role: 'admin'),
        child: const AdminMessagesScreen(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Tải thêm'), 600, maxScrolls: 40);
    await tester.drag(find.byType(ListView), const Offset(0, -160));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tải thêm'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('inbox-true-customer-100')),
      600,
      maxScrolls: 40,
    );
    expect(
      find.byKey(const ValueKey('inbox-true-customer-100')),
      findsOneWidget,
    );
    expect(find.text('Tải thêm'), findsNothing);
  });
}
