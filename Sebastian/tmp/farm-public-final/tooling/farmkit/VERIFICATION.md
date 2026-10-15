# Verification and acceptance limits

Version 1.1.0, tested 2026-10-15. Tests use synthetic files and disposable local containers; no customer/competition target was contacted. This record separates contract tests, installed-software checks and pending operational/event acceptance.

## Actual checks

| Check | Observed result |
| --- | --- |
| Original preparation package v1.0.0 | 27 unit tests: 26 pass, one Windows native-symlink privilege skip. Independent review performed 2,064 contract mutations, 40 targeted adversarial cases, 20 read-only tests, links and source-only package verification. |
| Extended contracts on Windows Python 3.12.14 | 39 unit tests: 38 pass, one native-symlink privilege skip; mocked redirect tests pass. Covers pure preview, incomplete-state preservation, subprocess/timeout failures, wrong/dirty sources, broken/non-venv refusal, download size/hash/existing tamper and prior schema/path/readiness/ZIP regressions. |
| Kali installation | Initial clean `kalilinux/kali-rolling` image digest `sha256:02f5d6c019e549b0f55da58e835cad5355ef1030c6b2645265a324e37dfc4acc`; Python 3.14.7. Online full prerequisites and all four Python groups installed. Initial BACnet compile failed because upstream routing default was enabled. After disabling routing, full installation resumed with the same prerequisites/clean pinned sources and completed all native builds, payload byte checks and final installation verification. The corrected installer was not separately run from a second pristine image. |
| Disconnected installed-state checks | A local snapshot of the installed test environment is run with Docker `--network none`. Unchanged inventory passes; omitted apt/native/Python inventories, removed client/library/Vulscan link/venv config, changed PEASS bytes, dirty source and uninstalled dpkg status fail. Redirected bin is rejected before commands; restored original state passes. |
| Installer execution boundary | Acquisition/build operations only. No PEASS execution, protocol queries, Nmap/NSE execution, scan, database updater, lab server or target activity. Metadata check runs Python environment identity/pip metadata and Git/dpkg status, without assessment-library imports or entry-point execution. |

Observed distro versions include TShark 4.6.6-1, Nmap 7.991+dfsg-1kali1, NetExec 1.5.1-0kali2, enum4linux-ng 1.3.10-0kali1, Mosquitto clients 2.1.2-3, libmodbus-dev 3.2.0-1 and CMake 4.3.4-1. Distro versions differ from source-reference candidates in sources.json; the latter are researched alternatives, not a claim that apt installed those exact versions. Full resolved versions and native hashes are recorded locally by install-state.json; the public manifest records top-level Python/source/asset identities.

## Review findings

The original review defects are resolved: R-FT-01 rejects malformed Unicode/NUL input without traceback; R-FT-02 corrects OpenPLC v4 license evidence; R-FT-03 fixes OPC UA documentation anchors. Independent installer review then found R-FT-04 (a saved empty inventory could verify without required components) and R-FT-05 (existing child symlinks could redirect writes). The implementation now derives required profile sets, checks dpkg installed status, Python environment/dependency consistency, native/library/source/link identities and file hashes; managed write paths reject redirects and pip requires the expected actual venv identity. Final review must inspect the settled public files and regression evidence before publication.

The public contribution preserves unrelated in-progress reporting edits outside this PR. The root README installer hunk is staged separately from those edits. No reporting source, private planning, source originals, installed prefix, upstream payload, capture, user path, credentials or real findings are part of the publication set. CI adds contract tests on Linux/Windows Python 3.10/3.12; CI execution results are separate from local test results.

## Acceptance still pending

FR-FT-001–004/007/009 and preparation portions of FR-FT-008/011 have catalog, validation, runbook and public-interface evidence. FR-FT-013 has actual full assessment installation evidence. FR-FT-014 completes only after independent review and verified commit/PR publication. No original criterion is deleted by this extension.

FR-FT-005 actual Linux/Windows host enumeration; FR-FT-006 full immutable dependency/license/build closure and fresh offline reinstall; FR-FT-010 protocol/PCAP/traffic rehearsals; FR-FT-012 actual event/SOW/staging/freeze approval remain open. NFR-FT-003 actual tool-version/synthetic operation checks without Internet, full setup-time/disk/RAM measurements, NFR-FT-004 measured operational load/stop behavior, and NFR-FT-002/006 full artifact/license/maintenance acceptance remain partial. Core on non-Kali Linux, other CPU architectures, optional Prowler/wkhtmltopdf/sensors/lab servers, Windows/.NET execution and serial/CAN/radio hardware are not tested. Successful software installation and hashes do not establish process safety, blanket compatibility or event permission.

`kit.py readiness` and the real artifact lock remain pending historical preparation records. Installer state is a separate local installation inventory and is never automatically converted into operational acceptance. Consult [the specification](spec.md), [install guide](INSTALL.md) and [runbooks](RUNBOOKS.md) for decisions, boundaries and next rehearsals.
