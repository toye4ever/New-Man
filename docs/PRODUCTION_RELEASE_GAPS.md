# Production release gaps — November 17, 2026 checkpoint

This matrix records repository evidence and owner decisions still needed. It is
not a reduced definition of the approved full MVP. The recovered November 2 audit
requires Android feature-level Guard, consent-based accountability, six English/
Spanish editions and qualified offline audio. The precise October 9 contract and
edition identifiers remain unrecovered; do not infer them from
current beta code.

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
| Production Android Guard | [Default evaluator](../lib/src/features/focus/domain/guard_readiness.dart) has empty qualification records and available implementation IDs; [service](../lib/src/features/focus/application/guard_readiness_service.dart) uses that default. [Native policy](../android/app/src/main/java/com/newman/newmanapp/GuardFeaturePolicy.java) requires live opt-in and qualification. | Recover exact feature targets/acceptance contract; qualify each supported app/version and failure/revocation behavior on authorized hardware. Existing policy and probes do not establish production enforcement. No Accessibility activation is authorized by this review. |
| Consent-based accountability | [Screen](../lib/src/features/accountability/presentation/accountability_screen.dart) now provides only an optional in-memory, manually entered private draft and review. It has no partner, send, history or persistence integration; see [draft acceptance](LOCAL_CHECK_IN_DRAFT.md). | Confirm partner invitation, field-level sharing, consent/revocation, retention and recovery contract before backend selection or transmission. No real sharing or live backend qualification exists in this slice; no private data should be sent. |
| Six English/Spanish editions | [Catalog](../lib/src/features/word/translations/domain/bible_translation.dart) defines KJV and NLT, both English. KJV is offline-downloadable; NLT is online-only. [Schema](../lib/src/core/database/app_database.dart) constrains translation/access states to those modes. | Recover all six exact identifiers and approved access modes; owner supplies rights/provider authorization and required attribution. Catalog entries do not prove licensed distribution. Additional editions need source integrity, migration and offline/online acceptance tests. Do not acquire rights or configure a provider as an inferred implementation task. |
| Qualified offline audio | [Audio boundary](../lib/src/features/word/audio/application/bible_audio_service.dart) preserves known/unknown TTS network requirements; [TTS service](../lib/src/services/tts_service.dart) uses platform engines/voice metadata, including Android numeric flags. The reader labels network use without claiming verified offline playback. Narration reliability tests establish control behavior, not offline voice installation or quality. | Confirm whether contract accepts device TTS versus recorded audio, languages/voices and offline guarantees. Qualify synthetic text in airplane mode on supported devices, missing/network-only voice behavior, interruptions, resume and privacy. No recorded-audio rights or downloads are established here. |

A successful debug APK build/manifest inspection remains distinct from a fresh
isolated installation and device smoke qualification. Native reminders are
separately dormant and unqualified; see [their validation gates](ANDROID_REMINDER_NATIVE_FOUNDATION.md).
These gaps cannot credibly be declared complete solely from portable tests or
CI compilation. No merge, release, deployment, provider activation or device
permission change follows from this document.
