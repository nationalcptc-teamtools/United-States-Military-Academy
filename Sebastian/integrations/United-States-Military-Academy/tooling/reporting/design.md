# Reporting format and direct tool output design

Design version: 2026-10-15. Current format target: generator 0.3.0, report schemas 1.0, 1.1 and 1.2. **Native tool adapters and the tool-run contract below are planned interfaces, not implemented import commands.**

## Report structure

The user requested a loose adaptation of an OSCP report example. Reuse general document structure only: original cover, contents, introduction/objective/scope, high-level summary/recommendations, methodology, detailed findings, and evidence/review appendices. Do not distribute the source document, exam wording, screenshots, sample assessment claims, identifiers, credentials, proof values, or embedded commands.

Markdown and PDF consume one ordered report view. Findings retain supplied business severity, candidate/confirmed status, affected assets, observation, validation, evidence/provenance, optional CVE/CVSS claims, impact, remediation and retest. No attack, persistence, cleanup or validation is inferred from a heading.

PDF uses Letter pages, one-inch margins, a restrained blue title, numbered sections, actual page numbers in its contents and draft/data markings. Local fonts only; source text remains literal. Evidence is referenced rather than opened or embedded.

Schema 1.0 is retained. Schema 1.1 adds three optional engagement fields:

| Field | Type / bounds | Meaning |
| --- | --- | --- |
| objective | Nonempty text, at most 10,000 characters | Supplied assessment purpose. Omission is explicitly described as not supplied. |
| recommendations | 1–20 nonempty strings, at most 2,000 characters each | Analyst-authored high-level recommendations; no automated summary or commitment. |
| methodology_sections | Nonempty object; only information_gathering, service_enumeration, validation, cleanup; each nonempty text up to 10,000 characters | Supplied activity/results. Only supplied sections render; headings do not establish performed activity. |

Old 1.0 documents reject these new keys instead of silently changing their contract. Both versions retain synthetic-only input and the same review gate. The input hash covers exact bytes; edited Markdown and PDF must be regenerated from the same source to remain synchronized.

## Intended ingestion flow

### Handling restrictions and severity method

Schema 1.2 requires report markings[] and allows additional finding/evidence markings[]. The closed labels are ORCON, PROPIN, PII, PII Red and FI; empty/duplicate/unknown/non-string tags fail. The report baseline must include ORCON. A child inherits ancestor tags and may add restrictions; evidence tags roll into the derived finding and all findings roll into the report. This applies to summaries and other synthesized analysis as well as detailed evidence.

ORCON denotes originator/client control. PROPIN covers internal systems, methods and procedures; PII covers employee/customer information; PII Red covers identity-theft-sensitive personal information; FI covers finances. These are overlapping categories, not a supplied total hierarchy. Retain their union, with PII Red replacing ordinary PII in the displayed label. For example, PROPIN plus FI yields ORCON//PROPIN//FI; adding PII Red yields ORCON//PROPIN//PII Red//FI. No automatic downgrade or declassification path exists.

Computed labels appear on every PDF page, Markdown, finding/evidence sections and manifest. Original input is not mutated. The old classification text is a supplied document label and cannot lower computed restrictions; recognized exact tags in it add restrictions in every schema, including migration to 1.2. Legacy 1.0/1.1 inputs are visibly flagged as unverified for structured inheritance. Current source labels are analyst assertions; the code does not detect sensitive prose, authorize storage/disclosure, or enable client inputs. Every example remains synthetic.

Business severity remains supplied by an analyst, with a visible “matrix not configured” method statement. No likelihood/impact matrix has been supplied for this implementation, and no scoring/mapping is invented. CVSS remains separate metadata. A later matrix needs exact axes, cells, boundary rules, provenance and fixtures before implementation.

Future producer/native adapters must preserve source markings and attach them to observations and derived analysis, inheriting ORCON and retaining combined restrictions through run-aware reports. Classification omission cannot be used as declassification. Define these fields in a versioned adapter contract before deployment; the planned envelope below still has no implemented importer.

Approved external tool or team helper → explicitly selected local export/stdin → passive adapter → validated run and metadata observations → human finding curation → report view → Markdown/PDF/manifest.

The reporter never launches tools, connects to targets, loads plugins based on source text, downloads parsers, follows URLs, or invokes AI. A scope reference records context; it does not grant permission. Native-export support must be implemented and tested against selected versions before advertised as available.

Three routes are deliberate:

1. Native metadata adapters for stable structured exports. Parse only a named format/version/profile, then emit the common envelope.
2. Producer envelopes for team-owned helpers/library clients. The producer writes the same contract directly, so the reporter needs no upstream runtime.
3. Reference-only or held input where output is binary, unrestricted text, sensitive process data, unselected, or under a license/maintenance hold. Hash/reference metadata is not parsed content or tested support.

No adapter invents business impact, severity, mitigation, retest, CVE applicability or confirmed findings. Imported tool assertions remain observations; people complete the finding contract. A future report schema must add visible run/observation registers before direct imports can be rendered. Do not pass these envelopes as current report input or silently reuse schema 1.1.

## Common producer envelope cptc.tool-run/1.0

[Synthetic example](examples/tool-run.json). This is a design fixture, not a reportgen input or an actual tool execution.

| Field | Required contract |
| --- | --- |
| contract_version | Exact cptc.tool-run/1.0. Unknown versions fail. |
| data_category | synthetic for preparation; client data remains disabled until a separate approved handling extension. |
| run.id | Stable ASCII ID, 1–64 characters; same rules as report IDs. |
| run.tool_id, tool_name, tool_version | Catalog TOOL ID or separately registered legacy tool, supplied name/version; no version inferred from filename or host installation. |
| run.profile_id, collector, scope_ref | Registered metadata-only profile, collector and approved scope-record reference; no passwords, tokens or unrestricted command lines. |
| run.started_at, finished_at | Supplied timezone-aware timestamps, or null for not_run. Finish must not precede start. No filesystem-time substitution. |
| run.status | success, partial, failed or not_run. Success requires exit_code 0 and complete input. Partial remains partial even with exit 0. |
| run.exit_code | Supplied integer; null when unavailable/not_run. A timeout is recorded as a failed/partial run, never successful absence. |
| run.input_sha256 | Supplied lowercase SHA-256 of a distinct source artifact consumed by the producer, or null when there is none/not_run, with a limitation explaining the omission. Never a hash of this envelope itself. The importer separately computes the exact received envelope/export hash. |
| run.limitations | Bounded list of sanitized limitations; mandatory explanation for partial/failed/not_run. Missing fields or excluded native records are visible, without raw source-value diagnostics. |
| observations | Bounded list; empty is valid for a successful empty result only with explicit coverage limits. Failed/not_run cannot fabricate successful empty coverage. |
| observation.id, asset_ref, observed_at | Stable observation ID, approved asset reference and source timestamp/timezone. Reject collisions and out-of-scope assets against supplied approved scope data; do not probe to resolve them. |
| observation.kind, metadata | Registered kind/profile-specific closed allowlist. Examples: network.service, tls.configuration, host.configuration, ot.endpoint, telemetry.metadata. Reject unknown keys/types; no arbitrary raw payload/text escape hatch. |

Initial planned limits: 2 MB per export, 100 runs per report, 2,000 observations per run, 64-character IDs and 240-character references, bounded metadata strings/lists. Revisit with selected synthetic fixtures and measured resources; these are workload limits, not a performance guarantee.

## Planned adapter interface and report handoff

An explicit adapter registry maps a selected adapter ID to its supported source-tool versions, input format, metadata profile and implementation version. A future import entry point takes bytes from one explicitly named file or stdin plus that adapter ID and approved scope data. It never selects an adapter from source instructions, file extensions or an installed executable. A producer-envelope adapter validates the envelope directly; native adapters translate only registered fields into it.

Each adapter returns a validated envelope and an import record containing the independently computed received-file SHA-256, adapter/version/profile, accepted/excluded/error counts and sanitized diagnostics. The export hash belongs in this separate record, avoiding a self-referential hash inside the bytes being hashed. A supplied source-artifact hash retains its supplied/unverified label; equality of hashes is not proof of an observation.

The next report schema will carry runs, observations and import records as separate registers. A human-curated finding references observation IDs; an observation references its run and import record. Render all run dispositions and coverage limitations, including failed/not-run/partial entries, in the report appendix. Findings keep the existing required evidence, impact, severity, remediation and review fields; adapters cannot fill those fields by inference. ID references must resolve, and excluded observations must not silently remove a run's coverage limitations. This schema and entry point require a later implementation proposal; neither exists in version 0.2.0.

Profiles must define exact allowed fields and values. For example, an OT endpoint profile may allow protocol, transport, device model/vendor and bounded capability names; it must not accept register contents, controller logic, process values, keys or arbitrary topic payloads. Strings still require literal rendering; a field allowlist alone cannot establish that its values are non-sensitive.

## Error, provenance and review behavior

- Validate the entire explicit input before publication. Reject unsupported format/version/profile, malformed/duplicate JSON keys, unexpected fields, oversized/deep records and missing run provenance.
- Native XML design must disable DTDs/entities/external resolution and apply depth/record/size limits. Do not execute processing instructions or include external files. A vetted parser/library choice requires its own dependency review.
- Native JSON/JSONL parsers preserve per-record failures and counts. No failed parser result becomes zero findings or complete coverage.
- Record computed source/export hash, adapter/version/profile, source-tool version, times and counts. Do not copy or retain unfiltered raw output, write absolute host paths, or expose source values in errors.
- Raw PCAP, terminal logs, database exports, controller data, screenshots and producer configs remain outside automatic ingestion. Any permitted private reference requires existing handling/retention approval; this design adds none.
- An identical run ID/hash may be recognized as a repeated import with an explicit disposition. Conflicting ID/hash is an error. Do not merge observations/findings automatically or count a repeated run twice.
- Batch partial output requires explicit user selection and a visible ledger. Report release is blocked by failed/partial/not_run coverage unless a future, explicitly designed human disposition records the exception; the current training release gate is unchanged.
- Producer output is untrusted data. Native severity/CVE labels are supplied assertions, not business risk or applicability proof. Neither a parser nor an envelope approves findings or event submission.

## Catalog output routes

These are proposed routes for all forty catalog entries, not a declaration that they are installed, selected, licensed for this use, or supported by current code.

| Catalog ID | Tool | Planned route / boundary |
| --- | --- | --- |
| TOOL-001 | LinPEAS | HOLD license/output-parsing review; unrestricted text reference only. |
| TOOL-002 | WinPEAS | HOLD same terms; variant-specific raw text is not imported. |
| TOOL-003 | Wireshark/TShark | Native selected-field JSON/TSV metadata adapter; PCAP/PCAPNG reference only, no packet-body import. |
| TOOL-004 | Zeek | Native JSON log adapter for explicitly allowed connection/protocol metadata; raw logs/configs excluded. |
| TOOL-005 | Suricata | Native EVE JSON/JSONL adapter for selected event metadata; payload, file and unrestricted alert content excluded. |
| TOOL-006 | Scapy | Team helper emits envelope for offline approved metadata; no raw packet/PCAP parser in reporter. |
| TOOL-007 | enum4linux-ng | Native JSON adapter after exact-version fixtures; allowlisted service/security configuration only, no account/share contents. |
| TOOL-008 | NetExec | Selected helper/profile emits envelope; no generic terminal/module-output scraping. |
| TOOL-009 | Impacket | HOLD modified-license/example selection; no blanket raw-output parser. |
| TOOL-010 | testssl.sh | Native JSON metadata adapter after selected-version fixture; retain supplied checks as observations. |
| TOOL-011 | ffuf | Native JSON metadata adapter after selection; no bodies, credentials, query secrets or unrestricted discovered URLs. |
| TOOL-012 | Metasploit | HOLD module review; selected metadata envelope only, no exploit/session/proof import. |
| TOOL-013 | PyModbus | Helper emits envelope with approved endpoint/protocol metadata, no register/process values. |
| TOOL-014 | mbpoll | Helper emits bounded run/availability metadata; raw polling values reference-only pending an approved profile. |
| TOOL-015 | libmodbus | Application/helper envelope; library has no universal native report format. |
| TOOL-016 | MinimalModbus | Helper envelope; transport/unit/run metadata only, no instrument readings. |
| TOOL-017 | python-snap7 | Helper envelope for approved identity/capability metadata; no data-block/logic dump. |
| TOOL-018 | cpppo | Helper envelope for approved CIP identity/security metadata, no arbitrary service/tag values. |
| TOOL-019 | pycomm3 | HOLD maintenance/compatibility; future reviewed helper envelope only. |
| TOOL-020 | asyncua | Helper envelope for endpoint/security-mode metadata; no application values or trust bypass. |
| TOOL-021 | open62541 | Optional lab/helper envelope; no mandatory second OPC UA runtime. |
| TOOL-022 | BACpypes3 | HOLD license ambiguity; no parsing integration until resolved. |
| TOOL-023 | BACnet Stack | Selected CLI/helper envelope for approved device/service metadata, not unrestricted discovery/value output. |
| TOOL-024 | Mosquitto | Helper envelope for connection/TLS/approved broker metadata; topic payloads and secrets excluded. |
| TOOL-025 | Paho MQTT | Helper envelope using same MQTT metadata profile; no publish or payload ingestion. |
| TOOL-026 | lib60870 | Conditional helper envelope for approved endpoint/capability metadata; no commands/process data. |
| TOOL-027 | libiec61850 | Conditional helper envelope; no raw GOOSE/control/protection data. |
| TOOL-028 | OpenDNP3 | HOLD archived dependency; lab-only envelope after owned selection, no default adapter. |
| TOOL-029 | Gurux DLMS | Conditional helper envelope for approved meter/transport metadata; no readings/keys. |
| TOOL-030 | can-utils | CAN logs reference-only; a separate approved helper may emit frame/type counts and limits. |
| TOOL-031 | python-can | Helper envelope for approved bus/log metadata; no raw frame payload ingestion. |
| TOOL-032 | cantools | Helper envelope for authorized synthetic/approved decode metadata; no proprietary DBC or process-value import. |
| TOOL-033 | canopen | Conditional helper envelope for approved declared dictionary/capability metadata, no SDO values/writes. |
| TOOL-034 | pymavlink | Offline helper envelope for type/count/format metadata; no location, command or payload default. |
| TOOL-035 | ChirpStack | LAB envelope for approved test-run metadata; no server configs, keys or raw telemetry. |
| TOOL-036 | zigpy | LAB helper envelope; no joining/control/OTA or secret-bearing device logs. |
| TOOL-037 | OpenPLC Runtime v4 | LAB producer envelope for synthetic fixture/rehearsal status, no controller source/config dump. |
| TOOL-038 | FUXA | LAB producer envelope for synthetic run/endpoint metadata, no HMI/process/config export. |
| TOOL-039 | Node-RED | LAB producer envelope; do not import flows/configs/credentials. |
| TOOL-040 | Conpot | LAB producer envelope for selected synthetic event metadata, not raw service logs. |

Existing repository Nmap XML is an additional planned native adapter: allowlisted host/port/state/service fields only. Exclude script/output payloads and credentials. Existing scanner execution, configuration and cached hosts are outside the reporter.

Primary format references: [Nmap XML](https://nmap.org/book/output-formats-xml-output.html), [TShark output options](https://www.wireshark.org/docs/man-pages/tshark.html), [Zeek log formats](https://docs.zeek.org/en/current/tutorial/logs.html), [Suricata EVE](https://docs.suricata.io/en/latest/output/eve/eve-json-output.html). These document format families, not version pins or tested adapters.

## Transition and verification gates

Keep current report JSON rendering as the deterministic fallback. Next adapter implementation should select a small subset, acquire 2–3 synthetic actual-version outputs per format, define closed metadata schemas and source-to-observation mappings, then add success/empty/partial/failed/not-run/duplicate/hostile-input fixtures.

Use a separate report-schema revision when runs/observations become renderable; preserve 1.0/1.1 compatibility or provide an explicit migration. New imports must remain passive/offline and publish atomically. Real-data handling, licensing, exact tools/versions, approved fields, runtime and event permission are unresolved gates. No current command claims direct native-output support.
