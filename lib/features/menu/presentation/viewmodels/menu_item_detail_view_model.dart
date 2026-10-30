import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../reviews/domain/entities/review.dart';
import '../../../reviews/presentation/review_providers.dart';
import '../../domain/entities/item_selection.dart';
import '../../domain/entities/menu_failure.dart';
import '../../domain/entities/menu_feed.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/entities/menu_item_feed.dart';
import 'menu_item_detail_state.dart';
import 'menu_providers.dart';

const reviewsFirstPage = 5;
const reviewsPageStep = 10;

/// One ViewModel per opened item; disposed with the screen, so every visit
/// starts from the default selection (FR-016).
final menuItemDetailViewModelProvider = NotifierProvider.autoDispose
    .family<MenuItemDetailViewModel, MenuItemDetailState, String>(
      MenuItemDetailViewModel.new,
    );

/// Combines the item stream, the review stream and the user's selection
/// into one [MenuItemDetailState] (`specs/004-food-details/research.md`
/// R4–R7).
class MenuItemDetailViewModel extends Notifier<MenuItemDetailState> {
  MenuItemDetailViewModel(this.menuItemId);

  final String menuItemId;

  ProviderSubscription<AsyncValue<MenuItemFeed>>? _itemSub;
  ProviderSubscription<AsyncValue<MenuFeed<Review>>>? _reviewsSub;

  AsyncValue<MenuItemFeed> _item = const AsyncLoading();
  AsyncValue<MenuFeed<Review>> _reviews = const AsyncLoading();
  MenuFeed<Review>? _shownReviews;

  ItemSelection? _selection;
  MenuItemDetailNotice? _notice;
  int _reviewLimit = reviewsFirstPage;
  bool _isLoadingMoreReviews = false;
  bool _hadServerItem = false;
  bool _hadServerReviews = false;
  bool _offlineGraceElapsed = false;
  Timer? _offlineTimer;

  @override
  MenuItemDetailState build() {
    ref.onDispose(() {
      _offlineTimer?.cancel();
      _offlineTimer = null;
    });

    _subscribeItem();
    _trackConnectivity();
    return _compose();
  }

  void selectSize(String sizeId) =>
      _updateSelection((selection, item) => selection.withSize(item, sizeId));

  void toggleTopping(String toppingId) => _updateSelection(
    (selection, item) => selection.toggleTopping(item, toppingId),
  );

  void increaseQuantity() => _updateSelection(
    (selection, _) => selection.withQuantity(selection.quantity + 1),
  );

  void decreaseQuantity() => _updateSelection(
    (selection, _) => selection.withQuantity(selection.quantity - 1),
  );

  void updateNote(String note) =>
      _updateSelection((selection, _) => selection.withNote(note));

  /// The cart feature does not exist yet; tell the user and keep the
  /// selection (FR-013).
  void addToCart() {
    if (!state.canOrder) {
      return;
    }
    _notice = MenuItemDetailNotice.addToCartUnavailable;
    _emit();
  }

  void loadMoreReviews() {
    final reviews = state.reviews;
    if (reviews.status != ReviewSectionStatus.ready ||
        !reviews.hasMore ||
        reviews.isLoadingMore) {
      return;
    }
    if (state.isOffline) {
      _notice = MenuItemDetailNotice.reviewsNeedConnection;
      _emit();
      return;
    }
    _reviewLimit += reviewsPageStep;
    _isLoadingMoreReviews = true;
    _subscribeReviews();
    _emit();
  }

  /// Re-subscribes to the item after an error; the selection is rebuilt
  /// from the next item.
  void retry() {
    _hadServerItem = false;
    _resetOffline();
    ref.invalidate(menuItemProvider(menuItemId));
    _subscribeItem();
    _emit();
  }

  void retryReviews() {
    _hadServerReviews = false;
    _isLoadingMoreReviews = false;
    _shownReviews = null;
    _resetOffline();
    ref.invalidate(menuItemReviewsProvider(_reviewsQuery));
    _subscribeReviews();
    _emit();
  }

  void clearNotice() {
    if (_notice == null) {
      return;
    }
    _notice = null;
    _emit();
  }

  MenuItemReviewsQuery get _reviewsQuery =>
      (menuItemId: menuItemId, limit: _reviewLimit);

  void _updateSelection(
    ItemSelection Function(ItemSelection selection, MenuItem item) update,
  ) {
    final selection = _selection;
    final item = state.item;
    if (!state.canOrder || selection == null || item == null) {
      return;
    }
    final next = update(selection, item);
    if (next == selection) {
      return;
    }
    _selection = next;
    _emit();
  }

  void _subscribeItem() {
    _itemSub?.close();
    final sub = ref.listen(menuItemProvider(menuItemId), (_, next) {
      _applyItem(next);
      _emit();
    });
    _itemSub = sub;
    _applyItem(sub.read());
  }

  void _applyItem(AsyncValue<MenuItemFeed> next) {
    _item = next;
    final item = _valueOf(next)?.item;
    if (item == null) {
      return;
    }
    final selection = _selection;
    if (selection == null) {
      _selection = ItemSelection.initial(item);
    } else {
      final result = selection.reconcile(item);
      _selection = result.selection;
      if (result.removedOptions) {
        _notice = MenuItemDetailNotice.optionsRemoved;
      }
    }
    if (_reviewsSub == null) {
      _subscribeReviews();
    }
  }

  void _subscribeReviews() {
    _reviewsSub?.close();
    final sub = ref.listen(menuItemReviewsProvider(_reviewsQuery), (_, next) {
      _applyReviews(next);
      _emit();
    });
    _reviewsSub = sub;
    _applyReviews(sub.read());
  }

  void _applyReviews(AsyncValue<MenuFeed<Review>> next) {
    _reviews = next;
    final feed = _valueOf(next);
    if (feed != null) {
      _shownReviews = feed;
      _isLoadingMoreReviews = false;
    } else if (_errorOf(next) != null) {
      _isLoadingMoreReviews = false;
    }
  }

  void _emit() {
    if (!ref.mounted) {
      return;
    }
    _trackConnectivity();
    state = _compose();
  }

  void _resetOffline() {
    _offlineGraceElapsed = false;
    _offlineTimer?.cancel();
    _offlineTimer = null;
  }

  /// Starts or stops the offline grace timer from the current feeds.
  void _trackConnectivity() {
    final itemFeed = _valueOf(_item);
    final reviewsFeed = _valueOf(_reviews);
    if (itemFeed != null && !itemFeed.isFromCache) {
      _hadServerItem = true;
    }
    if (reviewsFeed != null && !reviewsFeed.isFromCache) {
      _hadServerReviews = true;
    }

    final anyFromCache =
        (itemFeed?.isFromCache ?? false) || (reviewsFeed?.isFromCache ?? false);
    if (!anyFromCache) {
      _resetOffline();
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

  MenuItemDetailState _compose() {
    final error = _errorOf(_item);
    if (error != null) {
      return MenuItemDetailState(
        status: MenuItemDetailStatus.error,
        error: _toFailure(error),
        notice: _notice,
      );
    }

    final feed = _valueOf(_item);
    if (feed == null) {
      return MenuItemDetailState(
        status: MenuItemDetailStatus.loading,
        notice: _notice,
      );
    }

    final isOffline =
        (feed.isFromCache || (_valueOf(_reviews)?.isFromCache ?? false)) &&
        _offlineGraceElapsed;
    final item = feed.item;
    if (item == null) {
      if (feed.isFromCache && !_hadServerItem) {
        // Not cached and no server answer yet: wait for the grace period,
        // then report that the item could not be loaded.
        return MenuItemDetailState(
          status: _offlineGraceElapsed
              ? MenuItemDetailStatus.error
              : MenuItemDetailStatus.loading,
          isOffline: isOffline,
          error: _offlineGraceElapsed
              ? const MenuFailure(MenuFailureType.unavailable)
              : null,
          notice: _notice,
        );
      }
      return MenuItemDetailState(
        status: MenuItemDetailStatus.unavailable,
        notice: _notice,
      );
    }

    return MenuItemDetailState(
      status: MenuItemDetailStatus.ready,
      item: item,
      selection: _selection,
      isOffline: isOffline,
      reviews: _composeReviews(),
      notice: _notice,
    );
  }

  ReviewSectionState _composeReviews() {
    if (_errorOf(_reviews) != null) {
      return ReviewSectionState(status: ReviewSectionStatus.error);
    }
    final shown = _shownReviews;
    if (shown == null) {
      return ReviewSectionState.loading();
    }
    if (shown.items.isEmpty && shown.isFromCache && !_hadServerReviews) {
      return ReviewSectionState(
        status: _offlineGraceElapsed
            ? ReviewSectionStatus.error
            : ReviewSectionStatus.loading,
      );
    }
    return ReviewSectionState(
      status: ReviewSectionStatus.ready,
      reviews: shown.items,
      hasMore: shown.hasMore,
      isLoadingMore: _isLoadingMoreReviews,
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
