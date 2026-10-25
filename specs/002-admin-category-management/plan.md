# Implementation Plan: Admin Category Management

Use feature-first MVVM. A Firestore repository maps immutable category models, an official Riverpod `StreamProvider` exposes the ordered list, and an official Riverpod `AsyncNotifier` coordinates writes. The View only renders state and forwards user intent. Firestore rules remain the authority for Admin access.

The light-only shared theme is introduced under `lib/core/theme/` and follows the Food Ninja tokens in `docs/design_system.md`. The temporary app entry opens Category Management directly; this does not bypass Firebase authorization.

Until a Firebase Web app is registered, debug Chrome builds use an explicitly labelled in-memory Web Preview repository. Android continues to use the real Firebase project. Release builds never fall back to preview data.

Verification consists of repository-replaceable widget tests, ViewModel validation tests, `flutter analyze`, and `flutter test`.
