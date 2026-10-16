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

Active role records are in [development-functions](docs/proposals/development-functions/proposal.md). New [machine evidence](evidence/development-functions/continuation-checks.json), [source release](releases/workbench-1.0.1/workbench-1.0.1.zip) and [incremental manifest](CONTINUATION-FILES.json) record this continuation. PROJECT-FILES.json remains the original615-entry snapshot; apply the incremental manifest for current modified/added files. Existing historical integrations/output/tmp files are preserved. New machine scratch/checkouts/caches were not recursively recopied.

Windows workbench20 and reporter43 checks passed; Linux workbench18 passed/two optional dependencies skipped, with actual PDF generation successful. Independent code review was positive. Standalone release identities, exact procedures/limits and final publication checks are recorded in verification.md and machine evidence. These remain synthetic preparation checks, separate from actual tool/client/cloud/event acceptance.
