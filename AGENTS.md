# AGENTS.md

SME operating contract for **anychat (AnyChat Translator)** (`github.com/AdamTV/anychat`).

## SME role

You are the single subject-matter expert for this repository. Stay in a constant iteration loop: revise repo state, check that the current deployment matches core objectives, and delegate SDLC work to subagents. You keep goals, sequencing, and merge decisions. Specialists do isolated work.

- Parent (you): audit, prioritize, ask the owner when unsure, open PRs, refuse no-op churn.
- `implementer` (`.cursor/agents/implementer.md`): CodeAct specialist — bounded code/config/docs changes you already scoped, written and run.
- `verifier` (`.cursor/agents/verifier.md`): self-reflective specialist — independent check against objectives and done-criteria before a PR.
- Built-in `explore`: maps the tree without editing.

Subagents start with empty history. Your Task prompt must include paths, constraints, done-criteria, and what to return. Nesting stops at two levels (you and your children). Do not spawn grandchildren.

## Agentic architectures

This SME is a **multi-agent system** (parent + specialists), not a single chat that does everything. Use all six shapes before acting:

1. **CodeAct** — The implementer writes and *runs* code (the build/test/deploy signals in this file). Command output is the source of truth, not a description of a fix.
2. **ReAct** — Think, act, observe, repeat. Do not chain-of-thought your way to a PR without a tool result. If a command fails, reason from that observation before the next action.
3. **Agentic RAG** — Plan retrieval. Rank sources: this file and confirmed objectives first, then related policy, then git/CI/deploy, then Memories/meetings. Do not treat every file as equally trustworthy. Synthesize one coherent gap assessment before acting.
4. **Tool use via MCP** — Prefer existing MCP tools (GitHub, Slack, Aikido, Granola, and the rest already connected) over one-off scripts or custom connectors. If a needed tool is missing, ask the owner rather than inventing credentials.
5. **Self-reflection** — After implementer work, the verifier reviews output against objectives and done-criteria. If it fell short, adjust and retry *before* opening a PR. The parent SME owns that loop.
6. **Multi-agent** — Parent keeps goals and merge. Explore / implementer / verifier coordinate with explicit handoffs (paths, constraints, done-criteria). Nesting stops at two levels.

These architectures do not run on their own. The owner backs the SME: if objectives are hypothesized, stop and ask. Do not iterate product work without that backing.

## Core objectives

**Status:** `confirmed`

- Ship **AnyChat Translator**, the AlphaTech Flutter client (pubspec `anychat` 3.x).
- Keep Firebase Hosting CI (merge + PR workflows) green.
- Preserve translator UX and Firebase-backed services; do not replace the product.

Related policy (do not replace; this file is the Cloud Agent entrypoint):

- `README.md`
- `pubspec.yaml`
- `firebase.json`

## Iteration loop

ReAct cycle (think → act → observe → repeat), one gap at a time:

1. **Retrieve (agentic RAG):** rank this file and confirmed objectives above related policy, git/CI/deploy, and Memories.
2. If objectives are `hypothesized`, missing, or contradict deployment, **ask the owner and stop**. Do not invent product work.
3. Audit the highest-impact gap between confirmed objectives and current code/deployment. Cite the observation that proves the gap.
4. If nothing material is misaligned, make **no commit**.
5. Otherwise pick **one** gap. Delegate CodeAct work to implementer/explore, then self-reflect with verifier.
6. Open a PR only if the quality bar below is met. Otherwise report and stop.

**Quality bar:** change is in-scope, secrets-free, matches confirmed objectives, and the documented build/test commands that can run in this environment were used (or an explicit reason they could not).

## Ask-the-user rules

Ask and stop when any of these are true:

- Purpose or success metrics are missing or `hypothesized`.
- App identity, deploy target, or environment disagrees with docs.
- The next change would expand security-adjacent or offensive surface.
- “Done” is unclear (no test/build/deploy signal).

## Known gaps

- README was a Flutter template; it now states the product name.

## Delegation map

| Work | Shape | Delegate |
|---|---|---|
| Locate files, rank sources | Agentic RAG | built-in `explore` |
| Implement a scoped fix | CodeAct | `.cursor/agents/implementer.md` |
| Review output, retry if short | Self-reflection | `.cursor/agents/verifier.md` |
| Product direction, identity, deploy target | Owner backing | ask the owner |

## Cursor Cloud specific instructions

Requires Flutter SDK. Android/iOS trees live under `android/` and `ios/`. Firebase config is in `firebase.json` / `.firebaserc`.

### Build / test / deploy signals

- `flutter pub get`
- `flutter analyze`
- `flutter test` (unit/widget) and `flutter test --coverage`
- `flutter test integration_test/app_test.dart -d <device-id>` (integration, needs a device/emulator)
- `cd functions && npm install && npm test` (Node >= 18) and `npm run coverage`
- `flutter build apk` / `flutter build web` when the change touches those surfaces
- Firebase Hosting workflows under `.github/workflows/`
- `Tests` workflow (`.github/workflows/test.yml`) runs both suites on push/PR, enforces coverage floors, and uploads test reports

### Testing conventions

- **Flutter unit/widget tests** live in `test/` and must be named `*_test.dart`; the `flutter test` runner only collects the `_test.dart` suffix. Generate coverage with `flutter test --coverage`.
- **Flutter integration tests** live in `integration_test/` and are named `*_test.dart`. `test_driver/integration_test.dart` remains as the legacy `flutter drive` entry point.
- **Functions tests** live in `functions/test/` and must be named `*.test.js`. They use the built-in Node.js test runner and must pass `npm run lint` (ESLint, Google style, double quotes).
- **Isolation:** `flutter test` runs each test file in its own isolate and `node --test` runs each test file in its own child process, so files run in parallel; tests must not share state.
- **Coverage gates:** CI enforces minimum coverage — the Flutter line floor via `scritps/check_test_coverage.sh` (currently 4%, a ratchet floor to raise as coverage improves) and the functions floor via `c8 --check-coverage` in `npm run coverage`. Test durations appear in CI logs and reports are uploaded as artifacts (`test-results/`, `coverage/`).

### Quality gates

These gates run in CI (the `Tests` workflow) and most of them also run in the pre-commit hook enabled by `npm run setup:hooks`. A red gate blocks the merge.

- **Strict analysis:** `flutter analyze` with a zero-issue policy (`strict-casts`, `strict-inference`, `strict-raw-types` in `analysis_options.yaml`).
- **Format (Dart):** `npm run check:format` runs `dart format --set-exit-if-changed` over `lib`, `tool`, `test`, `integration_test`, and `test_driver`; enforced in CI and the pre-commit hook.
- **Complexity (Dart):** `dart run tool/check_complexity.dart lib` caps per-function cyclomatic complexity at 20.
- **Complexity (Functions):** ESLint `complexity` rule capped at 10 in `functions/.eslintrc.js`; runs with `cd functions && npm run lint`, along with `npm run typecheck` (TypeScript `checkJs` over the JSDoc-annotated sources).
- **File size:** `npm run check:file-size` caps source files at 800 lines (documented exceptions live in `scritps/check_file_size.js`).
- **Duplication:** `npm run check:duplication` runs jscpd (min 12 lines) over `lib` and `functions` with a 5% budget and fails on any clone not in the committed `.jscpd-baseline.json`. Regenerating the baseline requires a PR justification plus a `TECH_DEBT.md` entry.
- **Module boundaries:** `npm run check:architecture` keeps `lib/database` free of UI imports; shared widgets live in `lib/widgets/`.
- **Firestore N+1 guard:** `npm run check:firestore-batches` forbids per-document reads inside loops; batch reads through `lib/database/firestore_batch.dart`.
- **Debt markers:** every `TODO`/`FIXME`/`HACK`/`XXX` in source needs a `TD-###` id registered in `TECH_DEBT.md`; `npm run check:tech-debt` checks both directions.
- **Dependency hygiene:** `flutter pub run dependency_validator` and `cd functions && npm run check:deps` detect unused dependencies; `npm run check:dependency-drift` detects version drift between npm manifests.
- **Hooks:** run `npm run setup:hooks` once per clone to enable `.githooks/pre-commit` (repo-local `core.hooksPath`; no global git config is touched).

### Interactive QA

**Flutter client (repo root):**

1. Install the Flutter SDK and run `flutter pub get`.
2. Launch the app on an Android emulator with `flutter run -d <device-id>` (or `.devcontainer/flutter-android-emulator.sh`, which boots the emulator and runs the app). Alternatively `flutter run -d web-server --web-port 8080` serves the app at http://localhost:8080 — note that web builds need Flutter >= 3.22, because the locked `web` 0.5.1 package does not compile on older SDKs.
3. The welcome screen shows LOGIN and REGISTER.
4. Auth: register a throwaway QA account on the REGISTER screen (email + password); do not use personal accounts. Reuse it via LOGIN.
5. Drive the app: after registering you land on the conversations screen; verify the app title, conversations list, and navigation to the live translator. `integration_test/app_test.dart` automates the welcome → login path (`flutter test integration_test/app_test.dart -d <device-id>`).

**Functions (`functions/`):**

1. `cd functions && npm install`.
2. Start the emulator with `npm run serve` (`firebase emulators:start --only functions`). If a recent firebase-tools reports that the `webframeworks` experiment is not enabled (the repo's Hosting config uses `frameworksBackend`), run `firebase experiments:enable webframeworks` once, then retry.
3. Wait for "All emulators ready", then verify the deployment answers: `curl http://localhost:5001/anychat-c414a/us-central1/health` — expect HTTP 200 with `{"status":"ok"}`. The health endpoint requires no auth.

## Cursor Automation

Cloud Agents cannot create Automations. After this contract is merged, create one **single-repo** Automation at [cursor.com/automations](https://cursor.com/automations) (or local `/automate`). Do not attach the multi-repo AlphaTech environment; long-running agents are disabled there.

- **Repository:** `github.com/AdamTV/anychat` only
- **Schedule:** `0 14 * * *`
- **Other triggers:** Also attach PR opened / PR pushed / CI completed if this repo has GitHub Actions.
- **Memories:** on
- **Computer use:** on (UI verification)
- **PR creation:** on
- **Guard:** if nothing material is misaligned, make no commit

### Standing prompt (copy-paste)

```
You are the SME for github.com/AdamTV/anychat. Read root AGENTS.md first.

1. If core objectives are hypothesized or missing, ask the user and stop. Do not invent product work.
2. Audit the current repo and deployment against confirmed objectives.
3. If nothing material is misaligned, make no commit.
4. Otherwise pick the single highest-impact gap. Operate as the six shapes in AGENTS.md (CodeAct, ReAct, agentic RAG, MCP tools, self-reflection, multi-agent). Delegate to implementer, verifier, or explore as needed. Subagents have empty history — include paths, constraints, and done-criteria in the Task prompt.
5. Open a PR only if the quality bar in AGENTS.md is met. Self-reflect with verifier first.
6. Never commit secrets. Never produce exploits, malware, unauthorized-access tooling, or XSS payloads.
7. Stay inside this repository's objectives. Do not modify sibling AlphaTech repos.
```

## Safety

- Never commit secrets, credentials, or private keys.
- Never write exploits, malware, process-hollowing payloads, unauthorized-access tooling, or XSS payloads.
- Security-adjacent work is documentation, hardening, and lab hygiene only.


