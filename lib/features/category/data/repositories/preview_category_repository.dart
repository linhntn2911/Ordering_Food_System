import 'dart:async';

import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';

/// In-memory data used only when a debug web build has no Firebase Web app.
class PreviewCategoryRepository implements CategoryRepository {
  PreviewCategoryRepository()
    : _categories = [
        const Category(
          id: 'fried-chicken',
          name: 'Gà rán',
          imageUrl: '',
          sortOrder: 0,
          isPublished: true,
        ),
        const Category(
          id: 'rice',
          name: 'Cơm',
          imageUrl: '',
          sortOrder: 1,
          isPublished: true,
        ),
        const Category(
          id: 'noodles',
          name: 'Mì',
          imageUrl: '',
          sortOrder: 2,
          isPublished: true,
        ),
        const Category(
          id: 'snacks',
          name: 'Đồ ăn vặt',
          imageUrl: '',
          sortOrder: 3,
          isPublished: true,
        ),
        const Category(
          id: 'combos',
          name: 'Combo',
          imageUrl: '',
          sortOrder: 4,
          isPublished: true,
        ),
        const Category(
          id: 'tea',
          name: 'Trà',
          imageUrl: '',
          sortOrder: 5,
          isPublished: true,
        ),
        const Category(
          id: 'yogurt',
          name: 'Sữa chua',
          imageUrl: '',
          sortOrder: 6,
          isPublished: true,
        ),
        const Category(
          id: 'fresh-milk',
          name: 'Sữa tươi',
          imageUrl: '',
          sortOrder: 7,
          isPublished: true,
        ),
        const Category(
          id: 'latte',
          name: 'Latte',
          imageUrl: '',
          sortOrder: 8,
          isPublished: true,
        ),
        const Category(
          id: 'soft-drinks',
          name: 'Nước ngọt',
          imageUrl: '',
          sortOrder: 9,
          isPublished: true,
        ),
        const Category(
          id: 'juice-smoothies',
          name: 'Nước ép & Sinh tố',
          imageUrl: '',
          sortOrder: 10,
          isPublished: true,
        ),
      ];

  final List<Category> _categories;
  final StreamController<List<Category>> _changes =
      StreamController<List<Category>>.broadcast();

  @override
  Stream<List<Category>> watchCategories({int limit = 100}) async* {
    yield _snapshot(limit);
    yield* _changes.stream.map((_) => _snapshot(limit));
  }

  @override
  Future<void> createCategory({
    required String name,
    required String imageUrl,
    required bool isPublished,
  }) async {
    _categories.add(
      Category(
        id: 'preview-${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        imageUrl: imageUrl,
        sortOrder: _categories.length,
        isPublished: isPublished,
      ),
    );
    _emit();
  }

  @override
  Future<void> updateCategory({
    required String id,
    required String name,
    required String imageUrl,
    required bool isPublished,
  }) async {
    final index = _indexOf(id);
    final current = _categories[index];
    _categories[index] = Category(
      id: current.id,
      name: name,
      imageUrl: imageUrl,
      sortOrder: current.sortOrder,
      isPublished: isPublished,
    );
    _emit();
  }

  @override
  Future<void> setPublished(String id, {required bool isPublished}) async {
    final index = _indexOf(id);
    final current = _categories[index];
    _categories[index] = Category(
      id: current.id,
      name: current.name,
      imageUrl: current.imageUrl,
      sortOrder: current.sortOrder,
      isPublished: isPublished,
    );
    _emit();
  }

  @override
  Future<void> swapSortOrder(Category first, Category second) async {
    final firstIndex = _indexOf(first.id);
    final secondIndex = _indexOf(second.id);
    _categories[firstIndex] = Category(
      id: first.id,
      name: first.name,
      imageUrl: first.imageUrl,
      sortOrder: second.sortOrder,
      isPublished: first.isPublished,
    );
    _categories[secondIndex] = Category(
      id: second.id,
      name: second.name,
      imageUrl: second.imageUrl,
      sortOrder: first.sortOrder,
      isPublished: second.isPublished,
    );
    _categories.sort(
      (left, right) => left.sortOrder.compareTo(right.sortOrder),
    );
    _emit();
  }

  void dispose() => _changes.close();

  int _indexOf(String id) {
    final index = _categories.indexWhere((category) => category.id == id);
    if (index == -1) {
      throw StateError('Preview category $id was not found.');
    }
    return index;
  }

  List<Category> _snapshot(int limit) =>
      List<Category>.unmodifiable(_categories.take(limit));
  void _emit() => _changes.add(_snapshot(100));
}
