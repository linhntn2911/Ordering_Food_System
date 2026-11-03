# Feature Specification: GPS-assisted Delivery Address

**Feature ID**: `009-gps-address`  
**Status**: Approved for implementation  
**Related requirements**: FR-014, FR-017, FR-046, FR-047, FR-048

## User Story

As a Customer, I want to use my current device location or select a point on a
map so that I do not have to enter latitude and longitude manually and the app
can validate whether Ngô Chicken can deliver to me.

## Acceptance Scenarios

1. Given location services and permission are available, when the Customer taps
   **Use current location**, then the map moves to the detected position, the
   delivery pin is selected, and the address fields are resolved when the
   configured geocoding service is available.
2. Given the map is visible, when the Customer taps another point, then the pin,
   normalized address, delivery distance, and delivery fee are recalculated.
3. Given permission is denied or location services are disabled, when GPS is
   requested, then the screen displays a recoverable explanation and still lets
   the Customer select a point on the map.
4. Given no point has been selected but a complete textual address exists, when
   the Customer submits the form, then the system forward-geocodes the address,
   places the pin, recalculates distance and fee, and continues only when the
   result is serviceable.
5. Given a selected point is farther than 8 km or distance cannot be determined,
   when saving is attempted, then saving is blocked.
6. Latitude and longitude are never exposed as editable Customer form fields.
7. Given forward geocoding returns no usable result, when saving is attempted,
   then saving is blocked with a correction message; the app never invents
   coordinates.
8. Given an authenticated Customer saves an address, when the app is reloaded
   or reopened, then the address is restored from
   `users/{uid}/addresses/{addressId}` in Firestore.
9. A Customer can read and mutate only the address documents below their own
   Firebase Authentication UID.

## Out of Scope

- Background or live location tracking.
- Driver tracking.
- Automatically accepting a reverse-geocoded address without Customer review.
