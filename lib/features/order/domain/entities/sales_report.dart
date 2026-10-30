class SalesReport {
  const SalesReport({
    required this.completedOrderCount,
    required this.revenue,
    required this.topItems,
  });

  final int completedOrderCount;
  final int revenue;
  final List<TopSellingItem> topItems;

  int get averageOrderValue =>
      completedOrderCount == 0 ? 0 : revenue ~/ completedOrderCount;
}

class TopSellingItem {
  const TopSellingItem({
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.revenue,
  });

  final String menuItemId;
  final String name;
  final int quantity;
  final int revenue;
}
