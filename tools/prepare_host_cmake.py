"""Verify Kitware's pinned host archive before extracting into runner temp."""
import hashlib
import pathlib
import tarfile
import sys

ARCHIVE = 'cmake-3.22.1-macos-universal.tar.gz'
SHA256 = '9ba46ce69d524f5bcdf98076a6b01f727604fb31cf9005ec03dea1cf16da9514'
ROOT = 'cmake-3.22.1-macos-universal'


def prepare(archive, destination, expected=SHA256):
    archive, destination = pathlib.Path(archive), pathlib.Path(destination)
    if hashlib.sha256(archive.read_bytes()).hexdigest() != expected:
        raise ValueError('CMake archive SHA-256 mismatch')
    if destination.exists() and any(destination.iterdir()):
        raise ValueError('Refusing nonempty extraction destination')
    with tarfile.open(archive, 'r:gz') as contents:
        for member in contents.getmembers():
            path = pathlib.PurePosixPath(member.name)
            if path.is_absolute() or '..' in path.parts or not path.parts or path.parts[0] != ROOT:
                raise ValueError('Unexpected CMake archive path')
        destination.mkdir(parents=True, exist_ok=True)
        contents.extractall(destination, filter='data')
    root = destination / ROOT / 'CMake.app/Contents'
    for relative in ('bin/cmake', 'share/cmake-3.22/Modules/CMake.cmake'):
        if not (root / relative).is_file():
            raise ValueError('Incomplete CMake installation')
    return root.resolve()


def configure(properties, root):
    properties = pathlib.Path(properties)
    root = pathlib.Path(root).resolve()
    if not (root / 'bin/cmake').is_file():
        raise ValueError('CMake executable missing')
    lines = properties.read_text().splitlines() if properties.exists() else []
    lines = [line for line in lines if not line.lstrip().startswith(('cmake.dir=', 'cmake.dir:'))]
    value = str(root).replace('\\', '\\\\')
    properties.write_text('\n'.join(lines + ['cmake.dir=' + value]) + '\n')


if __name__ == '__main__':
    if len(sys.argv) == 4 and sys.argv[1] == '--configure':
        configure(sys.argv[2], sys.argv[3])
    elif len(sys.argv) == 3:
        print(prepare(sys.argv[1], sys.argv[2]))
    else:
        raise SystemExit('Usage: prepare_host_cmake.py ARCHIVE DEST | --configure local.properties CMAKE_ROOT')
