import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/features/order/domain/entities/order_status.dart';
import 'package:ordering_food_system/features/order_chat/domain/entities/chat_failure.dart';
import 'package:ordering_food_system/features/order_chat/domain/entities/chat_issue_type.dart';
import 'package:ordering_food_system/features/order_chat/domain/entities/chat_role.dart';
import 'package:ordering_food_system/features/order_chat/presentation/viewmodels/order_chat_providers.dart';

import '../../../support/fake_order_chat_repository.dart';
import '../../../support/order_chat_order_fixture.dart';

const _photoUrl = 'https://example.com/anh.jpg';

void main() {
  const customer = (
    orderId: 'order-one',
    userId: 'customer',
    role: ChatRole.customer,
  );
  const admin = (orderId: 'order-one', userId: 'admin', role: ChatRole.admin);
  late FakeOrderChatRepository repository;
  late ProviderContainer container;

  setUp(() => repository = FakeOrderChatRepository());
  tearDown(() async {
    container.dispose();
    await repository.close();
  });

  Future<void> start(ChatSession session, {bool closed = false}) async {
    container = ProviderContainer(
      overrides: [
        orderChatRepositoryProvider.overrideWithValue(repository),
        chatOrderProvider(session.orderId).overrideWith(
          (ref) => Stream.value(
            chatOrderFixture(
              status: closed ? OrderStatus.completed : OrderStatus.preparing,
              updatedAt: DateTime.now().subtract(const Duration(hours: 25)),
            ),
          ),
        ),
      ],
    );
    container.listen(orderChatViewModelProvider(session), (_, _) {});
    container.listen(chatOrderProvider(session.orderId), (_, _) {});
    container.listen(orderChatStreamProvider(session.orderId), (_, _) {});
    await container.read(chatOrderProvider(session.orderId).future);
    await container.read(orderChatStreamProvider(session.orderId).future);
  }

  test(
    'customer send defaults to other and retries with the same photo and ID',
    () async {
      await start(customer);
      final provider = orderChatViewModelProvider(customer);
      final model = container.read(provider.notifier);
      model.setText('  Giao trễ  ');
      expect(model.addImageUrl(_photoUrl), isNull);
      repository.nextSendFailure = ChatFailure.unavailable;
      await model.send();
      expect(container.read(provider).draft.imageUrls, hasLength(1));
      expect(container.read(provider).error, ChatFailure.unavailable.message);
      await model.send();
      expect(repository.sends, hasLength(2));
      expect(repository.sends.map((call) => call.id).toSet(), hasLength(1));
      expect(repository.delivered.values.single.text, 'Giao trễ');
      expect(repository.delivered.values.single.issue, ChatIssueType.other);
      expect(container.read(provider).draft.text, isEmpty);
    },
  );

  test('rejects insecure, duplicate and excess image links', () async {
    await start(customer);
    final model = container.read(orderChatViewModelProvider(customer).notifier);
    expect(model.addImageUrl('http://example.com/a.png'), isNotNull);
    expect(model.addImageUrl(_photoUrl), isNull);
    expect(model.addImageUrl(_photoUrl), isNotNull);
    expect(model.addImageUrl('https://example.com/b.png'), isNull);
    expect(model.addImageUrl('https://example.com/c.png'), isNull);
    expect(model.addImageUrl('https://example.com/d.png'), isNotNull);
    await model.send();
    expect(repository.delivered.values.single.paths, hasLength(3));
  });

  test('admin starts a conversation with the other issue type', () async {
    await start(admin);
    final model = container.read(orderChatViewModelProvider(admin).notifier);
    model.setText('Nhà hàng cần xác nhận địa chỉ');
    await model.send();
    expect(repository.delivered.values.single.role, ChatRole.admin);
    expect(repository.delivered.values.single.issue, ChatIssueType.other);
  });

  test('historical order accepts a message and clears the draft', () async {
    await start(customer, closed: true);
    final provider = orderChatViewModelProvider(customer);
    final model = container.read(provider.notifier);
    model.setText('Vẫn giữ nội dung');
    expect(model.addImageUrl(_photoUrl), isNull);
    await model.send();
    expect(repository.sends, hasLength(1));
    expect(container.read(provider).draft.text, isEmpty);
    expect(container.read(provider).draft.imageUrls, isEmpty);
  });
}
