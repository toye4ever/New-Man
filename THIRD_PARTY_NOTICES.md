# Third-party notices

New Man includes third-party software and Scripture content. First-party code is under the MIT License in LICENSE. Dependency and content terms are separate.

The app's Open-source licenses page contains Flutter package license metadata compiled into the binary. Android SDK, Gradle, Maven, and other platform components can carry separate terms. This document is a source-access guide, not a complete legal inventory or a claim that every platform artifact has completed license clearance.

## MPL 2.0 source access

The resolved Linux plugin chains include dbus 0.7.14 through file_picker / file_picker_linux, and gtk 2.2.0 through supabase_flutter / app_links / app_links_linux.

- [dbus 0.7.14 source](https://pub.dev/packages/dbus/versions/0.7.14)
- [gtk 2.2.0 source](https://pub.dev/packages/gtk/versions/2.2.0)
- [Mozilla Public License 2.0](https://www.mozilla.org/MPL/2.0/)
- [MPL 2.0 FAQ](https://www.mozilla.org/en-US/MPL/2.0/FAQ/)

Retain relevant notices and source availability when distributing these materials. Their presence in the lockfile does not mean that these Linux plugins are part of the Android APK, or that the entire application uses MPL.

## KJV provenance

The bundled assets/data/kjv.json contains 20 verses: Matthew 5:1-12, Psalm 23, and John 3:16-17. The full KJV is not bundled. On request, BibleVersionRepository downloads the [eBible VPL archive](https://ebible.org/Scriptures/eng-kjv_vpl.zip) and stores recognized 66-book text locally.

The [provider's copyright information](https://ebible.org/eng-kjv/copyright.htm) describes the standardized 1769 text as public domain outside the UK and warns about UK printing and import terms. [Cambridge's guidance](https://www.cambridge.org/sites/default/files/media/documents/Sample%20Text%20Pages.pdf) discusses limited liturgical/noncommercial educational quotations and permission for other uses. The precise UK treatment of this digital application and direct download remains unresolved. Do not treat this notice, MIT licensing, or a direct download as proof of worldwide content clearance.

## Source and binary relationship

The retained application and Android build inputs for the existing APK are mapped in docs/releases/v0.2.3-beta.1-source.json. The source was prepared for publication after the APK was built. The published binary tag is unchanged, and the source mapping does not establish bit-for-bit reproducibility.
