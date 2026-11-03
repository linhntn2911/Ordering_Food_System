import 'menu_item.dart';

/// One emission of the single-item stream used by Food Details.
class MenuItemFeed {
  const MenuItemFeed({required this.item, required this.isFromCache});

  /// Null when the item does not exist, is malformed or is no longer
  /// publicly readable.
  final MenuItem? item;

  /// Whether the data came from the device cache instead of the server.
  final bool isFromCache;
}
