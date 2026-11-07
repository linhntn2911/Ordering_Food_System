import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/chat_photo_viewer.dart';
import '../../domain/entities/chat_draft.dart';
import '../../domain/entities/chat_message.dart';
import '../viewmodels/order_chat_providers.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.own,
    required this.senderLabel,
    required this.userId,
    this.failure,
    this.onRetry,
  });

  final ChatMessage message;
  final bool own;
  final String senderLabel;
  final String userId;
  final String? failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final time = message.createdAt == null
        ? ''
        : DateFormat('HH:mm').format(message.createdAt!.toLocal());
    final theme = Theme.of(context).textTheme;
    return Align(
      alignment: own ? Alignment.centerRight : Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: 0.9,
        alignment: own ? Alignment.centerRight : Alignment.centerLeft,
        child: Align(
          alignment: own ? Alignment.centerRight : Alignment.centerLeft,
          child: Semantics(
            container: true,
            label: time.isEmpty
                ? 'Tin nhắn từ $senderLabel'
                : 'Tin nhắn từ $senderLabel, $time',
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: own ? AppColors.primarySoft : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadii.card),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.p12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!own) Text(senderLabel, style: theme.labelLarge),
                    if (message.text.isNotEmpty) SelectableText(message.text),
                    if (message.imagePaths.isNotEmpty)
                      Wrap(
                        spacing: AppSpacing.p4,
                        runSpacing: AppSpacing.p4,
                        children: [
                          for (
                            var index = 0;
                            index < message.imagePaths.length;
                            index++
                          )
                            Semantics(
                              label: 'Ảnh ${index + 1} của tin nhắn',
                              button: true,
                              child: SizedBox.square(
                                dimension: AppSpacing.minTouchTarget,
                                child: InkWell(
                                  key: ValueKey(
                                    'chat-photo-${message.id}-$index',
                                  ),
                                  onTap: () => _openPhoto(context, index),
                                  child:
                                      ChatDraft.isImageUrl(
                                        message.imagePaths[index],
                                      )
                                      ? const Icon(Icons.image_outlined)
                                      : _ChatImage(
                                          path: message.imagePaths[index],
                                          userId: userId,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    if (time.isNotEmpty) Text(time, style: theme.bodySmall),
                    if (message.isPending && failure == null)
                      const Icon(
                        Icons.schedule,
                        size: 16,
                        semanticLabel: 'Đang gửi',
                      ),
                    if (failure != null) ...[
                      Text('Gửi lỗi. $failure', style: theme.bodySmall),
                      if (onRetry != null)
                        TextButton(
                          key: ValueKey('chat-retry-${message.id}'),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 48),
                          ),
                          onPressed: onRetry,
                          child: const Text('Thử lại'),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openPhoto(BuildContext context, int index) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatPhotoViewer(
          count: message.imagePaths.length,
          initialIndex: index,
          itemBuilder: (_, index) => _ChatImage(
            path: message.imagePaths[index],
            userId: userId,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _ChatImage extends ConsumerWidget {
  const _ChatImage({
    required this.path,
    required this.userId,
    required this.fit,
  });

  final String path;
  final String userId;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ChatDraft.isImageUrl(path)) {
      return Image.network(
        path,
        fit: fit,
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        errorBuilder: (_, _, _) => const Icon(
          Icons.broken_image_outlined,
          semanticLabel: 'Không tải được ảnh',
        ),
      );
    }
    return ref
        .watch(chatPhotoProvider((path: path, userId: userId)))
        .when(
          data: (bytes) => Image.memory(
            bytes,
            fit: fit,
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
          ),
          loading: () => const Center(
            child: SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (_, _) => const Icon(
            Icons.broken_image_outlined,
            semanticLabel: 'Không tải được ảnh',
          ),
        );
  }
}
