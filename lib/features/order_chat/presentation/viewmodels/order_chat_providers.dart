import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/firebase/firebase_providers.dart';
import '../../../order/domain/entities/food_order.dart';
import '../../../order/presentation/viewmodels/admin_order_list_view_model.dart';
import '../../data/repositories/firestore_order_chat_repository.dart';
import '../../domain/entities/chat_failure.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_role.dart';
import '../../domain/entities/order_chat.dart';
import '../../domain/repositories/order_chat_repository.dart';

export 'order_chat_view_model.dart' show orderChatViewModelProvider;

typedef ChatSession = ({String orderId, String userId, ChatRole role});

final generalChatModeProvider = Provider<bool>(
  (ref) => false,
  dependencies: [],
);

final generalChatRepositoryProvider = Provider<OrderChatRepository>(
  (ref) => FirestoreOrderChatRepository(
    ref.watch(firebaseFirestoreProvider),
    ref.watch(firebaseAuthProvider),
    ref.watch(firebaseStorageProvider),
    general: true,
  ),
);

Duration? _retryChatRead(int retryCount, Object error) =>
    error == ChatFailure.permissionDenied
    ? null
    : ProviderContainer.defaultRetry(retryCount, error);

final orderChatRepositoryProvider = Provider<OrderChatRepository>(
  (ref) => FirestoreOrderChatRepository(
    ref.watch(firebaseFirestoreProvider),
    ref.watch(firebaseAuthProvider),
    ref.watch(firebaseStorageProvider),
  ),
);

final orderChatStreamProvider = StreamProvider.autoDispose
    .family<OrderChat?, String>(
      (ref, id) => ref.watch(orderChatRepositoryProvider).watchChat(id),
      retry: _retryChatRead,
      dependencies: [orderChatRepositoryProvider],
    );

final chatOrderProvider = StreamProvider.autoDispose.family<FoodOrder, String>(
  (ref, id) => ref.watch(orderRepositoryProvider).watchOrder(id),
);

final chatMessagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, ({String orderId, int limit})>(
      (ref, query) => ref
          .watch(orderChatRepositoryProvider)
          .watchMessages(query.orderId, limit: query.limit),
      retry: _retryChatRead,
      dependencies: [orderChatRepositoryProvider],
    );

final customerUnreadChatProvider = StreamProvider.autoDispose
    .family<bool, String>(
      (ref, id) =>
          ref.watch(orderChatRepositoryProvider).watchCustomerHasUnread(id),
    );

final chatPhotoProvider = FutureProvider.autoDispose
    .family<Uint8List, ({String path, String userId})>(
      (ref, photo) =>
          ref.watch(orderChatRepositoryProvider).photoBytes(photo.path),
      dependencies: [orderChatRepositoryProvider],
    );
