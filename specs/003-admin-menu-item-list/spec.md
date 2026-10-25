# Feature Specification: Admin Menu Item List

**Feature ID**: `003-admin-menu-item-list`  
**Status**: Approved for implementation  
**Owner**: Member 5 (Admin)

## User Story

As an Admin, I want to browse and search every menu item, filter by category,
and control publication and availability so the Ngô Chicken catalogue stays
accurate throughout the day.

## Acceptance Scenarios

1. The list includes published, hidden, available, and sold-out items for an authenticated Admin.
2. Search filters items by name without issuing a Firestore query for every keystroke.
3. Category chips filter the list using the category relationship.
4. Admin can mark an item available/sold out and published/hidden.
5. Loading, empty, no-result, error, retry, and disabled-action states are visible.
6. Firestore Rules remain the authority for all Admin writes.

## Out of Scope

- The Add/Edit Menu Item form, image upload, sizes, and toppings belong to the next increment.
- Hard deletion is prohibited for menu records.
