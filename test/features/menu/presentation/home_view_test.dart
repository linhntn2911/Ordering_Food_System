import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/core/theme/app_theme.dart';
import 'package:ordering_food_system/core/widgets/app_error_view.dart';
import 'package:ordering_food_system/core/widgets/food_card.dart';
import 'package:ordering_food_system/core/widgets/offline_banner.dart';
import 'package:ordering_food_system/features/menu/domain/entities/menu_failure.dart';
import 'package:ordering_food_system/features/menu/domain/entities/menu_item.dart';
import 'package:ordering_food_system/features/menu/presentation/viewmodels/menu_providers.dart';
import 'package:ordering_food_system/features/reviews/presentation/review_providers.dart';
import 'package:ordering_food_system/features/menu/presentation/views/home_view.dart';
import 'package:ordering_food_system/features/menu/presentation/views/menu_item_detail_view.dart';
import 'package:ordering_food_system/features/menu/presentation/views/menu_search_view.dart';
import 'package:ordering_food_system/features/menu/presentation/widgets/search_filter_sheet.dart';
import 'package:ordering_food_system/features/menu/presentation/widgets/category_card_list.dart';

import '../../../support/fake_menu_repository.dart';
import '../../../support/fake_review_repository.dart';
import '../../../support/menu_fixtures.dart';

const _grace = Duration(milliseconds: 20);

void main() {
  late FakeMenuRepository repository;

  setUp(() => repository = FakeMenuRepository());

  Future<void> pumpHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          menuRepositoryProvider.overrideWithValue(repository),
          reviewRepositoryProvider.overrideWithValue(FakeReviewRepository()),
          menuOfflineGraceProvider.overrideWithValue(_grace),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const HomeView()),
      ),
    );
  }

  void emitMenu() {
    repository
      ..emitCategories([
        category('com', name: 'Cơm', sortOrder: 1),
        category('do-uong', name: 'Đồ uống', sortOrder: 2),
        category('trang-mieng', name: 'Tráng miệng', sortOrder: 3),
      ])
      ..emitItems([
        menuItem('com-ga', categoryId: 'com', name: 'Cơm gà'),
        menuItem('tra-dao', categoryId: 'do-uong', name: 'Trà đào'),
      ])
      ..emitPopular([
        menuItem(
          'com-suon',
          categoryId: 'com',
          name: 'Cơm sườn',
          ratingAverage: 4.8,
          reviewCount: 41,
        ),
      ]);
  }

  group('User Story 1', () {
    testWidgets('shows a loading skeleton first', (tester) async {
      await pumpHome(tester);

      expect(find.bySemanticsLabel('Đang tải thực đơn'), findsOneWidget);
    });

    testWidgets('shows the empty state when the menu is empty', (tester) async {
      await pumpHome(tester);
      repository
        ..emitCategories([])
        ..emitItems([])
        ..emitPopular([]);
      await tester.pump();
      await tester.pump();

      expect(find.text('Thực đơn chưa sẵn sàng'), findsOneWidget);
    });

    testWidgets('shows an error with retry', (tester) async {
      await pumpHome(tester);
      repository.emitCategoriesError(
        const MenuFailure(MenuFailureType.unknown),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(AppErrorView), findsOneWidget);
      await tester.tap(find.text('Thử lại'));
      emitMenu();
      await tester.pump();
      await tester.pump();

      expect(find.text('Cơm gà'), findsOneWidget);
    });

    testWidgets('shows popular, category headers and items', (tester) async {
      await pumpHome(tester);
      emitMenu();
      await tester.pump();
      await tester.pump();

      expect(find.text('Phổ biến'), findsOneWidget);
      expect(find.text('Cơm sườn'), findsOneWidget);
      // "Cơm" appears as a chip and as a group header.
      expect(find.text('Cơm'), findsNWidgets(2));
      expect(find.text('Cơm gà'), findsOneWidget);
      expect(find.text('Trà đào'), findsOneWidget);
    });

    testWidgets('sections follow the Food Ninja Home order (US1-9)', (
      tester,
    ) async {
      await pumpHome(tester);
      emitMenu();
      await tester.pump();
      await tester.pump();

      double top(Finder finder) => tester.getTopLeft(finder).dy;
      final order = [
        find.text('Tìm món\nbạn yêu thích'),
        find.byKey(const ValueKey('home-search')),
        find.byKey(const ValueKey('home-view-menu')),
        find.text('Danh mục'),
        find.text('Phổ biến'),
        find.text('Cơm gà'),
      ];
      for (var i = 1; i < order.length; i++) {
        expect(top(order[i]), greaterThan(top(order[i - 1])));
      }
      expect(find.byKey(const ValueKey('home-notifications')), findsOneWidget);
      expect(find.byKey(const ValueKey('home-filter')), findsOneWidget);
    });

    testWidgets('"Mua ngay" scrolls to the category cards (US1-10)', (
      tester,
    ) async {
      await pumpHome(tester);
      repository
        ..emitCategories([category('com', name: 'Cơm')])
        ..emitItems([
          for (var i = 0; i < 30; i++) menuItem('m$i', name: 'Món $i'),
        ])
        ..emitPopular([]);
      await tester.pump();
      await tester.pump();
      final before = tester.getTopLeft(find.text('Danh mục')).dy;

      await tester.tap(find.byKey(const ValueKey('home-view-menu')));
      await tester.pumpAndSettle();

      final after = tester.getTopLeft(find.text('Danh mục')).dy;
      expect(after, lessThan(before));
      expect(after, lessThan(100));
    });

    testWidgets('notifications report a feature in development (US1-11)', (
      tester,
    ) async {
      await pumpHome(tester);
      emitMenu();
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('home-notifications')));
      await tester.pump();

      expect(find.text('Tính năng đang được phát triển'), findsOneWidget);
      expect(find.byType(HomeView), findsOneWidget);
    });

    testWidgets('hides popular when it is empty', (tester) async {
      await pumpHome(tester);
      emitMenu();
      repository.emitPopular([]);
      await tester.pump();
      await tester.pump();

      expect(find.text('Phổ biến'), findsNothing);
      expect(find.text('Cơm gà'), findsOneWidget);
    });
  });

  group('User Story 2', () {
    testWidgets('selecting a category shows only its items', (tester) async {
      await pumpHome(tester);
      emitMenu();
      await tester.pump();
      await tester.pump();

      expect(
        tester.getTopLeft(find.byKey(const ValueKey('category-chip-all'))).dx,
        lessThan(
          tester.getTopLeft(find.byKey(const ValueKey('category-chip-com'))).dx,
        ),
      );

      await tester.tap(find.byKey(const ValueKey('category-chip-do-uong')));
      repository.emitItems([
        menuItem('tra-dao', categoryId: 'do-uong', name: 'Trà đào'),
      ], categoryId: 'do-uong');
      await tester.pump();
      await tester.pump();

      expect(find.text('Trà đào'), findsOneWidget);
      expect(find.text('Cơm gà'), findsNothing);
      // Popular items from other categories are hidden too (US2-5).
      expect(find.text('Phổ biến'), findsNothing);
      expect(find.text('Cơm sườn'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('category-chip-all')));
      await tester.pump();
      await tester.pump();
      expect(find.text('Phổ biến'), findsOneWidget);
    });

    testWidgets('an empty category offers a way back to all items', (
      tester,
    ) async {
      await pumpHome(tester);
      emitMenu();
      await tester.pump();
      await tester.pump();

      final chip = find.byKey(const ValueKey('category-chip-trang-mieng'));
      await tester.ensureVisible(chip);
      await tester.pump();
      await tester.tap(chip);
      repository.emitItems([], categoryId: 'trang-mieng');
      await tester.pump();
      await tester.pump();

      expect(find.text('Danh mục này chưa có món'), findsOneWidget);
      await tester.tap(find.text('Xem tất cả món'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Cơm gà'), findsOneWidget);
    });

    testWidgets('a removed category shows a snackbar', (tester) async {
      await pumpHome(tester);
      emitMenu();
      await tester.pump();
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('category-chip-do-uong')));
      await tester.pump();

      repository.emitCategories([category('com', name: 'Cơm')]);
      await tester.pump();
      await tester.pump();

      expect(find.text('Danh mục này không còn được bán'), findsOneWidget);
    });
  });

  group('User Story 3', () {
    testWidgets('offline banner appears after the grace period and clears', (
      tester,
    ) async {
      await pumpHome(tester);
      repository
        ..emitCategories([category('com', name: 'Cơm')], isFromCache: true)
        ..emitItems([menuItem('com-ga', name: 'Cơm gà')], isFromCache: true)
        ..emitPopular([], isFromCache: true);
      await tester.pump();
      await tester.pump();
      expect(find.byType(OfflineBanner), findsNothing);

      await tester.pump(_grace * 2);
      expect(find.byType(OfflineBanner), findsOneWidget);
      expect(find.text('Cơm gà'), findsOneWidget);

      repository
        ..emitCategories([category('com', name: 'Cơm')])
        ..emitItems([menuItem('com-ga', name: 'Cơm gà')])
        ..emitPopular([]);
      await tester.pump();
      await tester.pump();
      expect(find.byType(OfflineBanner), findsNothing);
    });

    testWidgets('empty cache becomes an error with retry', (tester) async {
      await pumpHome(tester);
      repository
        ..emitCategories([], isFromCache: true)
        ..emitItems([], isFromCache: true)
        ..emitPopular([], isFromCache: true);
      await tester.pump();
      await tester.pump(_grace * 2);

      expect(find.byType(AppErrorView), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    });
  });

  group('User Story 4', () {
    testWidgets('tapping an item opens its details and back keeps state', (
      tester,
    ) async {
      await pumpHome(tester);
      emitMenu();
      await tester.pump();
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('category-chip-com')));
      repository.emitItems([
        menuItem('com-ga', categoryId: 'com', name: 'Cơm gà'),
      ], categoryId: 'com');
      await tester.pump();
      await tester.pump();

      // Data for the details screen so it does not stay on a spinner.
      repository.emitItem('com-ga', menuItem('com-ga', name: 'Cơm gà'));
      await tester.tap(find.byKey(const ValueKey('food-card-com-ga')));
      await tester.pumpAndSettle();

      final detail = tester.widget<MenuItemDetailView>(
        find.byType(MenuItemDetailView),
      );
      expect(detail.menuItemId, 'com-ga');

      Navigator.of(tester.element(find.byType(MenuItemDetailView))).pop();
      await tester.pumpAndSettle();

      final selectedCard = tester.widget<CategoryCard>(
        find.byKey(const ValueKey('category-chip-com')),
      );
      expect(selectedCard.selected, isTrue);
      expect(find.byType(FoodCard), findsWidgets);
    });

    testWidgets('scroll position is kept after returning', (tester) async {
      tester.view.physicalSize = const Size(1080, 1600);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            menuRepositoryProvider.overrideWithValue(repository),
            reviewRepositoryProvider.overrideWithValue(FakeReviewRepository()),
            menuOfflineGraceProvider.overrideWithValue(_grace),
          ],
          child: MaterialApp(theme: AppTheme.light, home: const HomeView()),
        ),
      );
      repository
        ..emitCategories([category('com', name: 'Cơm')])
        ..emitItems([
          for (var i = 0; i < 12; i++) menuItem('m$i', name: 'Món $i'),
        ])
        ..emitPopular([]);
      await tester.pump();
      await tester.pump();

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();
      final scrollable = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      final offset = scrollable.position.pixels;
      expect(offset, greaterThan(0));

      final visibleCard = find.byType(FoodCard).hitTestable().first;
      final itemId = tester.widget<FoodCard>(visibleCard).item.id;
      repository.emitItem(itemId, menuItem(itemId));
      await tester.tap(visibleCard);
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byType(MenuItemDetailView))).pop();
      await tester.pumpAndSettle();

      expect(
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .pixels,
        offset,
      );
    });
  });

  group('Search entry points (specs/003-menu-search FR-002)', () {
    List<MenuItem> searchable() => [
      menuItem('com-ga', categoryId: 'com', name: 'Cơm gà'),
      menuItem('tra-dao', categoryId: 'do-uong', name: 'Trà đào'),
    ];

    testWidgets('the search field opens search with every category', (
      tester,
    ) async {
      await pumpHome(tester);
      emitMenu();
      repository.emitSearchableItems(searchable());
      await tester.pump();
      await tester.pump();
      // A category picked on Home is not carried over (US1-7).
      await tester.tap(find.byKey(const ValueKey('category-chip-com')));
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('home-search')));
      await tester.pumpAndSettle();

      expect(find.byType(MenuSearchView), findsOneWidget);
      expect(find.byType(SearchFilterSheet), findsNothing);
      expect(find.text('Tính năng đang được phát triển'), findsNothing);
      expect(
        find.byKey(const ValueKey('search-result-com-ga')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('search-result-tra-dao')),
        findsOneWidget,
      );
    });

    testWidgets('the filter button opens search with the sheet open', (
      tester,
    ) async {
      await pumpHome(tester);
      emitMenu();
      repository.emitSearchableItems(searchable());
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('home-filter')));
      await tester.pumpAndSettle();

      expect(find.byType(MenuSearchView), findsOneWidget);
      expect(find.byType(SearchFilterSheet), findsOneWidget);
    });

    testWidgets('returning to Home and searching again starts fresh', (
      tester,
    ) async {
      await pumpHome(tester);
      emitMenu();
      repository.emitSearchableItems(searchable());
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('home-search')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('search-input')), 'tra');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('search-result-com-ga')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('search-back')));
      await tester.pumpAndSettle();
      expect(find.byType(MenuSearchView), findsNothing);

      await tester.tap(find.byKey(const ValueKey('home-search')));
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('search-input')),
      );
      expect(field.controller?.text, isEmpty);
      expect(
        find.byKey(const ValueKey('search-result-com-ga')),
        findsOneWidget,
      );
    });
  });
}
