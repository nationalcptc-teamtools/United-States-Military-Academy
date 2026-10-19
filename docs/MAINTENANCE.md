# Maintain the active repository

Use root products and current [profile](project-profile.md), [roadmap](roadmap.md), [readiness](READINESS.md) and [user guide](USER-GUIDE.md). `Solberg/` preserves history, manifests and synthetic artifacts; its integrations/tmp/output subtrees are not current dependency or execution roots. No archived payload bytes are deleted. Presentation attributes do not make tracked content private or exclude it from every dependency scanner.

Select active roots explicitly. From the repository root:

```powershell
git status --short
git diff --check
git diff --name-status
python -B -m unittest discover -s tests -v
python -B -m unittest discover -s tooling/farmkit/tests -v
python -B tooling/farmkit/kit.py validate
python -B -m unittest discover -s tooling/reporting/tests -v
python -B -m unittest discover -s tooling/workbench/tests -v
```

Checks use synthetic fixtures. Report optional renderer/platform skips; workbench tests supervise only their fixed synthetic worker. These are local procedures, not expanded CI. `kit.py readiness` should return exit 3 while evidence is pending. Farmkit CI success does not validate the full product or operational readiness.

Configure future dependency/security tools against active files such as `tooling/reporting/requirements.txt`, `tooling/farmkit/install-manifest.json` and selected root source. Inspect actual discovery results; Linguist metadata cannot guarantee dependency-graph exclusion. Do not remove historical manifests or rewrite old verification merely to satisfy a tool.

Before separately authorized publication, inspect changed paths/contents and exclude actual private/client evidence, workspaces and reports. Ignore rules do not protect tracked files. Cleanup/history rewriting/deletion needs a separate deliberate decision with recovery; none occurs here.
