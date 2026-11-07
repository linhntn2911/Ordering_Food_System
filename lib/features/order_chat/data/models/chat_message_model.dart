import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_role.dart';

abstract final class ChatMessageModel {
  static ChatMessage fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] as String,
      senderRole: ChatRole.values.byName(data['senderRole'] as String),
      text: data['text'] as String? ?? '',
      imagePaths: (data['imagePaths'] as List? ?? const []).cast<String>(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      isPending: doc.metadata.hasPendingWrites,
    );
  }
}
