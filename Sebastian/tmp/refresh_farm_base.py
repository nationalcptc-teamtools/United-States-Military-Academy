import hashlib
import re
import subprocess
from pathlib import Path
root = Path(__file__).resolve().parents[1]
repo = root/'integrations/United-States-Military-Academy'
git = 'C:/Users/sebastian.solberg/.cache/codex-runtimes/codex-primary-runtime/dependencies/native/git/cmd/git.exe'
def run(*args, input=None):
    return subprocess.run([git,'-C',str(repo),*args],input=input,check=True,capture_output=True).stdout
assert run('branch','--show-current').strip() == b'codex/farm-toolkit-suite'
def protected():
    return {p.relative_to(repo).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in (repo/'tooling/reporting').rglob('*') if p.is_file() and '__pycache__' not in p.parts}
before = protected()
# Only this unpublished branch's base/index moves; --mixed never changes files.
run('reset','--mixed','origin/codex/report-generator')
assert before == protected()
for path in (root/'tooling/farmkit').rglob('*'):
    if path.is_file() and '__pycache__' not in path.parts:
        raw = path.read_bytes().replace(b'\r\n',b'\n')
        path.write_bytes(raw)
        target = repo/'tooling/farmkit'/path.relative_to(root/'tooling/farmkit')
        target.write_bytes(raw)
run('add','.gitattributes','.github/workflows/farmkit.yml','.gitignore','install.sh','tooling/farmkit')
baseline = run('show','HEAD:README.md').decode()
section = (root/'tmp/farm-readme-section.txt').read_text(encoding='utf-8')
staged = re.sub(r'# Installation Script \(install.sh\).*?(?=# Super Nmap)',lambda m:section,baseline,flags=re.S)
digest = run('hash-object','-w','--stdin',input=staged.encode()).decode().strip()
run('update-index','--cacheinfo','100644,'+digest+',README.md')
snapshot = root/'tmp/farm-public-final'
snapshot.mkdir(exist_ok=False)
run('checkout-index','--all','--prefix='+snapshot.as_posix()+'/')
assert before == protected()
print(run('status','--short').decode())
print('New base:',run('rev-parse','HEAD').decode().strip())
