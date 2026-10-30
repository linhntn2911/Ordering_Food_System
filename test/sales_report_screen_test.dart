import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/features/order/data/repositories/preview_order_repository.dart';
import 'package:ordering_food_system/features/order/presentation/viewmodels/admin_order_list_view_model.dart';
import 'package:ordering_food_system/features/order/presentation/views/sales_report_screen.dart';

void main() {
  testWidgets('reports completed COD orders and top-selling items', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          orderRepositoryProvider.overrideWith((ref) {
            final repository = PreviewOrderRepository();
            ref.onDispose(repository.dispose);
            return repository;
          }),
        ],
        child: const MaterialApp(home: SalesReportScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sales report'), findsOneWidget);
    expect(find.byKey(const ValueKey('sales-total-revenue')), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('sales-report-content')),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    expect(find.text('Gà sốt phô mai cay'), findsOneWidget);
    expect(find.text('2 sold'), findsOneWidget);
  });

  testWidgets('fits a phone-sized viewport', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          orderRepositoryProvider.overrideWith((ref) {
            final repository = PreviewOrderRepository();
            ref.onDispose(repository.dispose);
            return repository;
          }),
        ],
        child: const MaterialApp(home: SalesReportScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
