import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/features/auth/domain/entities/app_user.dart';
import 'package:ordering_food_system/features/auth/presentation/viewmodels/auth_providers.dart';
import 'package:ordering_food_system/features/order/domain/entities/order_status.dart';
import 'package:ordering_food_system/features/order_chat/domain/entities/chat_failure.dart';
import 'package:ordering_food_system/features/order_chat/domain/entities/chat_message.dart';
import 'package:ordering_food_system/features/order_chat/domain/entities/chat_role.dart';
import 'package:ordering_food_system/features/order_chat/presentation/viewmodels/order_chat_providers.dart';
import 'package:ordering_food_system/features/order_chat/presentation/views/order_chat_screen.dart';

import '../../../support/fake_order_chat_repository.dart';
import '../../../support/order_chat_order_fixture.dart';

const _order = 'order-one';
const _user = AppUser(
  id: 'customer',
  fullName: 'Khách hàng',
  email: '',
  phone: '',
  role: 'customer',
  status: 'active',
);

const _png =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jGZkAAAAASUVORK5CYII=';

Widget _app(FakeOrderChatRepository repository, {bool closed = false}) =>
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => Stream.value(_user)),
        orderChatRepositoryProvider.overrideWithValue(repository),
        chatOrderProvider(_order).overrideWith(
          (ref) => Stream.value(
            chatOrderFixture(
              status: closed ? OrderStatus.cancelled : OrderStatus.preparing,
              updatedAt: DateTime.now().subtract(const Duration(hours: 25)),
            ),
          ),
        ),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: const OrderChatScreen(
          args: OrderChatArgs(_order, ChatRole.customer),
        ),
      ),
    );

ChatMessage _reply() => ChatMessage(
  id: 'reply',
  senderId: 'admin',
  senderRole: ChatRole.admin,
  text: 'Nhà hàng đã nhận được tin nhắn',
  imagePaths: const [],
  createdAt: DateTime(2026, 11, 1),
);

void main() {
  late FakeOrderChatRepository repository;
  setUp(() => repository = FakeOrderChatRepository());
  tearDown(() => repository.close());

  testWidgets('loads chat and sends the first message with a photo at 320 dp', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 680);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(repository));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Hãy mô tả vấn đề của bạn'), findsOneWidget);
    final send = find.byKey(const ValueKey('chat-send'));
    expect(tester.widget<IconButton>(send).onPressed, isNull);
    expect(tester.getSize(send).height, greaterThanOrEqualTo(48));
    expect(
      tester.getSize(find.byKey(const ValueKey('chat-add-photo'))).height,
      greaterThanOrEqualTo(48),
    );

    expect(find.byKey(const ValueKey('chat-issue-picker')), findsNothing);
    await tester.enterText(
      find.byKey(const ValueKey('chat-text')),
      'Đơn đến trễ',
    );
    await tester.tap(find.byKey(const ValueKey('chat-add-photo')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('chat-image-url')),
      'https://example.com/anh.jpg',
    );
    await tester.tap(find.text('Thêm ảnh'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Gỡ ảnh 1'), findsOneWidget);

    await tester.tap(send);
    await tester.pumpAndSettle();
    expect(repository.delivered.values.single.paths, [
      'https://example.com/anh.jpg',
    ]);
    expect(repository.delivered.values.single.text, 'Đơn đến trễ');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'marks incoming messages read and displays reply without reload',
    (tester) async {
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      repository.emitChat(
        chatFixture(unreadByCustomer: true, lastMessageId: 'reply'),
      );
      await tester.pumpAndSettle();
      expect(repository.reads, isEmpty);
      repository.emitMessages([_reply()]);
      await tester.pumpAndSettle();
      expect(find.text('Ngô Chicken'), findsOneWidget);
      expect(find.text('Nhà hàng đã nhận được tin nhắn'), findsOneWidget);
      expect(repository.reads.single.role, ChatRole.customer);
    },
  );

  testWidgets('closed chat displays history and replaces the composer', (
    tester,
  ) async {
    repository.chat = chatFixture();
    repository.messages = [_reply()];
    await tester.pumpWidget(_app(repository, closed: true));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('chat-closed')), findsOneWidget);
    expect(find.byKey(const ValueKey('chat-composer')), findsNothing);
    expect(find.text('Nhà hàng đã nhận được tin nhắn'), findsOneWidget);
  });

  testWidgets(
    'opens the selected photo and swipes through the message attachments',
    (tester) async {
      const paths = [
        'order_chats/order-one/photos/0.jpg',
        'order_chats/order-one/photos/1.jpg',
      ];
      repository.photoData = base64Decode(_png);
      repository.chat = chatFixture();
      repository.messages = [
        ChatMessage(
          id: 'photos',
          senderId: 'admin',
          senderRole: ChatRole.admin,
          text: '',
          imagePaths: paths,
          createdAt: DateTime(2026, 11, 1),
        ),
      ];
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();

      final firstPhoto = find.byKey(const ValueKey('chat-photo-photos-0'));
      expect(tester.getSize(firstPhoto), const Size(48, 48));
      await tester.tap(firstPhoto);
      await tester.pumpAndSettle();
      expect(find.text('Ảnh 1/2'), findsOneWidget);
      await tester.drag(find.byType(PageView), const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(find.text('Ảnh 2/2'), findsOneWidget);
      expect(repository.downloadedPhotos.toSet(), paths.toSet());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('permission failure exposes a safe back action', (tester) async {
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    repository.failChat(ChatFailure.permissionDenied);
    await tester.pumpAndSettle();
    expect(find.text(ChatFailure.permissionDenied.message), findsOneWidget);
    expect(find.text('Quay lại'), findsOneWidget);
    expect(find.byKey(const ValueKey('chat-send')), findsNothing);
  });
}
