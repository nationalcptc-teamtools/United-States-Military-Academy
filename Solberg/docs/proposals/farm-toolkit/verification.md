# Farming toolkit verification

Tester: root, with independent read-only `/root/validation_review` checks separately attributed in [review.md](review.md). Date: 2026-10-15. Runtime: bundled Python 3.12.14 on Windows. Product: local preparation module v1.0.0. No upstream tool or target was executed.

## Actual checks

- `python -B -m unittest discover -s tooling/farmkit/tests -v`: current suite 27 tests, **26 passed, 1 skipped** (native symlink creation privilege unavailable). Mocked symlink/reparse rejection ran and passed. Covers duplicate/oversized/deep/nonfinite/malformed JSON, control/surrogate strings, IDs/types/holds/coverage, source pins, lock/hash/size/dependency/path checks, missing/tampered artifacts, local CLI paths, pending readiness, offline/no-process behavior, package allowlist/hashes/repeatability and refused overwrite.
- Actual CLI validate, selected list, synthetic artifact verification, empty inventory and readiness paths exercised. Expected pending readiness is exit 3, not a passed runtime check. Passing the synthetic hash demonstrates integrity-helper behavior only.
- All 40 IDs/dispositions retained: 8 selected, 7 held, 7 lab and 18 conditional. Nine source projects cover eight selected routes plus the shared PEASS source; all acquired-byte hashes are null and every tool runtime remains not-run.
- Public module audit finds 15 allowlisted source/doc/data/test/fixture files, with no customer name, local user paths, OneDrive paths, secret/private-key markers or real outputs. Each package member is hashed. Independent content review remains part of T-FT-07.
- Before status-document updates, all 23 captured baseline files (original Analyst documents, reporting files/role records, AGENTS/workflow) were unchanged. Proposal/spec status additions are intentional; research catalog/reporting/AGENTS/workflow remain preserved. Integration checkout is clean at its existing reporting HEAD; no integration changes/push occurred.
- Local Markdown links, all nineteen design mappings, generated catalog metadata and source/reference boundaries checked. Settled counts/hashes/package details are appended to the task/journal delivery record.

Initial defect evidence: a 1,500-level JSON input was accepted by the host JSON parser, contrary to the desired bounded nesting check. Added an explicit 32-level bound and reran affected/full checks. Independent review later identified surrogate-output failure (R-FT-01), an OpenPLC v3 link incorrectly serving as v4 license evidence (R-FT-02), and two OPC UA runbook fragments missing a hyphen (R-FT-03). Root corrected all three and added regressions, including heading-fragment validation. Final independent disposition is in review.md.

## Requirement coverage and gaps

“Local pass” describes the preparation artifact/contract check only. Partial/not-run rows preserve the full original acceptance requirement.

| Requirement | Available result | Outstanding original acceptance |
| --- | --- | --- |
| FR-FT-001 | Local pass: 40 dispositions/reasons and named PEASS entries | Selection may change with authorized asset evidence. |
| FR-FT-002 | Local metadata/schema pass | Exact runtime/hardware/maintainer/license/smoke evidence pending. |
| FR-FT-003 | Local pass: primary candidate coverage and serial constraints | Actual protocol/model compatibility not demonstrated. |
| FR-FT-004 | Local pass: conditional/lab/gap coverage | Physical/RF/vendor scope unknown; DNP3 maintained option unresolved. |
| FR-FT-005 | Partial: synthetic host procedure provided | Actual Linux and Windows host-enumeration path not run. |
| FR-FT-006 | Partial: exact source references and synthetic integrity tests pass | No real upstream bytes, build/dependency closure, signatures or release smoke tests. |
| FR-FT-007 | Local pass: no tool/network execution path; active procedures explicitly gated | Future active profiles need scope/budget validation. |
| FR-FT-008 | Partial: bounded request/timeout/stop/evidence runbooks | Exact invocations and measured lab side effects not run. |
| FR-FT-009 | Local pass: synthetic status/evidence example boundaries | No report adapter or real-data handling acceptance claimed. |
| FR-FT-010 | Not run: actual selected-parser and six-protocol rehearsal | Requires reviewed tools, synthetic services and traffic observation. |
| FR-FT-011 | Partial: inspected baseline, exact public package and integration checklist | This package publication, eligible maintainer assignment and event approval pending. |
| FR-FT-012 | Partial: readiness/freeze decisions preserved | Actual event/timezone/SOW, approved staging/frozen artifact evidence unknown. |
| NFR-FT-001 | Local pass: hypotheses/evidence/readiness separated | Real observations require future source evidence. |
| NFR-FT-002 | Partial: attribution/holds/evidence preserved | Artifact-specific license/source/notice review before redistribution. |
| NFR-FT-003 | Partial: helper is standard-library/offline and checked with network/process blocked | Clean agreed Kali and Windows upstream runtime/install/resource tests not run. |
| NFR-FT-004 | Partial: explicit finite rehearsal ceilings and stop paths | No universal safe rate claimed; actual measured behavior pending. |
| NFR-FT-005 | Local public-content/allowlist checks pass | Engagement storage/export control remains an operational responsibility. |
| NFR-FT-006 | Partial: dated declarations, inactive holds and update policy | Actual dependency/security/maintenance acceptance and named owner pending. |
| NFR-FT-007 | Local links/IDs/contracts/design mapping checked | Independent current-version verdict recorded separately; full acceptance pending. |

Full original specification acceptance remains pending T-FT-09. A positive local implementation review does not change this matrix into competition readiness.

Independent review completed against the exact delivered ZIP, SHA-256 `de166b1b1a5c2628fe926dccd9d5039c2d3f8fd30b273b4e29e03db08a78fab0`. Scoped positive verdict; all three findings resolved/rechecked. Reviewer independently exercised 2,064 schema/type mutations, 40 targeted adversarial checks, 20 read-only/in-memory tests, 53 module links/fragments and exact ZIP/member/manifest/repeatability checks. No full independent temporary-file suite or upstream/runtime tests claimed. T-FT-01–08 complete for local delivery; T-FT-09/user acceptance remain pending.


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
