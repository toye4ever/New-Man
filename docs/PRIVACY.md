# Privacy posture

New Man is designed as a local-first product. The current portfolio build keeps Scripture reading state, plans, saved passages, notes, highlights, tasks, and preferences on the device by default.

## Current behavior

- Local state is stored with Drift/SQLite and limited compatibility preferences.
- The default app starts without a cloud account or cloud credentials.
- Optional Supabase initialization requires explicit build-time public connection values.
- Licensed NLT access uses a server-side function so the provider key does not ship in the client.
- Test fixtures are synthetic and contain no user data.

## Public product principles

- Collect the minimum data needed for a feature.
- Keep Bible notes and private reflections private by default.
- Make any future accountability sharing explicit, granular, and revocable.
- Do not treat accountability as surveillance.
- Avoid storing ordinary location history; prefer on-device evaluation for future location automations.
- Add clear export and deletion controls before production launch.

## Not yet production-ready

The repository is a portfolio prototype, not a published privacy policy or a production service. Account, sync, accountability, and location-sharing flows require threat modeling, consent UX, retention rules, and legal review before release.

