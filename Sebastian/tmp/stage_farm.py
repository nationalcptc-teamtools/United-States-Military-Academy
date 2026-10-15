import re
import subprocess
from pathlib import Path

root = Path(__file__).resolve().parents[1]
repo = root / 'integrations/United-States-Military-Academy'
git = 'C:/Users/sebastian.solberg/.cache/codex-runtimes/codex-primary-runtime/dependencies/native/git/cmd/git.exe'
def run(*args, input=None):
    return subprocess.run([git, '-C', str(repo), *args], input=input, check=True, capture_output=True).stdout

run('add', '.gitattributes', '.github/workflows/farmkit.yml', '.gitignore', 'install.sh', 'tooling/farmkit')
baseline = run('show', 'HEAD:README.md').decode('utf-8')
section = (root/'tmp/farm-readme-section.txt').read_text(encoding='utf-8')
staged = re.sub(r'# Installation Script \(install.sh\).*?(?=# Super Nmap)', lambda m: section, baseline, flags=re.S)
digest = run('hash-object', '-w', '--stdin', input=staged.encode('utf-8')).decode().strip()
run('update-index', '--cacheinfo', '100644,'+digest+',README.md')
snapshot = root / 'tmp/farm-public-review'
snapshot.mkdir(exist_ok=False)
run('checkout-index', '--all', '--prefix='+snapshot.as_posix()+'/')
print(run('diff', '--cached', '--stat').decode('utf-8'))
print('Review snapshot:', snapshot)
