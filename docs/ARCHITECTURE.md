# Architecture

New Man incrementally extends a Flutter Scripture planner using feature-oriented boundaries and local-first persistence.

The runtime starts in main.dart, optionally initializes Supabase only when public build-time values are supplied, bootstraps local repositories, and opens NewManApp. The top-level areas are Today, Word, Focus, Accountability, and More. Focus and Accountability remain deferred.

Presentation code composes application services and domain models. Repositories isolate Drift, preferences, provider networking, file import, and platform services. Legacy models/screens/services remain compatibility boundaries.

## Main areas

- lib/src/features/word/: Bible navigation, reading plans, translations, saved Scripture, and audio.
- lib/src/features/tasks/ and lib/src/features/today/: task editing, time blocks, priority, and Today views.
- lib/src/features/settings/: appearance preferences.
- lib/src/core/database/: local database, migration, recovery, and generated schema code.
- lib/src/app/: bootstrap, theme, navigation, and developer-tool policy.

## Persistence and compatibility

Drift/SQLite is the authoritative local store for migrated Word and task state. Schema snapshots v1 through v10 and corresponding migration tests are included. Historical preferences, recovery behavior, and compatibility layers are retained.

The Android beta application ID is com.newman.newmanapp.beta. It is separate from production and does not automatically inherit production data. This source snapshot preserves the retained beta build configuration. Existing Windows runner files are preserved without a new platform-qualification claim.

## External services and deferred work

KJV is downloaded directly from eBible on request. Optional Supabase and server-side NLT scaffolding are retained as source, not qualified beta services. The Android Guard service and developer code are retained but are not a public release feature.

Tests cover deterministic navigation, parsing, scheduling, persistence/migrations, tasks, selected widget flows, reader state, and translation handling. See the build and beta-testing documents for verification limits.
