import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ordering_food_system/core/errors/failures.dart';
import 'package:ordering_food_system/core/firebase/firestore_paths.dart';
import 'package:ordering_food_system/features/review/data/models/review_model.dart';
import 'package:ordering_food_system/features/review/domain/repositories/review_repository.dart';

/// Writes a review directly to Firestore. Firestore rules validate ownership,
/// completion, the 30-day window and one review per order (`<uid>_<orderId>`).
class FirebaseReviewRepository implements ReviewRepository {
  FirebaseReviewRepository({required this.auth, required this.firestore});

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  @override
  Future<List<ReviewModel>> getMyReviews() async {
    final uid = auth.currentUser?.uid;
    if (uid == null) return const [];
    final snapshot = await firestore
        .collection(FirestorePaths.reviews)
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
    final uid = auth.currentUser?.uid;
    if (uid == null) {
      throw const AuthFailure();
    }
    final reviewId = '${uid}_$orderId';
    final reviewRef = firestore
        .collection(FirestorePaths.reviews)
        .doc(reviewId);

    final trimmedComment = comment.trim();
    try {
      final orderRef = firestore.collection(FirestorePaths.orders).doc(orderId);
      final orderSnapshot = await orderRef.get();
      final orderData = orderSnapshot.data();
      if (orderData == null || orderData['customerId'] != uid) {
        throw const ValidationFailure(
          'Không tìm thấy đơn hàng của bạn. Vui lòng mở lại từ lịch sử đơn hàng.',
        );
      }
      if (orderData['orderStatus'] != 'Completed') {
        throw const ValidationFailure(
          'Chỉ có thể đánh giá đơn hàng đã hoàn thành.',
        );
      }

      final itemsSnapshot = await orderRef.collection('items').get();
      final menuItemIds = {
        for (final item in itemsSnapshot.docs)
          if ((item.data()['menuItemId'] as String?)?.isNotEmpty ?? false)
            item.data()['menuItemId'] as String,
      }.toList(growable: false);
      if (menuItemIds.isEmpty) {
        throw const ValidationFailure('Không tìm thấy món trong đơn hàng.');
      }

      final timestamp = FieldValue.serverTimestamp();
      final batch = firestore.batch();
      batch.set(reviewRef, {
        'customerId': uid,
        'orderId': orderId,
        'menuItemIds': menuItemIds,
        'rating': rating,
        'comment': trimmedComment,
        'imageUrls': images,
        'isEdited': false,
        'createdAt': timestamp,
        'updatedAt': timestamp,
      });

      for (final menuItemId in menuItemIds) {
        final publicRef = firestore
            .collection(FirestorePaths.menuItems)
            .doc(menuItemId)
            .collection('reviews')
            .doc(reviewId);
        batch.set(publicRef, {
          'rating': rating,
          'comment': trimmedComment,
          'imageUrls': images,
          'isEdited': false,
          'createdAt': timestamp,
          'updatedAt': timestamp,
        });
      }
      await batch.commit();
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw const ValidationFailure(
          'Chỉ đánh giá được đơn hàng đã hoàn thành trong vòng 30 ngày.',
        );
      }
      throw const ValidationFailure(
        'Không thể gửi đánh giá, vui lòng thử lại.',
      );
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
