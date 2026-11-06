# Data Model: Order-Issue Chat

**Feature**: `008-order-issue-chat` | **Research**: [research.md](research.md)

## Firestore

### `order_chats/{orderId}` - conversation metadata

Document ID equals `orders/{orderId}` (one conversation per order, FR-003).

| Field | Type | Rules |
|---|---|---|
| `orderId` | string | Equals the document ID |
| `orderCode` | string | Snapshot of `orders/{orderId}.orderCode` at creation |
| `customerId` | string | Equals `orders/{orderId}.customerId`; immutable |
| `issueType` | string | One of `missingOrWrongItem`, `lateDelivery`, `foodQuality`, `addressOrContact`, `codPayment`, `other` (FR-002); immutable |
| `openedByRole` | string | `customer` or `admin`; immutable |
| `lastMessageId` | string | Links the parent write to its newly created message |
| `lastMessageAt` | timestamp | Server time of the newest message |
| `lastMessagePreview` | string | First 80 characters of the newest text, or `"[Ảnh]"` when photo-only |
| `lastSenderRole` | string | `customer` or `admin` |
| `unreadByAdmin` | bool | Set `true` by a Customer send; set `false` by an Admin opening the conversation |
| `unreadByCustomer` | bool | Set `true` by an Admin send; set `false` by the Customer opening the conversation |
| `createdAt` | timestamp | Server time at creation |
| `updatedAt` | timestamp | Server time of the last metadata change |

Open or read-only is **not stored**; it is derived from the order (see "Open window").

### `order_chats/{orderId}/messages/{messageId}` - message

`messageId` is generated on the device before the first send and reused on retry (R3).

| Field | Type | Rules |
|---|---|---|
| `senderId` | string | Must equal `request.auth.uid` (FR-014) |
| `senderRole` | string | `customer` when sender is the order's Customer, `admin` when sender is an active Admin |
| `text` | string | 0-1,000 characters after trimming |
| `imagePaths` | list<string> | Up to three direct HTTPS image URLs (2,048 characters each). Existing Storage paths remain readable. |
| `createdAt` | timestamp | Must equal `request.time` (FR-010) |

Validation: `text.trim().length > 0 || imagePaths.length > 0` (FR-006). Messages are create-only; updates and deletes are rejected (FR-009).

### Indexes (`firestore.indexes.json`)

| Collection | Fields | Used by |
|---|---|---|
| `order_chats` | `customerId` ASC, `unreadByCustomer` ASC | Customer Orders tab badge |
| `order_chats` | `unreadByAdmin` ASC, `lastMessageAt` DESC | Admin unread badges |
| `order_chats` | `lastMessageAt` DESC (single field, automatic) | Admin "Has messages" filter |
| `messages` (collection) | `createdAt` DESC (single field, automatic) | Message list paging |

## Legacy Firebase Storage attachments

Path: `order_chats/{orderId}/{messageId}/{index}.jpg`, `index` in `0..2`.

- Content type `image/*`, size `< 5 MB` for legacy uploads.
- Create only; no overwrite or delete by clients.
- Read and create only by the order's Customer or an active Admin, and create only while the conversation is open.

## Dart domain entities (`lib/features/order_chat/domain/entities/`)

| Entity | Fields | Notes |
|---|---|---|
| `ChatIssueType` (enum) | six values above | Vietnamese labels: Thiếu hoặc sai món, Giao trễ, Chất lượng món, Địa chỉ hoặc liên hệ, Thanh toán COD, Khác |
| `ChatRole` (enum) | `customer`, `admin` | |
| `OrderChat` | `orderId`, `orderCode`, `customerId`, `issueType`, `openedByRole`, `lastMessageAt`, `lastMessagePreview`, `lastSenderRole`, `unreadByAdmin`, `unreadByCustomer` | Immutable, equatable |
| `ChatMessage` | `id`, `senderId`, `senderRole`, `text`, `imagePaths`, `createdAt?`, `isPending` | `createdAt` null or estimated while pending |
| `ChatDraft` | `text`, `imageUrls` (HTTPS URLs, max 3) | `validate()` checks content, text length, photo count, and photo size |
| `ChatWindow` | pure function `isOpen({orderStatus, completedAt, updatedAt, now})` | Mirrors rules (R5) |

## Open window (R5)

```
terminal = orderStatus in {Completed, Cancelled, Rejected}
endedAt  = completedAt ?? updatedAt
open     = !terminal || now < endedAt + 24h
```

## State transitions

Conversation: `absent -> exists` on the first message from either side (transaction, R2). There is no stored status; `open -> read-only` happens implicitly when the window above ends.

Message (client-side only): `draft -> sending -> sent`, with `sending -> failed -> (retry) sending`.
