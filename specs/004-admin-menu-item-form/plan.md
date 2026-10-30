# Implementation Plan: Add or Edit Menu Item

Extend the Menu domain with an immutable draft and size option. Add one
repository save operation implemented by Firestore/Firebase Storage and by the
debug preview repository. An official Riverpod AsyncNotifier validates and
coordinates persistence. One responsive Food Ninja light form supports Add and
Edit, while `image_picker` gathers local image bytes in the View.

Firestore remains behind the repository boundary. Existing menu documents are
compatible because a missing `sizes` array maps to an empty list. Images use a
menu-item-specific Storage path and Firestore stores only the resulting URL.

