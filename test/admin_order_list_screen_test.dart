import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/features/order/domain/entities/food_order.dart';
import 'package:ordering_food_system/features/order/domain/entities/order_status.dart';
import 'package:ordering_food_system/features/order/domain/repositories/order_repository.dart';
import 'package:ordering_food_system/features/order/presentation/viewmodels/admin_order_list_view_model.dart';
import 'package:ordering_food_system/features/order/presentation/views/admin_order_list_screen.dart';

void main() {
  testWidgets('renders the real-time order queue and totals', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [orderRepositoryProvider.overrideWithValue(_FakeOrders())],
        child: const MaterialApp(home: AdminOrderListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('ORD-20261019-0001'), findsOneWidget);
    expect(find.text('Nguyễn Minh Anh'), findsOneWidget);
    expect(find.text('125.000 ₫'), findsOneWidget);
    expect(find.text('Pending'), findsWidgets);
  });

  testWidgets('filters orders by status', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [orderRepositoryProvider.overrideWithValue(_FakeOrders())],
        child: const MaterialApp(home: AdminOrderListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('order-status-filters')));
    await tester.pumpAndSettle();

    final completedFilter = find.byKey(
      const ValueKey('order-filter-completed'),
    );
    expect(completedFilter, findsOneWidget);
    await tester.tap(completedFilter);
    await tester.pumpAndSettle();

    expect(find.text('ORD-20261019-0002'), findsOneWidget);
    expect(find.text('ORD-20261019-0001'), findsNothing);
    expect(find.byKey(const ValueKey('active-filter-chip')), findsOneWidget);
  });

  testWidgets('searches by customer name', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [orderRepositoryProvider.overrideWithValue(_FakeOrders())],
        child: const MaterialApp(home: AdminOrderListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('admin-order-search')),
      'Thu Hà',
    );
    await tester.pumpAndSettle();

    expect(find.text('ORD-20261019-0002'), findsOneWidget);
    expect(find.text('ORD-20261019-0001'), findsNothing);
  });
}

class _FakeOrders implements OrderRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Stream<List<FoodOrder>> watchAdminOrders({int limit = 100}) {
    final now = DateTime(2026, 10, 19, 12);
    return Stream.value([
      FoodOrder(
        id: 'order-1',
        orderCode: 'ORD-20261019-0001',
        customerId: 'customer-1',
        customerName: 'Nguyễn Minh Anh',
        customerPhone: '0912 345 678',
        deliveryAddress: '12 Nguyễn Trãi, Hà Nội',
        totalAmount: 125000,
        paymentMethod: 'cod',
        paymentStatus: 'unpaid',
        status: OrderStatus.pending,
        createdAt: now,
        updatedAt: now,
      ),
      FoodOrder(
        id: 'order-2',
        orderCode: 'ORD-20261019-0002',
        customerId: 'customer-2',
        customerName: 'Trần Thu Hà',
        customerPhone: '0988 120 456',
        deliveryAddress: '88 Láng Hạ, Hà Nội',
        totalAmount: 85000,
        paymentMethod: 'cod',
        paymentStatus: 'paid',
        status: OrderStatus.completed,
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now,
      ),
    ]);
  }
}
