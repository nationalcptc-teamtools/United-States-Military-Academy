# Development workbench proposal and specification

Feature amendment, 16 October 2026: application 1.2.0 includes individual tool onboarding and expanded source-package guides; workspace format 1.0.0 is unchanged. See [onboarding requirements](../../docs/tool-onboarding/spec.md). The maintenance amendment below describes the preceding 1.1.1 patch.

Current maintenance amendment, 16 October 2026: application 1.1.1 retains workspace format 1.0.0 and all original idea dispositions below. The incremental update extension already present in 1.1.0 remains; patch 1.1.1 fixes undo ID uniqueness, synthetic record declarations, target revalidation bounds, snapshot-consistent handoff and retired/Word catalog metadata. Current interfaces are in [contracts](CONTRACTS.md), with [verification](VERIFICATION.md). The dated 1.0.1 baseline below is retained history, not the current application version.

Version 1.0.1; 2026-10-15. Original preparation request: document and implement selected ideas to improve CPTC tool creation, discovery, preparation, use, logging and reporting. Priority is balanced across preparation, competition use and reporting. A decision was requested for each idea before design or implementation.

Continuation acceptance under FR-DF-009/015/025/032: the workbench can request the already integrated reporter's Word output alongside Markdown and optional PDF; all requested outputs retain identical supplied appendix facts/handling and manifest hashes. A failed optional renderer leaves no output bundle or snapshot record. Existing workspace format 1.0.0 remains editable after application upgrades; unsupported formats reject. Source bundles retain public scope/verification and the current reporter's Word tests. Project role records and continuation evidence are maintained in `Sebastian/docs/proposals/development-functions/`; executable changes stay in this root tooling layout. No idea disposition changes or new adapter/AI/target-execution scope is introduced.

All 120 ideas received explicit choices: 70 Include, 6 Defer, 44 Exclude. The later instruction removed local AI/correction and selected neutral JSON/Markdown files for manual cloud handoff. This portable record preserves stable idea IDs, observable acceptance, all 44 original requirement dispositions and external gates. Detailed private preparation history, source assessments and generated outputs are intentionally outside this source contribution. Developer/root held the sole editing slot; a separately authorized reviewer inspected read-only. Implementation and verification are complete for this synthetic local scope; user/event acceptance remains separate.

Current versus desired: the existing farm catalog/renderer lacked this surrounding workflow. Workbench 1.0.0 adds the listed local commands and artifacts, with synthetic-only inputs and manual review. Operations are metadata previews/manual records; only a fixed synthetic worker is supervised. Existing completed-report JSON is the supported import; native adapters/envelope validation are excluded. IDEA-DF-118 is superseded by the user's manual cloud-handoff instruction; no local AI or AI correction. IDEA-DF-119 authorized evaluation, fulfilled by the written CLI/browser comparison. IDEA-DF-074 uses existing capability owners rather than the excluded new claims system.

Acceptance evidence is [verification](VERIFICATION.md), [tests](tests/test_workbench.py), and the independent review summarized in VERIFICATION.md. Test names below refer to WorkbenchTests; manual/document acceptance is identified separately. Automated exercise actors are synthetic fixtures, not actual human acceptance. Actual event/client/cloud/host approvals and measured speed gains are outside these local pass criteria.

| Stable idea | User choice | Delivery / boundary | Observable evidence | Acceptance / failure behavior |
| --- | --- | --- | --- | --- |
| IDEA-DF-001 | Include | search / choose / card | test_catalog | Expected aliases and six tasks resolve; incompatible/held/not-ready entries and next actions remain visible. |
| IDEA-DF-002 | Include | search / choose / card | test_catalog | Expected aliases and six tasks resolve; incompatible/held/not-ready entries and next actions remain visible. |
| IDEA-DF-003 | Include | search / choose / card | test_catalog | Expected aliases and six tasks resolve; incompatible/held/not-ready entries and next actions remain visible. |
| IDEA-DF-004 | Include | search / choose / card | test_catalog | Expected aliases and six tasks resolve; incompatible/held/not-ready entries and next actions remain visible. |
| IDEA-DF-005 | Include | search / choose / card | test_catalog | Expected aliases and six tasks resolve; incompatible/held/not-ready entries and next actions remain visible. |
| IDEA-DF-006 | Include | compare + decision | test_catalog; test_intake_and_decisions | Comparison uses consistent fields; selected/rejected alternative and reason can be recorded. |
| IDEA-DF-007 | Include | search/card lifecycle gap from existing catalog | test_catalog | Known archived OpenDNP3 and its old spacing alias resolve to the cataloged maintained-alternative gap; no accepted replacement or full retirement inventory is invented. |
| IDEA-DF-008 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-009 | Include | search / choose / card | test_catalog | Expected aliases and six tasks resolve; incompatible/held/not-ready entries and next actions remain visible. |
| IDEA-DF-010 | Defer | Retained backlog; no implementation | Explicit user decision | Benefit/blocker/reconsideration trigger below; no readiness claim. |
| IDEA-DF-011 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-012 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-013 | Include | intake | test_intake_and_decisions; 39-command CLI exercise | Incomplete requests reject; reuse candidates, kind, dependencies and explainable priority inputs persist. |
| IDEA-DF-014 | Include | intake | test_intake_and_decisions; 39-command CLI exercise | Incomplete requests reject; reuse candidates, kind, dependencies and explainable priority inputs persist. |
| IDEA-DF-015 | Include | intake | test_intake_and_decisions; 39-command CLI exercise | Incomplete requests reject; reuse candidates, kind, dependencies and explainable priority inputs persist. |
| IDEA-DF-016 | Include | intake | test_intake_and_decisions; 39-command CLI exercise | Incomplete requests reject; reuse candidates, kind, dependencies and explainable priority inputs persist. |
| IDEA-DF-017 | Include | owner / card --workspace | test_owners_and_handling | Primary, backup and reviewer persist separately and overlay the live catalog. |
| IDEA-DF-018 | Include | decision | test_intake_and_decisions | Owned accepted/rejected/blocked/deferred decisions retain reasons; deferred work requires benefit and reconsideration trigger. |
| IDEA-DF-019 | Include | decision | test_intake_and_decisions | Owned accepted/rejected/blocked/deferred decisions retain reasons; deferred work requires benefit and reconsideration trigger. |
| IDEA-DF-020 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-021 | Defer | Retained backlog; no implementation | Explicit user decision | Benefit/blocker/reconsideration trigger below; no readiness claim. |
| IDEA-DF-022 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-023 | Include | decision | test_intake_and_decisions | Owned accepted/rejected/blocked/deferred decisions retain reasons; deferred work requires benefit and reconsideration trigger. |
| IDEA-DF-024 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-025 | Include | scaffold / check-docs | test_scaffold_and_preflight; test_help_contract_and_local_links | Generated help/version/status/owner/license/helpers exist; declaration/metadata/runbook drift is detected; unimplemented tool exits pending. |
| IDEA-DF-026 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-027 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-028 | Defer | Retained backlog; no implementation | Explicit user decision | Benefit/blocker/reconsideration trigger below; no readiness claim. |
| IDEA-DF-029 | Include | scaffold / check-docs | test_scaffold_and_preflight; test_help_contract_and_local_links | Generated help/version/status/owner/license/helpers exist; declaration/metadata/runbook drift is detected; unimplemented tool exits pending. |
| IDEA-DF-030 | Include | scaffold / check-docs | test_scaffold_and_preflight; test_help_contract_and_local_links | Generated help/version/status/owner/license/helpers exist; declaration/metadata/runbook drift is detected; unimplemented tool exits pending. |
| IDEA-DF-031 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-032 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-033 | Include | scaffold / check-docs | test_scaffold_and_preflight; test_help_contract_and_local_links | Generated help/version/status/owner/license/helpers exist; declaration/metadata/runbook drift is detected; unimplemented tool exits pending. |
| IDEA-DF-034 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-035 | Include | scaffold / check-docs | test_scaffold_and_preflight; test_help_contract_and_local_links | Generated help/version/status/owner/license/helpers exist; declaration/metadata/runbook drift is detected; unimplemented tool exits pending. |
| IDEA-DF-036 | Include | README extension walkthrough | 39-command CLI exercise; test_report_workflow | Documented reuse-to-scaffold-to-check-to-existing-report path works; native adapters remain unsupported. |
| IDEA-DF-037 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-038 | Include | select-checks | test_cli_and_metrics; README.md | Changed paths yield relevant check suggestions, integration needs and explicit omission caveat; no combined checker/CI added. |
| IDEA-DF-039 | Include | Existing reporter + live farm catalog | 36 reporter regressions; test_catalog; test_report_workflow | Existing schemas/IDs preserved; known fields, counts, statuses and imported source identity agree; unknown/native formats reject. |
| IDEA-DF-040 | Include | Existing reporter + live farm catalog | 36 reporter regressions; test_catalog; test_report_workflow | Existing schemas/IDs preserved; known fields, counts, statuses and imported source identity agree; unknown/native formats reject. |
| IDEA-DF-041 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-042 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-043 | Include | Secret scrubbing in previews/logs/handoff | test_spaced_secret_arguments_and_revalidation; test_delivery | Invented spaced/quoted/assignment secrets are absent from the checked summaries and diagnostics; no universal sensitivity claim. |
| IDEA-DF-044 | Include | check-links / check-docs | test_help_contract_and_local_links | Forty catalog/runbook IDs and checked local links resolve; deliberately broken links or declarations report inconsistency. |
| IDEA-DF-045 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-046 | Include | package + MANIFEST.json | test_delivery; settled package inspection | Exact enumerated reusable files/licenses/synthetic examples and hashes are inspectable; private workspaces are absent. |
| IDEA-DF-047 | Include | review-packet + proposal role artifacts | test_delivery; VERIFICATION.md | Source identities, requirement/idea mappings, actual checks/skips/findings/limits accompany review; supplied assertions are labeled. |
| IDEA-DF-048 | Defer | Retained backlog; no implementation | Explicit user decision | Benefit/blocker/reconsideration trigger below; no readiness claim. |
| IDEA-DF-049 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-050 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-051 | Include | platforms / preflight / card | test_scaffold_and_preflight; test_catalog | Missing prerequisites/destination/free space and separate readiness states display; tested versions remain unknown unless established. |
| IDEA-DF-052 | Include | platforms / preflight / card | test_scaffold_and_preflight; test_catalog | Missing prerequisites/destination/free space and separate readiness states display; tested versions remain unknown unless established. |
| IDEA-DF-053 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-054 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-055 | Defer | Retained backlog; no implementation | Explicit user decision | Benefit/blocker/reconsideration trigger below; no readiness claim. |
| IDEA-DF-056 | Include | package + MANIFEST.json | test_delivery; settled package inspection | Exact enumerated reusable files/licenses/synthetic examples and hashes are inspectable; private workspaces are absent. |
| IDEA-DF-057 | Include | compare-releases + README recovery procedure | test_delivery; standalone package exercise | Deterministic bundles compare changed paths; previous reviewed bytes may be restored to a new directory after hash verification. |
| IDEA-DF-058 | Include | compare-releases + README recovery procedure | test_delivery; standalone package exercise | Deterministic bundles compare changed paths; previous reviewed bytes may be restored to a new directory after hash verification. |
| IDEA-DF-059 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-060 | Include | Eight-field card readiness view | test_catalog | All43 cards separately label cataloged/downloaded/integrity/test/review/acceptance/publication/event states; unknowns stay explicit, license review differs from tool review, no promotion framework or approval inferred. |
| IDEA-DF-061 | Defer | Retained backlog; no implementation | Explicit user decision | Benefit/blocker/reconsideration trigger below; no readiness claim. |
| IDEA-DF-062 | Include | plan / revalidate / deviation | test_operations; test_spaced_secret_arguments_and_revalidation | Discovered targets stay separate; sanitized previews do not dispatch; supplied scope/profile/target changes need reacceptance; exceptions retain reason/reference. |
| IDEA-DF-063 | Include | plan / revalidate / deviation | test_operations; test_spaced_secret_arguments_and_revalidation | Discovered targets stay separate; sanitized previews do not dispatch; supplied scope/profile/target changes need reacceptance; exceptions retain reason/reference. |
| IDEA-DF-064 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-065 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-066 | Include | simulate / cancel / resume | test_cancel_owned_worker; test_operations | Fixed synthetic worker tree stops and records cancellation; resume requires repeat/skip and executes nothing. Actual tool lifecycle remains external. |
| IDEA-DF-067 | Include | README troubleshooting/manual fallback + card operation | test_catalog; 39-command CLI exercise | Offline/active/subscription/write effects and prerequisite/import/render/manual fallback guidance are visible; no hidden target execution. |
| IDEA-DF-068 | Include | simulate / cancel / resume | test_cancel_owned_worker; test_operations | Fixed synthetic worker tree stops and records cancellation; resume requires repeat/skip and executes nothing. Actual tool lifecycle remains external. |
| IDEA-DF-069 | Include | README troubleshooting/manual fallback + card operation | test_catalog; 39-command CLI exercise | Offline/active/subscription/write effects and prerequisite/import/render/manual fallback guidance are visible; no hidden target execution. |
| IDEA-DF-070 | Include | README troubleshooting/manual fallback + card operation | test_catalog; 39-command CLI exercise | Offline/active/subscription/write effects and prerequisite/import/render/manual fallback guidance are visible; no hidden target execution. |
| IDEA-DF-071 | Include | plan / revalidate / deviation | test_operations; test_spaced_secret_arguments_and_revalidation | Discovered targets stay separate; sanitized previews do not dispatch; supplied scope/profile/target changes need reacceptance; exceptions retain reason/reference. |
| IDEA-DF-072 | Include | plan / revalidate / deviation | test_operations; test_spaced_secret_arguments_and_revalidation | Discovered targets stay separate; sanitized previews do not dispatch; supplied scope/profile/target changes need reacceptance; exceptions retain reason/reference. |
| IDEA-DF-073 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-074 | Include | transfer / status owner age | test_owners_and_handling | Existing owner records show age and revision-protected release/transfer; no target-claim allocator. |
| IDEA-DF-075 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-076 | Include | edit-note / author | test_conflicts; test_authored_markings_reach_handoff_and_conflicts | Stale edits retain both authored versions with references instead of overwriting; restrictions survive conflict. |
| IDEA-DF-077 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-078 | Include | handoff / integrity / import-report | test_delivery; test_report_workflow; 39-command CLI exercise | Synthetic handoff manifests verify explicit contents; same report bytes import idempotently; changed reused finding IDs reject. Actual transfer approval is external. |
| IDEA-DF-079 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-080 | Include | status --destination | test_cli_and_metrics; 39-command CLI exercise | Text/JSON summaries contain IDs, revisions, update/age and next action; technical/user/event states remain distinct. |
| IDEA-DF-081 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-082 | Include | HANDOVER.md | Document/link review; test_help_contract_and_local_links | Shift/cohort checklists include scope, jobs, incidents, evidence location, pending review, synthetic lessons and authority; no private material is bundled. |
| IDEA-DF-083 | Include | status --destination | test_cli_and_metrics; 39-command CLI exercise | Text/JSON summaries contain IDs, revisions, update/age and next action; technical/user/event states remain distinct. |
| IDEA-DF-084 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-085 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-086 | Include | run-record / event / bounded state | test_separate_stage_failures_reach_appendix; test_operations; test_conflicts | Stage-specific status/exit/operator/tool/scope/evidence/binary/profile/config are retained; 500-event truncation and 2 MB state bounds are visible; no raw output captured. |
| IDEA-DF-087 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-088 | Include | run-record / event / bounded state | test_separate_stage_failures_reach_appendix; test_operations; test_conflicts | Stage-specific status/exit/operator/tool/scope/evidence/binary/profile/config are retained; 500-event truncation and 2 MB state bounds are visible; no raw output captured. |
| IDEA-DF-089 | Include | preview-import / import-report / integrity | test_snapshot_status_and_integrity; test_handoff_markdown_and_large_file_integrity | Received bytes and supplied hashes remain distinct; duplicates/conflicting IDs detected; full selected file hash rejects prefix matches and reports limits. |
| IDEA-DF-090 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-091 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-092 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-093 | Include | run-record / event / bounded state | test_separate_stage_failures_reach_appendix; test_operations; test_conflicts | Stage-specific status/exit/operator/tool/scope/evidence/binary/profile/config are retained; 500-event truncation and 2 MB state bounds are visible; no raw output captured. |
| IDEA-DF-094 | Include | preview-import / import-report / integrity | test_snapshot_status_and_integrity; test_handoff_markdown_and_large_file_integrity | Received bytes and supplied hashes remain distinct; duplicates/conflicting IDs detected; full selected file hash rejects prefix matches and reports limits. |
| IDEA-DF-095 | Include | preview-import / import-report / integrity | test_snapshot_status_and_integrity; test_handoff_markdown_and_large_file_integrity | Received bytes and supplied hashes remain distinct; duplicates/conflicting IDs detected; full selected file hash rejects prefix matches and reports limits. |
| IDEA-DF-096 | Include | handling + inherited markings | test_owners_and_handling; test_authored_markings_reach_handoff_and_conflicts; PDF check | Named handling decision refs persist; import/author/conflict/incident/retest restrictions combine in status/handoff/reports. |
| IDEA-DF-097 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-098 | Include | preview-import / review / duplicates / merge / undo-merge / prefill / author | test_report_workflow | Preview exposes count/status/limits; human accept/reject gate, explainable reversible merges and author-required impact/severity/remediation/retest retain originals. |
| IDEA-DF-099 | Include | preview-import / review / duplicates / merge / undo-merge / prefill / author | test_report_workflow | Preview exposes count/status/limits; human accept/reject gate, explainable reversible merges and author-required impact/severity/remediation/retest retain originals. |
| IDEA-DF-100 | Include | preview-import / review / duplicates / merge / undo-merge / prefill / author | test_report_workflow | Preview exposes count/status/limits; human accept/reject gate, explainable reversible merges and author-required impact/severity/remediation/retest retain originals. |
| IDEA-DF-101 | Include | preview-import / review / duplicates / merge / undo-merge / prefill / author | test_report_workflow | Preview exposes count/status/limits; human accept/reject gate, explainable reversible merges and author-required impact/severity/remediation/retest retain originals. |
| IDEA-DF-102 | Include | snapshot + changes.json | test_snapshot_order_is_sequence_not_random_id; test_separate_stage_failures_reach_appendix; PDF check | New snapshots preserve all run-stage outcomes and compare latest persisted revision; fact/status/evidence/context/marking changes remain inspectable. |
| IDEA-DF-103 | Include | snapshot + changes.json | test_snapshot_order_is_sequence_not_random_id; test_separate_stage_failures_reach_appendix; PDF check | New snapshots preserve all run-stage outcomes and compare latest persisted revision; fact/status/evidence/context/marking changes remain inspectable. |
| IDEA-DF-104 | Include | complete / retest / incident | test_snapshot_status_and_integrity; test_report_workflow; PDF check | Missing author/review/rubric/CVE verification stays visible; verified fix needs supplied retest evidence; incident actions remain pending without automatic notification. |
| IDEA-DF-105 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-106 | Include | complete / retest / incident | test_snapshot_status_and_integrity; test_report_workflow; PDF check | Missing author/review/rubric/CVE verification stays visible; verified fix needs supplied retest evidence; incident actions remain pending without automatic notification. |
| IDEA-DF-107 | Include | complete / retest / incident | test_snapshot_status_and_integrity; test_report_workflow; PDF check | Missing author/review/rubric/CVE verification stays visible; verified fix needs supplied retest evidence; incident actions remain pending without automatic notification. |
| IDEA-DF-108 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-109 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-110 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-111 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-112 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-113 | Include | metric | test_cli_and_metrics | Manual records include elapsed time, misses/retyping/duplicates/corrections/errors and context; no automatic telemetry or gain claim. |
| IDEA-DF-114 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-115 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-116 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-117 | Exclude | Excluded from new delivery | Explicit user decision | No new feature commissioned; existing governing controls/artifacts preserved. |
| IDEA-DF-118 | Include | handoff (user-corrected scope) | test_delivery; 39-command CLI exercise | Preview then explicit export creates neutral synthetic JSON/Markdown with markings/hashes; no local AI/correction/API/automatic transfer. |
| IDEA-DF-119 | Include | UI-EVALUATION.md | Document review; CLI/PDF/package evidence | CLI/static-text and possible browser costs/offline/resource/usability needs compared; plain-text fallback retained; no unmeasured browser benefit asserted. |
| IDEA-DF-120 | Include | HANDOVER.md | Document/link review; test_help_contract_and_local_links | Shift/cohort checklists include scope, jobs, incidents, evidence location, pending review, synthetic lessons and authority; no private material is bundled. |

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

Synthetic-only; no network/model/target dispatch from input. JSON/state 2 MB, depth 32, event retention 500 with truncation, appendix 200 blocks, full-file integrity maximum 512 MiB. Existing destination/protected path/redirect checks and atomic state replacement protect local workflow. Failure cases include stale edits, held/missing tools, unsupported input, changed scope/profile, partial/cancelled runs, downstream failures, malformed contracts, ledger I/O failure after a complete export, seeded secrets and changed evidence. Exact behavior/limitations: [contracts](CONTRACTS.md).

No actual operator timing, clean approved event image, native tool format, real target, private storage, actual retention enforcement or cloud-system use is established. The older scanner is outside remediation here; these commands never dispatch it. Synthetic known-answer checks do not substitute for actual event acceptance. User acceptance of this product remains pending.

## Requirement dispositions



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
