import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/core/theme/app_theme.dart';
import 'package:ordering_food_system/features/menu/domain/entities/menu_category.dart';
import 'package:ordering_food_system/features/menu/domain/entities/menu_search_query.dart';
import 'package:ordering_food_system/features/menu/presentation/widgets/search_filter_sheet.dart';

import '../../../support/menu_fixtures.dart';

void main() {
  late ValueNotifier<List<MenuCategory>> categories;
  MenuSearchFilters? result;
  var closed = false;

  setUp(() {
    categories = ValueNotifier([
      category('ga-ran', name: 'Gà rán'),
      category('do-an-vat', name: 'Đồ ăn vặt'),
      category('do-uong', name: 'Đồ uống'),
    ]);
    result = null;
    closed = false;
  });

  Future<void> openSheet(
    WidgetTester tester, {
    MenuSearchFilters initial = MenuSearchFilters.defaults,
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showSearchFilterSheet(
                  context,
                  initial: initial,
                  categories: categories,
                );
                closed = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  bool isSelected(WidgetTester tester, String key) {
    final chip = tester.widget<ChoiceChip>(
      find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(ChoiceChip),
      ),
    );
    return chip.selected;
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey(key));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('reflects the applied filters', (tester) async {
    await openSheet(
      tester,
      initial: const MenuSearchFilters(
        categoryId: 'do-uong',
        availableOnly: true,
        sortOrder: MenuSortOrder.priceAsc,
      ),
    );

    expect(find.text('Bộ lọc'), findsOneWidget);
    expect(isSelected(tester, 'filter-category-do-uong'), isTrue);
    expect(isSelected(tester, 'filter-category-all'), isFalse);
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const ValueKey('filter-available')),
          )
          .value,
      isTrue,
    );
    expect(isSelected(tester, 'filter-sort-priceAsc'), isTrue);
  });

  testWidgets('one category at a time; "Áp dụng" returns the draft', (
    tester,
  ) async {
    await openSheet(tester);

    await tapKey(tester, 'filter-category-ga-ran');
    await tapKey(tester, 'filter-category-do-an-vat');
    expect(isSelected(tester, 'filter-category-ga-ran'), isFalse);
    expect(isSelected(tester, 'filter-category-do-an-vat'), isTrue);

    await tapKey(tester, 'filter-available');
    await tapKey(tester, 'filter-sort-ratingDesc');
    await tapKey(tester, 'filter-apply');

    expect(closed, isTrue);
    expect(
      result,
      const MenuSearchFilters(
        categoryId: 'do-an-vat',
        availableOnly: true,
        sortOrder: MenuSortOrder.ratingDesc,
      ),
    );
  });

  testWidgets('"Đặt lại" resets the draft without closing', (tester) async {
    await openSheet(
      tester,
      initial: const MenuSearchFilters(
        categoryId: 'do-uong',
        availableOnly: true,
        sortOrder: MenuSortOrder.priceDesc,
      ),
    );

    await tapKey(tester, 'filter-reset');

    expect(closed, isFalse);
    expect(isSelected(tester, 'filter-category-all'), isTrue);
    expect(isSelected(tester, 'filter-sort-relevance'), isTrue);

    await tapKey(tester, 'filter-apply');
    expect(result, MenuSearchFilters.defaults);
  });

  testWidgets('dismissing returns null (FR-016)', (tester) async {
    await openSheet(tester);
    await tapKey(tester, 'filter-category-do-uong');

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
    expect(result, isNull);
  });

  testWidgets('follows category updates while open', (tester) async {
    await openSheet(tester);

    categories.value = [category('com', name: 'Cơm')];
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('filter-category-com')), findsOneWidget);
    expect(find.byKey(const ValueKey('filter-category-do-uong')), findsNothing);
  });

  testWidgets('fits 320 dp at 1.3x text (SC-006)', (tester) async {
    await openSheet(tester, size: const Size(320, 640), textScale: 1.3);

    expect(tester.takeException(), isNull);
    await tapKey(tester, 'filter-apply');
    expect(closed, isTrue);
  });
}
