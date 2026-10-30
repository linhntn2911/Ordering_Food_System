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
import 'package:ordering_food_system/features/menu/presentation/views/menu_item_form_screen.dart';

void main() {
  testWidgets('edit mode loads values and saves a valid item', (tester) async {
    final menu = _FakeMenu();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryRepositoryProvider.overrideWithValue(_FakeCategories()),
          menuRepositoryProvider.overrideWithValue(menu),
        ],
        child: MaterialApp(
          home: MenuItemFormScreen(
            item: MenuItem(
              id: 'chicken',
              categoryId: 'fried-chicken',
              name: 'Đùi gà rán',
              description: 'Giòn nóng',
              imageUrl: 'https://example.com/chicken.jpg',
              basePrice: 30000,
              isAvailable: true,
              isPublished: true,
              sortOrder: 0,
              ratingAverage: 0,
              reviewCount: 0,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit Menu Item'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    final nameField = tester.widget<TextFormField>(
      find.byKey(const ValueKey('menu-item-name')),
    );
    expect(nameField.controller?.text, 'Đùi gà rán');
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(menu.saved?.name, 'Đùi gà rán');
    expect(menu.saved?.basePrice, 30000);
  });

  testWidgets('shows required validation in add mode', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryRepositoryProvider.overrideWithValue(_FakeCategories()),
          menuRepositoryProvider.overrideWithValue(_FakeMenu()),
        ],
        child: const MaterialApp(home: MenuItemFormScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1800));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add menu item'));
    await tester.pump();

    expect(find.text('Select a category.'), findsWidgets);
  });
}

class _FakeCategories implements CategoryRepository {
  @override
  Stream<List<Category>> watchCategories({int limit = 100}) =>
      Stream.value(const [
        Category(
          id: 'fried-chicken',
          name: 'Gà rán',
          imageUrl: '',
          sortOrder: 0,
          isPublished: true,
        ),
      ]);

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
  MenuItemDraft? saved;

  @override
  Future<String> saveItem(MenuItemDraft draft) async {
    saved = draft;
    return draft.id ?? 'new-item';
  }

  @override
  Future<void> setAvailability(String id, {required bool isAvailable}) async {}
  @override
  Future<void> setPublished(String id, {required bool isPublished}) async {}
  @override
  Stream<List<MenuItem>> watchAdminItems({
    String? categoryId,
    int limit = 100,
  }) => const Stream.empty();
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
}
