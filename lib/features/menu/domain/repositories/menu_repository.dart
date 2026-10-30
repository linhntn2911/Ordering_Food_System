import '../entities/menu_category.dart';
import '../entities/menu_feed.dart';
import '../entities/menu_item.dart';
import '../entities/menu_item_draft.dart';
import '../entities/menu_item_feed.dart';

/// Menu contract shared by customer browsing
/// (`specs/002-browse-menu/contracts/menu_repository.md`) and Admin menu
/// management.
///
/// - Browsing item queries always filter on `isPublished` and
///   `isCategoryPublished` so Firestore rules accept them.
/// - A `limit` outside 1–100 throws a [RangeError].
/// - [MenuFeed.isFromCache] follows snapshot metadata, and streams re-emit
///   when only the metadata changes.
/// - [MenuFeed.hasMore] is true when the number of documents received equals
///   the requested limit.
/// - Malformed documents are skipped; permission and network errors are
///   emitted as `MenuFailure`.
/// - Missing optional fields fall back to defaults (no sizes, zero rating).
abstract interface class MenuRepository {
  /// Published categories ordered by `sortOrder` then name.
  Stream<MenuFeed<MenuCategory>> watchPublishedCategories({int limit = 50});

  /// Published items of published categories, including sold-out items.
  ///
  /// Without [categoryId] items are ordered by category order, category,
  /// item order and name. With [categoryId] only that category is returned,
  /// ordered by item order and name.
  Stream<MenuFeed<MenuItem>> watchBrowsableItems({
    String? categoryId,
    required int limit,
  });

  /// Every published item of published categories, including sold-out items,
  /// in menu order (category order, category, item order, name).
  ///
  /// Used by search, which filters and sorts on the client
  /// (`specs/003-menu-search/contracts/menu_repository_search.md`). Unlike the
  /// other item queries, [limit] may be 1–500.
  Stream<MenuFeed<MenuItem>> watchSearchableItems({int limit = 300});

  /// Up to [limit] available items ordered by rating average, review count
  /// and name, excluding items without reviews.
  Stream<MenuFeed<MenuItem>> watchPopularItems({int limit = 5});

  /// One item for the details screen with snapshot metadata
  /// (`specs/004-food-details/contracts/repositories.md`).
  ///
  /// The feed's `item` is null when the document does not exist or is
  /// malformed. When the item stops being publicly readable the stream emits
  /// a null item and closes.
  Stream<MenuItemFeed> watchItem(String menuItemId);

  /// Every item, published or not, for Admin management.
  Stream<List<MenuItem>> watchAdminItems({String? categoryId, int limit = 100});

  Future<void> setAvailability(String id, {required bool isAvailable});

  Future<void> setPublished(String id, {required bool isPublished});

  /// Creates or updates an item and returns its ID. Copies the owning
  /// category's `isPublished` and `sortOrder` onto the item.
  Future<String> saveItem(MenuItemDraft draft);
}
