import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/features/menu/domain/entities/menu_option.dart';
import 'package:ordering_food_system/features/menu/domain/entities/price_range.dart';

MenuOption _size(String id, int delta) =>
    MenuOption(id: id, name: id, priceDelta: delta);

void main() {
  test('no sizes gives a single price equal to the base price', () {
    final range = PriceRange.of(45000, const []);

    expect(range.min, 45000);
    expect(range.max, 45000);
    expect(range.isSingle, isTrue);
  });

  test('sizes with the same delta give a single price', () {
    final range = PriceRange.of(25000, [_size('s', 5000), _size('l', 5000)]);

    expect(range.min, 30000);
    expect(range.isSingle, isTrue);
  });

  test('different deltas give a range from base plus min to base plus max', () {
    final range = PriceRange.of(45000, [
      _size('s', 0),
      _size('m', 10000),
      _size('l', 20000),
    ]);

    expect(range.min, 45000);
    expect(range.max, 65000);
    expect(range.isSingle, isFalse);
  });

  test('size order does not change the range', () {
    final range = PriceRange.of(45000, [
      _size('l', 20000),
      _size('s', 0),
      _size('m', 10000),
    ]);

    expect(range.min, 45000);
    expect(range.max, 65000);
  });
}
