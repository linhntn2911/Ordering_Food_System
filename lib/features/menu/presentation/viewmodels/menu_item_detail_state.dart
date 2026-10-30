import '../../../reviews/domain/entities/review.dart';
import '../../domain/entities/item_selection.dart';
import '../../domain/entities/menu_failure.dart';
import '../../domain/entities/menu_item.dart';

enum MenuItemDetailStatus { loading, ready, unavailable, error }

enum MenuItemDetailNotice {
  optionsRemoved,
  reviewsNeedConnection,
  addToCartUnavailable,
}

enum ReviewSectionStatus { loading, ready, error }

class ReviewSectionState {
  ReviewSectionState({
    required this.status,
    Iterable<Review> reviews = const [],
    this.hasMore = false,
    this.isLoadingMore = false,
  }) : reviews = List<Review>.unmodifiable(reviews);

  ReviewSectionState.loading() : this(status: ReviewSectionStatus.loading);

  final ReviewSectionStatus status;

  /// Newest first.
  final List<Review> reviews;
  final bool hasMore;
  final bool isLoadingMore;

  bool get isEmpty => status == ReviewSectionStatus.ready && reviews.isEmpty;
}

class MenuItemDetailState {
  MenuItemDetailState({
    required this.status,
    this.item,
    this.selection,
    this.isOffline = false,
    this.error,
    ReviewSectionState? reviews,
    this.notice,
  }) : reviews = reviews ?? ReviewSectionState.loading();

  final MenuItemDetailStatus status;

  /// Set when [status] is ready.
  final MenuItem? item;

  /// Set when [status] is ready.
  final ItemSelection? selection;
  final bool isOffline;
  final MenuFailure? error;
  final ReviewSectionState reviews;
  final MenuItemDetailNotice? notice;

  /// Whether the item can be configured and added to the cart.
  bool get canOrder =>
      status == MenuItemDetailStatus.ready && (item?.isAvailable ?? false);

  int get unitPrice {
    final item = this.item;
    final selection = this.selection;
    return item == null || selection == null ? 0 : selection.unitPrice(item);
  }

  int get total {
    final item = this.item;
    final selection = this.selection;
    return item == null || selection == null ? 0 : selection.total(item);
  }
}
