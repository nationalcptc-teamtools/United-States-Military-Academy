# CPTC tooling project

Current continuation (15 October 2026): [workbench1.0.1](../tooling/workbench/README.md) integrates the existing Word renderer and preserves workspace format1.0.0. Full [role records](docs/proposals/development-functions/proposal.md), [publication notes](PUBLISHING.md), [incremental manifest](CONTINUATION-FILES.json) and [release/evidence](docs/proposals/development-functions/verification.md) are maintained here. Root tooling is the current implementation; the project snapshot/archive below is retained history.

Local preparation workspace for C3T / United States Military Academy's Collegiate Penetration Testing Competition tooling. Start with [the project profile](docs/project-profile.md), [workflow](docs/workflow.md), [reporting proposal](docs/proposals/report-generator/proposal.md), and [farming IT/OT toolkit proposal](docs/proposals/farm-toolkit/proposal.md).

## First product

Build reusable finding templates and an offline generator that turns structured outputs from the **14 November 2026 development session** into editable Markdown and a PDF. A synthetic starter is in [tooling/reporting](../tooling/reporting/README.md). It consumes normalized JSON; adapters for the team's actual scripts are the next integration step.

The starter performs no scanning, CVE lookup, model inference, network request, or publication. It preserves supplied observations, provenance, and review status. CVE/CVSS correlation and local AI are separately scoped experiments in [the roadmap](docs/roadmap.md).

## Workspace map

- [Project profile](docs/project-profile.md): ownership, source of truth, environments, and acceptance.
- [Competition and data policy](docs/policies/competition-and-data.md): evidence, constraints, and unresolved approvals.
- [Proposal artifacts](docs/proposals/report-generator/proposal.md): requirements, design, tasks, and review.
- [Farming IT/OT proposal](docs/proposals/farm-toolkit/proposal.md): forty-tool selection, full role artifacts and a [local preparation package](../tooling/farmkit/README.md) with source references, offline checks and bounded runbooks; upstream runtime and event acceptance pending.
- [Development workbench](../tooling/workbench/README.md): local tool discovery, creation helpers, synthetic workflow records, human finding review, report snapshots and neutral JSON/Markdown handoff; [scope and role artifacts](docs/proposals/development-functions/proposal.md) preserve all 120 user choices. No local AI or automatic cloud transfer.
- [Roadmap](docs/roadmap.md): priorities for the November development session.
- [Progress journal](docs/journal.md): dated implementation and validation evidence.
- [Report authoring template](../tooling/reporting/templates/report.md), [finding template](../tooling/reporting/templates/finding.md), and [incident template](../tooling/reporting/templates/incident.md).

## Repository relationship

Integration target: [nationalcptc-teamtools/United-States-Military-Academy](https://github.com/nationalcptc-teamtools/United-States-Military-Academy). Later on 2026-10-14, its master snapshot bf6e47a52e0edb8bbcb628269cc1693d6f0ce782 and authenticated write access were verified. The user approved sebastianjsolberg for this contribution. Reporting v0.2.0 is uploaded in [draft PR #1](https://github.com/nationalcptc-teamtools/United-States-Military-Academy/pull/1), updated 2026-10-15 at ec767e4 after independent review. It adds an original OSCP-inspired layout and [intake design](../tooling/reporting/design.md) for forty farm-tool candidates; native adapters remain planned. A separate integration checkout lives under integrations/United-States-Military-Academy. Earlier farming-toolkit observations and limits remain in the [toolkit specification](docs/proposals/farm-toolkit/spec.md); event approval remains separate.

The quoted **29 December 2023** deadline belongs to the historical template-repository README. The actual checkout's current README instead says the last commit is due **no later than 16 October**, without an explicit year/timezone in that line. The reporting upload was prepared on 14 October 2026. Confirm event start/timezone and current Operations Team guidance before calculating rulebook request/freeze dates or claiming event readiness.

Only reusable tooling, templates, dependency declarations, and synthetic fixtures are candidates for public integration. Review local planning records for private source references before sharing them. Keep client-derived reports and evidence in the officials' authorized environment. Ignore rules cannot protect content already tracked or otherwise uploaded.

Existing `AGENTS.md` and all `sources/` material remain unchanged and read-only. New work lives outside `sources/`.
