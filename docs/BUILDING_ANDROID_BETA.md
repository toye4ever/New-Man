# Android beta source and builds

This snapshot preserves the application source and Android configuration retained for the already-published 0.2.3-beta.1+5 APK. It is a beta-only configuration with no product flavors. It is not the later contributor-flavor configuration, a production signing setup, or a verified bit-for-bit reproduction recipe.

## Prerequisites

Use Flutter 3.44.8 / Dart 3.12.2 and a compatible Android SDK and Java installation. The source specifies Gradle 9.1.0, Android Gradle Plugin 9.0.1, Kotlin plugin 2.3.20, and Java/JVM target 17. Java target 17 is not itself a claim that Java 17 is a sufficient Gradle runtime: use a JDK compatible with the pinned Android Gradle Plugin. Android Studio's compatible bundled JDK is the normal starting point.

The existing artifact targets and compiles against API 36, has minimum API 24, and includes ARM64 only. The lockfile requires Flutter >=3.44 and Dart >=3.12 even though pubspec.yaml has a broader Dart constraint. Restore the checked-in lockfile without upgrading it.

Normal Flutter tooling must generate local SDK properties, plugin registration, and any missing wrapper/bootstrap files. Local SDK paths and generated dependency files are intentionally absent. The original build used an assisted cached SDK/native-asset setup. A later incremental build succeeded after an earlier failed attempt, and independent review checked its unsigned-to-signed payload preservation. The build also used external ARM64/native initialization overlays that are not included in this curated source snapshot. This portable recipe still needs clean-checkout qualification. Network access may be needed for official dependencies.

## Source checks

From a fresh public checkout:

```powershell
flutter --version
flutter pub get --enforce-lockfile
flutter analyze --no-pub
flutter test --no-pub
```

Do not silently change dependency versions to get a passing build. Report a failure with the toolchain version and a sanitized error excerpt.

## Unsigned Android packaging

```powershell
flutter build apk --release --target-platform android-arm64 --build-name 0.2.3-beta.1 --build-number 5 --no-pub
```

There is no --flavor argument for this snapshot. The source pubspec version remains 0.2.2+4 because the published beta supplied version 0.2.3-beta.1+5 through build properties; the explicit overrides above preserve that intent.

The Android configuration uses namespace com.newman.newmanapp, application ID com.newman.newmanapp.beta, label New Man Beta, unsigned release packaging, and disabled shrinking/minification. Backup is disabled and the retained cloud/device-transfer exclusions are included.

An unsigned APK is not the signed release download and cannot be installed as such. Do not add signing credentials to this repository. The public source does not include the owner's key and does not authorize publishing a newly signed artifact.

Contributor debug builds use the same beta application ID in this retained configuration, unlike newer flavor proposals. Do not install them over an existing signed beta or uninstall that beta to resolve a signature mismatch. Use an emulator or separate test device with no beta data. Production app data is separate and is not automatically migrated.

## What is and is not verified

The retained application/build-input hashes were checked before this source snapshot was prepared. The existing APK received static and bounded Android runtime checks. Neither fact proves this fresh-checkout command succeeds or produces identical APK bytes.

A new APK needs its own identity, signing, manifest, alignment, native-library, and bounded installation/startup checks. Publishing this unchanged source snapshot does not require rebuilding or replacing the already-published APK. Preserve the existing release tag and hash.
