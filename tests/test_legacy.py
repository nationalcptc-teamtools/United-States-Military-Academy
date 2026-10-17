"""Synthetic regression checks; no scanner is launched."""
import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import runpy
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]


def load(name):
    spec = importlib.util.spec_from_file_location('cptc_test_' + name, ROOT / (name + '.py'))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class LegacyTests(unittest.TestCase):
    def test_retired_modes_never_dispatch_or_mutate_config(self):
        legacy = load('super_nmap')
        with tempfile.TemporaryDirectory() as directory:
            config = Path(directory) / 'config.json'
            original = b'{"ranges":["192.0.2.0/24"],"hosts":["192.0.2.1"]}\n'
            config.write_bytes(original)
            with mock.patch('subprocess.Popen', side_effect=AssertionError('dispatch')), \
                 mock.patch('subprocess.run', side_effect=AssertionError('dispatch')), \
                 mock.patch('builtins.input', side_effect=AssertionError('prompt')):
                for mode in ('ping', 'port', 'fast', 'full', 'udp', 'custom', 'vulscan'):
                    with self.subTest(mode=mode), contextlib.redirect_stderr(io.StringIO()) as stderr:
                        self.assertEqual(legacy.main(['-s', mode, '-C', str(config),
                                                      '-H', '-o', directory, '-c=--reason']), 2)
                        self.assertIn('retired', stderr.getvalue())
                        self.assertIn('not translated', stderr.getvalue())
                self.assertEqual(config.read_bytes(), original)
                self.assertEqual([p.name for p in Path(directory).iterdir()], ['config.json'])

    def test_retired_entrypoint_does_not_read_configuration(self):
        legacy = load('super_nmap')
        with mock.patch('builtins.open', side_effect=AssertionError('config read')), \
             mock.patch.object(Path, 'open', side_effect=AssertionError('config read')), \
             contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(legacy.main(['-C', 'missing-scope.json']), 2)

    def test_actual_script_entrypoint_refuses_without_prompt_or_process(self):
        with mock.patch('sys.argv', ['super_nmap.py']), \
             mock.patch('builtins.input', side_effect=AssertionError('prompt')), \
             mock.patch('subprocess.Popen', side_effect=AssertionError('dispatch')), \
             mock.patch('subprocess.run', side_effect=AssertionError('dispatch')), \
             contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit) as exit_info:
            runpy.run_path(str(ROOT / 'super_nmap.py'), run_name='__main__')
        self.assertEqual(exit_info.exception.code, 2)

    def test_help_and_unknown_options_are_nonexecuting(self):
        legacy = load('super_nmap')
        with contextlib.redirect_stdout(io.StringIO()) as stdout, self.assertRaises(SystemExit) as info:
            legacy.main(['--help'])
        self.assertEqual(info.exception.code, 0)
        self.assertIn('cptc-windows.ps1', stdout.getvalue())
        with contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit) as info:
            legacy.main(['--unknown-target', '192.0.2.1'])
        self.assertEqual(info.exception.code, 2)

    def test_explicit_home_configuration_expands(self):
        config = load('config')
        with tempfile.TemporaryDirectory() as directory:
            expected = {'ranges': ['192.0.2.0/24'], 'hosts': []}
            path = Path(directory) / 'selected.json'
            path.write_text(json.dumps(expected), encoding='utf-8')
            with mock.patch.dict(os.environ, {'HOME': directory, 'USERPROFILE': directory}), \
                 mock.patch.object(config, 'prompt_config', side_effect=AssertionError('prompt')):
                self.assertEqual(config.read_config('~/selected.json'), expected)

    def test_default_home_fallback_and_explicit_precedence(self):
        config = load('config')
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory) / 'home'
            home.mkdir()
            fallback = {'ranges': [], 'hosts': ['fallback.example']}
            (home / '.config.json').write_text(json.dumps(fallback), encoding='utf-8')
            explicit = Path(directory) / 'chosen.json'
            expected = {'ranges': [], 'hosts': ['chosen.example']}
            explicit.write_text(json.dumps(expected), encoding='utf-8')
            cwd = os.getcwd()
            try:
                os.chdir(directory)
                with mock.patch.dict(os.environ, {'HOME': str(home), 'USERPROFILE': str(home)}), \
                     mock.patch.object(config, 'prompt_config', side_effect=AssertionError('prompt')):
                    self.assertEqual(config.read_config(), fallback)
                    self.assertEqual(config.read_config(explicit), expected)
            finally:
                os.chdir(cwd)

    def test_missing_explicit_config_never_falls_back_or_prompts(self):
        config = load('config')
        with tempfile.TemporaryDirectory() as directory:
            (Path(directory) / '.config.json').write_text('{}', encoding='utf-8')
            with mock.patch.dict(os.environ, {'HOME': directory, 'USERPROFILE': directory}), \
                 mock.patch.object(config, 'prompt_config', side_effect=AssertionError('prompt')), \
                 self.assertRaises(FileNotFoundError):
                config.read_config(Path(directory) / 'missing.json')

    def test_default_interactive_creation_stays_compatible(self):
        config = load('config')
        expected = {'ranges': [], 'hosts': []}
        with mock.patch.object(Path, 'open', side_effect=FileNotFoundError), \
             mock.patch.object(config, 'prompt_config', return_value=expected) as prompt, \
             mock.patch.object(config, 'write_config') as write, \
             contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(config.read_config(), expected)
        prompt.assert_called_once_with()
        write.assert_called_once_with(expected)


    def test_audit_wizard_rejects_invalid_ranges_before_host_checks(self):
        config = load('config')
        with mock.patch('builtins.input', side_effect=['bad-cidr', '192.0.2.0/24', '192.0.2.1']), contextlib.redirect_stdout(io.StringIO()):
            result = config.prompt_config()
        self.assertEqual(result, {'ranges': ['192.0.2.0/24'], 'hosts': ['192.0.2.1']})

    def test_audit_wizard_rejects_malformed_hosts_without_dns(self):
        config = load('config')
        with mock.patch('builtins.input', side_effect=['192.0.2.0/24', '--script=unexpected', '192.0.2.1']), \
             mock.patch('socket.getaddrinfo', side_effect=AssertionError('DNS')), contextlib.redirect_stdout(io.StringIO()):
            result = config.prompt_config()
        self.assertEqual(result['hosts'], ['192.0.2.1'])

    def test_audit_configuration_write_expands_home(self):
        config = load('config')
        with tempfile.TemporaryDirectory() as directory:
            with mock.patch.dict(os.environ, {'HOME': directory, 'USERPROFILE': directory}), \
                 mock.patch('builtins.input', return_value='~/scope.json'):
                config.write_config({'ranges': ['192.0.2.0/24'], 'hosts': []})
            self.assertEqual(json.loads((Path(directory) / 'scope.json').read_text()),
                             {'ranges': ['192.0.2.0/24'], 'hosts': []})

    def test_audit_invalid_config_never_overwrites_selected_file(self):
        config = load('config')
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'scope.json'
            original = b'{"ranges":[],"hosts":[]}'
            path.write_bytes(original)
            for data in ({'ranges': ['bad-cidr'], 'hosts': []}, {'ranges': [], 'hosts': ['--option']},
                         {'ranges': [], 'hosts': ['192.168.1']}, {'ranges': [], 'hosts': ['0x7f.0.0.1']},
                         {'ranges': [], 'hosts': ['app.example..']}, {'ranges': [], 'hosts': ['app.example...']},
                         {'ranges': ['192.0.2.0/24'], 'hosts': ['198.51.100.1']},
                         {'ranges': ['192.0.2.1/24'], 'hosts': []}, {'ranges': ['0.0.0.0/0'], 'hosts': []}):
                with self.subTest(data=data), mock.patch('builtins.input', return_value=str(path)), self.assertRaises(ValueError):
                    config.write_config(data)
                self.assertEqual(path.read_bytes(), original)

    def test_audit_read_validates_existing_config_without_rewriting(self):
        config = load('config')
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'scope.json'
            path.write_text('{"ranges":["bad-cidr"],"hosts":[]}', encoding='utf-8')
            before = path.read_bytes()
            with self.assertRaises(ValueError):
                config.read_config(path)
            self.assertEqual(path.read_bytes(), before)
        self.assertEqual(config.validate_config({'ranges': [], 'hosts': ['192.0.2.1', 'app.example']}),
                         {'ranges': [], 'hosts': ['192.0.2.1', 'app.example']})
        self.assertEqual(config.validate_config({'ranges': [], 'hosts': ['app.example.']}),
                         {'ranges': [], 'hosts': ['app.example.']})

if __name__ == '__main__':
    unittest.main()
