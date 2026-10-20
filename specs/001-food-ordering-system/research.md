# Firebase Foundation Research

## Decisions

- Use FlutterFire CLI for platform configuration because it creates the official `firebase_options.dart` and registers selected platforms against a real Firebase project.
- Use Cloud Firestore rather than SQLite because Customer and Admin devices require shared real-time data.
- Use Firebase Authentication UID as the ownership key for user documents and subcollections.
- Use repository interfaces so Firebase types do not leak into ViewModels or widgets.
- Use official package dependencies from the Firebase and Flutter publishers.
- Use Firebase Emulator Suite for rules testing after Firebase CLI initialization.

## Rejected Alternatives

- Hand-written Firebase API keys and app IDs: rejected because identifiers must come from the selected Firebase project.
- Calling Firestore from widgets: rejected because it violates MVVM and prevents repository substitution.
- Client-writable Admin role: rejected because navigation checks do not provide authorization.
- SharedPreferences for authentication tokens or business data: rejected because it is only for non-sensitive local configuration.
- SQLite as the primary database: rejected because it does not provide shared Customer/Admin synchronization without another backend.

## Open Configuration Inputs

- Firebase project ID.
- Final Android application ID if `com.example.ordering_food_system` is only a placeholder.
- Target platforms for the first configuration run; Android is the current baseline.
- Firestore region, which is effectively permanent after database creation and should be selected close to the target users.
