# Windows Debug storage isolation — source fix, runtime qualification pending

The pinned `path_provider_windows` 2.3.0 resolves ApplicationSupport under
RoamingAppData, using the executable's sanitized CompanyName/ProductName from
VERSIONINFO. `shared_preferences_windows` 2.4.1 uses the same support path for
`shared_preferences.json`, for both legacy and async preferences APIs. Dependency
versions remain unchanged in [pubspec.lock](../pubspec.lock).

[Runner identity](../windows/runner/runner_identity.h) now selects ProductName
`New Man Dev` only when `_DEBUG` is defined. The existing
[standard settings](../windows/CMakeLists.txt) define `_DEBUG` only for Debug and
are applied to the runner target, including its resources. The
[resource](../windows/runner/Runner.rc) uses this name for ProductName and
FileDescription; the [window title](../windows/runner/main.cpp) also identifies
Debug visibly. No executable target rename or Dart storage override is needed.

| Configuration | CompanyName / ProductName | Ordinary support directory |
| --- | --- | --- |
| Debug | `com.example` / `New Man Dev` | `%APPDATA%\com.example\New Man Dev` |
| Release | `com.example` / `New Man` (unchanged) | `%APPDATA%\com.example\New Man` |
| Profile | Same as Release (unchanged) | Same as Release — **not isolated** |

Database (`database/new_man.sqlite`), KJV (`bibles/kjv.json` plus retained copy),
local recovery backups and default shared preferences therefore follow the new
Debug root. This is application storage separation, not an OS sandbox, separate
Windows account or a claim that user-selected files/system temp are isolated.
Runtime provider resolution remains authoritative; a missing VERSIONINFO can
trigger filename fallback and must fail qualification rather than be guessed.

## Existing data and upgrade behavior

Release/Profile CompanyName, ProductName, OriginalFilename, InternalName, version
resources and target name are preserved. The release window title stays New Man.
No code copies, moves, deletes, imports or searches for the historical support
directory. Existing release upgrades retain the same storage root and existing
migration flow. Old debug builds may already have written into that root; this
change cannot separate historical mixed data retroactively. Leave it untouched.

New Debug starts with its own directory/preferences, normally empty. It does not
borrow historical release preferences for convenience or migrate them into Dev.
An existing New Man Dev directory may already contain test data; do not clear it
without separate approval. Do not use Profile for tests, and do not launch any
older Debug build assuming it has this isolation.

## Portable verification performed

`python3 -m unittest discover -s tools -p 'test_*.py'` runs the identity checks
using an existing C preprocessor and a synthetic empty `winres.h`. It preprocesses
real Runner.rc/header branches, verifies distinct Debug identity and title,
preserves Release/Profile values, and checks the existing Debug-only CMake define.
An independent preprocessing comparison also verifies that non-Debug resource
tokens match the prior source exactly. No real app files/preferences are opened.
These checks do **not** compile a Windows `.res`/executable, execute a provider or
prove runtime Windows isolation. No SDK/tool download or CI change is included.

## Future Windows qualification (not run, not a FRIDAY instruction)

Use a separately authorized isolated Windows build/test environment and synthetic
inputs only. Do not attach FRIDAY, use production data, move directories or change
settings as a shortcut. Before any executable launch:

1. Build exact candidate Debug and Release with the pinned Flutter/lockfile on an
   authorized Windows builder. Confirm the resource compiler succeeds. Inspect
   each produced executable's FileVersionInfo read-only (for example PowerShell
   `(Get-Item '<debug-exe>').VersionInfo`), not just the source header.
2. Require Debug ProductName/FileDescription `New Man Dev`, Release `New Man`,
   CompanyName `com.example` for both, and unchanged release filename/version
   fields. Do not launch a binary whose resource identity is missing/unexpected.
3. Launch only the verified Debug bundle; require visible New Man Dev title and
   no personal tasks/plans/preferences. Stop if existing personal records appear.
4. Create `SMOKE WINDOWS` with a synthetic subtask and choose a harmless app
   appearance preference. Close/reopen Debug: both persist. Locally confirm new
   storage is under the Dev support root, including database/preferences; do not
   open or copy the release database. Any write to the historical root is FAIL.
5. Verify a subsequent exact Debug launch reuses Dev data. Do not launch Profile
   as an isolation test. Release runtime/upgrade testing requires a separate
   synthetic fixture environment, not the historical real-data directory.
6. Keep evidence to commit/build IDs, resource identity, resolved relative paths
   and synthetic results. No personal file contents or global logs. On mismatch,
   close the binary, preserve files and report; do not repair/migrate/delete data.

Every Windows compile/runtime row remains **NOT RUN**. Portable checks are the
current evidence; real resource linking and provider behavior remain blockers to
calling Windows developer installs qualified.

## Feature-branch compiled identity gate

[Windows feature identity workflow](../.github/workflows/windows-feature-identity.yml)
uses standard `windows-latest`, following the existing Windows check's host,
but only for this repository's `mvp/nov-17` push events. It has read-only contents
permission, pinned checkout action, official Flutter 3.44.8 tag plus mandatory
revision/self-report assertions, locked dependencies, a 30-minute bound and no
signing, artifacts, main trigger or app launch. Android CI is unchanged. Build-tool
APPDATA/LOCALAPPDATA/PUB_CACHE are redirected to runner-temp directories before
Flutter starts; no existing user application storage is inspected or migrated.
It builds Debug and Release, then
[reads VERSIONINFO](../tools/read_windows_exe_identity.ps1) only from their exact
expected executable paths. [Validation](../tools/check_windows_exe_identity.py)
requires company, product, description, internal/original names, Debug flags and
matching nonempty version fields. Missing/unexpected resources fail closed.

Portable tests exercise synthetic JSON records and actual C preprocessing.
PowerShell is unavailable on the local Linux executor: its source was reviewed,
but no claim is made that its parser/FileVersionInfo path ran here. Workflow YAML,
contexts and source restrictions were checked separately. The first published
exact-head Windows run must establish PowerShell execution, resource compilation,
EXE paths and metadata values. It still does not establish runtime provider paths
or data isolation because it never launches the app. The owner-driven synthetic
runtime checks above remain separate, unrun gates; do not test them on FRIDAY.
