/// One emission of a browsing stream.
class MenuFeed<T> {
  MenuFeed({
    required Iterable<T> items,
    required this.isFromCache,
    required this.hasMore,
  }) : items = List<T>.unmodifiable(items);

  final List<T> items;

  /// Whether the data came from the device cache instead of the server.
  final bool isFromCache;

  /// Whether more documents may exist beyond the requested limit.
  final bool hasMore;
}
