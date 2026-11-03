import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/features/menu/domain/entities/menu_failure.dart';
import 'package:ordering_food_system/features/menu/presentation/viewmodels/home_menu_state.dart';
import 'package:ordering_food_system/features/menu/presentation/viewmodels/home_menu_view_model.dart';
import 'package:ordering_food_system/features/menu/presentation/viewmodels/menu_providers.dart';

import '../../../support/fake_menu_repository.dart';
import '../../../support/menu_fixtures.dart';

const _grace = Duration(milliseconds: 40);

void main() {
  late FakeMenuRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeMenuRepository();
    container = ProviderContainer(
      overrides: [
        menuRepositoryProvider.overrideWithValue(repository),
        menuOfflineGraceProvider.overrideWithValue(_grace),
      ],
    );
    addTearDown(container.dispose);
    container.listen(homeMenuViewModelProvider, (_, _) {});
  });

  HomeMenuState state() => container.read(homeMenuViewModelProvider);
  HomeMenuViewModel viewModel() =>
      container.read(homeMenuViewModelProvider.notifier);

  void emitStandardMenu() {
    repository
      ..emitCategories([
        category('com', name: 'Cơm', sortOrder: 1),
        category('do-uong', name: 'Đồ uống', sortOrder: 2),
        category('trang-mieng', name: 'Tráng miệng', sortOrder: 3),
      ])
      ..emitItems([
        menuItem('com-ga', categoryId: 'com'),
        menuItem('com-suon', categoryId: 'com'),
        menuItem('tra-dao', categoryId: 'do-uong'),
      ])
      ..emitPopular([
        menuItem('com-suon', ratingAverage: 4.8, reviewCount: 41),
      ]);
  }

  group('User Story 1 - browse from Home', () {
    test('starts in loading', () {
      expect(state().status, HomeMenuStatus.loading);
    });

    test('groups items by category in category order', () async {
      emitStandardMenu();
      await settle();

      final current = state();
      expect(current.status, HomeMenuStatus.data);
      expect(current.sections.map((s) => s.title), ['Cơm', 'Đồ uống']);
      expect(current.sections.first.items.map((i) => i.id), [
        'com-ga',
        'com-suon',
      ]);
      expect(current.popular.map((i) => i.id), ['com-suon']);
    });

    test('a category without items does not create a group', () async {
      emitStandardMenu();
      await settle();

      expect(
        state().sections.map((s) => s.categoryId),
        isNot(contains('trang-mieng')),
      );
    });

    test('drops items whose category is not visible', () async {
      repository
        ..emitCategories([category('com', name: 'Cơm')])
        ..emitItems([
          menuItem('com-ga', categoryId: 'com'),
          menuItem('lac', categoryId: 'unknown'),
        ])
        ..emitPopular([menuItem('lac', categoryId: 'unknown', reviewCount: 3)]);
      await settle();

      expect(state().sections.single.items.map((i) => i.id), ['com-ga']);
      expect(state().popular, isEmpty);
    });

    test('is empty when the server returns no categories or items', () async {
      repository
        ..emitCategories([])
        ..emitItems([])
        ..emitPopular([]);
      await settle();

      expect(state().status, HomeMenuStatus.empty);
    });

    test('shows error and recovers through retry', () async {
      repository.emitCategoriesError(
        const MenuFailure(MenuFailureType.unknown),
      );
      await settle();
      expect(state().status, HomeMenuStatus.error);

      viewModel().retry();
      expect(state().status, HomeMenuStatus.loading);

      emitStandardMenu();
      await settle();
      expect(state().status, HomeMenuStatus.data);
    });

    test('hides popular when nothing qualifies', () async {
      emitStandardMenu();
      repository.emitPopular([]);
      await settle();

      expect(state().popular, isEmpty);
      expect(state().status, HomeMenuStatus.data);
    });

    test('loadMore grows the limit and keeps items while loading', () async {
      repository
        ..emitCategories([category('com', name: 'Cơm')])
        ..emitItems([menuItem('a'), menuItem('b')], hasMore: true)
        ..emitPopular([]);
      await settle();

      repository.holdItemReplays = true;
      viewModel().loadMore();
      await settle();

      expect(repository.itemRequests.last, (categoryId: null, limit: 40));
      expect(state().status, HomeMenuStatus.data);
      expect(state().isLoadingMore, isTrue);
      expect(state().sections.single.items.map((i) => i.id), ['a', 'b']);

      repository.emitItems([menuItem('a'), menuItem('b'), menuItem('c')]);
      await settle();
      expect(state().isLoadingMore, isFalse);
      expect(state().sections.single.items, hasLength(3));
    });

    test('loadMore does nothing when there is no more data', () async {
      emitStandardMenu();
      await settle();
      final requests = repository.itemRequests.length;

      viewModel().loadMore();
      await settle();

      expect(repository.itemRequests, hasLength(requests));
    });
  });

  group('User Story 2 - browse by category', () {
    test('selecting a category requests only that category', () async {
      emitStandardMenu();
      await settle();

      viewModel().selectCategory('do-uong');
      repository.emitItems([
        menuItem('tra-dao', categoryId: 'do-uong'),
      ], categoryId: 'do-uong');
      await settle();

      expect(repository.itemRequests.last, (categoryId: 'do-uong', limit: 20));
      expect(state().selectedCategoryId, 'do-uong');
      expect(state().sections.single.items.single.id, 'tra-dao');
    });

    test('a selected category without items is an empty section', () async {
      emitStandardMenu();
      await settle();

      viewModel().selectCategory('trang-mieng');
      repository.emitItems([], categoryId: 'trang-mieng');
      await settle();

      expect(state().status, HomeMenuStatus.data);
      expect(state().isSelectedCategoryEmpty, isTrue);
    });

    test('selecting all returns to grouped items', () async {
      emitStandardMenu();
      await settle();
      viewModel().selectCategory('do-uong');
      await settle();

      viewModel().selectCategory(null);
      await settle();

      expect(state().isAllSelected, isTrue);
      expect(state().sections, hasLength(2));
    });

    test('changing category resets the page size', () async {
      repository
        ..emitCategories([category('com'), category('do-uong')])
        ..emitItems([menuItem('a')], hasMore: true)
        ..emitPopular([]);
      await settle();
      viewModel().loadMore();
      await settle();

      viewModel().selectCategory('do-uong');

      expect(repository.itemRequests.last, (categoryId: 'do-uong', limit: 20));
    });

    test(
      'an unpublished selected category resets to all with a notice',
      () async {
        emitStandardMenu();
        await settle();
        viewModel().selectCategory('do-uong');
        await settle();

        repository.emitCategories([category('com', name: 'Cơm')]);
        await settle();

        expect(state().selectedCategoryId, isNull);
        expect(state().notice, HomeMenuNotice.categoryRemoved);

        viewModel().clearNotice();
        expect(state().notice, isNull);
      },
    );
  });

  group('User Story 3 - realtime and offline', () {
    test('updates without retry when the stream emits again', () async {
      emitStandardMenu();
      await settle();

      repository.emitItems([
        menuItem('com-ga', basePrice: 50000),
        menuItem('com-moi'),
      ]);
      await settle();

      final items = state().sections.single.items;
      expect(items.first.basePrice, 50000);
      expect(items.map((i) => i.id), contains('com-moi'));
    });

    test('a sold-out item leaves popular but stays in the list', () async {
      emitStandardMenu();
      await settle();

      repository
        ..emitItems([menuItem('com-suon', isAvailable: false)])
        ..emitPopular([]);
      await settle();

      expect(state().popular, isEmpty);
      expect(state().sections.single.items.single.isAvailable, isFalse);
    });

    test('cache followed quickly by server data never shows offline', () async {
      repository
        ..emitCategories([category('com')], isFromCache: true)
        ..emitItems([menuItem('a')], isFromCache: true)
        ..emitPopular([], isFromCache: true);
      await settle();
      expect(state().isOffline, isFalse);

      repository
        ..emitCategories([category('com')])
        ..emitItems([menuItem('a')])
        ..emitPopular([]);
      await Future<void>.delayed(_grace * 2);

      expect(state().isOffline, isFalse);
    });

    test('cache-only data longer than the grace period is offline', () async {
      repository
        ..emitCategories([category('com')], isFromCache: true)
        ..emitItems([menuItem('a')], isFromCache: true)
        ..emitPopular([], isFromCache: true);
      await Future<void>.delayed(_grace * 2);

      expect(state().status, HomeMenuStatus.data);
      expect(state().isOffline, isTrue);

      repository
        ..emitCategories([category('com')])
        ..emitItems([menuItem('a')])
        ..emitPopular([]);
      await settle();
      expect(state().isOffline, isFalse);
    });

    test(
      'an empty cache without server data becomes an offline error',
      () async {
        repository
          ..emitCategories([], isFromCache: true)
          ..emitItems([], isFromCache: true)
          ..emitPopular([], isFromCache: true);
        await settle();
        expect(state().status, HomeMenuStatus.loading);

        await Future<void>.delayed(_grace * 2);
        expect(state().status, HomeMenuStatus.error);
        expect(state().error?.type, MenuFailureType.unavailable);
      },
    );
  });
}
