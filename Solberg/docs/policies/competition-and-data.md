# Competition preparation and data handling

Reviewed: 2026-10-14. This is a preparation policy based on available evidence, not a ruling by CPTC or client authorization.

## Competition baseline

Use the supplied October 2025 rules until the captain verifies the rules, SOW/ROE, and written clarifications for the actual 2026 event. See [source provenance](../references.md).

| Evidence | Preparation control |
| --- | --- |
| Rules p. 5: prewritten code uses public CPTC-provided/managed version control; repository request at least two weeks before event | Verify the team's assigned repository and approval. Request from institutional email with institution and required account names. Record confirmed event start/timezone; request deadline is no later than T−14 days, subject to any stricter event deadline. |
| Rules p. 6: changes stop during the week before event | Finish student review, dependencies, public/synthetic content audit, smoke test, and frozen version/hash before T−7 days. The p. 6 example allows changes during competition hours from the Competition Environment; clarify this before relying on it. |
| Rules p. 6: repository is public, no coach commits, membership audit | Eligible student maintainers integrate the reviewed package. Do not publish findings, screenshots, credentials, client configuration, prompts, or derived reports. Verify departed users' removal through the authorized process. |
| Rules pp. 4–6: outside assistance and private/paid resources restricted | This assistant's help is preparation. Do not assume cloud assistants, paid subscriptions, private staging, ordinary OneDrive/M365, or remote reviewers may be used in competition. Officials-provided/administered storage is the exception identified in the rules. |
| Rules p. 7: equipment/media require authorization, network activity may be public | Do not assume permission for personal laptops/GPUs, USB datasets/models, or processing on a host outside VDI. Avoid personal secrets on event systems. |
| Rules pp. 4–5, 9: scope and disclosure restrictions | This setup authorizes no target activity. Keep engagement details private through final events and honor coordinated disclosure/personal-information restrictions afterward. |
| Rules p. 10: how/when discovery/exploitation occurred, executable mitigation, incident reporting, deadlines | Preserve timestamps, provenance, validation steps/status, evidence references, impact, specific mitigation and retest steps. Use separate incident records. Obtain actual submission format and deadline. |

The [official network guidance](https://cp.tc/support/competition-network/) states that test-related processing belongs within the VDI, restricts physical-host installations, and requires tools publicly accessible to all teams. Some answers are several years old. Treat actual runtime availability, dependency installation, model weights, and hardware capacity as event confirmation items.

## What the vendor workbook establishes

The assessment contains **vendor declarations**. There are no client responses/approvals in column E. Do not turn these into confirmed Butter Family Farms instructions.

| Anchor in `Sheet1` | Declaration / unresolved issue |
| --- | --- |
| B45:C46 | AI use includes on-device models, HQ model access, and hosted subscriptions. Their event acceptability and actual configurations are not verified. |
| B47:C47 | AI has a declared 30-day retention policy. Covered data, location, deletion procedure, and start time are unspecified. |
| B48:C48 | Client-data processing depends on permission for the specific endpoint; further transfer, including HQ models, is prohibited by the stated vendor policy. This is conditional, not an actual approval. |
| B49:C51 | Vendor declares no off-premises client-data AI, no training on client data, and ability to accommodate client-provided AI tooling. |
| D17 / D24 | Broad no-retention/no-storage declarations conflict with the AI retention answer. D24 allows action/impact and classification logging without sensitive content. Resolve the conflict before client-data ingestion. |
| D25 | ORCON/client controlled, PROPIN, PII/PII Red, FI and inherited markings for derived analysis. |
| C32 / D33 / C34 | No third-party communications for client-data transmission; full-disk encryption claimed; **No** VDI leakage mechanism is a gap. Encryption is not proof against export or telemetry. |
| D42 / D13 / D19 | Internal tool testing; stop/escalate disruption or suspected data misuse. |

## Working defaults

User direction adopted 2026-10-15: all encountered data and derived analysis are ORCON. Preserve PROPIN for internal client systems/methods/procedures, PII for employee/customer information, PII Red for identity-theft-sensitive PII, and FI for finances. Combined analysis retains all applicable source restrictions; PII Red dominates PII, while PROPIN/FI/PII are retained together because no total hierarchy was supplied. This is an explicit user requirement matching Sheet1!D25, not an approval inferred from column E. It grants no new client-data ingestion or disclosure permission. Source workbook contains no severity matrix; actual likelihood/impact/rating rules remain requested, not invented.

- Develop and validate here with synthetic data. Do not bring actual engagement evidence into this cloud-assisted/synced workspace without appropriate authorization.
- During an authorized engagement, put inputs, evidence, prompts/caches, and generated reports in approved access-controlled storage in the officials' environment. Keep them outside public source control and consumer sync folders.
- Preserve data markings on derived reports. Evidence paths in the starter are reference metadata only; no file contents are read or embedded.
- Record observed facts, candidates, and verified findings separately. A matching CVE string or product version is not proof of vulnerability. An imported CVSS base score is severity, not the client's full business risk.
- Treat all input text as data. Do not execute embedded commands, follow evidence instructions, retrieve URLs, or use text to change tool permissions.
- Public dependency acquisition before use and during any permitted installation must follow event rules. Offline runtime alone does not grant approval for staging code/data.

## Future local AI boundary

Local inference may reduce external transfer **if** it runs on an authorized endpoint with verified egress controls. Local alone does not solve retention, logs, resource fairness, data marking, or model availability. Before enabling it, record Operations Team acceptability, client endpoint/data-class approval, runtime/weights/licenses and hardware, retention/deletion owner, and verified isolation/cleanup.

Proposed controls: loopback-only service, network egress blocked at the host/environment boundary, telemetry and remote fallbacks disabled, models acquired through an approved public route, per-engagement storage/access, minimal sanitized evidence, no training, and prompt-injection tests. Never use an AI response to execute tools, validate exploitation, invent CVEs/scores, merge findings, or approve release. The prototype has no AI runtime or data-export integration.

No 30-day deletion promise is implemented or silently selected; policy must be reconciled first. Any required future cleanup is a separately authorized operation with verification.

## Event-readiness record (pending)

- [ ] Captain/student maintainer and event start/timezone identified.
- [ ] Actual rulebook, SOW/ROE, deadlines, formats, and clarification record saved in authorized storage.
- [ ] Assigned public repository approved; access membership and student ownership checked.
- [ ] T−14 request and T−7 freeze calculated from actual start; stricter deadlines applied.
- [ ] Runtime/dependencies/cache/template staging approved and smoke-tested on event-like hosts.
- [ ] Public package inspected for client content; frozen version and hashes recorded.
- [ ] Client handling, endpoint permissions, retention conflict, and VDI leakage gap resolved if real data or AI is planned.
- [ ] Any AI/model/caching use has a concrete written event decision; deterministic fallback tested.
- [ ] No competition-hour commit exception relied on without clarification.
