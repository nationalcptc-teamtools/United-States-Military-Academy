# Toolkit design and delivery plan

Version 1.1.0, 2026-10-15. Implements [the specification](spec.md); actual results are in [VERIFICATION.md](VERIFICATION.md).

## Existing capabilities and proposed additions

| Existing implementation | Missing capability / addition | Benefit, duplication risk and effort |
| --- | --- | --- |
| config.py / super_nmap.py | Catalog/runbooks for industrial and farming possibilities | Broad protocol selection without another Nmap wrapper; low duplication, documentation/validation effort. Existing broad Nmap defaults remain separate. |
| Root apt/Vulscan/Prowler installer | Profile-based assessment installer with pins, isolated Python groups, integrity checks and inventory | One preparation path; extend existing entry point, moderate dependency/build/testing effort. No second operational scanner. |
| Passive reporting PR #1 | Tool-run status examples and future adapter map | Explicit evidence boundary; no duplicate report generator or implemented native-output adapters. |
| Concurrent master c2468f2 Linux/Windows runners | Standalone OT catalog and dependency preparation | Existing runners retain IT operations, scope, logging and their own installers; reuse distro packages where shared. No new assessment runner or changes to their behavior. Their optional tools outside this forty-entry catalog remain managed by their own installer. |
| No curated upstream collection | Forty entries with eight selected, eighteen conditional, seven lab and seven hold dispositions | Prioritize useful backends rather than install every alternative. Full software coverage differs from selected operational readiness. |

## Decisions and contracts

D-FT-01–08 retain the preparation design: catalog/dispositions and scenario hypotheses; team-authored passive stdlib helper; strict bounded JSON contracts; explicit artifact/dependency lock; immutable source references without invented byte hashes; bounded runbooks; separate reporting/evidence handoff; deterministic source-only package and readiness ledger. `kit.py` accepts local metadata only and never downloads or launches tools. The synthetic lock is explicitly synthetic. Real acquisition/readiness records remain separate and unpromoted.

D-FT-09 adds `install.sh` → `install.py` → fixed `install-manifest.json`. `plan` has no process/network/write effects. `install` obtains apt packages, isolated venvs, pinned source builds and PEASS assets; `check` uses local metadata/hashes only. Full targets Kali; core reduces package breadth. Four independent Python environments keep cpppo's older greenery constraints separate from modern OT and extended packages. Native SDKs remain libraries; no automatic client/scan workflow is synthesized. Alternative all-in-one venv was rejected for incompatible constraints; default lab servers were rejected per the requester's choice. Containers are a test facility, not a required operational deployment.

System packages are distro-managed; apt versions and pip resolution are recorded, not fully frozen. Source commits are exact and built file hashes are local identities, not claims of reproducible binaries. PEASS release bytes have exact sizes/SHA-256 and a pinned original license; setup stages but never executes them. Existing differing source/payload/Vulscan paths fail and are preserved. Native libraries retain upstream source/notices in the prefix. Detailed installed components, optional systems and license holds are in [INSTALL.md](INSTALL.md).

Failure is nonzero with an incomplete atomic inventory and named last step. Required check membership is derived from the profile, not trusted from a possibly incomplete saved list. Check validates dpkg installed status, venv identity, top-level versions/pip consistency, clean source commits, required native identities, hashes, notices, activation/report entry point and the legacy Vulscan link. Source/build/venv/bin/payload directories and write destinations reject redirects; normal venv interpreter links are allowed only to the setup interpreter and their actual environment prefix is checked before pip. Use a trusted quiescent prefix; concurrent replacement is outside this filesystem contract. apt mutations have no rollback. No target scope is accepted by setup because it never performs assessment activity.

## Requirement mappings

| Requirement | Design path / acceptance evidence |
| --- | --- |
| FR-FT-001/002 | Catalog, source evidence, notices, dispositions and metadata validation; license/runtime truth remains separate. |
| FR-FT-003/004 | Primary/conditional protocol matrix, runbooks and full coverage manifest; hardware and DNP3 gaps explicit. |
| FR-FT-005 | PEASS staged independently; Windows/.NET and host-output rehearsal remain external. |
| FR-FT-006 | Strict artifact lock, source and asset pins, installation inventory; fully pinned offline dependency closure remains external. |
| FR-FT-007/008 | Passive helper, acquisition-only installer, bounded runbooks; no default active operation. |
| FR-FT-009 | Synthetic status examples; private evidence and planned intake adapter boundary. |
| FR-FT-010 | Rehearsal ledger/runbooks; software install tests cannot substitute protocol/traffic tests. |
| FR-FT-011/012 | Explicit public branch/PR, exact publication allowlist, separate event/readiness decisions. |
| FR-FT-013/014 | Root quickstart, isolated full installer/check, forty coverage dispositions, independent review then commit/push/PR. |
| NFR-FT-001/002 | Hypotheses, honest tested/not-run states, canonical evidence and upstream notices/holds. |
| NFR-FT-003/004 | Disconnected installation checks and bounded processing, no active setup defaults; actual offline operational smoke/load/resource evidence remains external. |
| NFR-FT-005 | Exact public allowlist/privacy inspection, synthetic fixtures, private-output guidance and ignore rules. |
| NFR-FT-006/007 | Versioned manifests, maintained/held dispositions, stable IDs, navigable links and source-only deterministic packaging. |

## Serialized delivery and ownership

Root holds the editing slot. Read-only specialists supply architecture/provenance/review evidence; they do not save. T-FT-10 design precedes T-FT-11 installer/docs/tests; T-FT-12 runs actual disposable Kali installation and disconnected checks; T-FT-13 independently reviews the settled public delta and rechecks defects; T-FT-14 commits/pushes and opens/attaches the stacked PR. Do not merge automatically. Existing unrelated working edits are preserved and excluded from this contribution. T-FT-09 remains the separately owned actual host/protocol/hardware/license/staging/event acceptance task.

The publication set is root installer/quickstart/ignore/line-ending rules, this module and its contract CI. No private planning originals, customer names, local filesystem/user paths, upstream binary/source caches, installed prefixes, reports, captures, secrets or unrelated reporting edits belong in that set. The source archive builder has a fixed module allowlist and excludes downloaded software.
