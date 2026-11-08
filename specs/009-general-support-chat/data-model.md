# Data model

general_chats/{customerUid}: customerId equals document ID; customerName display snapshot; openedByRole customer; lastMessageId, lastMessageAt, lastMessagePreview, lastSenderRole; unreadByAdmin/unreadByCustomer; createdAt/updatedAt. messages/{messageId}: existing ChatMessage shape. No orderId, orderCode or orderStatus is needed.

order_chats is unchanged. New general parents are created on first send, never pre-seeded. Existing order history needs no migration. Both collections have server timestamps, immutable identities/messages and atomic metadata advances. Deploy Firestore rules and general unread index with the client; general attachments are HTTPS URLs, not Storage uploads.
