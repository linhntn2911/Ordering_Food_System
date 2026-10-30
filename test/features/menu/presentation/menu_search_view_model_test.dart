import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/features/menu/domain/entities/menu_failure.dart';
import 'package:ordering_food_system/features/menu/domain/entities/menu_item.dart';
import 'package:ordering_food_system/features/menu/domain/entities/menu_search_query.dart';
import 'package:ordering_food_system/features/menu/presentation/viewmodels/menu_providers.dart';
import 'package:ordering_food_system/features/menu/presentation/viewmodels/menu_search_state.dart';
import 'package:ordering_food_system/features/menu/presentation/viewmodels/menu_search_view_model.dart';

import '../../../support/fake_menu_repository.dart';
import '../../../support/menu_fixtures.dart';

const _grace = Duration(milliseconds: 40);
const _debounce = Duration(milliseconds: 30);

Future<void> _wait(Duration duration) async {
  await Future<void>.delayed(duration);
  await settle();
}

void main() {
  late FakeMenuRepository repository;
  late ProviderContainer container;
  late ProviderSubscription<MenuSearchState> subscription;

  setUp(() {
    repository = FakeMenuRepository();
    container = ProviderContainer(
      overrides: [
        menuRepositoryProvider.overrideWithValue(repository),
        menuOfflineGraceProvider.overrideWithValue(_grace),
        menuSearchDebounceProvider.overrideWithValue(_debounce),
      ],
    );
    addTearDown(container.dispose);
    subscription = container.listen(menuSearchViewModelProvider, (_, _) {});
  });

  MenuSearchState state() => container.read(menuSearchViewModelProvider);
  MenuSearchViewModel viewModel() =>
      container.read(menuSearchViewModelProvider.notifier);
  List<String> resultIds() => [for (final item in state().results) item.id];

  final items = <MenuItem>[
    menuItem('ga-vien', categoryId: 'ga-ran', name: 'Gà viên'),
    menuItem('com-ga', categoryId: 'com', name: 'Cơm gà', basePrice: 40000),
    menuItem(
      'ca-vien',
      categoryId: 'do-an-vat',
      name: 'Cá viên chiên',
      basePrice: 25000,
      isAvailable: false,
    ),
    menuItem(
      'tra-sua',
      categoryId: 'do-uong',
      name: 'Trà sữa',
      basePrice: 25000,
      ratingAverage: 4.9,
      reviewCount: 10,
    ),
  ];

  void emitMenu({bool isFromCache = false}) {
    repository
      ..emitCategories([
        category('ga-ran', name: 'Gà rán', sortOrder: 1),
        category('com', name: 'Cơm', sortOrder: 2),
        category('do-an-vat', name: 'Đồ ăn vặt', sortOrder: 3),
        category('do-uong', name: 'Đồ uống', sortOrder: 4),
      ], isFromCache: isFromCache)
      ..emitSearchableItems(items, isFromCache: isFromCache);
  }

  group('User Story 1 - search by name', () {
    test('starts loading with the default query', () {
      expect(state().status, MenuSearchStatus.loading);
      expect(state().query, const MenuSearchQuery());
      expect(repository.searchRequests, [300]);
    });

    test('the first feed shows every item in menu order', () async {
      emitMenu();
      await settle();

      expect(state().status, MenuSearchStatus.ready);
      expect(resultIds(), ['ga-vien', 'com-ga', 'ca-vien', 'tra-sua']);
      expect(state().categories, hasLength(4));
    });

    test('a keyword applies only after typing pauses', () async {
      emitMenu();
      await settle();

      viewModel()
        ..updateKeyword('t')
        ..updateKeyword('tra')
        ..updateKeyword('tra sua');
      await settle();
      expect(resultIds(), hasLength(4), reason: 'not applied before delay');

      await _wait(_debounce * 2);
      expect(state().query.keyword, 'tra sua');
      expect(resultIds(), ['tra-sua']);
    });

    test('submitting and clearing apply immediately', () async {
      emitMenu();
      await settle();

      viewModel().submitKeyword('ga');
      expect(resultIds(), ['ga-vien', 'com-ga']);

      viewModel().clearKeyword();
      expect(state().query.keyword, isEmpty);
      expect(resultIds(), hasLength(4));
    });

    test('clearing cancels a pending keyword', () async {
      emitMenu();
      await settle();

      viewModel()
        ..updateKeyword('pizza')
        ..clearKeyword();
      await _wait(_debounce * 2);

      expect(state().query.keyword, isEmpty);
    });

    test('keywords longer than 50 characters are cut', () async {
      emitMenu();
      await settle();

      viewModel().submitKeyword('a' * 70);

      expect(state().query.keyword, 'a' * 50);
    });

    test('no match is an empty result, not an error', () async {
      emitMenu();
      await settle();

      viewModel().submitKeyword('pizza');

      expect(state().isEmptyResult, isTrue);
    });

    test('new feeds are searched with the current query (FR-014)', () async {
      emitMenu();
      await settle();
      viewModel().submitKeyword('ga');

      repository.emitSearchableItems([
        menuItem('ga-vien', categoryId: 'ga-ran', name: 'Gà viên mới'),
        menuItem('tra-sua', categoryId: 'do-uong', name: 'Trà sữa gà'),
      ]);
      await settle();

      expect(resultIds(), ['ga-vien', 'tra-sua']);
      expect(state().results.first.name, 'Gà viên mới');
    });

    test('an error keeps the query and retry recovers', () async {
      emitMenu();
      await settle();
      viewModel().submitKeyword('ga');

      repository.emitSearchableError(
        const MenuFailure(MenuFailureType.unavailable),
      );
      await settle();
      expect(state().status, MenuSearchStatus.error);
      expect(state().error?.type, MenuFailureType.unavailable);
      expect(state().query.keyword, 'ga');

      viewModel().retry();
      await settle();
      expect(state().status, MenuSearchStatus.loading);

      repository.emitSearchableItems(items);
      await settle();
      expect(state().status, MenuSearchStatus.ready);
      expect(resultIds(), ['ga-vien', 'com-ga']);
    });

    test('an empty cache without server data becomes an error', () async {
      repository
        ..emitCategories([], isFromCache: true)
        ..emitSearchableItems([], isFromCache: true);
      await settle();
      expect(state().status, MenuSearchStatus.loading);

      await _wait(_grace * 2);
      expect(state().status, MenuSearchStatus.error);
    });

    test('cached data becomes offline after the grace period', () async {
      emitMenu(isFromCache: true);
      await settle();
      expect(state().isOffline, isFalse);

      await _wait(_grace * 2);
      expect(state().isOffline, isTrue);
      expect(state().status, MenuSearchStatus.ready);

      emitMenu();
      await settle();
      expect(state().isOffline, isFalse);
    });

    test('closing the screen discards the query (FR-015)', () async {
      emitMenu();
      await settle();
      viewModel()
        ..submitKeyword('ga')
        ..updateKeyword('pending');

      subscription.close();
      await settle();
      container.listen(menuSearchViewModelProvider, (_, _) {});
      await settle();

      expect(state().query, const MenuSearchQuery());
      await _wait(_debounce * 2);
      expect(state().query.keyword, isEmpty);
    });
  });

  group('User Story 2 - filters', () {
    test('applying filters recomputes without a new stream', () async {
      emitMenu();
      await settle();

      viewModel().applyFilters(
        const MenuSearchFilters(categoryId: 'do-an-vat', availableOnly: true),
      );

      expect(resultIds(), isEmpty);
      expect(state().selectedCategory?.name, 'Đồ ăn vặt');
      expect(repository.searchRequests, hasLength(1));
    });

    test('filters can be removed one at a time', () async {
      emitMenu();
      await settle();
      viewModel().applyFilters(
        const MenuSearchFilters(categoryId: 'do-an-vat', availableOnly: true),
      );

      viewModel().removeAvailableFilter();
      expect(resultIds(), ['ca-vien']);

      viewModel().removeCategoryFilter();
      expect(state().filters.isDefault, isTrue);
      expect(resultIds(), hasLength(4));
    });

    test('clearing filters keeps the keyword', () async {
      emitMenu();
      await settle();
      viewModel()
        ..submitKeyword('vien')
        ..applyFilters(
          const MenuSearchFilters(
            availableOnly: true,
            sortOrder: MenuSortOrder.priceAsc,
          ),
        );
      expect(resultIds(), ['ga-vien']);

      viewModel().clearFilters();

      expect(state().filters, MenuSearchFilters.defaults);
      expect(state().query.keyword, 'vien');
      expect(resultIds(), ['ga-vien', 'ca-vien']);
    });

    test('a removed category resets the filter and notifies once', () async {
      emitMenu();
      await settle();
      viewModel().applyFilters(const MenuSearchFilters(categoryId: 'do-uong'));

      repository.emitCategories([category('com', name: 'Cơm')]);
      await settle();

      expect(state().filters.categoryId, isNull);
      expect(state().notice, MenuSearchNotice.categoryRemoved);

      viewModel().clearNotice();
      expect(state().notice, isNull);
    });

    test('cached categories never reset the filter', () async {
      emitMenu();
      await settle();
      viewModel().applyFilters(const MenuSearchFilters(categoryId: 'do-uong'));

      repository.emitCategories([category('com')], isFromCache: true);
      await settle();

      expect(state().filters.categoryId, 'do-uong');
      expect(state().notice, isNull);
    });

    test('retry keeps the filters', () async {
      emitMenu();
      await settle();
      viewModel().applyFilters(const MenuSearchFilters(availableOnly: true));

      viewModel().retry();
      emitMenu();
      await settle();

      expect(state().filters.availableOnly, isTrue);
      expect(resultIds(), isNot(contains('ca-vien')));
    });
  });

  group('User Story 3 - sort order', () {
    test('removing the sort order returns to relevance', () async {
      emitMenu();
      await settle();
      viewModel().applyFilters(
        const MenuSearchFilters(sortOrder: MenuSortOrder.ratingDesc),
      );
      expect(resultIds().first, 'tra-sua');

      viewModel().removeSortOrder();

      expect(state().filters.sortOrder, MenuSortOrder.relevance);
      expect(resultIds().first, 'ga-vien');
    });
  });
}
