import 'package:ordering_food_system/features/menu/domain/entities/menu_category.dart';
import 'package:ordering_food_system/features/menu/domain/entities/menu_item.dart';
import 'package:ordering_food_system/features/menu/domain/entities/menu_option.dart';
import 'package:ordering_food_system/features/reviews/domain/entities/review.dart';

MenuCategory category(String id, {String? name, int sortOrder = 0}) {
  return MenuCategory(
    id: id,
    name: name ?? 'Danh mục $id',
    imageUrl: '',
    sortOrder: sortOrder,
  );
}

MenuItem menuItem(
  String id, {
  String categoryId = 'com',
  String? name,
  int basePrice = 45000,
  bool isAvailable = true,
  double ratingAverage = 0,
  int reviewCount = 0,
  List<MenuOption> sizes = const [],
  List<MenuOption> toppings = const [],
  String imageUrl = '',
  String description = '',
}) {
  return MenuItem(
    id: id,
    categoryId: categoryId,
    name: name ?? 'Món $id',
    description: description,
    imageUrl: imageUrl,
    basePrice: basePrice,
    isAvailable: isAvailable,
    isPublished: true,
    sortOrder: 0,
    ratingAverage: ratingAverage,
    reviewCount: reviewCount,
    sizes: sizes,
    toppings: toppings,
  );
}

/// Lets stream events propagate through providers and listeners.
Future<void> settle() async {
  for (var i = 0; i < 3; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

Review review(
  String id, {
  int rating = 5,
  String comment = 'Ngon',
  List<String> imageUrls = const [],
  bool isAnonymous = false,
  bool isEdited = false,
  DateTime? createdAt,
}) {
  return Review(
    id: id,
    rating: rating,
    comment: comment,
    imageUrls: imageUrls,
    isAnonymous: isAnonymous,
    isEdited: isEdited,
    createdAt: createdAt ?? DateTime(2026, 10, 18),
  );
}
