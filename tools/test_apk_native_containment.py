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
