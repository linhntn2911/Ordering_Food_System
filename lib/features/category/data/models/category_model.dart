import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/category.dart';

class CategoryModel {
  const CategoryModel({
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

  factory CategoryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) {
      throw StateError('Danh mục ${document.id} không có dữ liệu.');
    }
    final name = data['name'];
    if (name is! String || name.trim().isEmpty) {
      throw FormatException('Tên danh mục ${document.id} không hợp lệ.');
    }
    return CategoryModel(
      id: document.id,
      name: name.trim(),
      imageUrl: data['imageUrl'] as String? ?? '',
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      isPublished: data['isPublished'] as bool? ?? false,
    );
  }

  Category toEntity() => Category(
    id: id,
    name: name,
    imageUrl: imageUrl,
    sortOrder: sortOrder,
    isPublished: isPublished,
  );
}
