"""Unit tests for the New Man Android candidate guardrail."""
import unittest
from xml.etree import ElementTree

from check_android_candidate import verify_manifest


def manifest(package="com.newman.newmanapp.beta", app_attrs="", inside=""):
    return ElementTree.fromstring(
        f'<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="{package}">'
        f'<application android:allowBackup="false" {app_attrs}>{inside}</application></manifest>'
    )


GUARD = (
    '<service android:name="com.newman.newmanapp.GuardAccessibilityService" '
    'android:exported="false" android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE"/>'
)


class ManifestTests(unittest.TestCase):
    def test_release_manifest_accepts_clean_beta_identity(self):
        self.assertEqual(verify_manifest(manifest(), "release"), [])

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
