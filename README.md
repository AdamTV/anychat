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

## Testing

```bash
# Unit and widget tests
flutter test

# Integration test on a device/emulator (welcome screen -> login flow)
flutter test integration_test/app_test.dart -d <device-id>

# Cloud Functions tests
cd functions && npm test
```

CI (`.github/workflows/test.yml`) runs strict analysis, format checks, both
test suites, and coverage floors on every push and pull request.

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
