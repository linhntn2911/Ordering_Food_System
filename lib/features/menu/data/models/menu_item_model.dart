import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/menu_item.dart';
import '../../domain/entities/menu_option.dart';

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
    required this.sizes,
    required this.toppings,
    required this.isCategoryPublished,
    required this.categorySortOrder,
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
  final List<MenuOption> sizes;
  final List<MenuOption> toppings;
  final bool isCategoryPublished;
  final int categorySortOrder;

  factory MenuItemModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
    SnapshotOptions? _,
  ) {
    final data = document.data();
    if (data == null) {
      throw StateError('Menu item ${document.id} has no data.');
    }
    return MenuItemModel.fromMap(document.id, data);
  }

  /// Maps raw document data, throwing [FormatException] when a required
  /// field is missing or invalid. Optional fields fall back to defaults.
  factory MenuItemModel.fromMap(String id, Map<String, dynamic> data) {
    return MenuItemModel(
      id: id,
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
      sizes: _options(data['sizes']),
      toppings: _options(data['toppings']),
      isCategoryPublished: data['isCategoryPublished'] as bool? ?? false,
      categorySortOrder: (data['categorySortOrder'] as num?)?.toInt() ?? 0,
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
      'sizes': [for (final size in sizes) _optionToMap(size)],
      'toppings': [for (final topping in toppings) _optionToMap(topping)],
      'isCategoryPublished': isCategoryPublished,
      'categorySortOrder': categorySortOrder,
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
      sizes: sizes,
      toppings: toppings,
      isCategoryPublished: isCategoryPublished,
      categorySortOrder: categorySortOrder,
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

  /// Reads `{ id, name, priceDelta }` maps, skipping malformed entries.
  static List<MenuOption> _options(Object? raw) {
    if (raw is! List) {
      return const [];
    }
    final options = <MenuOption>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final id = entry['id'];
      final name = entry['name'];
      final priceDelta = entry['priceDelta'];
      if (id is String &&
          id.isNotEmpty &&
          name is String &&
          name.isNotEmpty &&
          priceDelta is num &&
          priceDelta >= 0) {
        options.add(
          MenuOption(id: id, name: name, priceDelta: priceDelta.toInt()),
        );
      }
    }
    return List.unmodifiable(options);
  }

  static Map<String, Object> _optionToMap(MenuOption option) {
    return {
      'id': option.id,
      'name': option.name,
      'priceDelta': option.priceDelta,
    };
  }
}
