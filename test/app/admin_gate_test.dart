import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/app/admin_gate.dart';
import 'package:ordering_food_system/app/router.dart';
import 'package:ordering_food_system/features/auth/domain/entities/app_user.dart';
import 'package:ordering_food_system/features/auth/presentation/viewmodels/auth_providers.dart';

void main() {
  AppUser user({String role = 'admin', String status = 'active'}) => AppUser(
    id: 'uid',
    fullName: 'Test',
    email: 'test@example.com',
    phone: '0900000000',
    role: role,
    status: status,
  );

  Future<void> pumpGate(WidgetTester tester, AppUser? signedIn) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(signedIn)),
        ],
        child: MaterialApp(
          home: const AdminGate(child: Text('admin screen')),
          onGenerateRoute: (settings) =>
              MaterialPageRoute(builder: (_) => Text('route ${settings.name}')),
        ),
      ),
    );
  }

  testWidgets('active admin sees the admin screen', (tester) async {
    await pumpGate(tester, user());
    await tester.pumpAndSettle();

    expect(find.text('admin screen'), findsOneWidget);
  });

  testWidgets('signed-out user is sent to login', (tester) async {
    await pumpGate(tester, null);
    await tester.pumpAndSettle();

    expect(find.text('admin screen'), findsNothing);
    expect(find.text('route ${AppRoutes.login}'), findsOneWidget);
  });

  testWidgets('customer is sent to login', (tester) async {
    await pumpGate(tester, user(role: 'customer'));
    await tester.pumpAndSettle();

    expect(find.text('admin screen'), findsNothing);
    expect(find.text('route ${AppRoutes.login}'), findsOneWidget);
  });

  testWidgets('disabled admin is sent to login', (tester) async {
    await pumpGate(tester, user(status: 'disabled'));
    await tester.pumpAndSettle();

    expect(find.text('admin screen'), findsNothing);
  });
}
