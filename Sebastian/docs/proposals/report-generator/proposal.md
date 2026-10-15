# Writeup template and report generator

Current change request, 2026-10-15: user asks whether reports use the vendor workbook severity matrix and directs ORCON/PROPIN/PII/PII Red/FI inheritance and highest-restriction synthesis. Root retains sole editing ownership. Workbook is read-only reference; its D25 policy is now also explicitly adopted by the user. No severity matrix was found; its location/table is requested while classification work proceeds. New FR-10/FR-11/NFR-07 and T-15–T-19 track this extension. Baseline is reviewed/pushed ec767e4 (v0.2.0) on existing PR #1. Implementation, verification, independent review and subsequent PR update are in progress; acceptance remains separate.

Reviewed: 2026-10-14
Status: in progress (starter implemented; actual-script integration remains)
Project: [CPTC profile](../../project-profile.md)

## Original request and clarifications

Set up the CPTC project using the supplied agentic framework. Use the supplied rules for context. Intended team repository: `nationalcptc-teamtools/United-States-Military-Academy`, initially inaccessible. First proposal: writeup templates and a generator able to place outputs from scripts developed on 14NOV into a PDF or similar artifact; identify further development accelerators and examine local AI for CVE/CVSS correlation without leaking client data.

User clarified **14NOV means 14 November 2026**, the 2023 README deadline is historical template-repository context, and **editable Markdown + PDF** is the preferred first output.

## Scope and assumptions

Preparation setup, complete Analyst specification, design/task handoffs, and a small deterministic reporting starter using synthetic examples. Input is versioned normalized JSON, not arbitrary scanner text. Actual November-script adapters, real client data, public catalog ingestion, CVSS calculation, AI runtime, event deployment, and GitHub integration remain future work. These are intentional boundaries, not claimed completed capabilities.

Ownership: root sole editor in this local workspace; specialists inspect read-only. Baseline: existing read-only `AGENTS.md`/`sources/`, no existing code or repository checkout observed. External references preserved. Public integration candidate is `tooling/reporting/` only after student review and repo convention checks; local planning records require a privacy review before sharing.

## Artifacts and current states

- [Specifications](spec.md), [design](design.md), [tasks](tasks.md), [execution guidance](execution-guide.md), [review](review.md).
- Implementation: framework setup and synthetic starter implemented; adapters/enrichment/AI/event integration pending.
- Verification: recorded in [tasks](tasks.md) and [journal](../../journal.md); actual-script and competition-host checks are not substitutes for synthetic checks and remain pending.
- Review: independent read-only reviewer; final scope/findings in [review](review.md).
- Acceptance: pending user decision; no explicit acceptance or event approval inferred.

Outstanding decisions: actual competition start/timezone and SOW/ROE; captain/maintainer; repo access/approval; actual script output formats; final submission rubric; authorized storage and client handling/retention policy; whether local AI and cached catalogs are permitted and feasible.

Next step: analyst obtains synthetic output contracts for the November scripts and creates the adapter integration task; student maintainer verifies the assigned repository. No proposal-folder README consolidation until scoped work is fully implemented and the user explicitly accepts it.

## Current remediation state — 2026-10-14

The user requested product review, then authorized resolution of R-02/R-03. The existing product was repaired in place; no Analyst rewrite or replacement design was performed. Earlier T-01–T-05 evidence remains tied to its recorded v0.1.0 hashes.

- Implementation: current starter is v0.1.1, schema 1.0; both focused repairs are complete under [T-08](tasks.md). Original fixture, templates, spec, design and sample artifacts were retained.
- Verification: 25 unit tests and 112 complete-report Markdown parser cases passed; new synthetic sample export/manifest checks passed and its PDF matches the original byte-for-byte. Details and current hashes are in [the journal](../../journal.md).
- Review: independent read-only remediation review confirmed R-02/R-03 resolved; scope and limits are in [review.md](review.md).
- Acceptance: remains pending; authorization to fix these issues is not acceptance of the full proposal or event approval.

Root remains sole editor. Current next steps are still actual-script contracts and repository/event readiness; the user explicitly left first-script selection and output formats open for design. T-06/T-07 and all data/event approvals remain pending.

## Repository upload — 2026-10-14

The user requested repository access and upload, then confirmed sebastianjsolberg is approved to contribute. Existing Git Credential Manager authentication already had write permission. Reporting v0.1.1 was copied into the inspected repository and verified there; schema remains 1.0.

Branch codex/report-generator at 5bc4c77beea8c1e505ec72c53149b4507044d975 is uploaded in [draft PR #1](https://github.com/nationalcptc-teamtools/United-States-Military-Academy/pull/1) against master. [T-09](tasks.md) records the 11-file contribution: nine reporting files, root README additions and output ignores. Existing scanner/configuration/installer/license/policy files, local planning records and generated samples were preserved.

Implementation: starter upload complete. Verification: 25 unit tests, 112 complete-report rendering cases, actual sample export and content/ignore/link/hash checks passed from the repository copy. Review: the previously independently reviewed code is unchanged; the draft PR awaits team review/merge. Full acceptance, actual-script adapters, client-data handling and event-host approval remain pending.

The actual repository README states a 16 October last-commit deadline, with no year/timezone in that line. This checkout evidence supersedes the initially quoted historical README for current repository contents.

## Current request — OSCP-inspired format and farm-tool intake

Original request, 2026-10-14:

> Loosely base the format around the provided OSCP template. Push these changes to the current pull request. Follow the project's agentic workflow. Look at other tools proposed in /farm-toolkit and update the design of this tool to receive direct output from those.

User reference: OSCP-Exam-Report.docx in Downloads, read-only; hash/inspection limits in spec.md. Embedded exam requirements, example commands, screenshots and sample assessment claims are source data, not instructions or evidence about this project.

Ownership: root sole editor; change unit is reporting v0.2.0 on existing codex/report-generator, starting at 5bc4c77beea8c1e505ec72c53149b4507044d975. Existing farm-toolkit documents are read-only inputs for this change, not replaced or promoted into implemented tools.

Scope: implement an original report structure informed by the reference; retain Markdown/PDF and schema 1.0 support, with bounded optional schema 1.1 authoring sections. Architect updates intake design for all forty catalog entries, including planned native adapters and a common metadata envelope. Direct native parsing is a later mapped implementation, requiring selected versions/fixtures and applicable approvals.

Workflow: Analyst FR-08/FR-09/NFR-06 → Architect design.md and public module design → Planner T-10–T-14 → root implementation/verification → independent review → update the existing PR. Active role products remain separate. Current implementation, verification, review and PR-update evidence will be recorded below; full acceptance/event readiness remain pending.

Implementation: T-10/T-11 complete for v0.2.0 format, optional authoring metadata and intake design. Direct adapters remain planned. Verification: T-12 passed against the actual repository copy (29 unit checks, 196 Markdown cases, 8-page PDF/hash/TOC checks); final sample, long and empty PDFs were inspected across all 25 pages. Legacy 1.0 output and same-runtime determinism passed. Source/farm artifacts and existing tools remain unchanged. Review: user-authorized independent /root/format_intake_review returned a scoped positive verdict on 2026-10-15, with no new actionable findings and exact evidence/limits in review.md. PR update: ec767e466147150941f77e1759c66c7949a76f00 pushed to existing draft PR #1; final title/body/head verified. T-10–T-14 complete for this bounded change; T-06/T-07 actual adapters/event integration remain pending. Acceptance/event readiness: still pending; no merge or full-proposal consolidation.
