/// A selectable size or topping with a non-negative VND price delta.
class MenuOption {
  const MenuOption({
    required this.id,
    required this.name,
    required this.priceDelta,
  });

  final String id;
  final String name;
  final int priceDelta;
}
