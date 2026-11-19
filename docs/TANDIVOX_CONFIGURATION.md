# Tandivox migration — configuration guide (names and references only)

This document lists configuration names, file paths, safe local test modes and
required permissions. It intentionally contains **no secret values**. Secrets are
kept in `functions/.env` (gitignored) or Google Secret Manager; never commit or
paste them.

## SMS bridge environment variables (`functions/`)

The Cloud Functions backend reads these at startup via `smsBridgeConfig()` in
`functions/index.js`:

| Variable | Role | Required for live SMS |
|---|---|---|
| `ALPHA_TEXT_URL` | Base URL of the alpha-text Twilio backend | Yes (non-SMS app runs without it) |
| `ALPHA_TEXT_API_KEY` | Shared key used to authenticate outbound relay POSTs to alpha-text | Yes for live sends |
| `TANDIVOX_BRIDGE_SECRET` | **Canonical** shared secret for the inbound `/inboundSms` bearer gate | Yes for live inbound |
| `ANYCHAT_BRIDGE_SECRET` | **Legacy fallback** name for the same secret (kept so existing deployments keep working) | No, if the canonical name is set |

### Bridge-secret resolution and precedence

Implemented in `functions/bridge_secret.js` (`resolveBridgeSecret`):

1. If only one of the two names holds a non-empty value, that value is used.
   - Canonical-only → uses `TANDIVOX_BRIDGE_SECRET`.
   - Legacy-only → falls back to `ANYCHAT_BRIDGE_SECRET` (current deployments).
2. If both hold the **same** non-empty value, that value is used.
3. If both hold **different** non-empty values, startup throws an error naming
   the two variables and instructing you to unset one. It never logs the values.
   This is a fail-safe: a misconfigured dual secret must not silently pick a
   winner.

Blank/whitespace-only values are treated as unset.

### Migrating an existing deployment

`functions/.env` now carries `TANDIVOX_BRIDGE_SECRET` (migrated from the legacy
name on 2026-11-19 with the value preserved). Existing deployments that still
only set `ANYCHAT_BRIDGE_SECRET` keep working via fallback. Do **not** set both
names to different values on any deployment; if migrating a live deployment, set
the canonical name to the same value and remove the legacy one (or rotate it as
a deliberate change) so the inbound bearer gate always matches what alpha-text
was configured to send.

## Safe local test mode (no live effects)

Run the backend against emulators; no real numbers, messages or purchases occur.

```bash
cd functions && npm install
firebase emulators:start --only functions
# wait for "All emulators ready", then:
curl http://localhost:5001/anychat-c414a/us-central1/health   # expect {"status":"ok"}
```

The Flutter app can be pointed at the Firebase emulators (see `docs/SMS_EXPANSION_PLAN.md`
and recent commit "Let the app run against Firebase emulators"). Unit/widget tests
under `test/` and Functions tests under `functions/test/` use injected fakes or
loopback only — none of them call a live provider.

## Local quality gates (commands)

Run from the repo root unless noted:

```bash
flutter pub get
flutter analyze
dart format --set-exit-if-changed lib test tool
dart run tool/check_complexity.dart lib
npm run check:file-size
flutter test
cd functions && npm install && npm test && npm run lint && npm run typecheck
```

## Permissions and limits relevant to this work

- No number purchase, port-in, sender ownership change, webhook/callback
  re-registration, DNS/routing change, billing change or live message is part of
  local development. Those are owner/provider actions (see the release checklist).
- The inbound `/inboundSms` endpoint is public at the IAM layer because
  alpha-text cannot mint Google identity tokens; the bearer bridge secret is the
  only gate. Keep that secret server-side and out of logs, bundles and fixtures.
