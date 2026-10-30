import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/app/app.dart';
import 'package:ordering_food_system/core/widgets/coming_soon_view.dart';
import 'package:ordering_food_system/features/menu/presentation/viewmodels/home_menu_view_model.dart';
import 'package:ordering_food_system/features/menu/presentation/viewmodels/menu_providers.dart';
import 'package:ordering_food_system/features/menu/presentation/views/home_view.dart';

import 'support/fake_menu_repository.dart';
import 'support/menu_fixtures.dart';

void main() {
  late FakeMenuRepository repository;

  setUp(() => repository = FakeMenuRepository());

  Future<void> pumpApp(WidgetTester tester) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [menuRepositoryProvider.overrideWithValue(repository)],
        child: const App(),
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

    for (final label in ['Trang chủ', 'Giỏ hàng', 'Đơn hàng', 'Tài khoản']) {
      expect(find.bySemanticsLabel(label), findsOneWidget);
    }
    expect(find.bySemanticsLabel(RegExp('Chat|Tin nhắn')), findsNothing);
    expect(find.byType(HomeView), findsOneWidget);
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
    expect(find.text(ComingSoonView.message), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('shell-tab-0')));
    await tester.pump();
    expect(container.read(homeMenuViewModelProvider).selectedCategoryId, 'com');
  });
}
