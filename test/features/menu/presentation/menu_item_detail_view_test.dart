import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/core/theme/app_theme.dart';
import 'package:ordering_food_system/core/utils/vnd_format.dart';
import 'package:ordering_food_system/core/widgets/app_error_view.dart';
import 'package:ordering_food_system/core/widgets/offline_banner.dart';
import 'package:ordering_food_system/core/widgets/rating_stars.dart';
import 'package:ordering_food_system/features/menu/domain/entities/menu_failure.dart';
import 'package:ordering_food_system/features/menu/domain/entities/menu_item.dart';
import 'package:ordering_food_system/features/menu/domain/entities/menu_option.dart';
import 'package:ordering_food_system/features/menu/presentation/viewmodels/menu_providers.dart';
import 'package:ordering_food_system/features/menu/presentation/views/menu_item_detail_view.dart';
import 'package:ordering_food_system/features/reviews/presentation/review_providers.dart';

import '../../../support/fake_menu_repository.dart';
import '../../../support/fake_review_repository.dart';
import '../../../support/menu_fixtures.dart';

const _grace = Duration(milliseconds: 20);
const _id = 'tra-dao';

const _m = MenuOption(id: 'm', name: 'M', priceDelta: 0);
const _l = MenuOption(id: 'l', name: 'L', priceDelta: 5000);
const _pearl = MenuOption(id: 'pearl', name: 'Trân châu đen', priceDelta: 5000);

final _peachTea = menuItem(
  _id,
  categoryId: 'do-uong',
  name: 'Trà đào',
  basePrice: 20000,
  sizes: const [_m, _l],
  toppings: const [_pearl],
  description: 'Trà đào cam sả pha tươi trong ngày.',
  ratingAverage: 4.9,
  reviewCount: 210,
);

void main() {
  late FakeMenuRepository menus;
  late FakeReviewRepository reviews;

  setUp(() {
    menus = FakeMenuRepository();
    reviews = FakeReviewRepository();
  });

  Future<void> pumpDetail(
    WidgetTester tester, {
    Size size = const Size(390, 2400),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          menuRepositoryProvider.overrideWithValue(menus),
          reviewRepositoryProvider.overrideWithValue(reviews),
          menuOfflineGraceProvider.overrideWithValue(_grace),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MenuItemDetailView(menuItemId: _id),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> showItem(WidgetTester tester, [MenuItem? item]) async {
    menus.emitItem(_id, item ?? _peachTea);
    await tester.pump();
    await tester.pump();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey(key));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  String addLabel(WidgetTester tester) {
    final button = find.byKey(const ValueKey('detail-add-to-cart'));
    return tester
        .widgetList<Text>(
          find.descendant(of: button, matching: find.byType(Text)),
        )
        .first
        .data!;
  }

  group('User Story 1', () {
    testWidgets('shows a skeleton while loading', (tester) async {
      await pumpDetail(tester);

      expect(find.bySemanticsLabel('Đang tải thông tin món'), findsOneWidget);
    });

    testWidgets('shows image placeholder, name, rating, price, description', (
      tester,
    ) async {
      await pumpDetail(tester);
      await showItem(tester);

      expect(find.text('Trà đào'), findsOneWidget);
      expect(find.byType(RatingStars), findsOneWidget);
      expect(find.text('4,9 (210 đánh giá)'), findsOneWidget);
      expect(find.text(formatVndRange(20000, 25000)), findsOneWidget);
      expect(find.text('Trà đào cam sả pha tươi trong ngày.'), findsOneWidget);
      expect(find.text('Hết hàng'), findsNothing);
    });

    testWidgets('unrated items say "Chưa có đánh giá"', (tester) async {
      await pumpDetail(tester);
      await showItem(tester, menuItem(_id, name: 'Trà đào', basePrice: 20000));

      expect(find.text('Chưa có đánh giá'), findsOneWidget);
      expect(find.byKey(const ValueKey('detail-rating')), findsOneWidget);
    });

    testWidgets('sizes with equal prices show a single price', (tester) async {
      await pumpDetail(tester);
      await showItem(
        tester,
        menuItem(
          _id,
          basePrice: 20000,
          sizes: const [
            _m,
            MenuOption(id: 'l', name: 'L', priceDelta: 0),
          ],
        ),
      );

      expect(find.text(formatVnd(20000)), findsOneWidget);
    });

    testWidgets('long descriptions fold with "Xem thêm"', (tester) async {
      await pumpDetail(tester);
      await showItem(
        tester,
        menuItem(_id, description: 'Trà đào thơm mát. ' * 60),
      );

      expect(
        find.byKey(const ValueKey('detail-description-toggle')),
        findsOneWidget,
      );
      await tapKey(tester, 'detail-description-toggle');
      expect(find.text('Thu gọn'), findsOneWidget);
    });

    testWidgets('empty descriptions are hidden', (tester) async {
      await pumpDetail(tester);
      await showItem(tester, menuItem(_id, name: 'Trà đào'));

      expect(
        find.byKey(const ValueKey('detail-description-toggle')),
        findsNothing,
      );
    });

    testWidgets('sold-out items show the label and a disabled button', (
      tester,
    ) async {
      await pumpDetail(tester);
      await showItem(
        tester,
        menuItem(
          _id,
          name: 'Trà đào',
          sizes: const [_m, _l],
          isAvailable: false,
        ),
      );

      expect(find.text('Hết hàng – chưa thể thêm vào giỏ'), findsOneWidget);
      expect(addLabel(tester), 'Hết hàng');
      expect(find.byKey(const ValueKey('detail-quantity')), findsNothing);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('detail-note')))
            .enabled,
        isFalse,
      );
    });

    testWidgets('an unavailable item offers to go back', (tester) async {
      await pumpDetail(tester);
      menus.emitItem(_id, null);
      await tester.pump();
      await tester.pump();

      expect(find.text('Món này không còn được bán'), findsOneWidget);
      await tester.tap(find.text('Quay lại'));
      await tester.pumpAndSettle();
      expect(find.byType(MenuItemDetailView), findsNothing);
    });

    testWidgets('an item removed while open becomes unavailable', (
      tester,
    ) async {
      await pumpDetail(tester);
      await showItem(tester);

      menus.emitItem(_id, null);
      await tester.pump();
      await tester.pump();

      expect(find.text('Món này không còn được bán'), findsOneWidget);
    });

    testWidgets('errors offer retry', (tester) async {
      await pumpDetail(tester);
      menus.emitItemError(_id, const MenuFailure(MenuFailureType.unknown));
      await tester.pump();
      await tester.pump();

      expect(find.byType(AppErrorView), findsOneWidget);
      await tester.tap(find.text('Thử lại'));
      await tester.pump();
      await showItem(tester);
      expect(find.text('Trà đào'), findsOneWidget);
    });

    testWidgets('cached data shows the offline banner', (tester) async {
      await pumpDetail(tester);
      menus.emitItem(_id, _peachTea, isFromCache: true);
      await tester.pump();
      await tester.pump(_grace * 2);
      await tester.pump();

      expect(find.byType(OfflineBanner), findsOneWidget);
    });

    testWidgets('the back button closes the screen', (tester) async {
      await pumpDetail(tester);
      await showItem(tester);

      await tester.tap(find.byKey(const ValueKey('detail-back')));
      await tester.pumpAndSettle();

      expect(find.byType(MenuItemDetailView), findsNothing);
    });
  });

  group('User Story 2', () {
    testWidgets('lists sizes and toppings with extra prices', (tester) async {
      await pumpDetail(tester);
      await showItem(tester);

      expect(find.text('Chọn size'), findsOneWidget);
      expect(find.text('Topping'), findsOneWidget);
      expect(find.text('+${formatVnd(5000)}'), findsNWidgets(2));
      expect(
        tester.getSemantics(find.byKey(const ValueKey('detail-size-m'))),
        isSemantics(isSelected: true),
      );
      expect(addLabel(tester), 'Thêm vào giỏ · ${formatVnd(20000)}');
    });

    testWidgets('choosing L and a topping updates the price', (tester) async {
      await pumpDetail(tester);
      await showItem(tester);

      await tapKey(tester, 'detail-size-l');
      expect(addLabel(tester), 'Thêm vào giỏ · ${formatVnd(25000)}');

      await tapKey(tester, 'detail-topping-pearl');
      expect(addLabel(tester), 'Thêm vào giỏ · ${formatVnd(30000)}');

      await tapKey(tester, 'detail-topping-pearl');
      expect(addLabel(tester), 'Thêm vào giỏ · ${formatVnd(25000)}');
    });

    testWidgets('items without options have no option section', (tester) async {
      await pumpDetail(tester);
      await showItem(tester, menuItem(_id, name: 'Trà đào'));

      expect(find.text('Chọn size'), findsNothing);
      expect(find.text('Topping'), findsNothing);
    });

    testWidgets('sold-out options cannot be chosen', (tester) async {
      await pumpDetail(tester);
      await showItem(
        tester,
        menuItem(_id, sizes: const [_m, _l], isAvailable: false),
      );

      await tapKey(tester, 'detail-size-l');

      expect(
        tester.getSemantics(find.byKey(const ValueKey('detail-size-l'))),
        isSemantics(isSelected: false),
      );
      expect(find.bySemanticsLabel(RegExp('không khả dụng')), findsNWidgets(2));
    });

    testWidgets('a removed topping shows a snackbar', (tester) async {
      await pumpDetail(tester);
      await showItem(tester);
      await tapKey(tester, 'detail-topping-pearl');

      menus.emitItem(
        _id,
        menuItem(_id, basePrice: 20000, sizes: const [_m, _l]),
      );
      await tester.pump();
      await tester.pump();

      expect(
        find.text('Một số tùy chọn đã thay đổi, vui lòng chọn lại'),
        findsOneWidget,
      );
      expect(addLabel(tester), 'Thêm vào giỏ · ${formatVnd(20000)}');
    });
  });

  group('User Story 3', () {
    testWidgets('shows "Chưa có đánh giá cho món này"', (tester) async {
      await pumpDetail(tester);
      await showItem(tester);
      reviews.emitReviews(_id, []);
      await tester.pump();
      await tester.pump();

      expect(find.text('Chưa có đánh giá cho món này'), findsOneWidget);
    });

    testWidgets('review cards show author label, date and edited state', (
      tester,
    ) async {
      await pumpDetail(tester);
      await showItem(tester);
      reviews.emitReviews(_id, [
        review(
          'r1',
          rating: 4,
          comment: 'Thơm vị đào',
          isEdited: true,
          createdAt: DateTime(2026, 10, 18),
        ),
        review('r2', isAnonymous: true, createdAt: DateTime(2026, 10, 9)),
      ]);
      await tester.pump();
      await tester.pump();

      expect(find.text('Khách hàng'), findsOneWidget);
      expect(find.text('Khách hàng ẩn danh'), findsOneWidget);
      expect(find.text('18/10/2026'), findsOneWidget);
      expect(find.text('09/10/2026'), findsOneWidget);
      expect(find.text('Đã chỉnh sửa'), findsOneWidget);
      expect(find.text('Thơm vị đào'), findsOneWidget);
      expect(find.bySemanticsLabel('Đánh giá 4,0 trên 5'), findsOneWidget);
      // SC-003: no identifier of any kind is rendered.
      expect(find.textContaining('customer'), findsNothing);
      expect(find.textContaining('order'), findsNothing);
    });

    testWidgets('long comments fold to four lines', (tester) async {
      await pumpDetail(tester);
      await showItem(tester);
      reviews.emitReviews(_id, [review('r1', comment: 'Rất ngon. ' * 80)]);
      await tester.pump();
      await tester.pump();

      final card = find.byKey(const ValueKey('review-r1'));
      expect(
        find.descendant(of: card, matching: find.text('Xem thêm')),
        findsOneWidget,
      );
    });

    testWidgets('"Xem thêm đánh giá" loads more and disappears at the end', (
      tester,
    ) async {
      await pumpDetail(tester);
      await showItem(tester);
      reviews.emitReviews(_id, [
        for (var i = 0; i < 5; i++) review('r$i'),
      ], hasMore: true);
      await tester.pump();
      await tester.pump();

      await tapKey(tester, 'detail-more-reviews');
      expect(reviews.requests.last.limit, 15);

      reviews.emitReviews(_id, [for (var i = 0; i < 7; i++) review('r$i')]);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('review-r6')), findsOneWidget);
      expect(find.byKey(const ValueKey('detail-more-reviews')), findsNothing);
    });

    testWidgets('a review error keeps the item and offers retry', (
      tester,
    ) async {
      await pumpDetail(tester);
      await showItem(tester);
      reviews.emitReviewsError(
        _id,
        const MenuFailure(MenuFailureType.unavailable),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Trà đào'), findsOneWidget);
      expect(find.text('Không tải được đánh giá.'), findsOneWidget);

      await tapKey(tester, 'detail-reviews-retry');
      reviews.emitReviews(_id, [review('r1')]);
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const ValueKey('review-r1')), findsOneWidget);
    });

    testWidgets('images open a viewer that swipes and closes', (tester) async {
      await pumpDetail(tester);
      await showItem(tester);
      reviews.emitReviews(_id, [
        review('r1', imageUrls: const ['a.jpg', 'b.jpg']),
      ]);
      await tester.pump();
      await tester.pump();

      await tapKey(tester, 'review-r1-image-0');
      expect(find.text('1/2'), findsOneWidget);

      await tester.drag(
        find.byKey(const ValueKey('review-image-pages')),
        const Offset(-300, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('2/2'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('review-image-close')));
      await tester.pumpAndSettle();
      expect(find.text('2/2'), findsNothing);
      expect(find.byType(MenuItemDetailView), findsOneWidget);
    });

    testWidgets('offline load more asks for a connection', (tester) async {
      await pumpDetail(tester);
      menus.emitItem(_id, _peachTea, isFromCache: true);
      await tester.pump();
      reviews.emitReviews(
        _id,
        [for (var i = 0; i < 5; i++) review('r$i')],
        isFromCache: true,
        hasMore: true,
      );
      await tester.pump();
      await tester.pump(_grace * 2);
      await tester.pump();

      await tapKey(tester, 'detail-more-reviews');

      expect(
        find.text('Cần kết nối mạng để tải thêm đánh giá'),
        findsOneWidget,
      );
      expect(reviews.requests, hasLength(1));
    });
  });

  group('User Story 4', () {
    testWidgets('quantity stepper and total (Trà đào L × 3)', (tester) async {
      await pumpDetail(tester);
      await showItem(tester);

      final minus = tester.widget<InkWell>(
        find.descendant(
          of: find.byKey(const ValueKey('detail-quantity-minus')),
          matching: find.byType(InkWell),
        ),
      );
      expect(minus.onTap, isNull);

      await tapKey(tester, 'detail-size-l');
      await tapKey(tester, 'detail-quantity-plus');
      await tapKey(tester, 'detail-quantity-plus');

      expect(find.text('3'), findsOneWidget);
      expect(addLabel(tester), 'Thêm vào giỏ · ${formatVnd(75000)}');
    });

    testWidgets('the note stops at 200 characters', (tester) async {
      await pumpDetail(tester);
      await showItem(tester);

      await tester.enterText(
        find.byKey(const ValueKey('detail-note')),
        'a' * 250,
      );
      await tester.pump();

      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('detail-note')),
      );
      expect(field.controller?.text.length, 200);
      expect(find.text('200/200'), findsOneWidget);
    });

    testWidgets('add to cart reports the feature and keeps choices', (
      tester,
    ) async {
      await pumpDetail(tester);
      await showItem(tester);
      await tapKey(tester, 'detail-size-l');
      await tester.enterText(
        find.byKey(const ValueKey('detail-note')),
        'ít đá',
      );

      await tapKey(tester, 'detail-add-to-cart');

      expect(find.text('Tính năng đang được phát triển'), findsOneWidget);
      expect(addLabel(tester), 'Thêm vào giỏ · ${formatVnd(25000)}');
      expect(find.text('ít đá'), findsOneWidget);
    });
  });

  testWidgets('fits 320 dp at 1.3x text (SC-006)', (tester) async {
    await pumpDetail(tester, size: const Size(320, 640), textScale: 1.3);
    await showItem(
      tester,
      menuItem(
        _id,
        name: 'Set to 2 kimbap + Gà viên 4 vị sốt + Khoai tây chiên siêu to',
        basePrice: 1250000,
        sizes: const [
          MenuOption(id: 'nho', name: 'Phần nhỏ cho hai người', priceDelta: 0),
          MenuOption(
            id: 'lon',
            name: 'Phần lớn cho bốn người',
            priceDelta: 350000,
          ),
        ],
        toppings: const [
          MenuOption(
            id: 'sot',
            name: 'Thêm sốt phô mai cay',
            priceDelta: 15000,
          ),
        ],
        description: 'Combo cho nhóm bạn. ' * 20,
        ratingAverage: 4.6,
        reviewCount: 1234,
      ),
    );
    reviews.emitReviews(_id, [
      review(
        'r1',
        comment: 'Rất ngon và đầy đặn. ' * 20,
        imageUrls: const ['a.jpg', 'b.jpg', 'c.jpg'],
        isEdited: true,
      ),
    ]);
    await tester.pump();
    await tester.pump();
    await tapKey(tester, 'detail-size-lon');
    for (var i = 0; i < 8; i++) {
      await tapKey(tester, 'detail-quantity-plus');
    }

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(addLabel(tester), 'Thêm vào giỏ · ${formatVnd(14400000)}');
  });
}
