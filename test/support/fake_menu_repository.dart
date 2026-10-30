import 'dart:async';

import 'package:ordering_food_system/features/menu/domain/entities/menu_category.dart';
import 'package:ordering_food_system/features/menu/domain/entities/menu_feed.dart';
import 'package:ordering_food_system/features/menu/domain/entities/menu_item.dart';
import 'package:ordering_food_system/features/menu/domain/entities/menu_item_feed.dart';
import 'package:ordering_food_system/features/menu/domain/repositories/menu_repository.dart';

typedef ItemsRequest = ({String? categoryId, int limit});

/// In-memory [MenuRepository] driven by explicit `emit*` calls.
///
/// Each stream replays its latest event to new listeners so providers that
/// re-subscribe (for example after a limit change) receive current data.
class FakeMenuRepository implements MenuRepository {
  final categoryRequests = <int>[];
  final itemRequests = <ItemsRequest>[];
  final popularRequests = <int>[];
  final itemIdRequests = <String>[];
  final searchRequests = <int>[];

  final _categories = _ReplayChannel<MenuFeed<MenuCategory>>();
  final _items = <String?, _ReplayChannel<MenuFeed<MenuItem>>>{};
  final _popular = _ReplayChannel<MenuFeed<MenuItem>>();
  final _searchable = _ReplayChannel<MenuFeed<MenuItem>>();
  final _singleItems = <String, _ReplayChannel<MenuItemFeed>>{};

  /// When true, item streams wait for an explicit emit after a new request
  /// instead of replaying the last event. Used to observe load-more states.
  bool holdItemReplays = false;

  @override
  Stream<MenuFeed<MenuCategory>> watchPublishedCategories({int limit = 50}) {
    categoryRequests.add(limit);
    return _categories.stream();
  }

  @override
  Stream<MenuFeed<MenuItem>> watchBrowsableItems({
    String? categoryId,
    required int limit,
  }) {
    itemRequests.add((categoryId: categoryId, limit: limit));
    return _itemsChannel(categoryId).stream(replay: !holdItemReplays);
  }

  @override
  Stream<MenuFeed<MenuItem>> watchSearchableItems({int limit = 300}) {
    searchRequests.add(limit);
    return _searchable.stream();
  }

  @override
  Stream<MenuFeed<MenuItem>> watchPopularItems({int limit = 5}) {
    popularRequests.add(limit);
    return _popular.stream();
  }

  @override
  Stream<MenuItemFeed> watchItem(String menuItemId) {
    itemIdRequests.add(menuItemId);
    return _singleItems.putIfAbsent(menuItemId, _ReplayChannel.new).stream();
  }

  void emitCategories(
    List<MenuCategory> categories, {
    bool isFromCache = false,
  }) {
    _categories.add(
      MenuFeed(items: categories, isFromCache: isFromCache, hasMore: false),
    );
  }

  void emitItems(
    List<MenuItem> items, {
    String? categoryId,
    bool isFromCache = false,
    bool hasMore = false,
  }) {
    _itemsChannel(
      categoryId,
    ).add(MenuFeed(items: items, isFromCache: isFromCache, hasMore: hasMore));
  }

  void emitPopular(List<MenuItem> items, {bool isFromCache = false}) {
    _popular.add(
      MenuFeed(items: items, isFromCache: isFromCache, hasMore: false),
    );
  }

  void emitSearchableItems(List<MenuItem> items, {bool isFromCache = false}) {
    _searchable.add(
      MenuFeed(items: items, isFromCache: isFromCache, hasMore: false),
    );
  }

  void emitSearchableError(Object error) => _searchable.addError(error);

  void emitItem(String menuItemId, MenuItem? item, {bool isFromCache = false}) {
    _singleItems
        .putIfAbsent(menuItemId, _ReplayChannel.new)
        .add(MenuItemFeed(item: item, isFromCache: isFromCache));
  }

  void emitItemError(String menuItemId, Object error) =>
      _singleItems.putIfAbsent(menuItemId, _ReplayChannel.new).addError(error);

  void emitCategoriesError(Object error) => _categories.addError(error);

  void emitItemsError(Object error, {String? categoryId}) =>
      _itemsChannel(categoryId).addError(error);

  _ReplayChannel<MenuFeed<MenuItem>> _itemsChannel(String? categoryId) =>
      _items.putIfAbsent(categoryId, _ReplayChannel.new);
}

/// Broadcasts events and replays the latest value (not errors) to new
/// listeners, so a retry after an error waits for the next emit.
class _ReplayChannel<T> {
  final _controller = StreamController<T>.broadcast();
  bool _hasLatest = false;
  T? _latest;

  Stream<T> stream({bool replay = true}) async* {
    if (replay && _hasLatest) {
      yield _latest as T;
    }
    yield* _controller.stream;
  }

  void add(T value) {
    _hasLatest = true;
    _latest = value;
    _controller.add(value);
  }

  void addError(Object error) {
    _hasLatest = false;
    _latest = null;
    _controller.addError(error);
  }
}
