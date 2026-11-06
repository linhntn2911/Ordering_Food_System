import 'chat_role.dart';

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.text,
    required List<String> imagePaths,
    required this.createdAt,
    this.isPending = false,
  }) : imagePaths = List.unmodifiable(imagePaths);

  final String id;
  final String senderId;
  final ChatRole senderRole;
  final String text;
  final List<String> imagePaths;
  final DateTime? createdAt;
  final bool isPending;
}
