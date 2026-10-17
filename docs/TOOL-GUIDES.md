# Catalog tool guides

This is the operator index for all forty catalog entries. It uses the checked-in catalog, not a new upstream compatibility assessment. Use the selected release and verify its actual help/API before rehearsal. Library/SDK entries need an authored, reviewed helper; they are not drop-in command-line tools. Held and lab-only entries retain their restrictions.

For individual preparation one-liners, see [tool onboarding](../tooling/farmkit/ONBOARDING.md). For repository-owned commands, see the [user guide](USER-GUIDE.md). For suite setup, see [installation](../tooling/farmkit/INSTALL.md). The module preparation ZIP alone is not the full suite.

## Find your tool

| ID | Tool | Disposition | Procedure |
| --- | --- | --- | --- |
| [TOOL-001](#tool-001) | LinPEAS | hold | [Runbook](../tooling/farmkit/RUNBOOKS.md#host-enumeration) |
| [TOOL-002](#tool-002) | WinPEAS | hold | [Runbook](../tooling/farmkit/RUNBOOKS.md#host-enumeration) |
| [TOOL-003](#tool-003) | Wireshark / TShark | selected | [Runbook](../tooling/farmkit/RUNBOOKS.md#offline-pcap) |
| [TOOL-004](#tool-004) | Zeek | conditional | [Runbook](../tooling/farmkit/RUNBOOKS.md#offline-pcap) |
| [TOOL-005](#tool-005) | Suricata | conditional | [Runbook](../tooling/farmkit/RUNBOOKS.md#offline-pcap) |
| [TOOL-006](#tool-006) | Scapy | conditional | [Runbook](../tooling/farmkit/RUNBOOKS.md#offline-pcap) |
| [TOOL-007](#tool-007) | enum4linux-ng | conditional | [Runbook](../tooling/farmkit/RUNBOOKS.md#remote-host-and-directory-clients) |
| [TOOL-008](#tool-008) | NetExec | conditional | [Runbook](../tooling/farmkit/RUNBOOKS.md#remote-host-and-directory-clients) |
| [TOOL-009](#tool-009) | Impacket | hold | [Runbook](../tooling/farmkit/RUNBOOKS.md#remote-host-and-directory-clients) |
| [TOOL-010](#tool-010) | testssl.sh | conditional | [Runbook](../tooling/farmkit/RUNBOOKS.md#tls-and-web-clients) |
| [TOOL-011](#tool-011) | ffuf | conditional | [Runbook](../tooling/farmkit/RUNBOOKS.md#tls-and-web-clients) |
| [TOOL-012](#tool-012) | Metasploit Framework | hold | [Runbook](../tooling/farmkit/RUNBOOKS.md#remote-host-and-directory-clients) |
| [TOOL-013](#tool-013) | PyModbus | selected | [Runbook](../tooling/farmkit/RUNBOOKS.md#modbus) |
| [TOOL-014](#tool-014) | mbpoll | selected | [Runbook](../tooling/farmkit/RUNBOOKS.md#modbus) |
| [TOOL-015](#tool-015) | libmodbus | conditional | [Runbook](../tooling/farmkit/RUNBOOKS.md#modbus) |
| [TOOL-016](#tool-016) | MinimalModbus | conditional | [Runbook](../tooling/farmkit/RUNBOOKS.md#modbus) |
| [TOOL-017](#tool-017) | python-snap7 | selected | [Runbook](../tooling/farmkit/RUNBOOKS.md#s7) |
| [TOOL-018](#tool-018) | cpppo | selected | [Runbook](../tooling/farmkit/RUNBOOKS.md#cip) |
| [TOOL-019](#tool-019) | pycomm3 | hold | [Runbook](../tooling/farmkit/RUNBOOKS.md#cip) |
| [TOOL-020](#tool-020) | asyncua / opcua-asyncio | selected | [Runbook](../tooling/farmkit/RUNBOOKS.md#opc-ua) |
| [TOOL-021](#tool-021) | open62541 | lab | [Runbook](../tooling/farmkit/RUNBOOKS.md#opc-ua) |
| [TOOL-022](#tool-022) | BACpypes3 | hold | [Runbook](../tooling/farmkit/RUNBOOKS.md#bacnet) |
| [TOOL-023](#tool-023) | BACnet Stack | selected | [Runbook](../tooling/farmkit/RUNBOOKS.md#bacnet) |
| [TOOL-024](#tool-024) | Mosquitto clients and broker | selected | [Runbook](../tooling/farmkit/RUNBOOKS.md#mqtt) |
| [TOOL-025](#tool-025) | Eclipse Paho MQTT Python | conditional | [Runbook](../tooling/farmkit/RUNBOOKS.md#mqtt) |
| [TOOL-026](#tool-026) | lib60870 | conditional | [Runbook](../tooling/farmkit/RUNBOOKS.md#lab-and-conditional) |
| [TOOL-027](#tool-027) | libiec61850 | conditional | [Runbook](../tooling/farmkit/RUNBOOKS.md#lab-and-conditional) |
| [TOOL-028](#tool-028) | OpenDNP3 | hold | [Runbook](../tooling/farmkit/RUNBOOKS.md#lab-and-conditional) |
| [TOOL-029](#tool-029) | Gurux DLMS Python | conditional | [Runbook](../tooling/farmkit/RUNBOOKS.md#lab-and-conditional) |
| [TOOL-030](#tool-030) | can-utils | conditional | [Runbook](../tooling/farmkit/RUNBOOKS.md#lab-and-conditional) |
| [TOOL-031](#tool-031) | python-can | conditional | [Runbook](../tooling/farmkit/RUNBOOKS.md#lab-and-conditional) |
| [TOOL-032](#tool-032) | cantools | conditional | [Runbook](../tooling/farmkit/RUNBOOKS.md#lab-and-conditional) |
| [TOOL-033](#tool-033) | canopen | conditional | [Runbook](../tooling/farmkit/RUNBOOKS.md#lab-and-conditional) |
| [TOOL-034](#tool-034) | pymavlink | conditional | [Runbook](../tooling/farmkit/RUNBOOKS.md#lab-and-conditional) |
| [TOOL-035](#tool-035) | ChirpStack | lab | [Runbook](../tooling/farmkit/RUNBOOKS.md#lab-and-conditional) |
| [TOOL-036](#tool-036) | zigpy | lab | [Runbook](../tooling/farmkit/RUNBOOKS.md#lab-and-conditional) |
| [TOOL-037](#tool-037) | OpenPLC Runtime v4 | lab | [Runbook](../tooling/farmkit/RUNBOOKS.md#lab-and-conditional) |
| [TOOL-038](#tool-038) | FUXA | lab | [Runbook](../tooling/farmkit/RUNBOOKS.md#lab-and-conditional) |
| [TOOL-039](#tool-039) | Node-RED | lab | [Runbook](../tooling/farmkit/RUNBOOKS.md#lab-and-conditional) |
| [TOOL-040](#tool-040) | Conpot | lab | [Runbook](../tooling/farmkit/RUNBOOKS.md#lab-and-conditional) |

## Common operator workflow

1. Inspect the card using `python tooling/workbench/workbench.py card TOOL_ID`; it exposes prerequisites, current holds and next actions without launching the tool. Substitute the ID from the index.
2. Check the selected installation profile and recorded tool version. Follow the linked bounded runbook for input, exact authorized endpoint/operation, time/request limits and stop conditions. A runbook is a rehearsal procedure, not proof of testing.
3. Preserve original output privately with tool/version, time, exit status and limitations. A failed/partial run is not zero findings. Curate synthetic report evidence manually using the [update guide](REPORT-UPDATES.md). No native format adapter is implemented.

The suite may stage some held/reference tools without granting operational or redistribution clearance. Installation checks, licensing, rehearsal and event acceptance remain separate. Public catalog runtime_status records remain as supplied; inspect actual local inventory for current installation state.

## TOOL-001

Preparation from the repository root: `python3 tools.py plan linpeas`; then `python3 tools.py install linpeas`. Check with `python3 tools.py check linpeas`. See [onboarding prerequisites and output locations](../tooling/farmkit/ONBOARDING.md).

**LinPEAS**

Linux host configuration and privilege-path enumeration on authorized servers/gateways.

- **Interface / prerequisites:** Shell on target; review chosen script variant and external commands.
- **Expected output:** text, upstream parsers optional.
- **Catalog evaluation:** hold. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-001-linpeas).
- **Recorded selection/license note:** GPL v2-or-later with custom clarifications/exceptions, not a plain GPL-3 label. Review output-parsing/aggregation terms and third-party components.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#host-enumeration).
- **Reference:** [Upstream source](https://github.com/peass-ng/PEASS-ng).

## TOOL-002

Preparation from the repository root: `python3 tools.py plan winpeas`; then `python3 tools.py install winpeas`. Check with `python3 tools.py check winpeas`. See [onboarding prerequisites and output locations](../tooling/farmkit/ONBOARDING.md).

**WinPEAS**

Windows host/HMI/engineering-station configuration enumeration.

- **Interface / prerequisites:** Match selected C#/.NET/batch variant and architecture; assess AV/runtime effects.
- **Expected output:** text.
- **Catalog evaluation:** hold. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-002-winpeas).
- **Recorded selection/license note:** Same PEASS license issue; enumerate potential paths, do not automatically exploit them.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#host-enumeration).
- **Reference:** [Upstream source](https://github.com/peass-ng/PEASS-ng/tree/master/winPEAS).

## TOOL-003

Preparation from the repository root: `python3 tools.py plan tshark`; then `python3 tools.py install tshark`. Check with `python3 tools.py check tshark`. See [onboarding prerequisites and output locations](../tooling/farmkit/ONBOARDING.md).

**Wireshark / TShark**

Inspect supplied captures and identify observed IT/OT conversations.

- **Interface / prerequisites:** Linux CLI first; GUI optional; capture privileges only for live capture.
- **Expected output:** PCAP/PCAPNG, fields/JSON/CSV-style exports.
- **Catalog evaluation:** selected. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-003-wireshark--tshark).
- **Recorded selection/license note:** GPL-2.0 family; preserve component notices. Dissector coverage is release dependent. Packet capture needs authorized placement and may contain secrets.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#offline-pcap).
- **Reference:** [Upstream source](https://github.com/wireshark/wireshark).

## TOOL-004

Preparation from the repository root: `python3 tools.py plan zeek`; then `python3 tools.py install zeek`. Check with `python3 tools.py check zeek`. See [onboarding prerequisites and output locations](../tooling/farmkit/ONBOARDING.md).

**Zeek**

Turn captures into connection/protocol metadata and support asset hypotheses.

- **Interface / prerequisites:** Linux binary/build dependencies; optional protocol packages reviewed separately.
- **Expected output:** structured logs.
- **Catalog evaluation:** conditional. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-004-zeek).
- **Recorded selection/license note:** BSD-style; plugins have their own provenance. Do not assume complete vendor/OT coverage.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#offline-pcap).
- **Reference:** [Upstream source](https://github.com/zeek/zeek).

## TOOL-005

Preparation from the repository root: `python3 tools.py plan suricata`; then `python3 tools.py install suricata`. Check with `python3 tools.py check suricata`. See [onboarding prerequisites and output locations](../tooling/farmkit/ONBOARDING.md).

**Suricata**

Offline protocol/event analysis as an alternative or complement to Zeek.

- **Interface / prerequisites:** Linux/Rust/C build or distro package; selected config/rules must be acquired separately.
- **Expected output:** EVE JSON.
- **Catalog evaluation:** conditional. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-005-suricata).
- **Recorded selection/license note:** GPL-2.0 family; rules have separate licenses. Use offline/IDS profile; do not deploy inline IPS in the initial kit.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#offline-pcap).
- **Reference:** [Upstream source](https://github.com/OISF/suricata).

## TOOL-006

Preparation from the repository root: `python3 tools.py plan scapy`; then `python3 tools.py install scapy`. Check with `python3 tools.py check scapy`. See [onboarding prerequisites and output locations](../tooling/farmkit/ONBOARDING.md).

**Scapy**

Flexible packet parsing and synthetic protocol fixtures when a full product is unnecessary.

- **Interface / prerequisites:** Python; selected layers/contrib modules, capture backend if needed.
- **Expected output:** PCAP and custom structured data.
- **Catalog evaluation:** conditional. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-006-scapy).
- **Recorded selection/license note:** GPL-2.0 family. Restrict initial helpers to offline parsing; raw packet generation is a separate reviewed use.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#offline-pcap).
- **Reference:** [Upstream source](https://github.com/secdev/scapy).

## TOOL-007

Preparation from the repository root: `python3 tools.py plan enum4linux-ng`; then `python3 tools.py install enum4linux-ng`. Check with `python3 tools.py check enum4linux-ng`. See [onboarding prerequisites and output locations](../tooling/farmkit/ONBOARDING.md).

**enum4linux-ng**

Windows/Samba inventory if business systems or file shares are in scope.

- **Interface / prerequisites:** Linux/Python plus Samba utilities.
- **Expected output:** JSON/YAML/text.
- **Catalog evaluation:** conditional. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-007-enum4linux-ng).
- **Recorded selection/license note:** GPL-3.0. Authentication/enumeration creates traffic; distinguish access denial from absent assets.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#remote-host-and-directory-clients).
- **Reference:** [Upstream source](https://github.com/cddmp/enum4linux-ng).

## TOOL-008

Preparation from the repository root: `python3 tools.py plan netexec`; then `python3 tools.py install netexec`. Check with `python3 tools.py check netexec`. See [onboarding prerequisites and output locations](../tooling/farmkit/ONBOARDING.md).

**NetExec**

Scope-limited Windows/network service assessment and inventory.

- **Interface / prerequisites:** Linux/Python with isolated dependency environment.
- **Expected output:** CLI/module-specific output.
- **Catalog evaluation:** conditional. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-008-netexec).
- **Recorded selection/license note:** BSD-2-Clause; modules/dependencies reviewed individually. No spraying, remote execution or bulk modules in default profiles.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#remote-host-and-directory-clients).
- **Reference:** [Upstream source](https://github.com/Pennyw0rth/NetExec).

## TOOL-009

Preparation from the repository root: `python3 tools.py plan impacket`; then `python3 tools.py install impacket`. Check with `python3 tools.py check impacket`. See [onboarding prerequisites and output locations](../tooling/farmkit/ONBOARDING.md).

**Impacket**

SMB/MSRPC/Kerberos protocol helpers for the IT side of an engagement.

- **Interface / prerequisites:** Python and isolated dependencies.
- **Expected output:** tool-dependent text.
- **Catalog evaluation:** hold. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-009-impacket).
- **Recorded selection/license note:** Slightly modified Apache Software License, per upstream. Do not relabel Apache-2.0; select exact examples and review terms/dependencies.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#remote-host-and-directory-clients).
- **Reference:** [Upstream source](https://github.com/fortra/impacket).

## TOOL-010

Preparation from the repository root: `python3 tools.py plan testssl`; then `python3 tools.py install testssl`. Check with `python3 tools.py check testssl`. See [onboarding prerequisites and output locations](../tooling/farmkit/ONBOARDING.md).

**testssl.sh**

TLS configuration review of approved web consoles, remote access or APIs.

- **Interface / prerequisites:** Linux/Bash and compatible OpenSSL/dependencies.
- **Expected output:** text/JSON/CSV.
- **Catalog evaluation:** conditional. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-010-testsslsh).
- **Recorded selection/license note:** GPL-2.0. Many handshakes/probes; choose bounded checks and account for fragile embedded endpoints.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#tls-and-web-clients).
- **Reference:** [Upstream source](https://github.com/testssl/testssl.sh).

## TOOL-011

Preparation from the repository root: `python3 tools.py plan ffuf`; then `python3 tools.py install ffuf`. Check with `python3 tools.py check ffuf`. See [onboarding prerequisites and output locations](../tooling/farmkit/ONBOARDING.md).

**ffuf**

Limited web content discovery on an explicitly approved portal.

- **Interface / prerequisites:** Go binary; reviewed wordlist with separate license/provenance.
- **Expected output:** JSON/text and other exports.
- **Catalog evaluation:** conditional. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-011-ffuf).
- **Recorded selection/license note:** MIT. Request generation/fuzzing is not a default OT operation; require explicit endpoint and budget.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#tls-and-web-clients).
- **Reference:** [Upstream source](https://github.com/ffuf/ffuf).

## TOOL-012

Preparation from the repository root: `python3 tools.py plan metasploit`; then `python3 tools.py install metasploit`. Check with `python3 tools.py check metasploit`. This entry is held; install fails before acquisition.

**Metasploit Framework**

Known module research and controlled lab reproduction; possible scoped IT checks.

- **Interface / prerequisites:** Ruby/dependencies; substantial optional footprint.
- **Expected output:** module-specific evidence.
- **Catalog evaluation:** hold. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-012-metasploit-framework).
- **Recorded selection/license note:** BSD-style core with component terms. Module/source review required; no blanket ICS exploitation profile.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#remote-host-and-directory-clients).
- **Reference:** [Upstream source](https://github.com/rapid7/metasploit-framework).

## TOOL-013

Preparation from the repository root: `python3 tools.py plan pymodbus`; then `python3 tools.py install pymodbus`. Check with `python3 tools.py check pymodbus`. See [onboarding prerequisites and output locations](../tooling/farmkit/ONBOARDING.md).

**PyModbus**

Modbus TCP/serial clients and synthetic server/simulator; possible pump, meter or environmental controller interfaces.

- **Interface / prerequisites:** Python; serial/simulator extras optional; pin API and Python versions.
- **Expected output:** helper-generated structured results.
- **Catalog evaluation:** selected. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-013-pymodbus).
- **Recorded selection/license note:** BSD-3-Clause-style terms. Upstream warns of API changes and limited nonstandard-device support. No arbitrary register sweeps.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#modbus).
- **Reference:** [Upstream source](https://github.com/pymodbus-dev/pymodbus).

## TOOL-014

Preparation from the repository root: `python3 tools.py plan mbpoll`; then `python3 tools.py install mbpoll`. Check with `python3 tools.py check mbpoll`. See [onboarding prerequisites and output locations](../tooling/farmkit/ONBOARDING.md).

**mbpoll**

Convenient Modbus TCP/RTU command-line checks.

- **Interface / prerequisites:** Compiled CLI plus selected libmodbus/libmodbuspp version.
- **Expected output:** text.
- **Catalog evaluation:** selected. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-014-mbpoll).
- **Recorded selection/license note:** GPL-3.0. Document selected major branch, finite polling, unit/address/type and no-write invocation. Distinct from proprietary modpoll.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#modbus).
- **Reference:** [Upstream source](https://github.com/epsilonrt/mbpoll).

## TOOL-015

Preparation from the repository root: `python3 tools.py plan libmodbus`; then `python3 tools.py install libmodbus`. Check with `python3 tools.py check libmodbus`. See [onboarding prerequisites and output locations](../tooling/farmkit/ONBOARDING.md).

**libmodbus**

C backend/alternative for Modbus TCP and RTU helpers.

- **Interface / prerequisites:** C build/native library; serial adapter for physical RTU.
- **Expected output:** application-defined.
- **Catalog evaluation:** conditional. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-015-libmodbus).
- **Recorded selection/license note:** LGPL-2.1-or-later. Useful backend, not another mandatory CLI; avoid duplicate implementations without need.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#modbus).
- **Reference:** [Upstream source](https://github.com/stephane/libmodbus).

## TOOL-016

Preparation from the repository root: `python3 tools.py plan minimalmodbus`; then `python3 tools.py install minimalmodbus`. Check with `python3 tools.py check minimalmodbus`. See [onboarding prerequisites and output locations](../tooling/farmkit/ONBOARDING.md).

**MinimalModbus**

Modbus RTU/ASCII instrument access where serial-only needs justify it.

- **Interface / prerequisites:** Python + pySerial; approved RS-232/485 interface.
- **Expected output:** application-defined.
- **Catalog evaluation:** conditional. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-016-minimalmodbus).
- **Recorded selection/license note:** Apache-2.0. Not a Modbus TCP replacement. Wiring, serial settings and physical access are prerequisites.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#modbus).
- **Reference:** [Upstream source](https://github.com/pyhys/minimalmodbus).

## TOOL-017

Preparation from the repository root: `python3 tools.py plan python-snap7`; then `python3 tools.py install python-snap7`. Check with `python3 tools.py check python-snap7`. See [onboarding prerequisites and output locations](../tooling/farmkit/ONBOARDING.md).

**python-snap7**

Siemens S7 communication and controlled simulator/metadata work if relevant.

- **Interface / prerequisites:** Python; exact release determines native vs pure-Python dependencies.
- **Expected output:** helper-defined.
- **Catalog evaluation:** selected. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-017-python-snap7).
- **Recorded selection/license note:** MIT. Current README describes pure Python and model/access limits; older releases may differ. Do not enable PUT/GET or change controller settings to make a test work.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#s7).
- **Reference:** [Upstream source](https://github.com/gijzelaerr/python-snap7).

## TOOL-018

Preparation from the repository root: `python3 tools.py plan cpppo`; then `python3 tools.py install cpppo`. Check with `python3 tools.py check cpppo`. See [onboarding prerequisites and output locations](../tooling/farmkit/ONBOARDING.md).

**cpppo**

EtherNet/IP CIP client/server and synthetic fixtures.

- **Interface / prerequisites:** Python; selected API/example dependency review.
- **Expected output:** text/structured helper results.
- **Catalog evaluation:** selected. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-018-cpppo).
- **Recorded selection/license note:** GPL-3 with stated exceptions/alternative terms. Use GPL route consistently; choose bounded identity/read operations, not arbitrary CIP services.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#cip).
- **Reference:** [Upstream source](https://github.com/pjkundert/cpppo).

## TOOL-019

Preparation from the repository root: `python3 tools.py plan pycomm3`; then `python3 tools.py install pycomm3`. Check with `python3 tools.py check pycomm3`. This entry is held; install fails before acquisition.

**pycomm3**

Allen-Bradley/Rockwell-specific EtherNet/IP option.

- **Interface / prerequisites:** Python; test selected controller family and API.
- **Expected output:** application-defined.
- **Catalog evaluation:** hold. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-019-pycomm3).
- **Recorded selection/license note:** MIT. Upstream explicitly says no longer actively developed. Keep as documented fallback; do not default-stage without ownership and compatibility evidence.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#cip).
- **Reference:** [Upstream source](https://github.com/ottowayi/pycomm3).

## TOOL-020

Preparation from the repository root: `python3 tools.py plan asyncua`; then `python3 tools.py install asyncua`. Check with `python3 tools.py check asyncua`. See [onboarding prerequisites and output locations](../tooling/farmkit/ONBOARDING.md).

**asyncua / opcua-asyncio**

OPC UA client/server, namespace inspection and security-mode evaluation.

- **Interface / prerequisites:** Python plus cryptography dependencies/certificates.
- **Expected output:** CLI or helper output.
- **Catalog evaluation:** selected. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-020-asyncua--opcua-asyncio).
- **Recorded selection/license note:** LGPL-3.0. Pin API/runtime; credentials/trust policy and node reads must be approved. Do not use writes, method calls or trust bypass by default.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#opc-ua).
- **Reference:** [Upstream source](https://github.com/FreeOpcUa/opcua-asyncio).

## TOOL-021

Preparation from the repository root: `python3 tools.py plan open62541`; then `python3 tools.py install open62541`. Check with `python3 tools.py check open62541`. See [onboarding prerequisites and output locations](../tooling/farmkit/ONBOARDING.md).

**open62541**

C OPC UA client/server and controlled fixture alternative.

- **Interface / prerequisites:** C/CMake; crypto plugins/dependencies selected explicitly.
- **Expected output:** application-defined.
- **Catalog evaluation:** lab. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-021-open62541).
- **Recorded selection/license note:** MPL-2.0; some examples/plugins CC0. Preserve per-file notices. Prefer one sufficient lab/backend over two mandatory stacks.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#opc-ua).
- **Reference:** [Upstream source](https://github.com/open62541/open62541).

## TOOL-022

Preparation from the repository root: `python3 tools.py plan bacpypes3`; then `python3 tools.py install bacpypes3`. Check with `python3 tools.py check bacpypes3`. This entry is held; install fails before acquisition.

**BACpypes3**

Python BACnet option for possible HVAC/ventilation/cold-room controls.

- **Interface / prerequisites:** Python/asyncio; no MCP/AI extras needed.
- **Expected output:** CLI/helper output.
- **Catalog evaluation:** hold. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-022-bacpypes3).
- **Recorded selection/license note:** pyproject says MIT but classifier says BSD. Resolve exact artifact licensing before staging; disable unrelated MCP/AI integration.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#bacnet).
- **Reference:** [Upstream source](https://github.com/JoelBender/BACpypes3).

## TOOL-023

Preparation from the repository root: `python3 tools.py plan bacnet`; then `python3 tools.py install bacnet`. Check with `python3 tools.py check bacnet`. See [onboarding prerequisites and output locations](../tooling/farmkit/ONBOARDING.md).

**BACnet Stack**

BACnet/IP CLI applications plus synthetic device; MS/TP only if separately supported.

- **Interface / prerequisites:** C/compiled apps; select datalink and exact utilities.
- **Expected output:** CLI output.
- **Catalog evaluation:** selected. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-023-bacnet-stack).
- **Recorded selection/license note:** GPL-2.0-or-later WITH GCC-exception-2.0 core; examples include MIT/Apache-2.0. Per-file review required. Bound discovery; default to explicit unicast reads.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#bacnet).
- **Reference:** [Upstream source](https://github.com/bacnet-stack/bacnet-stack).

## TOOL-024

Preparation from the repository root: `python3 tools.py plan mosquitto-clients`; then `python3 tools.py install mosquitto-clients`. Check with `python3 tools.py check mosquitto-clients`. See [onboarding prerequisites and output locations](../tooling/farmkit/ONBOARDING.md).

**Mosquitto clients and broker**

MQTT subscriber/client checks and synthetic broker for possible farm telemetry.

- **Interface / prerequisites:** Linux CLI; broker optional; TLS credentials/config separate.
- **Expected output:** text/topic payloads.
- **Catalog evaluation:** selected. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-024-mosquitto-clients-and-broker).
- **Recorded selection/license note:** EPL-2.0 OR BSD-3-Clause. A subscription sends traffic and can expose retained secrets. No publish/retained changes against a target by default.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#mqtt).
- **Reference:** [Upstream source](https://github.com/eclipse-mosquitto/mosquitto).

## TOOL-025

Preparation from the repository root: `python3 tools.py plan paho-mqtt`; then `python3 tools.py install paho-mqtt`. Check with `python3 tools.py check paho-mqtt`. See [onboarding prerequisites and output locations](../tooling/farmkit/ONBOARDING.md).

**Eclipse Paho MQTT Python**

Scriptable MQTT alternative when a reviewed structured adapter is useful.

- **Interface / prerequisites:** Python; pin callback/API version.
- **Expected output:** application-defined.
- **Catalog evaluation:** conditional. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-025-eclipse-paho-mqtt-python).
- **Recorded selection/license note:** EPL-2.0 / EDL-1.0 dual license. Mosquitto CLI may suffice; do not require both without a concrete use.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#mqtt).
- **Reference:** [Upstream source](https://github.com/eclipse-paho/paho.mqtt.python).

## TOOL-026

Preparation from the repository root: `python3 tools.py plan lib60870`; then `python3 tools.py install lib60870`. Check with `python3 tools.py check lib60870`. See [onboarding prerequisites and output locations](../tooling/farmkit/ONBOARDING.md).

**lib60870**

IEC 60870-5-101/104 lab/client work if energy or remote telemetry is established.

- **Interface / prerequisites:** C; serial for 101, TCP for 104; optional TLS dependencies.
- **Expected output:** application-defined.
- **Catalog evaluation:** conditional. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-026-lib60870).
- **Recorded selection/license note:** GPL-3.0 open-source route; commercial alternative is not selected. Commands/control services require separate approval.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#lab-and-conditional).
- **Reference:** [Upstream source](https://github.com/mz-automation/lib60870).

## TOOL-027

Preparation from the repository root: `python3 tools.py plan libiec61850`; then `python3 tools.py install libiec61850`. Check with `python3 tools.py check libiec61850`. See [onboarding prerequisites and output locations](../tooling/farmkit/ONBOARDING.md).

**libiec61850**

IEC 61850 MMS/GOOSE analysis/lab possibility for site power systems.

- **Interface / prerequisites:** C; selected Ethernet/TLS/platform capabilities.
- **Expected output:** application-defined.
- **Catalog evaluation:** conditional. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-027-libiec61850).
- **Recorded selection/license note:** GPL-3.0 open-source route; review dependencies. No GOOSE injection or protection/control operations in initial profiles.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#lab-and-conditional).
- **Reference:** [Upstream source](https://github.com/mz-automation/libiec61850).

## TOOL-028

Preparation from the repository root: `python3 tools.py plan opendnp3`; then `python3 tools.py install opendnp3`. Check with `python3 tools.py check opendnp3`. This entry is held; install fails before acquisition.

**OpenDNP3**

DNP3 reference/lab fallback for outstation/master scenarios.

- **Interface / prerequisites:** C++ build, optional bindings and dependencies.
- **Expected output:** application-defined.
- **Catalog evaluation:** hold. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-028-opendnp3).
- **Recorded selection/license note:** Apache-2.0; repository archived in 2022. DNP3 coverage is a selection gap until a maintained alternative or owned lab-only fallback is evaluated.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#lab-and-conditional).
- **Reference:** [Upstream source](https://github.com/dnp3/opendnp3).

## TOOL-029

Preparation from the repository root: `python3 tools.py plan gurux-dlms`; then `python3 tools.py install gurux-dlms`. Check with `python3 tools.py check gurux-dlms`. See [onboarding prerequisites and output locations](../tooling/farmkit/ONBOARDING.md).

**Gurux DLMS Python**

DLMS/COSEM electricity/water/gas meter client possibilities.

- **Interface / prerequisites:** Python; chosen transport and credentials; meter model validation.
- **Expected output:** structured/helper output.
- **Catalog evaluation:** conditional. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-029-gurux-dlms-python).
- **Recorded selection/license note:** GPL-2.0 family upstream declaration. Meter compatibility/authentication and selected modules need testing; do not alter meter configuration.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#lab-and-conditional).
- **Reference:** [Upstream source](https://github.com/Gurux/Gurux.DLMS.Python).

## TOOL-030

Preparation from the repository root: `python3 tools.py plan can-utils`; then `python3 tools.py install can-utils`. Check with `python3 tools.py check can-utils`. See [onboarding prerequisites and output locations](../tooling/farmkit/ONBOARDING.md).

**can-utils**

CAN capture/log tools and J1939/ISOBUS utilities for possible vehicle/implement networks.

- **Interface / prerequisites:** Linux SocketCAN; vcan for lab, approved adapter for real bus.
- **Expected output:** CAN logs.
- **Catalog evaluation:** conditional. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-030-can-utils).
- **Recorded selection/license note:** Per-file terms; candump is GPL-2.0-only OR BSD-3-Clause. Initial profile uses logs/listen-only capture; address claiming/replay/transmit are active and excluded. Not a complete agricultural implement decoder.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#lab-and-conditional).
- **Reference:** [Upstream source](https://github.com/linux-can/can-utils).

## TOOL-031

Preparation from the repository root: `python3 tools.py plan python-can`; then `python3 tools.py install python-can`. Check with `python3 tools.py check python-can`. See [onboarding prerequisites and output locations](../tooling/farmkit/ONBOARDING.md).

**python-can**

Flexible CAN log/adapter abstraction and virtual-bus fixtures.

- **Interface / prerequisites:** Python; backend/driver licenses and hardware vary.
- **Expected output:** CAN log/helper output.
- **Catalog evaluation:** conditional. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-031-python-can).
- **Recorded selection/license note:** LGPL-3.0. Hardware-independent API does not remove adapter or privilege requirements.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#lab-and-conditional).
- **Reference:** [Upstream source](https://github.com/hardbyte/python-can).

## TOOL-032

Preparation from the repository root: `python3 tools.py plan cantools`; then `python3 tools.py install cantools`. Check with `python3 tools.py check cantools`. See [onboarding prerequisites and output locations](../tooling/farmkit/ONBOARDING.md).

**cantools**

Decode CAN logs using a supplied DBC or other supported database.

- **Interface / prerequisites:** Python; authorized/public/synthetic signal database required.
- **Expected output:** decoded signals/plots/text.
- **Catalog evaluation:** conditional. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-032-cantools).
- **Recorded selection/license note:** MIT. Without signal definitions, report raw frames/uncertainty; do not guess engineering meaning or upload proprietary DBC files.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#lab-and-conditional).
- **Reference:** [Upstream source](https://github.com/cantools/cantools).

## TOOL-033

Preparation from the repository root: `python3 tools.py plan canopen`; then `python3 tools.py install canopen`. Check with `python3 tools.py check canopen`. See [onboarding prerequisites and output locations](../tooling/farmkit/ONBOARDING.md).

**canopen**

CANopen object dictionary/EDS workflows if industrial actuators use it.

- **Interface / prerequisites:** Python + python-can; synthetic EDS and virtual bus initially.
- **Expected output:** application-defined.
- **Catalog evaluation:** conditional. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-033-canopen).
- **Recorded selection/license note:** MIT. Not interchangeable with J1939/ISOBUS. NMT commands/SDO writes are excluded from initial profiles.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#lab-and-conditional).
- **Reference:** [Upstream source](https://github.com/canopen-python/canopen).

## TOOL-034

Preparation from the repository root: `python3 tools.py plan pymavlink`; then `python3 tools.py install pymavlink`. Check with `python3 tools.py check pymavlink`. See [onboarding prerequisites and output locations](../tooling/farmkit/ONBOARDING.md).

**pymavlink**

Offline MAVLink log interpretation if aerial/robotic assets enter scope.

- **Interface / prerequisites:** Python; dialect and log format matter.
- **Expected output:** telemetry/log output.
- **Catalog evaluation:** conditional. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-034-pymavlink).
- **Recorded selection/license note:** LGPL-3-or-later; generated code MIT, per upstream. Start with offline logs; no arming, navigation, parameter updates or radio operation.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#lab-and-conditional).
- **Reference:** [Upstream source](https://github.com/ArduPilot/pymavlink).

## TOOL-035

Preparation from the repository root: `python3 tools.py plan chirpstack`; then `python3 tools.py install chirpstack`. Check with `python3 tools.py check chirpstack`. See [onboarding prerequisites and output locations](../tooling/farmkit/ONBOARDING.md).

**ChirpStack**

LoRaWAN server/API reference and synthetic telemetry training.

- **Interface / prerequisites:** Server stack/dependencies; gateway/keys only for authorized RF lab.
- **Expected output:** API/log data.
- **Catalog evaluation:** lab. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-035-chirpstack).
- **Recorded selection/license note:** MIT server; dependencies separate. Not a universal LoRa sniffer or key-recovery tool. Full stack may be too large for event staging.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#lab-and-conditional).
- **Reference:** [Upstream source](https://github.com/chirpstack/chirpstack).

## TOOL-036

Preparation from the repository root: `python3 tools.py plan zigpy`; then `python3 tools.py install zigpy`. Check with `python3 tools.py check zigpy`. See [onboarding prerequisites and output locations](../tooling/farmkit/ONBOARDING.md).

**zigpy**

Zigbee protocol/coordinator reference if sensors/climate devices are established.

- **Interface / prerequisites:** Python plus vendor radio library/coordinator for RF.
- **Expected output:** helper/log output.
- **Catalog evaluation:** lab. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-036-zigpy).
- **Recorded selection/license note:** GPL-3.0 family with COPYING details; radio libraries separate. Joining/control/OTA are active; not a passive packet sniffer. No automatic firmware downloads.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#lab-and-conditional).
- **Reference:** [Upstream source](https://github.com/zigpy/zigpy).

## TOOL-037

Preparation from the repository root: `python3 tools.py plan openplc`; then `python3 tools.py install openplc`. Check with `python3 tools.py check openplc`. See [onboarding prerequisites and output locations](../tooling/farmkit/ONBOARDING.md).

**OpenPLC Runtime v4**

Small synthetic controller process for agreed protocol fixtures.

- **Interface / prerequisites:** Linux; native or reviewed container route; editor/compiler and resource needs require design.
- **Expected output:** synthetic runtime/API logs.
- **Catalog evaluation:** lab. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-037-openplc-runtime-v4).
- **Recorded selection/license note:** MIT core upstream declaration; dependency review needed. Use v4 evaluation, not EOL v3. Do not run upstream pipe-to-shell installers or enable cloud integrations by default.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#lab-and-conditional).
- **Reference:** [Upstream source](https://github.com/Autonomy-Logic/openplc-runtime).

## TOOL-038

Preparation from the repository root: `python3 tools.py plan fuxa`; then `python3 tools.py install fuxa`. Check with `python3 tools.py check fuxa`. See [onboarding prerequisites and output locations](../tooling/farmkit/ONBOARDING.md).

**FUXA**

Synthetic SCADA/HMI dashboard for Modbus, OPC UA, MQTT and S7 rehearsal.

- **Interface / prerequisites:** Node.js/web stack, selected connectors; optional containers.
- **Expected output:** synthetic HMI/log evidence.
- **Catalog evaluation:** lab. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-038-fuxa).
- **Recorded selection/license note:** MIT. Lab-only boundary; avoid a heavyweight HMI if minimal protocol fixtures suffice.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#lab-and-conditional).
- **Reference:** [Upstream source](https://github.com/frangoteam/FUXA).

## TOOL-039

Preparation from the repository root: `python3 tools.py plan node-red`; then `python3 tools.py install node-red`. Check with `python3 tools.py check node-red`. See [onboarding prerequisites and output locations](../tooling/farmkit/ONBOARDING.md).

**Node-RED**

Synthetic telemetry and workflow fixtures.

- **Interface / prerequisites:** Node.js; pin any additional protocol node packages separately.
- **Expected output:** synthetic flows/logs.
- **Catalog evaluation:** lab. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-039-node-red).
- **Recorded selection/license note:** Apache-2.0 core; contributed nodes have independent licenses/security. No remote flow downloads, dashboard exposure or customer credentials.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#lab-and-conditional).
- **Reference:** [Upstream source](https://github.com/node-red/node-red).

## TOOL-040

Preparation from the repository root: `python3 tools.py plan conpot`; then `python3 tools.py install conpot`. Check with `python3 tools.py check conpot`. See [onboarding prerequisites and output locations](../tooling/farmkit/ONBOARDING.md).

**Conpot**

ICS honeypot/service emulation for identification/capture exercises.

- **Interface / prerequisites:** Python, selected templates and dependencies.
- **Expected output:** synthetic logs/captures.
- **Catalog evaluation:** lab. [Detailed catalog card](../tooling/farmkit/CATALOG.md#tool-040-conpot).
- **Recorded selection/license note:** GPL-2.0. Emulation does not certify actual PLC behavior. Disable external intelligence feeds/telemetry and isolate the lab.
- **Procedure:** [Input, bounded operation, outcome and cleanup](../tooling/farmkit/RUNBOOKS.md#lab-and-conditional).
- **Reference:** [Upstream source](https://github.com/mushorg/conpot).
