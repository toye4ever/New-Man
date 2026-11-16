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

Contributor debug builds from the current source use `com.newman.newmanapp.beta.dev` so they can be installed alongside the signed beta, which retains `com.newman.newmanapp.beta`. Older debug builds may use the signed beta application ID; verify the APK identity before installing and never uninstall the signed beta to resolve a signature mismatch. Each package has separate app data; the developer build is not an upgrade or migration test for the signed beta.

## What is and is not verified

The retained application/build-input hashes were checked before this source snapshot was prepared. The existing APK received static and bounded Android runtime checks. Neither fact proves this fresh-checkout command succeeds or produces identical APK bytes.

A new APK needs its own identity, signing, manifest, alignment, native-library, and bounded installation/startup checks. Publishing this unchanged source snapshot does not require rebuilding or replacing the already-published APK. Preserve the existing release tag and hash.

## Check a newly built candidate manifest

After building, use Android SDK `apkanalyzer` (with SDK build-tools installed)
from the same SDK to inspect the merged APK manifest:

```sh
python3 tools/check_android_candidate.py release build/app/outputs/flutter-apk/app-release.apk
python3 tools/check_android_candidate.py debug build/app/outputs/flutter-apk/app-debug.apk
python3 -B -m unittest discover -s tools -p test_check_android_candidate.py
```

Use `--apkanalyzer /path/to/apkanalyzer` when it is not on PATH. The check
requires backup disabled, the expected package identity and debuggable flag,
and no accessibility service in release. Debug must use the separate `.dev`
identity and contain exactly the protected Guard qualification service.
An inspection failure exits 2; a rejected manifest exits 1. A passing manifest
check does not qualify Guard behavior, signing, clean installation, or device
flows. The historical beta predates containment and is not a new candidate.

## Bounded feature-branch Android CI

`android-feature-check.yml` runs only for pushes to this repository's
`mvp/nov-17` branch, on the standard `macos-15` ARM64 runner with read-only contents
permission. It does not use a larger/xlarge runner. It pins the checkout action to
a full commit SHA and fetches Flutter's official
`refs/tags/3.44.8` tag, retaining its name in the shallow clone. Both the tag target
and HEAD must equal `058e0af2c2b57e369d905a03ac9748b0ebf543c6`. Before Android
precache or app dependency resolution, Flutter's own machine-readable report must
confirm version 3.44.8 and that revision. No version file is invented or edited.
The build uses the source Gradle 9.1.0 wrapper and locked dependencies, rather than
the runner's globally installed Gradle. The checked-out
commit is asserted against the event SHA. There is no release, deployment,
custom signing, artifact upload, device operation, or use of stored secrets.
The existing Windows workflow remains a separate check.

Preflight requires Android platform 36, build-tools 36.0.0, platform-tools,
`apkanalyzer`, NDK 28.2.13676358 and ARM64 JDK 21 already installed on the runner.
It asserts macOS/ARM64, checks Java's major version, and points job-local NDK aliases at the pinned package rather than the runner default. The NDK host path is
`darwin-x86_64`, including on Apple Silicon; these macOS NDK tools are fat
binaries ([NDK host documentation](https://developer.android.com/ndk/guides/other_build_systems)).
The script also accepts an explicit Linux host tag for local preflight checks;
a Linux toolchain cannot pass the macOS check.

The workflow does not run sdkmanager or accept licenses; SDK auto-download is
disabled in Gradle. Missing components fail before fetching Flutter or resolving
build inputs. Standard Flutter/Gradle build dependency resolution still needs
network access. No SDK archive sideload or retry of denied cloud SDK downloads
is added. Shell commands use macOS-compatible tools, including `shasum` for the
resulting APK hash.

The [macOS 15 ARM64 runner inventory](https://github.com/actions/runner-images/blob/main/images/macos/macos-15-arm64-Readme.md)
checked on November 16, 2026 lists platform 36, build-tools 36.0.0,
platform-tools, NDK 28.2.13676358 and JDK 21. Runner inventory may change, so the
actual preflight result remains authoritative. Local synthetic preflight tests
do not prove runner readiness or Android compilation. A passing debug ARM64
build and compiled-manifest check remain distinct from installation and device
smoke qualification. The workflow must be published with GitHub workflow-write
access before a run can provide that evidence.

Run 43955599219 passed SDK/NDK/JDK preflight and locked Flutter dependencies,
then `configureCMakeDebug[arm64-v8a]` failed CXX1300 because CMake 3.22.1 was
missing. The feature check now obtains Kitware's host macOS universal 3.22.1
archive into runner temp, independently pins its SHA-256 in
`tools/prepare_host_cmake.py`, verifies before extraction, and checks the actual
binary version and preinstalled Ninja before Flutter setup. This is a host tool,
not an Android SDK package. It does not run sdkmanager or change the version pin.

The hash comes from Kitware's [official release checksum manifest](https://github.com/Kitware/CMake/releases/download/v3.22.1/cmake-3.22.1-SHA-256.txt),
listed alongside its detached signature in the [release assets](https://github.com/Kitware/CMake/releases/expanded_assets/v3.22.1).
The archive hash was verified locally; detached-signature verification is not
claimed. The setup follows Android's [custom CMake instructions](https://developer.android.com/studio/projects/install-ndk#vanilla_cmake):
add the installation bin directory to PATH, retain preinstalled Ninja, and set
`cmake.dir` in ignored runner-local `android/local.properties` while preserving
Flutter and SDK entries. Linux tests verify extraction/layout and properties;
executing the macOS binary and AGP's selection remain CI checks.

Hash provenance: [Kitware 3.22.1 release assets](https://github.com/Kitware/CMake/releases/expanded_assets/v3.22.1),
[official SHA-256 manifest](https://github.com/Kitware/CMake/releases/download/v3.22.1/cmake-3.22.1-SHA-256.txt)
and its [published signature](https://github.com/Kitware/CMake/releases/download/v3.22.1/cmake-3.22.1-SHA-256.txt.asc).
The independent manifest entry is
`9ba46ce69d524f5bcdf98076a6b01f727604fb31cf9005ec03dea1cf16da9514`.
Signature verification is not claimed. Selection follows Android's documented
[standalone CMake setup](https://developer.android.com/studio/projects/install-ndk#vanilla_cmake):
PATH includes its bin directory and ignored `android/local.properties` points
`cmake.dir` at `CMake.app/Contents`. Existing SDK/Flutter properties are preserved.
Local Linux checks verify the real archive hash, safe extraction, universal binary
layout, YAML and Bash; macOS execution, Ninja availability and AGP selection remain
CI checks. See failed [run 43955599219](https://github.com/toye4ever/New-Man/actions/runs/43955599219).
