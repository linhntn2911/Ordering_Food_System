import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/features/order/data/repositories/preview_order_repository.dart';
import 'package:ordering_food_system/features/order/domain/entities/food_order.dart';
import 'package:ordering_food_system/features/order/domain/entities/order_status.dart';
import 'package:ordering_food_system/features/order/presentation/viewmodels/admin_order_list_view_model.dart';
import 'package:ordering_food_system/features/order/presentation/views/admin_order_details_screen.dart';

import 'package:ordering_food_system/app/router.dart';
import 'package:ordering_food_system/features/order_chat/presentation/viewmodels/order_chat_providers.dart';
import 'package:ordering_food_system/features/order_chat/presentation/views/order_chat_screen.dart';
import 'package:ordering_food_system/features/order_chat/presentation/widgets/chat_unread_dot.dart';

import 'support/fake_order_chat_repository.dart';
import 'support/order_chat_order_fixture.dart';

void main() {
  testWidgets('opens chat for the displayed order and shows its unread dot', (
    tester,
  ) async {
    final repository = FakeOrderChatRepository()
      ..chat = chatFixture(orderId: 'order-1', unreadByAdmin: true);
    addTearDown(repository.close);
    await tester.pumpWidget(_app(chatRepository: repository));
    await tester.pumpAndSettle();
    final entry = find.byKey(const ValueKey('admin-order-chat-open'));
    expect(entry, findsOneWidget);
    expect(find.byType(ChatUnreadDot), findsOneWidget);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(find.text('Chat order-1'), findsOneWidget);
  });

  testWidgets('shows order snapshots, totals, and status history', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Chi tiết đơn hàng'), findsOneWidget);
    expect(find.text('Nguyễn Minh Anh'), findsOneWidget);
    final item = find.text('Gà sốt phô mai cay');
    await tester.scrollUntilVisible(
      item,
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(item, findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Tóm tắt thanh toán'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Tóm tắt thanh toán'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Lịch sử trạng thái'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Lịch sử trạng thái'), findsOneWidget);
    expect(find.text('Xác nhận đơn hàng'), findsOneWidget);
  });

  testWidgets('confirms a pending order and appends its new status', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Xác nhận đơn hàng'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Xác nhận'));
    await tester.pumpAndSettle();

    expect(find.text('Đã xác nhận'), findsWidgets);
    expect(find.text('Bắt đầu chuẩn bị'), findsOneWidget);
  });

  testWidgets('fits a phone-sized viewport', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

Widget _app({FakeOrderChatRepository? chatRepository}) {
  final now = DateTime.now();
  final order = FoodOrder(
    id: 'order-1',
    orderCode: 'ORD-20261019-0008',
    customerId: 'customer-order-1',
    customerName: 'Nguyễn Minh Anh',
    customerPhone: '0912 345 678',
    deliveryAddress: '12 Nguyễn Trãi, Thanh Xuân, Hà Nội',
    totalAmount: 125000,
    subtotal: 110000,
    deliveryFee: 15000,
    deliveryDistanceKm: 2.4,
    paymentMethod: 'cod',
    paymentStatus: 'unpaid',
    customerNote: 'Gọi trước khi giao.',
    status: OrderStatus.pending,
    createdAt: now,
    updatedAt: now,
  );
  return ProviderScope(
    overrides: [
      orderChatRepositoryProvider.overrideWith((ref) {
        if (chatRepository != null) return chatRepository;
        final repository = FakeOrderChatRepository();
        ref.onDispose(repository.close);
        return repository;
      }),
      orderRepositoryProvider.overrideWith((ref) {
        final repository = PreviewOrderRepository();
        ref.onDispose(repository.dispose);
        return repository;
      }),
    ],
    child: MaterialApp(
      onGenerateRoute: (settings) {
        if (settings.name != AppRoutes.orderChat) return null;
        final args = settings.arguments as OrderChatArgs;
        return MaterialPageRoute<void>(
          builder: (_) => Scaffold(body: Text('Chat ${args.orderId}')),
        );
      },
      home: AdminOrderDetailsScreen(
        initialOrder: order,
        requireAdminSession: false,
      ),
    ),
  );
}
