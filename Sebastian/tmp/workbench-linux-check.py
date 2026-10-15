import os
import pathlib
import shutil
import subprocess
import sys

shutil.copytree('/input', '/tmp/project/tooling')
shutil.copyfile('/input-license', '/tmp/project/LICENSE')
interpreter = next(iter(pathlib.Path('/opt').glob('**/reporting/bin/python')), pathlib.Path(sys.executable))
print('Interpreter:', interpreter, flush=True)
result = subprocess.run([str(interpreter), '-B', '-m', 'unittest', 'discover', '-s', 'tooling/workbench/tests', '-v'], cwd='/tmp/project')
extra = '''import sys
sys.path.insert(0, 'tooling/workbench')
import workspace, reports
workspace.init('output/session', 'Synthetic Linux')
item = reports.import_report('output/session', 'tooling/reporting/examples/report-marked.json')
reports.snapshot('output/session', item['id'], 'output/pdf', pdf=True)
print('Linux PDF generated')
'''
pdf = subprocess.run([str(interpreter), '-B', '-c', extra], cwd='/tmp/project')
raise SystemExit(result.returncode or pdf.returncode)
