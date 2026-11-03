# Implementation Plan: GPS-assisted Delivery Address

## Technical Decision

- Use `geolocator` for foreground device positioning.
- Use `flutter_map` and OpenStreetMap raster tiles for an interactive pin picker.
- Use Geoapify reverse geocoding and driving-route distance through an API key
  supplied with `--dart-define=GEOAPIFY_API_KEY=...`.
- Use Geoapify forward geocoding on submit when the Customer typed or changed a
  complete address without selecting a matching GPS/map point.
- Fall back to the existing Haversine preview when Geoapify route resolution is
  unavailable; saving still requires coordinates.
- Keep all location, HTTP, and permission work behind a repository injected by
  Riverpod. The View only renders state and forwards intent.
- Persist the resolved provider/place ID and route distance in `AddressModel` so
  Checkout displays the same preview. Authoritative server-side revalidation is
  still required before a production release.
- A failed or ambiguous first-result lookup blocks saving and leaves the typed
  fields available for correction; coordinates are never guessed.
- Use Firestore `users/{uid}/addresses/{addressId}` as the address source of
  truth. Firebase Authentication supplies `uid`; no demo customer ID is used.
- Use Firestore server timestamps and a single write batch when changing the
  default address so the repository maintains exactly one default document.
- Keep the in-memory repository only as a unit-test fake.

## Privacy and Scope

- Request only while-in-use location permission.
- Never request background location.
- Do not commit API keys.
- Show OpenStreetMap attribution and identify the application to the tile server.
