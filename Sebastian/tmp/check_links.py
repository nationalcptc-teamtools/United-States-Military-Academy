import re
from pathlib import Path
from urllib.parse import unquote

root = Path(__file__).resolve().parents[1]
files = [root / "README.md", *root.joinpath("docs").rglob("*.md"),
         *root.joinpath("tooling").rglob("*.md")]
checked = 0
missing = []
for file in files:
    for target in re.findall(r"\[[^\]]+\]\(([^)]+)\)", file.read_text(encoding="utf-8")):
        if "://" in target or target.startswith("#"):
            continue
        target = target.split("#")[0]
        path = (file.parent / unquote(target)).resolve()
        checked += 1
        if not path.exists():
            missing.append((str(file.relative_to(root)), target))
assert not missing, missing
print(f"Verified {checked} local Markdown links across {len(files)} files.")
