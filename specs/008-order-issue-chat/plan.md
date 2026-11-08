# Implementation Plan: Order-Issue Chat

**Branch**: `008-order-issue-chat` | **Date**: 2026-11-01 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/008-order-issue-chat/spec.md`

## Summary

Customers and Admins exchange text and photo messages about one order. Each order has at most one conversation, stored in `order_chats/{orderId}` with a `messages` subcollection; new image attachments are stored as HTTPS URLs, while existing Storage references remain readable. Sends run in a Firestore transaction with device-generated message IDs, so the first message from either side creates the conversation exactly once and retries never duplicate. Chat has no sending deadline: both roles can start or continue a conversation after any terminal status. Firestore and Storage enforce participant authorization without time gates. Admins find conversations through a "Tin mới" badge and a "Có tin nhắn" filter on the existing Admin order list; Customers see unread dots on the order and the Orders tab. Push notifications are deferred until a trusted backend exists. One shared `OrderChatScreen` serves both roles.

## Technical Context

**Language/Version**: Dart 3 / Flutter (stable channel used by the repo)

**Primary Dependencies**: `flutter_riverpod` ^3.4.3, `cloud_firestore` ^7.0.0, `firebase_storage` ^14.0.0, `firebase_auth` ^7.0.0 (all already in `pubspec.yaml`; no new packages)

**Storage**: Cloud Firestore (`order_chats`, `order_chats/{id}/messages`), Firebase Storage for legacy attachments (`order_chats/{orderId}/{messageId}/{index}.jpg`)

**Testing**: `flutter_test` unit and widget tests with fake repositories; `@firebase/rules-unit-testing` emulator tests for Firestore and Storage rules in `tests/firestore_rules`

**Target Platform**: Android first, Chrome (web) for development; iOS-compatible code where practical

**Project Type**: Mobile app (Flutter MVVM) with Firebase backend services

**Performance Goals**: Text message visible to the other side within 5 s, one-photo message within 10 s (SC-002)

**Constraints**: At most 3 direct HTTPS links per message, 2,048 characters each; bounded queries (30 messages per page, 100 conversations for Admin); no client-sent FCM; light-only design system

**Scale/Scope**: One restaurant, a handful of Admins, tens of conversations per day; 1 new screen, 4 existing screens touched, 2 rules files, 1 new feature folder

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|---|---|---|
| I. Specification before implementation | Pass | Clarified spec `specs/008-order-issue-chat/spec.md`; baseline FR-053 to FR-062 updated |
| II. MVVM and Riverpod boundaries | Pass | View -> `OrderChatViewModel` (Riverpod `Notifier`) -> `OrderChatRepository` interface -> Firestore/Storage implementation; no Firebase calls in widgets |
| III. Server-enforced integrity and security | Pass | Participant, sender, size and type rules enforced in `firestore.rules` and `storage.rules` (contract C1-C20, S1-S8); no client FCM |
| IV. Independently demonstrable stories | Pass | US1+US2 form the MVP; US3 and US4 add on independently (see tasks) |
| V. Consistent, verifiable quality | Pass | Loading/empty/error/retry states defined; unit, widget, and rules tests planned; `flutter analyze` gate |
| VI. Light-only Food Ninja design | Pass | Shared tokens and widgets; no new theme |
| Product and Technology Constraints | Pass | Constitution v1.3.0 permits order-scoped issue chat. |

**Post-design re-check (after Phase 1)**: unchanged. The design adds no backend, no new dependency, and no new theme; the constitution amendment has been applied.

## Project Structure

### Documentation (this feature)

```text
specs/008-order-issue-chat/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── order_chat_repository.md
│   ├── firebase_chat_access.md
│   └── order_chat_ui.md
├── checklists/requirements.md
└── tasks.md             # created by /speckit-tasks
```

### Source Code (repository root)

```text
lib/features/order_chat/
├── data/
│   ├── models/
│   │   ├── order_chat_model.dart
│   │   └── chat_message_model.dart
│   └── repositories/
│       └── firestore_order_chat_repository.dart
├── domain/
│   ├── entities/
│   │   ├── chat_issue_type.dart
│   │   ├── chat_role.dart
│   │   ├── order_chat.dart
│   │   ├── chat_message.dart
│   │   ├── chat_draft.dart
│   │   ├── chat_window.dart
│   │   └── chat_failure.dart
│   └── repositories/
│       └── order_chat_repository.dart
└── presentation/
    ├── viewmodels/
    │   ├── order_chat_providers.dart
    │   ├── order_chat_state.dart
    │   └── order_chat_view_model.dart
    ├── views/
    │   └── order_chat_screen.dart
    └── widgets/
        ├── chat_bubble.dart
        ├── chat_composer.dart
        └── chat_unread_dot.dart

# Existing files touched
lib/app/router.dart                                          # /order-chat route
lib/app/main_shell.dart                                      # Orders tab unread dot
lib/features/order_tracking/views/screens/order_detail_screen.dart   # "Nhắn nhà hàng"
lib/features/order/presentation/views/admin_order_details_screen.dart # "Nhắn khách"
lib/features/order/presentation/views/admin_order_list_screen.dart    # "Có tin nhắn" chip
lib/features/order/presentation/viewmodels/admin_order_list_view_model.dart # hasChat filter
lib/features/order/presentation/widgets/admin_order_card.dart         # "Tin mới" badge
firestore.rules, storage.rules, firestore.indexes.json, firebase.json (storage emulator port)
docs/database_schema.md                                      # order_chats section

test/features/order_chat/
├── domain/chat_window_test.dart
├── domain/chat_draft_test.dart
├── presentation/order_chat_view_model_test.dart
└── presentation/order_chat_screen_test.dart
test/support/fake_order_chat_repository.dart
tests/firestore_rules/order_chat_rules.test.mjs
tests/firestore_rules/order_chat_storage.test.mjs
```

**Structure Decision**: A new self-contained feature folder `lib/features/order_chat/` following the `AGENTS.md` data/domain/presentation layout, plus small, additive edits to existing order screens owned by other members. The chat screen is shared by both roles and parameterised by `ChatRole`.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| Constitution v1.2.0 excludes "chat" | Customers had no in-app way to report order problems; the product owner approved order-issue chat (spec change 2026-11-01, baseline User Story 11) | Keeping chat out of scope leaves order problems to phone calls outside the app. **Action**: amend the constitution to v1.3.0 (`/speckit-constitution`) to allow order-scoped chat while still excluding general chat, then proceed to `/speckit-tasks` and implementation. |

## Implementation details

The latest message ID links each message to its parent write in Firestore rules. Firestore validates new HTTPS references and existing-format Storage paths. The UI loads external images when opened and reads legacy images through authenticated Firebase Storage.

## Home support amendment — 2026-11-08

Add HomeOrderSupportButton to Home Scaffold with 96px scroll clearance. Push OrderChatOrderSelectionScreen above MainShell. An auto-dispose Riverpod provider uses OrderHistoryRepository, watches authentication, ignores the Orders filter, filters ownership, sorts newest first and exposes an unmodifiable list. Views render state and navigation only. Pass documentId to the existing chat screen; preserve server authorization without closing rules. LoginArgs(returnToCaller: true) returns Guests to selection. No dependencies, schema, indexes, seed or rules changes: reuse owner-scoped reads and existing chat writes.

Validate ownership, sorting, filter independence, login, loading/empty/error/retry, internal-ID routing, narrow width and text scale 1.3; run Home/chat regression tests, analyzer and full Flutter tests.

### Home amendment convergence

FR-018 maps to T058 and Home layout tests; FR-019 maps to T057 and ownership/sort/filter/internal-ID tests; FR-020 maps to T057 and guest/loading/error/retry/empty tests. No required Home-entry implementation gap found. Existing full-suite failures and T055 manual device validation remain outstanding. No rules/schema migration required.


## Unlimited order chat amendment — 2026-11-08

Approved rule: the owning active Customer and active Admins can start or continue order chat at any time, including after Completed, Cancelled or Rejected. There is no automatic expiry, read-only transition, resolve or reopen. This supersedes all earlier sending-window requirements. Ownership, active-account checks, immutable messages, one conversation per order, validation and retry deduplication remain required. No new schema or migration is needed. Chat remains order-scoped.

Implementation: remove deadline gates from Firestore/Storage, repository, ViewModel, providers, entry and composer. Remove expiry state/helper. Replace expiry tests with successful first-send/reply tests on historical orders and retain access-denial tests. Deploy both rules files with the client before using unlimited chat against production. No dependencies added.


## General support amendment — 2026-11-08

Feature 009 supersedes order-only chat and Home order selection: Home opens general restaurant support, one history per Customer. Order Details retains separate per-order chat. Admin drawer Tin nhắn opens a shared inbox with Chung / Theo đơn filters, preview/time/unread rows and order-details navigation. Reuse light Poppins tokens and chat controls; general_chats stores general histories separately by UID with no expiry. No existing chat migration; deploy Firestore rules/indexes together with client. See specs/009-general-support-chat/{spec,plan,tasks,data-model}.md.
