"""Portable C-preprocessor checks, not Windows resource/link/runtime evidence."""
import pathlib
import re
import shutil
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
CPP = shutil.which('cpp') or ('/usr/bin/cpp' if pathlib.Path('/usr/bin/cpp').exists() else None)


@unittest.skipUnless(CPP, 'Portable resource checks require an existing C preprocessor')
class WindowsIdentityTests(unittest.TestCase):
    def preprocess(self, debug=False, header_only=False):
        with tempfile.TemporaryDirectory() as temporary:
            stub = pathlib.Path(temporary)
            # Only preprocess resource tokens; no Windows SDK headers/compiler.
            (stub / 'winres.h').write_text('')
            command = [CPP, '-P', '-x', 'c', '-I', str(stub), '-I', str(ROOT / 'windows/runner')]
            if debug:
                command += ['-D_DEBUG']
            if header_only:
                return subprocess.check_output(command + ['-'], input='#include "runner_identity.h"\nNEW_MAN_WINDOW_TITLE\n', text=True)
            return subprocess.check_output(command + [str(ROOT / 'windows/runner/Runner.rc')], text=True)

    def values(self, debug=False):
        return dict(re.findall(r'VALUE "([^\"]+)", "([^\"]*)" "\\0"', self.preprocess(debug)))

    def test_release_and_profile_keep_historical_identity(self):
        # Profile has no _DEBUG: existing CMake copies Release flags for Profile.
        values = self.values()
        self.assertEqual(values['CompanyName'], 'com.example')
        self.assertEqual(values['ProductName'], 'New Man')
        self.assertEqual(values['FileDescription'], 'New Man')
        self.assertEqual(values['InternalName'], 'scripture_planner')
        self.assertEqual(values['OriginalFilename'], 'scripture_planner.exe')
        self.assertIn('L"New Man"', self.preprocess(header_only=True))

    def test_debug_has_distinct_support_identity_and_visible_title(self):
        debug = self.values(True)
        release = self.values()
        self.assertEqual(debug['CompanyName'], release['CompanyName'])
        self.assertEqual(debug['ProductName'], 'New Man Dev')
        self.assertEqual(debug['FileDescription'], 'New Man Dev')
        self.assertEqual({k: v for k, v in debug.items() if k not in ('ProductName', 'FileDescription')},
                         {k: v for k, v in release.items() if k not in ('ProductName', 'FileDescription')})
        self.assertIn('L"New Man Dev"', self.preprocess(True, header_only=True))
        self.assertNotEqual(pathlib.PureWindowsPath('com.example', debug['ProductName']),
                            pathlib.PureWindowsPath('com.example', release['ProductName']))

    def test_existing_build_wires_debug_define_to_runner_only_in_debug(self):
        settings = (ROOT / 'windows/CMakeLists.txt').read_text()
        self.assertIn('"$<$<CONFIG:Debug>:_DEBUG>"', settings)
        self.assertIn('CMAKE_CXX_FLAGS_PROFILE "${CMAKE_CXX_FLAGS_RELEASE}"', settings)
        self.assertIn('apply_standard_settings(${BINARY_NAME})', (ROOT / 'windows/runner/CMakeLists.txt').read_text())
        self.assertIn('window.Create(NEW_MAN_WINDOW_TITLE,', (ROOT / 'windows/runner/main.cpp').read_text())
