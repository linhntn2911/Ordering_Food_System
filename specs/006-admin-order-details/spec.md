# Feature Specification: Admin Order Details

## Goal

Allow an Admin to inspect a complete order snapshot and move it through the approved fulfillment workflow.

## User Stories

1. As an Admin, I can open an order from the Admin Order List and see customer, delivery, item, payment, total, note, and status-history information.
2. As an Admin, I can move an order through `Pending -> Confirmed -> Preparing -> OutForDelivery -> Completed`.
3. As an Admin, I can reject a Pending order only after entering a reason.

## Acceptance Scenarios

- Given an order exists, when Admin opens it, then the latest order, item snapshots, totals, and status history are shown.
- Given a Pending order, when Admin confirms it, then the order changes to Confirmed and a status event is created atomically.
- Given a Pending order, when Admin rejects without a reason, then submission is blocked.
- Given a terminal order, when Admin opens it, then no further transition action is offered.
- Loading, empty-item, error, retry, disabled, and submitting states are visible.

## Constraints

- Only Admin can perform transitions.
- Only approved transitions are accepted.
- A transition and its audit event use one Firestore transaction.
- FCM sending remains trusted-backend work; the client never stores or uses server credentials.

