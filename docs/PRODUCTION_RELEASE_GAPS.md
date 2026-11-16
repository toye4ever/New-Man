# Production release gaps — November 16 review

This matrix records repository evidence and owner decisions still needed. It is
not a reduced definition of the approved full MVP. The recovered November 2 audit
requires Android feature-level Guard, consent-based accountability, six English/
Spanish editions and qualified offline audio. The precise October 9 contract and
edition identifiers remain unrecovered (parent handoff); do not infer them from
current beta code.

| Milestone | Current source evidence | Remaining gate / owner decision |
| --- | --- | --- |
| Production Android Guard | [Default evaluator](../lib/src/features/focus/domain/guard_readiness.dart) has empty qualification records and available implementation IDs; [service](../lib/src/features/focus/application/guard_readiness_service.dart) uses that default. [Native policy](../android/app/src/main/java/com/newman/newmanapp/GuardFeaturePolicy.java) requires live opt-in and qualification. | Recover exact feature targets/acceptance contract; qualify each supported app/version and failure/revocation behavior on authorized hardware. Existing policy and probes do not establish production enforcement. No Accessibility activation is authorized by this review. |
| Consent-based accountability | [Screen](../lib/src/features/accountability/presentation/accountability_screen.dart) is a milestone placeholder, explicitly reserving trusted partners and check-ins. | Confirm partner invitation, field-level sharing, consent/revocation, retention and recovery contract before backend selection or transmission. No real sharing or live backend qualification exists in this slice; no private data should be sent. |
| Six English/Spanish editions | [Catalog](../lib/src/features/word/translations/domain/bible_translation.dart) defines KJV and NLT, both English. KJV is offline-downloadable; NLT is online-only. [Schema](../lib/src/core/database/app_database.dart) constrains translation/access states to those modes. | Recover all six exact identifiers and approved access modes; owner supplies rights/provider authorization and required attribution. Catalog entries do not prove licensed distribution. Additional editions need source integrity, migration and offline/online acceptance tests. Do not acquire rights or configure a provider as an inferred implementation task. |
| Qualified offline audio | [Audio boundary](../lib/src/features/word/audio/application/bible_audio_service.dart) models TTS voices and network requirement; [TTS service](../lib/src/services/tts_service.dart) uses platform engines/voice metadata. Narration reliability tests establish control behavior, not offline voice installation or quality. | Confirm whether contract accepts device TTS versus recorded audio, languages/voices and offline guarantees. Qualify synthetic text in airplane mode on supported devices, missing/network-only voice behavior, interruptions, resume and privacy. No recorded-audio rights or downloads are established here. |

A successful debug APK build/manifest inspection remains distinct from a fresh
isolated installation and device smoke qualification. Native reminders are
separately dormant and unqualified; see [their validation gates](ANDROID_REMINDER_NATIVE_FOUNDATION.md).
These gaps cannot credibly be declared complete solely from portable tests or
CI compilation. No merge, release, deployment, provider activation or device
permission change follows from this document.
