# Firestore Data Model

The authoritative collection and field catalog is maintained in `docs/database_schema.md`. This document records relationships used by implementation planning.

```text
users/{uid}
├── addresses/{addressId}
├── favorites/{menuItemId}
├── cart_items/{cartItemId}
├── notifications/{notificationId}
└── devices/{deviceId}

categories/{categoryId}
menu_items/{menuItemId}

orders/{orderId}
├── items/{orderItemId}
└── status_events/{eventId}

reviews/{reviewId}
restaurant_configs/main
```

## Relationship Rules

- `users/{uid}` uses the Firebase Authentication UID as its document ID.
- `menu_items.categoryId` references `categories/{categoryId}`.
- Favorite document IDs use `menuItemId` to prevent duplicates.
- Cart entries retain selected option snapshots but checkout revalidates source price and availability.
- Orders retain immutable item, recipient, address, distance, fee, and price snapshots.
- Reviews reference Customer, order, order item, and menu item IDs.
- Notification records reference an authorized order and are scoped under the recipient.
- Device records are scoped under a user to support multiple FCM tokens.
