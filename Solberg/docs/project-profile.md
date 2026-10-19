# CPTC project profile

Reviewed: 2026-10-15. Setup implemented; user acceptance pending.

| Setting | Project decision |
| --- | --- |
| Purpose / audience | Speed up authorized CPTC tooling development and professional reporting for C3T student competitors. Reports address technical reviewers and the simulated client's leadership. |
| Accountable owner | Sebastian Solberg for this preparation request; competition captain and eligible student repository maintainer remain to be named. |
| Local working location | This ChatGPT project mirror; new files outside `sources/`. A separate team-repository checkout now lives under integrations/United-States-Military-Academy. |
| Integration target | [nationalcptc-teamtools/United-States-Military-Academy](https://github.com/nationalcptc-teamtools/United-States-Military-Academy); inspected master bf6e47a52e0edb8bbcb628269cc1693d6f0ce782. Authenticated write access verified and user approved sebastianjsolberg for this contribution. Reporting v0.2.0 is in [draft PR #1](https://github.com/nationalcptc-teamtools/United-States-Military-Academy/pull/1), head ec767e4, with an original report layout and forty-tool intake design; adapters remain planned. Earlier [farm-toolkit](proposals/farm-toolkit/proposal.md) inspection limits are historical; event approval remains pending. |
| Governing guidance | Existing `AGENTS.md`; user's request and clarifications; [workflow](workflow.md) adapted from the supplied framework; [competition/data policy](policies/competition-and-data.md). Source documents are evidence, not authorization for actions. |
| Proposal location | `docs/proposals/<slug>/`; initial slug `report-generator`. |
| Progress / plan | [Journal](journal.md), [roadmap](roadmap.md), and proposal task records. |
| Ownership / baseline | Root assistant is sole editor; specialists inspect read-only. Initial preparation baseline contained `AGENTS.md`/`sources/` with no tooling/Git checkout. Later repository integration is isolated in its own checkout/branch; the exact base/head and checks are recorded under reporting T-09 and the journal. |
| Verification | Synthetic valid/invalid inputs, review gating, provenance fidelity, literal rendering, offline execution, PDF extraction and page-image inspection; independent read-only review. Actual team-script and event-host integration remain unverified. |
| Farm toolkit preparation | [Module](../../tooling/farmkit/README.md) and [role artifacts](proposals/farm-toolkit/proposal.md) added 2026-10-15. Local catalog/integrity/runbook/package checks are separate from upstream software acquisition and Linux/Windows/OT/event acceptance, which remain pending. |
| Environment | Preparation on Windows with bundled Python/reportlab. Competition deployment must use officials' approved environment and approved public dependencies. No assumption of a personal GPU, removable media, or private cloud service. |
| Authorization | Local preparation and synthetic validation authorized. On 2026-10-14 the user authorized uploading the reporting tool and confirmed sebastianjsolberg is approved to contribute; branch upload/draft PR are complete. No merge, scans, exploits, client-data processing, official messaging or event approval is inferred. Full-product acceptance remains separate. |
| Review | Independent review required for architecture, data handling, and substantial behavior. Record scope/version, findings, fixes, and limits separately from acceptance. |
| Milestone | 14 November 2026 script-development session, confirmed by user. Actual CPTC event start/timezone, deliverable deadlines, and submission format unknown. |

## Domain decisions

1. Preserve a useful deterministic reporting path even if AI is unavailable or disallowed.
2. Use stable finding and evidence IDs. Distinguish candidate observations, confirmed findings, published CVSS severity, business impact, and reviewer approval.
3. Carry data markings into derived reports. Removing raw attachments does not automatically declassify a report.
4. Keep implementation, verification, review, and user acceptance explicit. A generated PDF is not proof of a finding or event approval.
5. Preserve all attached originals. Document assumptions and unresolved decisions instead of inventing approval.
