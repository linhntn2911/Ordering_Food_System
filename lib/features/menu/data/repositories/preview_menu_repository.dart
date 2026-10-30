import 'dart:async';

import '../../domain/entities/menu_category.dart';
import '../../domain/entities/menu_feed.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/entities/menu_item_draft.dart';
import '../../domain/entities/menu_item_feed.dart';
import '../../domain/repositories/menu_repository.dart';

/// Ngô Chicken sample catalogue for debug Web Preview only.
class PreviewMenuRepository implements MenuRepository {
  PreviewMenuRepository() : _items = _seedItems();

  final List<MenuItem> _items;
  final StreamController<List<MenuItem>> _changes =
      StreamController<List<MenuItem>>.broadcast();

  @override
  Stream<List<MenuItem>> watchAdminItems({
    String? categoryId,
    int limit = 100,
  }) async* {
    yield _snapshot(categoryId: categoryId, limit: limit, publishedOnly: false);
    yield* _changes.stream.map(
      (_) =>
          _snapshot(categoryId: categoryId, limit: limit, publishedOnly: false),
    );
  }

  @override
  Stream<MenuFeed<MenuCategory>> watchPublishedCategories({
    int limit = 50,
  }) async* {
    final ids = <String>{for (final item in _items) item.categoryId};
    var order = 0;
    yield MenuFeed(
      items: [
        for (final id in ids.take(limit))
          MenuCategory(id: id, name: id, imageUrl: '', sortOrder: order++),
      ],
      isFromCache: false,
      hasMore: false,
    );
  }

  @override
  Stream<MenuFeed<MenuItem>> watchBrowsableItems({
    String? categoryId,
    required int limit,
  }) => _watchPublishedFeed(categoryId: categoryId, limit: limit);

  @override
  Stream<MenuFeed<MenuItem>> watchSearchableItems({int limit = 300}) =>
      _watchPublishedFeed(limit: limit);

  @override
  Stream<MenuFeed<MenuItem>> watchPopularItems({int limit = 5}) =>
      _watchPublishedFeed(limit: limit).map(
        (feed) => MenuFeed(
          items: feed.items.where((item) => item.hasRating),
          isFromCache: false,
          hasMore: false,
        ),
      );

  @override
  Stream<MenuItemFeed> watchItem(String menuItemId) async* {
    MenuItemFeed feed() => MenuItemFeed(
      item: _items.where((item) => item.id == menuItemId).firstOrNull,
      isFromCache: false,
    );
    yield feed();
    yield* _changes.stream.map((_) => feed());
  }

  Stream<MenuFeed<MenuItem>> _watchPublishedFeed({
    String? categoryId,
    required int limit,
  }) async* {
    MenuFeed<MenuItem> feed() {
      final items = _snapshot(
        categoryId: categoryId,
        limit: limit,
        publishedOnly: true,
      );
      return MenuFeed(
        items: items,
        isFromCache: false,
        hasMore: items.length == limit,
      );
    }

    yield feed();
    yield* _changes.stream.map((_) => feed());
  }

  @override
  Future<void> setAvailability(String id, {required bool isAvailable}) async {
    final index = _indexOf(id);
    _items[index] = _copy(_items[index], isAvailable: isAvailable);
    _emit();
  }

  @override
  Future<void> setPublished(String id, {required bool isPublished}) async {
    final index = _indexOf(id);
    _items[index] = _copy(_items[index], isPublished: isPublished);
    _emit();
  }

  @override
  Future<String> saveItem(MenuItemDraft draft) async {
    final id = draft.id ?? 'preview-${DateTime.now().microsecondsSinceEpoch}';
    final existingIndex = _items.indexWhere((item) => item.id == id);
    final existing = existingIndex == -1 ? null : _items[existingIndex];
    final saved = MenuItem(
      id: id,
      categoryId: draft.categoryId,
      name: draft.name,
      description: draft.description,
      imageUrl: draft.imageBytes == null
          ? draft.existingImageUrl
          : 'preview-image://$id',
      basePrice: draft.basePrice,
      isAvailable: draft.isAvailable,
      isPublished: draft.isPublished,
      sortOrder: existing?.sortOrder ?? _items.length,
      ratingAverage: existing?.ratingAverage ?? 0,
      reviewCount: existing?.reviewCount ?? 0,
      sizes: draft.sizes,
      toppings: existing?.toppings ?? const [],
      isCategoryPublished: existing?.isCategoryPublished ?? true,
      categorySortOrder: existing?.categorySortOrder ?? 0,
    );
    if (existingIndex == -1) {
      _items.add(saved);
    } else {
      _items[existingIndex] = saved;
    }
    _emit();
    return id;
  }

  void dispose() => _changes.close();

  int _indexOf(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) throw StateError('Preview menu item $id was not found.');
    return index;
  }

  List<MenuItem> _snapshot({
    required String? categoryId,
    required int limit,
    required bool publishedOnly,
  }) {
    return List<MenuItem>.unmodifiable(
      _items
          .where(
            (item) =>
                (categoryId == null || item.categoryId == categoryId) &&
                (!publishedOnly ||
                    (item.isPublished && item.isCategoryPublished)),
          )
          .take(limit),
    );
  }

  void _emit() => _changes.add(List<MenuItem>.unmodifiable(_items));
}

MenuItem _copy(MenuItem item, {bool? isAvailable, bool? isPublished}) {
  return MenuItem(
    id: item.id,
    categoryId: item.categoryId,
    name: item.name,
    description: item.description,
    imageUrl: item.imageUrl,
    basePrice: item.basePrice,
    isAvailable: isAvailable ?? item.isAvailable,
    isPublished: isPublished ?? item.isPublished,
    sortOrder: item.sortOrder,
    ratingAverage: item.ratingAverage,
    reviewCount: item.reviewCount,
    sizes: item.sizes,
    toppings: item.toppings,
    isCategoryPublished: item.isCategoryPublished,
    categorySortOrder: item.categorySortOrder,
  );
}

List<MenuItem> _seedItems() {
  var order = 0;
  MenuItem item(String id, String categoryId, String name, int price) {
    return MenuItem(
      id: id,
      categoryId: categoryId,
      name: name,
      description: 'Món ngon từ thực đơn Ngô Chicken.',
      imageUrl: '',
      basePrice: price,
      isAvailable: true,
      isPublished: true,
      sortOrder: order++,
      ratingAverage: 0,
      reviewCount: 0,
    );
  }

  return [
    item('fried-drumstick', 'fried-chicken', 'Đùi gà rán', 30000),
    item('fried-wing', 'fried-chicken', 'Cánh gà rán', 30000),
    item('cheese-chicken', 'fried-chicken', 'Gà sốt phô mai cay', 35000),
    item('garlic-chicken-rice', 'rice', 'Cơm gà chiên mắm tỏi', 40000),
    item('fried-rice-chicken', 'rice', 'Cơm rang gà rán', 50000),
    item('sausage-egg-rice', 'rice', 'Cơm rang trứng - xúc xích', 25000),
    item('bolognese', 'noodles', 'Mì Ý bò bằm', 35000),
    item('seafood-noodles', 'noodles', 'Mì cay hải sản', 45000),
    item('mixed-noodles', 'noodles', 'Mì cay thập cẩm', 50000),
    item('chicken-cake', 'snacks', 'Bánh gà', 30000),
    item('fries', 'snacks', 'Khoai tây tươi chiên', 25000),
    item('kimbap', 'snacks', 'Kimbap', 25000),
    item(
      'combo-sauce-kimbap',
      'combos',
      'Set gà viên 4 vị sốt + Kimbap',
      140000,
    ),
    item(
      'combo-kimbap-fries',
      'combos',
      'Set 2 Kimbap + Gà viên + Khoai tây',
      200000,
    ),
    item('combo-noodle-tea', 'combos', 'Mì cay xúc xích + Trà tắc', 35000),
    item('lemon-tea', 'tea', 'Trà chanh', 10000),
    item('peach-tea', 'tea', 'Trà đào', 20000),
    item('traditional-milk-tea', 'tea', 'Trà sữa truyền thống', 20000),
    item('iced-yogurt', 'yogurt', 'Sữa chua đánh đá', 20000),
    item('strawberry-yogurt', 'yogurt', 'Sữa chua lắc dâu', 25000),
    item('kiwi-yogurt', 'yogurt', 'Sữa chua lắc kiwi', 25000),
    item(
      'strawberry-fresh-milk',
      'fresh-milk',
      'Sữa tươi latte kem dâu',
      25000,
    ),
    item('mango-fresh-milk', 'fresh-milk', 'Sữa tươi latte kem xoài', 25000),
    item(
      'brown-sugar-fresh-milk',
      'fresh-milk',
      'Sữa tươi trân châu đường đen',
      25000,
    ),
    item('matcha-latte', 'latte', 'Matcha Latte', 25000),
    item('taro-latte', 'latte', 'Latte khoai môn', 25000),
    item('matcha-cookie', 'latte', 'Matcha cookie', 25000),
    item('coca', 'soft-drinks', 'Coca-Cola', 12000),
    item('pepsi', 'soft-drinks', 'Pepsi', 12000),
    item('seven-up', 'soft-drinks', '7UP', 12000),
    item('watermelon-juice', 'juice-smoothies', 'Nước ép dưa hấu', 25000),
    item('orange-juice', 'juice-smoothies', 'Nước ép cam', 25000),
    item('avocado-smoothie', 'juice-smoothies', 'Sinh tố bơ', 25000),
  ];
}
