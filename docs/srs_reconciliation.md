# SRS Revision Reconciliation

## Source

This project baseline was reconciled against `Project_PRM (3).docx`, last modified on 2026-10-17. `SPEC.md` and `specs/001-food-ordering-system/spec.md` remain the normative product specification used by Spec Kit.

## Adopted Changes

- Registration now explicitly requires full name, email, phone number, password, and matching password confirmation. The password minimum is six characters, every self-registered account receives the protected `Customer` role, successful registration establishes a session, and a welcome or verification email is initiated.
- Login now explicitly handles inactive accounts, role-based routing, persisted Firebase Authentication sessions, and the SRS rule of five consecutive failures followed by a 15-minute lockout.
- Cart rules now require authentication, a valid available item, valid quantity and required options, and price recalculation after quantity, size, or topping changes.
- Checkout recalculates restaurant-to-address distance whenever the selected address changes.
- Delivery fees are 15,000 VND through 3 km, 20,000 VND above 3 km through 5 km, and 30,000 VND above 5 km through 8 km. Unknown distances and distances above 8 km block checkout.
- Orders snapshot delivery distance and fee, use a structured unique order code, and require reasons for Customer cancellation and Admin rejection.
- Deleting a review restores submission eligibility only while the original 30-day review window remains open.
- New-order and cancellation notifications fan out to all active registered Admin devices.

## Preserved Project Decisions

- The release remains a single-restaurant, COD-only Flutter mobile application.
- Human roles remain Customer and pre-provisioned Admin; Guest remains an unauthenticated state.
- Firebase Authentication, Cloud Firestore, Firebase Cloud Messaging, optional Firebase Storage, MVVM, official Riverpod, and SharedPreferences remain mandatory.
- The screen inventory remains 23 screens because the SRS revision changes validation and checkout behavior rather than adding a separate screen.
- Light mode and the Food Ninja design system remain unchanged.

## Excluded Source Material

- The Payment Gateway actor is excluded because the approved scope and the detailed Place Order use case are COD-only and the revised SRS contains no active online-payment use case.
- Placeholder content such as `Patrol`, `Meal`, `UC Name2`, `Xyz Feature`, and instructional template paragraphs is not product behavior.
- Optional driver contact data is not adopted because the approved release has no Driver role or driver-assignment workflow.
- A customer-facing live map and live GPS tracking remain out of scope. Checkout still requires an authoritative distance calculation.

## Clarification Backlog

- Choose the distance and geocoding implementation and define how address coordinates are obtained and protected.
- Decide whether registration sends a welcome email, verification email, or both.
- Define the trusted implementation for the exact five-attempt, 15-minute login lockout.
- Set the cart quantity limit and maximum COD order value.
- Set the minimum text length for 1-2-star reviews; the source SRS contains a missing value.
- Decide the target Admin confirmation SLA; the source gives only an example of 5-10 minutes.
- Define an Admin merchant-reply use case before displaying official merchant replies in review details.
