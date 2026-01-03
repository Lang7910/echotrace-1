# Repository Guidelines

## Project Structure & Module Organization
- `lib/` contains the Flutter app source. Key areas include `main.dart`, `pages/` (UI screens), `services/` (database, analytics, export), `models/`, `providers/`, and `utils/`.
- `assets/` holds fonts, DLLs, and bundled tools referenced by `pubspec.yaml`.
- `test/` contains unit/widget tests (example: `path_utils_test.dart`).
- `docs/` hosts developer documentation (`development.md`, `wcdb_realtime.md`).
- Platform targets live in `android/`, `ios/`, `macos/`, `windows/`, `linux/`, and `web/`.
- `go_decrypt/` and `third_party/` contain local native/FFI tooling and vendored dependencies.

## Build, Test, and Development Commands
- `flutter pub get` installs Dart/Flutter dependencies.
- `flutter run` launches the app in debug mode for your current platform target.
- `flutter build windows` (or `macos`/`linux`) produces a desktop release build.
- `flutter test` runs the test suite under `test/`.
- `flutter analyze` checks code against `analysis_options.yaml` and `flutter_lints`.

## Coding Style & Naming Conventions
- Follow `flutter_lints` and keep code formatted with `dart format .` when changing Dart files.
- Use standard Dart naming: `UpperCamelCase` for classes, `lowerCamelCase` for fields/methods, `lower_snake_case` for file names.
- Common file patterns: `*_service.dart`, `*_page.dart`, `*_provider.dart`, `*_test.dart`.

## Testing Guidelines
- Testing uses `flutter_test`; tests live in `test/` and end with `*_test.dart`.
- Add tests for new utilities or parsing logic when feasible; no explicit coverage threshold is enforced.

## Commit & Pull Request Guidelines
- Recent commits commonly use Conventional Commit-style prefixes like `feat:` and short descriptions (often in Chinese); occasionally simple summaries like “更新版本号.”
- Prefer `type: short summary` for new commits to match history, keeping messages concise and descriptive.
- PRs should include a brief summary, linked issues if applicable, and screenshots for UI changes (especially analytics/report pages). Note the platform(s) tested.

## Security & Data Handling
- This project processes sensitive chat history. Do not commit real databases, decrypted exports, or user keys.
- Use anonymized data when sharing examples and keep local artifacts out of version control.
