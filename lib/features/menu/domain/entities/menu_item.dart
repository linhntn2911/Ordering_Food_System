import 'menu_option.dart';
import 'price_range.dart';

class MenuItem {
  MenuItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.basePrice,
    required this.isAvailable,
    required this.isPublished,
    required this.sortOrder,
    required this.ratingAverage,
    required this.reviewCount,
    List<MenuOption> sizes = const [],
    List<MenuOption> toppings = const [],
    this.isCategoryPublished = true,
    this.categorySortOrder = 0,
  }) : sizes = List<MenuOption>.unmodifiable(sizes),
       toppings = List<MenuOption>.unmodifiable(toppings);

  final String id;
  final String categoryId;
  final String name;
  final String description;
  final String imageUrl;
  final int basePrice;
  final bool isAvailable;
  final bool isPublished;
  final int sortOrder;
  final double ratingAverage;
  final int reviewCount;
  final List<MenuOption> sizes;
  final List<MenuOption> toppings;
  final bool isCategoryPublished;
  final int categorySortOrder;

  PriceRange get priceRange => PriceRange.of(basePrice, sizes);

  bool get hasRating => reviewCount > 0;
}
