class OrderItem {
  const OrderItem({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.imageUrl = '',
    this.basePrice = 0,
    this.selectedSize = '',
    this.selectedToppings = const [],
    this.note = '',
    this.reviewed = false,
  });

  final String id;
  final String menuItemId;
  final String name;
  final String imageUrl;
  final int basePrice;
  final String selectedSize;
  final List<String> selectedToppings;
  final int quantity;
  final int unitPrice;
  final int lineTotal;
  final String note;
  final bool reviewed;
}
