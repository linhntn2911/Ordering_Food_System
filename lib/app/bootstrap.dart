import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/services/preferences_service.dart';
import '../firebase_options.dart';
import 'app.dart';

const _useFirestoreEmulator = bool.fromEnvironment('USE_FIRESTORE_EMULATOR');
const _firestoreEmulatorPort = 8080;
const _authEmulatorPort = 9099;

/// Emulator-only options for web. A `demo-` project ID never reaches real
/// Firebase services, so no real identifiers are needed.
const _webEmulatorOptions = FirebaseOptions(
  apiKey: 'demo-api-key',
  appId: '1:000000000000:web:0000000000000000000000',
  messagingSenderId: '000000000000',
  projectId: 'demo-ordering',
  storageBucket: 'demo-ordering.appspot.com',
);

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(options: _firebaseOptions());
    if (_useFirestoreEmulator) {
      FirebaseFirestore.instance.useFirestoreEmulator(
        _emulatorHost(),
        _firestoreEmulatorPort,
      );
      await FirebaseAuth.instance.useAuthEmulator(
        _emulatorHost(),
        _authEmulatorPort,
      );
    }
  } catch (e) {
    debugPrint('Firebase initialization warning: $e');
  }

  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const FoodOrderingApp(),
    ),
  );
}

FirebaseOptions _firebaseOptions() {
  if (kIsWeb && _useFirestoreEmulator) {
    return _webEmulatorOptions;
  }
  return DefaultFirebaseOptions.currentPlatform;
}

/// The Android emulator reaches the host machine through 10.0.2.2.
String _emulatorHost() {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return '10.0.2.2';
  }
  return 'localhost';
}
