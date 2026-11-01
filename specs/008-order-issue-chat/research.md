# Research: Order-Issue Chat

**Feature**: `008-order-issue-chat` | **Spec**: [spec.md](spec.md) | **Date**: 2026-11-01

All Technical Context unknowns are resolved below. Each entry records the decision, why it fits this codebase, and what was rejected.

## R1 - Where conversation data lives

- **Decision**: A top-level collection `order_chats/{orderId}` (one metadata document per order, document ID equals the order ID) with a subcollection `order_chats/{orderId}/messages/{messageId}`.
- **Rationale**: Using the order ID as the document ID makes "at most one conversation per order" (FR-003) structural rather than a query. The existing `orders/{orderId}` rules only let an Admin change `orderStatus`, `updatedAt`, `rejectionReason`, and `completedAt`; unread flags written by Customers would require loosening those rules, so chat metadata stays out of the order document.
- **Alternatives considered**: `orders/{orderId}/messages` with unread fields on the order (rejected: weakens order integrity rules); one global `messages` collection keyed by order (rejected: harder ownership rules and queries).

## R2 - Creating the conversation and sending a message atomically

- **Decision**: Every send runs in one Firestore transaction: read `order_chats/{orderId}`; if absent, create it with `issueType`, `customerId`, `openedByRole`; then create the message document and update the metadata (`lastMessageAt`, `lastMessagePreview`, `lastSenderRole`, and the other side's unread flag).
- **Rationale**: A transaction makes the near-simultaneous Customer/Admin first message (User Story 3, scenario 2) converge on one conversation and keeps metadata consistent with the newest message.
- **Alternatives considered**: Batched write without a read (rejected: cannot decide create vs. update safely); a trusted backend function (rejected: the repo has no backend yet).

## R3 - Idempotent retries

- **Decision**: The message ID is generated on the device before the first attempt (`collection.doc().id`) and reused on every retry. Inside the transaction, if the message document already exists the send is treated as already delivered.
- **Rationale**: Satisfies FR-015 and SC-004 (three retries produce one message). Firestore's offline queue also retries with the same ID.
- **Alternatives considered**: Server-assigned IDs (rejected: a retry after a lost acknowledgement would duplicate the message).

## R4 - Photo upload and storage

- **Decision**: Photos are picked with the existing `image_picker` dependency, downscaled on pick (`maxWidth: 1600`, `imageQuality: 80`), validated client-side (image type, at most 5 MB, at most three), then uploaded to Firebase Storage at `order_chats/{orderId}/{messageId}/{index}.jpg`. The message document stores the **storage paths**, and is written only after every upload succeeds. Uploaded indexes are remembered in ViewModel state so a retry re-uploads only failed photos.
- **Rationale**: Meets FR-007 (no message with a missing photo). Storing paths instead of download URLs keeps reads behind Storage rules; the app resolves a download URL when displaying, which is itself rule-checked.
- **Alternatives considered**: Storing download URLs (rejected: token URLs bypass rules if leaked); writing the message first and patching photos later (rejected: a message could appear without its photos).

## R5 - 24-hour closing rule

- **Decision**: A conversation is open when the order status is not `Completed`, `Cancelled`, or `Rejected`, or when the request time is before `endedAt + 24h`, where `endedAt = completedAt ?? updatedAt` of the order. The same rule exists twice: as a pure Dart domain function for the UI, and in Firestore and Storage rules for enforcement.
- **Rationale**: The current order rules only allow `updatedAt` to change during status transitions, so for a terminal order `updatedAt` is the terminal time; `completedAt` is preferred when present. No extra stored status is needed (spec: "derived, not stored").
- **Alternatives considered**: A stored `closedAt` set by a scheduled job (rejected: needs a backend); trusting the client clock (rejected: rules must enforce FR-013).

## R6 - Unread indicators and the Admin "Has messages" filter

- **Decision**: Metadata holds two booleans, `unreadByAdmin` and `unreadByCustomer`. A sender sets the other side's flag to `true`; opening the conversation sets one's own flag to `false`. Admin screens watch `order_chats` ordered by `lastMessageAt` (bounded to 100) and join the result client-side with the existing Admin order list; the badge uses `unreadByAdmin`, and the "Has messages" filter keeps orders that have a conversation. The Customer Orders tab badge watches `order_chats` where `customerId == uid` and `unreadByCustomer == true`.
- **Rationale**: Booleans are queryable and enough for a badge (the spec asks for an indicator, not a count). The Admin order list already loads a bounded list and filters client-side (`AdminOrderListFilter.apply`), so a client-side join matches the existing pattern.
- **Alternatives considered**: Per-side `lastReadAt` timestamps (rejected: Firestore cannot query "lastMessageAt > lastReadAt"); unread counters (rejected: more write contention, not required).

## R7 - Notifications

- **Decision**: No push notifications in this feature (spec FR-017). New messages are signalled by real-time listeners and unread badges only.
- **Rationale**: The repo has no `functions/` backend, and the constitution forbids clients from sending privileged FCM messages.
- **Alternatives considered**: Client-written in-app notification records for the other party (rejected: requires cross-user writes and duplicates the badge).

## R8 - Message paging

- **Decision**: Watch the newest 30 messages ordered by `createdAt` descending; "load older" raises the limit by 30, following the review paging pattern in `MenuItemDetailViewModel` (`_reviewLimit`).
- **Rationale**: Keeps queries bounded (NFR-004) with a pattern the team already uses.
- **Alternatives considered**: Cursor-based pagination (rejected: unnecessary for conversations of this size).

## R9 - Server time and ordering

- **Decision**: `createdAt` is `FieldValue.serverTimestamp()` and rules require `createdAt == request.time`. Pending messages render with the local estimate (`ServerTimestampBehavior.estimate`) and a pending marker.
- **Rationale**: FR-010 requires server time; this matches BR-010.

## R10 - Sender labels

- **Decision**: Customers see Admin messages labelled "Ngô Chicken" (from `RestaurantInfo.name`); Admins see the Customer's name from the order snapshot (`customerName`).
- **Rationale**: Spec assumption: Admins act as one shared restaurant side.

## R11 - Where the code goes

- **Decision**: New feature folder `lib/features/order_chat/` (data, domain, presentation) with one shared `OrderChatScreen` opened with an order ID and the viewer role. Entry points and badges are added to the existing Customer `OrderDetailScreen`, `AdminOrderDetailsScreen`, `AdminOrderListScreen`/`AdminOrderCard`, and the Orders tab in `MainShell`.
- **Rationale**: Follows `AGENTS.md` feature structure and keeps the new screen independently testable.

## R12 - Verification

- **Decision**: Dart unit tests for the open-window rule, draft validation, and the ViewModel (with a fake repository); widget tests for the chat screen states and entry points; Firestore and Storage rules tests added to `tests/firestore_rules` running against the emulator with `--only firestore,storage`.
- **Rationale**: Constitution V requires rules or emulator verification for authorization.

## Dependencies

No new packages. Uses existing `cloud_firestore`, `firebase_storage`, `firebase_auth`, `image_picker`, and `flutter_riverpod`.
