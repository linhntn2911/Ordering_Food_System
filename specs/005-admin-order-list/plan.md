# Implementation Plan: Admin Order List

Create an Order feature with an immutable entity, tolerant Firestore model,
repository interface, Firestore stream implementation, and debug preview
implementation. Official Riverpod providers inject the repository and a
Notifier owns search/status filter state. The View consumes AsyncValue states
and renders Food Ninja light order cards from shared theme tokens.

Firestore queries the latest bounded order documents by descending `createdAt`.
Search and status filtering run in memory to avoid issuing a query for every
keystroke. The list does not mutate order status; transaction-safe transitions
remain the responsibility of the next Admin Order Details increment.

