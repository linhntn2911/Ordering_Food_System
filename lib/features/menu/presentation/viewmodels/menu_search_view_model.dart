import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/search_text.dart';
import '../../domain/entities/menu_category.dart';
import '../../domain/entities/menu_failure.dart';
import '../../domain/entities/menu_feed.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/entities/menu_search_query.dart';
import '../../domain/services/menu_search.dart';
import 'menu_providers.dart';
import 'menu_search_state.dart';

/// Disposed when the search screen closes, so every visit starts from the
/// default query (FR-015).
final menuSearchViewModelProvider =
    NotifierProvider.autoDispose<MenuSearchViewModel, MenuSearchState>(
      MenuSearchViewModel.new,
    );

/// Applies the keyword, filters and sort order to the searchable items
/// stream (`specs/003-menu-search/research.md` R3–R7).
///
/// Changing the query never opens another stream; results are recomputed
/// from the items already received.
class MenuSearchViewModel extends Notifier<MenuSearchState> {
  ProviderSubscription<AsyncValue<MenuFeed<MenuCategory>>>? _categoriesSub;
  ProviderSubscription<AsyncValue<MenuFeed<MenuItem>>>? _itemsSub;

  AsyncValue<MenuFeed<MenuCategory>> _categories = const AsyncLoading();
  AsyncValue<MenuFeed<MenuItem>> _items = const AsyncLoading();
  Map<String, String> _normalizedNames = const {};

  MenuSearchQuery _query = const MenuSearchQuery();
  MenuSearchNotice? _notice;
  Timer? _keywordTimer;
  bool _hadServerSnapshot = false;
  bool _offlineGraceElapsed = false;
  Timer? _offlineTimer;

  @override
  MenuSearchState build() {
    ref.onDispose(() {
      _keywordTimer?.cancel();
      _keywordTimer = null;
      _offlineTimer?.cancel();
      _offlineTimer = null;
    });

    _subscribeCategories();
    _subscribeItems();
    _trackConnectivity();
    return _compose();
  }

  /// Applies [keyword] once typing pauses for `menuSearchDebounceProvider`.
  void updateKeyword(String keyword) {
    _keywordTimer?.cancel();
    _keywordTimer = Timer(ref.read(menuSearchDebounceProvider), () {
      _keywordTimer = null;
      _setKeyword(keyword);
    });
  }

  /// Applies [keyword] immediately, for the keyboard search action.
  void submitKeyword(String keyword) {
    _keywordTimer?.cancel();
    _keywordTimer = null;
    _setKeyword(keyword);
  }

  void clearKeyword() => submitKeyword('');

  /// Replaces every filter at once ("Áp dụng" in the filter sheet).
  void applyFilters(MenuSearchFilters filters) => _setFilters(filters);

  void removeCategoryFilter() =>
      _setFilters(_query.filters.copyWith(clearCategory: true));

  void removeAvailableFilter() =>
      _setFilters(_query.filters.copyWith(availableOnly: false));

  void removeSortOrder() =>
      _setFilters(_query.filters.copyWith(sortOrder: MenuSortOrder.relevance));

  /// Resets filters and sort order but keeps the keyword.
  void clearFilters() => _setFilters(MenuSearchFilters.defaults);

  /// Re-subscribes after an error; the query is kept.
  void retry() {
    _hadServerSnapshot = false;
    _offlineGraceElapsed = false;
    _offlineTimer?.cancel();
    _offlineTimer = null;
    ref.invalidate(menuCategoriesProvider);
    ref.invalidate(searchableItemsProvider);
    _subscribeCategories();
    _subscribeItems();
    _emit();
  }

  void clearNotice() {
    if (_notice == null) {
      return;
    }
    _notice = null;
    _emit();
  }

  void _setKeyword(String keyword) {
    final limited = limitSearchKeyword(keyword);
    if (limited == _query.keyword) {
      return;
    }
    _query = _query.copyWith(keyword: limited);
    _emit();
  }

  void _setFilters(MenuSearchFilters filters) {
    if (filters == _query.filters) {
      return;
    }
    _query = _query.copyWith(filters: filters);
    _emit();
  }

  void _subscribeCategories() {
    _categoriesSub?.close();
    final sub = ref.listen(menuCategoriesProvider, (_, next) {
      _categories = next;
      _handleCategoriesChanged();
      _emit();
    });
    _categoriesSub = sub;
    _categories = sub.read();
  }

  void _subscribeItems() {
    _itemsSub?.close();
    final sub = ref.listen(searchableItemsProvider, (_, next) {
      _applyItems(next);
      _emit();
    });
    _itemsSub = sub;
    _applyItems(sub.read());
  }

  void _applyItems(AsyncValue<MenuFeed<MenuItem>> next) {
    _items = next;
    final feed = _valueOf(next);
    if (feed != null) {
      _normalizedNames = {
        for (final item in feed.items) item.id: normalizeSearchText(item.name),
      };
    }
  }

  /// Drops the category filter when that category is no longer published.
  ///
  /// Only server data counts, so a stale cache cannot clear the filter.
  void _handleCategoriesChanged() {
    final selected = _query.filters.categoryId;
    final feed = _valueOf(_categories);
    if (selected == null || feed == null || feed.isFromCache) {
      return;
    }
    if (!feed.items.any((category) => category.id == selected)) {
      _query = _query.copyWith(
        filters: _query.filters.copyWith(clearCategory: true),
      );
      _notice = MenuSearchNotice.categoryRemoved;
    }
  }

  void _emit() {
    if (!ref.mounted) {
      return;
    }
    _trackConnectivity();
    state = _compose();
  }

  /// Starts or stops the offline grace timer from the current feeds.
  void _trackConnectivity() {
    final feeds = <MenuFeed<Object?>>[
      ?_valueOf(_categories),
      ?_valueOf(_items),
    ];
    if (feeds.any((feed) => !feed.isFromCache)) {
      _hadServerSnapshot = true;
    }

    if (!feeds.any((feed) => feed.isFromCache)) {
      _offlineTimer?.cancel();
      _offlineTimer = null;
      _offlineGraceElapsed = false;
      return;
    }
    if (_offlineGraceElapsed || _offlineTimer != null) {
      return;
    }
    _offlineTimer = Timer(ref.read(menuOfflineGraceProvider), () {
      _offlineTimer = null;
      _offlineGraceElapsed = true;
      if (ref.mounted) {
        state = _compose();
      }
    });
  }

  MenuSearchState _compose() {
    final error = _errorOf(_categories) ?? _errorOf(_items);
    if (error != null) {
      return MenuSearchState(
        query: _query,
        status: MenuSearchStatus.error,
        error: _toFailure(error),
        notice: _notice,
      );
    }

    final categoriesFeed = _valueOf(_categories);
    final itemsFeed = _valueOf(_items);
    if (categoriesFeed == null || itemsFeed == null) {
      return MenuSearchState(
        query: _query,
        status: MenuSearchStatus.loading,
        notice: _notice,
      );
    }

    final isFromCache = categoriesFeed.isFromCache || itemsFeed.isFromCache;
    final isOffline = isFromCache && _offlineGraceElapsed;
    if (itemsFeed.items.isEmpty && isFromCache && !_hadServerSnapshot) {
      // Nothing cached and no server answer yet: wait for the grace period,
      // then report that the menu could not be loaded.
      return MenuSearchState(
        query: _query,
        status: _offlineGraceElapsed
            ? MenuSearchStatus.error
            : MenuSearchStatus.loading,
        isOffline: isOffline,
        error: _offlineGraceElapsed
            ? const MenuFailure(MenuFailureType.unavailable)
            : null,
        notice: _notice,
      );
    }

    final categories = categoriesFeed.items;
    final publishedIds = {for (final category in categories) category.id};
    final visibleItems = itemsFeed.items
        .where((item) => publishedIds.contains(item.categoryId))
        .toList();

    return MenuSearchState(
      query: _query,
      status: MenuSearchStatus.ready,
      results: searchMenuItems(
        visibleItems,
        _query,
        normalizedNames: _normalizedNames,
      ),
      categories: categories,
      isOffline: isOffline,
      notice: _notice,
    );
  }

  static T? _valueOf<T>(AsyncValue<T> asyncValue) {
    return switch (asyncValue) {
      AsyncData(:final value) => value,
      _ => null,
    };
  }

  /// An error being refreshed (after retry) counts as loading, not error.
  static Object? _errorOf(AsyncValue<Object?> asyncValue) {
    return switch (asyncValue) {
      AsyncError(:final error, isLoading: false) => error,
      _ => null,
    };
  }

  static MenuFailure _toFailure(Object error) {
    return error is MenuFailure
        ? error
        : MenuFailure(MenuFailureType.unknown, error);
  }
}
