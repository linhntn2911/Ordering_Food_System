import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/features/category/domain/entities/category.dart';
import 'package:ordering_food_system/features/category/domain/repositories/category_repository.dart';
import 'package:ordering_food_system/features/category/presentation/viewmodels/category_management_view_model.dart';
import 'package:ordering_food_system/features/menu/domain/entities/menu_category.dart';
import 'package:ordering_food_system/features/menu/domain/entities/menu_feed.dart';
import 'package:ordering_food_system/features/menu/domain/entities/menu_item.dart';
import 'package:ordering_food_system/features/menu/domain/entities/menu_item_draft.dart';
import 'package:ordering_food_system/features/menu/domain/entities/menu_item_feed.dart';
import 'package:ordering_food_system/features/menu/domain/repositories/menu_repository.dart';
import 'package:ordering_food_system/features/menu/presentation/viewmodels/menu_providers.dart';
import 'package:ordering_food_system/features/menu/presentation/views/admin_menu_item_list_screen.dart';

void main() {
  testWidgets('shows menu items and category filters', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryRepositoryProvider.overrideWithValue(_FakeCategories()),
          menuRepositoryProvider.overrideWithValue(_FakeMenu()),
        ],
        child: const MaterialApp(home: AdminMenuItemListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Menu Items'), findsOneWidget);
    expect(find.text('Gà rán'), findsWidgets);
    expect(find.text('Đùi gà rán'), findsOneWidget);
    expect(find.text('30.000 ₫'), findsOneWidget);
  });

  testWidgets('filters menu items by category', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryRepositoryProvider.overrideWithValue(_FakeCategories()),
          menuRepositoryProvider.overrideWithValue(_FakeMenu()),
        ],
        child: const MaterialApp(home: AdminMenuItemListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('category-filter-button')));
    await tester.pumpAndSettle();

    final teaOption = find.byKey(const ValueKey('category-filter-tea'));
    expect(teaOption, findsOneWidget);
    await tester.tap(teaOption);
    await tester.pumpAndSettle();

    expect(find.text('Trà đào'), findsOneWidget);
    expect(find.text('Đùi gà rán'), findsNothing);
    expect(find.byKey(const ValueKey('active-category-chip')), findsOneWidget);
  });
}

class _FakeCategories implements CategoryRepository {
  final categories = const [
    Category(
      id: 'fried-chicken',
      name: 'Gà rán',
      imageUrl: '',
      sortOrder: 0,
      isPublished: true,
    ),
    Category(
      id: 'tea',
      name: 'Trà',
      imageUrl: '',
      sortOrder: 1,
      isPublished: true,
    ),
  ];

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

class _FakeMenu implements MenuRepository {
  final items = [
    MenuItem(
      id: 'chicken',
      categoryId: 'fried-chicken',
      name: 'Đùi gà rán',
      description: '',
      imageUrl: '',
      basePrice: 30000,
      isAvailable: true,
      isPublished: true,
      sortOrder: 0,
      ratingAverage: 0,
      reviewCount: 0,
    ),
    MenuItem(
      id: 'peach-tea',
      categoryId: 'tea',
      name: 'Trà đào',
      description: '',
      imageUrl: '',
      basePrice: 20000,
      isAvailable: true,
      isPublished: true,
      sortOrder: 1,
      ratingAverage: 0,
      reviewCount: 0,
    ),
  ];

  @override
  Stream<List<MenuItem>> watchAdminItems({
    String? categoryId,
    int limit = 100,
  }) => Stream.value(
    items
        .where((item) => categoryId == null || item.categoryId == categoryId)
        .toList(),
  );
  @override
  Stream<MenuFeed<MenuCategory>> watchPublishedCategories({int limit = 50}) =>
      throw UnimplementedError();
  @override
  Stream<MenuFeed<MenuItem>> watchBrowsableItems({
    String? categoryId,
    required int limit,
  }) => throw UnimplementedError();
  @override
  Stream<MenuFeed<MenuItem>> watchSearchableItems({int limit = 300}) =>
      throw UnimplementedError();
  @override
  Stream<MenuFeed<MenuItem>> watchPopularItems({int limit = 5}) =>
      throw UnimplementedError();
  @override
  Stream<MenuItemFeed> watchItem(String menuItemId) =>
      throw UnimplementedError();
  @override
  Future<void> setAvailability(String id, {required bool isAvailable}) async {}
  @override
  Future<void> setPublished(String id, {required bool isPublished}) async {}
  @override
  Future<String> saveItem(MenuItemDraft draft) async => draft.id ?? 'new-item';
}
