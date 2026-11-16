"""Fail closed if a conventional APK ZIP contains JAR/APK signing material."""
import pathlib
import re
import struct
import sys
import zipfile


def verify_unsigned(path):
    data = pathlib.Path(path).read_bytes()
    # Reject ZIP64, concatenated and ambiguous ZIP layouts rather than guess.
    eocd = data.rfind(b'PK\x05\x06', max(0, len(data) - 65557))
    if eocd < 0 or eocd + 22 > len(data):
        raise ValueError('Missing ZIP end record')
    _, disk, start_disk, disk_entries, entries, size, offset, comment = struct.unpack_from('<4s4H2IH', data, eocd)
    if disk or start_disk or disk_entries != entries or entries == 65535 or offset == 0xffffffff or size == 0xffffffff:
        raise ValueError('Unsupported APK ZIP layout')
    if eocd + 22 + comment != len(data) or offset + size != eocd:
        raise ValueError('Ambiguous APK ZIP layout')
    if data[max(0, offset - 16):offset] == b'APK Sig Block 42':
        raise ValueError('APK signing block present')
    with zipfile.ZipFile(path) as archive:
        if 'AndroidManifest.xml' not in archive.namelist():
            raise ValueError('APK manifest missing')
        for name in archive.namelist():
            if re.fullmatch(r'META-INF/(?:[^/]+\.(?:RSA|DSA|EC|SF)|SIG-[^/]+)', name, re.IGNORECASE):
                raise ValueError('JAR signing material present')
    return True


if __name__ == '__main__':
    if len(sys.argv) != 2:
        raise SystemExit('Usage: check_unsigned_apk.py APK')
    try:
        verify_unsigned(sys.argv[1])
    except (OSError, ValueError, zipfile.BadZipFile) as error:
        raise SystemExit(str(error))
    print('Unsigned APK container verified; not installable/release qualification.')
