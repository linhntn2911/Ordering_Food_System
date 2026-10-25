import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/features/order/data/repositories/preview_order_repository.dart';
import 'package:ordering_food_system/features/order/domain/entities/food_order.dart';
import 'package:ordering_food_system/features/order/domain/entities/order_status.dart';
import 'package:ordering_food_system/features/order/presentation/viewmodels/admin_order_list_view_model.dart';
import 'package:ordering_food_system/features/order/presentation/views/admin_order_details_screen.dart';

void main() {
  testWidgets('shows order snapshots, totals, and status history', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Order details'), findsOneWidget);
    expect(find.text('Nguyễn Minh Anh'), findsOneWidget);
    expect(find.text('Gà sốt phô mai cay'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Payment summary'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Payment summary'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Status timeline'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Status timeline'), findsOneWidget);
    expect(find.text('Confirm order'), findsOneWidget);
  });

  testWidgets('confirms a pending order and appends its new status', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm order'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
    await tester.pumpAndSettle();

    expect(find.text('Confirmed'), findsWidgets);
    expect(find.text('Start preparing'), findsOneWidget);
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

Widget _app() {
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
    status: OrderStatus.pending,
    createdAt: now,
    updatedAt: now,
  );
  return ProviderScope(
    overrides: [
      orderRepositoryProvider.overrideWith((ref) {
        final repository = PreviewOrderRepository();
        ref.onDispose(repository.dispose);
        return repository;
      }),
    ],
    child: MaterialApp(home: AdminOrderDetailsScreen(initialOrder: order)),
  );
}
