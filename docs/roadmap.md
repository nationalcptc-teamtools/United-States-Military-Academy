# Current CPTC roadmap

Reviewed 16 October 2026. The preceding audit baseline was historical master `78dc138`; onboarding uses rewritten upstream master `96c7be5751f4a2ea862af58ef40428da098e5d84` plus preserved audited changes. Reporter 0.5.0, workbench 1.1.0, Word export, incremental updates, forty-tool guides and the farm installer existed at the preceding baseline.

| Priority | Work | Completion evidence / accountable role |
| --- | --- | --- |
| P0 | Reconcile cutoff/start/timezone, rules/SOW/ROE, owners and submission requirements | Captain/officials/report lead resolve CR-01/02 in [READINESS](READINESS.md); retain unknowns until supported |
| P0 | Decide operational reporting endpoint/storage/access/retention/export boundary | Custodian/officials resolve CR-03; reviewed implementation and approved-host tests precede real-data support |
| P0 | Accept selected installed tools on actual authorized hosts/labs | Runtime/lab/engagement owners resolve CR-04; installation is not operational acceptance |
| P1 | Reconcile status/publication and retire defective legacy scanning | Current maintenance cycle; synthetic checks and independent review establish local code/document outcome |
| P1 | Obtain rubric/risk matrix; assess screenshot and Word layout needs | Report lead resolves CR-05; screenshot embedding/native Word visual QA remain open |
| P2 | Choose image recovery versus fresh offline reinstall; finish selected license review | Maintainer/license reviewer resolves CR-06; full dependency closure/cache is unimplemented |
| P2 | Resolve required DNP3/SDK/hardware workflows | Tool/engagement owner resolves CR-07 only when actual assets require it |
| Maintenance | Keep active products distinct from historical archives | CR-08 and [maintenance guide](MAINTENANCE.md); preserve archived bytes |
| Deferred | Native scanner adapters and broader reporting/workbench CI | Explicit user instruction on 16 October: keep both deferred; retain existing farm CI |
| Optional | Browser interface, resource study and offline enrichment | No new implementation commissioned; existing evaluation/manual metrics remain available |

Local AI/correction remains removed. Prior 120 choices are preserved in [the historical decision register](../Solberg/docs/proposals/development-functions/decisions.md). This roadmap supersedes old feature ambitions without changing their historical records or granting event, client-data, target, deletion or publication approval.

Local audit patch revisions: reporter 0.5.1, workbench 1.1.1 and farmkit 1.1.1. These local changes correct confirmed boundary/integrity/dependency/catalog errors; they are not yet published or operationally accepted. Published baseline versions above remain historical facts.

## Individual tool onboarding, 16 October 2026

Farmkit/workbench 1.2.0 add per-tool plan/install/check selections, optional sensor/lab acquisition, Syft, pip-tools and LibreOffice preparation. See [workflow evidence](tool-onboarding/verification.md) and [one-line guide](../tooling/farmkit/ONBOARDING.md). Earlier local 1.1.1 patch descriptions above are retained history. Native adapters and broader CI remain deferred. Publication/acceptance status is recorded in the onboarding proposal.
