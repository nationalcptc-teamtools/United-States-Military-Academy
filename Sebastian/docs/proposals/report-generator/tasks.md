# Implementation tasks

## Current change — handling inheritance and severity provenance

Root is sole editor; baseline ec767e4/v0.2.0 on current PR #1. Source workbook and farm artifacts are read-only. No severity matrix exists in the supplied workbook; source matrix remains an open question.

| ID | Dependencies / owner | Deliverable and acceptance | Status / actual evidence |
| --- | --- | --- | --- |
| T-15 | none; root Analyst/Architect/Planner | FR-10/FR-11/NFR-07; exact workbook evidence, reversible union rule, compatible schema and bounded execution | Done: all sheet cells and package object inventory inspected; D25 matches user direction, no severity matrix. |
| T-16 | T-15; root Developer | v0.3.0/schema1.2; immutable structured inheritance, ORCON on every export, strongest PII label and union of categories; legacy warning and severity-method notice | In progress. |
| T-17 | T-16; root Tester | Mixed/invalid/legacy/release/parser regressions; every-page PDF markings, supplied text/hash/TOC checks and all-page visual QA; public allowlist and unchanged sources | Pending. |
| T-18 | T-17; authorized independent reviewer read-only | Exact-version specification and quality verdict, stable R-04+ findings if any; root remediates/retests | Pending. |
| T-19 | T-18; root integration | Append reviewed generic/synthetic change to current PR; remote head/content verified, no merge; record limits and unresolved matrix | Pending. |

Reviewed: 2026-10-14. Shared change unit: local starter v0.1.0. Root owns all workspace edits. Baseline/prerequisites: existing read-only project mirror, supplied framework/rules/workbook, no team repo checkout. Refer to the [execution guide](execution-guide.md) for assignments.

### T-01 — Configure framework and source-aware policy

Status: done
Requirements: FR-01, FR-07, NFR-02, NFR-04
Depends on: none
Owner / editing mode: root; sole editor, source analysts read-only
Workspace / version: local project docs, setup 2026-10-14
Baseline / prerequisites: framework v1.0, October 2025 rulebook, assessment Sheet1, user clarifications
Integration / distribution: local preparation; privacy review before sharing planning docs
Affected material: root README, profile, workflow, references, policy, roadmap
Deliverable: linked roles/ownership, evidence distinctions, AI boundary, event/data approval gaps
Acceptance: dates accurate, no client/competition permission inferred, sources unchanged
Verification: full rules/workbook/framework review; source hashes; independent document review
Evidence / deviations: original request retained; 14NOV2026 development milestone confirmed; no event date/repo access invented. Public archive follow-up incorporated in references/template guidance.

### T-02 — Specify contracts, design and templates

Status: done
Requirements: FR-02, FR-04–FR-07, NFR-01–NFR-04
Depends on: T-01
Owner / editing mode: root; sole editor
Workspace / version: proposal products and tooling/reporting templates
Baseline / prerequisites: T-01 evidence and confirmed Markdown/PDF preference
Integration / distribution: public-safe tooling subset after student review; active role artifacts retained locally
Affected material: proposal/spec/design/execution guide/tasks, normalized fixture/README, finding/incident templates
Deliverable: stable requirements, input/review/provenance contract, bounded offline architecture, reusable report/finding/incident templates
Acceptance: candidate/confirmed distinction; metadata not proof; incidents have timeline, addresses, affected scope and mitigation
Verification: contract review against supplied rules p. 10 and declared data limits
Evidence / deviations: no universal report rubric or CVSS version inferred; Python contract is documented by validator and synthetic fixture, not a separate duplicate schema implementation.

### T-03 — Implement the deterministic synthetic starter

Status: done
Requirements: FR-02–FR-05, NFR-01–NFR-03, NFR-05
Depends on: T-02
Owner / editing mode: root; sole editor
Workspace / version: tooling/reporting/reportgen.py v0.1.0
Baseline / prerequisites: no prior code; Python runtime and ReportLab 4.4.9 available
Integration / distribution: reviewed reusable tooling only; no repo write performed
Affected material: generator, dependency declaration, fixture, usage guidance, tests
Deliverable: validated JSON → literal draft Markdown/PDF plus hash manifest; synthetic reviewed-copy gate
Acceptance: offline/passive path, no evidence fetch, no implicit score/status promotion, no overwritten/partial report destination
Verification: T-04 tests and actual CLI sample export
Evidence / deviations: client-derived inputs explicitly rejected; actual script adapters and approved data-handling extension remain T-06 work. Generator source SHA-256: e65ce39377b117469acd7ab829b05f4a4d4b09ab61b1a581bbffe6ca1c871cab.

### T-04 — Verify synthetic contract and PDF output

Status: done
Requirements: FR-02–FR-05, NFR-01–NFR-05
Depends on: T-03
Owner / editing mode: root; sole editor/validator
Workspace / version: same T-03 source hash; synthetic tests and sample
Baseline / prerequisites: ReportLab 4.4.9; preparation-only pypdf 6.10.0, Poppler, installed Arial fonts
Integration / distribution: sample is synthetic; test images/stress/replica remain intermediate QA material
Affected material: tests; output/pdf/sample-report; journal
Deliverable: reproducible validation and inspected final sample
Acceptance: valid and invalid/release paths checked; provenance and hashes preserved; all pages legible
Verification: python -m unittest discover -s tooling/reporting/tests -v; sample CLI; PDF extraction/hash/active-content checks; Poppler PNG review
Evidence / deviations: 22 tests passed (0.758s), 3 sample pages and 5 final stress pages inspected. Same-runtime repeat PDF/Markdown/manifest byte identity checked. Socket-blocked PDF export passed. Initial default-system-temp run was interrupted after a test error/stall; test temp storage moved to ignored workspace tmp and final run passed. Early QA extraction comparison corrected for uppercase labels and repeated page frames. Long narrative chunking removed an excessive blank-page area in the initial stress render.

### T-05 — Independent review and remediation

Status: done
Requirements: NFR-03–NFR-05
Depends on: T-04
Owner / editing mode: independent reviewer read-only; root records/fixes
Workspace / version: same T-03 source hash and settled validation
Baseline / prerequisites: original request, role artifacts, implementation and T-04 evidence
Integration / distribution: local reviewed starter; review grants no event/user acceptance
Affected material: review.md and fixes/test evidence
Deliverable: scoped independent verdict with findings/dispositions
Acceptance: must-fix findings resolved; review independence and gaps explicit
Verification: read-only code/docs/hash review, image review as documented in review.md; root regression rerun
Evidence / deviations: R-01 numeric overflow correction and regression verified; separate historical-source/event-integration limits remain. See review.md for final verdict.

### T-06 — Integrate November scripts and approved data handling

Status: pending
Requirements: FR-02–FR-05 (full original-product integration), NFR-01–NFR-03
Depends on: T-05
Owner / editing mode: future student maintainer/analyst; ownership to confirm
Workspace / version: inspected team repository/approved development copy, not selected yet
Baseline / prerequisites: 2–3 synthetic actual-script outputs, tool conventions, authorized storage/endpoint handling and retention decisions
Integration / distribution: compatible adapter changes reviewed first, then public-safe package under team conventions
Affected material: future adapters/schema version, handling gates, fixtures and error/partial-run records
Deliverable: actual 14NOV2026 script outputs generate accurate draft reports in an approved environment
Acceptance: success/partial/failure cannot conceal lost observations; no fake empty success; raw/provenance retained privately; marking/review unchanged
Verification: synthetic integration fixtures plus event-like runtime rehearsal; real data only when authorized
Evidence / deviations: not run; actual scripts/format contracts and handling approvals unavailable. Starter is not claimed production-ready.

### T-07 — Prepare the approved event release

Status: pending
Requirements: NFR-02, NFR-04; competition readiness
Depends on: T-06
Owner / editing mode: eligible student maintainer/captain; confirm before edits
Workspace / version: user-described assigned repository after access/approval verification
Baseline / prerequisites: actual event start/timezone, current ROE/SOW, repo access and Operations Team decisions, required runtime/dependencies
Integration / distribution: approved public CPTC repository before confirmed freeze; reports/evidence stay in authorized private event storage
Affected material: release checklist, dependency/public-content audit, frozen version/hashes, membership record
Deliverable: documented approved release and successful submission rehearsal
Acceptance: T−14 request/T−7 freeze or stricter dates met; permitted environment/tooling; student can explain code; no private data published
Verification: captain approval record, repository inspection, competition-host smoke test and report rubric review
Evidence / deviations: not run; no external actions/repo writes/official messages performed. AI/cache experiments need separate proposals and concrete approvals.

### T-08 — Resolve literal Markdown and integer-parser review findings

Status: done
Requirements: FR-03, NFR-01, NFR-03, NFR-04; review findings R-02 and R-03
Depends on: T-05
Owner / editing mode: root sole editor; independent remediation reviewer read-only
Workspace / version: existing local reporting starter, patch version 0.1.1; schema remains 1.0
Baseline / prerequisites: v0.1.0 generator e65ce39377b117469acd7ab829b05f4a4d4b09ab61b1a581bbffe6ca1c871cab; existing fixtures, templates, design and historical T-01–T-05 evidence retained
Integration / distribution: local preparation only; no repository or event integration
Affected material: generator, unit tests, optional Markdown rendering QA, tooling README, proposal/review/task/journal records
Deliverable: source indentation and equals-sign lines remain literal; numeric-parser failures receive sanitized input rejection with exit 2
Acceptance: complete-report parser checks preserve literal characters and report headings; oversized integers produce no report or raw-value diagnostic; duplicate/nonfinite diagnostics remain intact; existing synthetic/offline/review boundaries unchanged
Verification: bundled Python -B -m unittest discover -s tooling/reporting/tests -v; optional check_markdown_rendering.py with bundled Node/Marked; real sample CLI and manifest/PDF identity checks; independent read-only re-review
Evidence / deviations: before fixes, focused JSON regressions yielded one failure, one error and one pass, and rendered-text QA exposed both Markdown defects. After fixes, all 25 unit tests passed in 1.100s and 112 full-report Markdown cases passed. Sample export at tmp/remediation/r02-r03-sample succeeded; hashes match manifest and its three-page PDF is byte-identical to the original. Independent reviewer confirmed both findings resolved. Exact whitespace and all list-container fidelity are outside the compact-text QA verdict; actual adapters/event readiness remain pending.
Settled generator SHA-256: c145d19e9ecdc9ea096a12c4566196d13b00ae9d121270a3ec1088460049b148
Settled unit tests SHA-256: 2eb14adc04dba3d1721e5fc12194c18f2d65507e3ae94e83faab63753a0d3d46
Settled Markdown QA SHA-256: f6da556e296831b819a2cf48f88a39023a2c819a6ae1dc600c2e2b2491855c7c

### T-09 — Verify repository access and upload the reviewed starter

Status: done (upload/draft PR; merge and event acceptance pending)
Requirements: FR-03, FR-06, NFR-01–NFR-04; repository portion of T-07
Depends on: T-08
Owner / editing mode: root sole editor; user confirmed sebastianjsolberg is approved to contribute
Workspace / version: integrations/United-States-Military-Academy, codex/report-generator, reporting v0.1.1/schema 1.0
Baseline / prerequisites: inspected master bf6e47a52e0edb8bbcb628269cc1693d6f0ce782; user upload authorization/account confirmation; authenticated write access
Integration / distribution: public team-repository branch and [draft PR #1](https://github.com/nationalcptc-teamtools/United-States-Military-Academy/pull/1); no automatic merge
Affected material: nine allowlisted reporting code/template/fixture/test/guidance files; root README/.gitignore additions
Deliverable: reviewed synthetic reporting package uploaded with usable examples and generated/private outputs excluded
Acceptance: existing tools/license/policy preserved; no source/planning/client artifacts uploaded; real use path passes from repository root; branch and PR verified
Verification: repository/branch/open-PR/dependency/configuration inspection; 25 tests; 112 rendering cases; actual Markdown/PDF/manifest export; staged-file/ignore/link/hash/whitespace checks
Evidence / deviations: 25 tests passed in 1.713s; rendering QA and sample export passed. Exact staged set was 11 approved files. config.py, super_nmap.py, install.sh, root requirements.txt, LICENSE and enumeration-agent policy unchanged; prior README/ignore text retained. Commit 5bc4c77beea8c1e505ec72c53149b4507044d975 uploaded; PR #1 confirmed open, draft, unmerged and mergeable through the connected GitHub tool.

T-06/T-07 update: access/contents are now inspected and starter upload complete. Earlier no-checkout/no-write statements describe the initial preparation baseline. Actual November adapters, client handling, Kali/event-host validation and event release gates remain pending; T-09 does not close those tasks.

### T-10 — Analyze reference and design report/intake contracts

Status: done
Requirements: FR-08, FR-09, NFR-06
Depends on: T-09
Owner / editing mode: root sole editor; sources/catalog read-only
Workspace / version: local proposal; public design under tooling/reporting, target v0.2.0
Baseline / prerequisites: PR #1 head 5bc4c77; immutable DOCX hash and forty-entry catalog inspected
Integration / distribution: private source evidence stays local; original public design enters existing PR
Affected material: spec/design/proposal, module design and example tool-run envelope
Deliverable: numbered report model, compatible input extension, per-tool output routes and gated import contract
Acceptance / checks: preserve IDs and source facts; map all forty TOOL IDs; distinguish planned adapters/holds from actual runtime; inspect examples/links/contracts
Evidence / deviations: DOCX text/style inspection succeeded; source rasterizer unavailable (missing LibreOffice). No exam commands executed or source media copied. Public design has exactly forty unique sequential TOOL routes plus Nmap; planned adapter registry, producer contract and run/observation/import registers are explicit. Source hashes remain unchanged. A self-review clarified that envelope hashes belong in separate import records, avoiding self-referential producer hashes.

### T-11 — Implement and verify template-inspired report rendering

Status: done
Requirements: FR-03–FR-06, FR-08, NFR-01, NFR-03, NFR-05, NFR-06
Depends on: T-10
Owner / editing mode: root sole editor
Workspace / version: existing reporting module, target v0.2.0; schemas 1.0/1.1
Baseline / prerequisites: T-10 report model; existing regression suite and source/privacy boundaries
Integration / distribution: synchronize reviewed preparation module into existing PR checkout
Affected material: validator, shared report view, Markdown/PDF renderers, fixture/templates/README and tests
Deliverable: cover/contents/numbered report with supplied objective, recommendations and methodology sections
Acceptance / checks: legacy facts/release/offline/error behavior retained; actual TOC pages; literal new fields; sample/long/empty PDF renders and visual QA; parser regressions
Evidence / deviations: v0.2.0 implemented shared report blocks, compatible schemas 1.0/1.1, original cover/contents/numbered sections, evidence register and multi-pass PDF TOC. Existing R-01–R-03 repairs retained. Four new unit checks cover legacy facts, optional sections/bounds and rejecting the design-only envelope as report input. Final preparation suite passed 29 tests (0.471s); 196 complete-report Markdown cases passed across fourteen contexts. Final sample has 8 pages; long and empty variants have 10 and 7 pages. All 25 pages inspected as images without clipping/overlap/missing text. Exact old 1.0 fixture rendered successfully; same-runtime repeated Markdown/PDF are byte-identical. An initial new assertion incorrectly expected an unescaped hyphen; the assertion was corrected. Initial 9-page spacing was tightened and all final sample pages rechecked.

### T-12 — Validate integration and public content

Status: done (independent review tracked separately in T-13)
Requirements: FR-08, FR-09, NFR-02–NFR-06
Depends on: T-11
Owner / editing mode: root sole editor/validator
Workspace / version: codex/report-generator, exact settled hash to record
Baseline / prerequisites: settled implementation and public design
Integration / distribution: existing draft PR #1
Affected material: tests, synthetic previews, design/contract fixtures, local evidence
Deliverable: reproducible verification with current hashes, all-page PDF QA and public-file allowlist
Acceptance / checks: meaningful pre-fix detection and affected regression passes; all forty IDs mapped; source DOCX/farm documents unchanged; no source screenshots/credentials or generated reports staged
Evidence / deviations: all 12 reporting files are byte-identical between preparation and the existing repository checkout. Repository-copy checks passed: 29 unit tests (0.559s), 196 Markdown cases, actual 8-page PDF export and optional PDF QA. All supplied text, artifact hashes, TOC page numbers and inactive PDF checks passed; repository preview is byte-identical to the visually inspected final sample. Sample chapter pages are 3/4/5/6/8. Both legacy/stress/empty extraction checks passed. All forty routes present; 70 local links across 22 documents passed. DOCX, farm-toolkit documents, root AGENTS and original sample PDF unchanged. Existing six repo tool/config/install/license/policy files match master; generated output/test temp are ignored. Public delta is seven modified plus three new files; exact staged allowlist still to verify under T-14.

Settled generator SHA-256: 61e58c2c636f22afdad34a686cb0302510cabbc23ef199770111beb2d258ab0b
Settled public design SHA-256: e76441243a2a9767a20e4ee6b35b15aa0e9504f5e78ca105edd40492177d1d3e
Settled unit tests SHA-256: 324e28d736eb2abe381626238a429752b36b9fe8da7a478c4658a638983d2b29
Settled Markdown QA SHA-256: 0314ae82edafb82dc2b558d7bd6e4e85a232a181053dc654d8da41efc7c7b6c9
Settled PDF QA SHA-256: 3b7bfb4c5e80db0f7fe686992b081a1e052b5e838f6862c5e096b5b34cc2fcde

### T-13 — Independent review and remediation

Status: done (2026-10-15)
Requirements: FR-08, FR-09, NFR-03–NFR-06
Depends on: T-12
Owner / editing mode: independent reviewer read-only; root records/fixes
Workspace / version: exact settled report/design/test version
Baseline / prerequisites: request, sources/constraints, role products and actual validation evidence
Integration / distribution: scoped review before final PR update
Affected material: review.md and any bounded remediation
Deliverable: independent specification/quality conclusions, stable R-* findings and dispositions
Acceptance / checks: no unresolved must-fix findings or explicit disposition; no claim that design proves adapter/runtime support
Evidence / deviations: user-authorized independent /root/format_intake_review returned a scoped positive verdict against ec767e466147150941f77e1759c66c7949a76f00 with no new actionable findings; R-01–R-03 remain resolved. Independently passed 196 Markdown cases, sample/stress/empty/legacy PDF QA, focused in-memory contract/release/parser checks, all forty routes/seven holds, unchanged source/existing-tool hashes and representative visual pages. Full root unit-suite/all-page checks were not independently repeated. See review.md for exact hashes, evidence and limits. No remediation changes required.

### T-14 — Update existing PR and hand off

Status: done (2026-10-15; draft PR update, no merge)
Requirements: FR-08, FR-09, NFR-02, NFR-04
Depends on: T-13
Owner / editing mode: root sole editor, approved contribution account sebastianjsolberg
Workspace / version: codex/report-generator; PR #1 only
Baseline / prerequisites: verified/reviewed exact change; remote head checked; existing author work preserved
Integration / distribution: append commit(s), update PR description, no merge
Affected material: allowlisted public module/design/fixtures and local progress records
Deliverable: pushed format/design changes and truthful PR validation/limitations
Acceptance / checks: remote PR head matches local commit; preserved existing tools; source/private artifacts excluded; final links/hashes/status current
Evidence / deviations: exact 10-file staged allowlist and private-source/credential-marker audit passed; git whitespace check passed. Independently reviewed ec767e466147150941f77e1759c66c7949a76f00 pushed on the existing branch without force. PR title/body updated for final v0.2.0 scope and verified through GitHub; full PR has 14 files, is open/draft/unmerged/mergeable and its head matches the clean local checkout. PR reattached to this chat. Default network push failed DNS; authorized escalated push succeeded. Connected GitHub integration could read but returned HTTP403 for metadata writes; the already-approved sebastianjsolberg credential updated title/body through REST after account/permission/head checks. Credentials stayed in memory and no helper/source/report artifacts were uploaded. Implementation/verification/review for this change unit complete; full acceptance, adapters and event readiness remain pending.
