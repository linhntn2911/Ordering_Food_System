# Feature Specification: Admin Category Management

**Feature ID**: `002-admin-category-management`  
**Status**: Approved for implementation  
**Owner**: Member 5 (Admin)

## Goal

Allow a pre-provisioned Admin to manage the ordered category catalogue used by menu-item forms and the customer menu. This is the first Admin screen and is temporarily used as the application entry screen while authentication routing is developed.

## User Story

As an Admin, I want to view, create, edit, publish, unpublish, and reorder food categories so that the menu is organised without deleting historical data.

## Acceptance Scenarios

1. Given an authenticated Admin, when the screen opens, then categories appear in `sortOrder` order and update when Firestore changes.
2. Given no categories, when loading completes, then an empty state offers an Add Category action.
3. Given a valid name and optional HTTP(S) image URL, when the Admin saves, then Firestore creates or updates the category with server timestamps.
4. Given invalid input, when the Admin saves, then field-level feedback appears and no write is attempted.
5. Given a category, when the Admin changes its publication switch, then the category is published or unpublished without hard deletion.
6. Given adjacent categories, when the Admin moves one up or down, then their sort order is swapped atomically.
7. Given a loading or Firestore failure, then the screen shows a consistent progress or actionable retry state.
8. Given a non-Admin or unauthenticated user, then Firestore rules reject the privileged operation even if the screen is opened directly.

## Out of Scope

- Category image upload to Firebase Storage; this increment accepts an optional image URL.
- Hard deletion of categories.
- Final Admin navigation and role-based login routing.
