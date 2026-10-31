import 'package:ordering_food_system/features/review/models/review_model.dart';

abstract class ReviewRepository {
  Future<List<ReviewModel>> getMyReviews();
  Future<void> submitReview({required String orderId, required int rating, required String comment, List<String> images = const []});
}

class MockReviewRepository implements ReviewRepository {
  final List<ReviewModel> _reviews = [];

  @override
  Future<List<ReviewModel>> getMyReviews() async {
    
    return List.of(_reviews);
  }

  @override
  Future<void> submitReview({required String orderId, required int rating, required String comment, List<String> images = const []}) async {
    
    _reviews.insert(0, ReviewModel(id: 'RV-${DateTime.now().millisecondsSinceEpoch}', orderId: orderId, userId: 'user_01', rating: rating, comment: comment, createdAt: DateTime.now(), images: images));
  }
}
