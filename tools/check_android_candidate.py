#!/usr/bin/env python3
"""Check the merged manifest of a newly built New Man APK."""

import argparse
from pathlib import Path
import subprocess
import struct
import zipfile
import sys
from xml.etree import ElementTree


ANDROID = "{http://schemas.android.com/apk/res/android}"
BETA_ID = "com.newman.newmanapp.beta"
ACCESSIBILITY_ACTION = "android.accessibilityservice.AccessibilityService"
ACCESSIBILITY_PERMISSION = "android.permission.BIND_ACCESSIBILITY_SERVICE"
GUARD_SERVICE = "com.newman.newmanapp.GuardAccessibilityService"


def verify_native_libraries(apk: Path, variant: str) -> list[str]:
    """Check bounded ELF headers, not linker correctness, alignment or signatures."""
    failures = []
    with zipfile.ZipFile(apk) as archive:
        libraries = [entry for entry in archive.infolist() if entry.filename.endswith(".so")]
        names = [entry.filename for entry in libraries]
        if len(names) != len(set(names)):
            failures.append("Duplicate native library ZIP entries.")
        required = {"lib/arm64-v8a/libflutter.so"}
        if variant == "release":
            required.add("lib/arm64-v8a/libapp.so")
        for missing in sorted(required - set(names)):
            failures.append(f"Missing required ARM64 library: {missing}.")
        for entry in libraries:
            parts = entry.filename.split("/")
            if len(parts) != 3 or parts[:2] != ["lib", "arm64-v8a"]:
                failures.append(f"Unexpected native library ABI/path: {entry.filename}.")
                continue
            with archive.open(entry) as library:
                header = library.read(64)
            if (len(header) != 64 or header[:7] != b"\x7fELF\x02\x01\x01"
                    or struct.unpack_from("<HHI", header, 16) != (3, 183, 1)
                    or struct.unpack_from("<H", header, 52)[0] != 64):
                failures.append(f"Expected ELF64 little-endian AArch64 shared object: {entry.filename}.")
    return failures



PAGE_SIZE = 16 * 1024
MAX_PROGRAM_HEADER_OFFSET = 1024 * 1024
MAX_PROGRAM_HEADERS = 1024


def verify_page_alignment(apk: Path) -> list[str]:
    """Bounded ELF64 PT_LOAD and stored-native ZIP checks, never execute/extract code.

    This is not a replacement for SDK zipalign or runtime/RELRO qualification.
    The existing native identity check separately restricts every .so to ARM64.
    """
    failures = []
    with zipfile.ZipFile(apk) as archive, apk.open("rb") as raw:
        libraries = [entry for entry in archive.infolist() if entry.filename.endswith(".so")]
        if not libraries:
            return ["No native libraries found for static page-alignment inspection."]
        for entry in libraries:
            name = entry.filename
            if entry.compress_type == zipfile.ZIP_STORED:
                raw.seek(entry.header_offset)
                local = raw.read(30)
                if len(local) != 30 or local[:4] != b"PK\x03\x04":
                    failures.append(f"{name}: malformed local ZIP header.")
                else:
                    method = struct.unpack_from("<H", local, 8)[0]
                    name_size, extra_size = struct.unpack_from("<HH", local, 26)
                    offset = entry.header_offset + 30 + name_size + extra_size
                    if method != zipfile.ZIP_STORED or offset + entry.compress_size > apk.stat().st_size:
                        failures.append(f"{name}: inconsistent stored ZIP entry.")
                    elif offset % PAGE_SIZE:
                        failures.append(f"{name}: stored ZIP data offset {offset} is not 16 KiB aligned.")
            with archive.open(entry) as library:
                header = library.read(64)
                if len(header) != 64 or header[:7] != b"\x7fELF\x02\x01\x01":
                    failures.append(f"{name}: cannot inspect ELF64 little-endian load headers.")
                    continue
                phoff = struct.unpack_from("<Q", header, 32)[0]
                phsize, phnum = struct.unpack_from("<HH", header, 54)
                if (phsize != 56 or not 1 <= phnum <= MAX_PROGRAM_HEADERS
                        or not 64 <= phoff <= MAX_PROGRAM_HEADER_OFFSET
                        or phoff + phsize * phnum > entry.file_size):
                    failures.append(f"{name}: invalid or unsupported bounded ELF program-header table.")
                    continue
                library.seek(phoff)
                table = library.read(phsize * phnum)
                if len(table) != phsize * phnum:
                    failures.append(f"{name}: truncated ELF program-header table.")
                    continue
                loads = 0
                for index in range(phnum):
                    kind, _, offset, address, _, _, _, alignment = struct.unpack_from(
                        "<IIQQQQQQ", table, index * phsize)
                    if kind != 1:  # PT_LOAD only; other segment types have different rules.
                        continue
                    loads += 1
                    if alignment < PAGE_SIZE or alignment & (alignment - 1):
                        failures.append(f"{name}: PT_LOAD[{index}] p_align={alignment:#x}; require power-of-two >= 0x4000.")
                    elif offset % alignment != address % alignment:
                        failures.append(f"{name}: PT_LOAD[{index}] file/virtual offsets are not congruent for p_align={alignment:#x}.")
                if not loads:
                    failures.append(f"{name}: no PT_LOAD segments inspected.")
    return failures


def verify_zipalign(apk: Path, executable: str) -> list[str]:
    """Run only the caller-selected trusted SDK tool, in verification mode."""
    try:
        result = subprocess.run(
            [executable, "-c", "-P", "16", "-v", "4", str(apk.resolve())],
            check=False, capture_output=True, text=True, encoding="utf-8", timeout=60,
        )
    except (OSError, subprocess.SubprocessError, UnicodeError) as error:
        return [f"ZIP alignment NOT verified: SDK zipalign unavailable/failed: {error}."]
    if result.returncode:
        return [f"ZIP alignment failed for {apk.name} (zipalign exit {result.returncode}):\n"
                + result.stdout + result.stderr]
    return []


def verify_manifest(root: ElementTree.Element, variant: str) -> list[str]:
    if root.tag != "manifest":
        return ["Input is not an Android manifest."]
    expected_id = f"{BETA_ID}.dev.nov17" if variant == "galaxy-test" else f"{BETA_ID}.dev" if variant == "debug" else BETA_ID
    failures = []
    if root.get("package") != expected_id:
        failures.append(f"Expected app ID {expected_id}; found {root.get('package')!r}.")
    forbidden_permissions = {
        "android.permission.POST_NOTIFICATIONS",
        "android.permission.SCHEDULE_EXACT_ALARM",
        "android.permission.USE_EXACT_ALARM",
    }
    for permission in list(root.findall("uses-permission")) + list(root.findall("uses-permission-sdk-23")):
        if permission.get(ANDROID + "name") in forbidden_permissions:
            failures.append("Dormant reminders must not declare notification/exact-alarm permissions.")
    app = root.find("application")
    if app is None:
        return failures + ["Application declaration is missing."]
    for receiver in app.findall("receiver"):
        if receiver.get(ANDROID + "name", "").split(".")[-1] in {
            "TaskReminderAlarmReceiver", "TaskReminderSystemReceiver"
        } or any(action.get(ANDROID + "name") == "com.newman.newmanapp.TASK_REMINDER_V1"
                 for action in receiver.findall("./intent-filter/action")):
            failures.append("Dormant task reminder receiver must not be registered.")
    expected_label = "New Man Test" if variant == "galaxy-test" else "New Man Dev" if variant == "debug" else "New Man Beta"
    if app.get(ANDROID + "label") != expected_label:
        failures.append(f"Expected application label {expected_label!r}.")
    if variant == "galaxy-test" and app.get(ANDROID + "name") != "com.newman.newmanapp.GalaxyTestApplication":
        failures.append("Temporary test must use its runtime identity guard.")
    if variant != "galaxy-test" and app.get(ANDROID + "name") == "com.newman.newmanapp.GalaxyTestApplication":
        failures.append("Temporary runtime identity guard leaked into an ordinary variant.")
    for component in list(app.findall("activity")) + list(app.findall("activity-alias")):
        launcher = any(
            any(action.get(ANDROID + "name") == "android.intent.action.MAIN" for action in entry.findall("action"))
            and any(category.get(ANDROID + "name") == "android.intent.category.LAUNCHER" for category in entry.findall("category"))
            for entry in component.findall("intent-filter")
        )
        if launcher and component.get(ANDROID + "label", expected_label) != expected_label:
            failures.append("Launcher component overrides the expected application label.")
    if app.get(ANDROID + "allowBackup") != "false":
        failures.append("Application must explicitly disable Android backup.")
    is_debuggable = app.get(ANDROID + "debuggable", "false")
    if is_debuggable != ("true" if variant in ("debug", "galaxy-test") else "false"):
        failures.append(f"Unexpected android:debuggable={is_debuggable!r}.")

    if variant == "release":
        if app.get(ANDROID + "testOnly", "false") != "false":
            failures.append("Release candidate must not be test-only.")
        if any(node.get(ANDROID + "shell", "false") != "false" for node in app.findall("profileable")):
            failures.append("Release candidate must not allow shell profiling.")

    def accessibility_service(service: ElementTree.Element) -> bool:
        return (
            service.get(ANDROID + "permission") == ACCESSIBILITY_PERMISSION
            or any(
                action.get(ANDROID + "name") == ACCESSIBILITY_ACTION
                for action in service.findall("./intent-filter/action")
            )
            or service.get(ANDROID + "name", "").split(".")[-1]
            == "GuardAccessibilityService"
        )

    services = [node for node in app.findall("service") if accessibility_service(node)]
    if variant == "release" and services:
        failures.append("Release candidate declares an unqualified accessibility service.")
    if variant in ("debug", "galaxy-test"):
        if len(services) != 1:
            failures.append("Expected one debug-only Guard qualification service.")
        elif services[0].get(ANDROID + "name") != GUARD_SERVICE:
            failures.append("Unexpected debug accessibility service class.")
        elif any(
            services[0].get(ANDROID + key) != value
            for key, value in {"exported": "false", "permission": ACCESSIBILITY_PERMISSION}.items()
        ):
            failures.append("Debug Guard must remain non-exported and permission-protected.")
    return failures


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("variant", choices=("debug", "release", "galaxy-test"))
    parser.add_argument("apk", type=Path)
    parser.add_argument("--apkanalyzer", default="apkanalyzer")
    parser.add_argument("--zipalign", required=True, help="Trusted preinstalled SDK zipalign path; never installs tools")
    opts = parser.parse_args()
    if not opts.apk.is_file():
        parser.error(f"APK does not exist: {opts.apk}")
    try:
        result = subprocess.run(
            [opts.apkanalyzer, "manifest", "print", str(opts.apk.resolve())],
            check=True, capture_output=True, text=True, encoding="utf-8", timeout=60,
        )
        errors = verify_manifest(ElementTree.fromstring(result.stdout), opts.variant)
        errors.extend(verify_native_libraries(opts.apk, opts.variant))
        errors.extend(verify_page_alignment(opts.apk))
        errors.extend(verify_zipalign(opts.apk, opts.zipalign))
    except (OSError, subprocess.SubprocessError, ElementTree.ParseError, zipfile.BadZipFile, RuntimeError, EOFError, UnicodeError, struct.error) as error:
        print(f"Could not inspect Android candidate: {error}", file=sys.stderr)
        return 2
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(f"{opts.variant.capitalize()} APK app ID, launcher label, backup policy, Guard/reminder containment and ARM64 ELF identity, static PT_LOAD and ZIP 16 KiB alignment verified (not runtime/RELRO/AAB qualification).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
