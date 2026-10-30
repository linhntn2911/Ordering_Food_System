import 'menu_item.dart';
import 'menu_option.dart';

/// Size, toppings, quantity and note chosen on Food Details
/// (`specs/004-food-details/data-model.md`).
///
/// Lives only while the screen is open; every visit starts from [initial].
class ItemSelection {
  ItemSelection._({
    required this.sizeId,
    required Set<String> toppingIds,
    required this.quantity,
    required this.note,
  }) : toppingIds = Set<String>.unmodifiable(toppingIds);

  /// Cheapest size (the first one on ties), no toppings, quantity 1, no note.
  factory ItemSelection.initial(MenuItem item) {
    return ItemSelection._(
      sizeId: _defaultSize(item)?.id,
      toppingIds: const {},
      quantity: minQuantity,
      note: '',
    );
  }

  static const minQuantity = 1;
  static const maxQuantity = 99;
  static const maxNoteLength = 200;

  /// Null when the item has no sizes.
  final String? sizeId;
  final Set<String> toppingIds;
  final int quantity;
  final String note;

  /// The note, or an empty string when it holds only whitespace.
  String get trimmedNote => note.trim();

  /// Selects [id] when it is one of the item's sizes.
  ItemSelection withSize(MenuItem item, String id) {
    if (!item.sizes.any((size) => size.id == id) || id == sizeId) {
      return this;
    }
    return _copy(sizeId: id);
  }

  /// Adds or removes [id] when it is one of the item's toppings.
  ItemSelection toggleTopping(MenuItem item, String id) {
    if (!item.toppings.any((topping) => topping.id == id)) {
      return this;
    }
    final toppingIds = {...this.toppingIds};
    if (!toppingIds.remove(id)) {
      toppingIds.add(id);
    }
    return _copy(toppingIds: toppingIds);
  }

  ItemSelection withQuantity(int quantity) =>
      _copy(quantity: quantity.clamp(minQuantity, maxQuantity));

  ItemSelection withNote(String note) {
    final runes = note.runes;
    return _copy(
      note: runes.length <= maxNoteLength
          ? note
          : String.fromCharCodes(runes.take(maxNoteLength)),
    );
  }

  /// Base price plus the chosen size and toppings, for one unit.
  int unitPrice(MenuItem item) {
    var price = item.basePrice;
    for (final size in item.sizes) {
      if (size.id == sizeId) {
        price += size.priceDelta;
      }
    }
    for (final topping in item.toppings) {
      if (toppingIds.contains(topping.id)) {
        price += topping.priceDelta;
      }
    }
    return price;
  }

  int total(MenuItem item) => unitPrice(item) * quantity;

  /// Drops choices the item no longer offers; a missing size falls back to
  /// the default size.
  ({ItemSelection selection, bool removedOptions}) reconcile(MenuItem item) {
    final sizeStillOffered = sizeId == null
        ? item.sizes.isEmpty
        : item.sizes.any((size) => size.id == sizeId);
    final offeredToppings = {for (final topping in item.toppings) topping.id};
    final keptToppings = toppingIds.where(offeredToppings.contains).toSet();
    final removedToppings = keptToppings.length != toppingIds.length;
    if (sizeStillOffered && !removedToppings) {
      return (selection: this, removedOptions: false);
    }
    // A size added to an item that had none is not a removal.
    final removedSize = !sizeStillOffered && sizeId != null;
    return (
      selection: _copy(
        sizeId: sizeStillOffered ? sizeId : _defaultSize(item)?.id,
        clearSize: !sizeStillOffered && _defaultSize(item) == null,
        toppingIds: keptToppings,
      ),
      removedOptions: removedSize || removedToppings,
    );
  }

  ItemSelection _copy({
    String? sizeId,
    bool clearSize = false,
    Set<String>? toppingIds,
    int? quantity,
    String? note,
  }) {
    return ItemSelection._(
      sizeId: clearSize ? null : sizeId ?? this.sizeId,
      toppingIds: toppingIds ?? this.toppingIds,
      quantity: quantity ?? this.quantity,
      note: note ?? this.note,
    );
  }

  static MenuOption? _defaultSize(MenuItem item) {
    MenuOption? cheapest;
    for (final size in item.sizes) {
      if (cheapest == null || size.priceDelta < cheapest.priceDelta) {
        cheapest = size;
      }
    }
    return cheapest;
  }

  @override
  bool operator ==(Object other) =>
      other is ItemSelection &&
      other.sizeId == sizeId &&
      other.quantity == quantity &&
      other.note == note &&
      other.toppingIds.length == toppingIds.length &&
      other.toppingIds.containsAll(toppingIds);

  @override
  int get hashCode =>
      Object.hash(sizeId, quantity, note, Object.hashAllUnordered(toppingIds));
}
