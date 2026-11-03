import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/app/main_shell_controller.dart';

void main() {
  test('checkout success can select the Orders tab', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(mainShellTabProvider), MainShellTab.home);

    container.read(mainShellTabProvider.notifier).select(MainShellTab.orders);

    expect(container.read(mainShellTabProvider), MainShellTab.orders);
  });

  test('invalid tab indexes are ignored', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(mainShellTabProvider.notifier).select(99);

    expect(container.read(mainShellTabProvider), MainShellTab.home);
  });
}
