import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firebase/firestore_paths.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/repositories/menu_repository.dart';
import '../models/menu_item_model.dart';

class FirestoreMenuRepository implements MenuRepository {
  FirestoreMenuRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<MenuItemModel> get _items {
    return _firestore
        .collection(FirestorePaths.menuItems)
        .withConverter<MenuItemModel>(
          fromFirestore: MenuItemModel.fromFirestore,
          toFirestore: (item, _) => item.toFirestore(),
        );
  }

  @override
  Stream<List<MenuItem>> watchPublishedItems({
    String? categoryId,
    int limit = 50,
  }) {
    if (limit < 1 || limit > 100) {
      throw RangeError.range(limit, 1, 100, 'limit');
    }

    Query<MenuItemModel> query = _items
        .where('isPublished', isEqualTo: true)
        .where('isAvailable', isEqualTo: true);

    if (categoryId != null && categoryId.trim().isNotEmpty) {
      query = query.where('categoryId', isEqualTo: categoryId.trim());
    }

    return query
        .orderBy('sortOrder')
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => List<MenuItem>.unmodifiable(
            snapshot.docs.map((document) => document.data().toEntity()),
          ),
        );
  }
}
