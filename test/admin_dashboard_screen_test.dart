import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/features/category/domain/entities/category.dart';
import 'package:ordering_food_system/features/category/domain/repositories/category_repository.dart';
import 'package:ordering_food_system/features/category/presentation/viewmodels/category_management_view_model.dart';
import 'package:ordering_food_system/features/order/data/repositories/preview_order_repository.dart';
import 'package:ordering_food_system/features/order/presentation/viewmodels/admin_order_list_view_model.dart';
import 'package:ordering_food_system/features/order/presentation/views/admin_dashboard_screen.dart';

void main() {
  testWidgets(
    'renders AdminDashboardScreen with greeting, metrics and quick actions',
    (tester) async {
      final categoryRepo = _FakeCategoryRepository([
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
            categoryRepositoryProvider.overrideWithValue(categoryRepo),
            orderRepositoryProvider.overrideWith((ref) {
              final repo = PreviewOrderRepository();
              ref.onDispose(repo.dispose);
              return repo;
            }),
          ],
          child: const MaterialApp(home: AdminDashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Good day, Admin 👋'), findsOneWidget);
      expect(find.text('Total Revenue'), findsOneWidget);
      expect(find.text('Active Queue'), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Live Orders'), findsWidgets);

      final recentOrdersFinder = find.text('Recent Orders');
      await tester.scrollUntilVisible(recentOrdersFinder, 200);
      expect(recentOrdersFinder, findsOneWidget);
    },
  );
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
