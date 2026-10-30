import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/core/utils/search_text.dart';
import 'package:ordering_food_system/features/menu/domain/entities/menu_item.dart';
import 'package:ordering_food_system/features/menu/domain/entities/menu_option.dart';
import 'package:ordering_food_system/features/menu/domain/entities/menu_search_query.dart';
import 'package:ordering_food_system/features/menu/domain/services/menu_search.dart';

import '../../../support/menu_fixtures.dart';

/// A slice of the Ngõ Chicken menu, in menu order.
final _menu = [
  menuItem(
    'ga-vien',
    categoryId: 'ga-ran',
    name: 'Gà viên truyền thống',
    basePrice: 30000,
  ),
  menuItem(
    'ga-han-quoc',
    categoryId: 'ga-ran',
    name: 'Gà sốt cay ngọt Hàn Quốc',
    basePrice: 35000,
    ratingAverage: 4.8,
    reviewCount: 126,
  ),
  menuItem(
    'canh-ga',
    categoryId: 'ga-ran',
    name: 'Cánh gà nướng',
    basePrice: 30000,
  ),
  menuItem(
    'com-ga',
    categoryId: 'com',
    name: 'Cơm gà chiên mắm tỏi',
    basePrice: 40000,
    ratingAverage: 4.7,
    reviewCount: 98,
  ),
  menuItem(
    'banh-ga',
    categoryId: 'do-an-vat',
    name: 'Bánh gà',
    basePrice: 30000,
  ),
  menuItem(
    'ca-vien',
    categoryId: 'do-an-vat',
    name: 'Cá viên chiên',
    basePrice: 25000,
    isAvailable: false,
  ),
  menuItem('kimbap', categoryId: 'do-an-vat', name: 'Kimbap', basePrice: 25000),
  menuItem(
    'my-y-ga',
    categoryId: 'combo',
    name: 'Mỳ ý + Gà rán',
    basePrice: 60000,
  ),
  menuItem(
    'tra-dao',
    categoryId: 'do-uong',
    name: 'Trà đào',
    basePrice: 20000,
    ratingAverage: 4.3,
    reviewCount: 52,
    sizes: const [
      MenuOption(id: 'm', name: 'M', priceDelta: 0),
      MenuOption(id: 'l', name: 'L', priceDelta: 5000),
    ],
  ),
  menuItem(
    'tra-sua',
    categoryId: 'do-uong',
    name: 'Trà sữa trân châu đường đen',
    basePrice: 25000,
    ratingAverage: 4.9,
    reviewCount: 210,
  ),
  menuItem(
    'sinh-to-bo',
    categoryId: 'do-uong',
    name: 'Sinh tố bơ',
    basePrice: 25000,
    isAvailable: false,
  ),
];

List<String> _ids(List<MenuItem> items) => [for (final i in items) i.id];

List<MenuItem> _search(
  String keyword, {
  String? categoryId,
  bool availableOnly = false,
  MenuSortOrder sortOrder = MenuSortOrder.relevance,
  List<MenuItem>? items,
}) {
  return searchMenuItems(
    items ?? _menu,
    MenuSearchQuery(
      keyword: keyword,
      filters: MenuSearchFilters(
        categoryId: categoryId,
        availableOnly: availableOnly,
        sortOrder: sortOrder,
      ),
    ),
  );
}

void main() {
  group('keyword (User Story 1)', () {
    test('an empty or blank keyword keeps every item in menu order', () {
      expect(_ids(_search('')), _ids(_menu));
      expect(_ids(_search('   ')), _ids(_menu));
    });

    test('matches without diacritics', () {
      expect(_ids(_search('tra sua')), ['tra-sua']);
    });

    test('ignores case and diacritics in the keyword', () {
      expect(_ids(_search('GA')), _ids(_search('gà')));
    });

    test('matches special characters literally', () {
      expect(_ids(_search('mỳ ý + gà')), ['my-y-ga']);
    });

    test('matches anywhere in the name, d matches đ', () {
      expect(_ids(_search('duong')), ['tra-sua']);
      expect(_ids(_search('đao')), ['tra-dao']);
    });

    test('names starting with the keyword come first in menu order', () {
      expect(_ids(_search('ga')), [
        'ga-vien',
        'ga-han-quoc',
        'canh-ga',
        'com-ga',
        'banh-ga',
        'my-y-ga',
      ]);
    });

    test('returns nothing when no name matches', () {
      expect(_search('pizza'), isEmpty);
    });

    test('does not modify the input list', () {
      final items = List<MenuItem>.of(_menu);
      _search('ga', sortOrder: MenuSortOrder.priceDesc, items: items);
      expect(_ids(items), _ids(_menu));
    });

    test('uses precomputed normalized names when given', () {
      final result = searchMenuItems(
        _menu,
        const MenuSearchQuery(keyword: 'x'),
        normalizedNames: {for (final item in _menu) item.id: 'x'},
      );
      expect(result, hasLength(_menu.length));
    });

    test('SC-002: the first 4 letters of any word find every sample item', () {
      final seed = jsonDecode(
        File('tools/seed_menu/menu_seed.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final items = [
        for (final raw in seed['items'] as List<dynamic>)
          menuItem(
            (raw as Map<String, dynamic>)['id'] as String,
            categoryId: raw['categoryId'] as String,
            name: raw['name'] as String,
          ),
      ];
      expect(items, isNotEmpty);

      for (final item in items) {
        for (final word in item.name.split(' ')) {
          if (!RegExp(r'\w', unicode: true).hasMatch(word)) {
            continue;
          }
          final prefix = String.fromCharCodes(word.runes.take(4));
          for (final keyword in [prefix, normalizeSearchText(prefix)]) {
            expect(
              _ids(_search(keyword, items: items)),
              contains(item.id),
              reason: '"$keyword" should find "${item.name}"',
            );
          }
        }
      }
    });

    test('SC-001: searching 300 items stays well under one frame', () {
      final items = [
        for (var i = 0; i < 300; i++)
          menuItem(
            'item-$i',
            name: 'Món số $i ${_menu[i % _menu.length].name}',
          ),
      ];
      _search('ga', items: items);

      final stopwatch = Stopwatch()..start();
      for (var i = 0; i < 10; i++) {
        _search('tra sua', sortOrder: MenuSortOrder.ratingDesc, items: items);
      }
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds / 10, lessThan(50));
    });
  });

  group('filters (User Story 2)', () {
    test('a category keeps only its items', () {
      expect(_ids(_search('', categoryId: 'do-an-vat')), [
        'banh-ga',
        'ca-vien',
        'kimbap',
      ]);
    });

    test('available only removes every sold-out item (SC-004)', () {
      final result = _search('', availableOnly: true);
      expect(result.every((item) => item.isAvailable), isTrue);
      expect(_ids(result), isNot(contains('ca-vien')));
      expect(_ids(result), isNot(contains('sinh-to-bo')));
    });

    test('sold-out items stay when available only is off', () {
      expect(_ids(_search('')), containsAll(['ca-vien', 'sinh-to-bo']));
    });

    test('keyword and filters combine with "and" (FR-008)', () {
      expect(
        _ids(_search('ga', categoryId: 'do-an-vat', availableOnly: true)),
        ['banh-ga'],
      );
    });

    test('filters can leave no result', () {
      expect(
        _search('sinh to', categoryId: 'do-uong', availableOnly: true),
        isEmpty,
      );
    });
  });

  group('sort orders (User Story 3)', () {
    test('price ascending uses the lowest size price, then the name', () {
      expect(_ids(_search('tra', sortOrder: MenuSortOrder.priceAsc)), [
        'tra-dao',
        'tra-sua',
      ]);
      expect(
        _ids(
          _search('', categoryId: 'ga-ran', sortOrder: MenuSortOrder.priceAsc),
        ),
        ['canh-ga', 'ga-vien', 'ga-han-quoc'],
      );
    });

    test('price descending puts the most expensive first', () {
      expect(
        _ids(
          _search('', categoryId: 'ga-ran', sortOrder: MenuSortOrder.priceDesc),
        ),
        ['ga-han-quoc', 'canh-ga', 'ga-vien'],
      );
    });

    test('rating puts rated items first, unrated last in menu order', () {
      expect(_ids(_search('', sortOrder: MenuSortOrder.ratingDesc)), [
        'tra-sua',
        'ga-han-quoc',
        'com-ga',
        'tra-dao',
        'ga-vien',
        'canh-ga',
        'banh-ga',
        'ca-vien',
        'kimbap',
        'my-y-ga',
        'sinh-to-bo',
      ]);
    });

    test('rating ties break on review count', () {
      final items = [
        menuItem('a', name: 'A', ratingAverage: 4.5, reviewCount: 3),
        menuItem('b', name: 'B', ratingAverage: 4.5, reviewCount: 9),
      ];
      expect(
        _ids(_search('', sortOrder: MenuSortOrder.ratingDesc, items: items)),
        ['b', 'a'],
      );
    });

    test('sorting combines with keyword and filters', () {
      expect(
        _ids(
          _search(
            'ga',
            availableOnly: true,
            sortOrder: MenuSortOrder.priceDesc,
          ),
        ),
        ['my-y-ga', 'com-ga', 'ga-han-quoc', 'banh-ga', 'canh-ga', 'ga-vien'],
      );
    });
  });
}
