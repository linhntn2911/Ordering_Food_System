class Category {
  const Category({
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
}
