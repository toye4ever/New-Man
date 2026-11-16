"""Unit tests for the New Man Android candidate guardrail."""
import unittest
from pathlib import Path
from xml.etree import ElementTree

from check_android_candidate import verify_manifest


def manifest(package="com.newman.newmanapp.beta", app_attrs="", inside="", label=None):
    label = label if label is not None else ("New Man Dev" if package.endswith(".dev") else "New Man Beta")
    return ElementTree.fromstring(
        f'<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="{package}">'
        f'<application android:allowBackup="false" android:label="{label}" {app_attrs}>{inside}</application></manifest>'
    )


GUARD = (
    '<service android:name="com.newman.newmanapp.GuardAccessibilityService" '
    'android:exported="false" android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE"/>'
)


class ManifestTests(unittest.TestCase):
    def test_debug_source_override_is_label_only(self):
        root = Path(__file__).resolve().parents[1]
        debug = ElementTree.parse(root / "android/app/src/debug/AndroidManifest.xml").getroot().find("application")
        main = ElementTree.parse(root / "android/app/src/main/AndroidManifest.xml").getroot().find("application")
        self.assertEqual(debug.attrib, {
            "{http://schemas.android.com/apk/res/android}label": "New Man Dev",
            "{http://schemas.android.com/tools}replace": "android:label",
        })
        self.assertEqual(main.get("{http://schemas.android.com/apk/res/android}label"), "New Man Beta")

    def test_debug_requires_distinct_visible_label(self):
        node = manifest(package="com.newman.newmanapp.beta.dev", app_attrs='android:debuggable="true"', inside=GUARD)
        self.assertFalse(verify_manifest(node, "debug"))
        for label in ("New Man Beta", "", "@string/unresolved"):
            node.find("application").set("{http://schemas.android.com/apk/res/android}label", label)
            self.assertIn("Expected application label", verify_manifest(node, "debug")[0])

    def test_release_label_is_unchanged(self):
        self.assertFalse(verify_manifest(manifest(), "release"))
        self.assertTrue(verify_manifest(manifest(label="New Man Dev"), "release"))

    def test_launcher_component_may_inherit_but_not_override_identity(self):
        for kind in ("activity", "activity-alias"):
            launcher = f'<{kind} android:name="example.Launcher"><intent-filter><action android:name="android.intent.action.MAIN"/><category android:name="android.intent.category.LAUNCHER"/></intent-filter></{kind}>'
            self.assertFalse(verify_manifest(manifest(inside=launcher), "release"))
            wrong = launcher.replace('android:name="example.Launcher"', 'android:name="example.Launcher" android:label="New Man Dev"')
            self.assertTrue(verify_manifest(manifest(inside=wrong), "release"))

    def test_release_manifest_accepts_clean_beta_identity(self):
        self.assertEqual(verify_manifest(manifest(), "release"), [])

    def test_release_rejects_test_only_and_shell_profiling(self):
        self.assertTrue(verify_manifest(manifest(app_attrs='android:testOnly="true"'), "release"))
        self.assertTrue(verify_manifest(manifest(inside='<profileable android:shell="true"/>'), "release"))
        self.assertFalse(verify_manifest(manifest(inside='<profileable android:shell="false"/>'), "release"))

    def test_release_manifest_fails_for_service_even_when_not_exported(self):
        self.assertIn("unqualified accessibility", verify_manifest(manifest(inside=GUARD), "release")[0])

    def test_release_manifest_fails_for_unknown_accessibility_service_action(self):
        node = (
            '<service android:name="example.Other"><intent-filter>'
            '<action android:name="android.accessibilityservice.AccessibilityService"/>'
            '</intent-filter></service>'
        )
        self.assertEqual(len(verify_manifest(manifest(inside=node), "release")), 1)

    def test_debug_must_have_separate_id_and_protected_service(self):
        attrs = 'android:debuggable="true"'
        self.assertEqual(
            verify_manifest(manifest(package="com.newman.newmanapp.beta.dev", app_attrs=attrs, inside=GUARD), "debug"),
            [],
        )
        self.assertIn("Expected app ID", verify_manifest(manifest(app_attrs=attrs, inside=GUARD), "debug")[0])
        self.assertIn(
            "non-exported", verify_manifest(
                manifest(package="com.newman.newmanapp.beta.dev", app_attrs=attrs, inside=GUARD.replace('"false"', '"true"')),
                "debug",
            )[0],
        )

    def test_release_rejects_debuggable_and_backup_enabled(self):
        doc = manifest(app_attrs='android:debuggable="true"')
        doc.find("application").set("{http://schemas.android.com/apk/res/android}allowBackup", "true")
        self.assertEqual(len(verify_manifest(doc, "release")), 2)


if __name__ == "__main__":
    unittest.main()
