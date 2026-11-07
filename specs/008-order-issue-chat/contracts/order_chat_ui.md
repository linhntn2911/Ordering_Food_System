# Contract: Order-Issue Chat UI

All screens follow `docs/design_system.md` (Poppins, `#53E88B -> #15BE77` gradient, shared tokens in `lib/core/theme/`, light only). Keys in backticks are widget keys used by tests.

## Route

`AppRoutes.orderChat = '/order-chat'` with arguments `OrderChatArgs(orderId, viewerRole)`. Not wrapped in `AdminGate`: both roles use it and rules enforce access. A signed-out user is sent to Login (`LoginArgs(returnToCaller: true)`) and returns to the chat on success.

## OrderChatScreen (`lib/features/order_chat/presentation/views/order_chat_screen.dart`)

1. **App bar**: back button; title "Trao đổi về đơn" + order code; subtitle with current order status (`OrderStatusChip`), updating live.
2. **Conversation initiation**. The first valid message creates a conversation with issue type `other`.
3. **Message list**: newest at the bottom; bubbles right-aligned for the viewer, left for the other side. Other-side label: Customer sees "Ngô Chicken", Admin sees the Customer name. Each bubble shows text, a photo grid (1-3 thumbnails, `chat-photo-<messageId>-<i>`), and time `HH:mm` (date separator `dd/MM/yyyy` between days). Pending bubbles show a clock icon; failed bubbles show "Gửi lỗi" and a retry button (`chat-retry-<messageId>`). "Xem tin cũ hơn" (`chat-load-older`) appears at the top when more messages exist.
4. **Composer** (`chat-composer`): image-link button (`chat-add-photo`, disabled at 3 links) opens an HTTPS URL dialog (`chat-image-url`), attached-link indicators with remove buttons, multi-line text field (`chat-text`, max 1,000 chars with counter shown above 900), send button (`chat-send`, disabled while the draft is invalid or sending).
5. **Closed state**: composer replaced by a notice (`chat-closed`): "Cuộc trò chuyện đã đóng. Bạn có thể báo vấn đề trong 24 giờ sau khi đơn kết thúc." If closing happens mid-draft, text and photos stay visible with the notice.
6. **Photo viewer**: tapping a thumbnail opens a full-screen swipeable viewer for that message's photos (reuse `ReviewImageViewer` if its API fits; otherwise a shared widget in `lib/core/widgets/`).
7. **States**: loading skeleton, empty ("Hãy mô tả vấn đề của bạn" for Customer, "Gửi tin nhắn cho khách" for Admin), error with retry, permission denied with back action.

Opening the screen calls `markRead` for the viewer role; new incoming messages while open are marked read as they arrive.

## Entry points and badges

| Screen | Change | Key |
|---|---|---|
| Customer `OrderDetailScreen` | Button "Nhắn nhà hàng" with unread dot when `unreadByCustomer`; hidden with explanation text when the window ended and no conversation exists | `order-chat-open` |
| `MainShell` Orders tab | Small dot when any own conversation has `unreadByCustomer` | `shell-tab-2-badge` |
| `AdminOrderDetailsScreen` | Button "Nhắn khách" with unread dot when `unreadByAdmin` | `admin-order-chat-open` |
| `AdminOrderCard` | "Tin mới" badge when `unreadByAdmin` | `admin-order-chat-badge-<orderId>` |
| `AdminOrderListScreen` filter row | Chip "Có tin nhắn" toggling the has-conversation filter | `admin-order-filter-has-chat` |

## Accessibility

Bubbles expose semantics "Tin nhắn từ <sender>, <time>"; photo thumbnails "Ảnh <i> của tin nhắn"; badges "Có tin nhắn chưa đọc". All controls meet 48 dp touch targets; layout must not overflow at 320 dp width and 1.3x text.
