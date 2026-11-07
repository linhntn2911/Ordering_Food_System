# Quickstart: Order-Issue Chat

**Feature**: `008-order-issue-chat` | **Spec**: [spec.md](spec.md)

## Setup

1. Start the emulators (Firestore, Auth, Storage) with the repo rules:

   ```powershell
   npx firebase-tools emulators:start --only firestore,auth,storage --project demo-ordering
   ```

   `firebase.json` must list a `storage` emulator port (added by this feature).

2. Seed menu data and test accounts as for earlier features (`tools/seed_menu`, `GCLOUD_PROJECT=demo-ordering`), then create test orders. Create orders through checkout or add fixtures in the Emulator UI (`http://127.0.0.1:4000/firestore`). The automated rules tests seed their own fixtures.

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
| Q1 | US1 | Customer opens `order-active` > "Nhắn nhà hàng", sends "Đơn lâu quá" | Conversation created; message shown |
| Q2 | US1 | Attach 2 photos and send without text | Message with 2 thumbnails; tapping opens full-screen viewer |
| Q3 | US1 | Tap the image button, paste a direct HTTPS image URL, and send it | Attachment opens in the viewer. Insecure, duplicate, and fourth links are refused. |
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

## Verification record

The targeted Flutter suite passed 27 tests, including the Customer and Admin entry points, photo selection and swipe, unread updates, a 320 dp viewport at 1.3× text scale, and the closed state. Firebase Emulator tests passed all 47 cases, including simultaneous first sends, retry deduplication, and Storage reads, size limits, and overwrite protection. The full Flutter suite still reports 15 failures that also occur on HEAD. Device timing and the two-account walkthrough are tracked in T055.
