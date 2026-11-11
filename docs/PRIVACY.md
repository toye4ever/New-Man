# Privacy posture

This describes the beta source, not a comprehensive production-service privacy policy.

## Local data

Reading state, plans, saved Scripture, notes, highlights, tasks, and preferences are stored locally using Drift/SQLite and limited compatibility preferences. The default app starts without a cloud account. The retained Android beta disables backup and includes cloud/device-transfer exclusions; static configuration does not prove behavior on every manufacturer device.

The bundled KJV asset contains 20 verses. When the user requests the full KJV, the app downloads it from eBible and stores the recognized text locally. That request contacts the provider and is subject to its service behavior and terms.

## Optional and deferred features

The source contains optional Supabase initialization using build-time public connection values and historical server-side NLT scaffolding. No credentials are included. These files are not evidence of an enabled or qualified cloud service or additional-translation beta feature.

Focus/Guard and accountability are deferred. An unfinished Android accessibility test service remains declared. Do not enable it. The developer Guard controller is unavailable through the public release UI; this is not a qualified accessibility feature.

Test fixtures are synthetic. Do not use personal notes or other sensitive records in public bug reports.

## Product principles

Keep private reflections private by default. Any future accountability sharing should be explicit, granular, and revocable. Account, sync, location-sharing, export, deletion, and retention behavior need their own implementation and review before production claims.
