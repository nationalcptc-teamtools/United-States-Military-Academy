# Development roadmap

Reviewed: 2026-10-14. Target development session: **14 November 2026**. This is not the assumed competition start.

| Priority | Deliverable | Gate / verification |
| --- | --- | --- |
| P0 — setup / starter | Framework artifacts, evidence-based policy, finding/incident templates, normalized JSON → Markdown/PDF, synthetic tests and demo | Current preparation scope; independent review and recorded validation. |
| P1 — before 14NOV | Obtain 2–3 synthetic outputs from planned scripts; agree schema, stable IDs, timestamps, source tool/version, exit status, review status, evidence references | Use the [adapter contract](../../tooling/reporting/README.md); failed runs must remain visible and cannot become zero findings. |
| P1 — 14NOV | Implement adapters for the actual scripts; preserve original output/hash privately, normalize observations, generate draft after each run | Test success, partial output, tool failure, duplicate observations, and schema evolution on synthetic fixtures. No scanner execution by report generator. |
| P1 — report quality | Editable report authoring, screenshot handling within approved storage, duplicate suggestions, remediation/retest checklist, business-impact review, submission rehearsal | Analysts verify discovery/exploitation claims and references; report owner reviews every final artifact. |
| P2 — offline public enrichment | Explicit-CVE lookup from a hashed public catalog snapshot; product/version match candidates; preserve publication/update/cache dates, CVSS source/version/vector/score | No engagement-aware online queries; uncertain/missing data stays unknown; matching does not confirm exploitability. No new scoring formula without validated implementation. |
| P2 — optional local AI | Draft prose, suggest correlations/duplicates, summarize approved evidence with citations | Separate proposal and approved endpoint/data/retention/event/model/resource controls. Off by default. Human accepts changes. |
| P2 — development speed | Synthetic adapter fixtures, schema validation in CI, formatter/linter once team conventions known, one-command report smoke test, template library, readiness bundle | Public CI gets synthetic data only; dependencies public and reproducible; preserve team repo's existing conventions. |
| P1 — farm toolkit preparation | [Local module](../../tooling/farmkit/README.md): forty dispositions, core source references, passive integrity/readiness checks, runbooks and synthetic fixtures | Local role cycle and review in [proposal artifacts](proposals/farm-toolkit/proposal.md). Real artifact/license/dependency acquisition and clean-image host/protocol rehearsal remain T-FT-09; no event readiness inferred. |
| P3 — integration / event rehearsal | Eligible student maintainer ports reviewed tooling to approved repository, tests real event runtime, freezes release | Requires repo access/content review, actual event dates and Operations Team decisions. Local preparation is not a substitute for this gate. |

## Concrete analyst follow-ups

1. Collect the actual November scripts' input/output contracts and report rubric in authorized storage. Request sanitized/synthetic examples, not client evidence.
2. Define which observations prove a finding, reviewer ownership, status transitions, and expected schema evolution. Confirm duplicate grouping policy.
3. Resolve event start/timezone, PDF/Markdown submission expectations, page limits, incident route, and internal report deadlines.
4. Resolve vendor retention contradictions and endpoint approval. Clarify whether any AI is permissible and whether publicly accessible local weights can be staged/run within supplied hosts.
5. Create a separate `offline-enrichment` proposal only when public catalog format, size, freshness, licensing, and staging constraints are known; create `local-ai-assistance` after concrete approvals and hardware checks.
