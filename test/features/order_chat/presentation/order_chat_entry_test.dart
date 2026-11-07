import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/app/router.dart';
import 'package:ordering_food_system/features/order/domain/entities/order_status.dart'
    as order;
import 'package:ordering_food_system/features/order_chat/domain/entities/order_chat.dart';
import 'package:ordering_food_system/features/order_chat/presentation/viewmodels/order_chat_providers.dart';
import 'package:ordering_food_system/features/order_chat/presentation/views/order_chat_screen.dart';
import 'package:ordering_food_system/features/order_chat/presentation/widgets/chat_unread_dot.dart';
import 'package:ordering_food_system/features/order_history/data/models/order_model.dart';
import 'package:ordering_food_system/features/order_history/presentation/viewmodels/order_history_viewmodel.dart';
import 'package:ordering_food_system/features/order_tracking/presentation/views/order_detail_screen.dart';
import 'package:ordering_food_system/features/review/presentation/viewmodels/review_provider.dart';

import '../../../support/fake_order_chat_repository.dart';
import '../../../support/order_chat_order_fixture.dart';

void main() {
  Widget app(
    FakeOrderChatRepository repository, {
    bool closed = false,
    Stream<OrderChat?>? conversation,
  }) => ProviderScope(
    overrides: [
      orderChatRepositoryProvider.overrideWithValue(repository),
      if (conversation != null)
        orderChatStreamProvider('firestore-doc')
            .overrideWith((ref) => conversation),
      reviewedOrderIdsProvider.overrideWithValue(const <String>{}),
      orderDetailByIdProvider('PUBLIC-CODE').overrideWith(
        (ref) => Stream.value(
          OrderModel(
            orderId: 'PUBLIC-CODE',
            documentId: 'firestore-doc',
            userId: 'customer',
            items: const [],
            subtotal: 45000,
            deliveryFee: 15000,
            discount: 0,
            totalPrice: 60000,
            status: OrderStatus.pending,
            createdAt: DateTime(2026, 11, 1),
            address: 'Địa chỉ',
            paymentMethod: 'COD',
          ),
        ),
      ),
      chatOrderProvider('firestore-doc').overrideWith(
        (ref) => Stream.value(
          chatOrderFixture(
            id: 'firestore-doc',
            status: closed
                ? order.OrderStatus.completed
                : order.OrderStatus.preparing,
            updatedAt: DateTime.now().subtract(const Duration(hours: 25)),
          ),
        ),
      ),
    ],
    child: MaterialApp(
      home: const OrderDetailScreen(orderId: 'PUBLIC-CODE'),
      onGenerateRoute: (settings) {
        if (settings.name != AppRoutes.orderChat) return null;
        final args = settings.arguments as OrderChatArgs;
        return MaterialPageRoute<void>(
          builder: (_) => Scaffold(body: Text('Chat ${args.orderId}')),
        );
      },
    ),
  );

  testWidgets('customer entry uses Firestore ID and displays unread dot', (
    tester,
  ) async {
    final repository = FakeOrderChatRepository()
      ..chat = chatFixture(orderId: 'firestore-doc', unreadByCustomer: true);
    addTearDown(repository.close);
    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();
    expect(find.text('PUBLIC-CODE'), findsOneWidget);
    final entry = find.byKey(const ValueKey('order-chat-open'));
    expect(entry, findsOneWidget);
    expect(find.byType(ChatUnreadDot), findsOneWidget);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(find.text('Chat firestore-doc'), findsOneWidget);
  });

  testWidgets('customer can open chat while conversation is loading', (
    tester,
  ) async {
    final repository = FakeOrderChatRepository();
    final conversation = StreamController<OrderChat?>();
    addTearDown(repository.close);
    addTearDown(() => unawaited(conversation.close()));
    await tester.pumpWidget(app(repository, conversation: conversation.stream));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('order-chat-open')));
    await tester.pumpAndSettle();
    expect(find.text('Chat firestore-doc'), findsOneWidget);
  });

  testWidgets(
    'closed order with no conversation shows the 24-hour explanation',
    (tester) async {
      final repository = FakeOrderChatRepository();
      addTearDown(repository.close);
      await tester.pumpWidget(app(repository, closed: true));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('order-chat-open')), findsNothing);
      expect(
        find.textContaining('24 giờ sau khi đơn kết thúc'),
        findsOneWidget,
      );
    },
  );
}
