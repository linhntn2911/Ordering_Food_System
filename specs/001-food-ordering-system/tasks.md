# Tasks: Firebase Data Foundation

## Phase 1: Setup

- [x] T001 Document Firebase foundation decisions in `specs/001-food-ordering-system/plan.md`.
- [x] T002 Document Firestore relationships in `specs/001-food-ordering-system/data-model.md`.
- [x] T003 Add official Firebase and SharedPreferences dependencies to `pubspec.yaml` and resolve `pubspec.lock`.
- [ ] T004 Confirm Firebase project ID, Android application ID, and first target platform.
- [ ] T005 Generate official platform configuration with `flutterfire configure`.

## Phase 2: Foundational Data Layer

- [x] T006 Create `docs/database_schema.md` with collections, fields, ownership, and example documents.
- [x] T007 Create deny-by-default Firestore rules in `firestore.rules`.
- [x] T008 Create required index declarations in `firestore.indexes.json`.
- [x] T009 Create Firebase service providers in `lib/core/firebase/firebase_providers.dart`.
- [x] T010 Create collection path constants in `lib/core/firebase/firestore_paths.dart`.
- [ ] T011 Initialize Firebase and ProviderScope through `lib/app/bootstrap.dart` and `lib/main.dart` after T005.

## Phase 3: Menu Read Vertical Slice

- [x] T012 [US1] Create immutable menu entity in `lib/features/menu/domain/entities/menu_item.dart`.
- [x] T013 [US1] Create menu repository contract in `lib/features/menu/domain/repositories/menu_repository.dart`.
- [x] T014 [US1] Create Firestore menu model and converter in `lib/features/menu/data/models/menu_item_model.dart`.
- [x] T015 [US1] Create Firestore repository implementation in `lib/features/menu/data/repositories/firestore_menu_repository.dart`.
- [x] T016 [US1] Expose menu repository and published-menu stream through official Riverpod providers.

## Phase 4: Verification

- [x] T017 Run formatting and `flutter analyze`.
- [x] T018 Run existing Flutter tests.
- [ ] T019 Validate public menu reads, Customer ownership, and Admin writes with Firebase Emulator Suite.
- [ ] T020 Record the confirmed project ID and deployment commands without committing credentials.

## Dependency Order

T003 can proceed immediately. T004 blocks T005. T005 blocks runtime initialization in T011. T006-T010 and T012-T016 can be implemented without a cloud project. T019 requires Firebase CLI initialization.
