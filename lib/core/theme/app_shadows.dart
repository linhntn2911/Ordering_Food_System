import 'package:flutter/material.dart';

abstract final class AppShadows {
  static const card = BoxShadow(
    color: Color(0x0D09051C),
    offset: Offset(0, 4),
    blurRadius: 20,
  );
  static const primary = BoxShadow(
    color: Color(0x2E53E88B),
    offset: Offset(0, 8),
    blurRadius: 20,
  );
}
