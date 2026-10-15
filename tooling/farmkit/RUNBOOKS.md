# Preparation and bounded rehearsal runbooks

These are procedures to evaluate selected versions in an isolated synthetic lab. They are **not executed profiles** or claims of tested controller behavior. No runtime/software package, target or customer protocol is confirmed. Resolve [readiness](readiness.json) before use. The checker is local-only; it cannot run any activity below.

## Common active-operation contract

Before each active rehearsal, a named operator records an explicit authorized endpoint and scope reference, selected tool/version and exact approved request. Use synthetic lab identities and registers. Do not substitute a subnet, wildcard address, broadcast destination or default credential. Verify release-specific invocation/behavior against source/help first. Acquire and verify artifacts/dependencies before starting.

For the initial lab measurement, use **one endpoint, one concurrent connection, no application retry, a 5-second connection timeout and a 15-second total application deadline**, unless a stricter row below applies. Count protocol/security handshakes separately; some library setup performs additional queries. Measure actual packets and elapsed time before accepting a profile. These are provisional lab ceilings, not universal safe operating rates. A version that cannot enforce the chosen budget stays unaccepted. Do not retry after a timeout without a new human decision.

Stop immediately for unexpected device/process behavior, latency, error bursts, unrelated traffic or uncertain scope. Terminate the client, disconnect the test path if safe and notify the engagement/lab lead through the authorized incident process. Retain minimal private evidence, request/response counts, timestamps and limits; do not reset, reconfigure or force outputs to recover. Cleanup is closing sessions/removing only agreed synthetic test artifacts, never deleting customer logs or evidence.

Every run records operator, tool/release/hash, profile/version, scope reference, endpoint reference, start/end timezone, attempted application requests, observed traffic, exit/result category, evidence ID/hash, limitations and cleanup status. Empty response, partial response, unsupported protocol, authentication error and timeout remain distinct. A read result is not vulnerability proof or evidence that a process is safe.

## Offline PCAP

TOOL-003 is the primary candidate; TOOL-004/005/006 are conditional alternatives. Obtain a synthetic PCAP/PCAPNG with a known inventory and expected protocol/message counts. Verify its hash and selected parser version. Run TShark offline file mode only, with name resolution disabled; inspect the exact invocation for no live interface/capture/network resolution path. Bound parser CPU/time and memory in the agreed host; malformed captures can affect parser availability even offline.

Extract only agreed endpoint/protocol/count metadata; do not export packet bodies, credentials or process values. Compare expected and actual identities/counts; inspect unsupported/encrypted traffic and truncation limits. Confirm no network egress in the blocked-egress lab. Record parser exit status and source hash. No supplied capture or actual TShark invocation was run in this delivery; that acceptance check stays not run.

## Host enumeration

TOOL-001/002 are on license hold. Before acquiring, distributing or parsing their output, resolve custom terms for the exact variants. Select a disposable synthetic Linux VM and a separate Windows x64 VM with known configuration. Record OS/build, shell or .NET variant, privilege level, tool asset/hash, available CPU/RAM/disk and endpoint-protection state. No AV exceptions, control bypass, privilege exploitation or chained execution are part of this procedure.

After owner approval, inspect the selected script/binary behavior and external-call options. Run once against the disposable host with a measured resource/deadline budget agreed by its owner; PEASS is host enumeration, not passive capture. Capture outbound activity in the lab so possible network effects are known. Keep full raw output private and produce a manual summary until parsing/license decisions exist. Record known misconfiguration detection and false positives; candidate paths require separate human validation. Quarantine, missing .NET, insufficient privileges, crash or timeout is failure/not-run, never proof of no escalation paths. Restore only the agreed disposable VM snapshot after evidence is preserved. Actual Linux/Windows tests are pending.

## Modbus

TOOL-013/014; TOOL-015/016 are alternatives. Approve TCP host/port or a specific physical RTU port with baud/parity/stop bits, unit ID, addressing convention, data type/word order and a single synthetic register range. Physical serial connection needs adapter/wiring/termination/owner permission; do not guess these on a live bus.

Initial lab request: **one FC04 Read Input Registers request for one known synthetic input register**, one unit ID. No sweeps, multiple-unit discovery, holding-register write, coil write or indefinite polling. Set finite polling/count explicitly for mbpoll and confirm the version's address convention. Observe connection/setup traffic and actual FC count. Expected observation is a correctly decoded known synthetic value in private lab evidence; public metadata records only run/protocol status. Wrong address/unit/word order is uncertainty, not a finding. Close the connection; no process state should need restoration. Test invocation and traffic are not yet verified.

## S7

TOOL-017, proposed pure-Python 3.2.1. Use a named synthetic S7 endpoint with explicit rack/slot and model/access assumptions; no mode change or enabling PUT/GET to make access work. Initial allowed application operation: **one reviewed Read SZL module-identification request (SZL 0x0011) if supported by the selected emulator/API**. Verify exact setup/API and response behavior first; if unsupported, record not-run rather than substituting data-block or logic transfers.

Use the common budgets, capture setup plus the SZL request, and check expected synthetic identity/unsupported behavior. Do not run the upstream real-PLC suite wholesale: it can contain writes/admin tests. No start/stop/reset, block upload/download, variable writes or administrative commands. Close the session and preserve minimal metadata. Runtime/API and emulator compatibility remain pending.

## CIP

TOOL-018 is selected for evaluation, with dependency review pending; TOOL-019 remains held for inactive development. Pin/review cpppo's crypto_licensing and greenery dependencies and prove offline behavior before installation. Approve one TCP EtherNet/IP endpoint and **one encapsulation ListIdentity request to the explicit unicast endpoint**, if supported by the selected version/profile. No UDP broadcast discovery default, arbitrary CIP services, tag writes, reset or controller-state operations.

Verify source behavior and count setup/session traffic separately from the one identity query; if the client cannot support the exact unicast request/budget, keep this route not-run and select a reviewed alternative through design. Observe identity/timeout/unsupported/authentication categories without guessing controller compatibility. Close the session. Actual implementation/traffic rehearsal remains pending.

## OPC UA

TOOL-020; TOOL-021 is an optional lab alternative. Approve an explicit synthetic endpoint URL, security mode/policy, expected certificate/trust relationship and credentials. Initial operation: **one GetEndpoints service request**, with no namespace crawl, value reads, subscriptions, writes or method calls. This query does not establish authorization to read process values.

Count discovery/security/session setup in addition to application requests and verify no automatic reconnect, alternate endpoint or security downgrade. Invalid certificates/authentication/trust failures remain failures; do not disable verification or grant trust automatically. Close sessions/security channels as applicable. Confirm metadata matches the synthetic server and private evidence omits secrets. Selected-version API/security behavior and capture remain not run.

## BACnet

TOOL-023; TOOL-022 remains license-held. Approve one unicast BACnet/IP address/port, device instance and explicit object/property binding. Initial operation: **one ReadProperty of the known Device object's vendorIdentifier property** on the synthetic device. Do not sweep instances, use broadcast Who-Is, write properties, register a foreign device, alter BBMD/network settings or invoke reinitialization.

The selected CLI may discover/bind automatically even with a read-style name. Review its address-cache/binding path and verify traffic before acceptance. If it cannot run the exact unicast request without discovery, keep it not-run until a reviewed binding/helper design exists. Observe the response or typed timeout/unsupported/error, count packets and close the client. MS/TP needs separate approved serial hardware. Runtime and traffic checks pending.

## MQTT

TOOL-024 clients; broker lab-only. TOOL-025 is conditional if a structured helper is justified. Approve broker/port, TLS certificate/policy, synthetic credentials and **one exact synthetic topic**, such as lab/sensor/status. No +/# wildcard subscriptions. Initial test is one CONNECT, one SUBSCRIBE, at most one received synthetic message and one UNSUBSCRIBE/DISCONNECT; **10 seconds total**, no reconnect and no application retry.

No publish, retained-message changes, will message, broker administration or topic enumeration. A broker may deliver many retained or in-flight messages despite the intended consumer limit; verify selected-client behavior/buffering in the isolated lab and minimize payload retention. A subscription sends traffic and changes session state. Keep credentials/topic payloads private; record only allowed status/count metadata publicly. Authentication failures, no message and timeout differ. Confirm session cleanup and capture. Actual test not run.

## Lab and conditional

Prefer small synthetic protocol fixtures over a mandatory full SCADA stack. TOOL-021/035–040 need isolated networking, no Internet feeds/cloud fallback/automatic updates, reviewed data/keys and measured resources. Do not expose server ports to engagement infrastructure. OpenPLC v3 is EOL; evaluate v4 independently. FUXA/Node-RED add connectors with their own dependencies/licenses. Conpot emulation is not proof of a real PLC's behavior.

CAN/J1939/partial ISOBUS and CANopen start with synthetic log/DBC/EDS files or a virtual CAN bus. No transmit, replay, address claim, NMT control or SDO write. Offline interpretation requires known signal definitions; preserve unknown meaning. LoRaWAN, Zigbee and MAVLink start with synthetic logs/reference lab data, with no joining, control, radio transmission, firmware download or flight commands. Physical/radio activities require separate scope/equipment approval. DNP3's maintained implementation selection is unresolved. IEC 60870, IEC 61850 and DLMS meter/client paths require actual scope and a separate bounded query profile before any operation.

## Acquisition and clean-image acceptance

1. Select a source/version and artifact type from the source reference record, with owner and license/dependency review. Confirm staging is through an approved public route. Acquire through normal reviewed preparation procedures; this module does not download anything.
2. Retain source/build relation, actual byte size/hash, signatures when available, notices and source obligations. Record all runtime/build dependencies, optional data/rule/configuration inputs and an immutable distro/build baseline. Verify the local inventory and confirm dependency closure manually.
3. Restore an agreed clean Kali image and separate Windows image; stage only approved artifacts. Block and observe Internet egress at the environment boundary, including name resolution/telemetry/update/fallback paths. Install with recorded privileges; measure time/disk/RAM. Cached developer packages are not clean-image evidence.
4. Run help/version and each applicable synthetic host/protocol/PCAP rehearsal above. Preserve exact invocations, outputs/hashes, traffic, timeout/stop/cleanup behavior and failure cases privately. Passing integrity checks cannot replace these runtime checks.
5. Have the independent reviewer inspect the current version and results. Record each rehearsal result in readiness with a reproducible evidence reference. Leave unavailable hardware paths not-run; do not promote a failed/partial run to success-empty.

## Freeze and student integration

Refresh the assigned repository state, exact file list, eligible student owner and approval for this contribution. Keep reporting/scanner behavior separate. Inspect every public file and ZIP member for private data; retain module and third-party notices. Obtain actual event start/timezone, current SOW/ROE and stricter deadlines before computing the rulebook's 14-day request/7-day freeze dates; clarify any event-hour commit exception. Record the frozen package/version/hash and membership review. User acceptance, official approval and publication are distinct states.
