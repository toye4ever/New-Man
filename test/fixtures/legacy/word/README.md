# Synthetic Word persistence fixtures

These files contain invented test data only. They mirror the JSON string stored
under `scripture_planner.plans.v1`; they do not contain exported user data.

- `plans_v1_current.json` represents the complete current Plan shape with mixed
  assignment completion and a per-reading translation override.
- `plans_v1_optional_legacy.json` represents the supported older shape using
  `translation` and omitting `sourceReferences`, `endDate`, `templateId`,
  `completed`, and `translationOverride`.
- `installed_versions_v2.json` is a test-only JSON transport for the legacy
  SharedPreferences StringList. It verifies installed/enabled translation-state
  mapping and is not an export of user data.
