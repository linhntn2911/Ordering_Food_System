# Feature Specification: Order-Issue Chat

**Feature Branch**: `008-order-issue-chat`

**Created**: 2026-11-01

**Status**: Draft (clarified 2026-11-01)

**Input**: User description: "Order-Issue Chat" - a conversation between a Customer and the restaurant's Admins when something goes wrong with an order. Baseline: `specs/001-food-ordering-system/spec.md` User Story 11, FR-053 to FR-062, BR-018 to BR-021, SC-010.

## Clarifications

### Session 2026-11-01

- Q: Where do Admins find conversations? → A: No separate inbox screen. Orders with unread Customer messages show a "new message" badge in the Admin order list and Admin order details, and the Admin order list gets a "Has messages" filter.
- Q: Can messages include photos in the first release? → A: Yes. A message may carry up to three direct HTTPS image links, with or without text.
- Q: How does a conversation close? → A: It does not expire automatically. Authorized participants can continue messaging indefinitely.
- Decision: Push notifications for chat are deferred until the project has the trusted notification backend required by the baseline (FR-040). Until then, new messages are signalled in the app by real-time updates and unread badges.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Customer reports a problem with an order (Priority: P1)

A Customer who has a problem with one of their orders (a missing or wrong item, late delivery, poor food quality, a wrong address or phone number, a cash-on-delivery question) opens the order and starts a conversation with the restaurant from that order. They describe what happened, can attach photos as evidence, and follow the replies in the same place.

**Why this priority**: This is the reason the feature exists. Without it, a Customer with a problem has no way to reach the restaurant inside the app.

**Independent Test**: Sign in as a Customer with an active order, open the order, choose "Message the restaurant", send a message with one photo, and confirm the message and photo appear in the conversation and stay there after leaving and reopening the order.

**Acceptance Scenarios**:

1. **Given** a signed-in Customer owns an order that is still in progress, **When** they open the order, choose "Message the restaurant", and send a first message, **Then** a conversation is created for that order and the message is shown in it.
2. **Given** a conversation already exists for the order, **When** the Customer opens chat from the order again, **Then** the existing conversation opens and no second conversation is created.
3. **Given** an owned historical order, **When** an authorized participant opens or sends chat, **Then** chat can be started or continued without a deadline, preserving its existing history.
4. **Given** an owned historical order, **When** an authorized participant opens or sends chat, **Then** chat can be started or continued without a deadline, preserving its existing history.
5. **Given** the Customer is writing a message, **When** it has no text and no photo, or the text is longer than 1,000 characters, **Then** it cannot be sent and the limit is shown.
6. **Given** the Customer attaches an image link, **When** the link is invalid, already attached, or exceeds the three-link limit, **Then** the app refuses it.
7. **Given** the device is offline or sending fails, **When** the Customer sends a message, **Then** the message is marked as pending or failed with a retry action, and retrying never produces a duplicate message.

---

### User Story 2 - Admin answers the Customer (Priority: P1)

An Admin notices that a Customer has written about an order, opens the conversation from that order, reads the problem and any photos together with the order details, and replies. The Customer sees the reply without refreshing and sees an unread badge if they are elsewhere in the app.

**Why this priority**: A Customer message has no value until the restaurant can see and answer it. Stories 1 and 2 together are the minimum usable feature.

**Independent Test**: With a conversation started by a Customer, sign in as an Admin, find the order through its badge or the "Has messages" filter, open the conversation, reply, and confirm the Customer sees the reply within a few seconds.

**Acceptance Scenarios**:

1. **Given** a Customer sends a message, **When** an Admin views the Admin order list, **Then** that order shows a "new message" badge without manual refresh, and the "Has messages" filter lists it.
2. **Given** an Admin opens the conversation from the Admin order details, **When** it loads, **Then** the order code and current order status are visible next to the messages, and all earlier messages and photos are shown in time order.
3. **Given** an Admin sends a reply, **When** the Customer has the conversation open, **Then** the reply appears without manual refresh; **When** the Customer is elsewhere in the app, **Then** an unread badge appears on the order and on the Orders tab.
4. **Given** either side has unread messages, **When** they open the conversation, **Then** the unread indicator for that conversation clears for them only.
5. **Given** a message contains photos, **When** either side taps a photo, **Then** it opens in a full-screen viewer where the other photos of that message can be swiped through.

---

### User Story 3 - Admin contacts the Customer about an order (Priority: P2)

While handling an order, an Admin needs the Customer's input (for example an item is out of stock or the address is unclear) and starts the conversation from the order instead of waiting for the Customer to write.

**Why this priority**: Useful for smoother fulfilment, but the restaurant can still reject or delay an order without it.

**Independent Test**: As an Admin, open an order with no conversation, start a conversation and send a message; as the owning Customer, confirm the unread badge appears and the conversation opens from the order.

**Acceptance Scenarios**:

1. **Given** an order with no conversation, **When** an Admin starts one from the Admin order details and sends a message, **Then** the conversation is created for that order and the Customer sees an unread badge.
2. **Given** a Customer and an Admin start a conversation for the same order at nearly the same time, **When** both messages are sent, **Then** both messages end up in one single conversation.

---

### User Story 4 - Continue support for historical orders (Priority: P2)

Order chat remains available indefinitely so Customers and Admins can continue support for historical orders.

**Why this priority**: Support can continue whenever a Customer needs help with a historical order.

**Independent Test**: Use old Completed, Cancelled and Rejected orders; verify both roles can start a conversation and send subsequent messages while preserving history.

**Acceptance Scenarios**:

1. **Given** an owned historical order, **When** an authorized participant opens or sends chat, **Then** chat can be started or continued without a deadline, preserving its existing history.
2. **Given** an existing conversation, **When** either side opens it, **Then** history and photos remain readable and new messages can be sent.
3. **Given** an owned historical order, **When** an authorized participant opens or sends chat, **Then** chat can be started or continued without a deadline, preserving its existing history.

---

### Edge Cases

- An external image becomes unavailable. The message remains visible and the viewer displays an image error.
- Order status changes update the chat header without interrupting message composition or sending.
- A conversation link is opened by someone who is no longer allowed to see the order (signed out, different account, disabled account): access is denied and the user lands on a safe screen.
- A Guest opens a conversation link: they are asked to sign in and, after signing in as the owning Customer, reach the conversation.
- A Customer or Admin account is disabled while a conversation is open: they can no longer send messages.
- Very long conversations: older messages load as the user scrolls back, without blocking the newest messages.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: An active Customer MUST be able to start or open chat for their own order at any time, including after completion, cancellation or rejection.
- **FR-002**: New conversations MUST automatically use the default issue type `other`. Customers and Admins can send the first valid message directly. Existing conversations retain their recorded issue type.
- **FR-003**: Each order MUST have at most one conversation; opening chat for an order that already has one MUST open the existing conversation.
- **FR-004**: An Admin MUST be able to start or open the conversation for any order from the Admin order details.
- **FR-005**: The Admin order list MUST show a "new message" badge on orders whose conversation has messages unread by Admins, and MUST offer a "Has messages" filter; Admin additionally has the shared inbox defined in feature 009.
- **FR-006**: A message MUST contain text of up to 1,000 characters, up to three photos, or both, and MUST NOT be empty.
- **FR-007**: New attachments MUST be direct HTTPS image URLs of at most 2,048 characters. The app MUST store the links with the message and display an error if an image cannot be loaded.
- **FR-008**: Photos MUST be viewable in a full-screen viewer by both participants.
- **FR-009**: Sent messages MUST NOT be editable or deletable by Customers or Admins.
- **FR-010**: New messages MUST appear for the other participant without manual refresh, in the order they were sent, using the server's time.
- **FR-011**: Each side MUST see an unread indicator for a conversation with messages they have not read (for the Customer, on the order and on the Orders tab; for Admins, on the order in the Admin order list and details). The indicator MUST clear only for the person who opens the conversation.
- **FR-012**: Authorized participants MUST be able to start or continue order chat indefinitely, regardless of order status or elapsed time. No automatic closing or reopening is required.
- **FR-013**: Server rules MUST restrict conversations, messages and attachments to the owning active Customer and active Admins, bind sender UID and role to the account, and impose no time limit.
- **FR-014**: A message's sender and role MUST be taken from the signed-in account and MUST NOT be choosable by the sender.
- **FR-015**: A message that fails to send MUST stay visible with a retry action, and a retry MUST NOT create a duplicate message or duplicate photos.
- **FR-016**: Order chat stays attached to its order and is reached from Order Details or Admin Theo đơn inbox. Home opens separate general restaurant support under feature 009; there is no Customer Chat tab or voice/video calling.
- **FR-017**: Chat push notifications are out of scope for this feature until the trusted notification backend exists; the client MUST NOT send push notifications itself.

### Key Entities *(include if feature involves data)*

- **Conversation**: Belongs to exactly one order and its Customer. Holds the issue type, who started it (Customer or Admin), the latest message preview and time, and per-side unread state. Chat does not expire; no closed state is stored.
- **Message**: Belongs to one conversation. Holds the sender, the sender's role (Customer or Admin), optional text, zero to three photos, and the server time it was sent.
- **Photo attachment**: Belongs to one message. Holds a reference to the stored image, which only the conversation's participants can view.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A Customer can go from opening an order to sending their first issue message with a photo in under 1 minute.
- **SC-002**: Under normal network conditions, a text message from either side appears for the other side within 5 seconds, and a message with one photo within 10 seconds.
- **SC-003**: All Guest, other-Customer and disabled-account access attempts are rejected; authorized participants can start and continue chat for historical orders of every terminal status.
- **SC-004**: Retrying a failed message 3 times results in exactly 1 delivered message with each link recorded once.
- **SC-005**: In a team demo, an Admin can find and answer a newly reported issue using only the Admin order list, without being told where to look.

## Assumptions

- The order flow, Customer order details, Admin order list, and Admin order details from the baseline specification already exist; this feature adds chat entry points and badges to them rather than replacing them.
- Admins act as one shared "restaurant" side: any active Admin can read and answer any conversation, and Customers see replies labelled "Ngô Chicken" rather than an individual Admin's name.
- External hosts control access to and availability of image content. A person who already has the URL may be able to view it. Earlier Firebase Storage attachments remain readable under their existing rules.
- Messages and attachment references are kept for as long as the order they belong to is kept.
Order chat remains available indefinitely so Customers and Admins can continue support for historical orders.
- No automatic replies, chatbot, translation, message search, or manual "resolved" status are included.
- Text uses the app's existing Vietnamese-first wording and the light-only design system.
- When the trusted notification backend is added later, chat push notifications can be enabled without changing how conversations work.

## Home support shortcut amendment — superseded by feature 009

FR-018–020 and SC-006 of the original Home order selector are retired. Home now opens general restaurant support directly; order conversations remain in Order Details and Admin Theo đơn inbox. See specs/009-general-support-chat/spec.md for the active requirements.

## Unlimited order chat amendment — 2026-11-08

Approved rule: the owning active Customer and active Admins can start or continue order chat at any time, including after Completed, Cancelled or Rejected. There is no automatic expiry, read-only transition, resolve or reopen. This supersedes all earlier sending-window requirements. Ownership, active-account checks, immutable messages, one conversation per order, validation and retry deduplication remain required. No new schema or migration is needed. Chat remains order-scoped.


## General support amendment — 2026-11-08

Feature 009 supersedes order-only chat and Home order selection: Home opens general restaurant support, one history per Customer. Order Details retains separate per-order chat. Admin drawer Tin nhắn opens a shared inbox with Chung / Theo đơn filters, preview/time/unread rows and order-details navigation. Reuse light Poppins tokens and chat controls; general_chats stores general histories separately by UID with no expiry. No existing chat migration; deploy Firestore rules/indexes together with client. See specs/009-general-support-chat/{spec,plan,tasks,data-model}.md.
