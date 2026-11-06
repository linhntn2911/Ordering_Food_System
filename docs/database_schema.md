# Food Ordering Firestore Schema

## Purpose

Cloud Firestore is the shared source of truth for Customer and Admin data. Firebase Authentication stores credentials and supplies the UID. SharedPreferences stores only non-sensitive device configuration. Firebase Storage stores binary images while Firestore stores their URLs.

## Naming and Value Rules

- Collection and field names use `lower_snake_case` for collections and `lowerCamelCase` for fields.
- Monetary values are integer VND, never formatted strings or floating-point values.
- Shared timestamps use Firestore server timestamps.
- User-owned paths use the authenticated UID.
- Roles, account status, totals, fees, distances, and order transitions are protected or trusted values.
- Historical orders store immutable snapshots instead of depending on mutable menu or address documents.

## Collections

### `users/{uid}`

| Field | Type | Required | Notes |
|---|---|---:|---|
| `fullName` | string | yes | Customer display name |
| `email` | string | yes | Mirrors Firebase Authentication email |
| `phone` | string | yes | Validated recipient contact |
| `avatarUrl` | string | no | Firebase Storage URL |
| `role` | string | yes | `customer` or protected `admin` |
| `status` | string | yes | `active` or `disabled` |
| `createdAt` | timestamp | yes | Server timestamp |
| `updatedAt` | timestamp | yes | Server timestamp |

Document ID equals the Firebase Authentication UID. Customers can update only permitted profile fields; they cannot update role or status.

### `users/{uid}/addresses/{addressId}`

| Field | Type | Required | Notes |
|---|---|---:|---|
| `userId` | string | yes | Must equal the authenticated UID and parent user ID |
| `label` | string | yes | For example `Nhà riêng` or `Văn phòng` |
| `recipientName` | string | yes | Delivery recipient |
| `phoneNumber` | string | yes | Validated Vietnamese mobile number |
| `streetAddress` | string | yes | House number and street |
| `ward`, `district`, `city` | string | no | Normalized administrative divisions |
| `latitude`, `longitude` | number | no | Resolved delivery pin; required by the app before saving |
| `placeId` | string | no | Geocoding-provider place identifier |
| `locationProvider` | string | no | Currently `geoapify` |
| `routeDistanceKm` | number | no | Resolved driving distance preview |
| `isDefault` | boolean | yes | Exactly one default when the address book is non-empty |
| `createdAt`, `updatedAt` | timestamp | yes | Firestore server timestamps |

Only the owner can read or write. The repository uses atomic write batches when
changing or promoting the default address.

### `users/{uid}/favorites/{menuItemId}`

Fields: `menuItemId`, `createdAt`. The menu item ID is also the document ID to prevent duplicates.

### `users/{uid}/cart_items/{cartItemId}`

Fields: `menuItemId`, `selectedSize`, `selectedToppings`, `quantity`, `note`, `previewUnitPrice`, `updatedAt`. Preview prices are revalidated at checkout.

### `users/{uid}/notifications/{notificationId}`

Fields: `type`, `title`, `body`, `orderId`, `isRead`, `createdAt`, optional `readAt`. The Customer can read and change read state; trusted code creates notification records.

### `users/{uid}/devices/{deviceId}`

Fields: `fcmToken`, `platform`, `isEnabled`, `lastSeenAt`, `updatedAt`. One user can register multiple devices.

### `categories/{categoryId}`

Fields: `name`, `imageUrl`, `sortOrder`, `isPublished`, `createdAt`, `updatedAt`. Published categories are publicly readable; Admin manages them.

### `menu_items/{menuItemId}`

Fields: `categoryId`, `name`, `description`, `imageUrl`, `basePrice`, `isAvailable`, `isPublished`, `sortOrder`, `ratingAverage`, `reviewCount`, `sizes`, `toppings`, `isCategoryPublished`, `categorySortOrder`, `createdAt`, `updatedAt`.

- `sizes` and `toppings` are arrays of `{ id, name, priceDelta }` maps. `priceDelta` is a non-negative integer VND amount added to `basePrice`. The current Admin form supports optional sizes `{ id: "m", name: "M", priceDelta: 0 }` and `{ id: "l", name: "L", priceDelta: <surcharge> }`. Missing `sizes` is treated as an empty array for older records.
- `isCategoryPublished` and `categorySortOrder` are denormalized copies of the owning category's `isPublished` and `sortOrder`. Firestore rules cannot read the owning category during list queries, so these copies let the rules hide items of unpublished categories and let one query order items by category.
- **Denormalization invariant**: whoever changes a category's `isPublished` or `sortOrder` (Admin or trusted code) MUST update `isCategoryPublished` and `categorySortOrder` on every item of that category in the same batch or transaction. Items written without these fields are not publicly readable.

Items where `isPublished == true` and `isCategoryPublished == true` are publicly readable regardless of `isAvailable`; unavailable items stay visible with a sold-out label (see `specs/002-browse-menu/spec.md`). Admin reads and manages all items.

Menu images are stored under `menu_items/{menuItemId}/{timestamp}.{extension}` in Firebase Storage. The client writes image bytes only for an authenticated active Admin, while Firestore stores the resulting download URL.

### `orders/{orderId}`

Fields: `orderCode`, `customerId`, `customerName`, `customerPhone`, `deliveryAddress`, `deliveryDistanceKm`, `subtotal`, `deliveryFee`, `totalAmount`, `paymentMethod`, `paymentStatus`, `orderStatus`, `customerNote`, `cancellationReason`, `rejectionReason`, `createdAt`, `updatedAt`, optional `completedAt`.

Delivery fee rules are 15,000 VND through 3 km, 20,000 VND above 3 km through 5 km, and 30,000 VND above 5 km through 8 km. Unknown distances and distances above 8 km are rejected. Trusted code must create orders because client-provided totals are not authoritative.

### `orders/{orderId}/items/{orderItemId}`

Fields: `menuItemId`, `name`, `imageUrl`, `basePrice`, `selectedSize`, `selectedToppings`, `quantity`, `unitPrice`, `lineTotal`, `note`, `reviewed`. All commercial fields are immutable snapshots.

### `orders/{orderId}/status_events/{eventId}`

Fields: `fromStatus`, `toStatus`, `actorId`, `actorRole`, optional `reason`, `createdAt`. Events form the Customer timeline and audit history.

### `reviews/{reviewId}`

Fields: `customerId`, `orderId`, `orderItemId`, `menuItemId`, `rating`, `comment`, `imageUrls`, `isAnonymous`, `isEdited`, `createdAt`, `updatedAt`. Trusted code validates order ownership, completion, review windows, duplicate prevention, and rating aggregation. Only the owner Customer and Admin can read it, because it contains customer and order identifiers.
**Free-tier implementation (no Cloud Functions, Spark plan):** the Customer writes the private review and the public copies directly. Firestore rules enforce owner, `Completed` order status, a 30-day window from `orders.updatedAt`, rating 1-5, comment and image limits, and one review per order through the document id `<uid>_<orderId>`. Deviation from the write invariant: `ratingAverage` and `reviewCount` on `menu_items` are not updated atomically yet, and `orderItemId`/order item `reviewed` are not set. Restore trusted aggregation when a backend is available.

### `menu_items/{menuItemId}/reviews/{reviewId}`

Public display copy of a review for the Food Details screen (`specs/004-food-details`). Fields: `rating` (1-5), `comment`, `imageUrls` (at most three), `isAnonymous`, `isEdited`, `createdAt`, `updatedAt`. The `reviewId` matches the private `reviews/{reviewId}` document.

- It never contains `customerId`, `orderId`, `orderItemId`, or any customer name. The app shows the author as "Khách hàng" or "Khách hàng ẩn danh".
- Readable when the parent menu item is publicly readable (`isPublished` and `isCategoryPublished`), or by Admin. No client may write it.
- **Write invariant**: trusted code (the review submission feature) MUST create, update, and delete this copy in the same batch or transaction as the private review and the item's `ratingAverage` and `reviewCount`. A review without its public copy does not appear on Food Details.

### `restaurant_configs/main`

Fields: `restaurantName`, `address`, `latitude`, `longitude`, `paymentMethods`, `deliveryRules`, `maxDeliveryDistanceKm`, `updatedAt`. This document is publicly readable and Admin or trusted-code writable. The initial `paymentMethods` value is `["cod"]` and the maximum distance is `8`.

## Derived Data

Sales reports are derived from completed orders and order items. No independent `sales_reports` collection is required initially. Average ratings and review counts are denormalized on menu items but updated atomically with review changes.

## Required Indexes

`firestore.indexes.json` defines published menu ordering, category menu filtering, Customer order history, Admin status queues, and recent reviews by menu item.

## Order-issue chat

The order_chats collection uses the order ID as its document ID. It stores the order code, customer ID, issue type, opening role, latest message ID, time, preview, sender role and both unread flags. Its messages subcollection stores sender UID and role, trimmed text, attachment references and server time. The client stores up to three HTTPS image URLs in imagePaths. Legacy Storage paths at order_chats/{orderId}/{messageId}/{index}.jpg remain readable. Existing orders need no migration. The rules derive the 24-hour window from completedAt or updatedAt for terminal orders.
