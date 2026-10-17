# Feature Specification: Food Ordering System

**Feature ID**: `001-food-ordering-system`  
**Created**: 2026-10-17  
**Status**: Draft ready for clarification and planning  
**Product**: Flutter mobile application for one restaurant  
**Input**: Course requirements, the revised `Project_PRM (3).docx` Food Ordering System SRS, and the architecture patterns reviewed in `Example-PRM393`

## Scope Decision

The application supports food ordering from one restaurant. Guests can browse the menu. Registered customers can manage a cart, delivery addresses, COD orders, reviews, favorites, and notifications. Pre-provisioned administrators manage the menu and process orders from the same mobile application through role-based navigation.

The first release uses Cash on Delivery only. It does not include an online payment gateway, a driver application, live GPS tracking, chat, multi-restaurant support, or complex voucher rules.

## Actors

### Human Actors

- **Guest**: An unauthenticated state that can browse, search, filter, and view food details.
- **Customer**: An authenticated user who can manage personal data, addresses, favorites, cart, orders, reviews, and notifications.
- **Admin**: A pre-provisioned internal user who can manage categories and menu items, process orders, and view sales reports.

### External Systems

- **Firebase Authentication**: Authenticates customers and administrators, maintains the authenticated session, and supports password reset.
- **Email delivery service**: Delivers password-reset and registration welcome or verification email initiated through Firebase Authentication or trusted backend code.
- **Cloud Firestore**: Stores application data and provides real-time updates.
- **Firebase Cloud Messaging**: Delivers order and operational push notifications.
- **Firebase Storage**: Stores menu and optional review images.
- **Trusted notification backend**: Sends FCM messages after verified Firestore events; this may be implemented with Cloud Functions or another trusted server environment.

## User Scenarios and Testing

### User Story 1 - Discover Food (Priority: P1)

As a Guest or Customer, I want to browse categories, search and filter food, and inspect item details so that I can decide what to order.

**Why this priority**: Menu discovery is the entry point to every order.

**Independent Test**: Seed categories and menu items, open the app without signing in, find an item by category and search, and view its current price, options, rating, and availability.

**Acceptance Scenarios**:

1. **Given** published menu data exists, **When** a Guest opens Home, **Then** available categories and food items are displayed with loading, empty, and error states.
2. **Given** a Guest enters a search phrase or filter, **When** matching data exists, **Then** only matching available items are shown.
3. **Given** an item is unavailable, **When** its details are opened, **Then** the screen explains that it cannot be added to the cart.

### User Story 2 - Create and Access an Account (Priority: P1)

As a Customer, I want to register, sign in, sign out, and reset my password so that I can use personalized ordering features securely.

**Why this priority**: Ordering and personal data require an authenticated identity.

**Independent Test**: Register with full name, email, phone, password, and matching confirmation; verify automatic Customer sign-in and registration email delivery; sign out, sign in again, and request a password reset email.

**Acceptance Scenarios**:

1. **Given** a Guest provides full name, a valid unique email, a valid phone number, a password of at least six characters, and matching confirmation, **When** registration succeeds, **Then** Firebase Authentication creates the account, Firestore creates a Customer profile, the session starts, and Home opens.
2. **Given** registration succeeds, **When** the account is established, **Then** the configured email service sends a welcome or verification email without exposing mail credentials in the client.
3. **Given** valid credentials for an active account, **When** a user signs in, **Then** the app retrieves the protected role and routes a Customer to Home or the previously requested flow and an Admin to the Order Queue or Management Dashboard.
4. **Given** an existing email, **When** password reset is requested, **Then** Firebase initiates the reset flow and the app shows a neutral success message.
5. **Given** invalid registration input or an authentication failure, **When** a form is submitted, **Then** field-level or actionable feedback is shown without losing valid input.
6. **Given** a disabled or blocked account, **When** sign-in is attempted, **Then** access is denied with an actionable account-status message.
7. **Given** five consecutive failed sign-in attempts, **When** another attempt occurs during the next 15 minutes, **Then** the trusted authentication layer rejects it and communicates the remaining lockout condition.

### User Story 3 - Build a Cart and Place a COD Order (Priority: P1)

As a Customer, I want to configure food items, manage quantities, choose an address, and place a COD order so that the restaurant can prepare and deliver my meal.

**Why this priority**: This is the primary business transaction and MVP value.

**Independent Test**: Add configured items to a cart, modify them, select or create an address, review totals, and submit one COD order.

**Acceptance Scenarios**:

1. **Given** an available food item, **When** the Customer selects required options and a valid quantity, **Then** the configured line is added and totals are recalculated.
2. **Given** an identical item configuration already exists, **When** it is added again, **Then** its quantity is increased rather than creating an ambiguous duplicate.
3. **Given** a non-empty valid cart and serviceable delivery address, **When** Checkout opens, **Then** the system calculates the restaurant-to-address distance, applies the matching delivery-fee band, and displays the resulting total.
4. **Given** the selected address is changed, **When** its distance is resolved, **Then** the delivery fee and order total are recalculated before confirmation.
5. **Given** the address is more than 8 km away or its distance cannot be determined, **When** confirmation is attempted, **Then** the system blocks the order and asks the Customer to choose or correct the address.
6. **Given** a valid serviceable address, **When** the Customer confirms COD checkout, **Then** one `Pending` order is created with immutable distance and delivery-fee snapshots and the submitted cart lines are cleared.
7. **Given** price or availability changed before confirmation, **When** checkout validates the cart, **Then** submission stops and the Customer is shown which lines require attention.

### User Story 4 - Track and Cancel an Order (Priority: P1)

As a Customer, I want to view order history and status changes and cancel a pending order so that I understand and control an active order.

**Why this priority**: Customers need visibility after checkout and a safe cancellation window.

**Independent Test**: Open a newly placed order, observe its timeline, cancel it while pending, and verify the updated state in both Customer and Admin views.

**Acceptance Scenarios**:

1. **Given** the Customer owns orders, **When** Order History opens, **Then** orders are sorted newest first and can be filtered by status.
2. **Given** a `Pending` order, **When** the Customer provides a reason and confirms cancellation, **Then** the status becomes `Cancelled` atomically.
3. **Given** the order has already left `Pending`, **When** cancellation is attempted, **Then** the action is rejected and the current state remains unchanged.

### User Story 5 - Process Orders as Admin (Priority: P1)

As an Admin, I want a real-time order queue and controlled status actions so that I can accept, prepare, dispatch, complete, or reject orders correctly.

**Why this priority**: Customer orders have no value until the restaurant can process them.

**Independent Test**: Place a Customer order, open it in the Admin queue, and move it through every allowed state while verifying invalid transitions are blocked.

**Acceptance Scenarios**:

1. **Given** a new order, **When** it is created, **Then** it appears in the Admin queue without a manual refresh.
2. **Given** a `Pending` order, **When** the Admin confirms or rejects it, **Then** only the selected valid transition is committed.
3. **Given** the Admin rejects a `Pending` order, **When** the action is submitted, **Then** a non-empty rejection reason is required and stored for the Customer and audit history.
4. **Given** a confirmed order, **When** the Admin processes it, **Then** statuses follow `Confirmed -> Preparing -> OutForDelivery -> Completed`.
5. **Given** concurrent Admin and Customer actions, **When** both target the same order, **Then** a transaction prevents stale or conflicting state changes.

### User Story 6 - Receive Order Notifications (Priority: P1)

As a Customer or Admin, I want timely push and in-app notifications about relevant order events so that I can act without repeatedly refreshing the application.

**Why this priority**: Notifications connect the Customer and restaurant during a time-sensitive workflow and satisfy a course requirement.

**Independent Test**: Trigger new-order, cancellation, confirmation, preparation, delivery, completion, and rejection events and verify the correct recipient receives a notification linked to the order.

**Acceptance Scenarios**:

1. **Given** notifications are permitted and a valid token exists, **When** an order event occurs, **Then** the trusted backend sends an FCM message and stores an in-app notification.
2. **Given** the user taps an order notification, **When** the app opens from foreground, background, or terminated state, **Then** it routes to the authorized Order Details screen.
3. **Given** push delivery is unavailable, **When** the user reconnects, **Then** Firestore still provides the current order state and notification history.

### User Story 7 - Manage Menu and Categories (Priority: P2)

As an Admin, I want to create, update, publish, unpublish, and categorize food items so that customers see an accurate menu.

**Why this priority**: Menu accuracy is required for reliable ordering but can initially use seeded data.

**Independent Test**: Add a category and menu item, edit the item, toggle availability, and verify the Customer menu updates.

**Acceptance Scenarios**:

1. **Given** a valid Admin session, **When** a category or item is saved, **Then** validated data is persisted and reflected in Customer browsing.
2. **Given** an item is referenced by historical orders, **When** the Admin removes it from sale, **Then** it is unpublished rather than destroying historical order data.
3. **Given** a non-Admin user, **When** an administrative write is attempted, **Then** both the UI and Firestore rules deny it.

### User Story 8 - Manage Customer Preferences and Saved Data (Priority: P2)

As a Customer, I want to manage profile data, delivery addresses, and favorites so that checkout and repeat discovery are faster.

**Why this priority**: These features improve usability and support checkout without expanding the core transaction.

**Independent Test**: Update the profile, create and choose a default address, favorite an item, restart the app, and verify the correct persisted state.

**Acceptance Scenarios**:

1. **Given** valid address data, **When** the Customer creates or edits an address, **Then** it is saved under that Customer and can be selected at checkout.
2. **Given** several addresses, **When** one becomes default, **Then** all other addresses for that Customer are non-default.
3. **Given** an available item, **When** favorite status is toggled, **Then** the Favorites screen and food card stay synchronized.

### User Story 9 - Review Purchased Items (Priority: P2)

As a Customer, I want to rate and review food from a completed order so that I can share useful feedback.

**Why this priority**: Reviews improve later purchase decisions and complete the post-order flow.

**Independent Test**: Complete an order, submit one review for a purchased item, and verify it appears on the item details and cannot be duplicated for the same order line.

**Acceptance Scenarios**:

1. **Given** an unreviewed item in a completed order within 30 days, **When** the Customer submits a 1-5 star rating and valid optional content, **Then** one review is saved and aggregate rating data is updated.
2. **Given** a 1-2 star rating, **When** the required explanation is missing, **Then** submission is blocked with field-level feedback.
3. **Given** a review owned by the Customer, **When** edit or delete is requested within its permitted window, **Then** the action succeeds and aggregate rating data is recalculated.

### User Story 10 - View Sales Summary (Priority: P3)

As an Admin, I want a compact sales report so that I can inspect completed-order revenue and popular items.

**Why this priority**: Reporting is useful for the demonstration but does not block the ordering lifecycle.

**Independent Test**: Complete seeded orders across several days and compare displayed totals and top items with the source order records.

**Acceptance Scenarios**:

1. **Given** completed orders exist, **When** the Admin chooses a date range, **Then** the report shows completed order count, COD revenue, and top-selling items for that range.
2. **Given** no completed orders exist in the selected range, **When** the report loads, **Then** it shows a clear zero-data state.

## Edge Cases

- The device loses connectivity during a write; the UI must show pending or failed state and prevent accidental duplicate submissions.
- A user double-taps Confirm Order; an idempotency key or transaction must ensure only one order is created.
- The menu item price, options, or availability changes while it is already in a cart.
- Customer cancellation and Admin confirmation occur at nearly the same time.
- FCM permission is denied, a token expires, or the user has multiple devices.
- A deep link points to an order owned by another user or to a deleted record.
- An Admin unpublishes a category containing active items.
- The default delivery address is deleted while referenced by an open checkout; the order must store an immutable address snapshot.
- A completed order is reopened after the review window expires.
- Review image upload partially succeeds; unsaved files must not create a broken review.
- Delivery distance cannot be resolved, falls exactly on a fee-band boundary, or exceeds the 8 km service radius.
- A disabled account or temporarily locked account attempts to reuse an existing local session.

## Requirements

### Functional Requirements

#### Account and Access

- **FR-001**: The system MUST allow Customer registration through Firebase Authentication using full name, email, phone number, password, and password confirmation.
- **FR-002**: Registration MUST validate required fields, email and phone formats, a password of at least six characters, matching confirmation, and email uniqueness.
- **FR-003**: After successful registration, the system MUST create a Firestore profile with the protected default role `Customer`, establish the authenticated session, route to Home, and initiate a welcome or verification email.
- **FR-004**: The system MUST allow active Customer and pre-provisioned Admin accounts to sign in and sign out and MUST route them by their protected Firestore role.
- **FR-005**: The system MUST support password reset through Firebase Authentication email delivery.
- **FR-006**: Protected screens and Firestore operations MUST enforce ownership, active-account status, and role authorization; a mobile client MUST NOT create or promote an Admin.
- **FR-044**: After five consecutive failed sign-in attempts, the trusted authentication layer MUST enforce a 15-minute temporary lockout and the client MUST display the lockout state.
- **FR-045**: Firebase Authentication MUST own and restore authentication sessions across application restarts until sign-out, revocation, disablement, or expiration; the app MUST NOT persist raw session tokens in SharedPreferences.

#### Menu Discovery

- **FR-007**: Guests and Customers MUST be able to browse published categories and available menu items.
- **FR-008**: Users MUST be able to search menu items by name and filter by category and availability.
- **FR-009**: Food Details MUST show image, name, description, base price, available options, rating summary, availability, and reviews.
- **FR-010**: Customers MUST be able to add and remove favorite items.

#### Cart and Checkout

- **FR-011**: Customers MUST be able to add a configured item containing quantity, selected size, toppings, and note.
- **FR-012**: Customers MUST be able to update or remove cart lines and see recalculated totals.
- **FR-013**: The system MUST validate required options, quantity limits, price, and current availability before checkout.
- **FR-014**: Checkout MUST require one valid delivery address and a recipient phone number.
- **FR-015**: The only payment method in scope MUST be Cash on Delivery.
- **FR-016**: A successful submission MUST create exactly one immutable order snapshot with status `Pending`, delivery distance, delivery fee, address, recipient, and item-price snapshots and clear only the submitted cart lines.
- **FR-046**: Checkout MUST calculate the distance between the restaurant and selected delivery address and MUST recalculate it whenever the address changes.
- **FR-047**: The delivery fee MUST be 15,000 VND for distance up to and including 3 km, 20,000 VND for distance greater than 3 km and up to and including 5 km, and 30,000 VND for distance greater than 5 km and up to and including 8 km.
- **FR-048**: Checkout MUST block confirmation when delivery distance is greater than 8 km or cannot be determined and MUST request a different or corrected address.
- **FR-049**: The order total MUST equal validated item subtotals plus the authoritative delivery fee.

#### Addresses and Profile

- **FR-017**: Customers MUST be able to view, create, edit, delete, and select delivery addresses.
- **FR-018**: The system MUST allow exactly one default address per Customer.
- **FR-019**: Customers MUST be able to view and update allowed profile fields.

#### Orders

- **FR-020**: Customers MUST be able to view their own order history and order details.
- **FR-021**: Customers MUST be able to cancel only their own `Pending` order and MUST provide a reason.
- **FR-022**: Admins MUST receive and filter a real-time order queue.
- **FR-023**: Admins MUST be able to confirm or reject a `Pending` order, and rejection MUST require a non-empty reason.
- **FR-024**: Admins MUST be able to apply only permitted sequential status transitions.
- **FR-025**: Every order state transition MUST record actor, source state, target state, timestamp, and reason when required for cancellation or rejection.
- **FR-026**: Historical orders MUST retain item name, price, selected options, recipient, phone, and delivery address snapshots.
- **FR-050**: Every created order MUST receive a unique structured code in the form `ORD-YYYYMMDD-XXXX` or an equivalently collision-safe documented format.

#### Reviews

- **FR-027**: Only the owner of a completed order line MAY maintain one active review for that line within 30 days of completion.
- **FR-028**: A review MUST contain a 1-5 star rating; text is required for 1-2 stars and limited to 500 characters.
- **FR-029**: A review MAY contain at most three images, each no larger than 5 MB.
- **FR-030**: A review MAY be edited once within 7 days and deleted within 30 days by its owner; deletion restores submission eligibility only while the original 30-day post-completion window remains open.
- **FR-031**: Review create, update, and delete operations MUST keep item rating aggregates consistent.

#### Menu Administration

- **FR-032**: Admins MUST be able to list, create, edit, publish, and unpublish categories and menu items.
- **FR-033**: Menu item input MUST validate name, category, non-negative price, image, description, options, and availability.
- **FR-034**: Menu records referenced by orders MUST be archived or unpublished instead of hard-deleted.

#### Notifications

- **FR-035**: The app MUST register and refresh FCM device tokens for authenticated users.
- **FR-036**: New and cancelled orders MUST notify every active registered Admin device.
- **FR-037**: Confirmed, rejected, preparing, out-for-delivery, completed, and cancelled events MUST notify the affected Customer.
- **FR-038**: Each push event MUST also create an in-app notification record.
- **FR-039**: A notification tap MUST deep-link to an authorized relevant screen.
- **FR-040**: FCM sends MUST originate from trusted backend code and MUST NOT expose server credentials in the Flutter client.

#### Reporting and Local Configuration

- **FR-041**: Admins MUST be able to view completed-order count, COD revenue, and top-selling items by date range.
- **FR-042**: SharedPreferences MUST persist local non-sensitive configuration including onboarding completion, language choice, notification preference hints, and other approved light-mode settings.
- **FR-043**: Secrets, roles, order truth, and authentication tokens MUST NOT be stored as authoritative data in SharedPreferences.

### Business Rules

- **BR-001**: Order status transitions are `Pending -> Confirmed -> Preparing -> OutForDelivery -> Completed`.
- **BR-002**: `Pending -> Rejected` and `Pending -> Cancelled` are terminal alternatives.
- **BR-003**: A Customer may cancel only while the order is still `Pending`.
- **BR-004**: One order uses one delivery address snapshot and one COD payment method.
- **BR-005**: The order total equals the sum of validated line totals plus the configured delivery fee.
- **BR-006**: A cart line is identical only when menu item, size, toppings, and note are identical.
- **BR-007**: Completed orders alone contribute to sales reports and unlock reviews.
- **BR-008**: Customer data is isolated by authenticated UID; Admin data access requires a trusted Admin role.
- **BR-009**: Every order status change creates one notification event and one audit entry.
- **BR-010**: Server timestamps are authoritative for orders, reviews, notifications, and audit events.
- **BR-011**: A Customer must be authenticated before adding or modifying cart items.
- **BR-012**: Every cart item must reference an available food item and contain a valid quantity, required size, selected toppings, and optional note.
- **BR-013**: Cart line subtotals must be recalculated whenever quantity, size, or toppings change; an identical configuration increases quantity instead of creating an ambiguous duplicate.
- **BR-014**: Delivery-fee bands are 15,000 VND for `0 < distance <= 3 km`, 20,000 VND for `3 < distance <= 5 km`, and 30,000 VND for `5 < distance <= 8 km`.
- **BR-015**: Orders beyond 8 km or without a determinable delivery distance are not accepted.
- **BR-016**: Self-registration always assigns `Customer`; Admin accounts are pre-provisioned and protected from client modification.
- **BR-017**: Five consecutive failed sign-in attempts trigger a 15-minute lockout enforced by a trusted authentication layer.

### Required Technical Constraints

- The client MUST be built with Flutter and Dart.
- Presentation MUST follow MVVM: Views render state and forward intent; ViewModels coordinate use cases and expose immutable state; repositories own data access.
- Riverpod MUST manage application state and dependency injection through the official `flutter_riverpod` package declared in `pubspec.yaml` and imported with `package:flutter_riverpod/flutter_riverpod.dart`.
- Agents and contributors MUST NOT invent, imitate, vendor, or create project-local replacements for Riverpod classes, providers, refs, notifiers, widgets, or runtime behavior. Application-specific providers and ViewModels MUST use the official package API.
- Riverpod code generation MAY be used only through the official supporting packages, and generated `.g.dart` files MUST NOT be written or edited manually.
- Firebase Authentication MUST provide login-related identity operations.
- Cloud Firestore MUST be the primary shared database for this release.
- Firebase Cloud Messaging MUST provide push notifications.
- SharedPreferences MUST persist local configuration state.
- Firebase Storage SHOULD store menu and review images when image upload is implemented.
- The UI MUST use the light-only Food Ninja design system defined in `docs/design_system.md` and reusable widgets rather than screen-specific copies.
- The application MUST expose only `ThemeMode.light`; dark-mode frames, a dark theme, and a user-facing theme toggle are out of scope.
- All in-app typography MUST use bundled Poppins fonts; logo lettering SHOULD remain an exported vector asset.
- Brand colors, gradients, typography, spacing, radii, and shadows MUST be centralized under `lib/core/theme/`; feature widgets MUST NOT define competing token sets.

### Non-Functional Requirements

- **NFR-001 Security**: Firestore and Storage rules MUST enforce user ownership and Admin-only operations; client-side hiding alone is insufficient.
- **NFR-002 Responsiveness**: Every asynchronous screen MUST define loading, success, empty, and error states without blocking the UI thread.
- **NFR-003 Reliability**: Order creation and status transitions MUST use transactions or equivalent atomic checks.
- **NFR-004 Performance**: Initial list queries MUST be paginated or bounded and supported by required indexes.
- **NFR-005 Maintainability**: Feature code MUST follow the structure in `AGENTS.md`, use snake_case files and PascalCase types, and avoid business logic in widgets.
- **NFR-006 Testability**: Repositories MUST be replaceable with fakes; critical ViewModels and primary journeys MUST have automated tests.
- **NFR-007 Accessibility**: Interactive controls MUST have readable contrast, semantic labels, and touch targets of at least 48 logical pixels where practical.
- **NFR-008 Consistency**: Colors, typography, spacing, radius, and shared components MUST come from centralized theme and token files.
- **NFR-009 Visual fidelity**: Customer and Admin screens MUST follow `docs/design_system.md`, including the `#53E88B -> #15BE77` primary gradient, Poppins type scale, 4-point spacing grid, and light-only surfaces.

## Key Entities

- **AppUser**: UID, email, display name, phone, photo URL, trusted role, account status, timestamps.
- **Address**: Owner UID, label, recipient, phone, normalized address lines, coordinates or other approved distance input, default flag, timestamps.
- **Category**: Name, image URL, sort order, published flag, timestamps.
- **MenuItem**: Category ID, name, description, image URL, base price, option groups, availability, rating summary, timestamps.
- **Favorite**: Customer UID and menu item ID pair.
- **CartItem**: Customer UID, menu item reference, option snapshot, quantity, note, calculated preview price, timestamps.
- **Order**: Customer UID, order code, recipient and address snapshots, delivery-distance and delivery-fee snapshots, COD payment state, monetary totals, current status, cancellation/rejection reason, timestamps.
- **OrderItem**: Menu item ID plus immutable name, image, price, options, quantity, note, and review state snapshot.
- **OrderStatusEvent**: Order ID, actor UID/type, from status, to status, reason, server timestamp.
- **Review**: Customer UID, order ID, order item ID, menu item ID, rating, comment, media URLs, anonymous flag, edit state, timestamps.
- **Notification**: Recipient UID, order ID, event type, title, body, read flag, deep-link data, timestamp.
- **DeviceToken**: UID, token, platform, enabled flag, last-seen timestamp.

## Screen Inventory and Team Allocation

Screen complexity is based on meaningful data state, validation, navigation, asynchronous operations, or multi-action behavior. Static splash artwork and simple dialogs do not count toward the course minimum.

| Owner | Screen | Complexity | Main responsibility |
|---|---|---:|---|
| Member 1 | Onboarding | Supporting | Explain app and persist completion state |
| Member 1 | Login | Medium | Validation, auth state, role routing |
| Member 1 | Register | Medium | Validation and profile creation |
| Member 1 | Forgot Password | Medium | Firebase reset flow and feedback |
| Member 1 | Profile | Medium | Load and update Customer profile |
| Member 2 | Home | Medium | Categories, featured items, async states |
| Member 2 | Search and Filter | Medium | Query, filters, sort, empty states |
| Member 2 | Food Details | High | Options, quantity, reviews, add to cart |
| Member 2 | Favorites | Medium | Reactive saved-item list and removal |
| Member 3 | Cart | High | Line editing, selection, totals, validation |
| Member 3 | Checkout | High | Address selection, summary, atomic submit |
| Member 3 | Address List | Medium | Default selection and CRUD navigation |
| Member 3 | Add or Edit Address | Medium | Form validation, normalization, serviceability, and persistence |
| Member 4 | Order History | Medium | Status tabs, filters, real-time updates |
| Member 4 | Order Details and Tracking | High | Timeline, cancellation, state actions |
| Member 4 | Review Purchased Item | Medium | Rating, text, images, validation |
| Member 4 | Notifications | Medium | Inbox, read state, deep links |
| Member 5 | Admin Order List | High | Real-time queue, status filters, alerts |
| Member 5 | Admin Order Details | High | Validation and status transitions |
| Member 5 | Menu Item List | Medium | Search, filter, publish state |
| Member 5 | Add or Edit Menu Item | High | Validated form, options, image upload |
| Member 5 | Category Management | Medium | Ordered CRUD and publication rules |
| Member 5 | Sales Report | Medium | Date range, metrics, top items, zero state |

Each member owns at least three Medium-or-higher screens. Shared widgets, Firebase setup, rules, test infrastructure, and integration work remain team responsibilities and do not replace individual screen ownership.

## Success Criteria

- **SC-001**: All five members can demonstrate at least three independently functional Medium-or-higher screens they own.
- **SC-002**: A first-time Customer can register, add an item, enter an address, and place a COD order in under five minutes without external guidance.
- **SC-003**: A submitted order appears in the Admin queue within five seconds under normal network conditions.
- **SC-004**: Valid order status changes appear on the Customer order screen and produce an in-app notification without manual refresh.
- **SC-005**: Duplicate taps on order submission create no more than one order.
- **SC-006**: Unauthorized Customer reads or writes against another user's protected data fail in Firebase emulator or rules tests.
- **SC-007**: `flutter analyze` completes without errors and the automated test suite passes before a feature is considered done.
- **SC-008**: The 23-screen inventory uses the same centralized colors, type scale, spacing, radius, and reusable components.
- **SC-009**: Checkout applies the three SRS delivery-fee bands correctly at 3 km, 5 km, and 8 km boundaries and rejects distances above 8 km.

## Assumptions

- The application targets Android first; iOS-compatible Flutter code is retained where practical.
- The restaurant has one delivery operation and Admin users manually set `OutForDelivery`; there is no driver role.
- COD payment collection occurs outside the app; the app records the selected payment method and completed order state.
- Seed data may be used during early UI development, but completed features read and write Firestore through repositories.
- The revised SRS fixes delivery fees at 15,000, 20,000, and 30,000 VND for the defined distance bands and fixes the delivery radius at 8 km.
- The technical plan must choose and document how a normalized address is converted into an authoritative restaurant-to-address distance; the SRS does not name a map or geocoding provider.
- The COD maximum, cart quantity limit, minimum review text for 1-2-star ratings, target Admin confirmation SLA, and merchant-reply authoring flow remain clarification items because the revised SRS does not provide complete usable values or use cases.

## Out of Scope

- Online payment, QR payment, refunds, and payment gateway callbacks. The Payment Gateway row retained in the source SRS is not active in this COD-only release because it has no corresponding approved payment use case.
- Driver or shipper accounts, driver assignment, and live GPS tracking. Checkout distance calculation is required, but a customer-facing live map is not required.
- Multiple restaurants, restaurant onboarding, commissions, or marketplace settlement.
- Customer-admin chat, voice calls, complex promotions, coupons, loyalty points, and scheduled delivery slots.
- Web administration portal; Admin uses the role-based Flutter application.

## Spec Kit Workflow State

This document completes the `specify` stage. Before implementation, the team must run or perform the equivalent of:

1. `constitution` - confirm project principles in `.specify/memory/constitution.md`.
2. `clarify` - resolve the distance/geocoding implementation, quantity limit, COD cap, review text minimum, registration email type, trusted lockout implementation, Admin confirmation SLA, and merchant-reply authoring flow.
3. `plan` - create `specs/001-food-ordering-system/plan.md` with Firebase schema, rules, architecture, navigation, and testing approach.
4. `checklist` - validate requirement quality.
5. `tasks` - create dependency-ordered, story-scoped tasks with exact file paths and member ownership.
6. `analyze` - check consistency among specification, plan, and tasks.
7. `implement` and `converge` - implement by story and repeat verification until no gaps remain.
