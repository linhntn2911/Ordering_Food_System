import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/features/order/presentation/viewmodels/admin_order_list_view_model.dart';
import 'package:ordering_food_system/features/order_chat/presentation/viewmodels/order_chat_providers.dart';

import '../../../support/fake_order_chat_repository.dart';
import '../../../support/order_chat_order_fixture.dart';

void main() {
  test('hasChat joins chat IDs with the existing order filters', () async {
    final repository = FakeOrderChatRepository()
      ..adminChats = [chatFixture(unreadByAdmin: true)];
    final container = ProviderContainer(
      overrides: [
        orderChatRepositoryProvider.overrideWithValue(repository),
        adminOrdersProvider.overrideWith(
          (ref) => Stream.value([
            chatOrderFixture(),
            chatOrderFixture(id: 'order-two'),
          ]),
        ),
      ],
    );
    addTearDown(repository.close);
    addTearDown(container.dispose);
    container.listen(filteredAdminOrdersProvider, (_, _) {});
    await container.read(adminOrdersProvider.future);
    expect(
      container.read(filteredAdminOrdersProvider).requireValue,
      hasLength(2),
    );

    final filter = container.read(adminOrderListFilterProvider.notifier);
    filter.setHasChat(true);
    final chats = await container.read(adminOrderChatsProvider.future);
    expect(chats['order-one']?.unreadByAdmin, isTrue);
    expect(
      container.read(filteredAdminOrdersProvider).requireValue.single.id,
      'order-one',
    );
    filter.setQuery('missing');
    expect(container.read(filteredAdminOrdersProvider).requireValue, isEmpty);
    filter.clearFilters();
    expect(
      container.read(filteredAdminOrdersProvider).requireValue,
      hasLength(2),
    );
  });
}
