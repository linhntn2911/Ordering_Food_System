import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/menu_category.dart';

class MenuCategoryModel {
  const MenuCategoryModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.sortOrder,
    required this.isPublished,
  });

  final String id;
  final String name;
  final String imageUrl;
  final int sortOrder;
  final bool isPublished;

  factory MenuCategoryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
    SnapshotOptions? _,
  ) {
    final data = document.data();
    if (data == null) {
      throw StateError('Category ${document.id} has no data.');
    }
    return MenuCategoryModel.fromMap(document.id, data);
  }

  /// Maps raw document data, throwing [FormatException] when `name` is
  /// missing or blank.
  factory MenuCategoryModel.fromMap(String id, Map<String, dynamic> data) {
    final name = data['name'];
    if (name is! String || name.trim().isEmpty) {
      throw const FormatException('Missing or invalid name.');
    }
    return MenuCategoryModel(
      id: id,
      name: name,
      imageUrl: data['imageUrl'] as String? ?? '',
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      isPublished: data['isPublished'] as bool? ?? false,
    );
  }

  Map<String, Object?> toFirestore() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'sortOrder': sortOrder,
      'isPublished': isPublished,
    };
  }

  MenuCategory toEntity() {
    return MenuCategory(
      id: id,
      name: name,
      imageUrl: imageUrl,
      sortOrder: sortOrder,
    );
  }
}
