# Food Ordering System Agent Guide

This file defines repository-wide instructions for coding agents and contributors.

## Sources of Truth

Read these files before changing product behavior:

1. `SPEC.md` and `specs/001-food-ordering-system/spec.md` for product scope and acceptance criteria.
2. `.specify/memory/constitution.md` for non-negotiable engineering principles.
3. The active feature `plan.md` and `tasks.md` after they are created.
4. `pubspec.yaml`, Firebase configuration, and current source code for the implemented baseline.

If documents conflict, use this order: the latest explicit human instruction, approved feature spec, constitution, plan, tasks, then existing implementation. Record any needed spec change before implementing behavior outside the approved scope.

## Spec Kit Workflow

Use the installed Spec Kit skills in this order:

1. `$speckit-constitution` once for project principles.
2. `$speckit-specify` for a bounded feature or material behavior change.
3. `$speckit-clarify` when requirements contain consequential ambiguity.
4. `$speckit-plan` for technical design.
5. `$speckit-checklist` for requirement quality gates.
6. `$speckit-tasks` for dependency-ordered implementation tasks.
7. `$speckit-analyze` before implementation.
8. `$speckit-implement` in user-story increments.
9. Converge by comparing code and tests with the approved spec until no required gaps remain.

Do not begin a substantial feature from a chat description alone. Update the feature spec, plan, and tasks first. Small repairs that preserve specified behavior may be implemented directly, but document any changed requirement.

<!-- SPECKIT START -->
For additional context about technologies, project structure, commands, and decisions, read the current feature plan under `specs/`.
<!-- SPECKIT END -->

## Product Boundaries

- One restaurant.
- Human roles: Customer and pre-provisioned Admin. Guest is an unauthenticated state.
- COD only.
- No driver application, GPS tracking, online payment, refunds, chat, marketplace behavior, or complex promotions.
- The required integrations are Firebase Authentication, Cloud Firestore, Firebase Cloud Messaging, Firebase Storage when images are uploaded, Riverpod, MVVM, and SharedPreferences.

## Architecture

Use feature-first MVVM. New application code should follow this target layout:

```text
lib/
├── app/
│   ├── app.dart
│   ├── bootstrap.dart
│   └── router.dart
├── core/
│   ├── config/
│   ├── errors/
│   ├── services/
│   ├── theme/
│   ├── utils/
│   └── widgets/
└── features/
    └── <feature>/
        ├── data/
        │   ├── models/
        │   ├── sources/
        │   └── repositories/
        ├── domain/
        │   ├── entities/
        │   └── repositories/
        └── presentation/
            ├── viewmodels/
            ├── views/
            └── widgets/
```

- **View**: renders immutable state, gathers input, and forwards user intent. Do not query Firebase or contain business rules.
- **ViewModel**: owns screen state and orchestration. Prefer Riverpod `Notifier` or `AsyncNotifier` and explicit methods such as `submitOrder()` or `cancelOrder()`.
- **Repository interface**: expresses feature operations without UI or Firebase types leaking into presentation.
- **Repository implementation/data source**: owns Firebase, SharedPreferences, mapping, transactions, and error translation.
- **Model/entity**: immutable, typed, serializable where required, and safe under missing or older Firestore fields.

The reviewed `Example-PRM393` project is a learning reference for `ProviderScope`, generated Riverpod providers, repository separation, and ViewModel-driven state. Do not copy its misspellings, mutable public lists, synchronous `SharedPreferences.getInstance()` misuse, swallowed exceptions, hard-coded store products, uppercase paths, or business logic in widgets.

## Riverpod Rules

- Riverpod MUST be consumed from the official `flutter_riverpod` package declared in `pubspec.yaml`. Run `flutter pub add flutter_riverpod` and `flutter pub get`; do not copy framework source into the repository.
- Coding agents MAY write application-specific provider, Notifier, AsyncNotifier, and ViewModel declarations using the official Riverpod API. They MUST NOT invent, imitate, vendor, or create project-local replacements for Riverpod types or behavior, including `Provider`, `Ref`, `Notifier`, `AsyncNotifier`, `ConsumerWidget`, or `ProviderScope`.
- Riverpod imports MUST use `package:flutter_riverpod/flutter_riverpod.dart`. If annotation-based generation is approved in the plan, add the official `riverpod_annotation`, `riverpod_generator`, and `build_runner` packages instead of hand-writing generated framework code.
- Wrap the root application in `ProviderScope`.
- Use providers for dependency injection; do not instantiate repositories inside widgets or `build()` methods.
- Prefer `ref.watch` for reactive dependencies and `ref.read` for commands.
- Expose loading, data, empty, and error states explicitly.
- Use `AsyncValue.guard` or equivalent error mapping for async actions, while preserving useful domain errors.
- Do not expose mutable collections from repositories or ViewModels.
- Keep provider names and files in Dart conventions: `cart_view_model.dart`, `CartViewModel`, `cartViewModelProvider`.
- Never edit generated `.g.dart` files. Regenerate them after annotated provider or model changes.

## Firebase and Data Rules

- Firebase Authentication UID is the identity key. Firebase Authentication owns session persistence; never copy raw ID, refresh, or session tokens into SharedPreferences.
- Registration validates full name, email, phone, a password of at least six characters, and matching confirmation before calling Firebase Authentication.
- Admin status must come from a trusted claim or protected server-managed record. Never trust a client-writable `role` field.
- Account disablement and the SRS rule of five failed attempts followed by a 15-minute lockout must be enforced by Firebase Authentication or trusted backend code, never by a resettable client counter alone.
- Firestore rules must enforce Customer ownership and Admin-only writes independently of UI checks.
- Use server timestamps for shared records.
- Use Firestore transactions or equivalent atomic operations for order creation, cancellation, status transitions, and rating aggregate updates.
- Copy item, price, option, recipient, address, delivery-distance, and delivery-fee snapshots into orders so history does not change when source records change.
- Recalculate delivery distance and fee whenever the checkout address changes. Apply 15,000 VND through 3 km, 20,000 VND above 3 km through 5 km, and 30,000 VND above 5 km through 8 km; block unknown distance and distances above 8 km.
- Treat distance, delivery fee, and order total as authoritative values validated by trusted code or protected server-managed data. Never accept client-provided totals without revalidation.
- Send registration welcome or verification email through Firebase Authentication or trusted backend code; never embed SMTP credentials in Flutter.
- Send FCM messages only from trusted backend code. The Flutter client registers tokens and handles messages; it must not contain service-account credentials or server keys.
- Store device tokens per user and device, refresh them, and deactivate invalid tokens.
- Use soft deletion or publication flags for menu data referenced by historical orders.
- Store only local non-sensitive configuration in SharedPreferences. Do not use it as the source of truth for roles, orders, prices, or authentication.

## UI and Design System

`docs/design_system.md` is the implementation authority for visual work. Read it before creating or reviewing any screen.

- Implement light mode only. Set `themeMode: ThemeMode.light`; do not add `darkTheme`, dark tokens, theme switching, or a theme preference in SharedPreferences.
- Use Poppins for all in-app text. Keep logo lettering as an exported asset.
- Use the Figma-derived primary gradient `#53E88B -> #15BE77`, primary text `#09051C`, and the semantic palette defined in the design-system document.
- Centralize colors, gradients, text styles, spacing, radii, shadows, and `ThemeData` under `lib/core/theme/`.
- Feature widgets must not hard-code brand hex values or create local copies of global visual tokens.
- Build reusable components for buttons, fields, food cards, quantity controls, status chips, order cards, loading states, empty states, error states, and navigation.
- Match approved Food Ninja light frames, but implement controls and layouts as Flutter widgets rather than flattened images.
- Use the 4-point spacing grid, standard 24-pixel screen padding, and responsive constraints from `docs/design_system.md`.
- Every data screen must handle loading, empty, error, retry, disabled, focused, and selected states where applicable.
- Customer and Admin flows must use the same design tokens so they read as one application.
- Preserve the screen ownership and Medium-or-higher complexity requirements in `SPEC.md`.

## Naming and Code Quality

- Use `snake_case.dart` file names, `PascalCase` types, and `lowerCamelCase` members.
- Use `repository`, never the misspelling `reposistory`.
- Keep one main public type per file unless small related state types improve readability.
- Prefer immutable state and `copyWith`-style updates.
- Do not catch an exception only to return `false`; translate it to a typed failure or expose it in ViewModel state.
- Do not use `print` for production logging.
- Do not commit secrets, service-account files, FCM server keys, or machine-specific paths.
- Keep generated platform files and Firebase-generated configuration separate from business code.

## Commands

Run from the repository root as appropriate:

```powershell
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format lib test
flutter analyze
flutter test
```

Use `flutterfire configure` only when the Firebase project and target platforms are known. Do not invent Firebase IDs or commit secrets.

## Testing and Completion Gates

- Unit-test ViewModel decisions, repository mapping, price calculations, validation, and status transitions.
- Widget-test critical forms and screen states.
- Use Firebase Emulator Suite or rules tests for ownership, Admin authorization, order races, and notification-trigger inputs where practical.
- A feature is done only when its acceptance scenarios pass, analyzer has no errors, tests pass, loading/error/empty states exist, security rules are updated, and the related spec/plan/tasks reflect the final behavior.
- Each member must be able to demonstrate at least three owned Medium-or-higher screens; shared infrastructure does not replace this requirement.

## Change Discipline

- Keep changes scoped to one user story or coherent cross-cutting foundation.
- Update generated code only by running its generator.
- When changing Firestore shape, update models, converters, rules, indexes, seed data, and migration notes together.
- When changing an order status or business rule, update Customer UI, Admin UI, notification behavior, tests, and documentation together.
- Record out-of-scope ideas as future work instead of silently expanding the release.
