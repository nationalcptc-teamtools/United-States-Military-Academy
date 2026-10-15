# Farming toolkit task plan

Planned 2026-10-15. Root is sole editor for every task; specialists inspect read-only. Working location is this project mirror. Baseline: original Analyst three-file hashes recorded in the journal; current reporting/integration state is captured in design D-FT-01. Existing work and synced sources are prerequisites to preserve, not task outputs.

| Task / owner | Depends on | Requirements | Deliverable / affected material | Acceptance and checks | State |
| --- | --- | --- | --- | --- | --- |
| T-FT-01 Architect/root editor | Analyst baseline | All 19 | design.md, proposal status | All requirements mapped; current baseline, choices, boundaries and external gates explicit; read-only architectural inspection | Complete |
| T-FT-02 Planner/Tech Lead/root | T-FT-01 | All 19 | tasks.md, execution-guide.md | Acyclic tasks, one editor, bounded Developer/Tester/Reviewer assignments and acceptance gaps | Complete |
| T-FT-03 Developer/root | T-FT-02 | FR-FT-001–004, NFR-FT-001/002/006/007 | tooling/farmkit catalog, sources, readiness, notices | Forty dispositions, supported names/coverage, exact researched references, holds; no fabricated byte hashes or runtime claims | Complete locally |
| T-FT-04 Developer/root | T-FT-03 | FR-FT-006/007/009/012, NFR-FT-003/005/007 | Local validator/integrity helper, synthetic fixture/lock, tests | Strict contracts; bounded local-only verification; meaningful malformed/hash/path/hold/offline tests | Complete locally |
| T-FT-05 Developer/root | T-FT-03 | FR-FT-005/008–012, NFR-FT-001/002/004/005/007 | Runbooks, evidence examples, integration/package guidance | Each primary protocol has finite scope/operation/budgets/stop/evidence/cleanup; not-run and permission gates explicit | Complete locally |
| T-FT-06 Tester/root with independent read-only specialist | T-FT-04/05 | All 19 | Actual local checks, requirement coverage and dated results here/journal | Tests and actual CLI paths, source/content/link/ID checks, unchanged reporting/integration; distinguish pass from external not-run | Complete for available local checks |
| T-FT-07 Reviewer/read-only; root records/remediates | T-FT-06 | All 19 | review.md, findings/remediation/current hashes | Independent actual-file review; separate specification and quality conclusions; affected checks repeated after fixes | Complete: positive scoped review; R-FT-01–03 resolved |
| T-FT-08 Delivery Lead/root | T-FT-07 | FR-FT-011/012, NFR-FT-005/007 | Reviewable local ZIP and manifest, status/journal/navigation | Exact public file allowlist, byte hashes, reproducible package, no private/source/payload data; final evidence matches review | Complete locally; user acceptance pending |
| T-FT-09 Team/runtime owner (unassigned) | T-FT-08 plus OD decisions | FR-FT-002/005/006/008/010–012; NFR-FT-002/003/004/006 | Approved acquisition, dependency/build closure, clean-image host/protocol rehearsal and event readiness | Real selected-version artifacts and Linux/Windows/lab tests with blocked Internet; measured traffic/resources and license/staging/owner/freeze evidence | Pending external evidence |

No T-FT-09 work is simulated as complete. T-FT-08 packages team-authored preparation materials only. Publication, scanning and real customer data are outside this local delivery session.

## Evidence and dispositions

Developer/Tester/Reviewer append actual results and significant findings here after the settled version is checked. An available-check pass does not supersede the original acceptance criteria or T-FT-09.

T-FT-03–06 evidence (2026-10-15): all forty entries and nineteen requirement mappings checked; 27 unit tests ran (26 pass, one native-symlink privilege skip), with mocked symlink/reparse checks passing. Separate-process CLI validate/list/synthetic verify/empty verify/readiness produced 0/0/0/3/3. Initial nesting-limit defect fixed. Independent R-FT-01 surrogate robustness, R-FT-02 OpenPLC license evidence and R-FT-03 OPC UA fragments corrected with regressions and the affected/full suite repeated. See [verification](verification.md) for the detailed acceptance-gap matrix.

T-FT-08 prepared package: output/farmkit/farmkit-1.0.0.zip, 46,590 bytes, 15 allowlisted files plus MANIFEST.json; SHA-256 `de166b1b1a5c2628fe926dccd9d5039c2d3f8fd30b273b4e29e03db08a78fab0`. All member hashes/sizes match and same-runtime repeat builds are byte-identical. The ZIP contains team-authored preparation materials only. No upstream payloads, planning/source originals, reports or credentials included.

T-FT-07 final review independently passed 2,064 schema/type mutations, 40 targeted adversarial checks, 20 read-only/in-memory tests, actual command-function exit checks, 53 module links/fragments, all nineteen mappings and complete ZIP/member/sidecar/repeat-build verification. The reviewer did not run tests that create temporary files; root's 27-test run is separately attributed. Exact identities, findings and acceptance limits are in [review.md](review.md). No implementation changes occurred after that settled review.

## Authorized installation/publication tasks — 2026-10-15

Root retains sole editing ownership; specialists are read-only. User requested commit/PR and clarified assessment suite default, lab servers optional.

| ID / owner | Dependencies | Requirement | Deliverable / acceptance | State |
| --- | --- | --- | --- | --- |
| T-FT-10 Architect/root | User extension, T-FT-08 | FR-FT-013/014 | D-FT-09, install matrix, isolated package groups and public integration boundary | Complete |
| T-FT-11 Developer/root | T-FT-10 | FR-FT-013 | Separate installer/manifest/root quickstart, all forty dispositions; deterministic preview and failure/integrity tests | Complete; see final verification/publication addendum |
| T-FT-12 Tester/root | T-FT-11 | FR-FT-013, NFR-FT-003/005/007 | Actual disposable Kali full-install/check and targeted regressions; distinguish software install from authorized operational acceptance | Complete; see final verification/publication addendum |
| T-FT-13 Independent reviewer/root editor | T-FT-12 | FR-FT-013/014 | Inspect actual staged delta, installation evidence and public contents; fix/retest findings | Complete; see final verification/publication addendum |
| T-FT-14 Delivery Lead/root | T-FT-13 | FR-FT-014 | Commit/push separate branch and create/attach stacked PR, verify exact remote head/base/files and clean worktree | Complete; see final verification/publication addendum |

Publication verified: [PR #2](https://github.com/nationalcptc-teamtools/United-States-Military-Academy/pull/2), commit `7ccc0a6bbdc3e5488f18f046610f3a271221b81a`; T-FT-09 remains external.
