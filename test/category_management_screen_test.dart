import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/app/app.dart';
import 'package:ordering_food_system/features/category/domain/entities/category.dart';
import 'package:ordering_food_system/features/category/domain/repositories/category_repository.dart';
import 'package:ordering_food_system/features/category/presentation/viewmodels/category_management_view_model.dart';
import 'package:ordering_food_system/features/category/presentation/views/category_management_screen.dart';

void main() {
  testWidgets('renders categories supplied by the repository', (tester) async {
    final repository = _FakeCategoryRepository([
      const Category(
        id: 'main',
        name: 'Main dishes',
        imageUrl: '',
        sortOrder: 0,
        isPublished: true,
      ),
    ]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [categoryRepositoryProvider.overrideWithValue(repository)],
        child: const FoodOrderingApp(initialHome: CategoryManagementScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Category Management'), findsOneWidget);
    expect(find.text('Main dishes'), findsOneWidget);
    expect(find.text('Published'), findsNWidgets(2));
  });

  testWidgets('shows empty state and opens add form', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryRepositoryProvider.overrideWithValue(
            _FakeCategoryRepository(const []),
          ),
        ],
        child: const FoodOrderingApp(initialHome: CategoryManagementScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No categories yet'), findsOneWidget);
    await tester.tap(find.text('Add new category'));
    await tester.pumpAndSettle();
    expect(find.text('Add category'), findsOneWidget);
  });

  testWidgets('fits a narrow screen at 1.3 text scale', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryRepositoryProvider.overrideWithValue(
            _FakeCategoryRepository([
              const Category(
                id: 'main',
                name: 'Main dishes',
                imageUrl: '',
                sortOrder: 0,
                isPublished: true,
              ),
            ]),
          ),
        ],
        child: const FoodOrderingApp(initialHome: CategoryManagementScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Main dishes'), findsOneWidget);
  });

  test('validates category name and image URL', () {
    expect(
      CategoryManagementViewModel.validate(name: 'A', imageUrl: ''),
      isNotNull,
    );
    expect(
      CategoryManagementViewModel.validate(
        name: 'Drinks',
        imageUrl: 'not-a-url',
      ),
      isNotNull,
    );
    expect(
      CategoryManagementViewModel.validate(
        name: 'Drinks',
        imageUrl: 'https://example.com/drinks.png',
      ),
      isNull,
    );
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
