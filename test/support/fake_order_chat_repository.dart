import 'dart:async';
import 'dart:typed_data';

import 'package:ordering_food_system/features/order_chat/domain/entities/chat_failure.dart';
import 'package:ordering_food_system/features/order_chat/domain/entities/chat_issue_type.dart';
import 'package:ordering_food_system/features/order_chat/domain/entities/chat_message.dart';
import 'package:ordering_food_system/features/order_chat/domain/entities/chat_role.dart';
import 'package:ordering_food_system/features/order_chat/domain/entities/order_chat.dart';
import 'package:ordering_food_system/features/order_chat/domain/repositories/order_chat_repository.dart';

typedef FakeSend = ({
  String orderId,
  String id,
  ChatRole role,
  String text,
  List<String> paths,
  ChatIssueType? issue,
});

class FakeOrderChatRepository implements OrderChatRepository {
  final sends = <FakeSend>[];
  final delivered = <String, FakeSend>{};
  final downloadedPhotos = <String>[];
  Uint8List? photoData;
  final reads = <({String orderId, ChatRole role})>[];
  final _chats = StreamController<OrderChat?>.broadcast(sync: true);
  final _messages = StreamController<List<ChatMessage>>.broadcast(sync: true);
  OrderChat? chat;
  List<ChatMessage> messages = [];
  List<OrderChat> adminChats = [];
  ChatFailure? nextSendFailure;
  Completer<void>? sendGate;
  int _sequence = 0;

  void emitChat(OrderChat? value) {
    chat = value;
    _chats.add(value);
  }

  void emitMessages(List<ChatMessage> value) {
    messages = value;
    _messages.add(value);
  }

  void failChat(ChatFailure failure) => _chats.addError(failure);

  Future<void> close() async {
    await _chats.close();
    await _messages.close();
  }

  @override
  Stream<OrderChat?> watchChat(String orderId) async* {
    yield chat;
    yield* _chats.stream;
  }

  @override
  Stream<List<ChatMessage>> watchMessages(
    String orderId, {
    required int limit,
  }) async* {
    yield messages.take(limit).toList();
    yield* _messages.stream.map((entries) => entries.take(limit).toList());
  }

  @override
  String newMessageId(String orderId) => 'message-${++_sequence}';

  @override
  Future<void> sendMessage({
    required String orderId,
    required String messageId,
    required ChatRole senderRole,
    required String text,
    required List<String> imagePaths,
    ChatIssueType? issueType,
  }) async {
    final call = (
      orderId: orderId,
      id: messageId,
      role: senderRole,
      text: text,
      paths: List<String>.unmodifiable(imagePaths),
      issue: issueType,
    );
    sends.add(call);
    if (delivered.containsKey(messageId)) return;
    final failure = nextSendFailure;
    nextSendFailure = null;
    if (failure != null) throw failure;
    await sendGate?.future;
    delivered[messageId] = call;
  }

  @override
  Future<void> markRead(
    String orderId,
    ChatRole viewerRole, {
    String? lastSeenMessageId,
  }) async => reads.add((orderId: orderId, role: viewerRole));

  @override
  Future<Uint8List> photoBytes(String storagePath) async {
    downloadedPhotos.add(storagePath);
    return photoData ?? Uint8List(0);
  }

  @override
  Stream<List<OrderChat>> watchAdminChats({int limit = 100}) =>
      Stream.value(adminChats.take(limit).toList());

  @override
  Stream<int> watchAdminUnreadCount() =>
      Stream.value(adminChats.where((chat) => chat.unreadByAdmin).length);

  @override
  Stream<bool> watchCustomerHasUnread(String customerId) => Stream.value(false);
}
