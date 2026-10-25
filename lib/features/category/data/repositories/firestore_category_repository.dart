import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firebase/firestore_paths.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../models/category_model.dart';

class FirestoreCategoryRepository implements CategoryRepository {
  FirestoreCategoryRepository(this._firestore);
  final FirebaseFirestore _firestore;
  CollectionReference<Map<String, dynamic>> get _categories =>
      _firestore.collection(FirestorePaths.categories);

  @override
  Stream<List<Category>> watchCategories({int limit = 100}) {
    if (limit < 1 || limit > 100) {
      throw RangeError.range(limit, 1, 100, 'limit');
    }
    return _categories
        .orderBy('sortOrder')
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => List<Category>.unmodifiable(
            snapshot.docs
                .map(CategoryModel.fromFirestore)
                .map((model) => model.toEntity()),
          ),
        );
  }

  @override
  Future<void> createCategory({
    required String name,
    required String imageUrl,
    required bool isPublished,
  }) async {
    final last = await _categories
        .orderBy('sortOrder', descending: true)
        .limit(1)
        .get();
    final lastOrder = last.docs.isEmpty
        ? -1
        : (last.docs.first.data()['sortOrder'] as num?)?.toInt() ?? -1;
    await _categories.add({
      'name': name,
      'imageUrl': imageUrl,
      'sortOrder': lastOrder + 1,
      'isPublished': isPublished,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateCategory({
    required String id,
    required String name,
    required String imageUrl,
    required bool isPublished,
  }) {
    return _categories.doc(id).update({
      'name': name,
      'imageUrl': imageUrl,
      'isPublished': isPublished,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> setPublished(String id, {required bool isPublished}) {
    return _categories.doc(id).update({
      'isPublished': isPublished,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> swapSortOrder(Category first, Category second) async {
    final batch = _firestore.batch();
    batch.update(_categories.doc(first.id), {
      'sortOrder': second.sortOrder,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_categories.doc(second.id), {
      'sortOrder': first.sortOrder,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }
}
