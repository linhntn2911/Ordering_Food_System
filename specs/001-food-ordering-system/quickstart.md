# Firebase Connection Quickstart

## Prerequisites

- Confirm the Firebase project ID and Android application ID.
- Install Firebase CLI and FlutterFire CLI.
- Enable Email/Password Authentication and create the default Cloud Firestore database.

## Configure

Run from the repository root:

```powershell
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
```

Select Android for the first configuration. Select the confirmed Firebase project and allow FlutterFire to generate `lib/firebase_options.dart` and the Android configuration.

## Verify

```powershell
flutter pub get
dart format lib test
flutter analyze
flutter test
```

After Firebase CLI initialization, validate rules with the emulator before deployment:

```powershell
firebase emulators:start --only auth,firestore
```

## Expected Result

- `Firebase.initializeApp` completes before the application is rendered.
- Official Riverpod providers expose initialized `FirebaseAuth` and `FirebaseFirestore` instances.
- Reading the published menu succeeds according to Firestore rules.
- Unauthorized Customer access to another user's protected path is rejected.
