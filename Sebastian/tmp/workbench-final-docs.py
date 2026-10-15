from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
DOC = ROOT / 'docs/proposals/development-functions'
def write(name, text):
    (DOC / name).write_text(text.strip() + '\n', encoding='utf-8')

old = (DOC / 'proposal.md').read_text(encoding='utf-8')
request = old.split('## Original request\n', 1)[1].split('## Problem and intended result', 1)[0].split('Clarification received this session:', 1)[0].strip()
legacy = old.split('## Legacy and cross-proposal mappings', 1)[1].split('## Separate progress states', 1)[0].strip()
write('proposal.md', f'''# Improve development related functions

Proposal: `development-functions`; updated 2026-10-15 (America/New_York). Accountable requester: Sebastian Solberg. Root holds the sole editing slot; the authorized independent reviewer inspected read-only.

**Implementation complete for the reconciled local preparation scope; verification passed; independent code review positive. User acceptance and event/operational approval remain pending.**

The user requested the remaining role cycle and a decision about every idea before design/implementation. All 120 were explicitly answered: **70 Include, 6 Defer, 44 Exclude**, with balanced emphasis on preparation, competition use and reporting. [Decisions](decisions.md) retain every reply; [scope](scope.md) maps every idea to its delivery, evidence or exclusion. The later correction replaces local AI/correction with neutral JSON and Markdown files for manual cloud handoff. No local model or cloud transfer is implemented.

## Original request

{request}

## Current result and boundaries

The [workbench 1.0.0](../../../tooling/workbench/README.md) adds tool discovery/cards/comparison, owned capability requests and decisions, a general tool starter, passive readiness, revision-safe workflow records, manual plans/run-stage logs, a fixed synthetic cancellation example, existing-report import and human curation, immutable Markdown/PDF snapshots, handling/status/retest/incident records and reviewed source/handoff bundles. It reuses the forty-tool farm catalog and reporter schemas 1.0/1.1/1.2. Reporter 0.3.1 adds a bounded appendix API without changing ordinary CLI/schema inputs.

The original Analyst specification was broader than the chosen scope. Its IDs/history remain; the current normative disposition is [scope.md](scope.md) plus the [44-row design mapping](design.md). Native adapters/common-output validation, a new target runner, profile budgets, global evidence graph, new claim system, CI, broad drills and local AI were excluded/deferred or superseded. The static legacy defects D-DF-001–005 remain outside this delivery and are not claimed corrected. Existing farm/runner/integration work remains preserved.

All examples are synthetic. Local record/review strings and checksums do not authenticate claims or approve assessment activity. Actual tools, official hosts, client data, human team ownership, retention, event rules/rubric and downstream cloud authorization remain unresolved gates. No speed improvement is claimed: manual measurement fields exist, but controlled timing drills were excluded.

## Role products and evidence

| Product | Current artifact |
| --- | --- |
| Analyst | [Specification](spec.md), [120 ideas](ideas.md), [user decisions](decisions.md) and [current scope/acceptance](scope.md) |
| Architect | [Design](design.md): all 32 FR and 12 NFR mapped, reuse, bounds, alternatives and failure contracts |
| Planner / Tech Lead | [Tasks](tasks.md) and [execution guide](execution-guide.md) |
| Developer | [Workbench source/usage](../../../tooling/workbench/README.md), [contracts](../../../tooling/workbench/CONTRACTS.md), additive reporter API |
| Tester | [Verification](verification.md), eighteen meaningful workbench tests and existing reporter regressions, real CLI/PDF/package checks |
| Independent Reviewer | [Review](review.md), six findings resolved and independently rechecked; final document status check recorded separately |
| Delivery | [Source preparation package](../../../output/workbench/release-1.0.0/workbench-1.0.0.zip), [manifest](../../../output/workbench/release-1.0.0/MANIFEST.json), [review packet](../../../output/workbench/review-packet/review.json), [synthetic handoff](../../../output/workbench/cloud-handoff/handoff.md), [PDF example](../../../output/pdf/workbench-demo/report.pdf) |
| Project history | [Journal](../../journal.md), [workflow](../../workflow.md), [profile](../../project-profile.md), [policy](../../policies/competition-and-data.md) |

## Ownership and baseline

Root edited documentation, implementation and tests; the separately authorized reviewer wrote nothing. A 125-file preimplementation SHA-256 snapshot is retained under local tmp. Final preservation comparison is recorded in verification.md. Synced sources and AGENTS files remain unchanged. The integration checkout remains separate at `7ccc0a6bbdc3e5488f18f046610f3a271221b81a`, branch `codex/farm-toolkit-suite`; no commits, remote fetch, upload, merge or installation were performed for this proposal. Earlier integration states in the specification/journal are dated history.

## Legacy and cross-proposal mappings

{legacy}

## Separate progress and handoff

- Analysis/design/planning: complete for all explicit user dispositions, with original IDs and history retained.
- Implementation: complete for the reconciled synthetic workbench scope, including the replacement manual cloud handoff and UI evaluation.
- Verification: Windows 18/18 workbench and 36/36 reporter tests passed; Linux 17 passed/1 optional extraction skip, plus successful Linux PDF generation. A 39-command subprocess exercise, ten visually inspected PDF pages and package verification supplement tests. See exact limits/results in verification.md.
- Independent review: scoped positive code verdict; R-DF-01–06 resolved and rechecked. Final documentation identities/status are subject to the final artifact check in review.md.
- Acceptance: explicit user acceptance pending; no proposal README consolidation. Event/runtime/client/cloud/publication approvals remain separate.

Ready for user evaluation of the local preparation product. No further design questions block this scoped delivery. OD-DF-001/002/004–009 remain operational/integration gates; native-format work is excluded here, controlled performance/resource work is excluded/deferred, and local AI has been superseded. A future authorized integration can use the source bundle after eligible team ownership, content, licensing and actual event/runtime checks.
''')

spec = (DOC / 'spec.md').read_text(encoding='utf-8')
start = spec.index('## Purpose, scope and requirement conventions')
spec = '''# Development functions specification

Prepared 2026-10-15 (America/New_York); updated after all user choices and implementation. Stable original IDs: 32 FR and 12 NFR. Status/ownership: [proposal](proposal.md). Original breadth: [120 ideas](ideas.md); authoritative choices: [decisions](decisions.md).

## Current normative scope and acceptance

All 120 user decisions were explicit before design/implementation: 70 Include, 6 Defer, 44 Exclude. The later user correction removes local AI/correction and selects neutral JSON/Markdown files for manual cloud handoff. [Scope and observable acceptance](scope.md) controls this delivery; [design](design.md) reconciles every original requirement, preserving removed portions as dispositions. The historical Analyst requirements and proposed targets below are not a commitment to revive excluded/deferred features. Implementation, verification, independent review and user acceptance are tracked separately in the proposal.

The delivered product is an offline synthetic preparation workbench using existing catalog/report contracts, not a native scanner adapter or target runner. All persisted records/exports are bounded; tool/import/render failures stay distinct; claims need human review; inherited restrictions remain. Evidence and actual failure/recovery limits are in [verification](verification.md) and [review](review.md). Current delivery has no unresolved design decision; event/host/client/storage/rubric/cloud approvals remain external gates.

''' + spec[start:]
spec = spec.replace('This session delivers analysis only. The later product requirements below describe observable outcomes, not an already implemented system.', 'The following sections preserve the original Analyst baseline and broad candidate outcomes. Apply the current scope reconciliation above when assessing this delivery.')
spec = spec.replace('Questions were asked early; only balanced emphasis has been answered in this session. Defaults below permit useful design without pretending approvals exist.', 'The table below preserves the original open-decision register. Current dispositions: OD-DF-003 native adapters/envelope validation excluded; OD-DF-010 controlled speed drills excluded and resource study deferred; OD-DF-011 local AI superseded by manual neutral handoff; OD-DF-012 settled by all 120 choices and the completed role plan. OD-DF-001/002/004–009 remain external operational gates, with synthetic local delivery permitted. Do not apply historical defaults that would rebuild excluded work.')
spec = spec.replace('**Ready for initial design, not ready for deployment or competition use.**', '**Historical Analyst handoff (fulfilled by design.md); actual deployment and competition use remain gated.**')
spec = spec.replace('No implementation or speed claim is established by these documents.', 'The original Analyst definitions alone establish no implementation or speed claim; current implementation evidence is linked above.')
write('spec.md', spec)

decision = (DOC / 'decisions.md').read_text(encoding='utf-8')
decision = decision.replace('- Design/planning: now authorized after scope reconciliation; implementation not yet started.', '- Design/planning/implementation: completed for reconciled synthetic preparation scope; verification/review in linked proposal. User acceptance remains pending.')
decision += '''

## Final clarification and execution record

After all batches, the user explicitly corrected IDEA-DF-118: "Actually, no local AI or AI correction. We will pass off to a cloud based system." The next reply selected "Neutral JSON and Markdown files". Include remains the historical disposition; its implementation is now a manual synthetic handoff, with no AI runtime, inference, correction, API or upload. IDEA-DF-119 is fulfilled by the CLI/browser evaluation and retained plain-text path, not an assumed browser build. IDEA-DF-074 applies to aging/release/transfer of existing owner records; the excluded IDEA-DF-073 claim allocator was not added.

The user authorized an independent read-only reviewer. Root retained editing throughout. See scope.md for every outcome and design.md for all original requirement dispositions. No further idea question remains unanswered; acceptance and operational approvals are distinct.
'''
write('decisions.md', decision)

# Every accepted idea receives a concrete command/doc and an observable acceptance check.
groups = [
([1,2,3,4,5,7,9], 'search / choose / card', 'test_catalog', 'Expected aliases and six tasks resolve; incompatible/held/not-ready entries and next actions remain visible.'),
([6], 'compare + decision', 'test_catalog; test_intake_and_decisions', 'Comparison uses consistent fields; selected/rejected alternative and reason can be recorded.'),
([13,14,15,16], 'intake', 'test_intake_and_decisions; 39-command CLI exercise', 'Incomplete requests reject; reuse candidates, kind, dependencies and explainable priority inputs persist.'),
([17], 'owner / card --workspace', 'test_owners_and_handling', 'Primary, backup and reviewer persist separately and overlay the live catalog.'),
([18,19,23], 'decision', 'test_intake_and_decisions', 'Owned accepted/rejected/blocked/deferred decisions retain reasons; deferred work requires benefit and reconsideration trigger.'),
([25,29,30,33,35], 'scaffold / check-docs', 'test_scaffold_and_preflight; test_help_contract_and_local_links', 'Generated help/version/status/owner/license/helpers exist; declaration/metadata/runbook drift is detected; unimplemented tool exits pending.'),
([36], 'README extension walkthrough', '39-command CLI exercise; test_report_workflow', 'Documented reuse-to-scaffold-to-check-to-existing-report path works; native adapters remain unsupported.'),
([38], 'select-checks', 'test_cli_and_metrics; execution-guide.md', 'Changed paths yield relevant check suggestions, integration needs and explicit omission caveat; no combined checker/CI added.'),
([39,40], 'Existing reporter + live farm catalog', '36 reporter regressions; test_catalog; test_report_workflow', 'Existing schemas/IDs preserved; known fields, counts, statuses and imported source identity agree; unknown/native formats reject.'),
([43], 'Secret scrubbing in previews/logs/handoff', 'test_spaced_secret_arguments_and_revalidation; test_delivery', 'Invented spaced/quoted/assignment secrets are absent from the checked summaries and diagnostics; no universal sensitivity claim.'),
([44], 'check-links / check-docs', 'test_help_contract_and_local_links', 'Forty catalog/runbook IDs and checked local links resolve; deliberately broken links or declarations report inconsistency.'),
([46,56], 'package + MANIFEST.json', 'test_delivery; settled package inspection', 'Exact enumerated reusable files/licenses/synthetic examples and hashes are inspectable; private workspaces are absent.'),
([47], 'review-packet + proposal role artifacts', 'test_delivery; independent review.md', 'Source identities, requirement/idea mappings, actual checks/skips/findings/limits accompany review; supplied assertions are labeled.'),
([51,52,60], 'platforms / preflight / card', 'test_scaffold_and_preflight; test_catalog', 'Missing prerequisites/destination/free space and separate readiness states display; tested versions remain unknown unless established.'),
([57,58], 'compare-releases + README recovery procedure', 'test_delivery; standalone package exercise', 'Deterministic bundles compare changed paths; previous reviewed bytes may be restored to a new directory after hash verification.'),
([62,63,71,72], 'plan / revalidate / deviation', 'test_operations; test_spaced_secret_arguments_and_revalidation', 'Discovered targets stay separate; sanitized previews do not dispatch; supplied scope/profile/target changes need reacceptance; exceptions retain reason/reference.'),
([66,68], 'simulate / cancel / resume', 'test_cancel_owned_worker; test_operations', 'Fixed synthetic worker tree stops and records cancellation; resume requires repeat/skip and executes nothing. Actual tool lifecycle remains external.'),
([67,69,70], 'README troubleshooting/manual fallback + card operation', 'test_catalog; 39-command CLI exercise', 'Offline/active/subscription/write effects and prerequisite/import/render/manual fallback guidance are visible; no hidden target execution.'),
([74], 'transfer / status owner age', 'test_owners_and_handling', 'Existing owner records show age and revision-protected release/transfer; no target-claim allocator.'),
([76], 'edit-note / author', 'test_conflicts; test_authored_markings_reach_handoff_and_conflicts', 'Stale edits retain both authored versions with references instead of overwriting; restrictions survive conflict.'),
([78], 'handoff / integrity / import-report', 'test_delivery; test_report_workflow; 39-command CLI exercise', 'Synthetic handoff manifests verify explicit contents; same report bytes import idempotently; changed reused finding IDs reject. Actual transfer approval is external.'),
([80,83], 'status --destination', 'test_cli_and_metrics; 39-command CLI exercise', 'Text/JSON summaries contain IDs, revisions, update/age and next action; technical/user/event states remain distinct.'),
([82,120], 'HANDOVER.md', 'Document/link review; test_help_contract_and_local_links', 'Shift/cohort checklists include scope, jobs, incidents, evidence location, pending review, synthetic lessons and authority; no private material is bundled.'),
([86,88,93], 'run-record / event / bounded state', 'test_separate_stage_failures_reach_appendix; test_operations; test_conflicts', 'Stage-specific status/exit/operator/tool/scope/evidence/binary/profile/config are retained; 500-event truncation and 2 MB state bounds are visible; no raw output captured.'),
([89,94,95], 'preview-import / import-report / integrity', 'test_snapshot_status_and_integrity; test_handoff_markdown_and_large_file_integrity', 'Received bytes and supplied hashes remain distinct; duplicates/conflicting IDs detected; full selected file hash rejects prefix matches and reports limits.'),
([96], 'handling + inherited markings', 'test_owners_and_handling; test_authored_markings_reach_handoff_and_conflicts; PDF check', 'Named handling decision refs persist; import/author/conflict/incident/retest restrictions combine in status/handoff/reports.'),
([98,99,100,101], 'preview-import / review / duplicates / merge / undo-merge / prefill / author', 'test_report_workflow', 'Preview exposes count/status/limits; human accept/reject gate, explainable reversible merges and author-required impact/severity/remediation/retest retain originals.'),
([102,103], 'snapshot + changes.json', 'test_snapshot_order_is_sequence_not_random_id; test_separate_stage_failures_reach_appendix; PDF check', 'New snapshots preserve all run-stage outcomes and compare latest persisted revision; fact/status/evidence/context/marking changes remain inspectable.'),
([104,106,107], 'complete / retest / incident', 'test_snapshot_status_and_integrity; test_report_workflow; PDF check', 'Missing author/review/rubric/CVE verification stays visible; verified fix needs supplied retest evidence; incident actions remain pending without automatic notification.'),
([113], 'metric', 'test_cli_and_metrics', 'Manual records include elapsed time, misses/retyping/duplicates/corrections/errors and context; no automatic telemetry or gain claim.'),
([118], 'handoff (user-corrected scope)', 'test_delivery; 39-command CLI exercise', 'Preview then explicit export creates neutral synthetic JSON/Markdown with markings/hashes; no local AI/correction/API/automatic transfer.'),
([119], 'UI-EVALUATION.md', 'Document review; CLI/PDF/package evidence', 'CLI/static-text and possible browser costs/offline/resource/usability needs compared; plain-text fallback retained; no unmeasured browser benefit asserted.'),
]
mapping = {}
for ids, delivery, evidence, acceptance in groups:
    for number in ids:
        assert number not in mapping, number
        mapping[number] = (delivery, evidence, acceptance)
rows = []
for line in decision.splitlines():
    if re.match(r'^\| IDEA-DF-\d{3} \|', line):
        cells = [cell.strip() for cell in line.split('|')[1:-1]]
        number = int(cells[0].split('-')[-1])
        if cells[2] == 'Include':
            delivery, evidence, acceptance = mapping.pop(number)
        elif cells[2] == 'Defer':
            delivery, evidence, acceptance = ('Retained backlog; no implementation', 'Explicit user decision', 'Benefit/blocker/reconsideration trigger below; no readiness claim.')
        else:
            delivery, evidence, acceptance = ('Excluded from new delivery', 'Explicit user decision', 'No new feature commissioned; existing governing controls/artifacts preserved.')
        rows.append(f'| {cells[0]} | {cells[2]} | {delivery} | {evidence} | {acceptance} |')
assert not mapping, mapping
assert len(rows) == 120
write('scope.md', '''# Settled scope and observable acceptance

2026-10-15. Normative reconciliation after all explicit replies: 70 Include, 6 Defer, 44 Exclude. Root editor. [User evidence](decisions.md) retains original wording; [design](design.md) maps all 44 original requirements. This table identifies the implemented observable contract for every retained idea; removed original requirement portions are not hidden prerequisites. Stable IDs are unchanged.

Current versus desired: the existing farm catalog/renderer lacked this surrounding workflow. Workbench 1.0.0 adds the listed local commands and artifacts, with synthetic-only inputs and manual review. Operations are metadata previews/manual records; only a fixed synthetic worker is supervised. Existing completed-report JSON is the supported import; native adapters/envelope validation are excluded. IDEA-DF-118 is superseded by the user's manual cloud-handoff instruction; no local AI or AI correction. IDEA-DF-119 authorized evaluation, fulfilled by the written CLI/browser comparison. IDEA-DF-074 uses existing capability owners rather than the excluded new claims system.

Acceptance evidence is [verification](verification.md), [tests](../../../tooling/workbench/tests/test_workbench.py), and [independent review](review.md). Test names below refer to WorkbenchTests; manual/document acceptance is identified separately. Automated exercise actors are synthetic fixtures, not actual human acceptance. Actual event/client/cloud/host approvals and measured speed gains are outside these local pass criteria.

| Stable idea | User choice | Delivery / boundary | Observable evidence | Acceptance / failure behavior |
| --- | --- | --- | --- | --- |
''' + '\n'.join(rows) + '''

## Deferred ideas

Requester/development lead owns reconsideration; none is required for current completion.

| ID | Retained benefit | Current blocker | Reconsideration trigger |
| --- | --- | --- | --- |
| IDEA-DF-010 | Show evidence age and unsupported capabilities systematically | User deferred; no agreed evidence freshness policy | User requests it and supplies freshness/unsupported taxonomy |
| IDEA-DF-021 | Short starter tasks for small sessions | User deferred; task capacity/owners unknown | Named session owner selects bounded starter tasks |
| IDEA-DF-028 | Consistent wrapper configuration examples | User deferred; typed wrapper contract unselected | Accepted wrapper/configuration proposal exists |
| IDEA-DF-048 | Per-defect reusable fixture library | User deferred the product initiative | Maintainer requests a library with maintenance ownership |
| IDEA-DF-055 | Quantify setup/startup/memory/disk/output costs | User deferred resource study | Approved benchmark host/workloads and measurement owner chosen |
| IDEA-DF-061 | Enforce current approved/excluded engagement profiles | User deferred scope-profile framework | Actual authorized profile/SOW/runtime owner and execution proposal available |

## Quality and remaining gates

Synthetic-only; no network/model/target dispatch from input. JSON/state 2 MB, depth 32, event retention 500 with truncation, appendix 200 blocks, full-file integrity maximum 512 MiB. Existing destination/protected path/redirect checks and atomic state replacement protect local workflow. Failure cases include stale edits, held/missing tools, unsupported input, changed scope/profile, partial/cancelled runs, downstream failures, malformed contracts, ledger I/O failure after a complete export, seeded secrets and changed evidence. Exact behavior/limitations: [contracts](../../../tooling/workbench/CONTRACTS.md).

No actual operator timing, clean approved event image, native tool format, real target, private storage, actual retention enforcement or cloud-system use is established. Existing legacy scanner defects remain listed in spec.md and are outside remediation here. Synthetic known-answer checks do not substitute for actual event acceptance. User acceptance of this product remains pending.
''')
print('Updated proposal, specification, decision clarification and 120-row scope map')
