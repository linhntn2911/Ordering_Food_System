// File generated manually based on Firebase project ordering-food-system-65c7f.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.windows:
        return windows;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCV_4n_OcT9MKsg3LkXrViDpwiGhXFNEPo',
    appId: '1:455542165389:web:90fc3d8da4149f754937c4',
    messagingSenderId: '455542165389',
    projectId: 'ordering-food-system-65c7f',
    authDomain: 'ordering-food-system-65c7f.firebaseapp.com',
    storageBucket: 'ordering-food-system-65c7f.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCV_4n_OcT9MKsg3LkXrViDpwiGhXFNEPo',
    appId: '1:455542165389:android:90fc3d8da4149f754937c4',
    messagingSenderId: '455542165389',
    projectId: 'ordering-food-system-65c7f',
    storageBucket: 'ordering-food-system-65c7f.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCV_4n_OcT9MKsg3LkXrViDpwiGhXFNEPo',
    appId: '1:455542165389:ios:90fc3d8da4149f754937c4',
    messagingSenderId: '455542165389',
    projectId: 'ordering-food-system-65c7f',
    storageBucket: 'ordering-food-system-65c7f.firebasestorage.app',
    iosBundleId: 'com.example.orderingFoodSystem',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCV_4n_OcT9MKsg3LkXrViDpwiGhXFNEPo',
    appId: '1:455542165389:web:90fc3d8da4149f754937c4',
    messagingSenderId: '455542165389',
    projectId: 'ordering-food-system-65c7f',
    authDomain: 'ordering-food-system-65c7f.firebaseapp.com',
    storageBucket: 'ordering-food-system-65c7f.firebasestorage.app',
  );
}
