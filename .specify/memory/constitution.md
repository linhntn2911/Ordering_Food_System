# Food Ordering System Constitution

## Core Principles

### I. Specification Before Implementation

Every material feature begins with an approved, independently testable user story and measurable acceptance scenarios. Product behavior belongs in the specification; technology decisions belong in the plan; executable work belongs in tasks. Implementation must converge on those artifacts instead of silently redefining them.

### II. MVVM and Riverpod Boundaries

Views render state and forward intent. ViewModels coordinate workflows and publish immutable state. Repository interfaces define data capabilities, and repository implementations own Firebase or local persistence. Riverpod provides state management and dependency injection. Business logic, Firebase calls, and repository construction are forbidden in widgets.

### III. Server-Enforced Data Integrity and Security

Authentication, ownership, and Admin authority must be enforced by Firebase rules and trusted backend code. Order creation, cancellation, status transitions, and rating aggregation require atomic validation. No client may assign itself an Admin role or send privileged FCM messages. Secrets never enter source control.

### IV. Independently Demonstrable User Stories

Each user story must produce a demonstrable increment with its own acceptance evidence. Each of five members owns at least three Medium-or-higher screens. Shared foundations enable those screens but do not count as substitutes. Cross-feature work must preserve independent testing of primary journeys.

### V. Consistent and Verifiable Quality

The app uses one design system and reusable components. Async screens include loading, empty, error, and retry behavior. Critical domain rules and ViewModels receive automated tests, authorization receives rules or emulator verification, and `flutter analyze` must pass before completion. Generated files are produced by tools and never hand-edited.

### VI. Light-Only Food Ninja Design Fidelity

All Customer and Admin screens use one shared light theme derived from the Pixel True Food Ninja kit. The green `#53E88B -> #15BE77` gradient, Poppins typography, semantic color tokens, spacing, radii, shadows, and reusable components are centralized. Dark mode, theme toggles, local competing tokens, and flattened screenshots used as controls are prohibited for this release.

## Product and Technology Constraints

The release is a single-restaurant Flutter mobile application with Guest, Customer, and pre-provisioned Admin experiences. It uses COD only and excludes payment gateways, driver accounts, GPS tracking, chat, multi-restaurant marketplace behavior, and complex promotions.

Firebase Authentication provides identity, Cloud Firestore is the shared database, Firebase Cloud Messaging provides push notifications, Firebase Storage supports uploaded images, Riverpod manages state and dependencies, MVVM separates responsibilities, and SharedPreferences stores only non-sensitive local configuration.

## Development Workflow and Gates

The project follows constitution -> specify -> clarify when needed -> plan -> checklist -> tasks -> analyze -> implement -> converge. Each pull request or reviewable change must identify its user story, update affected artifacts, keep schema and security rules consistent, and include verification evidence. New dependencies require a documented reason in the plan.

## Governance

This constitution overrides informal conventions and sample-code patterns. Amendments require an explicit rationale, version change, and updates to affected specifications, plans, tasks, and migration notes. Reviewers must verify architectural boundaries, security, scope, screen ownership, and test evidence before accepting a feature.

**Version**: 1.1.0 | **Ratified**: 2026-10-17 | **Last Amended**: 2026-10-17
