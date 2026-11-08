# Feature Specification: General restaurant support

Created: 2026-11-08. Status: Approved by explicit user instruction. Supersedes order-only chat scope and Home order selection in feature 008.

## User scenarios and testing

### US1 Customer general support (P1)
An active Customer opens the Home floating chat button, asks a restaurant question without choosing an order, and returns to the same conversation later. Guests sign in and return; disabled accounts are denied. Opening without sending does not create an empty conversation.

### US2 Admin messages inbox (P1)
An active Admin opens Tin nhắn, switches Chung / Theo đơn, sees latest previews, times and unread indicators sorted newest first, opens and replies. Order conversations show the order code and an action opening Admin Order Details. Lists support loading, empty, error/retry and load more beyond the first 100 conversations.

### US3 Separate histories and shared experience (P1)
Nhắn nhà hàng remains in Order Details, with one history per order. General history is separate, one per Customer. Both use the same composer, bubbles, photo links, retry/idempotency, pagination and read markers; neither expires. Reading one conversation must not mark another read. Incoming general replies show an unread indicator on Home support.

## Functional requirements

- FR-001 Home support opens general chat directly; unauthenticated users sign in and return. No order selector or new Customer navigation tab.
- FR-002 One general conversation per Customer UID; first send creates parent and message atomically. Retried sends use the same message ID and never duplicate. Reopening restores history.
- FR-003 Keep all existing order conversations and detail entry points; no history is merged or moved.
- FR-004 Admin Tin nhắn provides Chung / Theo đơn filters, newest-first preview/time/unread rows, load more, and order-code/detail context.
- FR-005 Only the owning active Customer and active Admins may read/write; deny Guests, disabled accounts, cross-customer access, forged sender/role/owner, editing/deleting messages and invalid content. Enforce on server.
- FR-006 Shared message limits: 1–1000 text characters or up to 3 valid HTTPS image links, maximum 2048 characters each. Existing order Storage images remain readable. No new general Storage uploads.
- FR-007 Both histories remain open indefinitely. Loading, empty, error/retry, pending/failed send and unread handling are explicit. Clear only viewer unread state after latest message is visible. Home shows general unread; Orders keeps order unread.

## Success criteria

- SC-001 Signed-in Customer reaches general chat from Home in one tap with no order requirement.
- SC-002 Reopening and retry scenarios preserve one conversation per customer and one message per send ID.
- SC-003 All unauthorized rules cases fail; both authorized roles can exchange text/images without changing order history.
- SC-004 Admin can locate each conversation through its filter and open order details from order chat.

## Key entities and boundaries

GeneralConversation: customer UID, name snapshot, latest message ID/preview/time/role, unread flags, created/updated timestamps. Message: sender UID/role, text, image links, server timestamp. Restaurant-related support only; no peer messaging, voice/video, external messaging or client-sent FCM. No time limit, new dependency or migration of existing chats. Customer login is required. Admin replies to customer-started general threads. Existing push deferral remains.

## Edge cases

Account switches must discard old subscriptions/drafts. Concurrent first sends and retry after reconnect must converge. Send failure retains draft and ID. Reading stale data cannot clear a newer message. More than 100 Admin conversations can be loaded. Narrow 320px and text scale 1.3 remain usable.


## Dashboard messages shortcut — 2026-11-09

FR-008: Admin Dashboard MUST offer a visible Tin nhắn button without opening the drawer. Tapping opens the existing messages inbox. A red numeric badge MUST show the combined number of conversations unread by Admin across general and order chat, updating in real time. Count conversations once within each kind, regardless of message volume; equal IDs across kinds are distinct. No truncation at the inbox paging limit. Hide the badge at zero; show 99+ above 99. Only active Admins subscribe. Loading/error MUST not display a false zero: show an accessible loading or unavailable indicator while keeping inbox navigation enabled and allow retry. No messages are marked read by opening Dashboard. Support 320px and text scale 1.3.

Acceptance: unread counts 2 general + 3 order show 5; reading a thread reduces the count; zero hides the badge; >100 still counts accurately. Guest/disabled accounts never subscribe. Dashboard shortcut opens Tin nhắn in one tap.
