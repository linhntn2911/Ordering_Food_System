import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../domain/entities/chat_failure.dart';
import '../../domain/entities/chat_issue_type.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_role.dart';
import '../../domain/entities/order_chat.dart';
import '../../domain/repositories/order_chat_repository.dart';
import '../models/chat_message_model.dart';
import '../models/order_chat_model.dart';

class FirestoreOrderChatRepository implements OrderChatRepository {
  FirestoreOrderChatRepository(
    this._db,
    this._auth,
    this._storage, {
    this.general = false,
  });

  final bool general;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _chats =>
      _db.collection(general ? 'general_chats' : 'order_chats');
  DocumentReference<Map<String, dynamic>> _order(String id) =>
      _db.collection('orders').doc(id);

  @override
  Stream<OrderChat?> watchChat(String orderId) => _chats
      .doc(orderId)
      .snapshots()
      .map(OrderChatModel.fromSnapshot)
      .mapErrors();

  @override
  Stream<List<ChatMessage>> watchMessages(
    String orderId, {
    required int limit,
  }) => _chats
      .doc(orderId)
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots(includeMetadataChanges: true)
      .map(
        (snapshot) => List<ChatMessage>.unmodifiable(
          snapshot.docs.map(ChatMessageModel.fromSnapshot),
        ),
      )
      .mapErrors();

  @override
  Stream<List<OrderChat>> watchAdminChats({int limit = 100}) => _chats
      .orderBy('lastMessageAt', descending: true)
      .limit(limit)
      .snapshots()
      .map(
        (snapshot) => List<OrderChat>.unmodifiable(
          snapshot.docs.map(OrderChatModel.fromSnapshot).whereType<OrderChat>(),
        ),
      )
      .mapErrors();

  @override
  Stream<bool> watchCustomerHasUnread(String customerId) => _chats
      .where('customerId', isEqualTo: customerId)
      .where('unreadByCustomer', isEqualTo: true)
      .limit(1)
      .snapshots()
      .map((snapshot) => snapshot.docs.isNotEmpty)
      .mapErrors();

  @override
  Stream<int> watchAdminUnreadCount() => _chats
      .where('unreadByAdmin', isEqualTo: true)
      .snapshots()
      .map((snapshot) => snapshot.size)
      .mapErrors();

  @override
  String newMessageId(String orderId) =>
      _chats.doc(orderId).collection('messages').doc().id;

  @override
  Future<void> sendMessage({
    required String orderId,
    required String messageId,
    required ChatRole senderRole,
    required String text,
    required List<String> imagePaths,
    ChatIssueType? issueType,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw ChatFailure.permissionDenied;
    final chat = _chats.doc(orderId);
    final message = chat.collection('messages').doc(messageId);
    final trimmed = text.trim();
    try {
      await _db.runTransaction((transaction) async {
        final existing = await transaction.get(message);
        if (existing.exists) {
          if (existing.data()?['senderId'] != uid) {
            throw ChatFailure.permissionDenied;
          }
          return;
        }
        final source = general
            ? _db.collection('users').doc(orderId)
            : _order(orderId);
        final order = (await transaction.get(source)).data();
        if (order == null) throw ChatFailure.permissionDenied;
        final previous = await transaction.get(chat);
        final now = FieldValue.serverTimestamp();
        final update = <String, dynamic>{
          'lastMessageId': messageId,
          'lastMessageAt': now,
          'lastMessagePreview': trimmed.isEmpty
              ? '[Ảnh]'
              : String.fromCharCodes(trimmed.runes.take(80)),
          'lastSenderRole': senderRole.name,
          'updatedAt': now,
          if (senderRole == ChatRole.admin)
            'unreadByCustomer': true
          else
            'unreadByAdmin': true,
        };
        if (previous.exists) {
          transaction.update(chat, update);
        } else {
          transaction.set(chat, {
            if (!general) 'orderId': orderId,
            if (!general) 'orderCode': order['orderCode'] ?? orderId,
            if (general) 'customerName': order['fullName'] ?? 'Khách hàng',
            'customerId': general ? orderId : order['customerId'],
            if (!general)
              'issueType':
                  (senderRole == ChatRole.admin
                          ? ChatIssueType.other
                          : issueType)
                      ?.name,
            'openedByRole': senderRole.name,
            'createdAt': now,
            'unreadByAdmin': false,
            'unreadByCustomer': false,
            ...update,
          });
        }
        transaction.set(message, {
          'senderId': uid,
          'senderRole': senderRole.name,
          'text': trimmed,
          'imagePaths': imagePaths,
          'createdAt': now,
        });
      });
    } on FirebaseException catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<void> markRead(
    String orderId,
    ChatRole viewerRole, {
    String? lastSeenMessageId,
  }) async {
    final doc = _chats.doc(orderId);
    final key = viewerRole == ChatRole.admin
        ? 'unreadByAdmin'
        : 'unreadByCustomer';
    try {
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(doc);
        final chat = snapshot.data();
        if (chat?[key] == true &&
            (lastSeenMessageId == null ||
                chat?['lastMessageId'] == lastSeenMessageId)) {
          transaction.update(doc, {key: false});
        }
      });
    } on FirebaseException catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<Uint8List> photoBytes(String storagePath) async {
    try {
      return await _storage.ref(storagePath).getData(5 * 1024 * 1024) ??
          (throw ChatFailure.unknown);
    } on FirebaseException catch (error) {
      throw _mapFailure(error);
    }
  }
}

ChatFailure _mapFailure(Object error) => switch (error) {
  FirebaseException(
    code: 'permission-denied' || 'unauthorized' || 'unauthenticated',
  ) =>
    ChatFailure.permissionDenied,
  FirebaseException(
    code: 'unavailable' ||
        'deadline-exceeded' ||
        'retry-limit-exceeded' ||
        'network-request-failed' ||
        'aborted',
  ) =>
    ChatFailure.unavailable,
  _ => ChatFailure.unknown,
};

extension<T> on Stream<T> {
  Stream<T> mapErrors() =>
      handleError((Object error) => throw _mapFailure(error));
}
