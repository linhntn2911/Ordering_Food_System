import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../menu/domain/entities/menu_feed.dart';
import '../data/repositories/firestore_review_repository.dart';
import '../domain/entities/review.dart';
import '../domain/repositories/review_repository.dart';

typedef MenuItemReviewsQuery = ({String menuItemId, int limit});

/// Review streams expose errors immediately; the screen offers its own
/// retry action instead of Riverpod's automatic retry.
Duration? _noAutomaticRetry(int retryCount, Object error) => null;

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return FirestoreReviewRepository(ref.watch(firebaseFirestoreProvider));
});

final menuItemReviewsProvider = StreamProvider.autoDispose
    .family<MenuFeed<Review>, MenuItemReviewsQuery>((ref, query) {
      return ref
          .watch(reviewRepositoryProvider)
          .watchMenuItemReviews(query.menuItemId, limit: query.limit);
    }, retry: _noAutomaticRetry);
