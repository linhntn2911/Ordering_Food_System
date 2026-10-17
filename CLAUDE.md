# Claude Project Instructions

Read `AGENTS.md` first. It is the shared engineering policy for every coding agent in this repository. Read `SPEC.md`, `.specify/memory/constitution.md`, and the active feature plan and tasks before making material changes.

<!-- SPECKIT START -->
For additional context about technologies, project structure, shell commands, and decisions, read the current feature plan under `specs/` and follow the installed `.claude/skills/speckit-*` workflow.
<!-- SPECKIT END -->

## Required Working Method

- Treat `specs/001-food-ordering-system/spec.md` as the canonical baseline specification and `SPEC.md` as its root mirror.
- For a new feature, update or create a bounded Spec Kit feature spec before planning implementation.
- Resolve consequential ambiguities in the specification. Put implementation choices in `plan.md`, then generate dependency-ordered `tasks.md`.
- Implement one independently testable user story at a time and verify it against Given/When/Then acceptance scenarios.
- Do not broaden scope beyond one restaurant, Customer/Admin roles, and COD-only ordering without an approved spec change.

## Implementation Guardrails

- Use Flutter MVVM with Riverpod dependency injection and immutable state.
- Use Riverpod only through the official `flutter_riverpod` dependency declared in `pubspec.yaml`. Never create local substitutes or reimplement Riverpod classes, providers, refs, notifiers, widgets, or runtime behavior. Application-specific providers and ViewModels must import and use the package API.
- Keep Firebase and SharedPreferences access behind repositories or data sources.
- Keep business logic out of widgets.
- Enforce authorization in Firebase rules and trusted backend code, not only in navigation.
- Send FCM messages from a trusted backend; never place server credentials in the client.
- Never edit generated `.g.dart` files manually.
- Follow Dart naming and formatting conventions even when the sample project does not.
- Read and enforce `docs/design_system.md`: Poppins, the Food Ninja green gradient, shared tokens, and light mode only.
- Reject new dark-theme branches, theme toggles, screen-local brand colors, and flattened screenshots used as UI controls.

## Verification

Before declaring work complete, run formatting, code generation when required, `flutter analyze`, and relevant `flutter test` suites. Report any check that cannot run and the exact reason. Compare the implementation with the active specification, plan, and tasks and close all required gaps.
