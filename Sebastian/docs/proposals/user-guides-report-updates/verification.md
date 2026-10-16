# Verification

Prepared 2026-10-16 on Windows with bundled Python 3.12. Synthetic fixtures only. Final settled results are recorded after source-package verification.

- Initial baseline reporter: 43 tests passed.
- Incremental-engine tests cover preservation, explicit amendments, legacy schemas, stale base/engagement, duplicate/conflicting evidence, invalid batch rollback, handling, review invalidation, canonical numeric identity, preview, output collision, render failure and optional-format propagation.
- Workbench tests cover current-state CLI, locked preview/apply, stale revision/digest/review, global ID collisions, no-op/replay byte preservation, unrelated acceptance and snapshot receipts.
- Windows sandbox initially denied default temporary paths and synthetic child cleanup. Tests use trusted workspace temporary directories; existing supervisor suite is rerun with its own process-cleanup access. These are environment limitations, not claimed product failures.
- Initial full settled suites before the final optional-format test: reporter 57 passed, workbench 28 passed, farmkit 39 run/one platform skip. The final counts and artifact checks follow.
- Guide links/anchors checked locally, all 48 current workbench commands covered. Both SVG graphics rendered and visually inspected. Source package includes modules, fixtures, tests and guides explicitly.

No live scans, upstream installation, target/client data, network evidence retrieval, native scanner adapter or event acceptance tested. Native Word pagination/layout is unchanged and remains outside this machine's available document renderer; structural Word tests do not certify native visual layout. No Linux runtime claim is made for this new change.

## Settled results

Reporter 58/58, workbench 28/28, farmkit 39 run/38 passed/one platform skip. Total: 125 tests, 124 passed and one skip, including the freshly extracted package. Package member hashes were compared to every current source before extraction. Standalone CLI create/preview/update/PDF/Word completed; PDF QA passed nine pages with source text, actual contents page numbers, inherited markings, artifact hashes and no active content. Marked QA passed 196 complete-report cases. Documentation and source reviewers returned no remaining material findings after corrections. User acceptance remains pending.
