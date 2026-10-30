import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/order_item.dart';

class OrderItemModel {
  const OrderItemModel(this.entity);

  final OrderItem entity;

  factory OrderItemModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
    SnapshotOptions? _,
  ) {
    final data = document.data();
    if (data == null) {
      throw StateError('Order item ${document.id} has no data.');
    }
    int integer(String key) =>
        data[key] is num ? (data[key] as num).toInt() : 0;
    String string(String key) => data[key]?.toString().trim() ?? '';
    final toppings = data['selectedToppings'];
    return OrderItemModel(
      OrderItem(
        id: document.id,
        menuItemId: string('menuItemId'),
        name: string('name').isEmpty ? 'Menu item' : string('name'),
        imageUrl: string('imageUrl'),
        basePrice: integer('basePrice'),
        selectedSize: string('selectedSize'),
        selectedToppings: toppings is Iterable
            ? List<String>.unmodifiable(
                toppings.map((value) => value.toString()),
              )
            : const [],
        quantity: integer('quantity'),
        unitPrice: integer('unitPrice'),
        lineTotal: integer('lineTotal'),
        note: string('note'),
        reviewed: data['reviewed'] == true,
      ),
    );
  }
}
