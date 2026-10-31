import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oder_food/features/review/models/review_model.dart';
import 'package:oder_food/features/review/repositories/review_repository.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) => MockReviewRepository());

final myReviewsProvider = FutureProvider<List<ReviewModel>>((ref) async {
  final repo = ref.watch(reviewRepositoryProvider);
  return repo.getMyReviews();
});

final reviewFormProvider = StateNotifierProvider<ReviewFormNotifier, ReviewFormState>((ref) {
  return ReviewFormNotifier(ref);
});

class ReviewFormState {
  ReviewFormState({this.rating = 5, this.comment = '', this.submitting = false, this.images = const []});
  final int rating;
  final String comment;
  final bool submitting;
  final List<String> images;

  ReviewFormState copyWith({int? rating, String? comment, bool? submitting, List<String>? images}) {
    return ReviewFormState(rating: rating ?? this.rating, comment: comment ?? this.comment, submitting: submitting ?? this.submitting, images: images ?? this.images);
  }
}

class ReviewFormNotifier extends StateNotifier<ReviewFormState> {
  ReviewFormNotifier(this.ref) : super(ReviewFormState());
  final Ref ref;

  void setRating(int rating) => state = state.copyWith(rating: rating);
  void setComment(String comment) => state = state.copyWith(comment: comment);
  void addImage(String image) => state = state.copyWith(images: [...state.images, image]);
  void removeImage(String image) => state = state.copyWith(images: state.images.where((e) => e != image).toList());

  Future<bool> submit(String orderId) async {
    if (state.submitting) return false;
    state = state.copyWith(submitting: true);
    try {
      final repo = ref.read(reviewRepositoryProvider);
      await repo.submitReview(orderId: orderId, rating: state.rating, comment: state.comment, images: state.images);
      ref.invalidate(myReviewsProvider);
      state = ReviewFormState();
      return true;
    } catch (_) {
      state = state.copyWith(submitting: false);
      return false;
    }
  }
}
