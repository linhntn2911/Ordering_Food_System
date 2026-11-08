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
| Q5 | US1 | Open `order-old` | “Nhắn nhà hàng” remains available; both roles can start and continue chat |
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

## Home support verification — 2026-11-08

On Customer Home, tap “Hỗ trợ đơn hàng”, choose an order, and verify the existing conversation opens. Back returns to selection and then preserves Home. As Guest, sign in from selection and verify the list appears. Confirm empty/error/retry states and that an old order still accepts new messages.

Automated result on origin/linh 53b50d9 plus Home support: 25 focused chat/Home-layout tests passed (including 5 new selection tests). Full Flutter suite: 322 passed, 17 failed across existing Admin/navigation/menu/notification tests; examples include missing Firebase initialization and the menu add-to-cart notice expectation. Full-suite completion gate remains unresolved; do not claim all tests pass. Existing T055 device/timing validation is still outstanding.


## Unlimited order chat amendment — 2026-11-08

Approved rule: the owning active Customer and active Admins can start or continue order chat at any time, including after Completed, Cancelled or Rejected. There is no automatic expiry, read-only transition, resolve or reopen. This supersedes all earlier sending-window requirements. Ownership, active-account checks, immutable messages, one conversation per order, validation and retry deduplication remain required. No new schema or migration is needed. Chat remains order-scoped.


Unlimited-chat verification (2026-11-08): analyzer passed; all 19 chat tests and all 50 Firebase Emulator rules tests passed. Both roles can start and reply on old Completed/Cancelled/Rejected orders; ownership, disabled-account, sender, validation and immutability tests still pass. Firestore and Storage rules must be deployed together with the client to apply the behavior against a hosted Firebase project. No production rules deployment performed in this change.
