# Architecture

New Man is an incremental Flutter retrofit that keeps a working Scripture planner usable while moving toward feature-oriented boundaries and local-first persistence.

## Runtime flow

```text
main.dart
  └─ local bootstrap
      ├─ Drift database and migration/recovery
      ├─ application repositories and services
      └─ NewManApp
          ├─ Today
          ├─ Word
          ├─ Focus (roadmap placeholder)
          ├─ Accountability (roadmap placeholder)
          └─ More / settings
```

Within active features, dependencies move inward:

```text
presentation → application → domain ← data/platform implementations
```

Widgets render state and invoke application services. Domain models hold deterministic rules. Repositories isolate Drift, preferences, network providers, file import, and device services.

## Key boundaries

- `lib/src/features/word/` owns Bible navigation, reading plans, translation state, saved Scripture, and audio contracts.
- `lib/src/features/tasks/` owns the task domain, application service, repository contract, and Drift implementation.
- `lib/src/core/database/` owns the application database, schema upgrades, legacy import, backup, and recovery.
- `lib/src/app/` owns bootstrap, navigation shell, and theme.
- Legacy folders under `lib/src/models`, `screens`, and `services` remain compatibility seams while the migration is completed incrementally.

## Persistence

Drift/SQLite is the authoritative local store for migrated Word state and task foundations. The repository includes committed schema snapshots from v1 through v7 and migration tests that exercise upgrades, rollback, retry, and preservation of existing data.

Legacy SharedPreferences keys and application identifiers are intentionally retained where changing them would orphan existing local data.

## External services

The default experience is usable without cloud configuration. Supabase initialization is optional and only occurs when public connection values are supplied with Dart defines. The included Edge Function keeps the licensed NLT provider key on the server; no provider credential is committed or expected in the Flutter client.

## Testing strategy

The suite covers deterministic Bible navigation, reference parsing, plan scheduling, repository behavior, schema migration, task persistence, widget flows, reader behavior, translation handling, and Windows text-to-speech smoke behavior.

