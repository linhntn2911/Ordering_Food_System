import 'package:equatable/equatable.dart';

class ReviewModel extends Equatable {
  const ReviewModel({required this.id, required this.orderId, required this.userId, required this.rating, required this.comment, required this.createdAt, this.images = const []});
  final String id;
  final String orderId;
  final String userId;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final List<String> images;

  @override
  List<Object?> get props => [id, orderId, userId, rating, comment, createdAt, images];
}
