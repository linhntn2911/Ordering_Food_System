import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/review.dart';

class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.rating,
    required this.comment,
    required this.imageUrls,
    required this.isEdited,
    required this.createdAt,
  });

  final String id;
  final int rating;
  final String comment;
  final List<String> imageUrls;
  final bool isEdited;
  final DateTime createdAt;

  /// Maps a public review document, throwing [FormatException] when the
  /// rating is not 1–5 or `createdAt` is missing.
  factory ReviewModel.fromMap(String id, Map<String, dynamic> data) {
    final rating = data['rating'];
    if (rating is! int || rating < 1 || rating > 5) {
      throw const FormatException('Điểm đánh giá bị thiếu hoặc không hợp lệ.');
    }
    final createdAt = data['createdAt'];
    if (createdAt is! Timestamp) {
      throw const FormatException('Thời gian tạo bị thiếu hoặc không hợp lệ.');
    }
    return ReviewModel(
      id: id,
      rating: rating,
      comment: data['comment'] as String? ?? '',
      imageUrls: _imageUrls(data['imageUrls']),
      isEdited: data['isEdited'] as bool? ?? false,
      createdAt: createdAt.toDate(),
    );
  }

  Review toEntity() {
    return Review(
      id: id,
      rating: rating,
      comment: comment,
      imageUrls: imageUrls,
      isEdited: isEdited,
      createdAt: createdAt,
    );
  }

  static List<String> _imageUrls(Object? raw) {
    if (raw is! List) {
      return const [];
    }
    return [
      for (final url in raw)
        if (url is String && url.isNotEmpty) url,
    ].take(Review.maxImages).toList(growable: false);
  }
}
