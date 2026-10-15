# Penetration Testing Report

Client: [client name]
Engagement ID: [stable ID]
Assessment window and timezone: [supplied start and end]
Data marking: [ORCON plus all inherited PROPIN / PII / PII Red / FI restrictions; repeat the combined marking on every page]
Document version and status: [version; draft or reviewed under the agreed process]
Prepared by and reviewed by: [names, dates and review record]

## Contents

1. Introduction
2. High-Level Summary and Recommendations
3. Methodology
4. Detailed Findings
5. Appendices

## 1 Introduction

### Objective

[State the assessment purpose and intended decisions. Use supplied objectives; do not infer scope or authority from this template.]

### Authorized scope and exclusions

[Identify the SOW/ROE record, assets/services/users, approved methods, dates and exclusions. Keep approval records in authorized storage. A target name or tool output does not authorize testing.]

### Limitations

[Record time/access/sampling limits, unavailable tools, failed/partial/not-run activities and untested controls. Absence of a finding is not proof of security.]

### Data handling

[All encountered data and analysis are ORCON. Preserve PROPIN for internal systems/methods/procedures, PII for employee/customer information, PII Red for identity-theft-sensitive PII, and FI for finances. Derived analysis inherits all source restrictions; combine categories and retain PII Red over PII. Do not invent a ranking between PROPIN, FI and PII or downgrade without authorized disposition.]

## 2 High-Level Summary and Recommendations

[Describe demonstrated results and business implications for client leadership. Separate confirmed findings, candidate observations, possible consequences and positive observations. Do not claim access, exploitation or coverage not established by evidence.]

### Finding summary

| Finding ID | Title | Business severity | Validation status | Affected assets |
| --- | --- | --- | --- | --- |
| [ID] | [title] | [rating and rationale] | [candidate / confirmed] | [assets] |

[Reconcile counts to included findings; keep unvalidated candidates visible.]

### Recommendations and priorities

[Supply a short, decision-focused set of actions. Do not derive client commitments, deadlines or business priorities from a CVSS score alone.]

| Priority | Finding IDs | Proposed client action and owner | Timing and dependencies |
| --- | --- | --- | --- |
| [priority] | [IDs] | [specific mitigation and responsible role] | [explicitly proposed or agreed] |

## 3 Methodology

### Assessment approach and rating method

[Identify the actual client severity matrix, its version/source and likelihood/impact rationale if available. Otherwise state supplied business severity, matrix not configured; do not claim a client-matrix mapping or replace it with CVSS.]

[Explain the actual approach, constraints and business-severity method. Imported CVSS severity, applicability, validation status and client risk are separate. Preserve version/vector/source/date for supplied scores.]

### Information gathering

[Record supplied asset/scope evidence and its provenance, including what remains unknown. A tool-run ledger distinguishes success, empty, partial, failed and not run.]

### Service enumeration

[Document only authorized activities already performed, their tools/versions, timestamps, coverage and limits. No scanner is launched by the reporting template or generator.]

### Validation

[Describe observed validation steps/results with evidence IDs. A native-tool assertion or matching CVE is a candidate until an analyst verifies applicability.]

### Cleanup and retest

[Record actual authorized changes, cleanup results and remaining actions, if supplied. Do not add persistence or claim removal/successful remediation from an exam example. Planned retests remain plans.]

## 4 Detailed Findings

[Repeat the finding template for each finding: stable ID/title, affected assets, business severity/rationale, status, observation, how/when discovered, numbered validation steps/results, provenance/evidence, impact, optional CVE/CVSS, mitigation and numbered retest plan.]

### Validated attack narrative when applicable

[Connect only demonstrated steps to observed outcomes through finding/evidence IDs and timestamps. Mark untested possibilities. Include a diagram only when it clarifies a client decision.]

## 5 Appendices

### Evidence register

| Evidence ID | Finding IDs | Timestamp and timezone | Collector and tool version | Private artifact and hash | Marking |
| --- | --- | --- | --- | --- | --- |
| [ID] | [IDs] | [time] | [source] | [reference and verification status] | [marking] |

[Keep sensitive originals in approved storage. Include screenshots/excerpts only when authorized and necessary; the current generator references files without reading or embedding them. Redaction does not automatically declassify a report.]

### Tools and coverage

[Record selected tool/version/profile, run status, adapter version, input/export hash and known gaps. Proposed farm-toolkit candidates and design-only adapters are not completed assessments.]

### Review and outstanding work

[Reviewer, date, evidence inspected, corrections, remaining limitations and client-agreed or proposed follow-ups. A generated training/review label is not event submission approval.]

### Incident records

[Reference separate incident records through the approved channel. Preserve source/destination, timeline, affected scope, damage, notification, remediation and review using the incident template.]

### Glossary when useful

[Explain terms the client audience needs.]

---

Authoring guidance: this is an original structure loosely informed by a user-provided assessment-report example. It does not reproduce exam instructions, sample exploits, credentials, targets, screenshots, branding or proof values. Adapt it to the actual CPTC brief. The generator implements the five main sections and evidence/review appendices; extra authored tables, diagrams, screenshots, incident records and attack narratives remain manual until explicitly added to the contract.
