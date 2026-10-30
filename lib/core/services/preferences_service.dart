import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'SharedPreferences must be initialized before runApp',
  );
});

final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PreferencesService(prefs);
});

class PreferencesService {
  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keySavedLoginEmail = 'saved_login_email';

  /// Returns true if the user has completed or skipped the onboarding flow.
  bool get isOnboardingCompleted =>
      _prefs.getBool(_keyOnboardingCompleted) ?? false;

  /// Marks onboarding as completed.
  Future<bool> setOnboardingCompleted(bool value) {
    return _prefs.setBool(_keyOnboardingCompleted, value);
  }

  /// Remembers email for convenience on login screen (non-sensitive).
  String? get savedLoginEmail => _prefs.getString(_keySavedLoginEmail);

  Future<bool> setSavedLoginEmail(String email) {
    return _prefs.setString(_keySavedLoginEmail, email);
  }

  Future<bool> clearSavedLoginEmail() {
    return _prefs.remove(_keySavedLoginEmail);
  }
}
