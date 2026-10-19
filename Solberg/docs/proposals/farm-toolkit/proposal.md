# Farming IT/OT tool catalog and preparation kit

Proposal: `farm-toolkit`  
Prepared: 2026-10-14  
Updated: 2026-10-15  
Active role: Delivery Lead, reviewed public contribution delivered  
Status: **assessment installer implemented, tested, independently reviewed, committed and published as PR #2; operational/event acceptance pending**  
Accountable requester: Sebastian Solberg  
Editing owner: root assistant, sole editor. Read-only architecture, provenance and validation/review specialists returned evidence to root; none edited this workspace or the integration checkout.

Current delivery: [PR #2](https://github.com/nationalcptc-teamtools/United-States-Military-Academy/pull/2), commit `7ccc0a6`, [installer/verification addendum](#authorized-suite-installation-and-publication-completed--2026-10-15). Earlier v1.0.0 narratives below are historical and superseded by that addendum.

## Original request

> You are the Analyst for project CPTC. I am beginning a new proposal: Create a list of open sourced tools that would be applicable in this competition for us to commit to the tooling repository (https://github.com/nationalcptc-teamtools/United-States-Military-Academy). We will set up access for you later when required to upload tools, but I will provide info as you need. Inlcude things like LinPEAs, WinPEAs, and as much flexible ICS and OT tools as possible for Farming based systems. Keep in mind the current information about our customer is just a name: Butter Family Farms.

The user also explicitly assigned the common project-neutral Analyst contract: inspect existing work, evidence, constraints and defects; distinguish current and desired states; clarify material ambiguities; record assumptions/exclusions; produce stable requirements and observable acceptance in `spec.md`; maintain request/status/ownership/links/mappings in `proposal.md`; hand off to Architect for `design.md`; save only while owning the editing slot.

Clarifications received 2026-10-14:

- Rules/event answer: **“October 2025.”** Adopt the October 2025 rulebook as the working baseline. This is not sufficient to identify an event, round, start timestamp or timezone; no calendar deadlines are calculated.
- Platform preference: **offline Kali/Linux kit plus Windows tools**.

## Current result and desired outcome

Analyst deliverables are a research-backed [candidate catalog](tool-catalog.md) and [specification](spec.md). Following the user's 2026-10-15 instruction to work through the remaining roles, the local [preparation module](../../../../tooling/farmkit/README.md) now implements all forty dispositions, nine immutable source-version reference records, a passive validator/artifact checker, readiness ledger, bounded runbooks, synthetic fixtures and deterministic packaging. Farm use cases remain hypotheses. No customer assets, protocols, vendors or vulnerabilities are confirmed.

The desired later product is a student-maintained, reproducible selection package suitable for review and eventual integration into the assigned public team repository. It must support offline operation after authorized acquisition, preserve upstream licensing, document operational effects, and give a competitor useful selection and evidence-handling guidance. A catalog entry is not a tested package or permission to use a tool.

The October 14 Analyst repository-inspection limits are historical. A separate clean integration checkout now exists at `ec767e466147150941f77e1759c66c7949a76f00` on the reporting branch, with contribution access and reporting publication recorded in the journal. The actual repository README now says NLT 16OCT without sufficient year/event/timezone. This package does not alter that checkout or PR; publication authorization for this contribution and event assignment/approval remain separate. Root planning files remain outside that repository.

## Artifacts and ownership

| Artifact | State / responsible role |
| --- | --- |
| [spec.md](spec.md) | Analyst specification; stable `FR-FT-*` / `NFR-FT-*` requirements and acceptance criteria. |
| [tool-catalog.md](tool-catalog.md) | Analyst research appendix; stable `TOOL-*` entries, priorities, sources, caveats and coverage gaps. |
| [design.md](design.md) | Architect design, baseline/alternatives/contracts/boundaries and all nineteen requirement mappings. |
| [tasks.md](tasks.md), [execution-guide.md](execution-guide.md) | Planner/Tech Lead products, serialized editing, bounded assignments and external acceptance gates. |
| [verification.md](verification.md) | Actual local tests, requirement coverage and not-run runtime checks. |
| [review.md](review.md) | Independent scoped positive verdict; R-FT-01–03 resolved and rechecked. |
| [Public module](../../../../tooling/farmkit/README.md) | Team-authored code/catalog/source references/runbooks/notices/tests/synthetic fixtures. |
| Release ZIP `output/farmkit/farmkit-1.0.0.zip`, manifest `output/farmkit/MANIFEST.json`, checksum `output/farmkit/farmkit-1.0.0.sha256` | Reviewable local v1.0.0 preparation package; fifteen files plus manifest, no upstream payloads. |
| [Project journal](../../journal.md) | Dated session evidence and handoff. |

No legacy artifact is renamed or superseded. The [report-generator proposal](../report-generator/proposal.md), its `FR-*` / `NFR-*` / `R-*` IDs, and existing implementation remain separate. `FR-FT-*` and `NFR-FT-*` are scoped to this proposal. Reporting integration is an interface consideration, not a new adapter implementation in this scope. Existing R-02/R-03 were resolved in that proposal; no new defect in the generator is alleged.

## Separate progress states

- **Analysis/design/planning:** complete for the local preparation deliverable; original requirement IDs and deferred decisions retained.
- **Implementation:** local module complete; no upstream software acquired, installed, vendored or launched, and no scanner/installer/report adapter added. Source pins have null byte hashes until acquisition; actual upstream inventory is empty.
- **Verification:** local contract/integrity/offline/package checks passed with one native-symlink privilege skip; complete dated results are in verification.md. Actual Kali/Windows/upstream/protocol/hardware/dependency-closure tests remain not run.
- **Review:** independent `/root/validation_review` returned a scoped positive verdict on the exact delivered package. R-FT-01 Unicode robustness, R-FT-02 OpenPLC evidence and R-FT-03 OPC UA fragments corrected and independently rechecked; no open actionable findings. See review.md for independent checks/hashes/limits.
- **Acceptance:** user acceptance and full original specification acceptance pending. Local role-cycle delivery does not waive T-FT-09 or imply publication, event permission or deployment readiness.

## Current delivery handoff

The design selects eight core evaluation candidates and preserves seven holds; optional alternatives/lab systems are explicit. No tool is runtime accepted. Architecture/provenance specialists inspected read-only; root implemented/tested; independent reviewer inspected actual files, reproduced/rechecked findings and independently verified the ZIP. T-FT-01–08 are complete locally. All role products remain separate until explicit acceptance.

Remaining original acceptance: exact Kali/Windows image, artifact/license/dependency acquisition review, actual synthetic host/PCAP/protocol rehearsals and measured traffic/resources, actual event start/SOW/staging/freeze decisions, student owner and authorization for publication. OD-FT-02 is partially resolved by prior reporting access; OD-FT-08 is provisionally resolved to this small core without adapters. Other gates remain open. The user has been asked for runtime/lab details while independent local work continues. No requested target activity or repository upload is inferred from this role-cycle instruction.


## Authorized suite installation and publication completed — 2026-10-15

Current result supersedes the preceding v1.0.0 no-installer/no-publication narrative. User explicitly requested all roles, commit/PR and an easy complete-suite installer, clarifying **assessment suite default, lab servers optional**. Root retained the editing slot; read-only architecture/provenance/review specialists supplied evidence without edits.

Published [PR #2](https://github.com/nationalcptc-teamtools/United-States-Military-Academy/pull/2), open and non-draft, head `codex/farm-toolkit-suite` at `7ccc0a6bbdc3e5488f18f046610f3a271221b81a`, base `codex/report-generator` at `5fc9b7d3619daf6b491d692891d3f9511e34538c`. API independently verified exact head/base, open/unmerged state and all 28 changed public files; mergeable against that base at verification. Attached to this chat. No reporting source changes or private planning/customer/source originals/upstream payloads were published. Local integration worktree is clean after commit. No merge performed. GitHub connector create returned 403; existing authorized account's memory-only Git credential flow successfully created and verified the PR without printing or saving credentials.

Latest master `c2468f2af95bc96acc82ec0cb083725d33304aef` adds independent Linux/Windows runners and changes README cutoff to 19 October. Reporting branch advanced concurrently to5fc9b7d; root refreshed the unpublished farm branch base/index without changing protected reporting bytes. PR #1 remains open/draft and needs reconciliation with master before the stack can merge. Existing runners retain their own install/doctor/scope/operation behavior; no duplicate runner is added. The historical16OCT note is not the latest master policy. Actual event/SOW/start/timezone/official cutoff remains unresolved.

Implementation: root `install.sh` provides plan/full/core/check; separate fixed manifest installs apt clients, four isolated Python groups, source-pinned mbpoll/BACnet client/lib60870/libiec61850/Vulscan, ReportLab and SHA-256/size checked LinPEAS/WinPEAS assets with original notice. All forty candidates retain automated/optional/lab/held dispositions. Windows payloads are staged only. Prowler and legacy wkhtmltopdf are optional; lab servers/sensors/hardware are separately documented. No assessment program, payload, updater, target operation or server was launched by setup.

Actual tests: Windows Python3.12.14 **39 tests,38pass,1native-symlink privilege skip**; exact public Kali Python3.14.7 **39pass** including symlinks, root shell syntax/preview and metadata validation. Initial clean Kali image `sha256:02f5d6c019e549b0f55da58e835cad5355ef1030c6b2645265a324e37dfc4acc` installed prerequisites/Python groups, then BACnet compile failed due upstream routing default. Root disabled routing and resumed successfully. Exact final manifest full same-prefix rerun with **network none + PIP_NO_INDEX=1 + skip-system passed**. It is not a second pristine install or fresh offline dependency closure. Final state binds manifest SHA`b7ee1aaf35391ce8468acf28741b3614972287cd4b35a7ee84894aed6f9dfe24`.

Thirteen disconnected installed-state cases passed: original/restored state accepted; missing apt/native/Python inventory, removed native client/library/Vulscan link/venv config, altered payload, dirty source and absent dpkg installed status rejected; redirected bin refused before command execution. Local evidence: inventory `tmp/farm-installed-state-final.json`, installation log `tmp/farm-kali-exact-final.log`, synthetic regression procedure `tmp/farm_install_smoke.py`. These are local test evidence, not public contents.

Independent review found/resolved **R-FT-04 incomplete required inventory** and **R-FT-05 redirected writes/invalid venv global pip risk**. Reviewer independently repeated reproductions, passive-plan prohibitions,20read-only checker tests,4installer test bodies,90public links/fragments, staged privacy/allowlist checks and exact manifest/state binding. Positive scoped verdict, no actionable findings; root's full environment tests are attributed separately. Git autocrlf fixture and evidence-byte mismatch detected during verification were corrected; LF rules preserve exact hashed fixture/manifest bytes. Final install.py SHA`adc09bc31db62d03ae2b87f0a6988870e1a4d44795a7b0a341cb434cfacf757c`.

Delivery artifacts: [public installation guide](../../../../tooling/farmkit/INSTALL.md), [public proposal](../../../../tooling/farmkit/proposal.md), [spec](../../../../tooling/farmkit/spec.md), [design](../../../../tooling/farmkit/design.md), [verification](../../../../tooling/farmkit/VERIFICATION.md), source-only ZIP `output/farmkit/farmkit-1.1.0.zip`, manifest `output/farmkit/farmkit-1.1.0.manifest.json`, checksum `output/farmkit/farmkit-1.1.0.sha256`. ZIP has23allowlisted files plus internal manifest, 78,106bytes, SHA`c7c80cc3ca8339486a5ece3e78a73af12ee7d69856a179185081d4f21086ebd8`; all members/hashes match current module. Historicalv1.0.0ZIP/manifest remain preserved.

T-FT-10–14 and FR-FT-013/014 are complete for the requested reviewed installation/public contribution. Full original operational acceptance/T-FT-09, Windows execution, protocol/PCAP/traffic/hardware rehearsals, resource measurements, immutable dependency/distro/build/license closure and event staging/eligible student/SOW/freeze approval remain explicit gates. Readiness ledger is not automatically promoted. Proposal/workflow delivery is complete; requester acceptance, merger and operational/event decisions are separate.

Final remote check: GitHub Actions 'Farm toolkit contracts' pull-request run 38763119743 completed successfully for commit 7ccc0a6bbdc3e5488f18f046610f3a271221b81a. CI result is separate from the local installation/rehearsal evidence.
