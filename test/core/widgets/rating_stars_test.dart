import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/core/widgets/rating_stars.dart';

void main() {
  Future<List<IconData?>> icons(WidgetTester tester, double rating) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(child: RatingStars(rating: rating)),
      ),
    );
    return [
      for (final icon in tester.widgetList<Icon>(find.byType(Icon))) icon.icon,
    ];
  }

  testWidgets('no rating shows five outlined stars', (tester) async {
    expect(await icons(tester, 0), List.filled(5, Icons.star_outline_rounded));
  });

  testWidgets('4.5 shows four full stars and a half star', (tester) async {
    expect(await icons(tester, 4.5), [
      ...List.filled(4, Icons.star_rounded),
      Icons.star_half_rounded,
    ]);
  });

  testWidgets('4.3 rounds down to four full stars', (tester) async {
    expect(await icons(tester, 4.3), [
      ...List.filled(4, Icons.star_rounded),
      Icons.star_outline_rounded,
    ]);
  });

  testWidgets('5 shows five full stars', (tester) async {
    expect(await icons(tester, 5), List.filled(5, Icons.star_rounded));
  });

  testWidgets('reads as one label with a decimal comma', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: RatingStars(rating: 4.5))),
    );
    expect(find.bySemanticsLabel('Đánh giá 4,5 trên 5'), findsOneWidget);
  });

  testWidgets('uses the requested size', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: RatingStars(rating: 3, size: 24))),
    );
    expect(tester.widget<Icon>(find.byType(Icon).first).size, 24);
  });
}
