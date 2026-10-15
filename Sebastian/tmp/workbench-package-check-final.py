import hashlib
import json
from pathlib import Path
import subprocess
import sys
import zipfile

root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / 'tooling/workbench'))
import delivery

release = root / 'output/workbench/release-1.0.0-settled/workbench-1.0.0.zip'
manifest = delivery.inspect_package(release)
other = delivery.package(root / 'tmp/workbench-repeat-release-settled')
assert other['zip_sha256'] == hashlib.sha256(release.read_bytes()).hexdigest()
with zipfile.ZipFile(release) as archive:
    assert len(archive.namelist()) == 51
    assert all(not Path(name).is_absolute() and '..' not in Path(name).parts for name in archive.namelist())
    for name in archive.namelist():
        if name.endswith('.py'):
            compile(archive.read(name), name, 'exec')
    extracted = root / 'tmp/workbench-standalone-settled'
    assert not extracted.exists()
    archive.extractall(extracted)
result = subprocess.run([sys.executable, '-B', '-m', 'unittest', 'discover', '-s', 'tooling/workbench/tests', '-v'],
                        cwd=extracted, capture_output=True, text=True, encoding='utf-8')
record = {'data_category': 'synthetic', 'members': 51, 'all_member_hashes_verified': True,
          'all_python_members_compile': True, 'repeatable_zip': True, 'zip_sha256': other['zip_sha256'],
          'extracted_suite_exit': result.returncode, 'stdout': result.stdout, 'stderr': result.stderr,
          'source_manifest': manifest}
(root / 'output/workbench/package-verification-final.json').write_text(json.dumps(record, indent=2) + '\n', encoding='utf-8')
print(result.stderr)
print(json.dumps({k:v for k,v in record.items() if k not in ('stdout','stderr','source_manifest')}, indent=2))
raise SystemExit(result.returncode)

