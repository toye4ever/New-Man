# One approved Android debug download

The project owner explicitly approved a one-day GitHub Actions debug APK download after being
told that signed-in users can download from this public repository. This is a
single delivery approval, not standing upload permission or device-install
approval. The artifact is named **New Man Dev for Galaxy**.

The existing feature-only Android workflow contains one upload step pinned to
official `actions/upload-artifact` v4.6.2 commit
`ea165f8d65b6e75b540449e92b4886f43607fa02`. The official tag was resolved directly
and cross-checked against its release/action definition. The sole payload is
`build/app/outputs/flutter-apk/app-arm64-v8a-debug.apk`, with `retention-days: 1`,
missing-file failure, hidden files excluded and overwrite disabled. No release
APK, signing key, directory, source bundle, database, preferences or extra
translation asset is selected.

Both payload recheck and upload require success, the exact repository and
`mvp/nov-17` ref, a push whose literal `github.event.before` equals
`279c2f4cf5350d9ae126a945a7d18d954e362726`, and `github.run_attempt == '1'`.
Debug compilation/check outcomes must be successful; immediately before upload,
the file must be a regular non-symlink and pass the compiled debug manifest/
native-containment checker again. Upload also requires that recheck succeeded.
The unsigned release compile/check step stays in place before delivery; global
success means a failed preceding gate blocks the upload.

Later forward pushes have a different prior SHA; manual reruns have another run
attempt. Neither uploads. There is no workflow_dispatch, workflow_call, fork/PR
trigger, new token permission, release, deployment or device operation. If this
attempt fails or expires, another upload requires a new explicit owner approval;
do not loosen the guard or change the prior SHA to retry under this approval.

The APK is built from a clean public source checkout without starting the app,
reading an installed edition/profile or configuring backend credentials. The
existing declared Scripture asset is the bundled KJV sample; no separate/full
edition asset is introduced. Existing debug signing is unchanged; a public APK
certificate is not the private signing key. This is the narrow approved exception
to the earlier no-artifact build checks, not production or hardware qualification.

The parent will publish only after current checks settle. Local preparation did
not upload anything. Runtime build/check/upload success, artifact link and expiry
must be observed from the eventual exact-head workflow run; this document does
not claim they have occurred.

## Separate temporary Galaxy test download — November 17, 2026

A separate one-day approval covers **New Man Test for Galaxy**, not a replacement
of either beta installation. Its fixed opt-in Gradle property
`newManGalaxyTest=true` selects Debug ID `com.newman.newmanapp.beta.dev.nov17`,
label `New Man Test`, and a debug-only Application that checks its actual runtime
package, debuggable flag and label before app startup. Ordinary Debug remains
`.beta.dev` / `New Man Dev`; Release remains `.beta` / `New Man Beta`, unsigned.
No production entry point, storage migration, permissions or provider is added.
The suffix has its own Android app-private storage; no old app data is read or
copied. Actual install/startup/storage isolation still requires device evidence.

Three new steps in the existing workflow require exact repository/ref, successful
preceding gates, push, literal prior SHA
`d2b3d4b3d2f70c4d1399484ce4184594fd9e2a02` and first run attempt only. They build
only temporary Debug ARM64, check its exact package/label/runtime guard plus all
existing backup, manifest, ABI and static alignment restrictions, then upload
only `build/app/outputs/flutter-apk/app-arm64-v8a-debug.apk` with retention one
day and the same pinned official action. The original upload gate is unchanged
and cannot match this prior SHA. Release checks run before the temporary build;
no Release APK or other file is uploaded. Failed or rerun attempts need a new
explicit approval; do not broaden the guard. No dispatch, reuse or PR trigger.
GitHub retention is one day, not a promise of deletion at an exact wall-clock
second; signed-in users can download during availability.

TTS discovery, SQLite/preferences and KJV storage use runtime context/provider
paths and require no external package registration. Their actual temporary-package
behavior is unqualified until native CI and isolated device checks run. The native
reminder qualification session intentionally accepts only `.beta.dev`, so remains
unavailable here; do not expand that allowlist. Guard remains debug-contained and
unqualified, with no activation needed for audio. No backend defines, voice install,
extra translation asset, signing credential or device operation is introduced.
