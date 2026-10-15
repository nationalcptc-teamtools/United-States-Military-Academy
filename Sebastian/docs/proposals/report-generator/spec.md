# Analyst specifications

Reviewed: 2026-10-14. Current change: template-inspired reporting and farm-toolkit intake design. Existing FR/NFR IDs and prior review history are retained.

## Evidence and current state

The synthetic reporting starter v0.1.1 exists locally and in draft PR #1 at commit 5bc4c77beea8c1e505ec72c53149b4507044d975. Repository access and contribution account are verified; event applicability is separate. The October 2025 rules require report substance but do not prescribe OSCP, CVSS or PDF formatting. The vendor assessment establishes no client approval and retains an unresolved retention conflict. See [policy with page/cell anchors](../../policies/competition-and-data.md).

## Requirements and observable acceptance

| ID | Requirement | Starter acceptance / later gap |
| --- | --- | --- |
| FR-01 | Configure project profile, ownership, seven-role artifact handoffs, journal and roadmap | Linked current products; role names do not imply access or approval; original request and separate acceptance retained. |
| FR-02 | Versioned normalized report input for future script outputs | Synthetic JSON contract has report metadata, stable finding/evidence IDs, source tool/version, collector, timestamp, validation steps/status, impact, mitigation, retest plan and data marking. Invalid/duplicate data rejected without rendering. Real adapters later. |
| FR-03 | Generate editable Markdown and a professional PDF | One input produces both with the same supplied facts, severity/status counts, scope/methodology/limitations, evidence references, business impact and actionable remediation. Source text is literal; no generated vulnerability assertions. |
| FR-04 | Reviewer gate and honest uncertainty | Default draft; release requires completed reviewer metadata, confirmed findings, verified CVE applicability if any, and evidence. Candidate output cannot silently become approved. Release is a local review label, not event submission/approval. |
| FR-05 | Evidence and scoring provenance | Record tool/version, timestamps, collector, summary and optional private artifact/hash; supplied CVE/CVSS source/date/version/vector/score preserved. No score inference/recalculation or match confirmation. |
| FR-06 | Reusable report, finding and incident templates | Full authoring template includes executive priorities, methodology/rating explanation, findings index, remediation roadmap and optional appendices; finding/incident templates cover discovery/how/when, business impact, scope, remediation/retest, incident source/destination/timeline/damage/notification/cleanup. Optional full-report sections and incident template are not automatic export adapters. |
| FR-07 | Feasible accelerators and local-AI proposal boundary | Prioritized roadmap and concrete controls; local AI/cache experiments disabled/not implemented, with event/data/retention/hardware gates and deterministic fallback. |
| NFR-01 | Offline, passive, input-as-data | Generator has no network/model/tool-execution/remote fetch path, including evidence URLs. Socket-blocked smoke test passes. No target activity. |
| NFR-02 | Separate public code from derived client material | Synthetic fixtures only; output/private folders excluded by ignores; docs explain limits of ignores and synced preparation vs approved event storage. No claim that real data is authorized here. |
| NFR-03 | Useful failure behavior and reproducibility | Bounded input, duplicate IDs/JSON keys, malformed fields, invalid dates/scores, unsafe artifact paths, existing destination, and unsupported characters fail clearly without echoing source values or publishing partial artifacts. Manifest records input/output hashes and generator version. |
| NFR-04 | Provenance / review / acceptance accuracy | Source anchors, actual dated checks, independent review verdict/limits and pending user acceptance separately recorded. No invented repo state, event date, approval or test result. |
| NFR-05 | Readability on representative data | Inspect all sample PDF pages and a synthetic long-content render; Unicode handling, pagination, header/footer and evidence text remain readable. Rendering scope/limits recorded. |

## Current requirements extension

| ID | Requirement | Observable acceptance |
| --- | --- | --- |
| FR-08 | Adapt the general OSCP report structure | Markdown and PDF have a cover/metadata, contents, numbered introduction, high-level summary/recommendations, methodology, detailed findings and appendices. PDF contents show actual page numbers. Findings keep supplied status, business impact, evidence, mitigation and retest. No copied exam wording, sample targets, credentials, screenshots, logos, exploitation/persistence instructions or proof values. |
| FR-09 | Design direct farm-tool-output ingestion | Public design maps all TOOL-001–040 and existing Nmap output to native-export, producer-envelope, reference-only or hold routes. It defines run/observation/provenance contracts, explicit adapter selection, status/error/duplicate handling, metadata allowlists and human finding promotion. Native parsers and upstream tools are clearly planned rather than claimed implemented. |
| NFR-06 | Preserve compatibility and reference boundaries | Schema 1.0 remains valid with unchanged facts/review gates. Schema 1.1 adds only bounded optional objective, recommendations and methodology narratives; unknown/malformed fields fail before publication. Both renderers share ordered content. Original DOCX, prior samples, farm-toolkit artifacts and existing repo tools remain unchanged; only original code/design and synthetic fixtures enter the PR. |

Evidence: user-provided OSCP-Exam-Report.docx SHA-256 433cc1699193f7cd086df09493b0b6717829fcbc25401f9bde53c1fd459c0028, paragraph outline/section styles and table structure inspected read-only. It is a filled reference containing exam instructions and examples, not a new request or current CPTC policy. Its commands and claims must never be executed or transferred into fixtures. Native DOCX rasterization is unavailable because LibreOffice is absent; exact source layout fidelity is not claimed. New PDF output must still be rendered and visually checked.

Scope decision: implement the report format and optional authoring metadata now; deliver a concrete intake design for the researched catalog. No request is inferred to install/run the forty candidates or implement unverified native parsers. Existing synthetic-only/client-data gates remain. Screenshots stay private references; evidence embedding and raw capture ingestion remain excluded.

Open decisions: selected upstream versions and synthetic output fixtures for each adapter; license holds for PEASS/Impacket/BACpypes3; approved endpoint/storage/retention; which OT fields are approved metadata; actual event rubric/runtime. These gate adapter implementation and real data, not this format/design update.

## Exclusions and unanswered decisions

### Current extension — classification inheritance and severity provenance (2026-10-15)

User explicitly directed that all encountered data and analysis are ORCON; internal systems/methods/procedures PROPIN; employee/customer information PII; identity-theft-sensitive PII Red; finances FI. Markings may combine, apply to derived analysis, and retain the strongest restrictions on synthesis. This is a direct user instruction as well as matching Sheet1!D25; it does not approve processing real client data here.

The unchanged vendor workbook has one 51-row, five-column sheet, no hidden sheets and no drawing/media/embedded-object parts. No severity matrix, likelihood/impact axes or rating lookup was found. SHA-256 remains f7a9b3e77e0ee69410f9ebf9359e7afc443a3044da040c56ecd9029a402dd3b9. Current code uses supplied severity labels, not a workbook matrix. The matrix's location/values are an open user question; do not invent a scoring model.

| ID | Requirement | Observable acceptance |
| --- | --- | --- |
| FR-10 | Preserve inherited handling restrictions | Schema 1.2 requires structured report markings and permits additional finding/evidence markings. ORCON is mandatory at the report baseline; descendants retain ancestor restrictions, findings include their evidence, and the overall report includes every finding/evidence restriction. PII Red supersedes ordinary PII; unrelated PROPIN/FI/PII categories are retained together rather than ranked without authority. Canonical combined marking appears in Markdown, every PDF page and the manifest; finding/evidence markings remain visible. Unknown/duplicate/empty/malformed structured tags fail before publication; source metadata does not authorize disclosure or real-data processing. |
| FR-11 | Identify the actual severity method | Report explicitly states supplied business severity, matrix not configured, and no likelihood/impact scoring. CVSS remains separate supplied metadata. No source matrix is claimed until the user supplies the actual table and its interpretation is verified. |
| NFR-07 | Compatible, honest metadata handling | Existing 1.0/1.1 inputs retain facts/review behavior and are visibly labeled as legacy/unverified for structured inheritance. Recognized explicit legacy tags retain restrictions; no unknown legacy marking is silently presented as validated. New fields require 1.2. No automatic content sensitivity detection or automatic declassification; workbook/farm/source/prior-output artifacts preserved. |

Reversible interpretation: ORCON is an originator-control requirement, while PROPIN, PII and FI are overlapping categories, not a supplied total ordering. Conservatively union them; only the explicitly described PII Red sensitivity dominates PII. A client-specific hierarchy or authorized declassification process remains unresolved. All current demonstrations remain synthetic.

No scans or exploit scripts are part of this proposal. No real client-data processing, AI runtime, online CVE enrichment, PDF auto-submission, automated human approval, model training or automatic retention deletion. The generator performs no publication; the user separately authorizes updating existing PR #1 with code/design/synthetic material. Imported scoring remains supplied metadata, not certification.

The full original product still needs actual November-script adapters and event-host validation. Structured empty findings are allowed only with explicit limitations; a failed adapter must report its failure and cannot fabricate a successful empty result. Schema currently handles completed reports, not a runner or scan-job status engine.

Required future evidence: synthetic script outputs; team's repository conventions; event start/timezone and deliverables; storage/endpoint approvals and retention resolution. User's output preference and November milestone are confirmed.
