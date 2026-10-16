# Project publication — 15 October 2026

The user requested this project's files in `Sebastian/`, with runnable products at the repository root. This snapshot records 615 existing project files: 566 archived project files and 49 integrated product files. Git metadata and caches are excluded; the synced `sources/` directory was empty and remains unchanged.

Root products combine master `c8f88dd` (including editable Word export) and development workbench `6e22cbb` (including the farm toolkit). Reporting 0.4.1 preserves both APIs and includes workbench appendices in Word, PDF, and Markdown. Historical checkout copies and generated synthetic preparation artifacts under this directory are archival.

Verification on Windows with Python 3.12:

- Reporting: 43 tests passed, including combined Word/appendix generation.
- Farm toolkit: 39 tests run successfully, one platform-specific skip.
- Workbench: 18 tests passed with the process permissions needed for worker cleanup.
- Manifest records every source path/hash and committed destination path/hash. Documentation product links target root tooling.
- No changes to `cptc-linux.sh` or `cptc-windows.ps1` relative to the current master.
- Changed product files pass the whitespace check. Archived generated Markdown retains its original formatting.

These checks use synthetic fixtures and do not establish event deployment or operational acceptance.


## Workbench integration continuation — 15 October 2026

User explicitly selected finishing integration and publishing the full records. Base6c8ec1d already published the complete original snapshot, so no documentation backlog was recopied. Root tooling now carries workbench1.0.1; reporter0.4.1 and workspace format1.0.0 are preserved separately. Snapshots can request the existing Word renderer, and source packages retain its regression tests/public records.

Active role records are in [development-functions](docs/proposals/development-functions/proposal.md). New [machine evidence](evidence/development-functions/continuation-checks.json), [source release](releases/workbench-1.0.1/workbench-1.0.1.zip) and [incremental manifest](CONTINUATION-FILES.json) record this continuation. PROJECT-FILES.json remains the original615-entry snapshot; apply the incremental manifest for current modified/added files. Existing historical integrations/output/tmp files were preserved at the time of that continuation; see the repository cleanup note below for their later removal from tracking. New machine scratch/checkouts/caches were not recursively recopied.

Windows workbench20 and reporter43 checks passed; Linux workbench18 passed/two optional dependencies skipped, with actual PDF generation successful. Independent code review was positive. Standalone release identities, exact procedures/limits and final publication checks are recorded in verification.md and machine evidence. These remain synthetic preparation checks, separate from actual tool/client/cloud/event acceptance.


## Repository cleanup — 16 October 2026

The historical `integrations/`, `tmp/` and `output/` trees were untracked from `master` (532 files, about 12 MB): two stale whole-repository checkouts, generated report PDFs and their rasterized page images, build logs, repeated release packages, and scratch scripts. This directory's own `.gitignore` already excludes `/integrations/`-adjacent preparation material via `/output/`, `/outputs/` and `/tmp/`; those rules were added after the files were tracked, and an ignore rule cannot untrack what is already committed. Removing them makes the published tree match the stated policy that only reusable tooling, templates, dependency declarations and synthetic fixtures are public.

Everything removed remains in Git history and is recoverable by path from commit `78dc138`. `PROJECT-FILES.json` and `CONTINUATION-FILES.json` were deliberately left unmodified: they are dated machine evidence, and `CONTINUATION-FILES.json` records a SHA-256 of `PROJECT-FILES.json` that editing either file would invalidate. Their entries therefore still describe the archival paths as they existed on 15 October 2026. Markdown links that pointed into the removed trees were converted to plain paths in backticks, so the provenance records still name every artifact and its recorded hash without producing broken links.

The one design record that existed nowhere else, the Word export packet (proposal, spec, design, tasks, execution guide and review), was relocated intact to [docs/proposals/word-workflow](docs/proposals/word-workflow/proposal.md) rather than deleted, because the feature it specifies ships at the repository root.

## Commit history rewrite — 16 October 2026

The user requires that no commit carry assistant attribution. Thirteen commits
whose messages ended in a `Co-Authored-By` trailer, or that descend from one,
were rewritten across `master` and the three `codex/*` branches. Only the
trailer line and its blank separator were removed: every rewritten commit keeps
its original tree hash, author, committer and both timestamps, verified
pair-by-pair against the pre-rewrite objects. Commits that predate
`c2468f2`/`0231c2b` were deliberately excluded from the rewrite so they keep
their existing identities and their GPG signatures.

| pre-rewrite | current | subject |
| --- | --- | --- |
| `c2468f2` | `0231c2b` | Add consolidated Linux/Windows enumeration runners |
| `78433b5` | `86267f0` | Merge branch 'master' into codex/report-generator |
| `c4e01c5` | `14f883a` | Merge pull request #1 |
| `c8f88dd` | `f816e76` | Add optional editable Word report export |
| `8b9875f` | `e650a45` | Merge codex/report-generator into codex/farm-toolkit-suite |
| `e298a57` | `0f90fbb` | Merge pull request #2 |
| `fbde046` | `f6e63df` | Merge origin/master into codex/development-workbench |
| `6e22cbb` | `a01160f` | Add offline development workbench and report workflow |
| `6c8ec1d` | `42ee6a2` | Organize CPTC project under Sebastian |
| `09099c6` | `4fb8aa3` | Finish workbench integration and publish Sebastian records |
| `78dc138` | `5909432` | Add complete user guides and shared incremental report updates |
| `0891cde` | `9ab8455` | Stop probing OT/ICS ports, and add operator activity logging |
| `613775c` | `dafcd6e` | Untrack local preparation artifacts and tidy the public tree |

Commit identifiers quoted elsewhere in this directory and under `tooling/` are
pre-rewrite values and were left unchanged on purpose. They appear in dated
records of work completed on 14 and 15 October, when those were the real
identities, and ten of the files holding them have their SHA-256 recorded in
`PROJECT-FILES.json`, `CONTINUATION-FILES.json` or
`releases/workbench-1.0.1/MANIFEST.json`. Editing them would invalidate those
digests and force the manifests themselves to be rewritten, so the table above
is the translation instead. Every recorded digest therefore still verifies.

Four merge commits created through the GitHub web interface — `78433b5`,
`8b9875f`, `c4e01c5` and `e298a57` — were GPG-signed. Rewriting a message
invalidates its signature, so the current commits are unsigned and lose the
"Verified" badge. The six signed commits outside the rewritten range, including
the initial commit and `bf6e47a`, keep their signatures.

Because published history changed, clones must be reset rather than merged:
`git fetch origin && git reset --hard origin/<branch>`. The pre-rewrite objects
remain in a local backup bundle only; they are not published.
