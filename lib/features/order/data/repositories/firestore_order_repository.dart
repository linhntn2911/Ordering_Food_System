import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/firebase/firestore_paths.dart';
import '../../domain/entities/food_order.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/entities/order_status.dart';
import '../../domain/entities/order_status_event.dart';
import '../../domain/entities/sales_report.dart';
import '../../domain/repositories/order_repository.dart';
import '../models/food_order_model.dart';
import '../models/order_item_model.dart';
import '../models/order_status_event_model.dart';

class FirestoreOrderRepository implements OrderRepository {
  FirestoreOrderRepository(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  Stream<List<FoodOrder>> watchAdminOrders({int limit = 100}) {
    if (limit < 1 || limit > 100) {
      throw RangeError.range(limit, 1, 100, 'limit');
    }
    return _firestore
        .collection(FirestorePaths.orders)
        .withConverter<FoodOrderModel>(
          fromFirestore: FoodOrderModel.fromFirestore,
          toFirestore: (_, _) =>
              throw UnsupportedError('Đơn hàng chỉ được phép xem.'),
        )
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => List<FoodOrder>.unmodifiable(
            snapshot.docs.map((document) => document.data().toEntity()),
          ),
        );
  }

  @override
  Stream<FoodOrder> watchOrder(String orderId) {
    return _firestore
        .collection(FirestorePaths.orders)
        .doc(orderId)
        .withConverter<FoodOrderModel>(
          fromFirestore: FoodOrderModel.fromFirestore,
          toFirestore: (_, _) =>
              throw UnsupportedError('Đơn hàng chỉ được phép xem.'),
        )
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data();
          if (data == null) throw StateError('Không tìm thấy đơn hàng $orderId.');
          return data.toEntity();
        });
  }

  @override
  Stream<List<OrderItem>> watchOrderItems(String orderId) {
    return _firestore
        .collection(FirestorePaths.orderItems(orderId))
        .withConverter<OrderItemModel>(
          fromFirestore: OrderItemModel.fromFirestore,
          toFirestore: (_, _) =>
              throw UnsupportedError('Món đã đặt are immutable.'),
        )
        .snapshots()
        .map(
          (snapshot) => List<OrderItem>.unmodifiable(
            snapshot.docs.map((document) => document.data().entity),
          ),
        );
  }

  @override
  Stream<List<OrderStatusEvent>> watchStatusEvents(String orderId) {
    return _firestore
        .collection(FirestorePaths.orderStatusEvents(orderId))
        .withConverter<OrderStatusEventModel>(
          fromFirestore: OrderStatusEventModel.fromFirestore,
          toFirestore: (_, _) =>
              throw UnsupportedError('Events are append-only.'),
        )
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => List<OrderStatusEvent>.unmodifiable(
            snapshot.docs.map((document) => document.data().entity),
          ),
        );
  }

  @override
  Future<void> transitionStatus({
    required String orderId,
    required OrderStatus expectedStatus,
    required OrderStatus targetStatus,
    String reason = '',
  }) async {
    if (!expectedStatus.canTransitionTo(targetStatus)) {
      throw ArgumentError('Không thể chuyển đơn hàng sang trạng thái này.');
    }
    final normalizedReason = reason.trim();
    if (targetStatus == OrderStatus.rejected && normalizedReason.isEmpty) {
      throw ArgumentError('Vui lòng nhập lý do từ chối đơn hàng.');
    }
    final actorId = _auth.currentUser?.uid;
    if (actorId == null) throw StateError('Cần đăng nhập quản trị viên.');

    final orderRef = _firestore.collection(FirestorePaths.orders).doc(orderId);
    final eventRef = _firestore
        .collection(FirestorePaths.orderStatusEvents(orderId))
        .doc();
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(orderRef);
      final data = snapshot.data();
      if (data == null) throw StateError('Không tìm thấy đơn hàng $orderId.');
      final current = OrderStatus.parse(data['orderStatus']);
      if (current != expectedStatus) {
        throw StateError(
          'Đơn hàng đã được quản trị viên khác cập nhật. Vui lòng làm mới và thử lại.',
        );
      }
      final customerId = data['customerId']?.toString() ?? '';
      if (customerId.isEmpty) {
        throw StateError('Đơn hàng chưa có thông tin khách hàng.');
      }
      final notificationRef = _firestore
          .collection(FirestorePaths.notifications(customerId))
          .doc();
      final updates = <String, Object?>{
        'orderStatus': targetStatus.wireValue,
        'updatedAt': FieldValue.serverTimestamp(),
        if (targetStatus == OrderStatus.rejected)
          'rejectionReason': normalizedReason,
        if (targetStatus == OrderStatus.completed)
          'completedAt': FieldValue.serverTimestamp(),
      };
      transaction.update(orderRef, updates);
      transaction.set(eventRef, {
        'fromStatus': current.wireValue,
        'toStatus': targetStatus.wireValue,
        'actorId': actorId,
        'actorRole': 'admin',
        if (normalizedReason.isNotEmpty) 'reason': normalizedReason,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.set(notificationRef, {
        'type': 'order_status',
        'title': 'Đơn hàng ${targetStatus.label}',
        'body': _notificationBody(targetStatus, normalizedReason),
        'orderId': orderId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Stream<SalesReport> watchSalesReport({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) {
    return _firestore
        .collection(FirestorePaths.orders)
        .where('orderStatus', isEqualTo: OrderStatus.completed.wireValue)
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startInclusive),
        )
        .where('createdAt', isLessThan: Timestamp.fromDate(endExclusive))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final totals = <String, _ItemTotal>{};
          var revenue = 0;
          for (final orderDocument in snapshot.docs) {
            final data = orderDocument.data();
            final amount = data['totalAmount'];
            if (amount is num) revenue += amount.toInt();
            final items = await orderDocument.reference
                .collection('items')
                .get();
            for (final itemDocument in items.docs) {
              final item = OrderItemModel.fromFirestore(
                itemDocument,
                null,
              ).entity;
              final key = item.menuItemId.isEmpty ? item.name : item.menuItemId;
              final current = totals[key];
              totals[key] = _ItemTotal(
                name: item.name,
                quantity: (current?.quantity ?? 0) + item.quantity,
                revenue: (current?.revenue ?? 0) + item.lineTotal,
              );
            }
          }
          final topItems =
              totals.entries
                  .map(
                    (entry) => TopSellingItem(
                      menuItemId: entry.key,
                      name: entry.value.name,
                      quantity: entry.value.quantity,
                      revenue: entry.value.revenue,
                    ),
                  )
                  .toList()
                ..sort(
                  (a, b) => b.quantity != a.quantity
                      ? b.quantity.compareTo(a.quantity)
                      : b.revenue.compareTo(a.revenue),
                );
          return SalesReport(
            completedOrderCount: snapshot.docs.length,
            revenue: revenue,
            topItems: List<TopSellingItem>.unmodifiable(topItems.take(10)),
          );
        });
  }

  String _notificationBody(OrderStatus status, String reason) {
    if (status == OrderStatus.rejected) {
      return 'Đơn hàng của bạn đã bị từ chối. Lý do: $reason';
    }
    return 'Đơn hàng của bạn hiện đang ${status.label.toLowerCase()}.';
  }
}

class _ItemTotal {
  const _ItemTotal({
    required this.name,
    required this.quantity,
    required this.revenue,
  });

  final String name;
  final int quantity;
  final int revenue;
}
