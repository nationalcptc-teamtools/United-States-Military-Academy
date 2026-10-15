# Development efficiency idea register

Prepared: 2026-10-15. Analyst appendix to [proposal.md](proposal.md) and [spec.md](spec.md). User priority: balanced preparation, competition use, logging and reporting.

These are **120 candidate ideas**, not implemented capabilities or authorization to use them. Distinct ideas share requirements where they serve the same outcome. The table retains Analyst recommendations; current binding user choices and conditions are recorded in [decisions.md](decisions.md). Architect must honor those choices and record resulting implementation dispositions before planning. Preserve IDs when ideas are deferred or retired. Design and implementation wait until all 120 user decisions are explicit.

Priority: **P0** initial offline/synthetic preparation slice; **P1** subsequent integrated slice with prerequisites; **P2** optional investigation. Gates: **L** local synthetic work; **V** selected versions, licenses and fixtures; **H** approved host/dependencies/lab; **S** current scope and active-operation approval; **D** data/storage/retention approval; **O** named eligible owner and event/publication decisions; **A** separate AI/enrichment approval. A gate indicates evidence needed for use/acceptance, not a request to perform that action now. `FR-DF-*` references resolve to the specification; cross-cutting `NFR-DF-*` constraints apply to every adopted idea.

## 1. Find and choose tools

| ID | Idea and intended benefit / observable check | Priority | Requirement links | Gates |
| --- | --- | --- | --- | --- |
| IDEA-DF-001 | One local entry point across farm tools, legacy scripts, reporting and development helpers; all existing stable IDs resolve without duplicate records claiming authority. | P0 | FR-DF-002, FR-DF-029 | L |
| IDEA-DF-002 | Search purpose, name and aliases so competitors can find a capability without knowing its project name; fixed query answer set verifies matches. | P0 | FR-DF-003 | L |
| IDEA-DF-003 | Combine platform/runtime/privilege/protocol/input/output filters; synthetic incompatible candidates are visibly excluded with a reason. | P0 | FR-DF-002, FR-DF-003 | L,V |
| IDEA-DF-004 | Task-oriented chooser for questions such as analyzing an existing capture or preparing service observations; six scenarios return a candidate or explicit coverage gap. | P0 | FR-DF-004 | L |
| IDEA-DF-005 | Compact tool cards show acquisition, tested version, hold, license, prerequisites and output route together; a cataloged tool cannot be mistaken for a ready tool. | P0 | FR-DF-002, FR-DF-005 | L,V |
| IDEA-DF-006 | Compare overlapping tools on the same criteria; selection records why one sufficient backend beats maintaining several redundant stacks. | P0 | FR-DF-004, FR-DF-006 | L,V |
| IDEA-DF-007 | Search aliases include retired names and common protocol terms; retired entries point to a replacement or gap rather than appearing current. | P0 | FR-DF-003, FR-DF-006 | L |
| IDEA-DF-008 | Save role/task shortlists containing IDs and filters, not copied metadata; opening a shortlist exposes current holds and changes. | P1 | FR-DF-003, FR-DF-030 | L,O |
| IDEA-DF-009 | Link the next useful action from every result: read runbook, obtain fixture, check prerequisite or review hold; a new operator completes a synthetic path without guessing. | P0 | FR-DF-005, FR-DF-029 | L |
| IDEA-DF-010 | Show unsupported capabilities and evidence age beside positive matches; a port or customer name never becomes proof of technology or scope. | P0 | FR-DF-004, FR-DF-006 | L,V |
| IDEA-DF-011 | Provide an offline documentation/reference index with checked dates; broken/missing references surface during preparation rather than during a timed operation. | P0 | FR-DF-005, FR-DF-029 | L,V |
| IDEA-DF-012 | Record failed searches in synthetic rehearsal to reveal vocabulary and coverage gaps; owned improvements follow measured misses rather than assumed needs. | P1 | FR-DF-028, FR-DF-030 | L,O |

## 2. Intake, prioritization and ownership

| ID | Idea and intended benefit / observable check | Priority | Requirement links | Gates |
| --- | --- | --- | --- | --- |
| IDEA-DF-013 | Use one short capability request describing current manual steps, user, input, output and acceptance; incomplete requests visibly lack a decision-ready state. | P0 | FR-DF-001, FR-DF-007 | L |
| IDEA-DF-014 | Search existing tools/contracts/proposals before approving new development; a duplicate synthetic request receives a reuse recommendation and evidence. | P0 | FR-DF-004, FR-DF-006 | L |
| IDEA-DF-015 | Rank opportunities by expected frequency/value, effort, risk, evidence confidence and prerequisites; retain scoring inputs and uncertainty for review. | P0 | FR-DF-001, FR-DF-028 | L,O |
| IDEA-DF-016 | Separate new tool, adapter, wrapper repair, documentation and retirement work; each request points to the relevant contract and verification path. | P0 | FR-DF-006, FR-DF-007 | L |
| IDEA-DF-017 | Name primary owner, backup and reviewer for each active capability; unowned records cannot masquerade as maintained/reviewed. | P0 | FR-DF-006, FR-DF-007 | L,O |
| IDEA-DF-018 | Keep a decision-blocker list with owner, next evidence and affected requirements; a missing event/runtime decision does not hide other useful independent work. | P0 | FR-DF-001, FR-DF-007 | L,O |
| IDEA-DF-019 | Record accepted and rejected alternatives once, then link affected proposals; later contributors can explain a decision without repeating research. | P0 | FR-DF-001, FR-DF-007 | L |
| IDEA-DF-020 | Explicit editing-slot and handoff record prevents parallel file edits; a read-only collaborator's changes remain proposals until the editor integrates them. | P0 | FR-DF-007 | L,O |
| IDEA-DF-021 | Keep small starter tasks with synthetic fixture and completion criteria for development sessions; a short session can finish a useful bounded contribution. | P0 | FR-DF-007, FR-DF-009 | L,O |
| IDEA-DF-022 | Reserve a visible repair lane for failed rehearsals and known defects; new feature intake does not conceal D-DF remediation. | P0 | FR-DF-007, FR-DF-012 | L,O |
| IDEA-DF-023 | Preserve deferred ideas with reconsideration trigger, benefit hypothesis and blocker; Architect can narrow the first slice without discarding breadth. | P0 | FR-DF-001 | L,O |
| IDEA-DF-024 | Capability handover/retirement checklist transfers owner, fixtures, known issues and fallback; departed maintainers leave no falsely supported tool. | P1 | FR-DF-006, FR-DF-007 | L,O |

## 3. Create tools and adapters faster

| ID | Idea and intended benefit / observable check | Priority | Requirement links | Gates |
| --- | --- | --- | --- | --- |
| IDEA-DF-025 | Maintain a minimal CLI/helper scaffold with help/version, typed inputs, explicit outputs and safe errors; a synthetic helper reaches its first valid fixture quickly. | P0 | FR-DF-008 | L |
| IDEA-DF-026 | Separate passive-adapter scaffold includes supported-version registry, mapping table and unsupported-format response; new parsers need no scanner runtime. | P0 | FR-DF-008, FR-DF-011 | L,V |
| IDEA-DF-027 | A common producer-envelope example lets script authors emit consistent provenance/status directly; validate it through an explicit future intake path. | P0 | FR-DF-009, FR-DF-010 | L |
| IDEA-DF-028 | Shared configuration-validation examples prevent each wrapper inventing scope/path/unknown-field behavior; seeded malformed config fails consistently. | P0 | FR-DF-008, FR-DF-012 | L |
| IDEA-DF-029 | Publish a concise error/exit/status vocabulary with copyable synthetic examples; callers can distinguish bad input, tool failure and partial output. | P0 | FR-DF-009, FR-DF-019 | L |
| IDEA-DF-030 | Reuse stable-ID, timestamp and artifact-hash helpers where appropriate; duplicated or timezone-less records fail the contract check. | P0 | FR-DF-008, FR-DF-010, FR-DF-021 | L |
| IDEA-DF-031 | Give authors a synthetic fixture contribution kit covering ordinary, empty, partial, failed and malformed exports; new integrations arrive with expected outputs. | P0 | FR-DF-009, FR-DF-011 | L,V |
| IDEA-DF-032 | Maintain a source-field-to-normalized-field worksheet; accepted/excluded counts and limitations reconcile with a known fixture. | P0 | FR-DF-010, FR-DF-011 | L,V |
| IDEA-DF-033 | Derive help/reference examples from versioned contracts or check them for drift; renamed fields cannot leave silently broken examples. | P0 | FR-DF-009, FR-DF-010, FR-DF-029 | L |
| IDEA-DF-034 | Test wrapper arguments using a stub executable/process boundary; reproduce D-DF-002 without running a scan. | P0 | FR-DF-009, FR-DF-012, FR-DF-017 | L |
| IDEA-DF-035 | Include owner/license/dependency/runbook metadata in every scaffold; a finished helper needs less repeated integration paperwork. | P0 | FR-DF-006, FR-DF-008, FR-DF-013 | L,V |
| IDEA-DF-036 | Provide a documented extension walkthrough from synthetic fixture to reviewed draft handoff; contributors can extend one module without changing unrelated tools. | P0 | FR-DF-007, FR-DF-008, FR-DF-031 | L |

## 4. Fast feedback and trustworthy review

| ID | Idea and intended benefit / observable check | Priority | Requirement links | Gates |
| --- | --- | --- | --- | --- |
| IDEA-DF-037 | One short local check covers contracts, fixtures, catalog consistency and relevant smoke checks with network blocked; failure identifies the broken outcome. | P0 | FR-DF-009, FR-DF-014 | L |
| IDEA-DF-038 | Select checks by changed contract/component while retaining affected integration checks; record why excluded checks are irrelevant rather than rerunning everything blindly. | P1 | FR-DF-007, FR-DF-009 | L,O |
| IDEA-DF-039 | Compatibility fixtures protect report 1.0/1.1 and farm v1 behavior; an accidental closed-schema extension fails before integration. | P0 | FR-DF-009, FR-DF-010 | L |
| IDEA-DF-040 | Known-answer parser outputs reconcile field/count/status preservation, not just successful parsing; ignored records cannot vanish silently. | P0 | FR-DF-009, FR-DF-011 | L,V |
| IDEA-DF-041 | Adversarial fixtures include malformed/truncated/deep/oversized input, Unicode, NUL, duplicate keys and literal markup; failures remain bounded and actionable. | P0 | FR-DF-009, FR-DF-010 | L |
| IDEA-DF-042 | Failure injection at capture/import/render stages proves a failed run never becomes clean-empty and a downstream failure never reruns the target. | P1 | FR-DF-019, FR-DF-025, FR-DF-032 | L,H |
| IDEA-DF-043 | Secret-seeded fixtures verify logs, errors and packages omit credentials/process payloads; scanning source-control ignores alone is insufficient. | P0 | FR-DF-009, FR-DF-015, FR-DF-022 | L |
| IDEA-DF-044 | Check catalog/runbook/contract links and ID consistency automatically; navigation defects surface before a competition user needs the reference. | P0 | FR-DF-002, FR-DF-029 | L |
| IDEA-DF-045 | Synthetic-only public CI mirrors the meaningful local check, with no cloud processing of client artifacts; permitted workflow and exact revision are recorded. | P1 | FR-DF-007, FR-DF-009, FR-DF-015 | L,O |
| IDEA-DF-046 | Public-file/package preview lists exact members, licenses and fixture categories before release; accidental private/derived material blocks promotion. | P0 | FR-DF-013, FR-DF-015 | L,V,O |
| IDEA-DF-047 | A settled-version review packet includes diff, hashes, requirements, actual checks, skips and limits; independent reviewer can inspect the real path efficiently. | P0 | FR-DF-007, FR-DF-015 | L,O |
| IDEA-DF-048 | Keep a small regression fixture for each resolved defect and link retests; reporting R-01–03 and farm R-FT-01–03 remain resolved history. | P0 | FR-DF-007, FR-DF-009, FR-DF-012 | L |

## 5. Prepare environments and releases

| ID | Idea and intended benefit / observable check | Priority | Requirement links | Gates |
| --- | --- | --- | --- | --- |
| IDEA-DF-049 | Separate acquisition recipe from runtime operations; discovery/preflight never downloads a package or contacts a target as a side effect. | P0 | FR-DF-013, FR-DF-014 | L,V |
| IDEA-DF-050 | Record immutable artifact/dependency inventory with actual hashes, notices and architecture; null source-byte hashes do not imply acquired bytes. | P0 | FR-DF-013, FR-DF-015 | V,O |
| IDEA-DF-051 | A per-platform readiness matrix shows runtime, native libraries, privileges/fonts/hardware and tested versions; unsupported platforms stay visible. | P0 | FR-DF-002, FR-DF-014 | L,H |
| IDEA-DF-052 | Preflight checks missing dependencies, permissions, destination and disk before dispatch; it offers an actionable gap without installation or network fallback. | P0 | FR-DF-014, FR-DF-017 | L,H |
| IDEA-DF-053 | Clean-image offline installation/use rehearsal exposes hidden developer-machine dependencies; record exact image and not-run paths honestly. | P1 | FR-DF-013, FR-DF-014, FR-DF-031 | V,H,O |
| IDEA-DF-054 | Compare permitted source/binary/cache/package staging approaches by license, size and setup time; select one only after event and resource constraints. | P1 | FR-DF-013, FR-DF-015 | V,H,O |
| IDEA-DF-055 | Measure install/startup time, peak memory/disk and output growth for the chosen subset; a bloated optional stack needs a justified benefit. | P1 | FR-DF-014, FR-DF-028 | H,V |
| IDEA-DF-056 | Produce a small allowlisted readiness bundle of code, contracts, synthetic fixtures, notices and offline help; verify exact members and repeatability. | P0 | FR-DF-015, FR-DF-029 | L,V,O |
| IDEA-DF-057 | Preserve the previous reviewed release and rollback/recovery instructions; a bad update does not force unpinned emergency acquisition. | P1 | FR-DF-006, FR-DF-015, FR-DF-032 | V,H,O |
| IDEA-DF-058 | Version-diff report identifies changed APIs, licenses, dependencies, behavior and fixtures; a release update receives proportional review/retest. | P1 | FR-DF-006, FR-DF-010, FR-DF-013 | V,O |
| IDEA-DF-059 | Freeze checklist uses confirmed event/timezone and official cutoffs, then records exact digest; missing dates cannot produce a false countdown. | P0 | FR-DF-015, FR-DF-030 | O |
| IDEA-DF-060 | Distinguish cataloged, acquired, integrity checked, tested, reviewed, accepted, published and event approved in readiness output; no single green flag hides missing gates. | P0 | FR-DF-002, FR-DF-014, FR-DF-015 | L,V,H,O |

## 6. Apply tools with less friction

| ID | Idea and intended benefit / observable check | Priority | Requirement links | Gates |
| --- | --- | --- | --- | --- |
| IDEA-DF-061 | Use scope-bound engagement profiles with explicit allowlists/exclusions; an absent or stale scope reference prevents operational dispatch. | P1 | FR-DF-016 | H,S,O |
| IDEA-DF-062 | Keep discovered asset inventory separate from approved targets; synthetic unexpected addresses remain candidates instead of expanding scan scope. | P0 | FR-DF-012, FR-DF-016 | L,S |
| IDEA-DF-063 | Offline preview shows sanitized exact plan, effects, target, budget and output destination; no process or DNS query occurs. | P0 | FR-DF-017 | L |
| IDEA-DF-064 | Approved typed profiles build structured arguments and block unreviewed option/target changes; stubbed invocation matches the reviewed plan. | P1 | FR-DF-012, FR-DF-016, FR-DF-017 | L,H,S |
| IDEA-DF-065 | Per-operation timeout/request/retry/concurrency ceilings include setup traffic; instrumentation shows limits rather than assuming reads are passive. | P1 | FR-DF-018 | H,S |
| IDEA-DF-066 | Visible stop/cancel path terminates children and records incomplete effects/artifacts; an interruption cannot be relabeled success. | P1 | FR-DF-018, FR-DF-019 | H,S |
| IDEA-DF-067 | Show a troubleshooting decision tree for missing binary, permission, authentication, unsupported output and converter failure; each leads to the correct stage recovery. | P0 | FR-DF-005, FR-DF-012, FR-DF-014 | L |
| IDEA-DF-068 | Resume interrupted work from recorded state with explicit rerun disposition; no active operation repeats automatically after a crash. | P1 | FR-DF-019, FR-DF-032 | H,S,D |
| IDEA-DF-069 | Keep a documented manual invocation/export/import fallback when wrappers are unavailable; manual runs still need the same provenance and scope record. | P1 | FR-DF-005, FR-DF-019, FR-DF-021 | H,S,D |
| IDEA-DF-070 | Operation class labels distinguish offline analysis, active query, subscription and write/control capability; search/runbooks never imply a multi-capability library is intrinsically read-only. | P0 | FR-DF-002, FR-DF-005, FR-DF-018 | L,V |
| IDEA-DF-071 | Validate plan identity again after scope/profile changes or DNS resolution according to approved policy; changed targets cannot slip through an old preview. | P1 | FR-DF-016, FR-DF-017 | H,S |
| IDEA-DF-072 | Capture deviations from a reviewed profile with reason and approval reference; undocumented exception use cannot retain the prior accepted-profile label. | P1 | FR-DF-016, FR-DF-018, FR-DF-019 | H,S,O |

## 7. Team coordination and continuity

| ID | Idea and intended benefit / observable check | Priority | Requirement links | Gates |
| --- | --- | --- | --- | --- |
| IDEA-DF-073 | Local task/target/profile claims reduce duplicate work; six synthetic operators see ownership or an explicit conflict before overlapping activity. | P1 | FR-DF-020, FR-DF-030 | L,H,O |
| IDEA-DF-074 | Stale claim age and release/transfer procedure prevent abandoned work from staying blocked indefinitely; no silent takeover of live operations. | P1 | FR-DF-020 | L,H,O |
| IDEA-DF-075 | Planned/attempted/completed coverage view shows missing, failed and not-run work separately; totals reconcile to run records. | P1 | FR-DF-019, FR-DF-030 | L,D,O |
| IDEA-DF-076 | Conflict-aware notes/curation updates preserve competing versions and editor identity; two offline edits do not overwrite one another. | P1 | FR-DF-020, FR-DF-024, FR-DF-032 | L,D |
| IDEA-DF-077 | Operator-to-reviewer handoff includes unresolved questions, evidence IDs and actual stages; reviewer can resume without verbal reconstruction. | P1 | FR-DF-007, FR-DF-021, FR-DF-024 | L,D,O |
| IDEA-DF-078 | Approved offline handoff bundle verifies hashes, IDs and duplicate imports; it uses only permitted storage/transfer routes. | P1 | FR-DF-020, FR-DF-021, FR-DF-032 | H,D,O |
| IDEA-DF-079 | Practice/backup-owner matrix identifies who has rehearsed each capability and available fallback; passing a fixture does not certify broader expertise. | P1 | FR-DF-006, FR-DF-031 | L,O |
| IDEA-DF-080 | Dashboard or text status export links each summary to records, age and next action; a browser/server is only one possible presentation. | P1 | FR-DF-030 | L,H,D,O |
| IDEA-DF-081 | Role-oriented next-action queues reduce context switching among operator, validator and report author; blocked/uncertain work remains visible. | P1 | FR-DF-020, FR-DF-024, FR-DF-030 | L,D,O |
| IDEA-DF-082 | Short shift/handoff checklist records scope changes, active jobs, incidents, evidence location and pending reviews; another authorized operator can continue safely. | P1 | FR-DF-007, FR-DF-019, FR-DF-027 | H,D,O |
| IDEA-DF-083 | Private status export distinguishes local technical completion from user/event acceptance; release or readiness claims cannot be inferred from a task checkbox. | P0 | FR-DF-007, FR-DF-015, FR-DF-030 | L,O |
| IDEA-DF-084 | Storage outage/restore drill validates approved checkpoints and conflict behavior; restored state cannot silently omit evidence or repeat target activity. | P1 | FR-DF-031, FR-DF-032 | H,D,O |

## 8. Logging and evidence

| ID | Idea and intended benefit / observable check | Priority | Requirement links | Gates |
| --- | --- | --- | --- | --- |
| IDEA-DF-085 | Stable engagement/task/run/import/observation/finding/evidence IDs make the lineage searchable; dangling or reused IDs block acceptance. | P0 | FR-DF-010, FR-DF-021 | L |
| IDEA-DF-086 | Structured stage events preserve status, exit, actor, tool/profile, scope and evidence refs; tool/import/render outcomes stay distinguishable. | P0 | FR-DF-019, FR-DF-022 | L |
| IDEA-DF-087 | Preserve timestamp offsets, elapsed duration and clock-skew limitations; filesystem times never replace missing source observation time. | P0 | FR-DF-010, FR-DF-021, FR-DF-022 | L |
| IDEA-DF-088 | Link each log/run to selected binary/profile/config identity without sensitive argument values; changed versions remain distinguishable. | P0 | FR-DF-013, FR-DF-021, FR-DF-022 | L,V |
| IDEA-DF-089 | Separate source artifact hash, received-export hash and normalized identity; avoid self-referential hashes and label supplied hashes unverified. | P0 | FR-DF-010, FR-DF-021 | L |
| IDEA-DF-090 | Closed log-field allowlists and seeded-secret cases reduce leakage while retaining actionable error codes; raw output is not dumped into diagnostics. | P0 | FR-DF-009, FR-DF-022 | L,D |
| IDEA-DF-091 | Evidence inventory links approved private originals to run/profile/operator and limitations; discovery/reporting paths do not dereference arbitrary files. | P1 | FR-DF-021, FR-DF-023 | H,D |
| IDEA-DF-092 | Record accepted/excluded/invalid/native record counts in imports; truncation, redaction and dropped unsupported records remain measurable coverage limits. | P0 | FR-DF-010, FR-DF-011, FR-DF-022 | L,V |
| IDEA-DF-093 | Bounded log/output quotas and crash-safe partial records reveal disk loss or interrupted capture; log failure cannot turn into successful absence. | P1 | FR-DF-019, FR-DF-022, FR-DF-032 | H,D |
| IDEA-DF-094 | Detect exact duplicate artifacts/imports without collapsing distinct observations; changed content under a reused ID raises a conflict. | P1 | FR-DF-020, FR-DF-021, FR-DF-024 | L,D |
| IDEA-DF-095 | Separate explicit evidence-integrity recheck from rendering; a tampered approved file is flagged before review without making the reporter open every reference. | P1 | FR-DF-021, FR-DF-026 | H,D |
| IDEA-DF-096 | Propagate data markings and keep retention/export/deletion decisions owned; sanitized summaries do not automatically lose inherited restrictions. | P1 | FR-DF-023, FR-DF-025, FR-DF-032 | H,D,O |

## 9. Reporting and professional communication

| ID | Idea and intended benefit / observable check | Priority | Requirement links | Gates |
| --- | --- | --- | --- | --- |
| IDEA-DF-097 | Implement the producer-envelope validator and one selected native metadata adapter first; versioned fixtures prove support without claiming all forty tools integrate. | P1 | FR-DF-010, FR-DF-011 | L,V |
| IDEA-DF-098 | Import preview shows records/counts/status/limitations before curation; unsupported, partial or failed input cannot silently become a complete draft. | P1 | FR-DF-011, FR-DF-024, FR-DF-025 | L,V,D |
| IDEA-DF-099 | Human validation queue separates observations from confirmed findings, with explicit accept/reject/reason and evidence linkage; no automatic promotion. | P1 | FR-DF-024 | L,D,O |
| IDEA-DF-100 | Duplicate suggestions group likely related observations while preserving all source IDs; human merge/split decisions remain reversible and attributable. | P1 | FR-DF-024 | L,D,O |
| IDEA-DF-101 | Finding draft templates prefill permitted provenance and structured observations; authors still supply/verify business impact, severity, mitigation and retest. | P1 | FR-DF-024, FR-DF-026 | L,D,O |
| IDEA-DF-102 | Run/coverage appendix renders success, empty success, partial, failed and not-run work; zero findings cannot hide a failed scan or import. | P1 | FR-DF-019, FR-DF-025 | L,D |
| IDEA-DF-103 | Incremental immutable draft snapshots and change summaries shorten review; reviewers inspect new/changed facts, evidence, statuses and limitations. | P1 | FR-DF-025, FR-DF-026 | L,D,O |
| IDEA-DF-104 | Completeness checks flag missing impact, remediation, retest, provenance, review or rubric sections; candidate CVEs cannot become verified through formatting. | P0 | FR-DF-024, FR-DF-026 | L,O |
| IDEA-DF-105 | Traceability view answers which source/run supports each claim and where it appears in the report; orphan factual references block export/review. | P1 | FR-DF-021, FR-DF-024, FR-DF-025 | L,D |
| IDEA-DF-106 | Remediation/retest tracker keeps recommended, applied and verified states separate; an unperformed retest cannot mark an issue resolved. | P1 | FR-DF-024, FR-DF-026 | L,D,O |
| IDEA-DF-107 | Linked incident timeline captures stop/containment/notification/cleanup states separately from findings; the tool never claims officials were contacted automatically. | P1 | FR-DF-027 | L,H,D,O |
| IDEA-DF-108 | Synthetic submission rehearsal checks synchronized Markdown/PDF, markings, page/content review, final owner and artifact hashes; release labeling is distinct from actual submission. | P0 | FR-DF-025, FR-DF-026, FR-DF-031 | L,O |

## 10. Training, measurement and optional assistance

| ID | Idea and intended benefit / observable check | Priority | Requirement links | Gates |
| --- | --- | --- | --- | --- |
| IDEA-DF-109 | Timed whole-workflow drills measure discovery, creation, preview, failure recovery, curation and draft handoff; compare against the recorded manual baseline. | P0 | FR-DF-028, FR-DF-031 | L,O |
| IDEA-DF-110 | Known-answer synthetic captures/exports and small protocol simulators cover representative scenarios; hardware/real-protocol gaps remain not_run. | P1 | FR-DF-009, FR-DF-011, FR-DF-031 | L,V,H |
| IDEA-DF-111 | Failure drills inject missing dependency, timeout, unsupported version, malformed export and storage loss; participants practice the correct recovery stage. | P0 | FR-DF-009, FR-DF-014, FR-DF-031 | L,H |
| IDEA-DF-112 | Rotate operator, validator and report-author roles to expose handoff friction; compare results with familiarity and assistance recorded. | P1 | FR-DF-007, FR-DF-028, FR-DF-031 | L,O |
| IDEA-DF-113 | Track search misses, retyping, duplicate work, review rework and errors as well as elapsed time; faster but incorrect results never count as improvement. | P0 | FR-DF-028 | L,O |
| IDEA-DF-114 | Post-drill retrospective turns bottlenecks into owned requirement/idea-linked changes; the next drill checks whether the fix helped. | P0 | FR-DF-001, FR-DF-028, FR-DF-031 | L,O |
| IDEA-DF-115 | Optional pinned public documentation snapshots reduce reference search time; check license, age/size and event staging before inclusion. | P2 | FR-DF-005, FR-DF-013, FR-DF-029 | V,H,O |
| IDEA-DF-116 | Optional offline public CVE snapshot lookup preserves source/update dates and match uncertainty; never send engagement context in online queries or claim exploitability from version match. | P2 | FR-DF-006, FR-DF-023, FR-DF-024 | V,H,D,O,A |
| IDEA-DF-117 | Optional approved local prose assistance proposes cited edits with human accept/reject; deterministic report generation remains the usable default. | P2 | FR-DF-023, FR-DF-024, FR-DF-025 | V,H,D,O,A |
| IDEA-DF-118 | Optional correlation/duplicate suggestions are explainable and reversible; neither model output nor imported text executes tools, confirms findings or changes permissions. | P2 | FR-DF-023, FR-DF-024 | H,D,O,A |
| IDEA-DF-119 | Evaluate proposed convenience features such as a local browser UI only against measured user benefit, offline/resource/access constraints and text fallback; a service is not assumed. | P2 | FR-DF-028, FR-DF-029, FR-DF-030 | L,H,O |
| IDEA-DF-120 | Authorized cohort handover retains synthetic lessons, retired-capability reasons and useful fixtures; private engagement content is excluded and maintenance burden is measured. | P2 | FR-DF-006, FR-DF-007, FR-DF-028 | L,D,O |

## Proposed first-slice evaluation order

First compare existing metadata/search/runbooks, scaffold/fixture checks, legacy failure remediation design, offline preflight and traceable synthetic evidence/report handoff. Establish the baseline before claiming time savings. Choose a small selected adapter subset only when versioned fixtures exist. Automated active execution, shared coordination, client-data workflows and optional assistance follow their gates; broad catalog coverage does not make them operationally accepted.

Architect should add dispositions to this register or a linked decision table, preserve every IDEA ID and record requirement mappings for adopted outcomes. Planner then schedules the chosen slice using acceptance criteria in [spec.md](spec.md). This appendix is an opportunity inventory, not a substitute for `design.md` or `tasks.md`.
