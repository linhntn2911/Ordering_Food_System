import '../../../menu/domain/entities/menu_feed.dart';
import '../entities/review.dart';

/// Read-only access to the public review copies of one menu item
/// (`specs/004-food-details/contracts/repositories.md`).
///
/// - Reviews are ordered newest first.
/// - A `limit` outside 1–100 throws a [RangeError].
/// - [MenuFeed.isFromCache] follows snapshot metadata and [MenuFeed.hasMore]
///   is true when the number of documents received equals the limit.
/// - Malformed documents are skipped; Firestore errors are emitted as
///   `MenuFailure`.
abstract interface class ReviewRepository {
  Stream<MenuFeed<Review>> watchMenuItemReviews(
    String menuItemId, {
    required int limit,
  });
}
