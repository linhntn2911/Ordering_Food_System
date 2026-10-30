import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/firebase/firebase_providers.dart';
import '../../data/repositories/firestore_menu_repository.dart';
import '../../domain/entities/menu_category.dart';
import '../../domain/entities/menu_feed.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/entities/menu_item_feed.dart';
import '../../domain/repositories/menu_repository.dart';

typedef BrowsableItemsQuery = ({String? categoryId, int limit});

/// Browsing streams expose errors immediately; the screen offers its own
/// retry action instead of Riverpod's automatic retry.
Duration? _noAutomaticRetry(int retryCount, Object error) => null;

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return FirestoreMenuRepository(
    ref.watch(firebaseFirestoreProvider),
    ref.watch(firebaseStorageProvider),
  );
});

final menuCategoriesProvider =
    StreamProvider.autoDispose<MenuFeed<MenuCategory>>((ref) {
      return ref.watch(menuRepositoryProvider).watchPublishedCategories();
    }, retry: _noAutomaticRetry);

final browsableItemsProvider = StreamProvider.autoDispose
    .family<MenuFeed<MenuItem>, BrowsableItemsQuery>((ref, query) {
      return ref
          .watch(menuRepositoryProvider)
          .watchBrowsableItems(
            categoryId: query.categoryId,
            limit: query.limit,
          );
    }, retry: _noAutomaticRetry);

final popularItemsProvider = StreamProvider.autoDispose<MenuFeed<MenuItem>>((
  ref,
) {
  return ref.watch(menuRepositoryProvider).watchPopularItems();
}, retry: _noAutomaticRetry);

final searchableItemsProvider = StreamProvider.autoDispose<MenuFeed<MenuItem>>((
  ref,
) {
  return ref.watch(menuRepositoryProvider).watchSearchableItems();
}, retry: _noAutomaticRetry);

final menuItemProvider = StreamProvider.autoDispose
    .family<MenuItemFeed, String>((ref, menuItemId) {
      return ref.watch(menuRepositoryProvider).watchItem(menuItemId);
    }, retry: _noAutomaticRetry);

/// How long cache-only data must persist before the screen is treated as
/// offline. Overridden in tests.
final menuOfflineGraceProvider = Provider<Duration>((ref) {
  return const Duration(seconds: 2);
});

/// Delay after the last keystroke before a search keyword is applied.
/// Overridden in tests.
final menuSearchDebounceProvider = Provider<Duration>((ref) {
  return const Duration(milliseconds: 300);
});
