import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/chat_draft.dart';

class ChatComposer extends StatelessWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.draft,
    required this.onText,
    required this.onRemove,
    required this.onAddImageUrl,
    required this.onSend,
    required this.sending,
    required this.canSend,
  });

  final TextEditingController controller;
  final ChatDraft draft;
  final ValueChanged<String> onText;
  final ValueChanged<int> onRemove;
  final String? Function(String) onAddImageUrl;
  final VoidCallback onSend;
  final bool sending;
  final bool canSend;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('chat-composer'),
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (draft.imageUrls.isNotEmpty)
        Wrap(
          spacing: AppSpacing.p8,
          children: [
            for (var index = 0; index < draft.imageUrls.length; index++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox.square(
                    dimension: AppSpacing.minTouchTarget,
                    child: const Icon(Icons.link_rounded),
                  ),

                  IconButton(
                    tooltip: 'Gỡ ảnh ${index + 1}',
                    onPressed: sending ? null : () => onRemove(index),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
          ],
        ),

      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            key: const ValueKey('chat-add-photo'),
            tooltip: 'Đính kèm link ảnh',
            onPressed: sending || draft.imageUrls.length >= ChatDraft.maxPhotos
                ? null
                : () => _showImageLinkDialog(context),
            icon: const Icon(Icons.add_photo_alternate_outlined),
          ),
          Expanded(
            child: TextField(
              key: const ValueKey('chat-text'),
              controller: controller,
              readOnly: sending,
              minLines: 1,
              maxLines: 3,
              maxLength: ChatDraft.maxTextLength,
              buildCounter:
                  (
                    _, {
                    required currentLength,
                    required isFocused,
                    required maxLength,
                  }) => currentLength > 900
                  ? Text('$currentLength/$maxLength')
                  : null,
              onChanged: onText,
              decoration: const InputDecoration(hintText: 'Nhập tin nhắn'),
            ),
          ),

          IconButton(
            key: const ValueKey('chat-send'),
            tooltip: 'Gửi tin nhắn',
            onPressed: canSend ? onSend : null,
            icon: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    ],
  );
  void _showImageLinkDialog(BuildContext context) {
    var url = '';
    String? error;
    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Đính kèm link ảnh'),
          content: TextField(
            key: const ValueKey('chat-image-url'),
            autofocus: true,
            keyboardType: TextInputType.url,
            onChanged: (value) {
              url = value;
              if (error != null) setState(() => error = null);
            },
            decoration: InputDecoration(
              labelText: 'Link ảnh',
              hintText: 'https://.../anh.jpg',
              prefixIcon: const Icon(Icons.link_rounded),
              errorText: error,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                final failure = onAddImageUrl(url);
                if (failure == null) {
                  Navigator.pop(context);
                } else {
                  setState(() => error = failure);
                }
              },
              child: const Text('Thêm ảnh'),
            ),
          ],
        ),
      ),
    );
  }
}
