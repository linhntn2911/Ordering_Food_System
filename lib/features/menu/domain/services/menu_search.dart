import '../../../../core/utils/search_text.dart';
import '../entities/menu_item.dart';
import '../entities/menu_search_query.dart';

/// Filters and sorts [items] for [query]
/// (`specs/003-menu-search/research.md` R3).
///
/// [items] must already be in menu order; that order breaks every tie, so
/// the result is stable. [normalizedNames] maps item ids to
/// [normalizeSearchText] of their names and avoids recomputing them.
List<MenuItem> searchMenuItems(
  List<MenuItem> items,
  MenuSearchQuery query, {
  Map<String, String>? normalizedNames,
}) {
  final filters = query.filters;
  final keyword = query.normalizedKeyword;
  String nameOf(MenuItem item) =>
      normalizedNames?[item.id] ?? normalizeSearchText(item.name);

  final matches = <_Match>[];
  for (var index = 0; index < items.length; index++) {
    final item = items[index];
    if (filters.categoryId != null && item.categoryId != filters.categoryId) {
      continue;
    }
    if (filters.availableOnly && !item.isAvailable) {
      continue;
    }
    final name = nameOf(item);
    if (keyword.isNotEmpty && !name.contains(keyword)) {
      continue;
    }
    matches.add(_Match(item, name, index));
  }

  final compare = switch (filters.sortOrder) {
    MenuSortOrder.relevance => _byRelevance(keyword),
    MenuSortOrder.priceAsc => _byPrice(ascending: true),
    MenuSortOrder.priceDesc => _byPrice(ascending: false),
    MenuSortOrder.ratingDesc => _byRating,
  };
  matches.sort((a, b) {
    final result = compare(a, b);
    return result != 0 ? result : a.index.compareTo(b.index);
  });
  return [for (final match in matches) match.item];
}

class _Match {
  const _Match(this.item, this.name, this.index);

  final MenuItem item;
  final String name;

  /// Position in the input, which is menu order.
  final int index;
}

typedef _Compare = int Function(_Match a, _Match b);

/// Names starting with the keyword come first; menu order otherwise.
_Compare _byRelevance(String keyword) {
  if (keyword.isEmpty) {
    return (_, _) => 0;
  }
  int rank(_Match match) => match.name.startsWith(keyword) ? 0 : 1;
  return (a, b) => rank(a).compareTo(rank(b));
}

/// Lowest size price, then name.
_Compare _byPrice({required bool ascending}) {
  return (a, b) {
    final byPrice = a.item.priceRange.min.compareTo(b.item.priceRange.min);
    if (byPrice != 0) {
      return ascending ? byPrice : -byPrice;
    }
    return a.name.compareTo(b.name);
  };
}

/// Rated items by average and review count, then name; unrated items last
/// in menu order.
int _byRating(_Match a, _Match b) {
  final aRated = a.item.hasRating;
  final bRated = b.item.hasRating;
  if (aRated != bRated) {
    return aRated ? -1 : 1;
  }
  if (!aRated) {
    return 0;
  }
  final byAverage = b.item.ratingAverage.compareTo(a.item.ratingAverage);
  if (byAverage != 0) {
    return byAverage;
  }
  final byCount = b.item.reviewCount.compareTo(a.item.reviewCount);
  if (byCount != 0) {
    return byCount;
  }
  return a.name.compareTo(b.name);
}
