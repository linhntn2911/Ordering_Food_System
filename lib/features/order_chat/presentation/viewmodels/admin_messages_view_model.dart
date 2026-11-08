import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../domain/entities/chat_failure.dart';
import '../../domain/entities/order_chat.dart';
import 'order_chat_providers.dart';

class AdminMessagesViewModel extends Notifier<({bool general, int limit})> {
  @override
  ({bool general, int limit}) build() => (general: true, limit: 100);
  void select(bool general) => state = (general: general, limit: 100);
  void loadMore() => state = (general: state.general, limit: state.limit + 100);
}

final adminMessagesViewModelProvider =
    NotifierProvider.autoDispose<
      AdminMessagesViewModel,
      ({bool general, int limit})
    >(AdminMessagesViewModel.new);

final adminMessagesProvider = StreamProvider.autoDispose<List<OrderChat>>((
  ref,
) {
  final user = ref.watch(authStateProvider).value;
  if (user == null || !user.isActive || !user.isAdmin) {
    return Stream.error(ChatFailure.permissionDenied);
  }
  final state = ref.watch(adminMessagesViewModelProvider);
  final repository = ref.watch(
    state.general ? generalChatRepositoryProvider : orderChatRepositoryProvider,
  );
  return repository.watchAdminChats(limit: state.limit);
}, retry: (_, _) => null);

final generalChatUnreadProvider = StreamProvider.autoDispose<bool>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null || !user.isActive || !user.isCustomer) {
    return Stream.value(false);
  }
  return ref
      .watch(generalChatRepositoryProvider)
      .watchCustomerHasUnread(user.id);
});
