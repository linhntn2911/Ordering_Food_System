import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/order_status.dart';
import '../../domain/entities/order_status_event.dart';

class OrderStatusEventModel {
  const OrderStatusEventModel(this.entity);

  final OrderStatusEvent entity;

  factory OrderStatusEventModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
    SnapshotOptions? _,
  ) {
    final data = document.data();
    if (data == null) {
      throw StateError('Status event ${document.id} has no data.');
    }
    final from = data['fromStatus'];
    final createdAt = data['createdAt'];
    return OrderStatusEventModel(
      OrderStatusEvent(
        id: document.id,
        fromStatus: from == null || from.toString().isEmpty
            ? null
            : OrderStatus.parse(from),
        toStatus: OrderStatus.parse(data['toStatus']),
        actorId: data['actorId']?.toString() ?? '',
        actorRole: data['actorRole']?.toString() ?? '',
        reason: data['reason']?.toString() ?? '',
        createdAt: createdAt is Timestamp
            ? createdAt.toDate()
            : DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );
  }
}
