# CPTC tool selection and preparation package

Version 1.1.0, 2026-10-15. A forty-entry open-source tooling catalog for a possible agriculture-themed IT/OT assessment. **Selected means selected for evaluation. Upstream software is not vendored here; the separate installer acquires supported assessment components. Installation and operational acceptance are distinct.** All technology scenarios are hypotheses.

Start with [the catalog](CATALOG.md), [bounded runbooks](RUNBOOKS.md), [source references](sources.json), [readiness record](readiness.json) and [notices](NOTICES.md). The machine-readable catalog includes priorities, dispositions, purpose, protocol coverage, runtime/dependencies/privileges/hardware, operational effects, outputs, license evidence, maintenance limits, ownership and test state. LinPEAS and WinPEAS are retained prominently with their license-review hold.

## Install from the repository

See [INSTALL.md](INSTALL.md) for the complete suite, platform requirements, optional lab systems and recovery. From the repository root on Kali:

```sh
bash install.sh --plan
bash install.sh --profile full
source .cptc-suite/activate
bash install.sh --check --profile full
```

The installer uses the network during preparation, records resolved versions and never launches an assessment tool, payload or lab server. [Verification evidence](VERIFICATION.md), [proposal](proposal.md), [specification](spec.md) and [design](design.md) distinguish actual installation checks from pending runtime/event acceptance.

## Selection

The initial core is TShark/Wireshark, PyModbus, mbpoll, python-snap7, cpppo, asyncua, BACnet Stack and Mosquitto clients. This covers packet analysis, Modbus TCP/RTU, S7, CIP, OPC UA, BACnet/IP and MQTT as evaluation possibilities. Every selected tool still needs artifact-specific license, dependency and runtime review. Mosquitto broker and other servers are lab options, not operational defaults. No blanket vendor/model coverage is promised.

Conditional entries address Linux/Windows IT, TLS/web interfaces, CAN/J1939/partial ISOBUS, CANopen, MAVLink, DLMS/COSEM and energy protocols. LoRaWAN/Zigbee systems are optional lab references. Archived OpenDNP3 leaves maintained DNP3 selection open; protocol support is not inferred from a port number or customer name. See the catalog for every disposition and alternative.

## Local commands

The helper requires Python 3.10+ and only the standard library. Run from the repository root:

~~~text
python -B tooling/farmkit/kit.py validate
python -B tooling/farmkit/kit.py list --disposition selected
python -B tooling/farmkit/kit.py list --protocol modbus-tcp
python -B tooling/farmkit/kit.py readiness
python -B -m unittest discover -s tooling/farmkit/tests -v
~~~

`validate` checks catalog/source/lock/readiness structure, IDs and references. It does not check actual upstream software or every truth claim in a human-written record. `list` filters offline metadata. `readiness` returns **3 (pending)** for unresolved gates/rehearsals, missing selected-tool acquisition, dependency review or runtime evidence; a structurally valid empty artifact inventory is never ready. Recorded human assertions are not independently authenticated by this helper.

Exit codes: **0** completed requested local check/list; **1** local file/I/O failure; **2** invalid record/contract; **3** pending artifacts/readiness. A failure prints a bounded category without echoing arbitrary source values. Nothing downloads, executes tools, scans targets, imports report findings or mutates input records. HTTPS locators are reference data only.

An explicit **synthetic** integrity demonstration:

~~~text
python -B tooling/farmkit/kit.py verify --lock tooling/farmkit/examples/synthetic-lock.json --root tooling/farmkit/examples/artifacts
~~~

This hashes one team-authored fixture. Its zero source commit and example.invalid locator are synthetic sentinels, not upstream provenance. It establishes only that local-byte verification works. To verify real acquired files later, supply their reviewed lock and explicit root. The default [upstream inventory](artifact-lock.json) is empty, so default verification returns pending. No record is automatically promoted after verification.

## Acquisition and integrity contracts

[sources.json](sources.json) binds candidate releases to full source commits and license evidence. Archive locators are derived candidates; no archive bytes/signatures were downloaded or hashed. Generated upstream archives may change representation. Select exact approved assets, compute the actual staged-byte SHA-256 and retain those bytes/provenance. Do not copy a null digest into a staged lock or follow an unpinned replacement URL.

The `cptc.artifact-lock/1.0` fields are demonstrated by [the synthetic lock](examples/synthetic-lock.json): identity/tool IDs, version/commit/origin, relative path/size/hash, platform/architecture, license/review, dependency IDs/closure-review state and smoke-check reference. All fields are required; unknown fields, duplicate keys/IDs/paths, moving commit references, missing or cyclic dependencies, invalid digests and unsafe paths are rejected. Upstream records may associate only selected tools with a recorded catalog license review. Synthetic artifacts cannot associate upstream tool IDs.

Dependencies must themselves be represented as reviewed source/runtime artifacts or documented in a separately reviewed immutable distribution/build record. The checker verifies only declared local artifacts and graph consistency; it cannot prove that all real dependencies or license obligations have been declared. Build toolchains, distro metadata, native libraries, optional extras, rule files, signal databases, signatures and notices are part of the later closure review. A successful hash is not proof of publisher authenticity, reproducible build, license compliance, clean runtime or process safety.

Artifact roots and every ancestor/component must be ordinary directories/files without symlinks or Windows reparse redirection. Paths must be portable relative forward-slash paths without traversal, drives, reserved device names or ambiguous suffixes. Input JSON is bounded at 2 MB, inventories at 256 entries and each artifact at 512 MiB; larger packages require a separately reviewed limit change. Streaming verification limits memory. Use a trusted, quiescent local directory; this is not a sandbox against another process concurrently replacing filesystem components.

## Evidence and reporting

[Synthetic status examples](examples/run-statuses.json) distinguish success-empty, partial, timeout, authentication failure, unsupported protocol and not-run. They are invented metadata, not tool outputs or confirmed findings. The reporting base accepts completed report schemas 1.0/1.1; the separate `cptc.tool-run/1.0` intake design remains planned. These example records are not inputs to the report command and no adapter is implemented here.

Actual engagement output belongs in authorized private event storage outside public code and consumer sync. Record source artifact hashes separately from later normalized/import envelope hashes. Do not commit credentials, controller values/logic, payloads, real captures, inventories, client-derived summaries or proprietary signal databases. Ignore rules supplement an exact upload inspection; they do not remove already tracked content.

## Rehearsal, update and integration

Follow [RUNBOOKS.md](RUNBOOKS.md). The online Kali assessment installation and disconnected installation check are recorded in VERIFICATION.md. Fresh offline reinstallation, Windows execution, hardware, host enumeration, selected protocol queries, traffic captures, measured stop behavior and full resource footprint remain **not run**. The historical readiness ledger is not automatically promoted by installation on a separate test workstation; no selected operation is marked runtime passed. The eight OD decisions and eleven rehearsal checks are preserved in the readiness ledger; all except the provisional subset decision remain pending or partial.

For updates, choose one exact reviewed version, inspect behavior/license/dependency differences, update immutable references, acquire through the approved public route, verify bytes/notices and repeat affected checks. Keep previous known records; do not silently follow `latest`. The existing general-purpose Nmap wrapper is separate and supplies no OT defaults.

For repository integration, refresh target revision/conventions and inspect this directory's exact file list. Name an eligible student maintainer, confirm publication authorization for this package, and resolve the current event's public-staging/freeze decisions. The October 2025 rulebook sets a repository-request lead time of at least 14 days and a no-change week before the event, subject to stricter official guidance; clarify the example competition-hour exception. Actual event start/timezone is needed to calculate dates. The repository's NLT 16OCT text alone supplies insufficient timing context.

The local release ZIP contains only this module's code, documents, JSON, tests, notices and synthetic fixture plus a hash manifest. It excludes private planning, reference originals, reporting outputs, upstream payloads and credentials. Publication and competition acceptance remain separate decisions.

To rebuild the fixed preparation-only ZIP, create an output parent outside this source directory and run `python -B tooling/farmkit/build.py output/farmkit-1.1.0.zip`. It includes exactly the files allowlisted in build.py plus MANIFEST.json with per-file sizes/hashes, fixed archive timestamps and no current-user path metadata. Existing outputs are refused. Repeat bytes are deterministic in the same Python/zlib runtime; ZIP compression bytes across other runtimes are not guaranteed identical.
