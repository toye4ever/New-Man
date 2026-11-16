#!/usr/bin/env python3
"""Check the merged manifest of a newly built New Man APK."""

import argparse
from pathlib import Path
import subprocess
import sys
from xml.etree import ElementTree


ANDROID = "{http://schemas.android.com/apk/res/android}"
BETA_ID = "com.newman.newmanapp.beta"
ACCESSIBILITY_ACTION = "android.accessibilityservice.AccessibilityService"
ACCESSIBILITY_PERMISSION = "android.permission.BIND_ACCESSIBILITY_SERVICE"
GUARD_SERVICE = "com.newman.newmanapp.GuardAccessibilityService"


def verify_manifest(root: ElementTree.Element, variant: str) -> list[str]:
    if root.tag != "manifest":
        return ["Input is not an Android manifest."]
    expected_id = f"{BETA_ID}.dev" if variant == "debug" else BETA_ID
    failures = []
    if root.get("package") != expected_id:
        failures.append(f"Expected app ID {expected_id}; found {root.get('package')!r}.")
    app = root.find("application")
    if app is None:
        return failures + ["Application declaration is missing."]
    expected_label = "New Man Dev" if variant == "debug" else "New Man Beta"
    if app.get(ANDROID + "label") != expected_label:
        failures.append(f"Expected application label {expected_label!r}.")
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
    if is_debuggable != ("true" if variant == "debug" else "false"):
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
    if variant == "debug":
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
    parser.add_argument("variant", choices=("debug", "release"))
    parser.add_argument("apk", type=Path)
    parser.add_argument("--apkanalyzer", default="apkanalyzer")
    opts = parser.parse_args()
    if not opts.apk.is_file():
        parser.error(f"APK does not exist: {opts.apk}")
    try:
        result = subprocess.run(
            [opts.apkanalyzer, "manifest", "print", str(opts.apk.resolve())],
            check=True, capture_output=True, text=True, encoding="utf-8", timeout=60,
        )
        errors = verify_manifest(ElementTree.fromstring(result.stdout), opts.variant)
    except (OSError, subprocess.SubprocessError, ElementTree.ParseError) as error:
        print(f"Could not inspect merged Android manifest: {error}", file=sys.stderr)
        return 2
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(f"{opts.variant.capitalize()} APK app ID, launcher label, backup policy, and Guard isolation verified.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
