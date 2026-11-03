import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/core/theme/app_theme.dart';
import 'package:ordering_food_system/features/menu/domain/entities/menu_option.dart';
import 'package:ordering_food_system/features/menu/presentation/viewmodels/menu_providers.dart';
import 'package:ordering_food_system/features/menu/presentation/views/home_view.dart';

import '../../../support/fake_menu_repository.dart';
import '../../../support/menu_fixtures.dart';

void main() {
  testWidgets('Home fits 320 dp at 1.3x text without overflow (SC-006)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repository = FakeMenuRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [menuRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: const HomeView(),
        ),
      ),
    );

    const longName =
        'Cơm chiên hải sản đặc biệt kiểu Dương Châu với tôm mực và rau củ';
    repository
      ..emitCategories([
        category(
          'com',
          name: 'Danh mục có tên rất dài để kiểm tra việc cắt chữ trên chip',
        ),
      ])
      ..emitItems([
        menuItem(
          'dai',
          name: longName,
          basePrice: 1250000,
          sizes: const [
            MenuOption(id: 's', name: 'Nhỏ', priceDelta: 0),
            MenuOption(id: 'l', name: 'Lớn', priceDelta: 350000),
          ],
          ratingAverage: 4.6,
          reviewCount: 1234,
        ),
      ])
      ..emitPopular([]);
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('1.250.000 – 1.600.000 ₫'), findsOneWidget);
  });
}
