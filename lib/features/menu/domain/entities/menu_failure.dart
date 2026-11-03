enum MenuFailureType { permissionDenied, unavailable, unknown }

/// Domain error for menu data, free of Firebase types.
class MenuFailure implements Exception {
  const MenuFailure(this.type, [this.cause]);

  final MenuFailureType type;
  final Object? cause;

  @override
  String toString() => 'MenuFailure($type)';
}
