import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/features/menu/domain/entities/menu_failure.dart';
import 'package:ordering_food_system/features/menu/domain/entities/menu_option.dart';
import 'package:ordering_food_system/features/menu/presentation/viewmodels/menu_item_detail_state.dart';
import 'package:ordering_food_system/features/menu/presentation/viewmodels/menu_item_detail_view_model.dart';
import 'package:ordering_food_system/features/menu/presentation/viewmodels/menu_providers.dart';
import 'package:ordering_food_system/features/reviews/presentation/review_providers.dart';

import '../../../support/fake_menu_repository.dart';
import '../../../support/fake_review_repository.dart';
import '../../../support/menu_fixtures.dart';

const _grace = Duration(milliseconds: 40);
const _id = 'tra-sua';

const _m = MenuOption(id: 'm', name: 'M', priceDelta: 0);
const _l = MenuOption(id: 'l', name: 'L', priceDelta: 5000);
const _pearl = MenuOption(id: 'pearl', name: 'Trân châu đen', priceDelta: 5000);
const _cheese = MenuOption(id: 'cheese', name: 'Kem cheese', priceDelta: 8000);

final _milkTea = menuItem(
  _id,
  categoryId: 'do-uong',
  name: 'Trà sữa',
  basePrice: 25000,
  sizes: const [_m, _l],
  toppings: const [_pearl, _cheese],
  ratingAverage: 4.7,
  reviewCount: 3,
);

Future<void> _wait(Duration duration) async {
  await Future<void>.delayed(duration);
  await settle();
}

void main() {
  late FakeMenuRepository menus;
  late FakeReviewRepository reviews;
  late ProviderContainer container;
  late ProviderSubscription<MenuItemDetailState> subscription;

  void open() {
    subscription = container.listen(
      menuItemDetailViewModelProvider(_id),
      (_, _) {},
    );
  }

  setUp(() {
    menus = FakeMenuRepository();
    reviews = FakeReviewRepository();
    container = ProviderContainer(
      overrides: [
        menuRepositoryProvider.overrideWithValue(menus),
        reviewRepositoryProvider.overrideWithValue(reviews),
        menuOfflineGraceProvider.overrideWithValue(_grace),
      ],
    );
    addTearDown(container.dispose);
    open();
  });

  MenuItemDetailState state() =>
      container.read(menuItemDetailViewModelProvider(_id));
  MenuItemDetailViewModel viewModel() =>
      container.read(menuItemDetailViewModelProvider(_id).notifier);

  Future<void> emitReady() async {
    menus.emitItem(_id, _milkTea);
    await settle();
  }

  group('User Story 1 - item information', () {
    test('starts loading', () {
      expect(state().status, MenuItemDetailStatus.loading);
    });

    test('an item makes the screen ready', () async {
      await emitReady();

      expect(state().status, MenuItemDetailStatus.ready);
      expect(state().item?.name, 'Trà sữa');
      expect(state().canOrder, isTrue);
    });

    test('a missing item is unavailable', () async {
      menus.emitItem(_id, null);
      await settle();

      expect(state().status, MenuItemDetailStatus.unavailable);
    });

    test('an item removed while open becomes unavailable', () async {
      await emitReady();

      menus.emitItem(_id, null);
      await settle();

      expect(state().status, MenuItemDetailStatus.unavailable);
      expect(state().item, isNull);
    });

    test('errors offer retry', () async {
      menus.emitItemError(_id, const MenuFailure(MenuFailureType.unknown));
      await settle();
      expect(state().status, MenuItemDetailStatus.error);

      viewModel().retry();
      await settle();
      expect(state().status, MenuItemDetailStatus.loading);

      await emitReady();
      expect(state().status, MenuItemDetailStatus.ready);
    });

    test('item changes show without reopening (FR-010)', () async {
      await emitReady();

      menus.emitItem(
        _id,
        menuItem(
          _id,
          name: 'Trà sữa mới',
          basePrice: 27000,
          isAvailable: false,
        ),
      );
      await settle();

      expect(state().item?.name, 'Trà sữa mới');
      expect(state().canOrder, isFalse);
    });

    test('cached data is offline after the grace period', () async {
      menus.emitItem(_id, _milkTea, isFromCache: true);
      await settle();
      expect(state().isOffline, isFalse);

      await _wait(_grace * 2);
      expect(state().isOffline, isTrue);
      expect(state().status, MenuItemDetailStatus.ready);
    });

    test('an uncached item while offline becomes an error', () async {
      menus.emitItem(_id, null, isFromCache: true);
      await settle();
      expect(state().status, MenuItemDetailStatus.loading);

      await _wait(_grace * 2);
      expect(state().status, MenuItemDetailStatus.error);
      expect(state().error?.type, MenuFailureType.unavailable);
    });

    test('reopening starts a fresh ViewModel (FR-016)', () async {
      await emitReady();
      viewModel()
        ..selectSize('l')
        ..increaseQuantity();

      subscription.close();
      await settle();
      open();
      await settle();

      expect(state().selection?.sizeId, 'm');
      expect(state().selection?.quantity, 1);
    });
  });

  group('User Story 2 - options and price', () {
    test('ready starts with the default selection', () async {
      await emitReady();

      expect(state().selection?.sizeId, 'm');
      expect(state().selection?.toppingIds, isEmpty);
      expect(state().unitPrice, 25000);
    });

    test('size and toppings update the price at once', () async {
      await emitReady();

      viewModel()
        ..selectSize('l')
        ..toggleTopping('pearl')
        ..toggleTopping('cheese');

      expect(state().unitPrice, 25000 + 5000 + 5000 + 8000);
      viewModel().toggleTopping('cheese');
      expect(state().unitPrice, 35000);
    });

    test('sold-out items ignore selection changes', () async {
      menus.emitItem(
        _id,
        menuItem(_id, sizes: const [_m, _l], isAvailable: false),
      );
      await settle();

      viewModel()
        ..selectSize('l')
        ..increaseQuantity()
        ..updateNote('ít đá')
        ..addToCart();

      expect(state().selection?.sizeId, 'm');
      expect(state().selection?.quantity, 1);
      expect(state().selection?.note, isEmpty);
      expect(state().notice, isNull);
    });

    test('a removed topping is dropped with a notice (FR-011)', () async {
      await emitReady();
      viewModel()
        ..toggleTopping('cheese')
        ..increaseQuantity();

      menus.emitItem(
        _id,
        menuItem(
          _id,
          basePrice: 25000,
          sizes: const [_m, _l],
          toppings: const [_pearl],
        ),
      );
      await settle();

      expect(state().selection?.toppingIds, isEmpty);
      expect(state().selection?.quantity, 2);
      expect(state().notice, MenuItemDetailNotice.optionsRemoved);

      viewModel().clearNotice();
      expect(state().notice, isNull);
    });

    test('a price change keeps the selection', () async {
      await emitReady();
      viewModel().selectSize('l');

      menus.emitItem(
        _id,
        menuItem(_id, basePrice: 30000, sizes: const [_m, _l]),
      );
      await settle();

      expect(state().selection?.sizeId, 'l');
      expect(state().unitPrice, 35000);
      expect(state().notice, isNull);
    });
  });

  group('User Story 3 - reviews', () {
    test('requests the first page once the item is ready', () async {
      expect(reviews.requests, isEmpty);

      await emitReady();

      expect(reviews.requests, [(menuItemId: _id, limit: reviewsFirstPage)]);
      expect(state().reviews.status, ReviewSectionStatus.loading);
    });

    test('shows reviews newest first as the stream delivers them', () async {
      await emitReady();
      reviews.emitReviews(_id, [review('r2'), review('r1')], hasMore: true);
      await settle();

      expect(state().reviews.status, ReviewSectionStatus.ready);
      expect(state().reviews.reviews.map((r) => r.id), ['r2', 'r1']);
      expect(state().reviews.hasMore, isTrue);

      reviews.emitReviews(_id, [review('r3'), review('r2'), review('r1')]);
      await settle();
      expect(state().reviews.reviews.first.id, 'r3');
    });

    test('load more grows the limit and keeps the list meanwhile', () async {
      await emitReady();
      reviews.emitReviews(_id, [
        for (var i = 0; i < 5; i++) review('r$i'),
      ], hasMore: true);
      await settle();
      reviews.holdReplays = true;

      viewModel().loadMoreReviews();
      await settle();

      expect(reviews.requests.last.limit, reviewsFirstPage + reviewsPageStep);
      expect(state().reviews.isLoadingMore, isTrue);
      expect(state().reviews.reviews, hasLength(5));

      reviews.emitReviews(_id, [for (var i = 0; i < 8; i++) review('r$i')]);
      await settle();
      expect(state().reviews.isLoadingMore, isFalse);
      expect(state().reviews.reviews, hasLength(8));
      expect(state().reviews.hasMore, isFalse);
    });

    test('load more does nothing without more reviews', () async {
      await emitReady();
      reviews.emitReviews(_id, [review('r1')]);
      await settle();

      viewModel().loadMoreReviews();

      expect(reviews.requests, hasLength(1));
    });

    test('a review error leaves the item ready and can be retried', () async {
      await emitReady();
      reviews.emitReviewsError(
        _id,
        const MenuFailure(MenuFailureType.unavailable),
      );
      await settle();

      expect(state().status, MenuItemDetailStatus.ready);
      expect(state().reviews.status, ReviewSectionStatus.error);

      viewModel().retryReviews();
      await settle();
      expect(state().reviews.status, ReviewSectionStatus.loading);

      reviews.emitReviews(_id, [review('r1')]);
      await settle();
      expect(state().reviews.status, ReviewSectionStatus.ready);
    });

    test('offline load more asks for a connection', () async {
      menus.emitItem(_id, _milkTea, isFromCache: true);
      await settle();
      reviews.emitReviews(
        _id,
        [for (var i = 0; i < 5; i++) review('r$i')],
        isFromCache: true,
        hasMore: true,
      );
      await _wait(_grace * 2);
      expect(state().isOffline, isTrue);
      expect(state().reviews.reviews, hasLength(5));

      viewModel().loadMoreReviews();

      expect(reviews.requests, hasLength(1));
      expect(state().notice, MenuItemDetailNotice.reviewsNeedConnection);
    });

    test('uncached reviews while offline become a section error', () async {
      menus.emitItem(_id, _milkTea, isFromCache: true);
      await settle();
      reviews.emitReviews(_id, [], isFromCache: true);
      await settle();
      expect(state().reviews.status, ReviewSectionStatus.loading);

      await _wait(_grace * 2);
      expect(state().reviews.status, ReviewSectionStatus.error);
      expect(state().status, MenuItemDetailStatus.ready);
    });

    test('no reviews are requested for an unavailable item', () async {
      menus.emitItem(_id, null);
      await settle();

      expect(reviews.requests, isEmpty);
    });
  });

  group('User Story 4 - quantity, note and add to cart', () {
    test('quantity stays within 1–99', () async {
      await emitReady();

      viewModel().decreaseQuantity();
      expect(state().selection?.quantity, 1);

      for (var i = 0; i < 120; i++) {
        viewModel().increaseQuantity();
      }
      expect(state().selection?.quantity, 99);
      expect(state().total, 25000 * 99);
    });

    test('note is cut at 200 characters', () async {
      await emitReady();

      viewModel().updateNote('a' * 250);

      expect(state().selection?.note, 'a' * 200);
    });

    test('add to cart reports the feature and keeps the selection', () async {
      await emitReady();
      viewModel()
        ..selectSize('l')
        ..increaseQuantity()
        ..increaseQuantity()
        ..updateNote('ít đá');
      final before = state().selection;

      viewModel().addToCart();

      expect(state().notice, MenuItemDetailNotice.addToCartUnavailable);
      expect(state().selection, before);
      expect(state().total, 30000 * 3);
    });
  });
}
