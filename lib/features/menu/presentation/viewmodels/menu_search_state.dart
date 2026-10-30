import '../../domain/entities/menu_category.dart';
import '../../domain/entities/menu_failure.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/entities/menu_search_query.dart';

enum MenuSearchStatus { loading, ready, error }

enum MenuSearchNotice { categoryRemoved }

class MenuSearchState {
  MenuSearchState({
    required this.query,
    required this.status,
    Iterable<MenuItem> results = const [],
    Iterable<MenuCategory> categories = const [],
    this.isOffline = false,
    this.error,
    this.notice,
  }) : results = List<MenuItem>.unmodifiable(results),
       categories = List<MenuCategory>.unmodifiable(categories);

  /// Applied keyword and filters.
  final MenuSearchQuery query;
  final MenuSearchStatus status;

  /// Matching items, empty while loading or on error.
  final List<MenuItem> results;

  /// Published categories offered by the filter sheet.
  final List<MenuCategory> categories;
  final bool isOffline;
  final MenuFailure? error;
  final MenuSearchNotice? notice;

  MenuSearchFilters get filters => query.filters;

  bool get isEmptyResult => status == MenuSearchStatus.ready && results.isEmpty;

  MenuCategory? get selectedCategory {
    final id = filters.categoryId;
    if (id == null) {
      return null;
    }
    for (final category in categories) {
      if (category.id == id) {
        return category;
      }
    }
    return null;
  }
}
