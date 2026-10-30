import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/firebase/firestore_paths.dart';
import '../../domain/entities/menu_category.dart';
import '../../domain/entities/menu_feed.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/entities/menu_item_draft.dart';
import '../../domain/entities/menu_item_feed.dart';
import '../../domain/repositories/menu_repository.dart';
import '../models/menu_category_model.dart';
import '../firestore_failure.dart';
import '../models/menu_item_model.dart';

class FirestoreMenuRepository implements MenuRepository {
  FirestoreMenuRepository(this._firestore, this._storage);

  final FirebaseFirestore _firestore;

  /// Read only when an Admin uploads an image, so browsing never depends
  /// on Firebase Storage being configured.
  final FirebaseStorage Function() _storage;

  CollectionReference<Map<String, dynamic>> get _categories =>
      _firestore.collection(FirestorePaths.categories);

  CollectionReference<Map<String, dynamic>> get _items =>
      _firestore.collection(FirestorePaths.menuItems);

  /// Filters every public item query needs so the security rules accept it.
  Query<Map<String, dynamic>> get _browsableItems => _items
      .where('isPublished', isEqualTo: true)
      .where('isCategoryPublished', isEqualTo: true);

  @override
  Stream<MenuFeed<MenuCategory>> watchPublishedCategories({int limit = 50}) {
    _checkLimit(limit);
    final query = _categories
        .where('isPublished', isEqualTo: true)
        .orderBy('sortOrder')
        .orderBy('name')
        .limit(limit);
    return _watchFeed(
      query,
      limit,
      (document) =>
          MenuCategoryModel.fromMap(document.id, document.data()).toEntity(),
    );
  }

  @override
  Stream<MenuFeed<MenuItem>> watchBrowsableItems({
    String? categoryId,
    required int limit,
  }) {
    _checkLimit(limit);
    final trimmedCategoryId = categoryId?.trim();

    final Query<Map<String, dynamic>> query;
    if (trimmedCategoryId == null || trimmedCategoryId.isEmpty) {
      query = _browsableItems
          .orderBy('categorySortOrder')
          .orderBy('categoryId')
          .orderBy('sortOrder')
          .orderBy('name')
          .limit(limit);
    } else {
      query = _items
          .where('categoryId', isEqualTo: trimmedCategoryId)
          .where('isPublished', isEqualTo: true)
          .where('isCategoryPublished', isEqualTo: true)
          .orderBy('sortOrder')
          .orderBy('name')
          .limit(limit);
    }
    return _watchFeed(query, limit, _toMenuItem);
  }

  @override
  Stream<MenuFeed<MenuItem>> watchSearchableItems({int limit = 300}) {
    _checkLimit(limit, max: _maxSearchLimit);
    final query = _browsableItems
        .orderBy('categorySortOrder')
        .orderBy('categoryId')
        .orderBy('sortOrder')
        .orderBy('name')
        .limit(limit);
    return _watchFeed(query, limit, _toMenuItem);
  }

  @override
  Stream<MenuFeed<MenuItem>> watchPopularItems({int limit = 5}) {
    _checkLimit(limit);
    final query = _browsableItems
        .where('isAvailable', isEqualTo: true)
        .orderBy('ratingAverage', descending: true)
        .orderBy('reviewCount', descending: true)
        .orderBy('name')
        .limit(limit);

    // Rated items have an average of at least 1, so they always sort ahead
    // of unrated items and filtering after the limit loses no rated item.
    return _watchFeed(query, limit, _toMenuItem).map(
      (feed) => MenuFeed(
        items: feed.items.where((item) => item.hasRating),
        isFromCache: feed.isFromCache,
        hasMore: false,
      ),
    );
  }

  @override
  Stream<MenuItemFeed> watchItem(String menuItemId) {
    return _items
        .doc(menuItemId)
        .snapshots(includeMetadataChanges: true)
        .map((document) {
          final data = document.data();
          MenuItem? item;
          if (document.exists && data != null) {
            try {
              item = MenuItemModel.fromMap(document.id, data).toEntity();
            } on FormatException {
              item = null;
            }
          }
          return MenuItemFeed(
            item: item,
            isFromCache: document.metadata.isFromCache,
          );
        })
        .transform(
          StreamTransformer<MenuItemFeed, MenuItemFeed>.fromHandlers(
            handleError: (error, stackTrace, sink) {
              // An item that stops being readable (unpublished) surfaces as
              // permission-denied on the document listener.
              if (error is FirebaseException &&
                  error.code == 'permission-denied') {
                sink.add(const MenuItemFeed(item: null, isFromCache: false));
                sink.close();
                return;
              }
              sink.addError(menuFailureFrom(error), stackTrace);
            },
          ),
        );
  }

  @override
  Stream<List<MenuItem>> watchAdminItems({
    String? categoryId,
    int limit = 100,
  }) {
    _checkLimit(limit);

    Query<Map<String, dynamic>> query = _items;
    if (categoryId != null && categoryId.trim().isNotEmpty) {
      query = query.where('categoryId', isEqualTo: categoryId.trim());
    }
    return query
        .orderBy('sortOrder')
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              List<MenuItem>.unmodifiable(snapshot.docs.map(_toMenuItem)),
        );
  }

  @override
  Future<void> setAvailability(String id, {required bool isAvailable}) {
    return _items.doc(id).update({
      'isAvailable': isAvailable,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> setPublished(String id, {required bool isPublished}) {
    return _items.doc(id).update({
      'isPublished': isPublished,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<String> saveItem(MenuItemDraft draft) async {
    final isCreating = draft.id == null;
    final reference = isCreating ? _items.doc() : _items.doc(draft.id);
    var imageUrl = draft.existingImageUrl;

    if (draft.imageBytes != null) {
      final extension = _extension(draft.imageName);
      final imageReference = _storage().ref(
        'menu_items/${reference.id}/${DateTime.now().millisecondsSinceEpoch}.$extension',
      );
      final contentType = extension == 'png' ? 'image/png' : 'image/jpeg';
      await imageReference.putData(
        draft.imageBytes!,
        SettableMetadata(contentType: contentType),
      );
      imageUrl = await imageReference.getDownloadURL();
    }

    var sortOrder = draft.sortOrder;
    if (isCreating) {
      final last = await _items
          .orderBy('sortOrder', descending: true)
          .limit(1)
          .get();
      sortOrder = last.docs.isEmpty
          ? 0
          : ((last.docs.first.data()['sortOrder'] as num?)?.toInt() ?? -1) + 1;
    }

    // Denormalized copies of the owning category (docs/database_schema.md).
    final category = await _categories.doc(draft.categoryId).get();
    final categoryData = category.data();

    final values = <String, Object?>{
      'categoryId': draft.categoryId,
      'name': draft.name,
      'description': draft.description,
      'imageUrl': imageUrl,
      'basePrice': draft.basePrice,
      'isAvailable': draft.isAvailable,
      'isPublished': draft.isPublished,
      'sortOrder': sortOrder,
      'sizes': [
        for (final size in draft.sizes)
          {'id': size.id, 'name': size.name, 'priceDelta': size.priceDelta},
      ],
      'isCategoryPublished': categoryData?['isPublished'] as bool? ?? false,
      'categorySortOrder': (categoryData?['sortOrder'] as num?)?.toInt() ?? 0,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (isCreating) {
      values['ratingAverage'] = 0.0;
      values['reviewCount'] = 0;
      values['createdAt'] = FieldValue.serverTimestamp();
      await reference.set(values, SetOptions(merge: false));
    } else {
      await reference.set(values, SetOptions(merge: true));
    }
    return reference.id;
  }

  MenuItem _toMenuItem(QueryDocumentSnapshot<Map<String, dynamic>> document) {
    return MenuItemModel.fromMap(document.id, document.data()).toEntity();
  }

  Stream<MenuFeed<T>> _watchFeed<T>(
    Query<Map<String, dynamic>> query,
    int limit,
    T Function(QueryDocumentSnapshot<Map<String, dynamic>>) map,
  ) {
    return query
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          final items = <T>[];
          for (final document in snapshot.docs) {
            try {
              items.add(map(document));
            } on FormatException {
              // Skip malformed documents instead of failing the whole feed.
            }
          }
          return MenuFeed<T>(
            items: items,
            isFromCache: snapshot.metadata.isFromCache,
            hasMore: snapshot.docs.length == limit,
          );
        })
        .transform(
          StreamTransformer<MenuFeed<T>, MenuFeed<T>>.fromHandlers(
            handleError: (error, stackTrace, sink) {
              sink.addError(menuFailureFrom(error), stackTrace);
            },
          ),
        );
  }

  static const _maxPageLimit = 100;
  static const _maxSearchLimit = 500;

  static void _checkLimit(int limit, {int max = _maxPageLimit}) {
    if (limit < 1 || limit > max) {
      throw RangeError.range(limit, 1, max, 'limit');
    }
  }

  static String _extension(String? fileName) {
    final normalized = fileName?.toLowerCase() ?? '';
    return normalized.endsWith('.png') ? 'png' : 'jpg';
  }
}
