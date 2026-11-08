# General support contract

Repository: existing OrderChatRepository interface is reused; general binding targets general_chats by customer UID, while order binding stays on order_chats by document ID. No synthetic orders. Both bindings share message serialization, transaction retries and read markers. Scoped providers isolate message, draft and photo state; GeneralChatScreen keys scope by viewer UID and target customer UID.

Server: active customer may lazily create own parent plus first message in one atomic write; Admin can reply to existing customer-started threads. Parent customerId equals document ID and never changes. Only viewer unread can clear. Metadata advances require a new message with the same ID/time/sender. Message identity/content/time are validated and messages cannot edit/delete. General attachments accept valid HTTPS links only. General Storage paths remain denied.

Index: general_chats(customerId ASC, unreadByCustomer ASC). Latest-message list uses its standard single-field descending index. Seed data: none required; first-send creates records. Migration: no modification to orders or order_chats. Deploy Firestore rules and indexes with client; hosted deployment was not performed by this task.
