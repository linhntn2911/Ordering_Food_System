# Tasks: Order-Issue Chat

**Input**: Design documents from `specs/008-order-issue-chat/` (`spec.md`, `plan.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`)

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`

**Tests**: Included as required by `plan.md` and project constitution principles (unit tests for domain/ViewModel, rules tests against Firebase emulator).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization, constitution gate, storage emulator, and index configuration.

- [X] T001 Amend project constitution to v1.3.0 to permit order-scoped issue chat in `.specify/memory/constitution.md`
- [X] T002 Configure Firebase Storage emulator port in `firebase.json`
- [X] T003 [P] Add composite indexes for `order_chats` (`customerId ASC, unreadByCustomer ASC` and `unreadByAdmin ASC, lastMessageAt DESC`) in `firestore.indexes.json`
- [X] T004 [P] Update database schema documentation with `order_chats` and `messages` subcollection in `docs/database_schema.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core security rules, domain entities, repository interfaces, and data models that MUST be complete before ANY user story can be implemented.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

### Security Rules & Emulator Verification

- [X] T005 Implement Firestore security rules for `order_chats/{orderId}` and `order_chats/{orderId}/messages/{messageId}` enforcing participants, immutable fields, size limits, and `chatOpen` 24h window in `firestore.rules`
- [X] T006 Implement Firebase Storage security rules for `order_chats/{orderId}/{messageId}/{index}.jpg` (content type `image/*`, size `< 5 MB`, max index 2, create-only, `chatOpen` window) in `storage.rules`
- [X] T007 [P] Create Firestore security rules emulator test suite (cases C1–C20) in `tests/firestore_rules/order_chat_rules.test.mjs`
- [X] T008 [P] Create Firebase Storage security rules emulator test suite (cases S1–S8) in `tests/firestore_rules/order_chat_storage.test.mjs`

### Domain Foundation

- [X] T009 [P] Create `ChatIssueType` enum (`missingOrWrongItem`, `lateDelivery`, `foodQuality`, `addressOrContact`, `codPayment`, `other`) with Vietnamese labels in `lib/features/order_chat/domain/entities/chat_issue_type.dart`
- [X] T010 [P] Create `ChatRole` enum (`customer`, `admin`) in `lib/features/order_chat/domain/entities/chat_role.dart`
- [X] T011 [P] Create `ChatFailure` domain failure types (`closed`, `permissionDenied`, `photoTooLarge`, `unavailable`, `unknown`) in `lib/features/order_chat/domain/entities/chat_failure.dart`
- [X] T012 [P] Create `ChatWindow` pure domain helper (`isOpen({orderStatus, completedAt, updatedAt, now})` where terminal is `Completed|Cancelled|Rejected` and window is `endedAt + 24h`) in `lib/features/order_chat/domain/entities/chat_window.dart`
- [X] T013 [P] Add unit tests for `ChatWindow` domain logic in `test/features/order_chat/domain/chat_window_test.dart`
- [X] T014 [P] Create `OrderChat` domain entity (`orderId`, `orderCode`, `customerId`, `issueType`, `openedByRole`, `lastMessageAt`, `lastMessagePreview`, `lastSenderRole`, `unreadByAdmin`, `unreadByCustomer`) in `lib/features/order_chat/domain/entities/order_chat.dart`
- [X] T015 [P] Create `ChatMessage` domain entity (`id`, `senderId`, `senderRole`, `text`, `imagePaths`, `createdAt`, `isPending`) in `lib/features/order_chat/domain/entities/chat_message.dart`
- [X] T016 [P] Create `ChatDraft` domain entity with `validate()` enforcing `text.trim().length <= 1000`, `photos.length <= 3`, photo size `< 5 MB`, and non-empty `text || photos` in `lib/features/order_chat/domain/entities/chat_draft.dart`
- [X] T017 [P] Add unit tests for `ChatDraft` validation rules in `test/features/order_chat/domain/chat_draft_test.dart`
- [X] T018 [P] Define `OrderChatRepository` interface per contract in `lib/features/order_chat/domain/repositories/order_chat_repository.dart`
- [X] T019 [P] Create `FakeOrderChatRepository` test double for unit/widget tests in `test/support/fake_order_chat_repository.dart`

### Data Layer Foundation

- [X] T020 [P] Create `OrderChatModel` with Firestore mapping and snapshot converters in `lib/features/order_chat/data/models/order_chat_model.dart`
- [X] T021 [P] Create `ChatMessageModel` with Firestore server timestamp handling in `lib/features/order_chat/data/models/chat_message_model.dart`
- [X] T022 Implement `FirestoreOrderChatRepository` with atomic transaction send (`order_chats/{orderId}` creation + message creation + metadata/unread update), idempotent retry, photo upload to Storage, and streams in `lib/features/order_chat/data/repositories/firestore_order_chat_repository.dart`

### Presentation Foundation

- [X] T023 [P] Create `OrderChatState` holding active chat, message list, draft, sending status, and error states in `lib/features/order_chat/presentation/viewmodels/order_chat_state.dart`
- [X] T024 [P] Create `OrderChatViewModel` (Riverpod `Notifier`) managing message draft, photo pick/remove, transaction send, markRead, and pagination in `lib/features/order_chat/presentation/viewmodels/order_chat_view_model.dart`
- [X] T025 [P] Register Riverpod providers (`orderChatViewModelProvider`, `orderChatRepositoryProvider`, `orderChatStreamProvider`) in `lib/features/order_chat/presentation/viewmodels/order_chat_providers.dart`
- [X] T026 [P] Create `ChatUnreadDot` widget in `lib/features/order_chat/presentation/widgets/chat_unread_dot.dart`
- [X] T027 [P] Create full-screen swipeable photo viewer widget in `lib/core/widgets/chat_photo_viewer.dart`
- [X] T028 Add `/order-chat` route accepting `OrderChatArgs(orderId, viewerRole)` in `lib/app/router.dart`

**Checkpoint**: Foundation ready - user story implementation can proceed.

---

## Phase 3: User Story 1 - Customer reports a problem with an order (Priority: P1) 🎯 MVP

**Goal**: A Customer can open their active/recent order (< 24h after completion), attach up to 3 photos (<= 5 MB), send a message, and follow replies in real time.

**Independent Test**: Sign in as a Customer with an active order, open the order, tap "Nhắn nhà hàng", send a message with one photo, and confirm the message and photo appear and persist on reload.

### Tests for User Story 1

- [X] T029 [P] [US1] Unit test `OrderChatViewModel` Customer flow (issue selection, photo attach, draft validation, atomic send, retry on failure) in `test/features/order_chat/presentation/order_chat_view_model_test.dart`
- [X] T030 [P] [US1] Widget test for `OrderChatScreen` Customer journey (composer, bubbles, photo picker, empty/loading/error states) in `test/features/order_chat/presentation/order_chat_screen_test.dart`

### Implementation for User Story 1

- [X] T031 [P] [US1] Default the issue type to `other` for new customer conversations
- [X] T032 [P] [US1] Implement `ChatBubble` widget showing sender label ("Ngô Chicken" for Admin), text, photo thumbnails (`chat-photo-<messageId>-<i>`), time `HH:mm`, pending icon, and retry button (`chat-retry-<messageId>`) in `lib/features/order_chat/presentation/widgets/chat_bubble.dart`
- [X] T033 [P] [US1] Implement `ChatComposer` widget with photo attach button (`chat-add-photo`), photo preview chips with remove, text input (`chat-text`, max 1000 chars), and send button (`chat-send`) in `lib/features/order_chat/presentation/widgets/chat_composer.dart`
- [X] T034 [US1] Implement `OrderChatScreen` layout with live order status chip, message list, photo click to full-screen viewer, and retry handling in `lib/features/order_chat/presentation/views/order_chat_screen.dart`
- [X] T035 [US1] Add "Nhắn nhà hàng" button (`order-chat-open`) with unread badge or 24-hour expiration notice to Customer `OrderDetailScreen` in `lib/features/order_tracking/views/screens/order_detail_screen.dart`

**Checkpoint**: At this point, User Story 1 is fully functional and testable independently.

---

## Phase 4: User Story 2 - Admin answers the Customer (Priority: P1)

**Goal**: Admins see incoming messages via badges on the Admin order list, can filter orders with messages, open conversations from Admin order details, read history/photos, and reply. Customer sees replies in real time and gets unread indicators.

**Independent Test**: With a conversation started by Customer, sign in as Admin, locate the order via "Tin mới" badge or "Có tin nhắn" filter, open chat, send a reply, and verify Customer receives the reply and unread indicator clears appropriately.

### Tests for User Story 2

- [X] T036 [P] [US2] Unit test Admin order list view model with `hasChat` filter and unread badge join in `test/features/order/presentation/admin_order_list_view_model_test.dart`
- [X] T037 [P] [US2] Widget test for Admin order card badge and Admin chat entry in `test/features/order/presentation/admin_order_details_screen_test.dart`

### Implementation for User Story 2

- [X] T038 [P] [US2] Add "Tin mới" badge (`admin-order-chat-badge-<orderId>`) when `unreadByAdmin` to `AdminOrderCard` in `lib/features/order/presentation/widgets/admin_order_card.dart`
- [X] T039 [P] [US2] Add "Nhắn khách" button (`admin-order-chat-open`) with unread dot to `AdminOrderDetailsScreen` in `lib/features/order/presentation/views/admin_order_details_screen.dart`
- [X] T040 [US2] Add `hasChat` filter state and client-side join with `watchAdminChats` stream in `lib/features/order/presentation/viewmodels/admin_order_list_view_model.dart`
- [X] T041 [US2] Add "Có tin nhắn" filter chip (`admin-order-filter-has-chat`) to filter bar in `lib/features/order/presentation/views/admin_order_list_screen.dart`
- [X] T042 [US2] Add unread dot badge (`shell-tab-2-badge`) to Orders tab watching `watchCustomerHasUnread` in `lib/app/main_shell.dart`
- [X] T043 [US2] Ensure `markRead` is triggered upon opening `OrderChatScreen` and when new messages arrive while screen is active for either role in `lib/features/order_chat/presentation/views/order_chat_screen.dart`

**Checkpoint**: User Stories 1 AND 2 are complete, forming the full Customer-Admin MVP loop.

---

## Phase 5: User Story 3 - Admin contacts the Customer about an order (Priority: P2)

**Goal**: An Admin can proactively initiate a conversation about an order from `AdminOrderDetailsScreen` (e.g. out of stock or address clarification) without waiting for the Customer.

**Independent Test**: Sign in as Admin, open an order without an existing conversation, tap "Nhắn khách", send a message (defaulting issue type to `other`), and verify Customer receives unread indicator and can open the chat.

### Tests for User Story 3

- [X] T044 [P] [US3] Unit test Admin initiation flow and concurrent start race resolution in `test/features/order_chat/presentation/order_chat_view_model_test.dart`

### Implementation for User Story 3

- [X] T045 [US3] Support Admin chat initiation in `OrderChatViewModel` with default issue type `other` in `lib/features/order_chat/presentation/viewmodels/order_chat_view_model.dart`
- [X] T046 [US3] Verify atomic transaction convergence for near-simultaneous Customer and Admin initiation in `lib/features/order_chat/data/repositories/firestore_order_chat_repository.dart`

**Checkpoint**: User Stories 1, 2, and 3 are functional and independently testable.

---

## Phase 6: User Story 4 - Conversation closes automatically (Priority: P2)

**Goal**: Conversations become read-only 24 hours after the order reaches `Completed`, `Cancelled`, or `Rejected`. Both sides can read history and photos, but cannot send new messages.

**Independent Test**: Open an order that ended > 24 hours ago; verify message history and photos load, the composer is replaced with "Cuộc trò chuyện đã đóng" notice (`chat-closed`), and any client-side send attempt is prevented.

### Tests for User Story 4

- [X] T047 [P] [US4] Unit test for 24-hour expiration behavior in `OrderChatViewModel` in `test/features/order_chat/presentation/order_chat_view_model_test.dart`

### Implementation for User Story 4

- [X] T048 [US4] Replace composer with notice widget (`chat-closed`: "Cuộc trò chuyện đã đóng. Bạn có thể báo vấn đề trong 24 giờ sau khi đơn kết thúc.") when `!chatWindow.isOpen` in `lib/features/order_chat/presentation/views/order_chat_screen.dart`
- [X] T049 [US4] Preserve draft text and attached photos on screen if closing window expires while user is composing in `lib/features/order_chat/presentation/viewmodels/order_chat_view_model.dart`
- [X] T050 [US4] Verify server-side rule rejection mapping (`ChatFailure.closed`) when writing to an expired conversation in `lib/features/order_chat/data/repositories/firestore_order_chat_repository.dart`

**Checkpoint**: All user stories (US1-US4) are fully functional.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Message pagination, accessibility, documentation, and end-to-end verification.

- [X] T051 [P] Implement message pagination ("Xem tin cũ hơn" `chat-load-older`, +30 messages) in `lib/features/order_chat/presentation/viewmodels/order_chat_view_model.dart` and `lib/features/order_chat/presentation/views/order_chat_screen.dart`
- [X] T052 [P] Verify accessibility semantics and 48 dp touch targets on all chat buttons, thumbnails, and composer controls per `contracts/order_chat_ui.md` in `lib/features/order_chat/presentation/views/order_chat_screen.dart`
- [X] T053 Run formatting and static analysis validation (`dart format lib test` and `flutter analyze`) across codebase
- [X] T054 Run automated test suite (`flutter test test/features/order_chat`) and emulator rules tests (`npm test` in `tests/firestore_rules`) per `quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately.
- **Foundational (Phase 2)**: Depends on Phase 1 completion - **BLOCKS all user stories**.
- **User Story 1 (Phase 3)**: Depends on Foundational (Phase 2). Delivers Customer MVP.
- **User Story 2 (Phase 4)**: Depends on Foundational (Phase 2) and integrates with User Story 1. Delivers complete Customer-Admin loop.
- **User Story 3 (Phase 5)**: Depends on Foundational (Phase 2) and Phase 3/4. Adds proactive Admin initiation.
- **User Story 4 (Phase 6)**: Depends on Foundational (Phase 2) and Phase 3/4. Enforces the 24h closing window.
- **Polish (Phase 7)**: Depends on all user stories being implemented.

### Parallel Opportunities

- **Phase 1**: T003 (`firestore.indexes.json`) and T004 (`docs/database_schema.md`) can run in parallel.
- **Phase 2**:
  - Security rules tests T007 and T008 can run in parallel.
  - Domain entities T009, T010, T011, T012, T014, T015, T016 can all be authored in parallel.
  - Domain unit tests T013 and T017 can run in parallel.
  - Data models T020 and T021 can run in parallel.
  - Presentation widgets T026, T027, T028 can run in parallel.
- **Phase 3 (US1)**: Tests T029 and T030 can run in parallel; widgets T031, T032, T033 can be authored in parallel before assembling in T034.
- **Phase 4 (US2)**: Tests T036 and T037 can run in parallel; badge T038 and button T039 can run in parallel.
- **Phase 7**: T051 and T052 can run in parallel.

---

## Parallel Example: User Story 1

```bash
# Launch test creation for User Story 1 in parallel:
Task: "Unit test OrderChatViewModel Customer flow in test/features/order_chat/presentation/order_chat_view_model_test.dart"
Task: "Widget test for OrderChatScreen Customer journey in test/features/order_chat/presentation/order_chat_screen_test.dart"

# Launch widget components for User Story 1 in parallel:
Task: "Default the issue type for new conversations"
Task: "Implement ChatBubble widget in lib/features/order_chat/presentation/widgets/chat_bubble.dart"
Task: "Implement ChatComposer widget in lib/features/order_chat/presentation/widgets/chat_composer.dart"
```

---

## Implementation Strategy

### MVP First (User Stories 1 & 2)

1. Complete **Phase 1: Setup** (Constitution amendment, emulator port, indexes).
2. Complete **Phase 2: Foundational** (Rules, Domain, Data repository, ViewModels).
3. Complete **Phase 3: User Story 1** (Customer issue reporting with photo).
4. Complete **Phase 4: User Story 2** (Admin reply + badges + filters).
5. **STOP and VALIDATE**: Test complete Customer-Admin exchange loop via emulator (`quickstart.md` Q1–Q7).

### Incremental Delivery

1. Phase 1 + Phase 2 → Solid, tested foundation.
2. Phase 3 (US1) → Customer can report issues.
3. Phase 4 (US2) → Admin can respond, completing MVP.
4. Phase 5 (US3) → Admin can proactively initiate issue resolution.
5. Phase 6 (US4) → Automated 24h close window enforced across UI and Firestore/Storage rules.
6. Phase 7 (Polish) → Pagination, accessibility, final quality checks.

## Phase 8: Convergence

- [ ] T055 Run the Customer and Admin journeys on a target device and record first-send time, delivery latency, and Admin discoverability per SC-001, SC-002, SC-005, and quickstart Q1–Q10 (partial).

## Image link attachments

- [X] Replace the image picker with an HTTPS link dialog, validate links in the client and rules, and preserve viewing of existing Storage attachments.

## Phase 9: Home support shortcut (US5)

- [X] T056 [US5] Amend baseline, feature spec, plan and design for FR-018–020.
- [X] T057 [US5] Add authenticated immutable order-selection provider and selection screen with login/loading/empty/error/retry.
- [X] T058 [US5] Add gradient Home support button, scroll clearance and existing chat routing.
- [X] T059 [US5] Test selection access/states/navigation and Home regressions; format, analyze and run Flutter tests; record convergence.


## Phase 10: Unlimited order chat (supersedes Phase 6)

- [X] T060 Update specs, plan, contracts and requirements-quality review for unlimited chat.
- [X] T061 Remove client and Firebase time gates while retaining participant authorization.
- [X] T062 Update domain, ViewModel, widget and rules tests for historical orders; format/analyze/run focused suites and document deployment needs.
