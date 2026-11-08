# Verification

1. Guest taps Home chat, signs in and returns to general chat without order selection.
2. Customer sends text/photo link, reopens and sees same history.
3. Admin drawer Tin nhắn → Chung → thread → reply. Customer Home unread dot clears on viewing latest reply.
4. Theo đơn → open thread → Chi tiết đơn. Its history stays separate from general support.
5. Verify foreign customer/disabled/Guest denial and retry/concurrent creation with emulator suite.


## Verification result — 2026-11-08

All 59 Firebase Emulator tests passed (including 9 new general-support cases), preserving the existing order and Storage access regressions. All 9 general-support widget tests passed: Home direct entry/unread badge, retry ID retention, guest login return, disabled/foreign denial, account-switch draft isolation, independent inbox filters, Admin reply/read isolation, 320px at text scale 1.3, and load-more beyond 100. The combined chat/Home layout run passed before the final two Admin cases were added; the new cases also pass. Full Flutter suite: 316 pass / 17 fail in existing Admin/menu/notification/navigation tests, consistent with prior recorded full-suite failures. Full-suite completion gate remains unresolved. No hosted deployment or physical-device walkthrough performed.

## Hosted deployment — 2026-11-08

After explicit user approval, deployed Firestore rules and indexes to ordering-food-system-65c7f using Firebase CLI. Compilation and deployment succeeded; CLI confirmed rules released to cloud.firestore and indexes deployed to the default database. This supersedes the earlier note that no hosted deployment had been performed. Client refresh/reopening and live two-account verification remain to be observed; index provisioning may finish asynchronously.


Dashboard shortcut verification (2026-11-09): all 30 focused chat tests pass; analyzer has no issues. Seven new tests cover live combined counts above the inbox page size, no read side effects, unauthorized-session subscription guards, direct Dashboard routing, zero/99+ display, loading/error navigation and 320px/text scale 1.3. No schema/rules/index deployment needed. Existing full-suite failures documented above remain outside this change.
