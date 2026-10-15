# Independent review: farming toolkit preparation package

Reviewed: 2026-10-15. Reviewer: read-only `/root/validation_review`. Editor/developer: root assistant. Product: `tooling/farmkit/`, v1.0.0. Root records this returned review without changing its conclusions.

## Scope and independence

Reviewer did not implement, edit, install, publish or execute upstream tools. Inspected all fifteen module files, actual release ZIP/sidecars, proposal/spec/design/tasks/execution/verification and project constraints. Checks used bundled Python 3.12.14 on Windows, read-only filesystem access and in-memory builder output. No target/client material processed; root retained sole editing ownership.

## Separate conclusions

**Specification:** Local preparation package implements the catalog, selection/source records, integrity checker, bounded rehearsal guidance and readiness reporting described by design. All nineteen original requirements have design mappings and all forty dispositions remain, including LinPEAS/WinPEAS.

Full original acceptance remains pending: actual acquisition/dependency closure, artifact licensing, clean Kali/Windows operation, host enumeration, selected parser/protocol rehearsals, measured traffic/resources, hardware, eligible operational ownership and event/staging/freeze decisions. The specification, verification matrix and readiness records preserve these gaps.

**Implementation quality:** Positive for this inspected local preparation package. R-FT-01–03 were independently identified, corrected by root and independently rechecked. **No remaining actionable findings in scope.** This is not competition readiness, third-party license compliance or approval to publish/use upstream tools.

## Findings and disposition

| ID | Severity | Evidence / impact | Correction and final disposition |
| --- | --- | --- | --- |
| R-FT-01 | P2 | Shared text validation accepted escaped unpaired surrogates; listing a tool name could throw UnicodeEncodeError under strict UTF-8 output. A programmatic NUL input path also bypassed stable rejection. | Resolved: kit.py:43 rejects surrogates; kit.py:97 rejects NUL paths; tests/test_kit.py:81 regression. Independent reproductions return exit 2 without traceback. |
| R-FT-02 | P2 | TOOL-037 claimed v4 MIT licensing with legacy OpenPLC v3 as its sole license-evidence link. | Resolved: catalog.json:1718 and CATALOG.md:600 reference current v4 LICENSE, independently read and confirmed MIT. Notices retain v3 only as EOL/history evidence. |
| R-FT-03 | P2 | TOOL-020/021 linked to #opcua, while the OPC UA heading produces #opc-ua. | Resolved: catalog.json:941/988 and CATALOG.md:348/363 corrected; tests/test_kit.py:305 checks fragments. Independent module target/fragment check passes. |

## Independent checks

- **2,064 schema/type mutations** across catalog/sources/lock/readiness: no unexpected exceptions.
- **40 targeted adversarial checks** passed: malformed/duplicate/nonfinite/oversized/deep JSON, unsafe paths, missing/tampered/wrong-size artifacts, dependency errors, synthetic/upstream separation, unsafe text and disabled network/process paths.
- **20 existing tests** with read-only/in-memory behavior independently passed. Complete suite was not independently run because other tests write temporary files.
- Actual command functions with socket, DNS and process creation blocked returned validate/list/synthetic verify/empty verify/readiness codes **0/0/0/3/3**.
- Forty tools: **8 selected, 18 conditional, 7 lab, 7 held**. All remain not_acquired/not_run; all selected license reviews pending. No staged/runtime acceptance fabricated.
- **53 module local links including fragments** passed. All nineteen IDs map to design.
- Runbooks inspected for finite requests, explicit destinations, timeout/retry/stop/cleanup, active-read labeling, host holds and no default write/control behavior. Effects remain explicitly untested.
- Public content has generic synthetic examples, no customer/local-user paths, real inventories or private-key material. No upstream payload included.
- Actual ZIP: **16 members**, exact fifteen-file allowlist, byte identity to current source, correct internal hashes/sizes and preparation-only declaration. Two in-memory builds matched each other and the delivered ZIP byte-for-byte.
- Sidecar checksum matches ZIP; sidecar/internal manifest JSON agrees (newline encoding differs).
- Existing reporting generator retains `61e58c2c636f22afdad34a686cb0302510cabbc23ef199770111beb2d258ab0b`.

Root separately ran the full suite: **27 tests, 26 passed, one native-symlink privilege skip**. Independent mocked symlink/reparse checks passed. Native symlink capability and an independent full-suite execution are not claimed.

## Inspected identity

| Artifact | SHA-256 |
| --- | --- |
| kit.py | `fcf270196ffa994a8b1ccbdce2e48f508a5e2eca62922cda0265bb487dd08861` |
| build.py | `2377152bdbfea4797e98786251febef96e7ab7bfb746f15549057852339b77e3` |
| catalog.json | `fbb2ee2c42de6fa8dd756dbaa42eeacbd85a6e060da3a3f755dd77d0bac16d68` |
| sources.json | `41a36db41adbcdcd45b95aeb4dffd33e23268ce4d564a592931a06dfbcc0178b` |
| readiness.json | `ec7e32f9bc66953cf5505e5319bf7672116633acb31c7c982bd84fb88441014e` |
| RUNBOOKS.md | `c60d8593b271869466bb4736c350a1758d5162eb69c778f3889b804c1ff112c2` |
| tests/test_kit.py | `774b827544b33cbc3ae0d764ae1646238094e0913b833d2350383dfd00b1fc21` |
| farmkit-1.0.0.zip, 46,590 bytes | `de166b1b1a5c2628fe926dccd9d5039c2d3f8fd30b273b4e29e03db08a78fab0` |

Internal manifest identifies every package file. Later private status/journal changes do not alter the reviewed package.

## Limits and handoff

Checker establishes record consistency and supplied-byte integrity, not human evidence authenticity, complete dependencies, license interpretation, upstream authenticity or runtime safety. The documented trusted/quiescent artifact-root assumption applies.

**Local role-cycle delivery may proceed.** All findings resolved; original operational acceptance gaps remain explicit. T-FT-09, user acceptance, publication and competition authorization are separate.

## Installer/publication review extension — 2026-10-15

Independent read-only `/root/validation_review` returned a positive scoped verdict with no remaining actionable findings. R-FT-04/05 resolved and independently rechecked; exact state/manifest binding confirmed. Independently passed20read-only checker and4installer test bodies, passive-plan prohibitions,90links, public privacy/28-file allowlist and checked Git newline handling. Root executed full Windows/Kali and13disconnected cases; reviewer inspected logs/procedure rather than rerunning installation. Original R-FT-01–03 remain resolved. Acceptance limits and exact code/manifest hashes are in the final verification addendum and public VERIFICATION.md. Publication verified as [PR #2](https://github.com/nationalcptc-teamtools/United-States-Military-Academy/pull/2), no merge.
