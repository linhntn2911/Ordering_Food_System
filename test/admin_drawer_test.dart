import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/app/app.dart';
import 'package:ordering_food_system/core/widgets/admin_drawer.dart';
import 'package:ordering_food_system/features/category/domain/entities/category.dart';
import 'package:ordering_food_system/features/category/domain/repositories/category_repository.dart';
import 'package:ordering_food_system/features/category/presentation/viewmodels/category_management_view_model.dart';
import 'package:ordering_food_system/features/order/data/repositories/preview_order_repository.dart';
import 'package:ordering_food_system/features/order/presentation/viewmodels/admin_order_list_view_model.dart';

void main() {
  testWidgets('opens AdminDrawer and shows all navigation items', (
    tester,
  ) async {
    final repository = _FakeCategoryRepository([
      const Category(
        id: 'main',
        name: 'Main dishes',
        imageUrl: '',
        sortOrder: 0,
        isPublished: true,
      ),
    ]);

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryRepositoryProvider.overrideWithValue(repository),
          orderRepositoryProvider.overrideWith((ref) {
            final repo = PreviewOrderRepository();
            ref.onDispose(repo.dispose);
            return repo;
          }),
        ],
        child: const FoodOrderingApp(),
      ),
    );
    await tester.pumpAndSettle();

    final menuButton = find.byKey(const ValueKey('admin-drawer-button'));
    expect(menuButton, findsOneWidget);

    await tester.tap(menuButton);
    await tester.pumpAndSettle();

    expect(find.byType(AdminDrawer), findsOneWidget);
    expect(find.text('Ngô Chicken'), findsWidgets);
    expect(find.text('Admin Workspace'), findsOneWidget);
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('CATALOG'), findsOneWidget);
    expect(find.text('OPERATIONS'), findsOneWidget);
    expect(find.text('Categories'), findsWidgets);
    expect(find.text('Menu Items'), findsWidgets);
    expect(find.text('Live Orders'), findsWidgets);
    expect(find.text('Sales Report'), findsWidgets);

    // Tap Sales Report
    final salesReportItem = find.byKey(
      const ValueKey('admin-drawer-sales-report'),
    );
    await tester.ensureVisible(salesReportItem);
    await tester.pumpAndSettle();
    await tester.tap(salesReportItem);
    await tester.pumpAndSettle();

    expect(find.text('Sales report'), findsOneWidget);
  });
}

class _FakeCategoryRepository implements CategoryRepository {
  _FakeCategoryRepository(this.categories);
  final List<Category> categories;

  @override
  Stream<List<Category>> watchCategories({int limit = 100}) =>
      Stream.value(categories);
  @override
  Future<void> createCategory({
    required String name,
    required String imageUrl,
    required bool isPublished,
  }) async {}
  @override
  Future<void> setPublished(String id, {required bool isPublished}) async {}
  @override
  Future<void> swapSortOrder(Category first, Category second) async {}
  @override
  Future<void> updateCategory({
    required String id,
    required String name,
    required String imageUrl,
    required bool isPublished,
  }) async {}
}
