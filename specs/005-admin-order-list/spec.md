# Feature Specification: Admin Order List

**Feature ID**: `005-admin-order-list`  
**Status**: Approved for implementation  
**Owner**: Member 5 (Admin)

## User Story

As an Admin, I want to monitor a real-time queue of Ngô Chicken orders and
quickly find orders by status, code, or customer so that new orders are handled
without repeatedly refreshing the application.

## Acceptance Scenarios

1. Authenticated Admins receive a real-time list ordered by newest `createdAt`.
2. Each card shows order code, customer, phone, delivery address, created time,
   COD total, and current status.
3. Search filters the loaded queue by order code, customer name, or phone.
4. Status filters support All, Pending, Confirmed, Preparing, Out for delivery,
   Completed, Cancelled, and Rejected, and display matching counts.
5. A new order arriving after the initial snapshot produces a visible in-app
   alert without manual refresh.
6. Loading, empty queue, no search results, error, and retry states are visible.
7. Debug builds without authentication use clearly labelled in-memory preview
   data; authenticated builds use Firestore through the repository.
8. Selecting an order exposes a navigation callback for the separate Admin
   Order Details increment.

## Out of Scope

- Confirming, rejecting, or advancing an order status.
- Reading order item subcollections and the complete status timeline.
- Sending FCM notifications. These belong to Admin Order Details and trusted
  backend increments.

