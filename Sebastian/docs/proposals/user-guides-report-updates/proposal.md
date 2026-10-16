# User guides and incremental report updates

Date: 2026-10-16. Owner/editor: root assistant for Sebastian Solberg. User acceptance: pending.

Request: implement guides for all human-facing tools, add a README quick start with diagrams/graphics, and improve reporting design/modularity, especially modifying existing reports after new tool output. The user supplied the master repository and requested the new CPTC project context be checked.

Baseline: master 6c8ec1d; fast-forwarded to the already published continuation 09099c6 before new work, retaining Word snapshot support and workspace-format compatibility. CPTC context reviewed: project profile/workflow, latest development/reporting chats, public root code and prior decision records. Synced sources were empty and remained untouched. User preference from the reporting context: master, direct commits, no new pull requests. Prior publication authorization is retained; no scanner execution, client-data processing or new native adapters are inferred.

Implementation: current source is in root `tooling/`; human documentation is in root `docs/` and README. This folder adds project records; archived snapshots remain unchanged. New reporting envelope is curated synthetic input, preserving the previous exclusion of native adapters and local AI. Existing report schemas and render APIs stay compatible.

Artifacts: [requirements](spec.md), [design](design.md), [tasks](tasks.md), [execution](execution-guide.md), [verification](verification.md), [review](review.md). Implementation, verification, independent review and acceptance are tracked separately. Operational/event acceptance is outside this preparation change.
