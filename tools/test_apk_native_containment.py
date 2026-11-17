"""Synthetic ZIP/ELF header fixtures only; no provider or device operations."""
import pathlib
import struct
import tempfile
import unittest
import zipfile
from xml.etree import ElementTree
from check_android_candidate import verify_native_libraries, verify_manifest
from test_check_android_candidate import manifest, GUARD


def elf(machine=183, word_class=2):
    data = bytearray(64)
    data[:7] = b'\x7fELF' + bytes([word_class, 1, 1])
    struct.pack_into('<HHI', data, 16, 3, machine, 1)
    struct.pack_into('<H', data, 52, 64)
    return data


class NativeContainmentTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.apk = pathlib.Path(self.temp.name) / 'synthetic.apk'

    def write(self, libraries):
        with zipfile.ZipFile(self.apk, 'w') as output:
            for name, data in libraries:
                output.writestr(name, data)

    def test_arm64_debug_jit_and_release_aot(self):
        self.write([('lib/arm64-v8a/libflutter.so', elf())])
        self.assertFalse(verify_native_libraries(self.apk, 'debug'))
        self.assertTrue(verify_native_libraries(self.apk, 'release'))
        self.write([(f'lib/arm64-v8a/{name}.so', elf()) for name in ('libflutter', 'libapp', 'libsqlite3')])
        self.assertFalse(verify_native_libraries(self.apk, 'release'))

    def test_reject_missing_engine_wrong_abi_and_hidden_native_assets(self):
        for extra in ('lib/x86_64/libother.so', 'assets/libother.so', 'lib/arm64-v8a/../libother.so'):
            self.write([('lib/arm64-v8a/libflutter.so', elf()), (extra, elf())])
            self.assertTrue(verify_native_libraries(self.apk, 'debug'))
        self.write([])
        self.assertTrue(verify_native_libraries(self.apk, 'debug'))

    def test_observed_fat_apk_dependency_extras_require_explicit_split(self):
        # Run 43978763332: ARM64 Flutter code plus non-target dependency ABIs.
        primary = [(f'lib/arm64-v8a/{name}.so', elf()) for name in ('libflutter', 'libapp', 'libdartjni', 'libdatastore_shared_counter')]
        extras = [
            (f'lib/{abi}/{name}.so', elf(machine=machine, word_class=word_class))
            for abi, machine, word_class in [('armeabi-v7a', 40, 1), ('x86_64', 62, 2)]
            for name in ('libdartjni', 'libdatastore_shared_counter')
        ]
        for variant in ('debug', 'release'):
            self.write(primary + extras)
            failures = verify_native_libraries(self.apk, variant)
            self.assertEqual(len(failures), 4)
            for path, _ in extras:
                self.assertTrue(any(path in failure for failure in failures))
            # Expected split layout keeps the ARM64 copies and removes extras.
            self.write(primary)
            self.assertFalse(verify_native_libraries(self.apk, variant))

    def test_header_rejects_wrong_machine_class_and_truncation(self):
        for data in (elf(machine=62), elf(word_class=1), b'not ELF', elf()[:32]):
            self.write([('lib/arm64-v8a/libflutter.so', data)])
            self.assertTrue(verify_native_libraries(self.apk, 'debug'))

    def test_duplicate_library_entries_rejected(self):
        import warnings
        with warnings.catch_warnings():
            warnings.simplefilter('ignore', UserWarning)
            self.write([('lib/arm64-v8a/libflutter.so', elf())] * 2)
        self.assertIn('Duplicate', verify_native_libraries(self.apk, 'debug')[0])

    def test_reminder_permission_and_receiver_remain_dormant(self):
        for variant in ('debug', 'release'):
            def root():
                return manifest(package='com.newman.newmanapp.beta.dev' if variant == 'debug' else 'com.newman.newmanapp.beta',
                                app_attrs='android:debuggable="true"' if variant == 'debug' else '',
                                inside=GUARD if variant == 'debug' else '')
            self.assertFalse(verify_manifest(root(), variant))
            for permission in ('POST_NOTIFICATIONS', 'SCHEDULE_EXACT_ALARM', 'USE_EXACT_ALARM'):
                for tag in ('uses-permission', 'uses-permission-sdk-23'):
                    node = root()
                    ElementTree.SubElement(node, tag, {'{http://schemas.android.com/apk/res/android}name': 'android.permission.' + permission})
                    self.assertTrue(verify_manifest(node, variant))
            for name in ('.TaskReminderAlarmReceiver', 'com.newman.newmanapp.TaskReminderSystemReceiver'):
                node = root()
                ElementTree.SubElement(node.find('application'), 'receiver', {'{http://schemas.android.com/apk/res/android}name': name})
                self.assertTrue(verify_manifest(node, variant))
            node = root()
            receiver = ElementTree.SubElement(node.find('application'), 'receiver', {'{http://schemas.android.com/apk/res/android}name': 'example.UnexpectedReceiver'})
            intent = ElementTree.SubElement(receiver, 'intent-filter')
            ElementTree.SubElement(intent, 'action', {'{http://schemas.android.com/apk/res/android}name': 'com.newman.newmanapp.TASK_REMINDER_V1'})
            self.assertTrue(verify_manifest(node, variant))


class PageAlignmentTests(unittest.TestCase):
    """Known structural fixtures, not executable native code or a runtime claim."""
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.apk = pathlib.Path(self.temp.name) / 'synthetic with spaces.apk'

    def elf_load(self, alignment=0x4000, **changes):
        data = bytearray(120)
        data[:64] = elf()
        struct.pack_into('<Q', data, 32, changes.get('phoff', 64))
        struct.pack_into('<HH', data, 54, changes.get('phsize', 56), changes.get('phnum', 1))
        struct.pack_into('<IIQQQQQQ', data, 64, changes.get('kind', 1), 5,
                         changes.get('offset', 0), changes.get('address', 0), 0,
                         changes.get('filesz', 120), changes.get('memsz', 120), alignment)
        return data

    def write(self, payload=None, aligned=True, compressed=False):
        name = 'lib/arm64-v8a/libflutter.so'
        entry = zipfile.ZipInfo(name)
        entry.compress_type = zipfile.ZIP_DEFLATED if compressed else zipfile.ZIP_STORED
        if aligned:
            padding = (-(30 + len(name.encode()) + 4)) % 16384
            entry.extra = struct.pack('<HH', 0xcafe, padding) + bytes(padding)
        with zipfile.ZipFile(self.apk, 'w') as archive:
            archive.writestr(entry, self.elf_load() if payload is None else payload)

    def test_positive_16k_and_larger_elf_alignment(self):
        from check_android_candidate import verify_page_alignment
        for alignment in (0x4000, 0x10000):
            self.write(self.elf_load(alignment))
            self.assertEqual(verify_page_alignment(self.apk), [])

    def test_4k_load_is_independent_of_aligned_zip(self):
        from check_android_candidate import verify_page_alignment
        self.write(self.elf_load(0x1000))
        failures = verify_page_alignment(self.apk)
        self.assertEqual(len(failures), 1)
        self.assertIn('libflutter.so: PT_LOAD[0] p_align=0x1000', failures[0])

    def test_zip_data_offset_is_independent_of_16k_load(self):
        from check_android_candidate import verify_page_alignment
        self.write(aligned=False)
        failures = verify_page_alignment(self.apk)
        self.assertEqual(len(failures), 1)
        self.assertIn('libflutter.so: stored ZIP data offset', failures[0])

    def test_compressed_library_still_requires_elf_alignment(self):
        from check_android_candidate import verify_page_alignment
        self.write(compressed=True, aligned=False)
        self.assertEqual(verify_page_alignment(self.apk), [])
        self.write(self.elf_load(0x1000), compressed=True, aligned=False)
        self.assertIn('PT_LOAD', verify_page_alignment(self.apk)[0])

    def test_malformed_headers_tables_and_loads_fail_closed(self):
        from check_android_candidate import verify_page_alignment
        for payload in (b'not ELF', self.elf_load(phnum=0), self.elf_load(phnum=1025),
                        self.elf_load(phoff=1048577), self.elf_load(phoff=120),
                        self.elf_load(phsize=55), self.elf_load(kind=2),
                        self.elf_load(0), self.elf_load(0x6000),
                        self.elf_load(address=1)):
            self.write(payload)
            self.assertTrue(verify_page_alignment(self.apk))

    def test_no_native_library_is_not_an_alignment_pass(self):
        from check_android_candidate import verify_page_alignment
        with zipfile.ZipFile(self.apk, 'w'):
            pass
        self.assertIn('No native libraries', verify_page_alignment(self.apk)[0])

    def test_zipalign_exact_readonly_invocation_and_failure(self):
        from unittest.mock import patch
        import subprocess
        from check_android_candidate import verify_zipalign
        self.write()
        tool = '/trusted SDK/build-tools/36.0.0/zipalign'
        with patch('check_android_candidate.subprocess.run') as run:
            run.return_value = subprocess.CompletedProcess([], 0, 'Verification successful', '')
            self.assertEqual(verify_zipalign(self.apk, tool), [])
            run.assert_called_once_with(
                [tool, '-c', '-P', '16', '-v', '4', str(self.apk.resolve())],
                check=False, capture_output=True, text=True, encoding='utf-8', timeout=60)
            run.return_value = subprocess.CompletedProcess([], 1, 'libflutter.so BAD', '')
            self.assertIn('libflutter.so BAD', verify_zipalign(self.apk, tool)[0])
        for error in (FileNotFoundError('missing tool'), subprocess.TimeoutExpired('zipalign', 60)):
            with patch('check_android_candidate.subprocess.run', side_effect=error):
                self.assertIn('NOT verified', verify_zipalign(self.apk, tool)[0])

    def test_cli_cannot_report_missing_or_failed_alignment_as_passed(self):
        import contextlib
        import io
        import subprocess
        from unittest.mock import patch
        from check_android_candidate import main
        node = manifest(package='com.newman.newmanapp.beta.dev',
                        app_attrs='android:debuggable="true"', inside=GUARD)
        manifest_result = subprocess.CompletedProcess([], 0, ElementTree.tostring(node, encoding='unicode'), '')
        for alignment, tool_result, expected in [
            (0x4000, subprocess.CompletedProcess([], 0, 'Verification successful', ''), 0),
            (0x1000, subprocess.CompletedProcess([], 0, 'Verification successful', ''), 1),
            (0x4000, subprocess.CompletedProcess([], 1, 'libflutter.so BAD', ''), 1),
            (0x4000, FileNotFoundError('missing pinned zipalign'), 1),
        ]:
            self.write(self.elf_load(alignment))
            output, error = io.StringIO(), io.StringIO()
            with patch('sys.argv', ['checker', 'debug', str(self.apk), '--apkanalyzer', '/trusted/apkanalyzer', '--zipalign', '/trusted/zipalign']), patch('check_android_candidate.subprocess.run', side_effect=[manifest_result, tool_result]), contextlib.redirect_stdout(output), contextlib.redirect_stderr(error):
                self.assertEqual(main(), expected)
            if expected:
                self.assertEqual(output.getvalue(), '')
                self.assertTrue(error.getvalue())
            else:
                self.assertIn('16 KiB alignment verified', output.getvalue())
