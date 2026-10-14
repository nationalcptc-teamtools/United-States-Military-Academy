# [Consulting team] — Penetration testing report

Client: [client name]
Engagement ID: [stable ID]
Assessment window / timezone: [start–end and timezone]
Data marking: [inherited marking]
Document version: [version]
Status: [draft / reviewed under the agreed process]
Prepared by / reviewed by: [names, dates and review record]

## Executive summary

[State assessment purpose, scope and main result in language suitable for client leadership. Separate demonstrated access/impact from plausible consequences and unvalidated candidates.]

[Describe the few most important business risks, affected operations, and the actions that reduce them. Include useful positive observations without treating untested systems as secure.]

### Immediate priorities

| Priority | Finding IDs | Client action / owner | Proposed timing / dependencies |
| --- | --- | --- | --- |
| [priority] | [IDs] | [concrete mitigation and responsible role] | [client-agreed or explicitly proposed] |

### Assessment limits

[Time, scope, access, tool failures, sampling and untested controls. A partial or failed run is a limitation, not a clean result.]

## Engagement overview

### Authorized scope and exclusions

[SOW/ROE reference, authorized assets/services/users/testing methods, exclusions, approved changes and assessment dates. Keep the actual approval record in authorized storage.]

### Methodology

[What was performed, when, and under which constraints. Explain discovery and validation separately. List tools/versions and source references in an appendix; do not claim every planned activity was performed.]

### Risk-rating method

[Define business severity, evidence/validation status, and prioritization method. Imported CVSS severity and analyst business risk are separate. State CVSS version/source/vector/date when used and explain uncertainty.]

## Findings summary

| Finding ID | Title | Business severity | Validation status | Affected assets |
| --- | --- | --- | --- | --- |
| [ID] | [title] | [rating] | [candidate / confirmed] | [assets] |

[Reconcile counts to included findings. Unvalidated candidates remain visible; do not silently mix them with confirmed findings.]

## Validated attack narrative (when applicable)

[Explain how verified weaknesses combined to produce an observed outcome, with timeline and finding/evidence IDs. Distinguish each demonstrated step from untested possibilities. Include a diagram only if it clarifies the client's decisions.]

## Technical findings

[Repeat the finding template for each included finding: affected assets, how/when discovered, source tool/version/operator, observed evidence, validation steps/results, business impact, severity rationale, mitigation and retest. Keep private evidence references intact and exclude unnecessary secrets.]

## Remediation roadmap

[Separate immediate containment, near-term fixes and longer-term systemic improvements where useful. Use specific tasks, owners/dependencies and verification criteria. Priorities and dates must be proposed or client-agreed, not invented commitments.]

## Appendices

### Evidence register and source provenance

| Evidence ID | Finding IDs | Timestamp / timezone | Collector / tool version | Private artifact / hash | Data marking |
| --- | --- | --- | --- | --- | --- |
| [ID] | [IDs] | [time] | [source] | [reference; hash verification status] | [marking] |

[Include approved screenshots/excerpts only when authorized and necessary. A normalized summary is not the raw artifact. Document redaction and limitations without asserting that redaction declassifies the report.]

### Tested assets, tools and references

[Asset coverage, tool versions, public vulnerability/advisory references, cache snapshot/date if applicable, and unknown or not-tested areas.]

### Cleanup and retest record

[Changes made, authorized cleanup steps, remaining artifacts/actions, retest results and dates. Do not claim removal or successful remediation without verification.]

### Glossary (if useful)

[Explain terminology that the client audience needs.]

### Incident records

[Reference separately submitted incident records through the event's approved channel. Use the incident template rather than hiding disruption details inside a finding.]

---

Authoring guidance: historical CPTC reports are useful examples, not a current rubric or a source of factual findings. Adapt these sections to the event brief and client needs. This full report-authoring template includes optional sections beyond the compact JSON generator's current export; they require analyst authoring until explicitly added to the contract.
