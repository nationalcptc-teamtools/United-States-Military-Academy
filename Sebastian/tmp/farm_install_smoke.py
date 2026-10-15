"""Disposable container only: actual installed-state regression checks."""
import contextlib
import copy
import io
import json
import os
import sys
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, '/work/tooling/farmkit')
import install as suite
prefix = Path('/opt/cptc-suite')
data = suite.manifest()
state_path = prefix / 'install-state.json'
original = state_path.read_bytes()
state = json.loads(original)
results = []

def check():
    with contextlib.redirect_stdout(io.StringIO()):
        return suite.check(prefix, data, 'full')

def rejected(label, action, restore):
    try:
        action()
        try:
            check()
        except (suite.InstallError, OSError):
            results.append(label)
        else:
            raise AssertionError('accepted: ' + label)
    finally:
        restore()

check()
results.append('disconnected unchanged installation accepted')
for field in ('apt_packages', 'native', 'python_groups'):
    changed = copy.deepcopy(state)
    changed[field] = [] if field == 'apt_packages' else {}
    rejected('missing ' + field, lambda changed=changed: state_path.write_text(json.dumps(changed)), lambda: state_path.write_bytes(original))

for label, path in [('native client', prefix/'bin/mbpoll'), ('native library', next(p for p in (prefix/'lib').rglob('*60870*') if p.is_file() and not p.is_symlink())), ('legacy source link', Path('/work/vulscan')), ('venv configuration', prefix/'venvs/ot/pyvenv.cfg')]:
    saved = path.with_name(path.name + '.smoke-backup')
    rejected('removed ' + label, lambda path=path,saved=saved: path.rename(saved), lambda path=path,saved=saved: saved.rename(path))

payload = prefix/'payloads/linpeas.sh'
payload_original = payload.read_bytes()
rejected('tampered PEASS bytes', lambda: payload.write_bytes(b'X'+payload_original[1:]), lambda: payload.write_bytes(payload_original))
src = prefix/'src/mbpoll/CMakeLists.txt'
src_original = src.read_bytes()
rejected('dirty pinned source', lambda: src.write_bytes(src_original+b'\n# smoke mutation\n'), lambda: src.write_bytes(src_original))

real_run = suite.run
def missing_package(argv, **kwargs):
    if argv[0] == 'dpkg-query':
        return '\n'.join(f'{p}\tconfig-files\t1' for p in data['profiles']['full']['apt'])
    return real_run(argv, **kwargs)
with patch.object(suite, 'run', side_effect=missing_package):
    try:
        check()
    except suite.InstallError:
        results.append('removed apt status')
    else:
        raise AssertionError('removed apt accepted')

bad_prefix = Path('/tmp/redirect-suite')
bad_prefix.mkdir()
binary_dir = bad_prefix/'bin'
try:
    binary_dir.symlink_to('/tmp', target_is_directory=True)
    with patch.object(suite, 'run', side_effect=AssertionError('command before rejection')):
        try:
            suite.install(data, 'full', bad_prefix, skip_system=True)
        except suite.InstallError:
            results.append('redirected bin rejected before commands')
        else:
            raise AssertionError('external bin accepted')
finally:
    binary_dir.unlink()
    bad_prefix.rmdir()
check()
results.append('restored installation accepted')
print(json.dumps({'checks':results,'count':len(results),'network':'none','python':sys.version.split()[0]}, indent=2))
