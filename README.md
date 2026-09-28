# New Man

New Man is a Christian discipline app that brings Scripture, reading plans, daily priorities, and attention-supporting tools into one Flutter experience.

The current portfolio build is strongest in **Word**: users can browse Scripture, create and follow reading plans, resume reading, save passages, switch translations, and listen with device text-to-speech. The app also includes the local persistence foundation for **Today** and tasks. Focus and Accountability are visible product directions, but are intentionally marked as future work rather than presented as finished features.

> **Project status:** active prototype / portfolio project. This is not a production release and does not claim production users or deployment.


## What works today

- Responsive Flutter shell for Windows and Android with Today, Word, Focus, Accountability, and More destinations
- Independent Bible browsing by book and chapter
- Reading plans with custom references, date ranges, selected weekdays, schedule preview, completion tracking, and Catch Me Up redistribution
- Continue Reading state and a Word dashboard that prioritizes active reading
- Saved Scripture with bookmarks, highlights, private notes, and reading history
- Translation management with provider-aware online/offline states
- Device text-to-speech controls and voice selection
- Local-first SQLite persistence with Drift and versioned migration coverage
- Task and daily-priority domain, repository, and migration foundations
- Optional Supabase Edge Function boundary for licensed NLT passage access; no provider key is included

## Engineering highlights

- **Safe incremental migration:** legacy SharedPreferences data is projected into versioned Drift schemas with retry, rollback, backup, and recovery behavior.
- **Deterministic core logic:** parsing, plan scheduling, navigation, and Catch Me Up behavior are testable without network or UI dependencies.
- **Layered feature design:** presentation code depends on application/domain contracts, while Drift and platform services remain behind data boundaries.
- **Provider seams:** Scripture text, translations, and narration are separated so licensed or platform-specific providers can be replaced without rewriting the reader.
- **Privacy by design:** Scripture notes, saved passages, tasks, and reading state remain local by default.
- **Compatibility discipline:** legacy application and storage identifiers are retained so existing local data is not orphaned during the retrofit.

## Architecture and stack

New Man uses Flutter and Dart with Material 3 UI, Drift/SQLite persistence, SharedPreferences compatibility during migration, device text-to-speech, and an optional Supabase boundary for server-mediated licensed content.

```text
Flutter UI
   ↓
Presentation screens and widgets
   ↓
Application services and repository contracts
   ↓
Domain models and deterministic rules
   ↓
Drift / SQLite, legacy preferences, device services, optional providers
```

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the feature boundaries and data flow, and [`docs/PRIVACY.md`](docs/PRIVACY.md) for the public privacy posture.

## Run locally

### Prerequisites

- Flutter 3.44.8 stable or another compatible Flutter release
- Dart `>=3.9.0 <4.0.0`
- For Windows: Visual Studio with Desktop development with C++
- For Android: Android Studio / Android SDK and an emulator or connected device

Check the machine first:

```powershell
flutter doctor
```

Install dependencies and run the default local experience:

```powershell
flutter pub get
flutter run -d windows
```

Or run on Android:

```powershell
flutter devices
flutter run -d <android-device-id>
```

The bundled KJV file is deliberately a small demo subset. The app can still be evaluated without cloud credentials; use `tools/convert_kjv_vpl.py` to prepare a complete compatible public-domain KJV asset for local testing.

### Optional NLT provider configuration

NLT access is not required for the default demo and no API key belongs in the client or repository. If you deploy the included Supabase function, configure `NLT_API_KEY` as a server-side secret, then pass only the public Supabase connection values at build/run time:

```powershell
flutter run -d windows `
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLIC_KEY
```

## Verify

```powershell
flutter pub get
flutter analyze
flutter test
flutter build windows --release
```

Verified on September 28, 2026 with Flutter 3.44.8 / Dart 3.12.2:

- dependency resolution: passed
- static analysis: passed with no issues
- automated tests: 80 passed
- Windows release build: passed

## Repository structure

```text
android/          Android runner and platform configuration
assets/           Bundled demo Scripture data
docs/             Public architecture and privacy notes
drift_schemas/    Versioned database schema snapshots
examples/         Sample passage import formats
lib/              Flutter application and feature code
supabase/         Optional licensed-content proxy and sync schema
test/             Domain, migration, repository, widget, and smoke tests
tools/            Public data-preparation utilities
windows/          Windows runner and native configuration
```

## Public roadmap

- Finish the Today task and daily-priority interaction flow
- Add focus-session foundations and measurable completion history
- Design consent-based accountability check-ins without surveillance
- Replace demo Scripture data with documented, license-compliant distribution flows
- Complete application identifiers, release signing, accessibility review, and device QA before any production release

## Known limitations

- Focus and Accountability are roadmap placeholders, not shipped feature claims.
- The bundled KJV is a demo subset rather than a complete Bible.
- NLT content requires a separately licensed provider account and server-side secret.
- Android release signing and legacy package/executable identifiers need production hardening.
- No production deployment, user count, or usage metric is claimed.

## License

The current [`LICENSE`](LICENSE) is a temporary portfolio-evaluation notice: the source is visible, but no reuse license is granted. If the project owner wants outside reuse or contributions, replace it with an OSI-approved license such as MIT after confirming ownership and third-party asset obligations.
