import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/menu_item.dart';

class MenuItemModel {
  const MenuItemModel({
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

  factory MenuItemModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
    SnapshotOptions? _,
  ) {
    final data = document.data();
    if (data == null) {
      throw StateError('Menu item ${document.id} has no data.');
    }

    return MenuItemModel(
      id: document.id,
      categoryId: _requiredString(data, 'categoryId'),
      name: _requiredString(data, 'name'),
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      basePrice: _requiredInt(data, 'basePrice'),
      isAvailable: data['isAvailable'] as bool? ?? false,
      isPublished: data['isPublished'] as bool? ?? false,
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      ratingAverage: (data['ratingAverage'] as num?)?.toDouble() ?? 0,
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, Object?> toFirestore() {
    return {
      'categoryId': categoryId,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'basePrice': basePrice,
      'isAvailable': isAvailable,
      'isPublished': isPublished,
      'sortOrder': sortOrder,
      'ratingAverage': ratingAverage,
      'reviewCount': reviewCount,
    };
  }

  MenuItem toEntity() {
    return MenuItem(
      id: id,
      categoryId: categoryId,
      name: name,
      description: description,
      imageUrl: imageUrl,
      basePrice: basePrice,
      isAvailable: isAvailable,
      isPublished: isPublished,
      sortOrder: sortOrder,
      ratingAverage: ratingAverage,
      reviewCount: reviewCount,
    );
  }

  static String _requiredString(Map<String, dynamic> data, String field) {
    final value = data[field];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    throw FormatException('Missing or invalid $field.');
  }

  static int _requiredInt(Map<String, dynamic> data, String field) {
    final value = data[field];
    if (value is num) {
      return value.toInt();
    }
    throw FormatException('Missing or invalid $field.');
  }
}
