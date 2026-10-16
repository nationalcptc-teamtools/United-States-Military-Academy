# Improve development related functions

## Integration continuation — 2026-10-15

User direction: "Continue with implementation. Push all changes to the repo in Sebastian/ and relevant changes directly to tools." Clarification: "Finish integration and publish the full records (recommended)." This is integration of the accepted scope; all 120 idea choices remain unchanged (70 Include, 6 Defer, 44 Exclude), and no local AI/correction or target execution is introduced.

The latest published base `6c8ec1d2b0f7bc13b62452fafdac45e1cb92e031` already contains the complete 615-entry project snapshot and reporter 0.4.1 with optional Word. Root preserved that work and found two bounded integration gaps: workbench snapshots could not select Word, and source bundles omitted its seven regression tests. Workbench 1.0.1 connects the existing renderer, includes the current public records/tests in releases, and retains workspace format 1.0.0 independently of application version. The reporter, farm toolkit, installer and operational runners remain unchanged from that base.

Root owns editing; independent agents inspected read-only. Implementation, Windows checks and scoped independent code review are complete. Full role records, [machine evidence](../../../evidence/development-functions/continuation-checks.json), [source release](../../../releases/workbench-1.0.1/workbench-1.0.1.zip) and the incremental [publication manifest](../../../CONTINUATION-FILES.json) live under Sebastian/. Current executable products remain in [root tooling](../../../../tooling/workbench/README.md). Original PROJECT-FILES.json and historical integration/tmp/output copies are preserved as the original snapshot, not overwritten with stale local files. User acceptance/event/runtime/client/cloud gates remain distinct.

Proposal: `development-functions`; updated 2026-10-15 (America/New_York). Accountable requester: Sebastian Solberg. Root holds the sole editing slot; the authorized independent reviewer inspected read-only.

**Implementation complete for the reconciled local preparation scope; verification passed; independent code review positive. User acceptance and event/operational approval remain pending.**

Publication follow-up, 2026-10-15: the user explicitly requested "Commit and push to the repo". The reusable implementation, portable public specification/verification, tests and navigation are committed and pushed as [6e22cbb](https://github.com/nationalcptc-teamtools/United-States-Military-Academy/commit/6e22cbb43269825dc8456336a95eba403f24ff90) on `codex/development-workbench`. This supersedes earlier local-only publication statements for these public files. Generated reports, workspaces and private preparation records remain local. No pull request or merge was performed in this follow-up; user/event acceptance remains separate.

The user requested the remaining role cycle and a decision about every idea before design/implementation. All 120 were explicitly answered: **70 Include, 6 Defer, 44 Exclude**, with balanced emphasis on preparation, competition use and reporting. [Decisions](decisions.md) retain every reply; [scope](scope.md) maps every idea to its delivery, evidence or exclusion. The later correction replaces local AI/correction with neutral JSON and Markdown files for manual cloud handoff. No local model or cloud transfer is implemented.

## Original request

> You are the Analyst for project CPTC, proposal improve development related functions. Document as many ideas as possible to increase the speed and efficiency for tooling creation and finding in preparation of the competition, as well as use of the tools, including application, logging, and reporting.
>
> Apply the common role contract in the project-neutral agentic workflow.
> Inspect the request, relevant existing work, source evidence, constraints,
> and known defects. Distinguish current conditions from the desired result.
> Clarify material ambiguities; record reversible assumptions and exclusions.
>
> Produce spec.md with stable requirement IDs and observable acceptance criteria.
> Include quality constraints, relevant failure cases, boundaries, evidence,
> and unresolved decisions. Initialize or update proposal.md with the original
> request, status, ownership, artifact links, and any legacy mappings.
>
> Architect will turn the proposal and specifications into design.md.
> Give Architect enough evidence and constraints to make design decisions.
> Report readiness for design and remaining questions. Save only while you
> own the editing slot; otherwise return proposed content to the editor.

## Current result and boundaries

The [workbench 1.0.0](../../../../tooling/workbench/README.md) adds tool discovery/cards/comparison, owned capability requests and decisions, a general tool starter, passive readiness, revision-safe workflow records, manual plans/run-stage logs, a fixed synthetic cancellation example, existing-report import and human curation, immutable Markdown/PDF snapshots, handling/status/retest/incident records and reviewed source/handoff bundles. It reuses the forty-tool farm catalog and reporter schemas 1.0/1.1/1.2. Reporter 0.3.1 adds a bounded appendix API without changing ordinary CLI/schema inputs.

The original Analyst specification was broader than the chosen scope. Its IDs/history remain; the current normative disposition is [scope.md](scope.md) plus the [44-row design mapping](design.md). Native adapters/common-output validation, a new target runner, profile budgets, global evidence graph, new claim system, CI, broad drills and local AI were excluded/deferred or superseded. The static legacy defects D-DF-001–005 remain outside this delivery and are not claimed corrected. Existing farm/runner/integration work remains preserved.

All examples are synthetic. Local record/review strings and checksums do not authenticate claims or approve assessment activity. Actual tools, official hosts, client data, human team ownership, retention, event rules/rubric and downstream cloud authorization remain unresolved gates. No speed improvement is claimed: manual measurement fields exist, but controlled timing drills were excluded.

## Role products and evidence

| Product | Current artifact |
| --- | --- |
| Analyst | [Specification](spec.md), [120 ideas](ideas.md), [user decisions](decisions.md) and [current scope/acceptance](scope.md) |
| Architect | [Design](design.md): all 32 FR and 12 NFR mapped, reuse, bounds, alternatives and failure contracts |
| Planner / Tech Lead | [Tasks](tasks.md) and [execution guide](execution-guide.md) |
| Developer | [Workbench source/usage](../../../../tooling/workbench/README.md), [contracts](../../../../tooling/workbench/CONTRACTS.md), additive reporter API |
| Tester | [Verification](verification.md), eighteen meaningful workbench tests and existing reporter regressions, real CLI/PDF/package checks |
| Independent Reviewer | [Review](review.md), six findings resolved and independently rechecked; final document status check recorded separately |
| Delivery | [Source preparation package](../../../output/workbench/release-1.0.0-settled/workbench-1.0.0.zip), [manifest](../../../output/workbench/release-1.0.0-settled/MANIFEST.json), [review packet](../../../output/workbench/review-packet-settled/review.json), [synthetic handoff](../../../output/workbench/cloud-handoff/handoff.md), [PDF example](../../../output/pdf/workbench-demo/report.pdf) |
| Project history | [Journal](../../journal.md), [workflow](../../workflow.md), [profile](../../project-profile.md), [policy](../../policies/competition-and-data.md) |

## Ownership and baseline

Root edited documentation, implementation and tests; the separately authorized reviewer wrote nothing. A 125-file preimplementation SHA-256 snapshot is retained under local tmp. Final preservation comparison is recorded in verification.md. Synced sources and AGENTS files remain unchanged. The integration checkout remains separate at `7ccc0a6bbdc3e5488f18f046610f3a271221b81a`, branch `codex/farm-toolkit-suite`; no commits, remote fetch, upload, merge or installation were performed for this proposal. Earlier integration states in the specification/journal are dated history.

## Legacy and cross-proposal mappings

| Existing artifact / IDs | Relationship to this proposal |
| --- | --- |
| [Reporting proposal](../report-generator/proposal.md) and [specification](../report-generator/spec.md), baseline `FR-01`–`FR-09` / `NFR-01`–`NFR-06`, subsequent `FR-10/11` / `NFR-07` | Reuse renderer, templates, provenance/review gates and planned intake; reconcile working schema 1.2 inherited markings and explicit severity-method limits. `FR-DF-010/011/023/024/025/026` address integration; original IDs and acceptance stay intact. |
| [Reporting intake design](../../../../tooling/reporting/design.md), `cptc.tool-run/1.0` | Proposed producer envelope only. Architect must reconcile it with a future run-aware report schema; current schemas 1.0/1.1 must not silently change. |
| [Farm toolkit proposal](../farm-toolkit/proposal.md), `FR-FT-001`–`FR-FT-012`, `NFR-FT-001`–`NFR-FT-007`, `TOOL-001`–`TOOL-040` | Reuse catalog IDs, holds, source/integrity/package/readiness/runbook work. `FR-DF-002/013/014/015/016` extend the surrounding workflow without declaring tools acquired or runtime accepted. |
| Farm `T-FT-09` and `OD-FT-*` | Remain original external-runtime/event gates. `OD-DF-*` reference overlapping decisions; no gate is waived or renamed. |
| Farm `FR-FT-013/014`, `T-FT-10`–`T-FT-14` | Separate subsequent suite-installer/publication work. Reuse/evaluate the working installer through that plan instead of commissioning a second installer here; actual install/review/publication evidence remains separate. |
| Reporting `R-01`–`R-03`; farm `R-FT-01`–`R-FT-03` | Resolved/rechecked history, retained as regression evidence. New static legacy observations use `D-DF-*`, not reused review IDs. |
| [Roadmap](../../roadmap.md) | This proposal expands development-speed, adapter, reporting and rehearsal opportunities. It supplements the roadmap; it does not overwrite accepted milestones or fund separate AI/enrichment experiments. |

There is no legacy artifact for this specific proposal to rename or consolidate. `FR-DF-*`, `NFR-DF-*`, `IDEA-DF-*`, `D-DF-*`, `OD-DF-*` and `A-DF-*` are stable within this proposal; removed items must be retained with a disposition rather than renumbered.

## Separate progress and handoff

- Analysis/design/planning: complete for all explicit user dispositions, with original IDs and history retained.
- Implementation: complete for the reconciled synthetic workbench scope, including the replacement manual cloud handoff and UI evaluation.
- Verification: Windows 18/18 workbench and 36/36 reporter tests passed; Linux 17 passed/1 optional extraction skip, plus successful Linux PDF generation. A 39-command subprocess exercise, ten visually inspected PDF pages and package verification supplement tests. See exact limits/results in verification.md.
- Independent review: scoped positive specification/code verdict; R-DF-01–06 and two final catalog scope cautions resolved and rechecked. Final documentation/status/link/preservation checks passed; exact attribution is in review.md.
- Acceptance: explicit user acceptance pending; no proposal README consolidation. Event/runtime/client/cloud/publication approvals remain separate.

Ready for user evaluation of the local preparation product. No further design questions block this scoped delivery. OD-DF-001/002/004–009 remain operational/integration gates; native-format work is excluded here, controlled performance/resource work is excluded/deferred, and local AI has been superseded. A future authorized integration can use the source bundle after eligible team ownership, content, licensing and actual event/runtime checks.
