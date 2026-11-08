/// Public display copy of a review (`menu_items/{id}/reviews/{reviewId}`).
///
/// It carries no customer or order identifiers, so the author is always shown
/// as "Khách hàng".
class Review {
  Review({
    required this.id,
    required this.rating,
    required this.comment,
    required Iterable<String> imageUrls,
    required this.isEdited,
    required this.createdAt,
  }) : imageUrls = List<String>.unmodifiable(imageUrls);

  static const maxImages = 3;

  final String id;

  /// 1–5 stars.
  final int rating;
  final String comment;
  final List<String> imageUrls;
  final bool isEdited;
  final DateTime createdAt;

  String get authorLabel => 'Khách hàng';
}
