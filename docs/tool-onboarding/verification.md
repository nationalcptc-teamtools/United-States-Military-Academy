# Verification

Verified 16 October 2026 America/New_York (17 October UTC). Controller SHA-256 `703f96c64eb7ac4a55e1215c2059d89ab4ad163ae5895b07da44b4e54852cfbc`; registry `a740ba167118358a42e20ad5d918c80202713b1ab031f03e6ed1cafd3ce70cdd`. Source base: `96c7be5751f4a2ea862af58ef40428da098e5d84` plus preserved audited maintenance fixes. Farmkit/workbench application 1.2.0; reporter 0.5.1; schemas unchanged.

## Synthetic checks

Supported-host verification used disposable Kali Rolling 2026.3 amd64, Python 3.14.7, based on local image ID `sha256:d54316edbdf4d05ecb828ac5aa98f98f12865a884f5ae5c4c1644cd5a0a156e2`. It already contained the older suite prerequisites; this is a fresh individual prefix, not a pristine operating-system installation.

| Suite | Result |
| --- | --- |
| Legacy configuration | 13 passed |
| Reporting, with installed reporting dependencies | 60 run, 59 passed, 1 optional pypdf QA skip |
| Workbench, with installed reporting dependencies | 33 run, 32 passed, 1 optional pypdf QA skip |
| Farmkit including 22 new onboarding regressions | 65 passed on Linux |

Total supported-host checks: 171 run, 169 passed and two optional QA skips. Commands were `python -m unittest discover -s DIRECTORY` for `tests`, `tooling/reporting/tests`, `tooling/workbench/tests`, and `tooling/farmkit/tests`; reporting/workbench used the selected reporting environment. The initial system-Python run lacked its optional report dependencies and failed accordingly; rerunning with the documented reporting environment produced the results above.

Windows checks separately passed configuration (13), reporting (60) and all 22 onboarding regressions. Two full workbench attempts each encountered a different transient `WinError 5` during directory publication; this environment limitation remains recorded and is not reported as a full Windows pass. Linux workbench results passed. Farmkit Windows package checks retain the native-symlink privilege skip; the farmkit-only archive also skips its existing sibling-reporter equality check because that module is deliberately absent.

The new regressions exercise complete/unique catalog selection, duplicate selection, no-write/no-process plans, individual closure, held preflight, invalid pins, unsupported hosts, malformed/incomplete state before commands, path escape rejection, native output membership, pinned asset bytes, changed/missing images/files, no-start image/Compose acquisition, Vulscan link independence, symlink archive rejection, completed-selection reuse and incomplete failure receipts. Independent reviewers additionally checked all 74 selections and package links.

## Actual acquisition and independent utility examples

The following real preparation command completed in the disposable Linux environment using a new prefix:

```sh
python3 tools.py install syft pip-tools reporting open62541 ffuf libreoffice zigpy vulscan linpeas --prefix /opt/cptc-final
python3 tools.py check syft pip-tools reporting open62541 ffuf libreoffice zigpy vulscan linpeas --prefix /opt/cptc-final
```

The selection installed exact Python top-level pins, acquired and size/hash-verified Syft and LinPEAS, staged the pinned Vulscan reference, installed LibreOffice Writer through apt, and built open62541 1.5.9 at its pinned commit. Only the SDK and two firststeps example targets were built; encryption and interprocedural optimization were explicitly disabled. No example, payload or assessment was executed. Repeating installation reused completed receipts without apt changes. The final passive check also passed with the container disconnected from its network.

All eight image/lab acquisition recipes were exercised through the same acquisition/check functions against the reviewed controller: Zeek, community Suricata, Node-RED, FUXA, Mosquitto broker, OpenPLC, ChirpStack and Conpot. Eleven distinct Linux amd64 OCI images were acquired by immutable digest, including all six ChirpStack components; Conpot 1.0.0 was built from its pinned source Dockerfile and its local image ID checked. ChirpStack's seven service image overrides matched the six acquired identities. Acquisition tests ran against Docker's local image store on the preparation host; they did not certify a fresh Linux Docker installation or start any of those runtimes. An intermediate run rejected receipts after controller edits as designed; all eight were reacquired/rechecked against the frozen source and passed.

The documented independent examples also completed:

- Syft generated and parsed a local CycloneDX SBOM of the public reporting source using the included no-update/no-enrichment configuration.
- pip-tools generated the reporting hash lock; a fresh matching Python environment installed it with `--require-hashes` and passed `pip check`.
- The existing reporter exported the synthetic example as DOCX; LibreOffice Writer 26.8.0.3 converted it to a PDF with a fresh user profile. PDF signature/existence checked. A container dconf configuration warning did not prevent conversion. Native Microsoft Word pagination remains uncertified.

No client data, assessment target, live capture, sensor, broker, PLC runtime, HMI, honeypot or Node-RED flow was used or started. Upstream build/package endpoints were contacted for preparation only.

## Portable packages and documentation

Both source packages were built twice with identical bytes in the same Python/zlib runtime, extracted, and exercised. Farmkit contains 45 members; workbench contains 82, below its existing 100-member inspection bound. Every direct new onboarding guide/diagram/spec link is present. The extracted root `tools.py plan zeek pip-tools` works in both. Extracted farm tests passed: 65 run, 63 passed/two explicit skips in farmkit-only; 65 run, 64 passed/one native-symlink skip in workbench. A legacy failure-state test originally assumed the sibling reporter existed; it now supplies its own synthetic prerequisite so it tests the intended failure path in either package.

The new SVG was rendered and visually inspected by root and an independent reviewer: all five cards, connectors and footer fit and match the established guides. The existing link checker reported 289 consistent local references across the changed operational guides. Independent implementation and specification reviews passed after all recorded R-ON-* findings were resolved; see review.md.

## Limits

No universal transitive lock, fresh offline reinstall cache, complete license closure, real protocol/hardware workflow, native scanner adapter, broader CI or event acceptance is claimed. Distro/transitive dependencies and Conpot base/build inputs remain resolved rather than completely locked. Held selections retain their reasons. The existing core/full installer was not freshly reinstalled in this task; its previous verification remains historical. Current individual acquisitions and source packaging do not replace the separate readiness/operational approval process.
