import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/core/theme/app_theme.dart';
import 'package:ordering_food_system/core/widgets/food_card.dart';
import 'package:ordering_food_system/features/menu/domain/entities/menu_item.dart';
import 'package:ordering_food_system/features/menu/domain/entities/menu_option.dart';

import '../../../support/menu_fixtures.dart';

Widget _wrap(MenuItem item, {VoidCallback? onTap}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: FoodCard(item: item, onTap: onTap),
      ),
    ),
  );
}

void main() {
  testWidgets('shows a single price and rating', (tester) async {
    await tester.pumpWidget(
      _wrap(menuItem('a', name: 'Cơm gà', ratingAverage: 4.6, reviewCount: 23)),
    );

    expect(find.text('Cơm gà'), findsOneWidget);
    expect(find.text('45.000 ₫'), findsOneWidget);
    expect(find.text('4,6 (23)'), findsOneWidget);
    expect(find.text('Hết hàng'), findsNothing);
  });

  testWidgets('shows a price range for sizes with different prices', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        menuItem(
          'a',
          sizes: const [
            MenuOption(id: 's', name: 'Nhỏ', priceDelta: 0),
            MenuOption(id: 'l', name: 'Lớn', priceDelta: 20000),
          ],
        ),
      ),
    );

    expect(find.text('45.000 – 65.000 ₫'), findsOneWidget);
  });

  testWidgets('shows no-rating text, sold-out label and placeholder', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(menuItem('a', isAvailable: false)));

    expect(find.text('Chưa có đánh giá'), findsOneWidget);
    expect(find.text('Hết hàng'), findsOneWidget);
    expect(find.byType(FoodImagePlaceholder), findsOneWidget);
  });

  testWidgets('exposes one semantic button with name, price and status', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        menuItem('a', name: 'Phở', isAvailable: false),
        onTap: () => tapped = true,
      ),
    );

    expect(
      find.bySemanticsLabel(RegExp(r'^Phở, 45\.000.*₫, .*Hết hàng$')),
      findsOneWidget,
    );

    final size = tester.getSize(find.byType(FoodCard));
    expect(size.height, greaterThanOrEqualTo(48));

    await tester.tap(find.byType(FoodCard));
    expect(tapped, isTrue);
    handle.dispose();
  });
}
