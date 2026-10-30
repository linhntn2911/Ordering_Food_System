import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/features/menu/data/models/menu_category_model.dart';
import 'package:ordering_food_system/features/menu/data/models/menu_item_model.dart';

Map<String, dynamic> _itemData([Map<String, dynamic> overrides = const {}]) {
  return {
    'categoryId': 'com',
    'name': 'Cơm gà',
    'basePrice': 45000,
    'isPublished': true,
    'isAvailable': true,
    'sortOrder': 2,
    'ratingAverage': 4.5,
    'reviewCount': 10,
    'isCategoryPublished': true,
    'categorySortOrder': 1,
    'sizes': [
      {'id': 's', 'name': 'Nhỏ', 'priceDelta': 0},
      {'id': 'l', 'name': 'Lớn', 'priceDelta': 20000},
    ],
    ...overrides,
  };
}

void main() {
  group('MenuItemModel.fromMap', () {
    test('reads the browsing and denormalized fields', () {
      final item = MenuItemModel.fromMap('com-ga', _itemData()).toEntity();

      expect(item.id, 'com-ga');
      expect(item.isCategoryPublished, isTrue);
      expect(item.categorySortOrder, 1);
      expect(item.sizes.map((size) => size.priceDelta), [0, 20000]);
      expect(item.priceRange.min, 45000);
      expect(item.priceRange.max, 65000);
      expect(item.hasRating, isTrue);
    });

    test('reads valid toppings and skips malformed ones', () {
      final item = MenuItemModel.fromMap(
        'tra-sua',
        _itemData({
          'toppings': [
            {'id': 'tran-chau', 'name': 'Trân châu đen', 'priceDelta': 5000},
            {'id': 'bad', 'name': 'Âm', 'priceDelta': -1},
            {'id': '', 'name': 'Không id', 'priceDelta': 1000},
            'not a map',
            {'id': 'kem', 'name': 'Kem cheese', 'priceDelta': 8000},
          ],
        }),
      ).toEntity();

      expect(item.toppings.map((topping) => topping.id), ['tran-chau', 'kem']);
      expect(item.toppings.last.priceDelta, 8000);
    });

    test('falls back to defaults when optional fields are missing', () {
      final data = _itemData()
        ..remove('sizes')
        ..remove('ratingAverage')
        ..remove('reviewCount');

      final item = MenuItemModel.fromMap('x', data).toEntity();

      expect(item.sizes, isEmpty);
      expect(item.toppings, isEmpty);
      expect(item.ratingAverage, 0);
      expect(item.reviewCount, 0);
      expect(item.hasRating, isFalse);
    });

    test('skips malformed size entries', () {
      final item = MenuItemModel.fromMap(
        'x',
        _itemData({
          'sizes': [
            {'id': 's', 'name': 'Nhỏ', 'priceDelta': 0},
            {'id': 'bad', 'name': 'Âm', 'priceDelta': -5000},
            {'name': 'Không id', 'priceDelta': 1000},
            'not a map',
          ],
        }),
      ).toEntity();

      expect(item.sizes.map((size) => size.id), ['s']);
    });

    test('throws FormatException when name or basePrice is missing', () {
      expect(
        () => MenuItemModel.fromMap('x', _itemData()..remove('name')),
        throwsFormatException,
      );
      expect(
        () => MenuItemModel.fromMap('x', _itemData({'basePrice': 'free'})),
        throwsFormatException,
      );
    });

    test('exposes sizes as an unmodifiable list', () {
      final item = MenuItemModel.fromMap('x', _itemData()).toEntity();

      expect(() => item.sizes.clear(), throwsUnsupportedError);
    });
  });

  group('MenuCategoryModel.fromMap', () {
    test('reads name and defaults sortOrder to 0', () {
      final category = MenuCategoryModel.fromMap('com', {
        'name': 'Cơm',
        'isPublished': true,
      }).toEntity();

      expect(category.name, 'Cơm');
      expect(category.sortOrder, 0);
      expect(category.imageUrl, '');
    });

    test('throws FormatException when name is blank', () {
      expect(
        () => MenuCategoryModel.fromMap('com', {'name': '  '}),
        throwsFormatException,
      );
    });
  });
}
