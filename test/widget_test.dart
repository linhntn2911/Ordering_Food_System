import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/app/app.dart';
import 'package:ordering_food_system/app/main_shell.dart';
import 'package:ordering_food_system/features/auth/data/models/user_model.dart';
import 'package:ordering_food_system/features/auth/domain/entities/app_user.dart';
import 'package:ordering_food_system/features/auth/presentation/viewmodels/auth_providers.dart';
import 'package:ordering_food_system/features/cart/presentation/views/cart_screen.dart';
import 'package:ordering_food_system/features/cart/presentation/views/member3_navigation_hub.dart';
import 'package:ordering_food_system/features/menu/presentation/viewmodels/home_menu_view_model.dart';
import 'package:ordering_food_system/features/menu/presentation/viewmodels/menu_providers.dart';
import 'package:ordering_food_system/features/menu/presentation/views/home_view.dart';

import 'support/fake_menu_repository.dart';
import 'support/menu_fixtures.dart';

void main() {
  late FakeMenuRepository repository;

  setUp(() => repository = FakeMenuRepository());

  const customer = AppUser(
    id: 'customer_1',
    fullName: 'Khách hàng',
    email: 'customer@example.com',
    phone: '0900000002',
    role: 'customer',
    status: 'active',
  );

  Future<void> pumpApp(WidgetTester tester, {AppUser? user = customer}) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          menuRepositoryProvider.overrideWithValue(repository),
          authStateProvider.overrideWith((ref) => Stream.value(user)),
        ],
        child: const FoodOrderingApp(initialHome: MainShell()),
      ),
    );
  }

  testWidgets('App uses the single light theme', (tester) async {
    await pumpApp(tester);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);
    expect(app.darkTheme, isNull);
    expect(app.theme?.brightness, Brightness.light);
  });

  testWidgets('bottom navigation has four tabs and no chat (FR-018)', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.pump();

    for (final label in ['Trang chủ', 'Giỏ hàng', 'Đơn hàng', 'Tài khoản']) {
      expect(find.bySemanticsLabel(label), findsOneWidget);
    }
    expect(find.bySemanticsLabel(RegExp('Chat|Tin nhắn')), findsNothing);
    expect(find.byType(HomeView), findsOneWidget);
  });

  testWidgets('signed-out users do not see the Cart tab', (tester) async {
    await pumpApp(tester, user: null);
    await tester.pump();

    expect(find.byKey(const ValueKey('shell-tab-1')), findsNothing);
    expect(find.bySemanticsLabel('Giỏ hàng'), findsNothing);
    for (final label in ['Trang chủ', 'Đơn hàng', 'Tài khoản']) {
      expect(find.bySemanticsLabel(label), findsOneWidget);
    }
  });

  testWidgets('signed-out Orders tab offers Go to Login', (tester) async {
    await pumpApp(tester, user: null);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('shell-tab-2')));
    await tester.pump();

    expect(find.text('Lịch sử đơn hàng'), findsOneWidget);
    expect(find.text('Go to Login'), findsWidgets);
    expect(find.text('Chưa có đơn hàng'), findsNothing);
  });

  testWidgets('switching tabs keeps the Home selection (FR-018, FR-019)', (
    tester,
  ) async {
    await pumpApp(tester);
    repository
      ..emitCategories([category('com', name: 'Cơm')])
      ..emitItems([menuItem('com-ga', name: 'Cơm gà')])
      ..emitPopular([]);
    await tester.pump();
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeView)),
    );
    container.read(homeMenuViewModelProvider.notifier).selectCategory('com');
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('shell-tab-1')));
    await tester.pump();
    expect(find.byType(CartScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('shell-tab-0')));
    await tester.pump();
    expect(container.read(homeMenuViewModelProvider).selectedCategoryId, 'com');
  });

  group('AppUser & UserModel Tests', () {
    test('AppUser role and status helpers return expected flags', () {
      const customer = AppUser(
        id: 'user_1',
        fullName: 'Nguyen Van A',
        email: 'customer@example.com',
        phone: '0912345678',
        role: 'customer',
        status: 'active',
      );

      expect(customer.isAdmin, isFalse);
      expect(customer.isCustomer, isTrue);
      expect(customer.isActive, isTrue);
      expect(customer.isDisabled, isFalse);

      const admin = AppUser(
        id: 'admin_1',
        fullName: 'Admin User',
        email: 'admin@foodninja.vn',
        phone: '0988888888',
        role: 'admin',
        status: 'active',
      );

      expect(admin.isAdmin, isTrue);
      expect(admin.isCustomer, isFalse);
      expect(admin.isActive, isTrue);
      expect(admin.isDisabled, isFalse);

      const disabledUser = AppUser(
        id: 'user_2',
        fullName: 'Disabled User',
        email: 'disabled@example.com',
        phone: '0900000000',
        role: 'customer',
        status: 'disabled',
      );

      expect(disabledUser.isActive, isFalse);
      expect(disabledUser.isDisabled, isTrue);
    });

    test('UserModel converts to and from AppUser entity properly', () {
      final now = DateTime.now();
      final model = UserModel(
        id: 'user_thai',
        fullName: 'Thai Dang Quang',
        email: 'thai@example.com',
        phone: '0987654321',
        avatarUrl: 'https://example.com/avatar.png',
        role: 'customer',
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );

      final entity = model.toEntity();
      expect(entity.id, equals('user_thai'));
      expect(entity.fullName, equals('Thai Dang Quang'));
      expect(entity.email, equals('thai@example.com'));
      expect(entity.phone, equals('0987654321'));
      expect(entity.avatarUrl, equals('https://example.com/avatar.png'));
      expect(entity.role, equals('customer'));
      expect(entity.status, equals('active'));

      final fromEntity = UserModel.fromEntity(entity);
      expect(fromEntity.id, equals(model.id));
      expect(fromEntity.fullName, equals(model.fullName));
      expect(fromEntity.email, equals(model.email));
    });
  });

  testWidgets('Member3 Navigation Hub and Cart preloaded smoke test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FoodOrderingApp(initialHome: Member3NavigationHub()),
      ),
    );

    // Initial pump and settle
    await tester.pumpAndSettle();

    // Verify AppBar title of CartScreen
    expect(find.text('Giỏ hàng của bạn'), findsOneWidget);

    // Verify toolbar
    expect(find.text('Chọn tất cả'), findsOneWidget);

    // Verify preloaded mock food items
    expect(find.text('Gà sốt cay ngọt Hàn Quốc'), findsOneWidget);
    expect(find.text('Cơm rang gà chiên mắm tỏi'), findsOneWidget);

    // Verify Bottom Navigation Bar tabs
    expect(find.text('Giỏ hàng'), findsOneWidget);
    expect(find.text('Thanh toán'), findsOneWidget);
    expect(find.text('Sổ địa chỉ'), findsOneWidget);

    // Tap on 'Sổ địa chỉ' tab
    await tester.tap(find.text('Sổ địa chỉ'));
    await tester.pumpAndSettle();

    // Verify AddressListScreen is displayed with preloaded default address
    expect(find.text('Sổ địa chỉ'), findsWidgets);
    expect(find.textContaining('123 Lê Lợi'), findsOneWidget);
    expect(find.text('Mặc định'), findsOneWidget);
  });
}
