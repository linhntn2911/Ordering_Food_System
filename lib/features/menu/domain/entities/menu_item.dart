import 'menu_size_option.dart';

class MenuItem {
  const MenuItem({
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
    this.sizes = const [],
  });

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
  final List<MenuSizeOption> sizes;
}
