import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  SharedPreferencesService(this._prefs);
  final SharedPreferences _prefs;

  static const String _keyFcmToken = 'fcm_token';
  static const String _keyLastReadNotificationId = 'last_read_notification_id';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyIsFirstLaunch = 'is_first_launch';

  Future<void> setFcmToken(String token) async { await _prefs.setString(_keyFcmToken, token); }
  String? getFcmToken() => _prefs.getString(_keyFcmToken);
  Future<void> setLastReadNotificationId(String id) async { await _prefs.setString(_keyLastReadNotificationId, id); }
  String? getLastReadNotificationId() => _prefs.getString(_keyLastReadNotificationId);
  Future<void> setThemeMode(String mode) async { await _prefs.setString(_keyThemeMode, mode); }
  String getThemeMode() => _prefs.getString(_keyThemeMode) ?? 'system';
  Future<void> setIsFirstLaunch(bool value) async { await _prefs.setBool(_keyIsFirstLaunch, value); }
  bool isFirstLaunch() => _prefs.getBool(_keyIsFirstLaunch) ?? true;
  Future<void> clearAll() async { await _prefs.clear(); }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must be initialized in main.dart');
});

final sharedPreferencesServiceProvider = Provider<SharedPreferencesService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SharedPreferencesService(prefs);
});
