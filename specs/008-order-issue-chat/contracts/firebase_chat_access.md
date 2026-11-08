# Contract: Firestore and Storage access for Order-Issue Chat

Rules live in `firestore.rules` and `storage.rules`. Cases below are implemented as emulator tests in `tests/firestore_rules/order_chat_rules.test.mjs` (Firestore) and `tests/firestore_rules/order_chat_storage.test.mjs` (Storage). Fixture: `customer-1` owns `order-active` (status `Preparing`), `order-recent` (`Completed`, `completedAt` = now - 2h) and `order-old` (`Completed`, `completedAt` = now - 25h); `customer-2` owns nothing; `admin-1` is an active Admin; `admin-off` is an Admin with status `disabled`.

## Shared rule helpers

```
function chatOrder(orderId) = get(/orders/$(orderId)).data
function isChatParticipant(orderId) =
  signedIn() && currentUser().data.status == 'active'\n  && (chatOrder(orderId).customerId == request.auth.uid || isAdmin())
function senderRole(orderId) = isAdmin() ? 'admin' : 'customer'
```

## Firestore cases

| ID | Actor | Action | Expected |
|---|---|---|---|
| C1 | customer-1 | Create `order_chats/order-active` with valid fields and first message in one transaction | Allow |
| C2 | customer-2 | Read `order_chats/order-active` or its messages | Deny |
| C3 | Guest | Read `order_chats/order-active` | Deny |
| C4 | admin-1 | Read any `order_chats` document and messages; list `order_chats` ordered by `lastMessageAt` | Allow |
| C5 | admin-off | Read or write `order_chats/order-active` | Deny |
| C6 | customer-1 | Create message with `senderId` = `admin-1` or `senderRole` = `admin` | Deny |
| C7 | customer-1 | Create message with `createdAt` not equal to request time | Deny |
| C8 | customer-1 | Create message with empty text and no images, text over 1,000 chars, or 4 image paths | Deny |
| C9 | customer-1 | Create message with an image path outside `order_chats/order-active/{messageId}/` | Deny |
| C10 | customer-1 | Update or delete an existing message | Deny |
| C11 | customer-1 | Send to `order-recent` (ended 2h ago) | Allow |
| C12 | customer-1 / admin-1 | Start and continue messages on old Completed, Cancelled and Rejected orders | Allow |
| C13 | customer-1 / admin-1 | Read `order-old` conversation and messages | Allow |
| C14 | customer-1 | Update metadata `customerId`, `issueType`, `openedByRole`, or `orderCode` | Deny |
| C15 | customer-1 | Set own `unreadByCustomer` to false | Allow |
| C16 | customer-1 | Set `unreadByAdmin` to false | Deny |
| C17 | admin-1 | Set own `unreadByAdmin` to false; set `unreadByCustomer` to false | Allow; Deny |
| C18 | customer-1 | Create `order_chats/{id}` whose ID is not an existing own order, or with `customerId` different from the order | Deny |
| C19 | customer-1 | Query `order_chats` where `customerId == customer-1` and `unreadByCustomer == true` | Allow |
| C20 | customer-1 | Query `order_chats` without the `customerId` filter | Deny |

Metadata updates are allowed only for keys `lastMessageId`, `lastMessageAt`, `lastMessagePreview`, `lastSenderRole`, `unreadByAdmin`, `unreadByCustomer`, `updatedAt`, with participant, immutable-field and atomic message-advance validation; there is no time gate. Each participant may clear only their own unread flag.

## Storage cases (`order_chats/{orderId}/{messageId}/{index}.jpg`)

| ID | Actor | Action | Expected |
|---|---|---|---|
| S1 | customer-1 | Upload 1 MB `image/jpeg` to `order-active` | Allow |
| S2 | customer-1 | Upload 6 MB image | Deny |
| S3 | customer-1 | Upload `application/pdf` | Deny |
| S4 | customer-2 | Upload or read under `order-active` | Deny |
| S5 | admin-1 | Read any chat photo | Allow |
| S6 | customer-1 | Overwrite or delete an existing photo | Deny |
| S7 | customer-1 | Upload under `order-old` | Allow |
| S8 | Guest | Read a chat photo | Deny |


## Unlimited order chat amendment — 2026-11-08

Approved rule: the owning active Customer and active Admins can start or continue order chat at any time, including after Completed, Cancelled or Rejected. There is no automatic expiry, read-only transition, resolve or reopen. This supersedes all earlier sending-window requirements. Ownership, active-account checks, immutable messages, one conversation per order, validation and retry deduplication remain required. No new schema or migration is needed. Chat remains order-scoped.
