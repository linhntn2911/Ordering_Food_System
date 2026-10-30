/// Public display copy of a review (`menu_items/{id}/reviews/{reviewId}`).
///
/// It carries no customer or order identifiers, so the author is only ever
/// shown as "Khách hàng" or "Khách hàng ẩn danh".
class Review {
  Review({
    required this.id,
    required this.rating,
    required this.comment,
    required Iterable<String> imageUrls,
    required this.isAnonymous,
    required this.isEdited,
    required this.createdAt,
  }) : imageUrls = List<String>.unmodifiable(imageUrls);

  static const maxImages = 3;

  final String id;

  /// 1–5 stars.
  final int rating;
  final String comment;
  final List<String> imageUrls;
  final bool isAnonymous;
  final bool isEdited;
  final DateTime createdAt;

  String get authorLabel => isAnonymous ? 'Khách hàng ẩn danh' : 'Khách hàng';
}
