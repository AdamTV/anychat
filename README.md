# AnyChat Translator

AnyChat is a multilingual chat application built with Flutter. It lets people
converse across languages in real time: messages are translated as they are
sent, and speech is transcribed and translated through a Firebase-backed
Speech-to-Text pipeline.

## Features

- Real-time conversations backed by Cloud Firestore
- Automatic message translation between supported languages
- Speech-to-Text transcription, with short-lived access tokens minted by a
  Cloud Function (no service-account keys ship with the app)
- Authentication with email/password, Google, Facebook, and Apple sign-in
- Localizable UI and per-user theme/language settings
- Push and local notifications

## Tech stack

- Flutter (Dart SDK `>=3.0.0 <3.19.0`)
- Firebase: Auth, Cloud Firestore, Realtime Database, Storage, Cloud
  Functions, App Check, and Hosting
- Cloud Functions (Node.js) hosting the Speech-to-Text token endpoint

## Getting started

Prerequisites: Flutter SDK, Android SDK, Node.js >= 18, and the Firebase CLI.

```bash
# Install Dart dependencies
flutter pub get

# Run the app on an Android emulator or a connected device
flutter run -d <device-id>

# Install and test the Cloud Functions
cd functions && npm install
```

Firebase configuration (`lib/firebase_options.dart`,
`android/app/google-services.json`, and the iOS/macOS
`GoogleService-Info.plist` files) is generated with the FlutterFire CLI:

```bash
flutterfire configure
```

Deploy the security rules and functions with:

```bash
firebase deploy --only firestore:rules,database:rules,storage,functions
```

## SMS through alpha-text

This fork bridges phone-number conversations to the alpha-text backend's
shared Twilio number pool. It is **SMS-only**: it does not integrate voice
calls or MMS, so the chat screen hides the call action in SMS threads.
Normal AnyChat-to-AnyChat messages stay in Firestore and are
not relayed to alpha-text.

Signed-in users can select **New SMS** on the conversations screen and enter
a phone number in E.164 format (for example, `+14155551234`). The dialog
currently uses English literals (`New SMS`, `Cancel`, `Start`); localization
is a follow-up. Spaces, dots, dashes, and parentheses are stripped; the result
must be `+` followed by 7-15 digits (no leading zero), otherwise the dialog
does nothing. Numbers without a country code are not accepted. Leaving an SMS
thread deletes its conversation document. Message documents stay in Firestore,
so if the same user reopens the thread, or the contact texts again, the earlier
history reappears.

### Message flow and routing

- The client opens `conversations/sms-<uid>-<contact digits>` and its
  `users/<uid>/conversations/<conversationId>` info document. The conversation
  records `smsOwner`, the canonical E.164 `smsContact`, and a synthetic
  `sms:+<digits>` participant;
  incoming/outgoing languages initially use the user's language. They are
  written only when the info document is created, so language settings the
  user changes survive reopening the thread and later inbound messages.
- Outbound message documents with `channel: "sms"` trigger
  `relaySmsMessage`. It posts `{to, body}` to
  `<ALPHA_TEXT_URL>/api/messages`, authenticated with the server API key,
  and supplies `X-User-Uid: <senderId>` for uid-scoped message storage and
  route allocation. This is a **trusted server header**, not Firebase token
  verification by alpha-text. Pool/administrative APIs are not all uid-scoped.
- A proxy number may serve multiple users texting different contacts.
  Routes are unique on `(number, contact)` (the database key is
  `(number_sid, contact)`): two users texting the same contact need different
  pool numbers. Existing `(uid, contact)` routes are reused; provision more
  numbers if none is free. Stale-route reclamation uses `ROUTE_STALE_DAYS`
  (default `7`, minimum `1`); this is not a permanent dedicated-number promise.
  The cutoff is currently fixed at backend startup and advances only on restart.
  Allocation removes stale routes for that contact; late replies after
  reassignment can reach the new owner.
- Inbound Twilio SMS is attributed by `(To pool number, From contact)`.
  alpha-text forwards routed messages to `inboundSms`, which canonicalizes
  `from` to E.164 (it rejects non-E.164 senders such as short codes, a
  missing row id, or a uid containing `/` with HTTP 400), merges the same
  conversation, and writes `messages/sms-<backend row id>` with
  `channel: "sms-inbound"`. This marker prevents an outbound relay loop.
  Existing chat listeners and translation handling consume the message.
  Unrouted inbound messages remain in alpha-text's legacy identity and are
  not forwarded to AnyChat.

### Server configuration and deployment

Configure these values only in server environments, never in Flutter assets,
client code, `--dart-define`, or committed configuration:

| Server | Environment variable | Value |
| --- | --- | --- |
| Functions | `ALPHA_TEXT_URL` | HTTPS alpha-text backend base URL, without `/api/messages` |
| Functions | `ALPHA_TEXT_API_KEY` | Must match the backend's `APP_API_KEY` |
| Functions and backend | `ANYCHAT_BRIDGE_SECRET` | Same nonempty shared secret on both servers |
| Backend | `ANYCHAT_BRIDGE_URL` | Functions base URL, e.g. `https://us-central1-<project-id>.cloudfunctions.net` |
| Backend | `ROUTE_STALE_DAYS` | Route inactivity threshold in days; defaults to `7` |

The backend appends `/inboundSms` to `ANYCHAT_BRIDGE_URL`; do not include that
suffix in the variable. Functions read `process.env` directly. Supply values
through protected deployment environment configuration (such as an untracked
Functions env file); merely creating Secret Manager secrets is insufficient:
the current exports do not declare Secret Manager bindings. Leave the backend
bridge URL unset to disable forwarding. With a URL but no secret it still attempts
callbacks, which the inbound handler rejects.

Deploy in this order:

1. Configure and deploy alpha-text with working Twilio credentials, persistent
   storage, a provisioned SMS-capable number pool, and public HTTPS webhooks.
   Set `APP_API_KEY`, the bridge base URL/secret, and route policy. Keep Twilio
   signature validation enabled and `PUBLIC_BASE_URL` aligned with the public
   webhook URL. Forwarding cannot succeed until the next step is deployed.
2. Configure the Functions environment and deploy the bridge from this root:
   `firebase deploy --only functions:relaySmsMessage,functions:inboundSms`.
   The runtime service account needs Firestore access. Ensure the backend can
   reach the HTTPS endpoint; it uses Bearer shared-secret auth, not a Firebase
   user token or Google IAM identity token.
3. Run the rules tests (`cd rules-tests && npm ci && npm test`), then deploy
   the Firestore rules: `firebase deploy --only firestore:rules`. No GitHub
   workflow deploys rules or functions: `firebase-hosting-merge.yml` deploys
   Hosting only, and the `firestore-rules-tests` CI job only tests the rules
   on the emulator. Rules, functions, and Hosting are deployed separately, so
   check that the live rules match `firestore.rules` on `main` after each
   rules change (Firebase console > Firestore > Rules).
4. After verifying the server path and authorization prerequisites below,
   build and distribute the Flutter client for the same Firebase project.
   No Twilio credentials, backend API key, or bridge secret belong in it.

### Firestore authorization

`firestore.rules` scopes access by collection. The rules and the client
flows they allow are tested on the local emulator (see Testing):

- `users/{uid}`: any signed-in user can read profiles, because people search
  lists the collection. That exposes every profile's email, display name, and
  blocked-account list to every signed-in user, as before. Only the owner can
  create, update, or delete their profile, limited to the known profile fields.
- `users/{uid}/conversations/{id}`: only the owner can list, update, or delete
  these docs. A member of a normal conversation may *create* (never update)
  the doc for another member while starting or growing that conversation, and
  may read it during that step. Language values are limited to two string
  fields.
- `conversations/{id}` and its `messages`/`transcribedMessages`: members
  only. A new normal conversation has exactly the creator and one other user.
  Members may bump `timestamp`, add one member, or remove themselves. The last
  member deletes the conversation. Messages must use
  `senderId == request.auth.uid` and a server timestamp, and cannot be edited
  or deleted by clients. Any member can still clear a live-translator
  transcript.
- SMS threads: create only as `sms-<auth uid>-<digits>`, with
  `smsOwner == auth uid`, a canonical E.164 `smsContact`, and participants
  exactly `[owner, "sms:" + smsContact]`. These fields are then immutable, so
  nobody else can take a thread over, even after it is deleted and recreated.
  Client messages in SMS threads must carry `channel: "sms"` and
  `smsStatus: "pending"` and must have 1-1600 characters of text. Normal
  threads reject any `channel` or `sms*` field. `sms-inbound`, provider ids,
  and delivery status are written only by the Admin SDK.

The relay checks the same conditions again on the server (defense in depth).
It only sends when the message is `pending` with valid text, the
conversation id starts with `sms-`, `smsOwner === senderId`, `smsContact` is
canonical E.164, the id equals `sms-<senderId>-<digits>`, and the
participants are exactly the owner and the contact. Otherwise it stamps
`smsStatus: "failed"` and an `smsError` code without calling alpha-text.

Remaining prerequisites before exposing SMS to untrusted users:
deploy these rules (step 3 above; CI does not deploy them), enable and
configure Firebase Auth, and protect the inbound shared secret and endpoint.
Admin SDK writes bypass rules. Existing documents created under the old
permissive rules are not migrated or re-validated, and threads with a
non-canonical `smsContact` can no longer be reopened by clients (the relay
also rejects their messages). Review those
before relying on the new guarantees. `database.rules.json` and
`storage.rules` were not part of this review. The rules have not been
deployed or tested against a live project.

### Failure, retry, and delivery limits

- The relay stamps `smsStatus: "sent"` on an HTTP-success response and
  `"failed"` on an HTTP/network failure. A validation failure (see Firestore
  authorization) also stamps `"failed"`, plus an `smsError` code. `"sent"` means backend acceptance, **not handset delivery**.
- There is no application retry queue or outbound idempotency key. Caught
  network/HTTP failures are recorded rather than rethrown; changing an existing
  message does not retrigger `onCreate`. Trigger redelivery or resubmission can
  send duplicate SMS, especially if sending succeeded before status recording
  failed. Do not assume exactly-once delivery or automatic retry.
- Backend forwarding is best-effort: failures are logged, the inbound row is
  retained, and Twilio still receives a successful webhook response. There is
  no durable bridge retry/backfill worker. Recovery requires an operator-driven,
  uid-scoped pull from `/api/messages?sinceId=...` and replay.
- Replaying the **same backend row id** merges the same Firestore message
  document, but updates its server timestamp and conversation metadata;
  existing language settings are preserved. The conversation and info docs are
  written in one transaction, but the message write is separate, so the
  inbound write as a whole is not atomic. Provider webhook
  redelivery can create another backend row; provider SID deduplication is not
  implemented, so this is not end-to-end idempotency.

## Testing

```bash
# Unit and widget tests
flutter test

# Integration test on a device/emulator (welcome screen -> login flow)
flutter test integration_test/app_test.dart -d <device-id>

# Cloud Functions tests
cd functions && npm test

# Firestore rules tests (local emulator, demo project, no credentials;
# needs Java 21+ for the Firestore emulator)
cd rules-tests && npm install && npm test
```

`rules-tests/` is separate from `functions/`, so `node --test` in
`functions/` does not pick up the emulator tests. `npm test` runs
`firebase emulators:exec` with the `demo-anychat` project id on port 8181.
Each test file uses its own `demo-anychat-*` project. With an emulator
already running, use `FIRESTORE_EMULATOR_HOST=127.0.0.1:8181 npm run test:only`.

CI (`.github/workflows/test.yml`) runs strict analysis, format checks, the
Flutter, Functions, and Firestore rules suites, and coverage floors on every
push and pull request.

## CI/CD automation

- **Dependency updates** — Dependabot (`.github/dependabot.yml`) opens weekly
  update PRs for Dart (`pub`), Cloud Functions (`npm`), Android (`gradle`),
  and GitHub Actions.
- **PR review** — the `Droid Auto Review` workflow posts automated code and
  security review comments on every pull request (requires the
  `FACTORY_API_KEY` repository secret; generate one at
  https://app.factory.ai/settings/api-keys).
- **Build performance** — the `Tests` and deploy workflows time every step,
  cache pub/npm dependencies, and upload `build-metrics/timings.jsonl`
  artifacts with per-step durations.
- **Releases** — pushing a `v*` tag runs the `Release` workflow, which
  generates grouped release notes (`scritps/generate_release_notes.sh`),
  publishes a GitHub release, and prepends the section to `CHANGELOG.md`.
- **Rollback** — the `Rollback` workflow (Actions > Rollback > Run workflow)
  redeploys Hosting and functions from any previous git ref; see
  [docs/ROLLBACK.md](docs/ROLLBACK.md).
- **Flaky tests** — the weekly `Flaky Test Detection` workflow re-runs failed
  tests and reports flaky ones (`scritps/flaky_test_detector.js`); run it
  locally with `npm run check:flaky`.
- **Alerts** — the `Alerts` workflow posts to Slack when CI, deploys, releases,
  or rollbacks fail; see [docs/ALERTING.md](docs/ALERTING.md).

## Project structure

- `lib/` — application code (screens, services, database, widgets)
- `functions/` — Cloud Functions source (Node.js)
- `rules-tests/` — Firestore security rules tests (emulator)
- `test/` — unit and widget tests
- `integration_test/` — on-device integration tests
- `.github/workflows/` — CI and Firebase Hosting deploys

## Security

Never commit Firebase service-account keys; the repository gitignore blocks
the known key-file patterns. Speech-to-Text access tokens are minted at
runtime by the `getSpeechAccessToken` callable function. Firestore, Realtime
Database, and Storage rules live in `firestore.rules`, `database.rules.json`,
and `storage.rules`.

## License

MIT — see [LICENSE](LICENSE).
