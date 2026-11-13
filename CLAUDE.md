# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

- Install dependencies: `flutter pub get`
- Run locally against dev Supabase: `flutter run --flavor dev --dart-define-from-file=env/dev.env`
- Run web: `flutter run -d chrome`
- Static analysis: `flutter analyze`
- Full test suite: `flutter test`
- Single test file: `flutter test test/path/to/test_file.dart`
- One test by name: `flutter test test/path/to/test_file.dart --plain-name "test name"`
- Regenerate Freezed/JSON code after changing annotated models: `dart run build_runner build --delete-conflicting-outputs`
- Production Android APK: `flutter build apk --flavor prod --release --dart-define-from-file=env/prod.env`
- Production Android AAB (Play Store): `flutter build appbundle --flavor prod --release --dart-define-from-file=env/prod.env`

Production release requires `env/prod.env` with explicit production Supabase credentials and `SUPABASE_CREDENTIALS_EXPLICIT=true`, plus `android/key.properties` and its upload keystore. These files are intentionally not versioned. The Gradle configuration fails closed if a `prodRelease` build lacks signing configuration. Do not use dev credentials or debug signing for production. See `docs/pt/13-build-e-publicacao.md` for release and obfuscation details.

## Architecture

TAREQO is a Flutter/Material 3 multi-tenant ERP with Riverpod state management, local SQLite persistence, Supabase SaaS persistence/authentication, and pt/en/fr localization. The root widget is `TareqoApp` in `lib/app.dart`; it selects the theme, locale/currency settings, auth gate, navigation routes, and app-lock overlay. `lib/main.dart` and flavor configuration bootstrap the application.

The code follows Clean Architecture and dependency direction is inward:

- `lib/domain/`: business entities, repository/service contracts, use cases, and domain errors. Keep business rules here; this layer must not depend on data or presentation implementations.
- `lib/data/`: repository implementations, local and remote data sources, and synchronization/processors. Local persistence has SQLite and in-memory implementations behind shared contracts; web uses memory where native SQLite is unavailable. Supabase implementations enforce tenant-aware remote access; database RLS is authoritative.
- `lib/presentation/`: screens, reusable widgets, navigation, and Riverpod controllers/providers. Providers bridge UI to use cases through the composition root; screens should not implement business transactions.
- `lib/core/`: cross-cutting configuration, database/platform abstractions, DI, networking, security, localization helpers, theme/tokens, and shared utilities.

`lib/core/di/service_locator.dart` is the composition root: it registers implementations, repositories and use cases (including platform/backend variants). `lib/presentation/controllers/` exposes application state through Riverpod. When changing persisted data or a business flow, trace the contract through domain → data source/repository → use case → registration → provider → UI; related multi-write operations should preserve transaction/unit-of-work semantics. SQLite schema and idempotent migrations are managed by `lib/core/database/app_database.dart`; keep the IO and stub database APIs in sync.

`lib/core/config/app_flavor.dart`, `lib/core/config/supabase_config.dart` and `android/app/build.gradle.kts` define environment/flavor and release behavior. Android flavors are `dev` (application ID suffix `.dev`) and `prod` (store application ID). Release builds require explicit defines; do not rely on embedded defaults.

The global visual system lives in `lib/core/theme/app_colors.dart`, `app_theme.dart`, and `app_tokens.dart`. `AppTheme.light`/`dark` are installed by `TareqoApp`; use semantic theme roles and shared tokens rather than adding per-screen palette literals. Generated localization sources are under `lib/l10n/generated/`; edit source ARB files and regenerate rather than hand-editing generated Dart.

## Development references

- `README.md`: product scope, stack, quick start and top-level commands.
- `docs/pt/02-arquitetura.md`: architecture and dependency rules.
- `docs/pt/04-dados.md`: persistence and database conventions.
- `docs/pt/09-testes.md`: testing approach.
- `docs/pt/10-guia-desenvolvedor.md`: development workflow and implementation conventions.
- `docs/pt/13-build-e-publicacao.md`: platform builds and release signing.
- `docs/pt/23-design-system-e-convencoes-ui-ux.md`: UI/design-system conventions.

For new persisted modules, the developer guide describes the project flow: define domain model/contract/use case, implement data variants and repository, register dependencies, add providers/UI and tests, then regenerate annotated code if needed.
