// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ordering_food_system/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('Member3 Navigation Hub and Cart preloaded smoke test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: FoodOrderingApp()));

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
