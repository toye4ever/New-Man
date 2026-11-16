import hashlib
import io
import pathlib
import tarfile
import tempfile
import unittest
from prepare_host_cmake import prepare, configure, ROOT


class HostCmakeTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = pathlib.Path(self.temp.name)

    def archive(self, names):
        archive = self.root / 'fixture.tar.gz'
        with tarfile.open(archive, 'w:gz') as output:
            for name in names:
                member = tarfile.TarInfo(name)
                member.size = 1
                output.addfile(member, io.BytesIO(b'x'))
        return archive, hashlib.sha256(archive.read_bytes()).hexdigest()

    def test_layout_and_properties(self):
        archive, checksum = self.archive([ROOT + '/CMake.app/Contents/' + name for name in
            ('bin/cmake', 'share/cmake-3.22/Modules/CMake.cmake')])
        root = prepare(archive, self.root / 'with spaces', checksum)
        properties = self.root / 'local.properties'
        properties.write_text('sdk.dir=/sdk\nflutter.sdk=/flutter\ncmake.dir=/old\n')
        configure(properties, root)
        configure(properties, root)
        self.assertEqual(properties.read_text(), f'sdk.dir=/sdk\nflutter.sdk=/flutter\ncmake.dir={root}\n')
        with self.assertRaises(ValueError):
            prepare(archive, self.root / 'with spaces', checksum)

    def test_hash_before_extraction(self):
        archive, _ = self.archive([])
        destination = self.root / 'output'
        with self.assertRaises(ValueError):
            prepare(archive, destination)
        self.assertFalse(destination.exists())

    def test_traversal_rejected(self):
        archive, checksum = self.archive([ROOT + '/../escaped'])
        with self.assertRaises(ValueError):
            prepare(archive, self.root / 'output', checksum)
        self.assertFalse((self.root / 'escaped').exists())

    def test_incomplete_layout_rejected(self):
        archive, checksum = self.archive([ROOT + '/CMake.app/Contents/bin/cmake'])
        with self.assertRaises(ValueError):
            prepare(archive, self.root / 'output', checksum)


if __name__ == '__main__':
    unittest.main()
