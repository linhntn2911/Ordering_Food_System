import 'package:ordering_food_system/features/review/models/review_model.dart';

abstract class ReviewRepository {
  Future<List<ReviewModel>> getMyReviews();
  Future<void> submitReview({required String orderId, required int rating, required String comment, List<String> images = const []});
}
