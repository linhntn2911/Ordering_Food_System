# Quickstart: Order-Issue Chat

**Feature**: `008-order-issue-chat` | **Spec**: [spec.md](spec.md)

## Setup

1. Start the emulators (Firestore, Auth, Storage) with the repo rules:

   ```powershell
   npx firebase-tools emulators:start --only firestore,auth,storage --project demo-ordering
   ```

   `firebase.json` must list a `storage` emulator port (added by this feature).

2. Seed menu data and test accounts as for earlier features (`tools/seed_menu`, `GCLOUD_PROJECT=demo-ordering`), then create test orders. Clients cannot create orders (rules), so add them in the Emulator UI (`http://127.0.0.1:4000/firestore`) or with the order fixture script added by this feature:

   | Order ID | `customerId` | `orderStatus` | Timing |
   |---|---|---|---|
   | `order-active` | the test Customer UID | `Preparing` | - |
   | `order-recent` | the test Customer UID | `Completed` | `completedAt` = now - 2h |
   | `order-old` | the test Customer UID | `Completed` | `completedAt` = now - 25h |

3. Run the app:

   ```powershell
   flutter run -d chrome --web-port 5555 --dart-define=USE_FIRESTORE_EMULATOR=true
   ```

## Verification scenarios

| # | Story | Steps | Expected |
|---|---|---|---|
| Q1 | US1 | Customer opens `order-active` > "Nhắn nhà hàng", picks "Giao trễ", sends "Đơn lâu quá" | Conversation created; message shown; send button disabled until an issue type is chosen |
| Q2 | US1 | Attach 2 photos and send without text | Message with 2 thumbnails; tapping opens full-screen viewer |
| Q3 | US1 | Try attaching a 4th photo, and a >5 MB file | 4th refused; large file refused with "Ảnh vượt quá 5 MB" |
| Q4 | US1 | DevTools > Offline, send a message, go online | Pending, then sent; exactly one message |
| Q5 | US1 | Open `order-old` | No "Nhắn nhà hàng"; explanation of the 24-hour rule |
| Q6 | US2 | Admin opens Admin Order List | `order-active` shows "Tin mới"; chip "Có tin nhắn" lists it |
| Q7 | US2 | Admin opens order > "Nhắn khách", replies | Badge clears for Admin only; Customer sees reply within 5 s, or a dot on the Orders tab if elsewhere |
| Q8 | US3 | Admin starts chat on an order without one | Conversation created; Customer sees the unread dot |
| Q9 | US4 | Open the chat of a conversation on `order-old` | History readable, composer replaced by "Cuộc trò chuyện đã đóng" |
| Q10 | Security | Sign in as another Customer and open `/order-chat` for `order-active` | Permission denied state |

## Automated checks

```powershell
dart format lib test
flutter analyze
flutter test test/features/order_chat
cd tests/firestore_rules; npm test   # C1-C20, S1-S8
```
