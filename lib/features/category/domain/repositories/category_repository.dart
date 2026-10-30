import '../entities/category.dart';

abstract interface class CategoryRepository {
  Stream<List<Category>> watchCategories({int limit = 100});
  Future<void> createCategory({
    required String name,
    required String imageUrl,
    required bool isPublished,
  });
  Future<void> updateCategory({
    required String id,
    required String name,
    required String imageUrl,
    required bool isPublished,
  });
  Future<void> setPublished(String id, {required bool isPublished});
  Future<void> swapSortOrder(Category first, Category second);
}
