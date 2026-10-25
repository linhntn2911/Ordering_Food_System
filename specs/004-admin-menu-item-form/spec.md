# Feature Specification: Add or Edit Menu Item

**Feature ID**: `004-admin-menu-item-form`  
**Status**: Approved for implementation  
**Owner**: Member 5 (Admin)

## User Story

As an Admin, I want to add a new menu item or edit an existing one so that the
Ngô Chicken catalogue, prices, images, sizes, visibility, and daily
availability remain accurate.

## Acceptance Scenarios

1. Admin opens one shared form in Add mode from Menu Item List or Edit mode from
   an existing item.
2. The form requires a name, category, and positive integer base price; it
   validates description length, image selection, and optional L-size surcharge.
3. Admin can select an image, preview it, and upload it to Firebase Storage when
   saving to the real Firebase repository.
4. Admin can mark the item available/sold out and published/hidden.
5. Optional M/L sizes store M at the base price and L as a non-negative
   additional price. Items without sizes remain valid.
6. Saving creates or updates one Firestore document using server timestamps and
   returns to the real-time Menu Item List.
7. Loading, validation, upload/save error, disabled-action, and success states
   are visible. Preview mode performs the same interaction in memory.
8. Existing records without `sizes` remain readable.

## Out of Scope

- Hard deletion of menu items.
- Cropping or editing selected images.
- Arbitrary option groups and toppings; this release models the supplied menu's
  M/L price difference only.

