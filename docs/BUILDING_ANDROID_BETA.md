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
python3 tools/check_android_candidate.py release build/app/outputs/flutter-apk/app-release.apk --zipalign "$ANDROID_HOME/build-tools/36.0.0/zipalign"
python3 tools/check_android_candidate.py debug build/app/outputs/flutter-apk/app-debug.apk --zipalign "$ANDROID_HOME/build-tools/36.0.0/zipalign"
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
`mvp/nov-17` branch, on the standard `macos-15-intel` x64 runner with read-only contents
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
`apkanalyzer`, NDK 28.2.13676358 and x64 JDK 21 already installed on the runner.
It asserts macOS/x86_64, checks Java's major version and x64 architecture, and points job-local NDK aliases at the pinned package rather than the runner default. The NDK host path is
`darwin-x86_64`, also used on the earlier Apple Silicon host; these macOS NDK tools are fat
binaries ([NDK host documentation](https://developer.android.com/ndk/guides/other_build_systems)).
The script also accepts an explicit Linux host tag for local preflight checks;
a Linux toolchain cannot pass the macOS check.

The workflow does not run sdkmanager or accept licenses; SDK auto-download is
disabled in Gradle. Missing components fail before fetching Flutter or resolving
build inputs. Standard Flutter/Gradle build dependency resolution still needs
network access. No SDK archive sideload or retry of denied cloud SDK downloads
is added. Shell commands use macOS-compatible tools, including `shasum` for the
resulting APK hash.

The [macOS 15 x64 runner inventory](https://github.com/actions/runner-images/blob/main/images/macos/macos-15-Readme.md)
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

## Optional unsigned release build gate

The repository's `android/app/build.gradle.kts` explicitly sets release
`signingConfig = null`. Source inspection found no release keystore-property
loader, signing secret or assignment to the debug signer. This CI unit changes
no Android build configuration, permissions or signing behavior. Debug builds
and their existing manifest check still run first and are unchanged.

The final workflow step runs only when the checked-out feature-branch commit
contains `.ci/verify-unsigned-release` with the exact text `enabled` (a trailing
newline is fine). The marker is enabled on this feature-branch candidate. To request
the extra gate, create that file locally and include it in the authorized
`mvp/nov-17` candidate commit; the existing push-only, repository/branch-guarded
workflow then evaluates the checked-out marker. Remove it in a later commit to
skip the gate again. This is not a workflow dispatch, arbitrary-ref trigger,
settings change or request to publish anything now. The step uses `hashFiles`
only at the documented [step-if context](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts#context-availability).
The existing standard macOS runner, time limit, read-only permissions, exact
Flutter/Gradle/CMake pins and preinstalled-only SDK preflight remain in force.

The gate builds `flutter build apk --release --target-platform android-arm64
--no-pub`, with SDK auto-download disabled. The pinned Flutter Gradle plugin
copies the variant output into `build/app/outputs/flutter-apk/app-release.apk`
even when the original Gradle output is unsigned. Runtime CI must establish the
actual output and complete compilation; no new release APK was built locally.

`tools/check_unsigned_apk.py` rejects JAR signing material and the APK signing
block before the ZIP central directory. Unknown/ZIP64/ambiguous layouts fail
closed. Synthetic fixtures cover unsigned, v1-signature entries, signing-block
containers, malformed/missing manifest and trailing bytes. This is absence-of-
signing evidence for a conventional APK, not signature authenticity validation.
The existing compiled manifest checker then requires the beta package (no `.dev`),
explicit backups off, no debuggable/test-only/shell-profileable flags and no
Guard/accessibility declaration. The APK hash is printed, but no binary is
uploaded, installed, signed, released or deployed. No secrets are needed.

An unsigned release candidate is a build/containment check, not an installable
production release or hardware qualification. The real debug build at published
`e99ee2a` passed in run 43962308608; it provides no evidence that this optional
release path has run. Exact-head release CI remains pending publication and runner execution.
The private debug acceptance commit `fe15c13` remains separate and unchanged.


## Intel host attempt after ARM runner capacity failure

Run 43966107083 on `7986836` ended cancelled before runner acquisition; the public
annotation reported constrained macOS ARM capacity, not an app compile failure
(parent evidence). This next candidate selects the standard `macos-15-intel`
runner and asserts Darwin/x86_64. It uses preinstalled `JAVA_HOME_21_X64`, asserts
Java 21 and x64 architecture, and retains `darwin-x86_64` NDK host tools. The
independently hash-pinned Kitware CMake 3.22.1 universal archive is unchanged and
contains x86_64; actual CMake/Ninja execution is still checked before Flutter.
The Android target remains ARM64 for both debug and unsigned release builds.

The official x64 runner inventory checked November 16 lists API 36, build-tools
36.0.0 and NDK 28.2.13676358. These are preflight requirements, not permission to
install missing packages. Flutter tag/revision, lockfile, Gradle and CMake pins,
read-only contents permission and the feature-only repository/ref guard remain
unchanged. No larger runner, signing, binary upload, deployment or device action
is added. `.ci/verify-unsigned-release` now contains `enabled`, selecting the
existing release-containment step after the unchanged debug checks. Runtime
runner availability, compilation, unsigned container and compiled manifests for
this exact combined candidate are pending CI. No capacity guarantee is made.


## Distinct Android debug launcher label

The debug manifest alone overrides `android:label` to `New Man Dev`, using
`tools:replace="android:label"`. Android's documented
[attribute merge rule](https://developer.android.com/build/manage-manifests#attribute_markers)
keeps the higher-priority debug value without replacing the application node or
other attributes/children. The main/public label remains `New Man Beta`; IDs,
backups, Guard service containment and permission declarations are unchanged.
The compiled-manifest checker now requires these exact variant labels and rejects
MAIN/LAUNCHER activities/aliases with conflicting label overrides. Source XML and
synthetic checker tests do not execute AGP merging or inspect a new APK. Those
remain exact-head CI gates; actual Galaxy launcher presentation remains NOT RUN.
A visible Dev label helps selection but never substitutes for package/hash proof.


## Native library and dormant-reminder containment

The existing candidate checker now inspects packaged `.so` entries without
extracting or executing them. Each must be under `lib/arm64-v8a/`, have a unique
ZIP name and a 64-byte ELF header identifying a little-endian ELF64 AArch64 shared
object. Flutter's engine is required in both variants; release additionally
requires `libapp.so`, while Debug may use JIT without it. Only the first 64 bytes
per library are read. Synthetic fixtures cover missing/duplicate libraries,
wrong ABI/path, x64/32-bit headers and truncation. The existing local historical
public APK passed this header-only check; it is not the new candidate.

Merged-manifest checks also reject POST_NOTIFICATIONS, SCHEDULE_EXACT_ALARM and
USE_EXACT_ALARM declarations (including uses-permission-sdk-23), known task
reminder receivers and the task-reminder broadcast action. These boundaries match
the still-unregistered foundation; any future reviewed wiring must explicitly
revisit them. This unit adds no permission or native/app behavior.

The workflow calls this checker for Debug and unsigned Release. This original
identity-header stage alone does not verify ELF load alignment, ZIP payload
integrity, runtime linking, 16 KB compatibility or hardware behavior. The later
static alignment gate below adds separate checks and needs new exact-head CI
evidence.
It does not prove Debug's signer/certificate identity. Release absence of signing
material remains the separate unsigned-container check, not a claim of signed
release provenance. Record compiled-manifest, container, native-header and actual
device evidence separately; do not infer device qualification from this gate.

## Explicit ABI split for branch diagnostic APKs

Run 43978763332 on `d1d22b0` compiled Debug successfully but the strict native
checker found four dependency entries outside ARM64: `libdartjni.so` and
`libdatastore_shared_counter.so` under both `armeabi-v7a` and `x86_64`.
`--target-platform android-arm64` selected Flutter's ARM64 code without removing
those dependency ABIs from the non-split APK. That artifact was ARM64-targeted,
not ARM64-only; rejecting it under the strict diagnostic contract was expected.

The pinned Flutter revision's
[Gradle plugin](https://github.com/flutter/flutter/blob/058e0af2c2b57e369d905a03ac9748b0ebf543c6/packages/flutter_tools/gradle/src/main/kotlin/FlutterPlugin.kt)
uses its supported ABI list for non-split dependency filtering. With
`--split-per-abi`, it enables ABI splits, resets the list, disables the universal
APK and includes the requested target ABI. Its
[APK output selection](https://github.com/flutter/flutter/blob/058e0af2c2b57e369d905a03ac9748b0ebf543c6/packages/flutter_tools/lib/src/android/gradle.dart)
then expects `app-arm64-v8a-debug.apk` / `app-arm64-v8a-release.apk`.

Only this repository/ref-guarded feature workflow now passes both
`--target-platform android-arm64 --split-per-abi` and selects those exact files.
There is no fallback to a fat APK or allowlist bypass. Native ELF checks,
notification/receiver/Guard containment, labels, backup policy and unsigned
release checks are unchanged. Normal/local build defaults, Android Gradle
configuration, signing and dependency pins are untouched. The verified Today
harness remains a separate preceding commit with no changes.

Flutter applies ABI-specific version codes to split APKs. These are temporary
build-check outputs, not an approved install/release; record actual version codes
before any separately authorized device work. No artifact upload is added.

Portable regression fixtures reproduce all four dependency paths and prove both
variants reject that fat layout while accepting the expected ARM64 split layout.
YAML/Bash/context/output-path checks verify workflow wiring; they do not execute
Gradle packaging. A fresh exact-head CI run must compile both splits and inspect
the actual APKs before this correction is considered runtime verified. No new
APK or device evidence is claimed from local tests.

A separately approved, first-attempt-only one-day debug download is scoped in
[ONE_DAY_DEBUG_DOWNLOAD.md](ONE_DAY_DEBUG_DOWNLOAD.md). Its literal prior-head
guard is a narrow exception to earlier no-artifact checks, not standing upload
permission; unsigned release verification remains unchanged.


## Static 16 KiB alignment gate

The feature workflow now requires two independent checks on **each exact debug
and unsigned release APK**, following [Android's page-size guidance](https://developer.android.com/guide/practices/page-sizes):

- Bounded, dependency-free inspection of ELF64 PT_LOAD headers requires a
  power-of-two `p_align >= 0x4000` and congruent file/virtual offsets. A stored
  native library's local ZIP data offset must also be divisible by 16384.
- The pinned preinstalled SDK tool runs `zipalign -c -P 16 -v 4 APK` in read-only
  verification mode. This independently checks APK alignment, including the
  ordinary four-byte alignment of other uncompressed entries. Compressed native
  entries have no direct ZIP mmap alignment requirement; ELF checks still apply.

`--zipalign` is mandatory. The existing SDK preflight already required the
Build-Tools 36.0.0 file, and now also requires it executable. The
[standard Intel runner inventory](https://github.com/actions/runner-images/blob/main/images/macos/macos-15-Readme.md)
lists Build-Tools 36.0.0. Missing tools, unsupported flags, tool timeout/nonzero
exit, malformed/unsupported ELF tables or misalignment fail the gate; no SDK
installation, realignment, signing or fallback is attempted. Failures identify
library/segment or ZIP offset, or retain the SDK tool's package diagnostics.

Synthetic positive/negative tests exercise 16/64 KiB versus 4 KiB LOAD alignment,
malformed tables, misaligned stored native entries, compressed libraries and the
exact trusted-tool argument vector/failure path. They do not execute libraries.
The SDK subprocess is mocked in these portable tests; this cloud executor has no
SDK zipalign. Actual Build-Tools execution and the current APKs' alignment remain
pending an exact-head CI run, not established by fixture success.
ELF program tables are bounded to 1024 entries and a 1 MiB starting offset;
unsupported layouts fail explicitly rather than receiving an alignment pass.

Local SDK zipalign is unavailable in the restored executor. Its invocation is
mocked in portable tests; **a fresh exact-head hosted build must establish the
real zipalign result on both APKs**. Prior successful build/identity checks do not
establish this new result. No current APK is declared aligned or broken here.
These are static PT_LOAD/ZIP checks only: no RELRO audit, full ELF validity,
runtime linking, 16 KiB device behavior, AAB/Play or signing qualification is
claimed. Packaging/linker settings and the literal one-day upload authorization
conditions are unchanged.
