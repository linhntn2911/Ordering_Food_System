import 'package:flutter/material.dart';

extension AppNavigationContextExtension on BuildContext {
  Future<T?> push<T extends Object?>(String routeName, {Object? extra}) {
    return Navigator.of(this).pushNamed<T>(routeName, arguments: extra);
  }

  void pop<T extends Object?>([T? result]) {
    Navigator.of(this).pop<T>(result);
  }
}

