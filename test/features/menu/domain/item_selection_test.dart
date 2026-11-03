import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/features/menu/domain/entities/item_selection.dart';
import 'package:ordering_food_system/features/menu/domain/entities/menu_item.dart';
import 'package:ordering_food_system/features/menu/domain/entities/menu_option.dart';

import '../../../support/menu_fixtures.dart';

const _m = MenuOption(id: 'm', name: 'M', priceDelta: 0);
const _l = MenuOption(id: 'l', name: 'L', priceDelta: 5000);
const _pearl = MenuOption(id: 'pearl', name: 'Trân châu đen', priceDelta: 5000);
const _cheese = MenuOption(id: 'cheese', name: 'Kem cheese', priceDelta: 8000);

final _milkTea = menuItem(
  'tra-sua',
  name: 'Trà sữa',
  basePrice: 25000,
  sizes: const [_l, _m],
  toppings: const [_pearl, _cheese],
);

List<MenuOption> _options(Object? raw) => [
  for (final option in (raw as List<dynamic>? ?? const []))
    MenuOption(
      id: (option as Map<String, dynamic>)['id'] as String,
      name: option['name'] as String,
      priceDelta: option['priceDelta'] as int,
    ),
];

/// Every subset of [toppings].
Iterable<Set<String>> _subsets(List<MenuOption> toppings) sync* {
  for (var mask = 0; mask < 1 << toppings.length; mask++) {
    yield {
      for (var i = 0; i < toppings.length; i++)
        if (mask & (1 << i) != 0) toppings[i].id,
    };
  }
}

void main() {
  group('initial', () {
    test('picks the cheapest size, no toppings, quantity 1, no note', () {
      final selection = ItemSelection.initial(_milkTea);

      expect(selection.sizeId, 'm');
      expect(selection.toppingIds, isEmpty);
      expect(selection.quantity, 1);
      expect(selection.note, isEmpty);
      expect(selection.unitPrice(_milkTea), 25000);
    });

    test('picks the first size when prices tie', () {
      final item = menuItem(
        'x',
        sizes: const [
          MenuOption(id: 'a', name: 'A', priceDelta: 0),
          MenuOption(id: 'b', name: 'B', priceDelta: 0),
        ],
      );
      expect(ItemSelection.initial(item).sizeId, 'a');
    });

    test('has no size when the item has none', () {
      final item = menuItem('x', basePrice: 30000);
      final selection = ItemSelection.initial(item);

      expect(selection.sizeId, isNull);
      expect(selection.total(item), 30000);
    });
  });

  group('choices', () {
    test('withSize accepts only offered sizes', () {
      final selection = ItemSelection.initial(_milkTea);

      expect(selection.withSize(_milkTea, 'l').sizeId, 'l');
      expect(selection.withSize(_milkTea, 'xl').sizeId, 'm');
    });

    test('toggleTopping adds and removes offered toppings', () {
      var selection = ItemSelection.initial(_milkTea)
          .toggleTopping(_milkTea, 'pearl')
          .toggleTopping(_milkTea, 'cheese')
          .toggleTopping(_milkTea, 'unknown');
      expect(selection.toppingIds, {'pearl', 'cheese'});

      selection = selection.toggleTopping(_milkTea, 'pearl');
      expect(selection.toppingIds, {'cheese'});
    });

    test('quantity is clamped to 1–99', () {
      final selection = ItemSelection.initial(_milkTea);

      expect(selection.withQuantity(0).quantity, 1);
      expect(selection.withQuantity(3).quantity, 3);
      expect(selection.withQuantity(120).quantity, 99);
    });

    test('note is cut at 200 characters; blank notes count as empty', () {
      final selection = ItemSelection.initial(_milkTea);

      expect(selection.withNote('ă' * 250).note.runes.length, 200);
      expect(selection.withNote('  ít đá ').trimmedNote, 'ít đá');
      expect(selection.withNote('   ').trimmedNote, isEmpty);
    });
  });

  group('price', () {
    test('size L with two toppings, three cups', () {
      final selection = ItemSelection.initial(_milkTea)
          .withSize(_milkTea, 'l')
          .toggleTopping(_milkTea, 'pearl')
          .toggleTopping(_milkTea, 'cheese')
          .withQuantity(3);

      expect(selection.unitPrice(_milkTea), 25000 + 5000 + 5000 + 8000);
      expect(selection.total(_milkTea), 43000 * 3);
    });

    test('SC-002: every size × topping × quantity of the sample menu', () {
      final seed = jsonDecode(
        File('tools/seed_menu/menu_seed.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final items = <MenuItem>[
        for (final raw in seed['items'] as List<dynamic>)
          menuItem(
            (raw as Map<String, dynamic>)['id'] as String,
            basePrice: raw['basePrice'] as int,
            sizes: _options(raw['sizes']),
            toppings: _options(raw['toppings']),
          ),
      ];
      var combinations = 0;

      for (final item in items) {
        final sizes = item.sizes.isEmpty ? <MenuOption?>[null] : item.sizes;
        for (final size in sizes) {
          for (final toppingIds in _subsets(item.toppings)) {
            for (final quantity in [1, 2, 99]) {
              var selection = ItemSelection.initial(item);
              if (size != null) {
                selection = selection.withSize(item, size.id);
              }
              for (final id in toppingIds) {
                selection = selection.toggleTopping(item, id);
              }
              selection = selection.withQuantity(quantity);

              final expectedUnit =
                  item.basePrice +
                  (size?.priceDelta ?? 0) +
                  item.toppings
                      .where((topping) => toppingIds.contains(topping.id))
                      .fold<int>(0, (sum, topping) => sum + topping.priceDelta);
              expect(selection.total(item), expectedUnit * quantity);
              combinations++;
            }
          }
        }
      }
      expect(combinations, greaterThan(items.length * 3));
    });
  });

  group('reconcile', () {
    test('keeps a selection whose options still exist', () {
      final selection = ItemSelection.initial(_milkTea)
          .toggleTopping(_milkTea, 'pearl');

      final result = selection.reconcile(_milkTea);

      expect(result.removedOptions, isFalse);
      expect(identical(result.selection, selection), isTrue);
    });

    test('drops a removed topping and reports it', () {
      final selection = ItemSelection.initial(_milkTea)
          .toggleTopping(_milkTea, 'pearl')
          .toggleTopping(_milkTea, 'cheese')
          .withQuantity(2);
      final updated = menuItem(
        'tra-sua',
        basePrice: 25000,
        sizes: const [_l, _m],
        toppings: const [_pearl],
      );

      final result = selection.reconcile(updated);

      expect(result.removedOptions, isTrue);
      expect(result.selection.toppingIds, {'pearl'});
      expect(result.selection.quantity, 2);
    });

    test('a removed size falls back to the default size', () {
      final selection = ItemSelection.initial(_milkTea).withSize(_milkTea, 'l');
      final updated = menuItem('tra-sua', sizes: const [_m]);

      final result = selection.reconcile(updated);

      expect(result.removedOptions, isTrue);
      expect(result.selection.sizeId, 'm');
    });

    test('sizes added to an item without sizes are not a removal', () {
      final plain = menuItem('x');
      final selection = ItemSelection.initial(plain);

      final result = selection.reconcile(menuItem('x', sizes: const [_m, _l]));

      expect(result.removedOptions, isFalse);
      expect(result.selection.sizeId, 'm');
    });

    test('all sizes removed clears the size', () {
      final selection = ItemSelection.initial(_milkTea);

      final result = selection.reconcile(menuItem('tra-sua'));

      expect(result.removedOptions, isTrue);
      expect(result.selection.sizeId, isNull);
    });
  });

  test('equality ignores topping order', () {
    final a = ItemSelection.initial(_milkTea)
        .toggleTopping(_milkTea, 'pearl')
        .toggleTopping(_milkTea, 'cheese');
    final b = ItemSelection.initial(_milkTea)
        .toggleTopping(_milkTea, 'cheese')
        .toggleTopping(_milkTea, 'pearl');

    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });
}
