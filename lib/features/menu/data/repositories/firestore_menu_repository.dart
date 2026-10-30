import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firebase/firestore_paths.dart';
import '../../domain/entities/menu_category.dart';
import '../../domain/entities/menu_feed.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/entities/menu_item_feed.dart';
import '../../domain/repositories/menu_repository.dart';
import '../models/menu_category_model.dart';
import '../firestore_failure.dart';
import '../models/menu_item_model.dart';

class FirestoreMenuRepository implements MenuRepository {
  FirestoreMenuRepository(this._firestore);

  final FirebaseFirestore _firestore;

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
}
