import '../entities/menu_item.dart';

abstract interface class MenuRepository {
  Stream<List<MenuItem>> watchPublishedItems({
    String? categoryId,
    int limit = 50,
  });
}
