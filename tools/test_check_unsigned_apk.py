import pathlib
import struct
import tempfile
import unittest
import zipfile
from check_unsigned_apk import verify_unsigned


class UnsignedTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.apk = pathlib.Path(self.temp.name) / 'test.apk'

    def make(self, extra=None):
        with zipfile.ZipFile(self.apk, 'w') as archive:
            archive.writestr('AndroidManifest.xml', b'synthetic fixture')
            if extra:
                archive.writestr(extra, b'synthetic fixture')

    def test_unsigned(self):
        self.make()
        self.assertTrue(verify_unsigned(self.apk))

    def test_v1_material(self):
        for name in ['META-INF/CERT.RSA', 'META-INF/CERT.SF', 'meta-inf/test.ec', 'META-INF/SIG-CUSTOM']:
            self.make(name)
            with self.assertRaisesRegex(ValueError, 'JAR signing'):
                verify_unsigned(self.apk)

    def test_v2_v3_container(self):
        self.make()
        data = self.apk.read_bytes()
        end = data.rfind(b'PK\x05\x06')
        offset = struct.unpack_from('<I', data, end + 16)[0]
        block = struct.pack('<Q', 24) + struct.pack('<Q', 24) + b'APK Sig Block 42'
        data = bytearray(data[:offset] + block + data[offset:])
        struct.pack_into('<I', data, end + len(block) + 16, offset + len(block))
        self.apk.write_bytes(data)
        with self.assertRaisesRegex(ValueError, 'APK signing block'):
            verify_unsigned(self.apk)

    def test_bad_or_missing_manifest(self):
        self.apk.write_bytes(b'not an apk')
        with self.assertRaises(ValueError):
            verify_unsigned(self.apk)
        with zipfile.ZipFile(self.apk, 'w') as archive:
            archive.writestr('unrelated', b'x')
        with self.assertRaisesRegex(ValueError, 'manifest missing'):
            verify_unsigned(self.apk)

    def test_trailing_bytes(self):
        self.make()
        self.apk.write_bytes(self.apk.read_bytes() + b'extra')
        with self.assertRaises(ValueError):
            verify_unsigned(self.apk)
