import hashlib
import json
from pathlib import Path
import re
import subprocess

root = Path(__file__).resolve().parents[1]
repo = root/'integrations/United-States-Military-Academy'
manifest = json.loads((root/'output/workbench/release-1.0.0-settled/MANIFEST.json').read_text())
expected = {name for name in manifest['files'] if name.startswith('tooling/workbench/')}
expected |= {'tooling/reporting/reportgen.py', 'tooling/reporting/README.md'}
staged = set(subprocess.check_output(['git','diff','--cached','--name-only'],cwd=repo,text=True).splitlines())
assert staged == expected | {'README.md','tooling/workbench/SPEC.md','tooling/workbench/VERIFICATION.md'}, staged
for name in expected:
    raw = subprocess.check_output(['git','show',':'+name],cwd=repo)
    assert hashlib.sha256(raw).hexdigest() == manifest['files'][name], name
spec = (repo/'tooling/workbench/SPEC.md').read_text(encoding='utf-8')
scope_rows = re.findall(r'^\| (IDEA-DF-\d{3}) \| (Include|Defer|Exclude) \|',spec,re.M)
assert len(scope_rows) == len(dict(scope_rows)) == 120
assert len(re.findall(r'^\| (?:FR|NFR)-DF-\d{3} \|',spec,re.M)) == 44
for name in ('cptc-linux.sh','cptc-windows.ps1','install.sh'):
    assert subprocess.check_output(['git','diff','--cached','--',name],cwd=repo) == b''
result = {'staged_files':sorted(staged),'exact_reviewed_files':len(expected),
          'private_or_generated_files':False,'all120_choices_preserved':True,'all44_requirements_preserved':True,
          'existing_runners_installer_preserved':True}
(root/'tmp/workbench-publication-audit.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2))
