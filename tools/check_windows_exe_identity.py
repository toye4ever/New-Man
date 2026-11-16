"""Validate narrowly selected compiled VERSIONINFO, without running an EXE."""
import json
import pathlib
import sys


def verify(report):
    if not isinstance(report, dict) or set(report) != {'debug', 'release'}:
        raise ValueError('Expected debug and release identity records')
    for variant, product in [('debug', 'New Man Dev'), ('release', 'New Man')]:
        info = report[variant]
        expected = {'company': 'com.example', 'product': product, 'description': product,
                    'internalName': 'scripture_planner', 'originalFilename': 'scripture_planner.exe'}
        if not isinstance(info, dict):
            raise ValueError('Identity record missing')
        for field, value in expected.items():
            if info.get(field) != value:
                raise ValueError(f'{variant} {field} identity mismatch')
        if type(info.get('debug')) is not bool or info['debug'] != (variant == 'debug'):
            raise ValueError(f'{variant} compiled debug flag mismatch')
        for field in ('fileVersion', 'productVersion'):
            if not isinstance(info.get(field), str) or not info[field].strip():
                raise ValueError(f'{variant} version is missing')
    for field in ('fileVersion', 'productVersion'):
        if report['debug'][field] != report['release'][field]:
            raise ValueError('Debug/release versions differ')
    return True


if __name__ == '__main__':
    if len(sys.argv) != 2:
        raise SystemExit('Usage: check_windows_exe_identity.py REPORT.json')
    try:
        verify(json.loads(pathlib.Path(sys.argv[1]).read_text(encoding='utf-8-sig')))
    except (OSError, ValueError) as error:
        raise SystemExit(str(error))
    print('Compiled Debug/Release identities and versions verified; no app launch performed.')
