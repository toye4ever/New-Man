import copy
import unittest
from check_windows_exe_identity import verify


def fixture():
    release = {'company': 'com.example', 'product': 'New Man', 'description': 'New Man',
               'internalName': 'scripture_planner', 'originalFilename': 'scripture_planner.exe',
               'fileVersion': '0.2.3-beta.1', 'productVersion': '0.2.3-beta.1', 'debug': False}
    debug = dict(release, product='New Man Dev', description='New Man Dev', debug=True)
    return {'debug': debug, 'release': release}


class CompiledIdentityTests(unittest.TestCase):
    def test_expected_compiled_records(self):
        self.assertTrue(verify(fixture()))

    def test_shared_debug_identity_is_rejected(self):
        value = fixture()
        value['debug']['product'] = 'New Man'
        with self.assertRaises(ValueError): verify(value)

    def test_release_identity_and_flags_are_preserved(self):
        for variant, field, bad in [('release', 'company', 'changed'), ('release', 'product', 'New Man Dev'),
                                    ('release', 'debug', True), ('debug', 'debug', 'true'),
                                    ('debug', 'description', 'New Man'), ('release', 'originalFilename', 'other.exe')]:
            value = fixture(); value[variant][field] = bad
            with self.assertRaises(ValueError): verify(value)

    def test_missing_and_inconsistent_versions_rejected(self):
        for field in ('fileVersion', 'productVersion'):
            for bad in ('', None, 'different'):
                value = fixture(); value['debug'][field] = bad
                with self.assertRaises(ValueError): verify(value)
        for bad in ({}, {'debug': {}}, [], {'debug': None, 'release': None}):
            with self.assertRaises(ValueError): verify(copy.deepcopy(bad))
