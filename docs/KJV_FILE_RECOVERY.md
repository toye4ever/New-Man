# Recoverable KJV file replacement

The old installer used a shared `.download` filename and deleted `kjv.json`
before rename. A failed rename could remove the only readable edition.

The installer now converts/validates the archive as before, creates a unique
same-parent staging directory, writes with flush and verifies the encoded bytes.
An I/O error reading an existing primary aborts replacement before promotion.
Before replacing a readable primary, it writes/verifies a previous copy and
promotes that to `kjv.json.previous`. Only after read-back verification of this
fallback may it promote the new primary. No explicit destination deletion is
used. The platform rename may itself remove an existing file; the retained copy
covers that failure window. The previous copy is retained after success.

Both repository installation checks and a fresh Scripture reader prefer a
readable primary and recover from `.previous` if the primary is missing,
unreadable, invalid UTF-8 or invalid JSON/model envelope. Abandoned unique stages
are never considered installed content. Normal completion/failure attempts to
remove only its own stage. Restart recovery does not promote arbitrary `.download`
or staging files. Retrying with a corrupt/missing primary preserves an existing
readable fallback instead of copying the corrupt primary over it.

The archive converter's canonical 66-book/chapter/count/contiguous-reference
checks are unchanged. The storage envelope check is not a replacement for those
checks or a new claim that all legacy files have canonical integrity. No provider,
URL, content rights, edition or real device changes are introduced.

## Guarantees and limits

This is a recovery protocol, not an atomic multi-file transaction. Flushed file
writes and same-parent rename reduce interruption windows; Dart does not expose
portable directory fsync here, and no guarantee against power loss, disk loss,
external tampering or all platform/filesystem behaviors is made. Reads can return
the previous edition during an interrupted promotion. Existing reader instances
keep their current in-memory text; fresh readers use the recovery path.

Replacement is serialized by an exact absolute-path key within the current app
isolate, rejecting another concurrent writer. Unique stages prevent collisions.
This is not an interprocess/isolate lock; multiple processes/isolates writing the
same install directory are unsupported. Current archive conversion runs in an
isolate but file installation runs in the owning app isolate. No external process
is started. A retained previous copy and transient stage require extra storage;
insufficient space fails before deleting the prior readable copy. Orphan stage
cleanup after process death is deliberately deferred rather than guessing which
uncommitted files to promote/delete.

## Evidence

Tests use synthetic JSON, VPL snippets and temporary directories only. Injected
failures cover staged/truncated write, invalid model, backup promotion, a
Windows-like destination removal followed by rename failure, retry with corrupt
primary, concurrent replacement rejection, and fresh Scripture-reader reopen.
Repository tests preserve an installed fixture through HTTP failure and actual
canonical archive rejection, then reopen/reconcile availability. These are Linux
portable tests, not Android/Windows filesystem or power-cut qualification.

Run pinned Flutter 3.44.8 with the unchanged lockfile:

```
flutter pub get --offline --enforce-lockfile
flutter test --no-pub test/recoverable_kjv_file_test.dart test/translation_manager_test.dart
flutter analyze --no-pub
```

## Android/Windows path review — no device filesystem access

[Repository](../lib/src/services/bible_version_repository.dart) appends
`bibles/kjv.json` to `getApplicationSupportDirectory()`; [recovery storage](../lib/src/services/recoverable_kjv_file.dart)
uses sibling `kjv.json.previous` and unique `kjv-install-*` directories under the
same bibles parent. A first install need not have a previous copy. Legacy
`.download` and orphan stages are ignored, never automatically promoted.

The pinned `path_provider_android` 2.3.1 implementation uses Context `filesDir`.
A typical owner-user `.beta.dev` path is
`/data/user/0/com.newman.newmanapp.beta.dev/files/bibles/kjv.json`; `/data/data`
may alias it and profiles/users can differ. Runtime provider resolution is
authoritative. The `.beta` private directory is separate; no hard-coded Android
root was introduced by this change.

The pinned `path_provider_windows` 2.3.0 uses RoamingAppData plus sanitized
executable CompanyName/ProductName (or executable-name fallback). Current
[Runner.rc](../windows/runner/Runner.rc) declares `com.example` / `New Man`, yielding
ordinary `%APPDATA%\com.example\New Man\bibles\kjv.json`. This is not the source
checkout or Android path. Other binaries can supply different version resources;
Windows debug/release with matching resources may share this directory, so do
not assume Android `.dev` isolation on Windows. Dependency versions are recorded
in [pubspec.lock](../pubspec.lock); source review used their pinned implementations.

Do not move/delete/repair real files using these examples. Actual Android/Windows
rename, storage-exhaustion and power-cut qualification remain pending. The
[Galaxy smoke](GALAXY_ISOLATED_SMOKE.md) uses ordinary reading only, leaving failure
injection to synthetic temporary files and no personal data.
