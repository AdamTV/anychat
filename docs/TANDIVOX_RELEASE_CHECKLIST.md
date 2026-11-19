# Tandivox migration — release checklist (production approvals)

Status: local implementation and tests are complete for the scoped items in
`TANDIVOX_CURRENT_STATE.md`. Nothing below has been done. Every item is an
owner or provider action that requires **explicit approval before it happens**;
none of them is performed by this code or by CI automatically as part of the
rebrand.

## What is already locally true (no approval needed)

- Owned user-facing branding reads "Tandivox" on Android, iOS and web, in the
  English app strings and the notification dialog title.
- Composer double-submit guard prevents duplicate client-enqueued sends and keeps
  the draft recoverable on failure (covered by `test/composer_guard_test.dart`).
- Bridge-secret alias resolves with a safe legacy fallback and throws on
  conflicting dual values without logging secrets (covered by
  `functions/test/bridge_secret.test.js`).
- All quality gates green: analyze, format, complexity, file-size, `flutter test`
  (87), Functions `npm test` (62) + lint + typecheck.

## Production approvals required from the owner

1. **Approve deployment.** The rebrand touches app labels and metadata that ship
   on every Hosting deploy (`firebase.json` builds and deploys Functions in the
   same commit). Decide when to merge/deploy; do not treat this work as an
   automatic release.
2. **Brand/legal confirmation.** Confirm "Tandivox" use is authorized for these
   surfaces and that preserving historical event provenance (old events remain
   attributed to the prior name) is acceptable. This document does not claim
   trademark clearance or legal rebranding completion.
3. **Consent continuity.** Per CRTC guidance, a business rename for the same
   legal person does not invalidate existing consent if purpose/scope are
   respected. Confirm that holds here and that no new sending scope is implied by
   the rename.
4. **Bridge-secret migration — done locally** (2026-11-19, owner-approved):
   `functions/.env` now carries `TANDIVOX_BRIDGE_SECRET`; the legacy name was
   removed and the value preserved. When deploying, make sure the Functions
   runtime receives `TANDIVOX_BRIDGE_SECRET` (e.g. via Secret Manager) with that
   same value, since alpha-text sends this secret as the inbound bearer token.

## Provider / operator actions still needed (out of scope here)

These are gaps called out in the current-state note. They must be built and
verified before live production use, not assumed:

- **Server-side send idempotency ledger.** A durable `(uid, requestKey)` intent
  plus provider-SID record so a timeout after acceptance is an *unknown*
  outcome reconciled via IDs — not a blind resend. The client guard reduces but
  does not eliminate duplicate-outbound risk. (TD-006.)
- **Inbound deduplication and status reconciliation.** Persist provider message
  IDs with transactional dedup and wire delivery-status callbacks into the
  message model. Until then, UI delivery state reflects backend *acceptance*,
  not delivery.
- **Consent/suppression evidence model** and segment/encoding cost estimates if
  they are required for the intended send basis. Confirm whether the existing
  shared-proxy-number routing satisfies the target use or needs changes — any
  change to numbers/routing is itself an approved action, not automatic.

## Explicit non-goals (not authorized by this work)

- No number purchase or port-in, sender ownership change, or webhook/callback
  re-registration.
- No DNS/routing change, billing change, subscription creation, or live
  call/message send.
- No production data migration applied here; the handoff's data-migration runbook
  (backup → inventory in-flight ops → fence workers → canary → monitor → roll
  back) is a separately approved step. See `docs/ROLLBACK.md` for the existing
  rollback path.

## Suggested sequencing to production

1. Owner approves deployment and confirms items 2–4 above.
2. Merge to the release branch; CI deploys Hosting + Functions (channel `live`).
3. Verify: Hosting returns 200, `/health` returns `{"status":"ok"}` (commands in
   `docs/ROLLBACK.md`).
4. Exercise the inbox happy path against a **fake/sandbox** channel first:
   connect → receive one inbound event → open conversation → draft → submit twice
   with the same request → confirm one logical provider operation → process a
   delivered callback → verify state/history. Then test an unknown-outcome and an
   opt-out case.
5. Only after sandbox verification, conduct an explicitly approved canary against
   an approved real destination/number before broader activation.
