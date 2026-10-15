"""Final delivery audit, not a new public all-in-one check feature."""
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
from urllib.parse import unquote

root = Path(__file__).resolve().parents[1]
docs = root / 'docs/proposals/development-functions'
sys.path.insert(0, str(root / 'tooling/workbench'))
import delivery

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()
def choice_rows(name):
    result = {}
    for line in (docs / name).read_text(encoding='utf-8').splitlines():
        if re.match(r'^\| IDEA-DF-\d{3} \|', line):
            cells = [cell.strip() for cell in line.split('|')[1:-1]]
            if name == 'scope.md' and cells[1] not in ('Include','Defer','Exclude'):
                continue
            identifier = cells[0]
            assert identifier not in result, identifier
            result[identifier] = cells[2] if name == 'decisions.md' else cells[1]
    return result

decisions, scope = choice_rows('decisions.md'), choice_rows('scope.md')
assert decisions == scope
assert set(decisions) == {f'IDEA-DF-{i:03d}' for i in range(1,121)}
assert Counter(decisions.values()) == {'Include':70, 'Defer':6, 'Exclude':44}
spec = (docs / 'spec.md').read_text(encoding='utf-8')
defined = set(re.findall(r'^\| ((?:FR|NFR)-DF-\d{3}) /', spec, re.M))
expected = {f'FR-DF-{i:03d}' for i in range(1,33)} | {f'NFR-DF-{i:03d}' for i in range(1,13)}
design_ids = set(re.findall(r'^\| ((?:FR|NFR)-DF-\d{3}) \|', (docs/'design.md').read_text(encoding='utf-8'), re.M))
assert defined == expected == design_ids
review = (docs/'review.md').read_text(encoding='utf-8')
reviewed = {}
for filename, expected_sha in re.findall(r'^\| ([\w/._-]+\.py) \| ([0-9a-f]{64}) \|', review, re.M):
    path = root/'tooling/workbench'/filename
    assert sha(path) == expected_sha, filename
    reviewed[filename] = expected_sha
assert len(reviewed) == 9

baseline = json.loads((root/'tmp/development-functions-implementation-baseline.json').read_text(encoding='utf-8-sig'))
changed, missing = [], []
for item in baseline:
    path = root/item['path']
    if not path.is_file():
        missing.append(item['path'])
    elif sha(path).lower() != item['hash'].lower():
        changed.append(item['path'].replace('\\','/'))
assert not missing, missing
allowed = {'README.md','docs/journal.md','tooling/reporting/reportgen.py','tooling/reporting/README.md'}
assert all(path in allowed or path.startswith('docs/proposals/development-functions/') for path in changed), changed
head = subprocess.check_output(['git','-C',str(root/'integrations/United-States-Military-Academy'),'rev-parse','HEAD'], text=True).strip()
status = subprocess.check_output(['git','-C',str(root/'integrations/United-States-Military-Academy'),'status','--short'], text=True).strip()
assert head == '7ccc0a6bbdc3e5488f18f046610f3a271221b81a' and not status

release = root/'output/workbench/release-1.0.0-settled/workbench-1.0.0.zip'
manifest = delivery.inspect_package(release)
assert sha(release) == 'fc2e71072a2d3becb5516ec35e3a1edc3bd7b656bffb49aa273f3a9a001c2550'
assert all(sha(root/name) == checksum for name, checksum in manifest['files'].items() if name != 'LICENSE')
assert (root/'sources').is_dir()

evidence = {'data_category':'synthetic', 'requirement_dispositions':sorted(expected),
            'idea_choices':decisions, 'reviewed_source_hashes':reviewed,
            'verification':(docs/'verification.md').read_text(encoding='utf-8'),
            'scope':(docs/'scope.md').read_text(encoding='utf-8'),
            'design':(docs/'design.md').read_text(encoding='utf-8'),
            'review':review,
            'source_package_sha256':sha(release),
            'package_check':json.loads((root/'output/workbench/package-verification-final.json').read_text(encoding='utf-8')),
            'limits':['No target/client/cloud transfer/publication', 'Actual human/user/event approval pending']}
(root/'tmp/workbench-review-evidence.json').write_text(json.dumps(evidence,indent=2)+'\n',encoding='utf-8')
packet = root/'output/workbench/review-packet-settled'
if not packet.exists():
    delivery.review_packet(root/'output/workbench/demo-session', packet, root/'tmp/workbench-review-evidence.json')

# The record exists before checking links to itself; final content replaces this own audit placeholder.
record = root/'output/workbench/final-artifact-checks.json'
record.write_text('{}\n',encoding='utf-8')
paths = [*docs.glob('*.md'), * (root/'tooling/workbench').glob('*.md'), root/'tooling/reporting/README.md',root/'README.md']
links = delivery.check_links(paths)
assert links['consistent'], links
doc_hashes = {str(path.relative_to(root)).replace('\\','/'):sha(path) for path in docs.glob('*.md')}
result = {'data_category':'synthetic','passed':True,'baseline_files':len(baseline),'missing':missing,
          'changed_existing_files':sorted(changed), 'unexpected_changes':[],
          'idea_counts':dict(Counter(decisions.values())),'ideas_unique':len(decisions),
          'requirement_definitions':len(defined),'design_dispositions':len(design_ids),
          'local_link_check':links,'independently_reviewed_code_hashes_match':True,
          'source_package_matches_current_bytes':True,'source_zip_sha256':sha(release),
          'integration_head':head,'integration_clean':True,'role_document_hashes':doc_hashes,
          'review_packet_exists':(packet/'review.json').is_file(),
          'user_acceptance':'pending','event_approval':'pending','published':False}
record.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in result.items() if k not in ('role_document_hashes','local_link_check')},indent=2))
print(json.dumps(links))
