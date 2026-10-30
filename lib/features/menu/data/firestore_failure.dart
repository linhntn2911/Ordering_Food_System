import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entities/menu_failure.dart';

/// Maps Firestore and unknown errors from menu and review streams to
/// [MenuFailure].
MenuFailure menuFailureFrom(Object error) {
  if (error is MenuFailure) {
    return error;
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' => MenuFailure(
        MenuFailureType.permissionDenied,
        error,
      ),
      'unavailable' => MenuFailure(MenuFailureType.unavailable, error),
      _ => MenuFailure(MenuFailureType.unknown, error),
    };
  }
  return MenuFailure(MenuFailureType.unknown, error);
}
