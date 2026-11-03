# Tasks: GPS-assisted Delivery Address

- [x] T001 Add GPS/map dependencies and foreground platform permissions.
- [x] T002 Add immutable location result models and repository abstraction.
- [x] T003 Implement Geolocator and Geoapify data access.
- [x] T004 Add Riverpod location-selection ViewModel and explicit states.
- [x] T005 Replace coordinate inputs/presets with GPS and map pin selection.
- [x] T006 Persist provider metadata and route-distance preview in AddressModel.
- [x] T007 Add repository/ViewModel tests for success and failure states.
- [x] T009 Forward-geocode a complete typed address automatically on submit.
- [x] T010 Add tests for successful and failed automatic address resolution.
- [x] T011 Persist Customer addresses in UID-scoped Firestore subcollections.
- [x] T012 Resolve address ownership from Firebase Authentication.
- [x] T013 Protect address documents with owner-only Firestore rules and
  validated server timestamps.
- [ ] T008 Run formatting, analyzer, and relevant tests. Formatting and the
  full-project analyzer pass; Flutter test execution is currently blocked by
  the local Flutter SDK attempting a network version fetch and writing SDK
  cache stamps in the restricted environment.
