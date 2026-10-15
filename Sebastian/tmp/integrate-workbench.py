"""Copy only reviewed reusable source into the clean team checkout."""
import hashlib
import json
from pathlib import Path
import shutil

root = Path(__file__).resolve().parents[1]
repo = root / 'integrations/United-States-Military-Academy'
manifest = json.loads((root/'output/workbench/release-1.0.0-settled/MANIFEST.json').read_text())
selected = [name for name in manifest['files'] if name.startswith('tooling/workbench/')]
selected += ['tooling/reporting/reportgen.py', 'tooling/reporting/README.md']
assert not (repo/'tooling/workbench').exists()
for name in selected:
    source = root/name
    assert hashlib.sha256(source.read_bytes()).hexdigest() == manifest['files'][name], name
    destination = repo/name
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, destination)
readme = repo/'README.md'
text = readme.read_text(encoding='utf-8')
text = text.replace('Version 0.3.0 accepts synthetic inputs only', 'Version 0.3.1 accepts synthetic inputs only')
section = '''
## Development workbench

The [offline workbench](tooling/workbench/README.md) provides one place to find cataloged tools, compare prerequisites and holds, record capability requests, create tool starters, and manage synthetic preparation records. It reuses the farm catalog and existing report schemas, with human finding review, immutable Markdown/PDF snapshots and separate tool/import/render outcomes.

```sh
python3 tooling/workbench/workbench.py search modbus --protocol modbus
python3 tooling/workbench/workbench.py choose "analyze existing capture"
python3 tooling/workbench/workbench.py --help
```

Requires Python 3.10+; PDF uses the existing reporting dependency. See [contracts](tooling/workbench/CONTRACTS.md), [verification and review](tooling/workbench/VERIFICATION.md), and [handover guidance](tooling/workbench/HANDOVER.md). The workbench accepts synthetic preparation data only. Plans are previews/manual records; only a fixed synthetic worker is supervised. Native scanner output remains unsupported. Neutral JSON/Markdown exports support manual cloud handoff; no local AI, correction service, API or automatic transfer is included. Actual tool, client, host and event approval remains separate.

'''
assert '## Development workbench' not in text
assert '## Legacy tools' in text
text = text.replace('## Legacy tools', section + '## Legacy tools')
readme.write_text(text, encoding='utf-8', newline='\n')
print(json.dumps({'reviewed_files_copied':selected,'root_readme_updated':True,'private_or_generated_content':False},indent=2))
