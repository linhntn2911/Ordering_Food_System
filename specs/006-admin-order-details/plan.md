# Implementation Plan: Admin Order Details

- Extend immutable order entities with item snapshots, status events, and safe optional detail fields.
- Extend `OrderRepository` with detail streams and an atomic status-transition command.
- Implement Firestore converters, transaction logic, preview state, and security rules.
- Build Riverpod providers/ViewModel and a responsive Food Ninja light detail screen.
- Connect order cards to details and verify transition validation and widget behavior.

