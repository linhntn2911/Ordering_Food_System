import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/firebase/firestore_paths.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/entities/menu_item_draft.dart';
import '../../domain/repositories/menu_repository.dart';
import '../models/menu_item_model.dart';

class FirestoreMenuRepository implements MenuRepository {
  FirestoreMenuRepository(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

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

  @override
  Stream<List<MenuItem>> watchAdminItems({
    String? categoryId,
    int limit = 100,
  }) {
    if (limit < 1 || limit > 100) {
      throw RangeError.range(limit, 1, 100, 'limit');
    }

    Query<MenuItemModel> query = _items;
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
    final rawItems = _firestore.collection(FirestorePaths.menuItems);
    final reference = isCreating ? rawItems.doc() : rawItems.doc(draft.id);
    var imageUrl = draft.existingImageUrl;

    if (draft.imageBytes != null) {
      final extension = _extension(draft.imageName);
      final imageReference = _storage.ref(
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
      sortOrder = last.docs.isEmpty ? 0 : last.docs.first.data().sortOrder + 1;
    }

    final values = <String, Object?>{
      'categoryId': draft.categoryId,
      'name': draft.name,
      'description': draft.description,
      'imageUrl': imageUrl,
      'basePrice': draft.basePrice,
      'isAvailable': draft.isAvailable,
      'isPublished': draft.isPublished,
      'sortOrder': sortOrder,
      'sizes': draft.sizes
          .map(
            (size) => {
              'name': size.name,
              'additionalPrice': size.additionalPrice,
            },
          )
          .toList(growable: false),
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

  String _extension(String? fileName) {
    final normalized = fileName?.toLowerCase() ?? '';
    return normalized.endsWith('.png') ? 'png' : 'jpg';
  }
}
