# Farming toolkit design

Design baseline: 2026-10-15. Architect: read-only `/root/architecture`; root reviewed and adopted the design as sole editor. Implementation location: `tooling/farmkit/`. All original requirement IDs remain in force.

## D-FT-01: Baseline and completion boundary

The initial deliverable is a commit-ready catalog and preparation package. Preserve all forty entries and the original operational acceptance requirements. Local implementation completion is distinct from full offline-kit/runtime acceptance. Only the customer name is known; public package examples use generic synthetic names.

The original Analyst snapshot is historical: a clean integration checkout exists at `integrations/United-States-Military-Academy`, HEAD `ec767e466147150941f77e1759c66c7949a76f00`, on the reporting branch. Reporting is v0.2.0 with schemas 1.0/1.1; its `cptc.tool-run/1.0` and forty intake routes remain planned. Existing upload authorization concerned reporting. This module is prepared locally; no reporting/scanner/configuration/installer/PR change is needed.

The inspected repository says NLT 16OCT without enough event/year/timezone evidence. Do not turn that text, the October 2025 rulebook version, or the November development milestone into an event timestamp.

## D-FT-02: Catalog and selection

`catalog.json` is the machine-readable selection record; `CATALOG.md` is its generated human-readable equivalent. The original [research appendix](tool-catalog.md) remains intact. Each record carries identity/upstream, priority, disposition/reason, capability/protocols, runtime/dependencies/hardware/privileges, operation classes, outputs, upstream license evidence/review, maintenance limitations, responsible role, checked date, runbook and test state.

Selected means **selected for evaluation**, never staged or runtime accepted. Initial selected IDs are 003, 013, 014, 017, 018, 020, 023 and 024. Keep 001/002/009/012/019/022/028 held. Optional lab IDs are 021 and 035–040. Remaining entries are conditional. No item initially claims acquisition, dependency closure, security audit, licensed redistribution or actual runtime verification. PEASS remains prominent and held; this is not omission of the requested tools.

One sufficient backend per protocol is preferred. Two Modbus entries support distinct library/CLI needs. Optional second OPC UA stacks and server platforms stay out of the default operational kit. CAN/J1939 coverage is not complete ISOBUS engineering; RF/physical/energy options need evidence.

## D-FT-03: Source references versus staged bytes

`sources.json` records exact researched source revisions, immutable archive/license locators and chosen release labels for the core plus PEASS. A source pin is not an acquired or tested binary. `artifact-lock.json` is initially an **empty upstream inventory**, with all acquisition acceptance pending.

Actual staged artifacts must use the separate `cptc.artifact-lock/1.0` contract: ID, associated tools, exact version and full commit, origin URL, relative path, byte size/SHA-256, platform/architecture, license evidence/review, dependency artifact IDs and closure-review state, and smoke-check reference. Built outputs additionally require a separate reviewed build/dependency record before runtime acceptance. No inferred dependency closure or guessed digest qualifies. Synthetic fixture artifacts have no upstream tool IDs and can never establish that an upstream tool was acquired.

Moving pins, unknown fields, duplicate keys/IDs, unresolved dependency references/cycles, invalid digests and unsafe paths fail validation. Source references with unresolved artifact bytes stay references. Acquisition format (public distro snapshot, wheelhouse, source archives, binaries or images) remains OD-FT-04. License review, publisher identity, build reproducibility and dependency completeness require human evidence beyond a successful hash check.

## D-FT-04: Offline helper

`kit.py` uses Python 3.10+ standard library only. Commands validate the catalog/source/lock/readiness contracts, list/filter entries and verify supplied local artifact bytes. Readiness reports missing decisions and runtime evidence with a nonzero pending result. It does not claim approval when records merely contain assertions.

The helper has no network, installation, subprocess, shell-command or scanner path. It reads bounded JSON, treats all strings as data, and prints bounded diagnostics without dumping source values. Artifact verification streams bounded regular files under an explicit root; it rejects traversal, absolute paths, reserved/ambiguous Windows names and symlink/reparse components. It neither repairs missing artifacts nor substitutes downloads. Read-only verification does not mutate manifests or inputs.

The source tree and final package contain only team-authored code/docs, attributed metadata, source references and synthetic fixtures. No third-party software is relicensed under the module license. The delivered ZIP includes a byte-hash manifest; it packages preparation materials, not executable upstream tools.

## D-FT-05: Operational and rehearsal runbooks

`RUNBOOKS.md` covers offline PCAP, Linux/Windows enumeration, six primary active protocol families, acquisition/clean-image checks, optional hardware gaps and freeze/integration. Each active family names the precise allowed request, destination/unit/address/node/topic limits, request/connection budgets, timeout/retries, effects, stop/cleanup and evidence needs.

Examples are lab plans requiring selected-version invocation verification. No executable active profile or target runner is delivered. Initial budgets are provisional lab ceilings, not universal safe rates, and distinguish application requests from handshakes. Default runbooks prohibit sweeps, indefinite polling, broad broadcasts, writes, controller mode/logic changes, publish/retained modifications and trust bypass. Read/subscription traffic is active.

Actual Linux/Windows enumeration, PCAP interpretation with selected TShark, protocol read/query rehearsal, traffic confirmation, measured footprint and physical paths remain not run until facilities and reviewed artifacts exist. Missing .NET, quarantine or authentication failure cannot imply no findings. Do not disable endpoint controls.

## D-FT-06: Evidence interface

Provide generic synthetic run records showing success-empty, partial, failure and not-run states, with tool/version, profile/operator/scope, timezone timestamps, exit status, source-artifact/hash and limitations. Preserve unsupported/authentication/timeout categories. Do not add process values, secrets or arbitrary raw output to metadata.

Align conceptually with the existing `cptc.tool-run/1.0` design. Current reportgen does not accept these examples as completed report JSON. Do not implement adapters, findings, CVE validation or report-schema changes here. Raw engagement material belongs in approved private event storage, not this synced preparation package.

## D-FT-07: Verification and readiness

Validate all forty dispositions, required fields, seven primary coverage families and conditional coverage/gaps. Test malformed/oversized JSON, duplicate keys, IDs/enums/types, pin/hash/dependency failures, unsafe paths/reparse points, missing/tampered artifacts, held-tool staging and offline execution. Synthetic verification passes only as integrity-helper evidence.

`readiness.json` preserves OD-FT-01–08 and explicit Linux/Windows/protocol/resource/hardware checks. Partial access resolution is recorded without equating repository write access with event approval. Required unresolved checks always yield pending readiness. Independent settled-version review checks both actual implementation and remaining specification gaps. Full proposal acceptance stays pending, even if all available local tests pass.

## D-FT-08: Alternatives and transition

Documentation alone lacks machine-checkable consistency. A small passive helper adds reusable value without another scanner or Nmap wrapper. Bulk installation, vendoring every candidate, mandatory containers and generic report parsing introduce unnecessary dependencies and unresolved obligations, so they are deferred. Source references plus an empty real-artifact lock honestly distinguish research from bytes acquired.

Before publication, refresh target revision/conventions, inspect the exact public file list, confirm eligible student ownership, current staging/deadline decisions and authorization for this contribution. Existing reporting PR and legacy tools remain intact. Reserve proposal README consolidation for full scoped completion and explicit acceptance.

## Requirement mapping

| Requirement | Design | Verification / remaining acceptance |
| --- | --- | --- |
| FR-FT-001 | D-FT-02 | All 40 dispositions and requested PEASS names. |
| FR-FT-002 | D-FT-02/03/05 | Catalog/schema/reference checks; exact runtime metadata pending. |
| FR-FT-003 | D-FT-02/05 | Primary coverage and serial constraints; real rehearsals pending. |
| FR-FT-004 | D-FT-02/05 | Conditional coverage plus explicit ISOBUS/RF/energy gaps. |
| FR-FT-005 | D-FT-05/07 | Host runbooks delivered; actual Linux/Windows runs not run. |
| FR-FT-006 | D-FT-03/04 | Strict lock/hash tests and source pins; acquisition/dependency closure pending. |
| FR-FT-007 | D-FT-04/05 | No network/process execution; active runbooks explicit and gated. |
| FR-FT-008 | D-FT-05/07 | Bounded per-family runbooks; measured lab effects pending. |
| FR-FT-009 | D-FT-06 | Synthetic failure/status evidence and honest reporting boundary. |
| FR-FT-010 | D-FT-05/07 | Rehearsal procedures and not-run ledger; actual protocol tests pending. |
| FR-FT-011 | D-FT-01/08 | Commit-ready package/integration checklist; publication pending. |
| FR-FT-012 | D-FT-07/08 | Event/staging/freeze gates retained. |
| NFR-FT-001 | D-FT-01/02/06/07 | Evidence/hypothesis/test/approval distinctions. |
| NFR-FT-002 | D-FT-02/03/08 | Attributions/holds; actual third-party redistribution review pending. |
| NFR-FT-003 | D-FT-03/07 | Helper works offline; upstream clean-Kali runtime remains not run. |
| NFR-FT-004 | D-FT-05/07 | Finite requests/stop paths; measured effects pending. |
| NFR-FT-005 | D-FT-01/06/08 | Synthetic/public-content inspection and exact package file list. |
| NFR-FT-006 | D-FT-02/03/08 | Dated upstream declarations/owner/fallback; security audit pending. |
| NFR-FT-007 | D-FT-02/07/08 | Links/IDs/mappings, independent implementation review. |

Ready for Planner/local implementation. Full offline-kit acceptance and event use require the explicit remaining evidence; the design does not waive original criteria.

## D-FT-09: Authorized suite installation and PR

2026-10-15 user extension maps FR-FT-013/014. Add `install.py` and `install-manifest.json` separately from passive kit.py. Root install.sh dispatches preview/default full install; preserve scanner/Prowler availability and reporting dependency installation. Full means supported assessment components plus staged Linux/Windows PEASS assets; lab servers remain optional as the user chose. A forty-ID installation matrix names alternative/held/manual cases rather than pretending every library/server was installed.

Use apt clients/dev libraries only in default profiles; do not automatically install/start daemon packages. Isolate reporting, current OT, cpppo and optional Python clients in venvs. Fetch native client/library sources by full commit, verify checkout and retain notices. Download PEASS exact release assets and check published size/SHA-256; stage without executing or parsing. This narrow end-user acquisition does not remove catalog output-integration or redistribution holds. Use explicit argv, fail on required errors, retain per-step state and actual package versions, support resumable verified existing artifacts, and check installation through metadata/file identity only. Never imply an installed tool has passed engagement/runtime acceptance.

Clone/fetch/build/download/install are explicit online preparation actions. No unsupported offline switch or private cache fallback is added. A later wheel/distro snapshot closure is still needed for offline installation. Default native/library installation needs no physical access. Preview works without mutation or subprocess/network; execution requires Kali/Linux. Optional Prowler remains an explicit separately isolated choice.

Implement and test in the preparation module, copy the exact public module into an isolated branch from `origin/codex/report-generator`, and create a stacked PR against that branch so reporting PR #1 is not duplicated. Include a sanitized public design/validation note instead of raw private workspace/planning records. Actual disposable Kali installation, no-target checks, synthetic regression, ignored artifacts and independent final review precede publication. No merge.
