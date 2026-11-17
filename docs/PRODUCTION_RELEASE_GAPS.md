# Production release gaps — November 17, 2026 checkpoint

This matrix distinguishes the authorized KJV-focused public beta from the
confirmed October 9 1.0 scope. Accountability in that scope is local-only:
morning commitments, evening outcome (met / partly met / not met), optional
notes and dated history, with eventual Today wrap-up integration. Partners,
accounts, network/sync, Mayday and sharing are not prerequisites for this slice.

The Android contract requires complete offline editions of KJV, WEB, BSB,
ASV 1901, Darby and Reina-Valera 1909. iOS/Windows additionally include Louis
Segond 1910. Confirming the roster does not establish content availability or
full bundling rights. No new text, provider, UI mode or distribution authorization
is introduced by this document; current beta behavior remains unchanged.

## Small KJV beta evidence and remaining acceptance

Checkpoint: `f674959276cbbe47d1cafaf8545f0384263d6c85`, tree
`6904aa0e1b2a4e1d39d3371cd2470806715ee712`. Host verification includes 468
passing Flutter tests, synthetic installed-KJV disk reopen, and Today, Plan,
Reader and Guard recovery tests. These are host/synthetic results, not handset
acceptance or a claim that the broader production MVP is complete.

- [Android build evidence and limits](BUILDING_ANDROID_BETA.md#verified-feature-checkpoint--november-17-2026):
  Debug ARM64 and unsigned release compilation, compiled manifest/containment,
  static ELF LOAD and ZIP 16 KiB checks passed. No artifact was uploaded by that
  run; no signed release, AAB, handset/runtime or live backend qualification.
- [Windows evidence and limits](WINDOWS_DEBUG_STORAGE.md#verified-build-checkpoint--november-17-2026):
  Debug/Release compilation and EXE identities passed; no launch or default
  provider-resolved SQLite/preferences runtime qualification.
- [Isolated owner-run smoke checklist](GALAXY_ISOLATED_SMOKE.md) remains the
  separate device acceptance gate. CI does not mark its rows passed. Installed
  KJV offline text and device audio are separate acceptance questions.

## Broader production MVP blockers

| Milestone | Current source evidence | Remaining gate / owner decision |
| --- | --- | --- |
| Production Android Guard | [Default evaluator](../lib/src/features/focus/domain/guard_readiness.dart) has empty qualification records and available implementation IDs; [service](../lib/src/features/focus/application/guard_readiness_service.dart) uses that default. [Native policy](../android/app/src/main/java/com/newman/newmanapp/GuardFeaturePolicy.java) requires live opt-in and qualification. | Apply the confirmed feature-level acceptance contract and qualify each supported app/version and failure/revocation behavior on authorized hardware. Existing policy and probes do not establish production enforcement. No Accessibility activation is authorized by this review. |
| Local-only accountability | [Shipped screen](../lib/src/features/accountability/presentation/accountability_screen.dart) remains a discarded in-memory private draft. The separate [domain](../lib/src/features/accountability/domain/local_check_in.dart) and [explicit store](../lib/src/features/accountability/data/explicit_local_check_in_store.dart) are unexposed, opt-in foundations with typed outcomes and synthetic reopen/rollback tests; see [boundaries](LOCAL_CHECK_IN_DRAFT.md). | Implement and qualify explicit local persistence consent, morning/evening/history UI and Today wrap-up integration after retention/deletion and private storage/backup behavior are resolved. Missing check-ins must remain unrecorded. No partner, backend or transmission is needed for the confirmed local-only scope; the existing discard promise must remain true until a separately reviewed UI change. |
| Complete offline edition roster | [Current catalog](../lib/src/features/word/translations/domain/bible_translation.dart) still defines KJV and online-only NLT; [schema](../lib/src/core/database/app_database.dart) remains limited to those identifiers/modes. No additional edition is installed or bundled by the unexposed work. | Android: KJV, WEB, BSB, ASV 1901, Darby, Reina-Valera 1909; iOS/Windows add Louis Segond 1910. Full bundling rights, source integrity and required attribution remain pending review. A future full-catalog packet must preserve stored `kjv`/`nlt`, retain KJV/recovery paths, and treat NLT as unavailable legacy references rather than deleting or coercing them; current NLT behavior is unchanged. Synthetic metadata/migration tests cannot qualify complete offline datasets or platform runtime behavior. |
| Qualified offline audio | [Audio boundary](../lib/src/features/word/audio/application/bible_audio_service.dart) preserves known/unknown TTS network requirements; [TTS service](../lib/src/services/tts_service.dart) uses platform engines/voice metadata, including Android numeric flags. The reader labels network use without claiming verified offline playback. Narration reliability tests establish control behavior, not offline voice installation or quality. | Confirm whether contract accepts device TTS versus recorded audio, languages/voices and offline guarantees. Qualify synthetic text in airplane mode on supported devices, missing/network-only voice behavior, interruptions, resume and privacy. No recorded-audio rights or downloads are established here. |

A successful debug APK build/manifest inspection remains distinct from a fresh
isolated installation and device smoke qualification. Native reminders are
separately dormant and unqualified; see [their validation gates](ANDROID_REMINDER_NATIVE_FOUNDATION.md).
These gaps cannot credibly be declared complete solely from portable tests or
CI compilation. No merge, release, deployment, provider activation or device
permission change follows from this document.
