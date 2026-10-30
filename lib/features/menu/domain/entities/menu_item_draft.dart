import 'dart:typed_data';

import 'menu_option.dart';

class MenuItemDraft {
  const MenuItemDraft({
    this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.existingImageUrl,
    this.imageBytes,
    this.imageName,
    required this.basePrice,
    required this.isAvailable,
    required this.isPublished,
    required this.sortOrder,
    this.sizes = const [],
  });

  final String? id;
  final String categoryId;
  final String name;
  final String description;
  final String existingImageUrl;
  final Uint8List? imageBytes;
  final String? imageName;
  final int basePrice;
  final bool isAvailable;
  final bool isPublished;
  final int sortOrder;
  final List<MenuOption> sizes;
}
