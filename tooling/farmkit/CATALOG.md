# Tool selection catalog

Evaluation snapshot from catalog.json; checked 2026-10-15. Selected means selected for evaluation. Acquisition/runtime fields are planning-baseline records, not the actual installer inventory. Check install-state.json and the installation checker for local staging; installation does not resolve operational, license or event holds. Farm scenarios are hypotheses.

## Selection

| Tool | Disposition | Protocols | Purpose |
| --- | --- | --- | --- |
| TOOL-001 [LinPEAS](https://github.com/peass-ng/PEASS-ng) | hold | linux-host | Linux host configuration and privilege-path enumeration on authorized servers/gateways |
| TOOL-002 [WinPEAS](https://github.com/peass-ng/PEASS-ng/tree/master/winPEAS) | hold | windows-host | Windows host/HMI/engineering-station configuration enumeration |
| TOOL-003 [Wireshark / TShark](https://github.com/wireshark/wireshark) | selected | packet-analysis | Inspect supplied captures and identify observed IT/OT conversations |
| TOOL-004 [Zeek](https://github.com/zeek/zeek) | conditional | packet-analysis | Turn captures into connection/protocol metadata and support asset hypotheses |
| TOOL-005 [Suricata](https://github.com/OISF/suricata) | conditional | packet-analysis | Offline protocol/event analysis as an alternative or complement to Zeek |
| TOOL-006 [Scapy](https://github.com/secdev/scapy) | conditional | packet-analysis | Flexible packet parsing and synthetic protocol fixtures when a full product is unnecessary |
| TOOL-007 [enum4linux-ng](https://github.com/cddmp/enum4linux-ng) | conditional | smb | Windows/Samba inventory if business systems or file shares are in scope |
| TOOL-008 [NetExec](https://github.com/Pennyw0rth/NetExec) | conditional | smb, ldap | Scope-limited Windows/network service assessment and inventory |
| TOOL-009 [Impacket](https://github.com/fortra/impacket) | hold | smb, msrpc, kerberos | SMB/MSRPC/Kerberos protocol helpers for the IT side of an engagement |
| TOOL-010 [testssl.sh](https://github.com/testssl/testssl.sh) | conditional | tls | TLS configuration review of approved web consoles, remote access or APIs |
| TOOL-011 [ffuf](https://github.com/ffuf/ffuf) | conditional | http | Limited web content discovery on an explicitly approved portal |
| TOOL-012 [Metasploit Framework](https://github.com/rapid7/metasploit-framework) | hold | module-specific | Known module research and controlled lab reproduction; possible scoped IT checks |
| TOOL-013 [PyModbus](https://github.com/pymodbus-dev/pymodbus) | selected | modbus-tcp, modbus-rtu | Modbus TCP/serial clients and synthetic server/simulator; possible pump, meter or environmental controller interfaces |
| TOOL-014 [mbpoll](https://github.com/epsilonrt/mbpoll) | selected | modbus-tcp, modbus-rtu | Convenient Modbus TCP/RTU command-line checks |
| TOOL-015 [libmodbus](https://github.com/stephane/libmodbus) | conditional | modbus-tcp, modbus-rtu | C backend/alternative for Modbus TCP and RTU helpers |
| TOOL-016 [MinimalModbus](https://github.com/pyhys/minimalmodbus) | conditional | modbus-rtu, modbus-ascii | Modbus RTU/ASCII instrument access where serial-only needs justify it |
| TOOL-017 [python-snap7](https://github.com/gijzelaerr/python-snap7) | selected | s7 | Siemens S7 communication and controlled simulator/metadata work if relevant |
| TOOL-018 [cpppo](https://github.com/pjkundert/cpppo) | selected | cip | EtherNet/IP CIP client/server and synthetic fixtures |
| TOOL-019 [pycomm3](https://github.com/ottowayi/pycomm3) | hold | cip | Allen-Bradley/Rockwell-specific EtherNet/IP option |
| TOOL-020 [asyncua / opcua-asyncio](https://github.com/FreeOpcUa/opcua-asyncio) | selected | opcua | OPC UA client/server, namespace inspection and security-mode evaluation |
| TOOL-021 [open62541](https://github.com/open62541/open62541) | lab | opcua | C OPC UA client/server and controlled fixture alternative |
| TOOL-022 [BACpypes3](https://github.com/JoelBender/BACpypes3) | hold | bacnet-ip | Python BACnet option for possible HVAC/ventilation/cold-room controls |
| TOOL-023 [BACnet Stack](https://github.com/bacnet-stack/bacnet-stack) | selected | bacnet-ip, bacnet-mstp | BACnet/IP CLI applications plus synthetic device; MS/TP only if separately supported |
| TOOL-024 [Mosquitto clients and broker](https://github.com/eclipse-mosquitto/mosquitto) | selected | mqtt | MQTT subscriber/client checks and synthetic broker for possible farm telemetry |
| TOOL-025 [Eclipse Paho MQTT Python](https://github.com/eclipse-paho/paho.mqtt.python) | conditional | mqtt | Scriptable MQTT alternative when a reviewed structured adapter is useful |
| TOOL-026 [lib60870](https://github.com/mz-automation/lib60870) | conditional | iec60870-101, iec60870-104 | IEC 60870-5-101/104 lab/client work if energy or remote telemetry is established |
| TOOL-027 [libiec61850](https://github.com/mz-automation/libiec61850) | conditional | iec61850 | IEC 61850 MMS/GOOSE analysis/lab possibility for site power systems |
| TOOL-028 [OpenDNP3](https://github.com/dnp3/opendnp3) | hold | dnp3 | DNP3 reference/lab fallback for outstation/master scenarios |
| TOOL-029 [Gurux DLMS Python](https://github.com/Gurux/Gurux.DLMS.Python) | conditional | dlms-cosem | DLMS/COSEM electricity/water/gas meter client possibilities |
| TOOL-030 [can-utils](https://github.com/linux-can/can-utils) | conditional | can, j1939, isobus-partial | CAN capture/log tools and J1939/ISOBUS utilities for possible vehicle/implement networks |
| TOOL-031 [python-can](https://github.com/hardbyte/python-can) | conditional | can | Flexible CAN log/adapter abstraction and virtual-bus fixtures |
| TOOL-032 [cantools](https://github.com/cantools/cantools) | conditional | can | Decode CAN logs using a supplied DBC or other supported database |
| TOOL-033 [canopen](https://github.com/canopen-python/canopen) | conditional | canopen | CANopen object dictionary/EDS workflows if industrial actuators use it |
| TOOL-034 [pymavlink](https://github.com/ArduPilot/pymavlink) | conditional | mavlink | Offline MAVLink log interpretation if aerial/robotic assets enter scope |
| TOOL-035 [ChirpStack](https://github.com/chirpstack/chirpstack) | lab | lorawan | LoRaWAN server/API reference and synthetic telemetry training |
| TOOL-036 [zigpy](https://github.com/zigpy/zigpy) | lab | zigbee | Zigbee protocol/coordinator reference if sensors/climate devices are established |
| TOOL-037 [OpenPLC Runtime v4](https://github.com/Autonomy-Logic/openplc-runtime) | lab | plc-lab | Small synthetic controller process for agreed protocol fixtures |
| TOOL-038 [FUXA](https://github.com/frangoteam/FUXA) | lab | scada-lab | Synthetic SCADA/HMI dashboard for Modbus, OPC UA, MQTT and S7 rehearsal |
| TOOL-039 [Node-RED](https://github.com/node-red/node-red) | lab | telemetry-lab | Synthetic telemetry and workflow fixtures |
| TOOL-040 [Conpot](https://github.com/mushorg/conpot) | lab | ics-lab | ICS honeypot/service emulation for identification/capture exercises |

## TOOL-001 LinPEAS

PEASS assets are staged by core/full or individually; execution and output integration remain held for the license/module issue below.

- Runtime: Shell on target; review chosen script variant and external commands
- Dependencies: Shell on target; review chosen script variant and external commands
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: None for offline metadata; real capture/serial interfaces need separate permission and hardware.
- Operations: H, A; outputs: text, upstream parsers optional
- License: GPL v2-or-later with custom clarifications/exceptions, not a plain GPL-3 label. Review output-parsing/aggregation terms and third-party components.
- Evidence: [upstream 1](https://github.com/peass-ng/PEASS-ng/blob/master/LICENSE)
- Maintenance: Upstream declaration reviewed; no independent security/dependency audit or maintenance assurance.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#host-enumeration).

## TOOL-002 WinPEAS

PEASS assets are staged by core/full or individually; execution and output integration remain held for the license/module issue below.

- Runtime: Match selected C#/.NET/batch variant and architecture; assess AV/runtime effects
- Dependencies: Match selected C#/.NET/batch variant and architecture; assess AV/runtime effects
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: None for offline metadata; real capture/serial interfaces need separate permission and hardware.
- Operations: H, A; outputs: text
- License: Same PEASS license issue; enumerate potential paths, do not automatically exploit them.
- Evidence: [upstream 1](https://github.com/peass-ng/PEASS-ng/blob/master/LICENSE)
- Maintenance: Upstream declaration reviewed; no independent security/dependency audit or maintenance assurance.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#host-enumeration).

## TOOL-003 Wireshark / TShark

Initial primary-protocol evaluation route; not acquired or runtime accepted.

- Runtime: Linux CLI first; GUI optional; capture privileges only for live capture
- Dependencies: Linux CLI first; GUI optional; capture privileges only for live capture
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: None for offline metadata; real capture/serial interfaces need separate permission and hardware.
- Operations: O, P; outputs: PCAP/PCAPNG, fields/JSON/CSV-style exports
- License: GPL-2.0 family; preserve component notices. Dissector coverage is release dependent. Packet capture needs authorized placement and may contain secrets.
- Evidence: [upstream 1](https://github.com/wireshark/wireshark)
- Maintenance: Upstream declaration reviewed; no independent security/dependency audit or maintenance assurance.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#offline-pcap).

## TOOL-004 Zeek

Use only when authorized technology evidence justifies this capability; avoid redundant dependencies.

- Runtime: Linux binary/build dependencies; optional protocol packages reviewed separately
- Dependencies: Linux binary/build dependencies; optional protocol packages reviewed separately
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: None for offline metadata; real capture/serial interfaces need separate permission and hardware.
- Operations: O, P; outputs: structured logs
- License: BSD-style; plugins have their own provenance. Do not assume complete vendor/OT coverage.
- Evidence: [upstream 1](https://github.com/zeek/zeek/blob/master/COPYING)
- Maintenance: Upstream declaration reviewed; no independent security/dependency audit or maintenance assurance.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#offline-pcap).

## TOOL-005 Suricata

Use only when authorized technology evidence justifies this capability; avoid redundant dependencies.

- Runtime: Linux/Rust/C build or distro package; selected config/rules must be acquired separately
- Dependencies: Linux/Rust/C build or distro package; selected config/rules must be acquired separately
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: None for offline metadata; real capture/serial interfaces need separate permission and hardware.
- Operations: O, P; outputs: EVE JSON
- License: GPL-2.0 family; rules have separate licenses. Use offline/IDS profile; do not deploy inline IPS in the initial kit.
- Evidence: [upstream 1](https://github.com/OISF/suricata)
- Maintenance: Upstream declaration reviewed; no independent security/dependency audit or maintenance assurance.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#offline-pcap).

## TOOL-006 Scapy

Use only when authorized technology evidence justifies this capability; avoid redundant dependencies.

- Runtime: Python; selected layers/contrib modules, capture backend if needed
- Dependencies: Python; selected layers/contrib modules, capture backend if needed
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: None for offline metadata; real capture/serial interfaces need separate permission and hardware.
- Operations: O, A, W; outputs: PCAP and custom structured data
- License: GPL-2.0 family. Restrict initial helpers to offline parsing; raw packet generation is a separate reviewed use.
- Evidence: [upstream 1](https://github.com/secdev/scapy)
- Maintenance: Upstream declaration reviewed; no independent security/dependency audit or maintenance assurance.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#offline-pcap).

## TOOL-007 enum4linux-ng

Use only when authorized technology evidence justifies this capability; avoid redundant dependencies.

- Runtime: Linux/Python plus Samba utilities
- Dependencies: Linux/Python plus Samba utilities
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: None for offline metadata; real capture/serial interfaces need separate permission and hardware.
- Operations: A; outputs: JSON/YAML/text
- License: GPL-3.0. Authentication/enumeration creates traffic; distinguish access denial from absent assets.
- Evidence: [upstream 1](https://github.com/cddmp/enum4linux-ng)
- Maintenance: Upstream declaration reviewed; no independent security/dependency audit or maintenance assurance.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#remote-host-and-directory-clients).

## TOOL-008 NetExec

Use only when authorized technology evidence justifies this capability; avoid redundant dependencies.

- Runtime: Linux/Python with isolated dependency environment
- Dependencies: Linux/Python with isolated dependency environment
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: None for offline metadata; real capture/serial interfaces need separate permission and hardware.
- Operations: A, H, W; outputs: CLI/module-specific output
- License: BSD-2-Clause; modules/dependencies reviewed individually. No spraying, remote execution or bulk modules in default profiles.
- Evidence: [upstream 1](https://github.com/Pennyw0rth/NetExec)
- Maintenance: Upstream declaration reviewed; no independent security/dependency audit or maintenance assurance.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#remote-host-and-directory-clients).

## TOOL-009 Impacket

Held for the license/module/maintenance issue below; no default staging.

- Runtime: Python and isolated dependencies
- Dependencies: Python and isolated dependencies
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: None for offline metadata; real capture/serial interfaces need separate permission and hardware.
- Operations: A, H, W; outputs: tool-dependent text
- License: Slightly modified Apache Software License, per upstream. Do not relabel Apache-2.0; select exact examples and review terms/dependencies.
- Evidence: [upstream 1](https://github.com/fortra/impacket/blob/master/LICENSE)
- Maintenance: Upstream declaration reviewed; no independent security/dependency audit or maintenance assurance.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#remote-host-and-directory-clients).

## TOOL-010 testssl.sh

Use only when authorized technology evidence justifies this capability; avoid redundant dependencies.

- Runtime: Linux/Bash and compatible OpenSSL/dependencies
- Dependencies: Linux/Bash and compatible OpenSSL/dependencies
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: None for offline metadata; real capture/serial interfaces need separate permission and hardware.
- Operations: A; outputs: text/JSON/CSV
- License: GPL-2.0. Many handshakes/probes; choose bounded checks and account for fragile embedded endpoints.
- Evidence: [upstream 1](https://github.com/testssl/testssl.sh)
- Maintenance: Upstream declaration reviewed; no independent security/dependency audit or maintenance assurance.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#tls-and-web-clients).

## TOOL-011 ffuf

Use only when authorized technology evidence justifies this capability; avoid redundant dependencies.

- Runtime: Go binary; reviewed wordlist with separate license/provenance
- Dependencies: Go binary; reviewed wordlist with separate license/provenance
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: None for offline metadata; real capture/serial interfaces need separate permission and hardware.
- Operations: A; outputs: JSON/text and other exports
- License: MIT. Request generation/fuzzing is not a default OT operation; require explicit endpoint and budget.
- Evidence: [upstream 1](https://github.com/ffuf/ffuf)
- Maintenance: Upstream declaration reviewed; no independent security/dependency audit or maintenance assurance.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#tls-and-web-clients).

## TOOL-012 Metasploit Framework

Held for the license/module/maintenance issue below; no default staging.

- Runtime: Ruby/dependencies; substantial optional footprint
- Dependencies: Ruby/dependencies; substantial optional footprint
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: None for offline metadata; real capture/serial interfaces need separate permission and hardware.
- Operations: A, H, W; outputs: module-specific evidence
- License: BSD-style core with component terms. Module/source review required; no blanket ICS exploitation profile.
- Evidence: [upstream 1](https://github.com/rapid7/metasploit-framework/blob/master/LICENSE)
- Maintenance: Upstream declaration reviewed; no independent security/dependency audit or maintenance assurance.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#remote-host-and-directory-clients).

## TOOL-013 PyModbus

Initial primary-protocol evaluation route; not acquired or runtime accepted.

- Runtime: Python; serial/simulator extras optional; pin API and Python versions
- Dependencies: Python; serial/simulator extras optional; pin API and Python versions
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: None for offline metadata; real capture/serial interfaces need separate permission and hardware.
- Operations: A, W, L; outputs: helper-generated structured results
- License: BSD-3-Clause-style terms. Upstream warns of API changes and limited nonstandard-device support. No arbitrary register sweeps.
- Evidence: [upstream 1](https://github.com/pymodbus-dev/pymodbus/blob/dev/LICENSE)
- Maintenance: Upstream declaration reviewed; no independent security/dependency audit or maintenance assurance.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#modbus).

## TOOL-014 mbpoll

Initial primary-protocol evaluation route; not acquired or runtime accepted.

- Runtime: Compiled CLI plus selected libmodbus/libmodbuspp version
- Dependencies: Compiled CLI plus selected libmodbus/libmodbuspp version
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: None for offline metadata; real capture/serial interfaces need separate permission and hardware.
- Operations: A, W; outputs: text
- License: GPL-3.0. Document selected major branch, finite polling, unit/address/type and no-write invocation. Distinct from proprietary modpoll.
- Evidence: [upstream 1](https://github.com/epsilonrt/mbpoll)
- Maintenance: Upstream declaration reviewed; no independent security/dependency audit or maintenance assurance.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#modbus).

## TOOL-015 libmodbus

Use only when authorized technology evidence justifies this capability; avoid redundant dependencies.

- Runtime: C build/native library; serial adapter for physical RTU
- Dependencies: C build/native library; serial adapter for physical RTU
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: None for offline metadata; real capture/serial interfaces need separate permission and hardware.
- Operations: A, W, L; outputs: application-defined
- License: LGPL-2.1-or-later. Useful backend, not another mandatory CLI; avoid duplicate implementations without need.
- Evidence: [upstream 1](https://github.com/stephane/libmodbus)
- Maintenance: Upstream declaration reviewed; no independent security/dependency audit or maintenance assurance.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#modbus).

## TOOL-016 MinimalModbus

Use only when authorized technology evidence justifies this capability; avoid redundant dependencies.

- Runtime: Python + pySerial; approved RS-232/485 interface
- Dependencies: Python + pySerial; approved RS-232/485 interface
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: Conditional adapter/driver and physical-access approval; use synthetic files/virtual bus first.
- Operations: A, W; outputs: application-defined
- License: Apache-2.0. Not a Modbus TCP replacement. Wiring, serial settings and physical access are prerequisites.
- Evidence: [upstream 1](https://github.com/pyhys/minimalmodbus)
- Maintenance: Upstream declaration reviewed; no independent security/dependency audit or maintenance assurance.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#modbus).

## TOOL-017 python-snap7

Initial primary-protocol evaluation route; not acquired or runtime accepted.

- Runtime: Python; exact release determines native vs pure-Python dependencies
- Dependencies: Python; exact release determines native vs pure-Python dependencies
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: None for offline metadata; real capture/serial interfaces need separate permission and hardware.
- Operations: A, W, L; outputs: helper-defined
- License: MIT. Current README describes pure Python and model/access limits; older releases may differ. Do not enable PUT/GET or change controller settings to make a test work.
- Evidence: [upstream 1](https://github.com/gijzelaerr/python-snap7/blob/master/LICENSE)
- Maintenance: Upstream declaration reviewed; no independent security/dependency audit or maintenance assurance.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#s7).

## TOOL-018 cpppo

Initial primary-protocol evaluation route; not acquired or runtime accepted.

- Runtime: Python; selected API/example dependency review
- Dependencies: Python; selected API/example dependency review
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: None for offline metadata; real capture/serial interfaces need separate permission and hardware.
- Operations: A, W, L; outputs: text/structured helper results
- License: GPL-3 with stated exceptions/alternative terms. Use GPL route consistently; choose bounded identity/read operations, not arbitrary CIP services.
- Evidence: [upstream 1](https://github.com/pjkundert/cpppo/blob/master/LICENSE)
- Maintenance: Upstream declaration reviewed; no independent security/dependency audit or maintenance assurance.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#cip).

## TOOL-019 pycomm3

Held for the license/module/maintenance issue below; no default staging.

- Runtime: Python; test selected controller family and API
- Dependencies: Python; test selected controller family and API
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: None for offline metadata; real capture/serial interfaces need separate permission and hardware.
- Operations: A, W; outputs: application-defined
- License: MIT. Upstream explicitly says no longer actively developed. Keep as documented fallback; do not default-stage without ownership and compatibility evidence.
- Evidence: [upstream 1](https://github.com/ottowayi/pycomm3)
- Maintenance: Explicit inactive/archived upstream warning; fallback owner needed.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#cip).

## TOOL-020 asyncua / opcua-asyncio

Initial primary-protocol evaluation route; not acquired or runtime accepted.

- Runtime: Python plus cryptography dependencies/certificates
- Dependencies: Python plus cryptography dependencies/certificates
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: None for offline metadata; real capture/serial interfaces need separate permission and hardware.
- Operations: A, W, L; outputs: CLI or helper output
- License: LGPL-3.0. Pin API/runtime; credentials/trust policy and node reads must be approved. Do not use writes, method calls or trust bypass by default.
- Evidence: [upstream 1](https://github.com/FreeOpcUa/opcua-asyncio)
- Maintenance: Upstream declaration reviewed; no independent security/dependency audit or maintenance assurance.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#opc-ua).

## TOOL-021 open62541

Optional lab/reference system; do not install in an engagement network.

- Runtime: C/CMake; crypto plugins/dependencies selected explicitly
- Dependencies: C/CMake; crypto plugins/dependencies selected explicitly
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: None for offline metadata; real capture/serial interfaces need separate permission and hardware.
- Operations: A, W, L; outputs: application-defined
- License: MPL-2.0; some examples/plugins CC0. Preserve per-file notices. Prefer one sufficient lab/backend over two mandatory stacks.
- Evidence: [upstream 1](https://github.com/open62541/open62541)
- Maintenance: Upstream declaration reviewed; no independent security/dependency audit or maintenance assurance.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#opc-ua).

## TOOL-022 BACpypes3

Held for the license/module/maintenance issue below; no default staging.

- Runtime: Python/asyncio; no MCP/AI extras needed
- Dependencies: Python/asyncio; no MCP/AI extras needed
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: None for offline metadata; real capture/serial interfaces need separate permission and hardware.
- Operations: A, W, L; outputs: CLI/helper output
- License: pyproject says MIT but classifier says BSD. Resolve exact artifact licensing before staging; disable unrelated MCP/AI integration.
- Evidence: [upstream 1](https://github.com/JoelBender/BACpypes3/blob/main/pyproject.toml)
- Maintenance: Upstream declaration reviewed; no independent security/dependency audit or maintenance assurance.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#bacnet).

## TOOL-023 BACnet Stack

Initial primary-protocol evaluation route; not acquired or runtime accepted.

- Runtime: C/compiled apps; select datalink and exact utilities
- Dependencies: C/compiled apps; select datalink and exact utilities
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: None for offline metadata; real capture/serial interfaces need separate permission and hardware.
- Operations: A, W, L; outputs: CLI output
- License: GPL-2.0-or-later WITH GCC-exception-2.0 core; examples include MIT/Apache-2.0. Per-file review required. Bound discovery; default to explicit unicast reads.
- Evidence: [upstream 1](https://github.com/bacnet-stack/bacnet-stack)
- Maintenance: Upstream declaration reviewed; no independent security/dependency audit or maintenance assurance.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#bacnet).

## TOOL-024 Mosquitto clients and broker

Initial primary-protocol evaluation route; not acquired or runtime accepted.

- Runtime: Linux CLI; broker optional; TLS credentials/config separate
- Dependencies: Linux CLI; broker optional; TLS credentials/config separate
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: None for offline metadata; real capture/serial interfaces need separate permission and hardware.
- Operations: A, W, L; outputs: text/topic payloads
- License: EPL-2.0 OR BSD-3-Clause. A subscription sends traffic and can expose retained secrets. No publish/retained changes against a target by default.
- Evidence: [upstream 1](https://github.com/eclipse-mosquitto/mosquitto/blob/master/LICENSE.txt)
- Maintenance: Upstream declaration reviewed; no independent security/dependency audit or maintenance assurance.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#mqtt).

## TOOL-025 Eclipse Paho MQTT Python

Use only when authorized technology evidence justifies this capability; avoid redundant dependencies.

- Runtime: Python; pin callback/API version
- Dependencies: Python; pin callback/API version
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: None for offline metadata; real capture/serial interfaces need separate permission and hardware.
- Operations: A, W; outputs: application-defined
- License: EPL-2.0 / EDL-1.0 dual license. Mosquitto CLI may suffice; do not require both without a concrete use.
- Evidence: [upstream 1](https://github.com/eclipse-paho/paho.mqtt.python/blob/master/LICENSE.txt)
- Maintenance: Upstream declaration reviewed; no independent security/dependency audit or maintenance assurance.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#mqtt).

## TOOL-026 lib60870

Use only when authorized technology evidence justifies this capability; avoid redundant dependencies.

- Runtime: C; serial for 101, TCP for 104; optional TLS dependencies
- Dependencies: C; serial for 101, TCP for 104; optional TLS dependencies
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: None for offline metadata; real capture/serial interfaces need separate permission and hardware.
- Operations: A, W, L; outputs: application-defined
- License: GPL-3.0 open-source route; commercial alternative is not selected. Commands/control services require separate approval.
- Evidence: [upstream 1](https://github.com/mz-automation/lib60870)
- Maintenance: Upstream declaration reviewed; no independent security/dependency audit or maintenance assurance.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#lab-and-conditional).

## TOOL-027 libiec61850

Use only when authorized technology evidence justifies this capability; avoid redundant dependencies.

- Runtime: C; selected Ethernet/TLS/platform capabilities
- Dependencies: C; selected Ethernet/TLS/platform capabilities
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: None for offline metadata; real capture/serial interfaces need separate permission and hardware.
- Operations: A, W, L; outputs: application-defined
- License: GPL-3.0 open-source route; review dependencies. No GOOSE injection or protection/control operations in initial profiles.
- Evidence: [upstream 1](https://github.com/mz-automation/libiec61850)
- Maintenance: Upstream declaration reviewed; no independent security/dependency audit or maintenance assurance.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#lab-and-conditional).

## TOOL-028 OpenDNP3

Held for the license/module/maintenance issue below; no default staging.

- Runtime: C++ build, optional bindings and dependencies
- Dependencies: C++ build, optional bindings and dependencies
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: None for offline metadata; real capture/serial interfaces need separate permission and hardware.
- Operations: A, W, L; outputs: application-defined
- License: Apache-2.0; repository archived in 2022. DNP3 coverage is a selection gap until a maintained alternative or owned lab-only fallback is evaluated.
- Evidence: [upstream 1](https://github.com/dnp3/opendnp3)
- Maintenance: Explicit inactive/archived upstream warning; fallback owner needed.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#lab-and-conditional).

## TOOL-029 Gurux DLMS Python

Use only when authorized technology evidence justifies this capability; avoid redundant dependencies.

- Runtime: Python; chosen transport and credentials; meter model validation
- Dependencies: Python; chosen transport and credentials; meter model validation
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: None for offline metadata; real capture/serial interfaces need separate permission and hardware.
- Operations: A, W; outputs: structured/helper output
- License: GPL-2.0 family upstream declaration. Meter compatibility/authentication and selected modules need testing; do not alter meter configuration.
- Evidence: [upstream 1](https://github.com/Gurux/Gurux.DLMS.Python)
- Maintenance: Upstream declaration reviewed; no independent security/dependency audit or maintenance assurance.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#lab-and-conditional).

## TOOL-030 can-utils

Use only when authorized technology evidence justifies this capability; avoid redundant dependencies.

- Runtime: Linux SocketCAN; vcan for lab, approved adapter for real bus
- Dependencies: Linux SocketCAN; vcan for lab, approved adapter for real bus
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: Conditional adapter/driver and physical-access approval; use synthetic files/virtual bus first.
- Operations: O, P, A, W; outputs: CAN logs
- License: Per-file terms; candump is GPL-2.0-only OR BSD-3-Clause. Initial profile uses logs/listen-only capture; address claiming/replay/transmit are active and excluded. Not a complete agricultural implement decoder.
- Evidence: [upstream 1](https://github.com/linux-can/can-utils/blob/master/candump.c)
- Maintenance: Upstream declaration reviewed; no independent security/dependency audit or maintenance assurance.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#lab-and-conditional).

## TOOL-031 python-can

Use only when authorized technology evidence justifies this capability; avoid redundant dependencies.

- Runtime: Python; backend/driver licenses and hardware vary
- Dependencies: Python; backend/driver licenses and hardware vary
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: Conditional adapter/driver and physical-access approval; use synthetic files/virtual bus first.
- Operations: O, A, W; outputs: CAN log/helper output
- License: LGPL-3.0. Hardware-independent API does not remove adapter or privilege requirements.
- Evidence: [upstream 1](https://github.com/hardbyte/python-can)
- Maintenance: Upstream declaration reviewed; no independent security/dependency audit or maintenance assurance.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#lab-and-conditional).

## TOOL-032 cantools

Use only when authorized technology evidence justifies this capability; avoid redundant dependencies.

- Runtime: Python; authorized/public/synthetic signal database required
- Dependencies: Python; authorized/public/synthetic signal database required
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: Conditional adapter/driver and physical-access approval; use synthetic files/virtual bus first.
- Operations: O; outputs: decoded signals/plots/text
- License: MIT. Without signal definitions, report raw frames/uncertainty; do not guess engineering meaning or upload proprietary DBC files.
- Evidence: [upstream 1](https://github.com/cantools/cantools)
- Maintenance: Upstream declaration reviewed; no independent security/dependency audit or maintenance assurance.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#lab-and-conditional).

## TOOL-033 canopen

Use only when authorized technology evidence justifies this capability; avoid redundant dependencies.

- Runtime: Python + python-can; synthetic EDS and virtual bus initially
- Dependencies: Python + python-can; synthetic EDS and virtual bus initially
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: Conditional adapter/driver and physical-access approval; use synthetic files/virtual bus first.
- Operations: A, W, L; outputs: application-defined
- License: MIT. Not interchangeable with J1939/ISOBUS. NMT commands/SDO writes are excluded from initial profiles.
- Evidence: [upstream 1](https://github.com/canopen-python/canopen)
- Maintenance: Upstream declaration reviewed; no independent security/dependency audit or maintenance assurance.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#lab-and-conditional).

## TOOL-034 pymavlink

Use only when authorized technology evidence justifies this capability; avoid redundant dependencies.

- Runtime: Python; dialect and log format matter
- Dependencies: Python; dialect and log format matter
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: Conditional adapter/driver and physical-access approval; use synthetic files/virtual bus first.
- Operations: O, A, W; outputs: telemetry/log output
- License: LGPL-3-or-later; generated code MIT, per upstream. Start with offline logs; no arming, navigation, parameter updates or radio operation.
- Evidence: [upstream 1](https://github.com/ArduPilot/pymavlink)
- Maintenance: Upstream declaration reviewed; no independent security/dependency audit or maintenance assurance.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#lab-and-conditional).

## TOOL-035 ChirpStack

Optional lab/reference system; do not install in an engagement network.

- Runtime: Server stack/dependencies; gateway/keys only for authorized RF lab
- Dependencies: Server stack/dependencies; gateway/keys only for authorized RF lab
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: Conditional adapter/driver and physical-access approval; use synthetic files/virtual bus first.
- Operations: L, A, W; outputs: API/log data
- License: MIT server; dependencies separate. Not a universal LoRa sniffer or key-recovery tool. Full stack may be too large for event staging.
- Evidence: [upstream 1](https://github.com/chirpstack/chirpstack)
- Maintenance: Upstream declaration reviewed; no independent security/dependency audit or maintenance assurance.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#lab-and-conditional).

## TOOL-036 zigpy

Optional lab/reference system; do not install in an engagement network.

- Runtime: Python plus vendor radio library/coordinator for RF
- Dependencies: Python plus vendor radio library/coordinator for RF
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: Conditional adapter/driver and physical-access approval; use synthetic files/virtual bus first.
- Operations: L, A, W; outputs: helper/log output
- License: GPL-3.0 family with COPYING details; radio libraries separate. Joining/control/OTA are active; not a passive packet sniffer. No automatic firmware downloads.
- Evidence: [upstream 1](https://github.com/zigpy/zigpy/blob/dev/COPYING)
- Maintenance: Upstream declaration reviewed; no independent security/dependency audit or maintenance assurance.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#lab-and-conditional).

## TOOL-037 OpenPLC Runtime v4

Optional lab/reference system; do not install in an engagement network.

- Runtime: Linux; native or reviewed container route; editor/compiler and resource needs require design
- Dependencies: Linux; native or reviewed container route; editor/compiler and resource needs require design
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: None for offline metadata; real capture/serial interfaces need separate permission and hardware.
- Operations: L, W; outputs: synthetic runtime/API logs
- License: MIT core upstream declaration; dependency review needed. Use v4 evaluation, not EOL v3. Do not run upstream pipe-to-shell installers or enable cloud integrations by default.
- Evidence: [upstream 1](https://github.com/Autonomy-Logic/openplc-runtime/blob/main/LICENSE)
- Maintenance: Upstream declaration reviewed; no independent security/dependency audit or maintenance assurance.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#lab-and-conditional).

## TOOL-038 FUXA

Optional lab/reference system; do not install in an engagement network.

- Runtime: Node.js/web stack, selected connectors; optional containers
- Dependencies: Node.js/web stack, selected connectors; optional containers
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: None for offline metadata; real capture/serial interfaces need separate permission and hardware.
- Operations: L, A, W; outputs: synthetic HMI/log evidence
- License: MIT. Lab-only boundary; avoid a heavyweight HMI if minimal protocol fixtures suffice.
- Evidence: [upstream 1](https://github.com/frangoteam/FUXA)
- Maintenance: Upstream declaration reviewed; no independent security/dependency audit or maintenance assurance.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#lab-and-conditional).

## TOOL-039 Node-RED

Optional lab/reference system; do not install in an engagement network.

- Runtime: Node.js; pin any additional protocol node packages separately
- Dependencies: Node.js; pin any additional protocol node packages separately
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: None for offline metadata; real capture/serial interfaces need separate permission and hardware.
- Operations: L, A, W; outputs: synthetic flows/logs
- License: Apache-2.0 core; contributed nodes have independent licenses/security. No remote flow downloads, dashboard exposure or customer credentials.
- Evidence: [upstream 1](https://github.com/node-red/node-red)
- Maintenance: Upstream declaration reviewed; no independent security/dependency audit or maintenance assurance.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#lab-and-conditional).

## TOOL-040 Conpot

Optional lab/reference system; do not install in an engagement network.

- Runtime: Python, selected templates and dependencies
- Dependencies: Python, selected templates and dependencies
- Privileges: Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.
- Hardware: None for offline metadata; real capture/serial interfaces need separate permission and hardware.
- Operations: L; outputs: synthetic logs/captures
- License: GPL-2.0. Emulation does not certify actual PLC behavior. Disable external intelligence feeds/telemetry and isolate the lab.
- Evidence: [upstream 1](https://github.com/mushorg/conpot)
- Maintenance: Upstream declaration reviewed; no independent security/dependency audit or maintenance assurance.
- Owner: Eligible student maintainer (unassigned); runtime: not run; acquisition: not acquired.
- [Runbook](RUNBOOKS.md#lab-and-conditional).
