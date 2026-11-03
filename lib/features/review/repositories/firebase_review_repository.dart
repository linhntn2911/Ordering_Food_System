import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ordering_food_system/core/errors/failures.dart';
import 'package:ordering_food_system/features/review/models/review_model.dart';
import 'package:ordering_food_system/features/review/repositories/review_repository.dart';

/// Reviews are written by the `submitReview` Cloud Function, which validates
/// ownership, completion, the 30-day window and duplicates in a transaction.
class FirebaseReviewRepository implements ReviewRepository {
  FirebaseReviewRepository({
    required this.auth,
    required this.firestore,
    FirebaseFunctions? functions,
  }) : _functions =
           functions ??
           FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final FirebaseFunctions _functions;

  @override
  Future<List<ReviewModel>> getMyReviews() async {
    final uid = auth.currentUser?.uid;
    if (uid == null) return const [];
    final snapshot = await firestore
        .collection('reviews')
        .where('customerId', isEqualTo: uid)
        .get();
    final reviews = snapshot.docs.map(_fromDocument).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(reviews);
  }

  @override
  Future<void> submitReview({
    required String orderId,
    required int rating,
    required String comment,
    List<String> images = const [],
  }) async {
    try {
      await _functions.httpsCallable('submitReview').call<Map<String, dynamic>>({
        'orderId': orderId,
        'rating': rating,
        'comment': comment,
        'imageUrls': images,
      });
    } on FirebaseFunctionsException catch (error) {
      throw ValidationFailure(error.message ?? 'Không thể gửi đánh giá.');
    }
  }

  ReviewModel _fromDocument(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return ReviewModel(
      id: doc.id,
      orderId: data['orderId'] as String? ?? '',
      userId: data['customerId'] as String? ?? '',
      rating: (data['rating'] as num?)?.toInt() ?? 0,
      comment: data['comment'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      images: List<String>.from(data['imageUrls'] as List? ?? const []),
    );
  }
}
