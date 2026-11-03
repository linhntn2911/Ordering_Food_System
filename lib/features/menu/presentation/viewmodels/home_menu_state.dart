import '../../domain/entities/menu_category.dart';
import '../../domain/entities/menu_failure.dart';
import '../../domain/entities/menu_item.dart';

enum HomeMenuStatus { loading, data, empty, error }

enum HomeMenuNotice { categoryRemoved, loadMoreFailed }

class MenuSection {
  MenuSection({
    required this.categoryId,
    required this.title,
    required Iterable<MenuItem> items,
  }) : items = List<MenuItem>.unmodifiable(items);

  final String categoryId;
  final String title;
  final List<MenuItem> items;
}

class HomeMenuState {
  HomeMenuState({
    required this.status,
    Iterable<MenuCategory> categories = const [],
    this.selectedCategoryId,
    Iterable<MenuSection> sections = const [],
    Iterable<MenuItem> popular = const [],
    this.isOffline = false,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.notice,
    this.error,
  }) : categories = List<MenuCategory>.unmodifiable(categories),
       sections = List<MenuSection>.unmodifiable(sections),
       popular = List<MenuItem>.unmodifiable(popular);

  final HomeMenuStatus status;
  final List<MenuCategory> categories;

  /// `null` means "Tất cả".
  final String? selectedCategoryId;
  final List<MenuSection> sections;
  final List<MenuItem> popular;
  final bool isOffline;
  final bool hasMore;
  final bool isLoadingMore;
  final HomeMenuNotice? notice;
  final MenuFailure? error;

  bool get isAllSelected => selectedCategoryId == null;

  /// A selected category that has no items to show.
  bool get isSelectedCategoryEmpty =>
      !isAllSelected &&
      status == HomeMenuStatus.data &&
      sections.every((section) => section.items.isEmpty);
}
