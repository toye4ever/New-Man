#!/usr/bin/env python3
"""Require pinned Android packages already present on the CI runner.

This checker does not install SDK packages, accept licenses, or access the network.
"""
import argparse
from pathlib import Path
import sys

NDK_VERSION = "28.2.13676358"
BUILD_TOOLS = "36.0.0"
PLATFORM = "android-36"


def verify_sdk(root: Path, host_tag: str = "darwin-x86_64") -> list[str]:
    if host_tag not in {"darwin-x86_64", "linux-x86_64"}:
        return [f"Unsupported NDK host tag: {host_tag!r}."]
    required = [
        root / "platforms" / PLATFORM / "android.jar",
        root / "build-tools" / BUILD_TOOLS / "aapt2",
        root / "build-tools" / BUILD_TOOLS / "zipalign",
        root / "platform-tools" / "adb",
        root / "cmdline-tools" / "latest" / "bin" / "apkanalyzer",
        root / "ndk" / NDK_VERSION / "toolchains" / "llvm" / "prebuilt" / host_tag / "bin" / "clang",
        root / "ndk" / NDK_VERSION / "source.properties",
    ]
    failures = [f"Missing preinstalled SDK file: {path}" for path in required if not path.is_file()]
    properties = root / "ndk" / NDK_VERSION / "source.properties"
    if properties.is_file():
        try:
            entries = dict(
                line.split("=", 1) for line in properties.read_text(encoding="utf-8").splitlines()
                if "=" in line and not line.lstrip().startswith("#")
            )
            revision = {key.strip(): value.strip() for key, value in entries.items()}.get("Pkg.Revision")
            if revision != NDK_VERSION:
                failures.append(f"Expected NDK {NDK_VERSION}; found {revision!r}.")
        except (OSError, UnicodeError) as error:
            failures.append(f"Cannot read preinstalled NDK metadata: {error}")
    return failures


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("sdk_root", type=Path)
    parser.add_argument("--host-tag", choices=("darwin-x86_64", "linux-x86_64"), default="darwin-x86_64")
    opts = parser.parse_args()
    failures = verify_sdk(opts.sdk_root, opts.host_tag)
    if failures:
        print("\n".join(failures), file=sys.stderr)
        print("Required packages must already be installed; no SDK installation was attempted.", file=sys.stderr)
        return 1
    print(f"Preinstalled SDK paths verified: {PLATFORM}, build-tools {BUILD_TOOLS}, NDK {NDK_VERSION} ({opts.host_tag}).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
