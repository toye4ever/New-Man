# New Man

New Man is a local-first Christian discipline and Scripture app built with Flutter. This source snapshot accompanies the Android beta with Today tasks, reading plans, KJV reading, saved Scripture, and appearance preferences.

## Android beta

The existing [binary prerelease](https://github.com/toye4ever/New-Man/releases/tag/v0.2.3-beta.1-binary) contains the signed ARM64 APK:

- Version: 0.2.3-beta.1, build 5
- Android package: com.newman.newmanapp.beta
- Android 7.0 / API 24 or later
- SHA-256: 8d36f6681c1616423d085199acae1a2ad56f996d705ee3353a822b4400fc62f8

This source was prepared for publication after that APK was built. The application files and retained Android build inputs are mapped in [source provenance](docs/releases/v0.2.3-beta.1-source.json). The existing binary tag remains unchanged, so its automatic GitHub source archives still refer to the earlier repository state. Use this source revision for the accompanying source snapshot. No bit-for-bit reproduction or clean-machine build is claimed.

Focus/Guard, reminders, cloud/accountability, and additional translations are deferred. The APK retains an unfinished accessibility test service. Do not enable it in Android Accessibility settings. Read the [beta testing notes](docs/BETA_TESTING.md) before testing.

## Build and contribute

The reviewed toolchain was Flutter 3.44.8 / Dart 3.12.2. Follow [Android build guidance](docs/BUILDING_ANDROID_BETA.md) for the retained beta-only configuration, version overrides, signing boundaries, and validation limits.

The repository preserves its existing Windows runner, examples, and optional Supabase scaffolding. This Android source update does not qualify a current Windows release, production upgrade, iOS build, or hosted service.

See [architecture](docs/ARCHITECTURE.md) and [privacy](docs/PRIVACY.md).

## License and content

First-party code is available under the [MIT License](LICENSE), copyright 2026 Oluwatoye Oladoja-Oladapo. Dependencies and Scripture retain their separate terms. The KJV sample contains 20 verses; the full text is downloaded from eBible only when requested. See [third-party notices](THIRD_PARTY_NOTICES.md), including the unresolved UK distribution caveat.
