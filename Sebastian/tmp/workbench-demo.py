"""Reproducible synthetic CLI exercise; no actual human or event acceptance."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
work = ROOT / 'output/workbench/demo-session'
inputs = ROOT / 'output/workbench/demo-inputs'
inputs.mkdir(parents=True, exist_ok=True)
log = []

def command(*args, codes=(0,)):
    result = subprocess.run([sys.executable, '-B', str(ROOT / 'tooling/workbench/workbench.py'), *map(str, args)],
                            cwd=ROOT, capture_output=True, text=True, encoding='utf-8')
    log.append({'arguments': list(map(str, args)), 'exit': result.returncode, 'stdout': result.stdout, 'stderr': result.stderr})
    if result.returncode not in codes:
        raise RuntimeError((args, result.returncode, result.stdout, result.stderr))
    return json.loads(result.stdout)

def data(name, value):
    path = inputs / name
    path.write_text(json.dumps(value, indent=2) + '\n', encoding='utf-8')
    return path

command('init', work, '--owner', 'Synthetic exercise owner')
command('search', 'modbus', '--protocol', 'modbus')
command('search', 'winpeas', '--platform', 'linux', '--explain-excluded')
command('choose', 'analyze existing capture')
command('card', 'TOOL-013', codes=(0, 3))
command('compare', 'TOOL-013', 'TOOL-014')
command('platforms')
command('preflight', ROOT / 'output/workbench/future-output', '--require', sys.executable)
command('intake', work, data('request.json', {
    'problem': 'Avoid retyping synthetic Modbus preparation notes', 'user': 'Training operator',
    'input': 'Invented metadata', 'output': 'Reviewable draft', 'acceptance': 'All supplied fields visible',
    'owner': 'Author', 'backup': 'Backup', 'reviewer': 'Reviewer', 'kind': 'documentation',
    'value': 4, 'frequency': 3, 'confidence': 3, 'effort': 2, 'risk': 2, 'dependencies': [], 'reuse_query': 'modbus'}))
command('decision', work, data('decision.json', {'topic': 'Synthetic tool choice', 'owner': 'Exercise owner',
    'choice': 'accepted', 'reason': 'Existing capability covers invented task', 'alternatives': ['duplicate wrapper']}))
command('owner', work, 'TOOL-013', '--primary', 'Author', '--backup', 'Backup', '--reviewer', 'Reviewer')
command('scaffold', ROOT / 'output/workbench/demo-tool', '--name', 'synthetic_helper', '--owner', 'Training author')
command('check-docs', ROOT / 'output/workbench/demo-tool')
command('check-links')
plan = command('plan', work, data('plan.json', {'command': 'synthetic-preview --token "INVENTED-CANARY"',
    'scope_ref': 'Synthetic SOW v1 (not authorization)', 'profile': 'manual-example-v1',
    'effects': 'Preview only', 'limits': 'No target operation', 'destination': str(ROOT / 'output/workbench/future-output'),
    'targets': ['192.0.2.10'], 'approved_targets': ['192.0.2.10'], 'excluded_targets': [], 'discovered': ['192.0.2.11']}))
command('revalidate', work, plan['id'], data('current.json', {k: plan[k] for k in
    ('scope_ref', 'profile', 'targets', 'approved_targets', 'excluded_targets')}), '--reviewer', 'Synthetic reviewer')
runs = []
for status, exit_code in [('success', 0), ('partial', 0), ('failed', 7), ('cancelled', 130), ('not_run', None)]:
    args = ['run-record', work, '--tool', 'Synthetic ' + status, '--version', 'fixture-1', '--operator', 'Exercise author',
            '--status', status, '--limitations', 'Invented outcome; no target testing occurred',
            '--scope-ref', 'Synthetic scope', '--evidence-ref', 'E-SYNTHETIC-CLI']
    if exit_code is not None:
        args += ['--exit-code', exit_code]
    runs.append(command(*args))
command('event', work, runs[0]['id'], '--stage', 'import', '--status', 'failed', '--code', 'synthetic_format_failure', '--exit-code', 2)
command('event', work, runs[0]['id'], '--stage', 'render', '--status', 'failed', '--code', 'synthetic_render_failure', '--exit-code', 1)
command('resume', work, runs[2]['id'], '--disposition', 'skip', '--actor', 'Synthetic author')
fixture = ROOT / 'tooling/reporting/examples/report-marked.json'
command('preview-import', fixture)
item = command('import-report', work, fixture)
command('import-report', work, fixture)
source = json.loads(fixture.read_text(encoding='utf-8'))
finding = source['findings'][0]['id']
command('prefill', work, item['id'], finding)
command('duplicates', work, item['id'])
command('review', work, item['id'], finding, '--decision', 'accept', '--reason',
        'Automated exercise of synthetic review gate only; actual human review remains required', '--reviewer', 'Synthetic test actor')
command('complete', work, item['id'], '--rubric', 'scope', codes=(0, 3))
command('incident', work, data('incident.json', {'run': runs[2]['id'], 'actor': 'Exercise author',
    'summary': 'Invented failure; no real incident or notification', 'stop': 'No target process started', 'markings': ['FI']}))
command('retest', work, data('retest.json', {'finding': finding, 'actor': 'Exercise author',
    'summary': 'Invented recommendation; fix not applied', 'status': 'recommended'}))
command('handling', work, data('handling.json', {'custodian': 'Synthetic exercise owner',
    'retention': 'Preparation example only; actual policy unresolved', 'export': 'Synthetic files only', 'deletion': 'No automatic deletion'}))
command('snapshot', work, item['id'], ROOT / 'output/pdf/workbench-demo', '--pdf')
command('status', work, '--destination', ROOT / 'output/workbench/demo-status')
command('handoff', work, ROOT / 'output/workbench/cloud-handoff', '--reviewer', 'Synthetic export exercise', '--import-id', item['id'])
command('handoff', work, ROOT / 'output/workbench/cloud-handoff', '--reviewer', 'Synthetic export exercise', '--import-id', item['id'], '--approve-export')
command('integrity', fixture, hashlib.sha256(fixture.read_bytes()).hexdigest())
(inputs / 'cli-results.json').write_text(json.dumps({'data_category': 'synthetic', 'checks': log,
    'limits': 'Automated exercise; not actual human, event, operational or cloud acceptance'}, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'commands': len(log), 'pdf': 'output/pdf/workbench-demo/report.pdf', 'handoff': 'output/workbench/cloud-handoff',
                  'all_expected_exit_codes': True}))
