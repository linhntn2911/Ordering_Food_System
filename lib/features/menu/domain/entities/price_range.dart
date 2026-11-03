import 'menu_option.dart';

/// Lowest and highest price of a menu item across its sizes.
///
/// Toppings are not included.
class PriceRange {
  const PriceRange({required this.min, required this.max});

  factory PriceRange.of(int basePrice, List<MenuOption> sizes) {
    if (sizes.isEmpty) {
      return PriceRange(min: basePrice, max: basePrice);
    }

    var minDelta = sizes.first.priceDelta;
    var maxDelta = sizes.first.priceDelta;
    for (final size in sizes.skip(1)) {
      if (size.priceDelta < minDelta) minDelta = size.priceDelta;
      if (size.priceDelta > maxDelta) maxDelta = size.priceDelta;
    }
    return PriceRange(min: basePrice + minDelta, max: basePrice + maxDelta);
  }

  final int min;
  final int max;

  bool get isSingle => min == max;
}
