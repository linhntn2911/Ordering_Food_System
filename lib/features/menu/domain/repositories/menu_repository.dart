import '../entities/menu_item.dart';
import '../entities/menu_item_draft.dart';

abstract interface class MenuRepository {
  Stream<List<MenuItem>> watchPublishedItems({
    String? categoryId,
    int limit = 50,
  });

  Stream<List<MenuItem>> watchAdminItems({String? categoryId, int limit = 100});

  Future<void> setAvailability(String id, {required bool isAvailable});

  Future<void> setPublished(String id, {required bool isPublished});

  Future<String> saveItem(MenuItemDraft draft);
}
