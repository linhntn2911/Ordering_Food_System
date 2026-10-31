import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oder_food/core/services/shared_preferences_service.dart';

class FirebaseMessagingService {
  FirebaseMessagingService(this._messaging, this._prefsService);
  final FirebaseMessaging _messaging;
  final SharedPreferencesService _prefsService;

  Future<void> initialize() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    final token = await _messaging.getToken();
    if (token != null) {
      await _prefsService.setFcmToken(token);
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Handle foreground messages
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle notification opened
    });
  }

  Future<String?> getToken() => _messaging.getToken();
}

final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) => FirebaseMessaging.instance);
final firebaseMessagingServiceProvider = Provider<FirebaseMessagingService>((ref) {
  final messaging = ref.watch(firebaseMessagingProvider);
  final prefsService = ref.watch(sharedPreferencesServiceProvider);
  return FirebaseMessagingService(messaging, prefsService);
});
