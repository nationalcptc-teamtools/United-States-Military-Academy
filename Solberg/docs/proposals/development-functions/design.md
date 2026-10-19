# Development workbench design

## Integration continuation — 2026-10-15

Reuse reporter 0.4.1 unchanged. Add optional `snapshot --docx`, pass it through keyword-only `reports.snapshot(..., docx=False)` to the existing `generate(..., docx=...)`. Preserve existing positional arguments, authoritative input and shared appendix/handling inheritance. The renderer stages every requested format; the workbench then publishes the complete bundle and ledger record. A renderer exception occurs before snapshot mutation. Manual Markdown/Word edits change their hashes and do not update other formats.

Separate application VERSION=1.0.1 from WORKSPACE_VERSION=1.0.0. State creation/validation use the latter; CLI/status/release identity uses the former. No workspace content migration is required. Explicit source members now include workbench SPEC.md/VERIFICATION.md and reporting tests/test_docx.py, yielding 54 ZIP members including manifest. Keep sibling tooling paths so catalog/renderer/package resolvers remain valid.

Repository publication is incremental from 6c8ec1d: active role records and a small evidence/release/continuation manifest go in Sebastian/; code remains root tooling/. Preserve the original 615-file manifest and historic archive. Do not run broad recursive copying scripts or overwrite reporter 0.4.1 from older local mirrors. All 44 original requirement dispositions and all 120 idea choices remain intact.

Architect: root, 2026-10-15. Editing: root only. User decisions: [decisions.md](decisions.md). All 120 decisions explicit: 70 Include, 6 Defer, 44 Exclude. Subsequent user correction replaces local AI/correction with a manual cloud-system handoff. No local model, remote API or automatic upload is part of this implementation. Independent read-only reviewer authorized by user.

## Scope and reuse

Create `tooling/workbench/`, an offline Python 3.10+ command-line application. Read the existing forty-tool farm catalog and existing report JSON schemas 1.0/1.1/1.2; retain their source-of-truth contracts. No native scanner parser or cptc.tool-run producer-envelope validator. Imported reports remain synthetic-only. A local workbench workspace contains workflow state; it is not a new cross-project evidence-ID graph.

Use the existing renderer for editable Markdown and optional ReportLab PDF. Add an optional, validated appendix-block API so both formats contain identical supplied run/incident/retest information; the ordinary report CLI/schema remains unchanged. Hash the appendix separately in extended manifests. Preserve existing catalog, farm installer, integration checkout and independent Linux/Windows runners. Existing runner operation budgets and authorization are not replaced or disabled.

No new target runner, typed operation profiles, budget engine, staging/installation system, full acquisition inventory, documentation snapshot/index, saved shortlist, failed-search telemetry, CI, broad adversarial fixture library, practice/simulator packs, submission rehearsal, CVE lookup, prose AI or global traceability view is added. The original FR/NFR tables remain historical breadth; the following reconciled mapping controls this delivery.

## Components

| Component | Responsibility / information boundary |
| --- | --- |
| common.py | Bounded local JSON, sanitized errors, local IDs/time/hashes, regular-file checks, atomic no-overwrite bundles and revision-checked state changes. No network. |
| catalog.py | Live view of farm catalog plus legacy/report/workbench helpers; text/task/protocol/platform/runtime/privilege/input/output/operation/readiness filters, comparisons, cards and next actions. Named owners and evaluation decisions stored as overlays, not edits to farm v1. |
| workspace.py | Synthetic workspace; requests with priorities/owners/blockers/alternatives/deferred triggers; conflict-preserving authored notes; stale ownership release/transfer without a new target-claim service; manual metrics; acceptance/status and shift records. |
| operations.py | Offline operator-authored plans, preview/revalidation/deviation records, separate discovered/approved lists, manual run/stage events, bounded logs. Synthetic fixed worker supervision demonstrates stop/child cleanup and deliberate resume. It never dispatches target-facing commands. Manual runner integration is documented. |
| reports.py | Preview/import existing completed-report JSON, idempotent import, human candidate review, deterministic explainable duplicate suggestions and reversible merge history, prefilled drafts, completeness, retest/incident records, snapshot changes, appendix and integrity checks. |
| workbench.py | Explicit CLI commands and machine-readable results; no dynamic plugin/command execution from files. |
| build.py / guidance | Allowlisted preparation/reviewer/handoff bundles, checksums, previous-release comparison/recovery, cloud handoff and cohort guidance. Local browser interface evaluated against CLI/static export; no server selected. |

The public module plus existing sibling catalog/reporter is the supported repository layout. A preparation ZIP includes those required reusable siblings and notices, with no output/workspace/client material. Workspace/handoff bundles are separately generated, synthetic-marked and private by default. No new upload action.

## State and contracts

Workspace `state.json` has workbench version, synthetic category, monotonically increasing revision, owner/handling controls and named collections (requests, decisions, notes, plans, runs, reviews, merges, retests, incidents, metrics, snapshots). Local object IDs are implementation identifiers required by included helpers/status/duplicate handling, not the excluded full evidence graph. Existing finding/evidence IDs are retained without renumbering.

Each mutation takes expected revision, an exclusive lock, validates current state and writes a temporary file followed by replace. Stale authored edits preserve current/proposed values in a conflict record and return conflict status; no silent merge. New bundles/destinations refuse overwrite and redirected/symlink/reparse paths. The trusted, quiescent parent-directory assumption is explicit; this is not protection from a hostile process replacing directories concurrently.

Plans describe manually supplied executable/arguments/effects/limits/destination and external scope reference. Store sanitized preview; do not execute that text. Scope/target/profile digest changes invalidate approval; revalidation takes operator-supplied authorized address sets and records reviewer decision, without DNS probing. Discovered assets stay separate. Deviation records record reason and external approval reference; they do not grant permission.

Run metadata is entered manually using CLI fields; no new producer export contract/example. Tool, import and render statuses remain distinct. Logs retain concise action/status/identity metadata and diagnostic codes; secrets/raw payloads are not recorded. Fixed synthetic supervisor owns only its own process group; cancellation terminates children and records cancelled/partial state. Resume requires explicit repeat/skip disposition and never relaunches a target.

Import uses the existing report validator. A preview is non-mutating. Exact bytes get received-export identity; existing supplied source hashes retain unverified status. Same-content import is idempotent; conflicting same finding IDs preserve versions or fail explicitly. Human review records reason/reviewer and distinguishes confirmed finding from imported candidate. Duplicate suggestions are deterministic (same title/assets or substantial word overlap), with reasons; merge chooses a primary, retains both originals, union of restrictions and reversible decision history. No automatically generated severity/impact/CVE claim.

Snapshots contain authoritative input, report.md, optional report.pdf, manifest, changes and run/incident/retest appendix. A new output directory is required; no snapshot mutates previous outputs. Review checks include unresolved candidates, required narrative/evidence/reviewer and rubric items. Retest applied/verified states require operator evidence references; no automatic recovery/notification. Cloud handoff exports selected synthetic report/workflow summaries in neutral JSON/Markdown with inherited handling, review-state and checksums. The operator chooses the external system and transfer outside this application; real-data/cloud authorization remains external.

## Alternatives and limits

Use standard-library JSON and files instead of database/server: sufficient for a small team, portable and easy to inspect. Explicit revisions/locks/conflicts avoid accidental lost updates. A central live collaboration service and new claim allocator were excluded. Existing owner records can age/release/transfer; no new target locking.

Use existing renderer with a small appendix hook instead of duplicate PDF engine. Keep native formats and automatic source parsing excluded. Use manual efficiency metrics instead of excluded drills/telemetry; search-miss fields may be entered by a person, but searches do not collect them automatically. UI evaluation may measure passive operations and compare task paths; it does not claim controlled participant time-saving evidence or implement a browser server.

Runtime acceptance: verify synthetic paths on this Windows preparation host. Linux-specific process-group behavior should be checked where a runtime is available; otherwise name the gap. Actual targets, client evidence, event hosts and a cloud service are not used. No report/download/inventory success is treated as event approval.

## Reconciled requirement mapping

| Requirement | Current delivery path / removed portions |
| --- | --- |
| FR-DF-001 | All 120 user dispositions retained; scope matrix and request priorities. |
| FR-DF-002 | Live catalog view/owner overlay/cards/readiness. No new artifact inventory. |
| FR-DF-003 | Search/filter/aliases; saved lists and automatic miss telemetry excluded. |
| FR-DF-004 | Task chooser and explainable comparisons; no inferred customer scope. |
| FR-DF-005 | Per-tool next actions and troubleshooting; new global offline index excluded. |
| FR-DF-006 | Owner/backup/reviewer, intake/reuse/alternatives/version comparison; retirement checklist excluded. |
| FR-DF-007 | Request/decision/status/review/shift handoff records; new editing-slot record and action queues excluded. |
| FR-DF-008 | General tool scaffold/metadata/helpers/walkthrough; adapter scaffold and contributor fixture kit excluded. |
| FR-DF-009 | Change-relevant, compatibility, known-answer, secret and link checks; combined command/broad fixture suite/new CI excluded. |
| FR-DF-010 | Existing report schema compatibility and local run/hash records; native/common envelope and global ID scheme excluded. |
| FR-DF-011 | Excluded native adapter slice; existing report import preview only. |
| FR-DF-012 | Separate discovery metadata/preview/troubleshooting. Legacy scanner remediation beyond chosen outcomes remains outside this delivery; defects not claimed fixed. |
| FR-DF-013 | Existing installer/reference inventory reused, no new acquisition/inventory initiative. |
| FR-DF-014 | Platform matrix and passive preflight. Clean-image rehearsal excluded. |
| FR-DF-015 | Public-content preview, preparation ZIP/reviewer packet/previous release; freeze checklist/staging study excluded. |
| FR-DF-016 | Revalidate supplied plans and discovered/approved separation; new scope-profile framework deferred. |
| FR-DF-017 | Offline manually authored plan preview; typed execution profiles excluded. |
| FR-DF-018 | Synthetic process supervision/stop only; new operation budget enforcement excluded. Existing runners unchanged. |
| FR-DF-019 | Manual run and stage log, cancellation, explicit resume and run appendix; no target dispatch. |
| FR-DF-020 | Revision conflicts and existing-owner aging/release/transfer, duplicate import, handoff. New claims/coverage/action queues excluded. |
| FR-DF-021 | Distinct source/export hashes and explicit integrity check; full evidence inventory/traceability graph excluded. |
| FR-DF-022 | Structured minimal log, tool identity, size bounds and partial state; closed field allowlist initiative excluded. |
| FR-DF-023 | Synthetic-only, handling inheritance/custodian metadata. Actual client/cloud handling approval remains external. |
| FR-DF-024 | Human review/deterministic suggestions/reversible merge/prefill/remediation tracking; local AI replaced by cloud handoff. |
| FR-DF-025 | Snapshots/diffs, shared Markdown/PDF appendix with all run statuses. |
| FR-DF-026 | Completeness/rubric/reviewer checks, evidence integrity/retest; submission rehearsal excluded. |
| FR-DF-027 | Linked incident timeline and shift record; no automatic notification. |
| FR-DF-028 | Manual multidimensional metrics; resource study deferred, automated miss logging and timed drills excluded. |
| FR-DF-029 | CLI help/links for implemented paths; global offline reference index/snapshots excluded. |
| FR-DF-030 | Linked text/status export with distinct acceptance and staleness; coverage view/role queues excluded. |
| FR-DF-031 | Excluded practice/simulator/drill initiatives; meaningful verification of delivered behavior still performed. |
| FR-DF-032 | Conflict-safe state, deliberate resume, handoff/snapshots and previous release recovery; outage drill excluded. |
| NFR-DF-001 | Honest recorded versus verified versus approved states; no implied finding confirmation. |
| NFR-DF-002 | No socket/DNS/model/native scanner path; explicit fixed synthetic process supervision only. |
| NFR-DF-003 | Synthetic input, redacted logs, explicit package membership and handling inheritance. |
| NFR-DF-004 | Existing third-party notices/holds; no acquisition or license clearance. |
| NFR-DF-005 | Safe basic parser/path/output contracts needed by delivered code, not a new broad fixture-library product. |
| NFR-DF-006 | Existing schemas preserved, deterministic source-only packages and identity checks. |
| NFR-DF-007 | New target load budgets excluded; only own synthetic process lifecycle verified. |
| NFR-DF-008 | Plain-text/JSON interface, platform prerequisite matrix; untested actual hosts labeled. |
| NFR-DF-009 | Original speed/resource acceptance targets superseded by deferred/excluded measurements; no gain promised. |
| NFR-DF-010 | Standard library plus existing optional ReportLab; few explicit modules. |
| NFR-DF-011 | Per-adopted-idea mapping and independent review on settled bytes. |
| NFR-DF-012 | Preserve existing timestamp behavior; new clock/offset initiative and countdown/freeze feature excluded. |

All runtime/approval gaps remain visible; accepted outcomes do not revive deferred/excluded features. This reconciled design defines full delivery scope, superseding the broad Analyst acceptance for removed portions while retaining original IDs/history.
