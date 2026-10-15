# Proposal: farming IT/OT assessment toolkit

Proposal ID: `farm-toolkit`. Version 1.1.0, 2026-10-15. Ownership: requester/captain owns event acceptance; root editor owns this contribution; independent reviewer inspects without editing. Eligible student runtime/license/rehearsal owners remain to be assigned. Status: implementation and installation verification complete; final public review/publication tracked in the pull request; operational/event acceptance pending.

Original request (public extract): create a list of open-source tools applicable to CPTC for the team tooling repository, including LinPEAS, WinPEAS and flexible ICS/OT tools for farming systems. The original customer-specific request remains in private planning. The only customer information is a name; no technologies or findings are inferred from it. The requester subsequently asked to complete all workflow roles, commit the work, open a pull request, and make the complete suite easy to install. Clarifications: October 2025 rulebook baseline; offline Kali/Linux workstation plus Windows tools; assessment suite by default, lab servers optional.

| Role product | Artifact / result |
| --- | --- |
| Analyst | [Specification](spec.md), [40-tool catalog](CATALOG.md), [source references](sources.json); stable requirement/tool/decision IDs and observable acceptance. |
| Architect | [Design](design.md); extend root installation, isolate dependencies, preserve scanner/reporter and held paths. |
| Planner / Tech Lead | Design's dependency sequence, sole editor, independent review, concrete deliverables and external gates. |
| Developer | [Passive checker](kit.py), [installer](install.py), [manifest](install-manifest.json), synthetic fixtures and root entry point. |
| Tester / Reviewer | [Verification](VERIFICATION.md), contract tests, isolated Kali installation, disconnected checks and regression evidence; remaining limits explicit. |
| Delivery | Public branch and PR; [installation guide](INSTALL.md), notices and source-only deterministic archive builder. No automatic merge or operational acceptance. |

Legacy mapping: FR-FT-001–012/NFR-FT-001–007 retain the original preparation specification; FR-FT-013/014 are the authorized installation/publication extension. Original design D-FT-01–08 and T-FT-01–08 cover the reviewed preparation kit; D-FT-09 and T-FT-10–14 cover install design, implementation, testing, independent review and publication. T-FT-09 is still the external runtime/event rehearsal gate. The prior v1.0.0 preparation artifact is historical, not silently overwritten. Reporting's separate requirements and PR #1 are not renumbered or superseded; direct farm-output adapters remain planned.

This contribution is based on `codex/report-generator` (PR #1), refreshed at `5fc9b7d3619daf6b491d692891d3f9511e34538c`, and leaves its source and scanner/configuration behavior unchanged. It replaces the root installer with the requested suite preparation entry point. The installer is independently network-active for acquisition, while `kit.py` remains passive. Private sources, customer material, local installed software, captures and credentials are excluded from the public contribution.

A concurrent master update, `c2468f2af95bc96acc82ec0cb083725d33304aef`, adds consolidated Linux/Windows enumeration runners and updates its README cutoff to 19 October. They provide their own installation/doctor and explicit-scope operational entry points; this proposal adds catalog/OT preparation rather than another runner. This stacked contribution does not absorb those separate commits. PR #1 currently needs reconciliation against updated master before the stack can merge; no merge or update of that separate PR is performed here.

Remaining decisions and acceptance gaps are in [spec.md](spec.md): exact event/SOW/start/timezone, eligible maintainer, permitted staging format, license/dependency closure, exact team Windows/runtime/resources, actual protocols, hardware and bounded operational rehearsals. Software installation is verified separately from these gates. Initial design and the authorized implementation are ready for maintainer review.
