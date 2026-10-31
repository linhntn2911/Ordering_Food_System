import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FirestoreService {
  FirestoreService(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> ordersCollection() {
    return _firestore.collection('orders');
  }

  CollectionReference<Map<String, dynamic>> reviewsCollection() {
    return _firestore.collection('reviews');
  }

  CollectionReference<Map<String, dynamic>> notificationsCollection() {
    return _firestore.collection('notifications');
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getOrder(String orderId) {
    return ordersCollection().doc(orderId).get();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getOrdersStream({String? userId}) {
    Query<Map<String, dynamic>> query = ordersCollection().orderBy('createdAt', descending: true);
    if (userId != null && userId.isNotEmpty) {
      query = query.where('userId', isEqualTo: userId);
    }
    return query.snapshots();
  }
}

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return FirestoreService(firestore);
});
