# Repository Guidelines

## Project Structure

`lib/` contains the Flutter app, including screens, services, database code, and shared widgets. `assets/` holds app resources. Cloud Functions live in `functions/`; Flutter unit and widget tests are in `test/`, and on-device tests are in `integration_test/`. Platform projects are under `android/`, `ios/`, `web/`, `linux/`, `macos/`, and `windows/`. Firebase configuration and security rules are at the repository root.

## Build, Test, and Development

- `flutter pub get` installs Flutter dependencies.
- `flutter run -d <device-id>` launches the app on a connected device or emulator.
- `flutter analyze` checks Dart code; `npm run check:format` verifies formatting.
- `flutter test` runs unit and widget tests; use `flutter test --coverage` to collect coverage.
- `cd functions && npm install && npm test` installs and runs Cloud Functions tests. Run `npm run lint` and `npm run typecheck` there before submitting Functions changes.
- `npm run check:quality` runs repository structure, debt, dependency-drift, and duplication checks.

## Style and Tests

Use `dart format` for Dart. Name Dart files and tests in `snake_case.dart`; use `UpperCamelCase` for types and `lowerCamelCase` for members. Flutter tests must end in `_test.dart`. Functions use the repository's ESLint Google style; name tests `*.test.js` and keep them compatible with Node's built-in test runner. CI enforces analysis, formatting, and coverage thresholds.

## Commits and Pull Requests

Use short, imperative commit subjects, for example, `Format all Dart sources with dart format`. Pull requests should explain the change and user impact, list relevant tests and checks, link an issue when applicable, and include screenshots for visible UI changes.

## Security

Never commit service-account keys, private credentials, or generated secrets. Keep Firebase security rules and app behavior aligned with the existing Firebase-backed translator.
