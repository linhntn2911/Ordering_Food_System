# Feature Specification: Food Ordering System

**Feature ID**: `001-food-ordering-system`  
**Created**: 2026-10-17  
**Status**: Draft ready for clarification and planning  
**Product**: Flutter mobile application for one restaurant  
**Input**: Course requirements, the supplied Food Ordering System SRS, and the architecture patterns reviewed in `Example-PRM393`

## Scope Decision

The application supports food ordering from one restaurant. Guests can browse the menu. Registered customers can manage a cart, delivery addresses, COD orders, reviews, favorites, and notifications. Pre-provisioned administrators manage the menu and process orders from the same mobile application through role-based navigation.

The first release uses Cash on Delivery only. It does not include an online payment gateway, a driver application, live GPS tracking, chat, multi-restaurant support, or complex voucher rules.

## Actors

### Human Actors

- **Guest**: An unauthenticated state that can browse, search, filter, and view food details.
- **Customer**: An authenticated user who can manage personal data, addresses, favorites, cart, orders, reviews, and notifications.
- **Admin**: A pre-provisioned internal user who can manage categories and menu items, process orders, and view sales reports.

### External Systems

- **Firebase Authentication**: Authenticates customers and administrators and supports password reset.
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

**Independent Test**: Register a new account, sign out, sign in again, and request a password reset email.

**Acceptance Scenarios**:

1. **Given** valid registration data, **When** a Guest submits registration, **Then** a Firebase account and Customer profile are created.
2. **Given** valid credentials, **When** a user signs in, **Then** the app routes to the Customer or Admin area based on the trusted role.
3. **Given** an existing email, **When** password reset is requested, **Then** Firebase initiates the reset flow and the app shows a neutral success message.
4. **Given** invalid input or an authentication failure, **When** the form is submitted, **Then** field-level or actionable error feedback is shown without losing valid input.

### User Story 3 - Build a Cart and Place a COD Order (Priority: P1)

As a Customer, I want to configure food items, manage quantities, choose an address, and place a COD order so that the restaurant can prepare and deliver my meal.

**Why this priority**: This is the primary business transaction and MVP value.

**Independent Test**: Add configured items to a cart, modify them, select or create an address, review totals, and submit one COD order.

**Acceptance Scenarios**:

1. **Given** an available food item, **When** the Customer selects required options and a valid quantity, **Then** the configured line is added and totals are recalculated.
2. **Given** an identical item configuration already exists, **When** it is added again, **Then** its quantity is increased rather than creating an ambiguous duplicate.
3. **Given** a non-empty valid cart and delivery address, **When** the Customer confirms COD checkout, **Then** one `Pending` order is created and the submitted cart lines are cleared.
4. **Given** price or availability changed before confirmation, **When** checkout validates the cart, **Then** submission stops and the Customer is shown which lines require attention.

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
3. **Given** a confirmed order, **When** the Admin processes it, **Then** statuses follow `Confirmed -> Preparing -> OutForDelivery -> Completed`.
4. **Given** concurrent Admin and Customer actions, **When** both target the same order, **Then** a transaction prevents stale or conflicting state changes.

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

## Requirements

### Functional Requirements

#### Account and Access

- **FR-001**: The system MUST allow Customer registration using Firebase Authentication email and password.
- **FR-002**: The system MUST allow Customer and Admin sign-in and sign-out.
- **FR-003**: The system MUST support password reset through Firebase Authentication.
- **FR-004**: The system MUST create a Customer profile for a newly registered account.
- **FR-005**: Admin accounts MUST be pre-provisioned; a mobile client MUST NOT promote itself to Admin.
- **FR-006**: Protected screens and Firestore operations MUST enforce ownership and role authorization.

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
- **FR-016**: A successful submission MUST create exactly one immutable order snapshot with status `Pending` and clear only the submitted cart lines.

#### Addresses and Profile

- **FR-017**: Customers MUST be able to view, create, edit, delete, and select delivery addresses.
- **FR-018**: The system MUST allow exactly one default address per Customer.
- **FR-019**: Customers MUST be able to view and update allowed profile fields.

#### Orders

- **FR-020**: Customers MUST be able to view their own order history and order details.
- **FR-021**: Customers MUST be able to cancel only their own `Pending` order and MUST provide a reason.
- **FR-022**: Admins MUST receive and filter a real-time order queue.
- **FR-023**: Admins MUST be able to confirm or reject a `Pending` order.
- **FR-024**: Admins MUST be able to apply only permitted sequential status transitions.
- **FR-025**: Every order state transition MUST record actor, source state, target state, timestamp, and optional reason.
- **FR-026**: Historical orders MUST retain item name, price, selected options, recipient, phone, and delivery address snapshots.

#### Reviews

- **FR-027**: Only the owner of a completed order line MAY submit one review for that line within 30 days of completion.
- **FR-028**: A review MUST contain a 1-5 star rating; text is required for 1-2 stars and limited to 500 characters.
- **FR-029**: A review MAY contain at most three images, each no larger than 5 MB.
- **FR-030**: A review MAY be edited once within 7 days and deleted within 30 days by its owner.
- **FR-031**: Review create, update, and delete operations MUST keep item rating aggregates consistent.

#### Menu Administration

- **FR-032**: Admins MUST be able to list, create, edit, publish, and unpublish categories and menu items.
- **FR-033**: Menu item input MUST validate name, category, non-negative price, image, description, options, and availability.
- **FR-034**: Menu records referenced by orders MUST be archived or unpublished instead of hard-deleted.

#### Notifications

- **FR-035**: The app MUST register and refresh FCM device tokens for authenticated users.
- **FR-036**: New and cancelled orders MUST notify active Admin devices.
- **FR-037**: Confirmed, rejected, preparing, out-for-delivery, completed, and cancelled events MUST notify the affected Customer.
- **FR-038**: Each push event MUST also create an in-app notification record.
- **FR-039**: A notification tap MUST deep-link to an authorized relevant screen.
- **FR-040**: FCM sends MUST originate from trusted backend code and MUST NOT expose server credentials in the Flutter client.

#### Reporting and Local Configuration

- **FR-041**: Admins MUST be able to view completed-order count, COD revenue, and top-selling items by date range.
- **FR-042**: SharedPreferences MUST persist local non-sensitive configuration including onboarding completion, language or theme choice, and notification preference hints.
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

### Required Technical Constraints

- The client MUST be built with Flutter and Dart.
- Presentation MUST follow MVVM: Views render state and forward intent; ViewModels coordinate use cases and expose immutable state; repositories own data access.
- Riverpod MUST manage application state and dependency injection. Riverpod code generation MAY be used, and generated `.g.dart` files MUST NOT be edited manually.
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
- **Address**: Owner UID, label, recipient, phone, address lines, note, default flag, timestamps.
- **Category**: Name, image URL, sort order, published flag, timestamps.
- **MenuItem**: Category ID, name, description, image URL, base price, option groups, availability, rating summary, timestamps.
- **Favorite**: Customer UID and menu item ID pair.
- **CartItem**: Customer UID, menu item reference, option snapshot, quantity, note, calculated preview price, timestamps.
- **Order**: Customer UID, order code, recipient snapshot, address snapshot, COD payment state, monetary totals, current status, cancellation/rejection reason, timestamps.
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
| Member 3 | Add or Edit Address | Medium | Form validation and persistence |
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

## Assumptions

- The application targets Android first; iOS-compatible Flutter code is retained where practical.
- The restaurant has one delivery operation and Admin users manually set `OutForDelivery`; there is no driver role.
- COD payment collection occurs outside the app; the app records the selected payment method and completed order state.
- Seed data may be used during early UI development, but completed features read and write Firestore through repositories.
- Exact delivery fee and COD maximum are configuration values decided during planning.

## Out of Scope

- Online payment, QR payment, refunds, and payment gateway callbacks.
- Driver or shipper accounts, driver assignment, GPS maps, and live location.
- Multiple restaurants, restaurant onboarding, commissions, or marketplace settlement.
- Customer-admin chat, voice calls, complex promotions, coupons, loyalty points, and scheduled delivery slots.
- Web administration portal; Admin uses the role-based Flutter application.

## Spec Kit Workflow State

This document completes the `specify` stage. Before implementation, the team must run or perform the equivalent of:

1. `constitution` - confirm project principles in `.specify/memory/constitution.md`.
2. `clarify` - resolve remaining delivery fee, quantity limit, COD cap, and review text minimum decisions.
3. `plan` - create `specs/001-food-ordering-system/plan.md` with Firebase schema, rules, architecture, navigation, and testing approach.
4. `checklist` - validate requirement quality.
5. `tasks` - create dependency-ordered, story-scoped tasks with exact file paths and member ownership.
6. `analyze` - check consistency among specification, plan, and tasks.
7. `implement` and `converge` - implement by story and repeat verification until no gaps remain.
