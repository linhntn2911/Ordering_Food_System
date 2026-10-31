import 'package:oder_food/features/review/models/review_model.dart';

abstract class ReviewRepository {
  Future<List<ReviewModel>> getMyReviews();
  Future<void> submitReview({required String orderId, required int rating, required String comment, List<String> images = const []});
}

class MockReviewRepository implements ReviewRepository {
  final List<ReviewModel> _reviews = [];

  @override
  Future<List<ReviewModel>> getMyReviews() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.of(_reviews);
  }

  @override
  Future<void> submitReview({required String orderId, required int rating, required String comment, List<String> images = const []}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _reviews.insert(0, ReviewModel(id: 'RV-${DateTime.now().millisecondsSinceEpoch}', orderId: orderId, userId: 'user_01', rating: rating, comment: comment, createdAt: DateTime.now(), images: images));
  }
}
