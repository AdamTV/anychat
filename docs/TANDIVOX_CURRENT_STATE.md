# Tandivox migration — current state, gaps and verification

Status: locally complete for the scoped items below. No deployment, merge,
number purchase, live message, routing/callback change or production data
migration is performed by this work. Provider approval, lawful send basis,
production configuration and live verification remain separate release gates
(see `TANDIVOX_RELEASE_CHECKLIST.md`).

## What changed in this pass

Three safe-local items were implemented on top of the existing working tree.
They are additive; they do not rewrite the conversation model, the SMS relay,
or any provider integration.

### 1. Composer double-send guard (client)

`chat_screen.dart` previously cleared the composer and dropped its composing
flag **before** awaiting `AnyChatUser.addMessageToConversation`, with no
re-entry lock. A double submit (Enter plus a tap on send, or two quick taps)
could enqueue two provider sends; a failed send also silently discarded the
draft.

- New `lib/components/composer_guard.dart` — `ComposerSendGuard` owns the text
  controller and an `_inFlight` lock. While one send is in flight further
  submits are ignored. The controller clears only after the send resolves; on
  failure the draft is kept and an `onError` callback fires (surfaced as a new
  localized string). Send action and error surface are injectable, so the logic
  is testable without Firebase.
- `lib/screens/chat_screen.dart` now delegates to the guard instead of clearing
  up front.
- New token `unableToSendMessage` in `lib/l10n/intl_en.arb`.

This addresses the handoff's "double clicks, reconnects and retries must not
create duplicate outbound messages" at the client edge. It is **not** a
server-side request-key idempotency ledger (see gaps).

### 2. Tandivox rebrand (owned surfaces only)

Compatibility-first: each name match was classified before editing. Only owned,
user-facing branding changed; internal keys, IDs and historical records are
untouched.

Changed to the new name:
- Android `android:label`, iOS `CFBundleDisplayName` and Facebook display name.
- Six iOS `NS*UsageDescription` permission strings.
- Web `<title>`, apple-mobile-web-app-title meta, `web/manifest.json`.
- The hardcoded notification dialog title in
  `lib/services/notifications/notifications_util.dart`.
- Ten English arb **values** (keys unchanged), e.g. `title`, `inviteToAnyChat`,
  `isCallingYouOnAnyChat`, `byContinuingIAgree`.

Kept stable on purpose (compatibility keys — changing them would break auth,
storage, routing or history):
- `pubspec.yaml` package name `anychat`; all Dart class/file names
  (`AnyChatAuth`, `AnyChatUser`, `AnyChatMessage`, …); `package:anychat/…` imports.
- iOS `CFBundleName` (lowercase internal identifier), Firebase auth handler URL,
  all `CFBundleURLSchemes`, Facebook App ID, AdMob IDs.
- The whole web `firebaseConfig` block (project id, database URL, storage
  bucket) and the Google sign-in client id; Android deep-link schemes.
- All l10n token **keys** (only values changed). The non-English arb files are
  not edited; they fall back to English for the touched keys.
- Firestore collection/doc/id schemes, provider IDs, billing references.

`flutter gen-l10n` regenerated `lib/generated/l10n/*`; the English output now
carries "Tandivox" in every changed value while getter names (internal token
keys) remain unchanged.

### 3. Bridge-secret environment alias (functions)

`functions/bridge_secret.js` resolves the shared bridge secret:
`TANDIVOX_BRIDGE_SECRET` is canonical, `ANYCHAT_BRIDGE_SECRET` is the legacy
fallback. When only one holds a non-empty value that value is used, so existing
deployments keep working with no change. If **both** hold different non-empty
values the configuration throws (ambiguous) — it does not silently pick one —
and the error names the variables but never their values. `smsBridgeConfig()`
in `functions/index.js` now calls this resolver; both callers (`relaySmsMessage`,
`inboundSms`) are unchanged otherwise.

## Current-state gap note (real paths)

The core inbox journey already exists in the tree and is untouched by this pass:
connect a channel (auth + SMS conversation setup), open the conversations list,
select a conversation, compose/send, and read delivery state through the relay.

What remains **not** built (out of scope for this safe-local pass, tracked so it
is not mistaken for done):

- `functions/sms_bridge.js` — outbound sends are claimed transactionally, but
  there is no durable `(uid, requestKey)` send-ledger or provider-SID record, so
  a timeout after acceptance is an **unknown outcome**, not proven idempotent on
  the server. TD-006 covers this. The client guard (item 1) reduces but does not
  eliminate duplicate-outbound risk; true exactly-once needs the ledger.
- Inbound webhook rows and delivery-status callbacks are not yet persisted into
  the AnyChat message model with durable provider deduplication (`smsProviderId`
  is written, status reconciliation is not wired). Delivery state shown in the UI
  is relay status, which is backend **acceptance**, not delivery.
- No consent/suppression evidence model, no segment/encoding cost estimate, no
  attachment pipeline — these are absent features, and nothing here claims they
  work.

## Verification report (commands actually run this session)

Environment: Flutter 3.47.9 stable, Node v24.x, OpenJDK 21. Flutter invoked via
`/home/adamtv/flutter/bin`. Commands run from the repo root unless noted; the
Functions gates run from `functions/`.

| Gate | Command | Result |
|---|---|---|
| Dart analysis | `flutter analyze` | No issues found (exit 0) |
| Dart format | `dart format --set-exit-if-changed lib test tool` | 206 files, 0 changed (exit 0) |
| Dart complexity | `dart run tool/check_complexity.dart lib` | max 12, limit 20 (exit 0) |
| File size | `npm run check:file-size` | within 800-line cap (exit 0) |
| Flutter unit/widget | `flutter test` | 87 pass, 0 fail (baseline was 80; +7 composer-guard tests) |
| Functions unit | `cd functions && npm test` | 62 pass, 0 fail (baseline was 56; +6 bridge-secret tests) |
| Functions lint | `cd functions && npm run lint` | 0 problems (exit 0) |
| Functions typecheck | `cd functions && npm run typecheck` | 0 errors (exit 0) |
| l10n regeneration | `flutter gen-l10n` | exit 0; English output carries the new name |

No pre-existing failures were introduced. No browser screenshots were captured
this pass (no live device/emulator session was opened), so none are reported.
