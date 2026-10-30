import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/menu_category.dart';
import '../../domain/entities/menu_failure.dart';
import '../../domain/entities/menu_feed.dart';
import '../../domain/entities/menu_item.dart';
import 'home_menu_state.dart';
import 'menu_providers.dart';

const homeMenuPageSize = 20;

final homeMenuViewModelProvider =
    NotifierProvider<HomeMenuViewModel, HomeMenuState>(HomeMenuViewModel.new);

/// Combines the category, item and popular streams into one [HomeMenuState].
///
/// `build` subscribes with `ref.listen` instead of `ref.watch` so selection,
/// page size and offline tracking survive stream updates. Item subscriptions
/// are swapped when the category or page size changes.
class HomeMenuViewModel extends Notifier<HomeMenuState> {
  ProviderSubscription<AsyncValue<MenuFeed<MenuCategory>>>? _categoriesSub;
  ProviderSubscription<AsyncValue<MenuFeed<MenuItem>>>? _itemsSub;
  ProviderSubscription<AsyncValue<MenuFeed<MenuItem>>>? _popularSub;

  AsyncValue<MenuFeed<MenuCategory>> _categories = const AsyncLoading();
  AsyncValue<MenuFeed<MenuItem>> _items = const AsyncLoading();
  AsyncValue<MenuFeed<MenuItem>> _popular = const AsyncLoading();

  String? _selectedCategoryId;
  int _limit = homeMenuPageSize;
  bool _isLoadingMore = false;
  HomeMenuNotice? _notice;
  bool _hadServerSnapshot = false;
  bool _offlineGraceElapsed = false;
  Timer? _offlineTimer;

  @override
  HomeMenuState build() {
    ref.onDispose(() {
      _offlineTimer?.cancel();
      _offlineTimer = null;
    });

    _subscribeCategories();
    _subscribePopular();
    _subscribeItems();
    _trackConnectivity();
    return _compose();
  }

  /// Selects one category, or "Tất cả" when [categoryId] is null.
  void selectCategory(String? categoryId) {
    if (categoryId == _selectedCategoryId) {
      return;
    }
    _selectedCategoryId = categoryId;
    _limit = homeMenuPageSize;
    _isLoadingMore = false;
    _subscribeItems();
    _emit();
  }

  /// Requests the next page of items for the current selection.
  void loadMore() {
    final current = state;
    if (current.status != HomeMenuStatus.data ||
        !current.hasMore ||
        _isLoadingMore) {
      return;
    }
    _limit += homeMenuPageSize;
    _isLoadingMore = true;
    _subscribeItems(keepCurrentWhileLoading: true);
    _emit();
  }

  /// Re-subscribes to every stream after an error.
  void retry() {
    _isLoadingMore = false;
    _limit = homeMenuPageSize;
    _hadServerSnapshot = false;
    _offlineGraceElapsed = false;
    _offlineTimer?.cancel();
    _offlineTimer = null;
    ref.invalidate(menuCategoriesProvider);
    ref.invalidate(popularItemsProvider);
    ref.invalidate(browsableItemsProvider);
    _subscribeCategories();
    _subscribePopular();
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

  void _subscribePopular() {
    _popularSub?.close();
    final sub = ref.listen(popularItemsProvider, (_, next) {
      _popular = next;
      _emit();
    });
    _popularSub = sub;
    _popular = sub.read();
  }

  /// Listens to the item query for the current selection and page size.
  ///
  /// With [keepCurrentWhileLoading] the items already on screen stay visible
  /// until the new query delivers data (used for load more and its fallback).
  void _subscribeItems({bool keepCurrentWhileLoading = false}) {
    _itemsSub?.close();
    final query = (categoryId: _selectedCategoryId, limit: _limit);
    final sub = ref.listen(browsableItemsProvider(query), (_, next) {
      _applyItems(next, keepCurrentWhileLoading: keepCurrentWhileLoading);
      _emit();
    });
    _itemsSub = sub;
    _applyItems(sub.read(), keepCurrentWhileLoading: keepCurrentWhileLoading);
  }

  void _applyItems(
    AsyncValue<MenuFeed<MenuItem>> next, {
    required bool keepCurrentWhileLoading,
  }) {
    final hasCurrent = _valueOf(_items) != null;
    if (next is AsyncLoading && keepCurrentWhileLoading && hasCurrent) {
      return;
    }
    if (next is AsyncError && _isLoadingMore && hasCurrent) {
      // Keep the loaded page and fall back to the previous page size.
      _isLoadingMore = false;
      _notice = HomeMenuNotice.loadMoreFailed;
      _limit -= homeMenuPageSize;
      _subscribeItems(keepCurrentWhileLoading: true);
      return;
    }
    if (next is! AsyncLoading) {
      _isLoadingMore = false;
    }
    _items = next;
  }

  /// Resets the selection when the selected category is no longer published.
  void _handleCategoriesChanged() {
    final selected = _selectedCategoryId;
    final categories = _valueOf(_categories);
    if (selected == null || categories == null) {
      return;
    }
    final stillVisible = categories.items.any((c) => c.id == selected);
    if (!stillVisible) {
      _selectedCategoryId = null;
      _limit = homeMenuPageSize;
      _isLoadingMore = false;
      _notice = HomeMenuNotice.categoryRemoved;
      _subscribeItems();
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
      ?_valueOf(_popular),
    ];
    if (feeds.any((feed) => !feed.isFromCache)) {
      _hadServerSnapshot = true;
    }

    final anyFromCache = feeds.any((feed) => feed.isFromCache);
    if (!anyFromCache) {
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

  HomeMenuState _compose() {
    final error = _errorOf(_categories) ?? _errorOf(_items);
    if (error != null) {
      return HomeMenuState(
        status: HomeMenuStatus.error,
        selectedCategoryId: _selectedCategoryId,
        error: _toFailure(error),
        notice: _notice,
      );
    }

    final categoriesFeed = _valueOf(_categories);
    final itemsFeed = _valueOf(_items);
    if (categoriesFeed == null || itemsFeed == null) {
      return HomeMenuState(
        status: HomeMenuStatus.loading,
        selectedCategoryId: _selectedCategoryId,
        notice: _notice,
      );
    }

    final categories = categoriesFeed.items;
    final categoryNames = {for (final c in categories) c.id: c.name};
    final visibleItems = itemsFeed.items
        .where((item) => categoryNames.containsKey(item.categoryId))
        .toList();
    final popularFeed = _valueOf(_popular);
    final popular = (popularFeed?.items ?? const <MenuItem>[]).where(
      (item) => categoryNames.containsKey(item.categoryId),
    );

    final isFromCache = categoriesFeed.isFromCache || itemsFeed.isFromCache;
    final isOffline = isFromCache && _offlineGraceElapsed;
    final nothingToShow =
        categories.isEmpty ||
        (_selectedCategoryId == null && visibleItems.isEmpty);

    if (nothingToShow && isFromCache && !_hadServerSnapshot) {
      // Empty cache and no server answer yet: wait for the grace period, then
      // report that the menu could not be loaded instead of "empty".
      return HomeMenuState(
        status: _offlineGraceElapsed
            ? HomeMenuStatus.error
            : HomeMenuStatus.loading,
        selectedCategoryId: _selectedCategoryId,
        isOffline: isOffline,
        error: _offlineGraceElapsed
            ? const MenuFailure(MenuFailureType.unavailable)
            : null,
        notice: _notice,
      );
    }

    if (nothingToShow) {
      return HomeMenuState(
        status: HomeMenuStatus.empty,
        categories: categories,
        selectedCategoryId: _selectedCategoryId,
        isOffline: isOffline,
        notice: _notice,
      );
    }

    final selected = _selectedCategoryId;
    final sections = selected == null
        ? _groupByCategory(visibleItems, categoryNames)
        : [
            MenuSection(
              categoryId: selected,
              title: categoryNames[selected] ?? '',
              items: visibleItems,
            ),
          ];

    return HomeMenuState(
      status: HomeMenuStatus.data,
      categories: categories,
      selectedCategoryId: selected,
      sections: sections,
      popular: popular,
      isOffline: isOffline,
      hasMore: itemsFeed.hasMore,
      isLoadingMore: _isLoadingMore,
      notice: _notice,
    );
  }

  /// Groups consecutive items of the same category. The query already orders
  /// items by category, so groups follow category order.
  static List<MenuSection> _groupByCategory(
    List<MenuItem> items,
    Map<String, String> categoryNames,
  ) {
    final sections = <MenuSection>[];
    var start = 0;
    for (var i = 1; i <= items.length; i++) {
      final boundary =
          i == items.length || items[i].categoryId != items[start].categoryId;
      if (boundary) {
        final categoryId = items[start].categoryId;
        sections.add(
          MenuSection(
            categoryId: categoryId,
            title: categoryNames[categoryId] ?? '',
            items: items.sublist(start, i),
          ),
        );
        start = i;
      }
    }
    return sections;
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
