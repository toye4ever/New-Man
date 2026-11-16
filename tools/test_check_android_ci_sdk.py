"""Bounded preflight tests using synthetic package paths, without network calls."""
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest

from check_android_ci_sdk import BUILD_TOOLS, NDK_VERSION, PLATFORM, verify_sdk


class PreinstalledSdkTests(unittest.TestCase):
    def setUp(self):
        self.temporary = TemporaryDirectory(prefix="newman-sdk-preflight-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.files = [
            f"platforms/{PLATFORM}/android.jar",
            f"build-tools/{BUILD_TOOLS}/aapt2",
            f"build-tools/{BUILD_TOOLS}/zipalign",
            "platform-tools/adb",
            "cmdline-tools/latest/bin/apkanalyzer",
            f"ndk/{NDK_VERSION}/toolchains/llvm/prebuilt/darwin-x86_64/bin/clang",
            f"ndk/{NDK_VERSION}/source.properties",
        ]

    def populate(self):
        for name in self.files:
            target = self.root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.touch()
        (self.root / self.files[-1]).write_text(f"Pkg.Revision = {NDK_VERSION}\n", encoding="utf-8")

    def test_empty_sdk_lists_missing_requirements_without_mutation(self):
        self.assertEqual(len(verify_sdk(self.root)), len(self.files))
        self.assertEqual(list(self.root.iterdir()), [])

    def test_expected_preinstalled_packages_pass(self):
        self.populate()
        self.assertEqual(verify_sdk(self.root), [])

    def test_linux_toolchain_cannot_pass_macos_preflight(self):
        self.populate()
        prebuilt = self.root / f"ndk/{NDK_VERSION}/toolchains/llvm/prebuilt"
        (prebuilt / "darwin-x86_64").rename(prebuilt / "linux-x86_64")
        self.assertIn("darwin-x86_64", verify_sdk(self.root)[0])
        self.assertEqual(verify_sdk(self.root, "linux-x86_64"), [])

    def test_unknown_host_tag_fails_closed(self):
        self.assertIn("Unsupported NDK host", verify_sdk(self.root, "../unexpected")[0])

    def test_ndk_cannot_be_substituted(self):
        self.populate()
        (self.root / self.files[-1]).write_text("Pkg.Revision = 27.3.13750724\n", encoding="utf-8")
        self.assertIn("Expected NDK", verify_sdk(self.root)[0])

    def test_build_tools_cannot_be_silently_omitted(self):
        self.populate()
        (self.root / f"build-tools/{BUILD_TOOLS}/aapt2").unlink()
        self.assertIn("aapt2", verify_sdk(self.root)[0])

    def test_malformed_ndk_metadata_fails_closed(self):
        self.populate()
        (self.root / self.files[-1]).write_bytes(b"\xff")
        self.assertIn("Cannot read", verify_sdk(self.root)[0])


if __name__ == "__main__":
    unittest.main()
