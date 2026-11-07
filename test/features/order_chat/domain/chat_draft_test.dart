import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/features/order_chat/domain/entities/chat_draft.dart';

void main() {
  test('validates content and trimmed character count', () {
    expect(ChatDraft(text: '  ').canSend, isFalse);
    expect(ChatDraft(text: 'a' * 1001).canSend, isFalse);
    expect(ChatDraft(text: '  NaN ').canSend, isTrue);
  });

  test('allows image links only over HTTPS and limits attachment count', () {
    const url = 'https://example.com/anh.png';
    expect(ChatDraft(imageUrls: [url]).canSend, isTrue);
    expect(
      ChatDraft(imageUrls: ['http://example.com/anh.png']).canSend,
      isFalse,
    );
    expect(ChatDraft(imageUrls: List.filled(4, url)).canSend, isFalse);
  });
}
