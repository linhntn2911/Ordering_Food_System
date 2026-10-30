import '../../../../core/utils/search_text.dart';

/// Result orders offered by the search filter sheet.
enum MenuSortOrder {
  relevance('Phù hợp nhất'),
  priceAsc('Giá thấp đến cao'),
  priceDesc('Giá cao đến thấp'),
  ratingDesc('Đánh giá cao');

  const MenuSortOrder(this.label);

  final String label;
}

/// Choices confirmed together with "Áp dụng" in the filter sheet.
class MenuSearchFilters {
  const MenuSearchFilters({
    this.categoryId,
    this.availableOnly = false,
    this.sortOrder = MenuSortOrder.relevance,
  });

  static const defaults = MenuSearchFilters();

  /// `null` means "Tất cả".
  final String? categoryId;
  final bool availableOnly;
  final MenuSortOrder sortOrder;

  bool get isDefault => this == defaults;

  MenuSearchFilters copyWith({
    String? categoryId,
    bool clearCategory = false,
    bool? availableOnly,
    MenuSortOrder? sortOrder,
  }) {
    return MenuSearchFilters(
      categoryId: clearCategory ? null : categoryId ?? this.categoryId,
      availableOnly: availableOnly ?? this.availableOnly,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MenuSearchFilters &&
      other.categoryId == categoryId &&
      other.availableOnly == availableOnly &&
      other.sortOrder == sortOrder;

  @override
  int get hashCode => Object.hash(categoryId, availableOnly, sortOrder);
}

/// The applied keyword and filters of one search session.
class MenuSearchQuery {
  const MenuSearchQuery({
    this.keyword = '',
    this.filters = MenuSearchFilters.defaults,
  });

  /// Keyword as applied after the typing delay, before normalization.
  final String keyword;
  final MenuSearchFilters filters;

  String get normalizedKeyword => normalizeSearchText(keyword);

  /// A keyword of only whitespace counts as empty.
  bool get hasKeyword => normalizedKeyword.isNotEmpty;

  MenuSearchQuery copyWith({String? keyword, MenuSearchFilters? filters}) {
    return MenuSearchQuery(
      keyword: keyword ?? this.keyword,
      filters: filters ?? this.filters,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MenuSearchQuery &&
      other.keyword == keyword &&
      other.filters == filters;

  @override
  int get hashCode => Object.hash(keyword, filters);
}
