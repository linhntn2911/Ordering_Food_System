import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract final class MainShellTab {
  static const home = 0;
  static const cart = 1;
  static const orders = 2;
  static const profile = 3;
}

class MainShellTabController extends Notifier<int> {
  @override
  int build() => MainShellTab.home;

  void select(int tab) {
    if (tab < MainShellTab.home || tab > MainShellTab.profile) return;
    state = tab;
  }
}

final mainShellTabProvider = NotifierProvider<MainShellTabController, int>(
  MainShellTabController.new,
);
