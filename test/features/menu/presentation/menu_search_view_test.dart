import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/core/theme/app_theme.dart';
import 'package:ordering_food_system/core/widgets/app_error_view.dart';
import 'package:ordering_food_system/core/widgets/food_card.dart';
import 'package:ordering_food_system/core/widgets/offline_banner.dart';
import 'package:ordering_food_system/features/menu/domain/entities/menu_failure.dart';
import 'package:ordering_food_system/features/menu/domain/entities/menu_option.dart';
import 'package:ordering_food_system/features/menu/presentation/viewmodels/menu_providers.dart';
import 'package:ordering_food_system/features/reviews/presentation/review_providers.dart';
import 'package:ordering_food_system/features/menu/presentation/views/menu_item_detail_view.dart';
import 'package:ordering_food_system/features/menu/presentation/views/menu_search_view.dart';
import 'package:ordering_food_system/features/menu/presentation/widgets/search_filter_sheet.dart';

import '../../../support/fake_menu_repository.dart';
import '../../../support/fake_review_repository.dart';
import '../../../support/menu_fixtures.dart';

const _grace = Duration(milliseconds: 20);
const _debounce = Duration(milliseconds: 300);

void main() {
  late FakeMenuRepository repository;

  setUp(() => repository = FakeMenuRepository());

  Future<void> pumpSearch(
    WidgetTester tester, {
    bool openFilters = false,
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          menuRepositoryProvider.overrideWithValue(repository),
          reviewRepositoryProvider.overrideWithValue(FakeReviewRepository()),
          menuOfflineGraceProvider.overrideWithValue(_grace),
          menuSearchDebounceProvider.overrideWithValue(_debounce),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: MenuSearchView(openFilters: openFilters),
        ),
      ),
    );
  }

  void emitMenu({bool isFromCache = false}) {
    repository
      ..emitCategories([
        category('ga-ran', name: 'Gà rán', sortOrder: 1),
        category('do-an-vat', name: 'Đồ ăn vặt', sortOrder: 2),
        category('do-uong', name: 'Đồ uống', sortOrder: 3),
      ], isFromCache: isFromCache)
      ..emitSearchableItems([
        menuItem(
          'ga-vien',
          categoryId: 'ga-ran',
          name: 'Gà viên',
          basePrice: 30000,
        ),
        menuItem(
          'banh-ga',
          categoryId: 'do-an-vat',
          name: 'Bánh gà',
          basePrice: 30000,
        ),
        menuItem(
          'ca-vien',
          categoryId: 'do-an-vat',
          name: 'Cá viên chiên',
          basePrice: 25000,
          isAvailable: false,
        ),
        menuItem(
          'tra-dao',
          categoryId: 'do-uong',
          name: 'Trà đào',
          basePrice: 20000,
          sizes: const [
            MenuOption(id: 'm', name: 'M', priceDelta: 0),
            MenuOption(id: 'l', name: 'L', priceDelta: 5000),
          ],
        ),
        menuItem(
          'tra-sua',
          categoryId: 'do-uong',
          name: 'Trà sữa trân châu đường đen',
          basePrice: 25000,
          ratingAverage: 4.9,
          reviewCount: 210,
        ),
      ], isFromCache: isFromCache);
  }

  Future<void> loaded(WidgetTester tester) async {
    emitMenu();
    await tester.pump();
    await tester.pump();
  }

  List<String> resultIds(WidgetTester tester) => [
    for (final card in tester.widgetList<FoodCard>(find.byType(FoodCard)))
      card.item.id,
  ];

  Future<void> typeKeyword(WidgetTester tester, String keyword) async {
    await tester.enterText(find.byKey(const ValueKey('search-input')), keyword);
    await tester.pump(_debounce);
    await tester.pump();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey(key));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> removeChip(WidgetTester tester, String key) async {
    final chip = find.byKey(ValueKey(key));
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: chip, matching: find.byIcon(Icons.close_rounded)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> applyFilters(WidgetTester tester, List<String> keys) async {
    await tapKey(tester, 'search-filter');
    for (final key in keys) {
      await tapKey(tester, key);
    }
    await tapKey(tester, 'filter-apply');
  }

  group('User Story 1', () {
    testWidgets('focuses the keyword field and shows a skeleton', (
      tester,
    ) async {
      await pumpSearch(tester);
      await tester.pump();

      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('search-input')),
      );
      expect(field.autofocus, isTrue);
      expect(find.bySemanticsLabel('Đang tải thực đơn'), findsOneWidget);
    });

    testWidgets('lists every item with a count', (tester) async {
      await pumpSearch(tester);
      await loaded(tester);

      expect(find.text('5 món'), findsOneWidget);
      expect(find.byType(FoodCard), findsNWidgets(5));
      expect(find.text('Hết hàng'), findsOneWidget);
    });

    testWidgets('results update after typing pauses', (tester) async {
      await pumpSearch(tester);
      await loaded(tester);

      await tester.enterText(
        find.byKey(const ValueKey('search-input')),
        'tra sua',
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(FoodCard), findsNWidgets(5));

      await tester.pump(_debounce);
      await tester.pump();
      expect(resultIds(tester), ['tra-sua']);
      expect(find.text('1 món'), findsOneWidget);
    });

    testWidgets('the keyboard search action applies immediately', (
      tester,
    ) async {
      await pumpSearch(tester);
      await loaded(tester);

      await tester.enterText(find.byKey(const ValueKey('search-input')), 'ga');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      expect(resultIds(tester), ['ga-vien', 'banh-ga']);
      await tester.pump(_debounce);
    });

    testWidgets('the clear button appears with text and clears at once', (
      tester,
    ) async {
      await pumpSearch(tester);
      await loaded(tester);
      expect(find.byKey(const ValueKey('search-clear')), findsNothing);

      await typeKeyword(tester, 'tra');
      expect(find.byKey(const ValueKey('search-clear')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('search-clear')));
      await tester.pump();

      expect(find.byKey(const ValueKey('search-clear')), findsNothing);
      expect(find.byType(FoodCard), findsNWidgets(5));
    });

    testWidgets('no match shows the empty state with "Xóa từ khóa"', (
      tester,
    ) async {
      await pumpSearch(tester);
      await loaded(tester);

      await typeKeyword(tester, 'pizza');

      expect(find.text('Không tìm thấy món phù hợp'), findsOneWidget);
      expect(find.text('Xóa bộ lọc'), findsNothing);
      await tester.tap(find.text('Xóa từ khóa'));
      await tester.pump();
      expect(find.byType(FoodCard), findsNWidgets(5));
    });

    testWidgets('an error offers retry and keeps the keyword', (tester) async {
      await pumpSearch(tester);
      await loaded(tester);
      await typeKeyword(tester, 'tra');

      repository.emitSearchableError(
        const MenuFailure(MenuFailureType.unavailable),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byType(AppErrorView), findsOneWidget);

      await tester.tap(find.text('Thử lại'));
      await tester.pump();
      emitMenu();
      await tester.pump();
      await tester.pump();

      expect(resultIds(tester), ['tra-dao', 'tra-sua']);
      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('search-input')),
      );
      expect(field.controller?.text, 'tra');
    });

    testWidgets('cached results show the offline banner', (tester) async {
      await pumpSearch(tester);
      emitMenu(isFromCache: true);
      await tester.pump();
      await tester.pump(_grace * 2);
      await tester.pump();

      expect(find.byType(OfflineBanner), findsOneWidget);
      expect(find.byType(FoodCard), findsNWidgets(5));
    });

    testWidgets('details keep keyword, filters and scroll on return', (
      tester,
    ) async {
      await pumpSearch(tester, size: const Size(390, 400));
      repository
        ..emitCategories([category('com', name: 'Cơm')])
        ..emitSearchableItems([
          for (var i = 0; i < 12; i++)
            menuItem('m$i', categoryId: 'com', name: 'Cơm số $i'),
        ]);
      await tester.pump();
      await tester.pump();
      await typeKeyword(tester, 'com');
      await applyFilters(tester, ['filter-sort-priceAsc']);

      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();
      final offset = tester
          .state<ScrollableState>(
            find.descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            ),
          )
          .position
          .pixels;
      expect(offset, greaterThan(0));

      final card = find.byType(FoodCard).hitTestable().first;
      final itemId = tester.widget<FoodCard>(card).item.id;
      repository.emitItem(itemId, menuItem(itemId, categoryId: 'com'));
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<MenuItemDetailView>(find.byType(MenuItemDetailView))
            .menuItemId,
        itemId,
      );

      Navigator.of(tester.element(find.byType(MenuItemDetailView))).pop();
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('search-input')),
      );
      expect(field.controller?.text, 'com');
      expect(find.byKey(const ValueKey('search-chip-sort')), findsOneWidget);
      final after = tester
          .state<ScrollableState>(
            find.descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            ),
          )
          .position
          .pixels;
      expect(after, offset);
    });

    testWidgets('fits 320 dp at 1.3x text (SC-006)', (tester) async {
      await pumpSearch(tester, size: const Size(320, 640), textScale: 1.3);
      await loaded(tester);
      await typeKeyword(tester, 'tra');
      await applyFilters(tester, [
        'filter-category-do-uong',
        'filter-available',
        'filter-sort-priceDesc',
      ]);

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('search-chip-sort')), findsOneWidget);
    });
  });

  group('User Story 2', () {
    testWidgets('openFilters opens the sheet without focusing the field', (
      tester,
    ) async {
      await pumpSearch(tester, openFilters: true);
      await loaded(tester);
      await tester.pumpAndSettle();

      expect(find.byType(SearchFilterSheet), findsOneWidget);
      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('search-input')),
      );
      expect(field.autofocus, isFalse);
      expect(
        find.byKey(const ValueKey('filter-category-do-an-vat')),
        findsOneWidget,
      );
    });

    testWidgets('applying filters shows removable chips', (tester) async {
      await pumpSearch(tester);
      await loaded(tester);
      expect(find.byKey(const ValueKey('search-filter-active')), findsNothing);

      await applyFilters(tester, [
        'filter-category-do-an-vat',
        'filter-available',
      ]);

      expect(resultIds(tester), ['banh-ga']);
      expect(
        find.byKey(const ValueKey('search-chip-category')),
        findsOneWidget,
      );
      expect(find.text('Đồ ăn vặt'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('search-chip-available')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('search-filter-active')),
        findsOneWidget,
      );

      await removeChip(tester, 'search-chip-available');
      expect(resultIds(tester), ['banh-ga', 'ca-vien']);

      await tapKey(tester, 'search-clear-filters');
      expect(find.byKey(const ValueKey('search-chip-category')), findsNothing);
      expect(find.byType(FoodCard), findsNWidgets(5));
    });

    testWidgets('dismissing the sheet keeps the results (FR-016)', (
      tester,
    ) async {
      await pumpSearch(tester);
      await loaded(tester);
      await tapKey(tester, 'search-filter');
      await tapKey(tester, 'filter-category-do-uong');

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byType(SearchFilterSheet), findsNothing);
      expect(find.byType(FoodCard), findsNWidgets(5));
      expect(find.byKey(const ValueKey('search-chip-category')), findsNothing);
    });

    testWidgets('an empty filtered result offers "Xóa bộ lọc"', (tester) async {
      await pumpSearch(tester);
      await loaded(tester);
      await typeKeyword(tester, 'ca vien');
      await applyFilters(tester, ['filter-available']);

      expect(find.text('Không tìm thấy món phù hợp'), findsOneWidget);
      expect(find.text('Xóa từ khóa'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(OutlinedButton),
          matching: find.text('Xóa bộ lọc'),
        ),
      );
      await tester.pumpAndSettle();
      expect(resultIds(tester), ['ca-vien']);
    });

    testWidgets('a removed category resets the filter with a snackbar', (
      tester,
    ) async {
      await pumpSearch(tester);
      await loaded(tester);
      await applyFilters(tester, ['filter-category-do-uong']);
      expect(resultIds(tester), ['tra-dao', 'tra-sua']);

      repository.emitCategories([category('ga-ran', name: 'Gà rán')]);
      await tester.pump();
      await tester.pump();

      expect(find.text('Danh mục này không còn được bán'), findsOneWidget);
      expect(find.byKey(const ValueKey('search-chip-category')), findsNothing);
    });
  });

  group('User Story 3', () {
    testWidgets('price ascending reorders results and shows a chip', (
      tester,
    ) async {
      await pumpSearch(tester);
      await loaded(tester);
      await typeKeyword(tester, 'tra');

      await applyFilters(tester, ['filter-sort-priceAsc']);
      expect(resultIds(tester), ['tra-dao', 'tra-sua']);
      expect(find.text('Giá thấp đến cao'), findsOneWidget);

      await applyFilters(tester, ['filter-sort-priceDesc']);
      expect(resultIds(tester), ['tra-sua', 'tra-dao']);

      await removeChip(tester, 'search-chip-sort');
      expect(find.byKey(const ValueKey('search-chip-sort')), findsNothing);
      expect(resultIds(tester), ['tra-dao', 'tra-sua']);
    });

    testWidgets('rating puts rated items first', (tester) async {
      await pumpSearch(tester);
      await loaded(tester);

      await applyFilters(tester, ['filter-sort-ratingDesc']);

      expect(resultIds(tester).first, 'tra-sua');
    });
  });
}
