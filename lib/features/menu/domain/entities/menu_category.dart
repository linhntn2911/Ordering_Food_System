class MenuCategory {
  const MenuCategory({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final String imageUrl;
  final int sortOrder;
}
