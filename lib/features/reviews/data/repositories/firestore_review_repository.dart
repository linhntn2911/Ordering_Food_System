import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firebase/firestore_paths.dart';
import '../../../menu/data/firestore_failure.dart';
import '../../../menu/domain/entities/menu_feed.dart';
import '../../domain/entities/review.dart';
import '../../domain/repositories/review_repository.dart';
import '../models/review_model.dart';

class FirestoreReviewRepository implements ReviewRepository {
  FirestoreReviewRepository(this._firestore);

  static const _maxLimit = 100;

  final FirebaseFirestore _firestore;

  @override
  Stream<MenuFeed<Review>> watchMenuItemReviews(
    String menuItemId, {
    required int limit,
  }) {
    if (limit < 1 || limit > _maxLimit) {
      throw RangeError.range(limit, 1, _maxLimit, 'limit');
    }
    return _firestore
        .collection(FirestorePaths.menuItemReviews(menuItemId))
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          final reviews = <Review>[];
          for (final document in snapshot.docs) {
            try {
              reviews.add(
                ReviewModel.fromMap(document.id, document.data()).toEntity(),
              );
            } on FormatException {
              // Skip malformed reviews instead of failing the whole list.
            }
          }
          return MenuFeed<Review>(
            items: reviews,
            isFromCache: snapshot.metadata.isFromCache,
            hasMore: snapshot.docs.length == limit,
          );
        })
        .transform(
          StreamTransformer<MenuFeed<Review>, MenuFeed<Review>>.fromHandlers(
            handleError: (error, stackTrace, sink) {
              sink.addError(menuFailureFrom(error), stackTrace);
            },
          ),
        );
  }
}
