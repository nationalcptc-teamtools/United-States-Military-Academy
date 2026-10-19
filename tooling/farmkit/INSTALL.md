# Install the assessment suite

Use a disposable **Kali Linux x86-64** workstation with Python 3.10+ and Internet during preparation. Allow several GB of free disk space for distro packages, isolated Python environments and native builds. The full profile was exercised on the Kali image recorded in [VERIFICATION.md](VERIFICATION.md). Windows is a payload destination, not an installer host. Run setup as your normal user; it uses sudo for apt only. A root-owned prefix requires root for later maintenance.

From the repository root:

```sh
bash install.sh --plan
bash install.sh --profile full
source .cptc-suite/activate
bash install.sh --check --profile full
```

The default is `full`. Use `--prefix /absolute/trusted/path` consistently on install and check to choose another location. Do not move the repository or prefix afterward: the activation and reporting wrapper contain their installation paths. Rerun setup at the final location if necessary. The prefix must be trusted and quiescent while installing/checking; this is not a sandbox against concurrent file replacement. Existing redirected paths, modified source checkouts and mismatched payloads fail without being overwritten. Existing unrelated `vulscan` directories/links must be moved aside by their owner before installation.

`--profile core` installs the eight selected protocol/packet-analysis backends, reporting and PEASS assets with fewer IT/extended-protocol components. It is intended for apt-based Linux but only Kali full installation has been exercised. `--skip-system` is an advanced option for pre-provisioned packages; it still requires and checks the complete package set. `--with-prowler` adds Kali's Prowler package. `--with-legacy-pdf` requests the unused legacy wkhtmltopdf package, if the selected distro still offers it. These two options are not part of the tested default; their apt failures are errors. ReportLab PDF generation is included by default. The old super_nmap wrapper is retired; see the migration guide.

## What full installs

| Component | Installation and location |
| --- | --- |
| Linux/Windows enumeration | SHA-256 and size checked `linpeas.sh` and `winPEASx64.exe` in `.cptc-suite/payloads`; original PEASS license retained; neither is executed. WinPEAS x64 requires Windows/.NET Framework 4.8. |
| Packet/IT clients | Distro nmap, TShark, Mosquitto clients, can-utils, ffuf, testssl.sh, smbclient, enum4linux-ng and NetExec. Impacket arrives through distro dependencies, with its own notices. |
| Primary OT Python | PyModbus, python-snap7 and asyncua in `venvs/ot`; cpppo in separate `venvs/cip` to isolate its older greenery and crypto_licensing dependency constraints. |
| Extended Python | Scapy, MinimalModbus, Paho MQTT, python-can, cantools, canopen, Gurux DLMS and pymavlink in `venvs/extended`. Serial/CAN/radio access still needs hardware, privileges and explicit scope. |
| Native clients | Source-pinned mbpoll and BACnet Stack ReadProperty client in `bin/mbpoll` and `bin/bacnet-readprop`. BACnet routing and non-IPv4 transports are disabled in this client build. |
| Energy protocol libraries | Source-pinned lib60870 and libiec61850 under `lib/` and `include/`; SDKs for later reviewed clients, not ready-made assessment workflows. TLS/R-GOOSE/R-SMV are not enabled by this build. |
| Existing Nmap integration | Source-pinned Vulscan checkout with repository `vulscan` link. No database updater or NSE script is run. Its upstream COPYING file contains unresolved merge markers; this is preserved and explicitly not license-cleared by setup. |
| Reporting | Isolated ReportLab/python-docx environment and `bin/cptc-report` forwarding to the existing repository reporter. Completed synthetic report JSON and curated updates; native farm-tool adapters remain deferred. |

Exact source commits, top-level Python versions, asset hashes and all forty catalog dispositions are in [install-manifest.json](install-manifest.json). [CATALOG.md](CATALOG.md) remains the capability, operation and license reference. `plan` lists both profile components and all forty dispositions; entries outside the chosen profile remain uninstalled even when their general method is automated.

Activation adds OT Python first on PATH. For an isolated group explicitly select its interpreter, for example `.cptc-suite/venvs/cip/bin/python`. Most library packages require a separately reviewed client; installation does not create a scope-approved operation. PEASS output parsing/aggregation and other held integration paths remain held. Installing unmodified upstream assets on a team workstation is separate from approving redistribution or using their output.

## Integrity, offline use and failure recovery

The installer obtains signed distro packages through apt, exact top-level Python versions through pip, full Git source commits, and byte-pinned PEASS release assets. It records actual distro versions, resolved Python packages and built native file hashes in `install-state.json`. Transitive Python packages and rolling distro versions are **resolved and recorded, not fully locked**. This is an online preparer for an offline-capable workstation; it does not implement fresh offline reinstallation, a dependency cache, a reproducible distro snapshot, a signed software bill of materials or complete license closure. Preserve an approved workstation image and the inventory if event staging allows it; do not upload local prefixes or images to this repository.

`check` needs no Internet. It checks required profile membership, installed distro status, isolated Python identities/top-level versions/dependency consistency, clean pinned source checkouts, native file hashes, PEASS bytes, notices and the legacy Vulscan link. It does not run assessment programs, import their libraries, execute payloads or start servers. It does not authenticate human license/event assertions or verify every installed dependency byte. `kit.py readiness` deliberately remains pending until separate operational evidence exists; installer success never promotes it.

On error setup returns nonzero and leaves an incomplete inventory with the last/failed step. Review the local terminal output and inventory. Correct a temporary prerequisite/network problem and rerun with the same profile/prefix. A partially fetched source directory without HEAD must be preserved/moved aside by its owner before retry. Modified files or a release asset that changes bytes require investigation and a reviewed manifest update, not bypassing checks. apt changes are system-wide and are not rolled back on failure. To discard a suite, use the disposable workstation or remove only the explicitly chosen prefix and its repository Vulscan link; setup never recursively deletes it for you.

## Optional servers, hardware and held tools

Lab systems are separate opt-in projects on an isolated lab network. Follow the canonical upstream setup, choose a reviewed version and its own environment, and record it separately. Do not install these into the suite's Python environments or start them on a competition host by default.

| Option | Upstream setup / boundary |
| --- | --- |
| Mosquitto broker | [Mosquitto downloads](https://mosquitto.org/download/); broker is separate from installed clients. Bind only to the approved lab interface. |
| open62541 | [Upstream build instructions](https://github.com/open62541/open62541); use a separate synthetic OPC UA server. |
| ChirpStack | [Official documentation](https://www.chirpstack.io/docs/); optional LoRaWAN server and radio infrastructure. |
| zigpy | [Canonical repository](https://github.com/zigpy/zigpy); separate coordinator/backend environment and approved radio hardware. |
| OpenPLC v4 | [Current runtime](https://github.com/Autonomy-Logic/openplc-runtime); legacy v3 is end of life. Isolated simulation only. |
| FUXA | [Canonical repository](https://github.com/frangoteam/FUXA); separate HMI lab. |
| Node-RED | [Official installation](https://nodered.org/docs/getting-started/); separate lab runtime and reviewed nodes. |
| Conpot | [Canonical repository](https://github.com/mushorg/conpot); separate Python and protocol dependencies. Do not merge its constraints into the assessment environments. |
| Zeek / Suricata | [Zeek setup](https://docs.zeek.org/en/current/install.html), [Suricata setup](https://docs.suricata.io/en/latest/install.html); optional sensors requiring deployment/resource planning. No sensor service is installed by default. |

Held paths remain explicit: selected Metasploit modules, BACpypes3 license mismatch, inactive pycomm3, archived OpenDNP3, and PEASS/Impacket output integration. Zeek, hardware paths and lab systems are not silently omitted from coverage: their disposition is visible in the manifest/catalog. DNP3 has no accepted maintained backend. CAN/J1939 decoding does not establish complete ISOBUS coverage. Actual asset/protocol/Windows/hardware/traffic rehearsals and event rules remain separate acceptance gates in [RUNBOOKS.md](RUNBOOKS.md).

## Patch 1.1.1 preparation changes

The reporting environment now declares both pinned dependencies from the active reporter: ReportLab 4.4.9 and python-docx 1.2.0. Existing inventories bound to the previous manifest must be prepared and checked against this changed manifest before acceptance. This declaration correction has synthetic test evidence; no fresh installation of the revised manifest was performed in this maintenance cycle. Prior installation/host/protocol results do not certify these new bytes. Saved inventory schema/native paths/digests are validated before metadata commands; malformed state is a controlled failure, not evidence of an accepted installation.

## Individual additions and optional preparation

Use [one-line onboarding](ONBOARDING.md) to select any catalog tool or preparation utility independently, including optional sensors and isolated lab acquisition. Existing profile checks are unchanged.
