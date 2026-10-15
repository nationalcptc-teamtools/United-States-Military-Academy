# Solution design

## Classification extension — 2026-10-15

Target v0.3.0; FR-10/FR-11/NFR-07. Report schema 1.2 adds required report markings[] and optional finding/evidence markings[]. Closed labels are ORCON, PROPIN, PII, PII Red and FI. Validate before rendering, preserve source input, and compute an immutable view: report baseline → finding → evidence; evidence restrictions roll into the derived finding; all restrictions roll into the report. Descendants add restrictions and cannot remove inherited labels. PII Red replaces PII in the displayed canonical union, retaining its meaning; no ranking is invented for the other categories.

The legacy classification text stays as a supplied document label, not an authoritative handling override. Old schemas remain usable with an explicit legacy/unverified-inheritance warning; known exact legacy tags retain restrictions and all exports carry ORCON. Version 1.2 requires ORCON in its structured baseline; omitted child tags inherit. Every PDF page carries the computed report marking, even when only one source has PII Red/FI. Markdown, detailed findings/evidence and manifest expose the same view. Labels are supplied assertions, not a content detector, access control, encryption or release permission. Synthetic-only input remains unchanged.

Severity method is explicitly supplied business severity, matrix not configured. The workbook contains no severity matrix; retain existing labels/claims and defer matrix calculation/mapping until actual source axes/cells/rules are available. No CVSS-to-business-risk conversion. Verify malformed tags, mixed-source rollups, ancestor retention, PII Red handling, legacy warnings, every-page markings, manifest identity and unchanged release/offline/atomicity behavior.

Reviewed: 2026-10-14. Current change: v0.2.0 format and future farm-tool intake. One shared-workspace editor; prior v0.1.x choices/review remain historical evidence.

## Components and requirement mapping

| Component | Requirements |
| --- | --- |
| Profile/workflow/policy/roadmap/proposal products | FR-01, FR-07, NFR-02, NFR-04 |
| `tooling/reporting/reportgen.py` input validator + Markdown/PDF renderer | FR-02–FR-05, NFR-01, NFR-03, NFR-05 |
| `tooling/reporting/examples/report.json`, templates, README | FR-02, FR-06, NFR-02 |
| Synthetic regression tests + hashes/PDF visual review | FR-03–FR-05, NFR-01, NFR-03–NFR-05 |
| Shared numbered report view + compatible optional authoring fields | FR-08, NFR-06 |
| [Public intake/format design](../../../../tooling/reporting/design.md) and [synthetic envelope](../../../../tooling/reporting/examples/tool-run.json) | FR-09; farm-toolkit FR-FT-009 interface |

Flow: authorized script → future adapter → normalized JSON → validation → local draft/release gate → literal Markdown/PDF → hash manifest → human artifact review → approved event submission process.

The generator never runs the script, reads the referenced evidence file, retrieves reference URLs, calls an API, or invokes a model. Evidence artifacts are metadata links with relative paths, not attachment inclusion. This avoids reading arbitrary local files. Screenshot embedding and duplicate grouping are future work.

## Contract and review states

Retain schema 1.0 and add schema 1.1 with bounded optional engagement objective, recommendations and methodology_sections. Unknown fields still fail. Only 1.1 accepts new keys; legacy input retains its facts and review semantics under the new layout. File/stdin still accepts completed report JSON, not native tool outputs. Input hashes cover exact bytes.

Findings are `candidate` or `confirmed`; supplied CVE applicability is separately `candidate` or `verified`. Drafts include both. `--release` requires a human reviewer name/date, confirmed status for every included finding and verified applicability for included CVEs. No claims are promoted automatically, and there is no exclusion option that silently hides candidates. The review label does not verify evidence or authorize external release.

CVSS imports only versions 3.1 and 4.0, an explicit numeric score, vector, source, and retrieval date. Perform basic shape/version/range checks, without a scoring algorithm or verification of public facts. Human reviewers must validate vector/score consistency and suitability. Business severity/impact are separate supplied fields.

## Data boundaries and failure behavior

Input size and per-field/list limits cap rendering workload. Artifact references must be relative, without traversal, drive/URL/UNC prefixes or backslashes; they are never opened. HTML/Markdown control characters are escaped in Markdown; ReportLab XML is escaped and every string is treated as plain text. Unsupported PDF characters fail before output creation rather than silently disappearing. Supported font coverage is checked with locally available DejaVu/Arial fonts; no fonts are downloaded.

Validate the complete document before creating the destination. Refuse an existing destination directory. Render all files into a sibling temporary directory and publish it by renaming after successful creation. Refuse outputs under synced `sources/` or reusable `tooling/`. Remove staging data if rendering fails; errors identify contract locations, not source content. Output is client-derived and inherits the input marking.

The manifest records schema/generator version, review label, classification/data category, input SHA-256, and artifact hashes. It establishes file identity, not authenticity or exploit validation. Avoid embedding absolute input paths, environment usernames, current host details, or raw evidence in the manifest.

## Dependencies and tradeoffs

Python 3.10+ plus ReportLab for PDF. Markdown-only mode works with the standard library. Pin the version actually exercised in this preparation environment; event dependency/license/public availability and installation require separate review. Tests use stdlib `unittest`; PDF extraction QA uses preparation-only `pypdf`. No web renderer, remote assets, container daemon, model service, or hosted CI is required for runtime.

Strict validation favors predictable evidence over arbitrary scanner ingest. Markdown remains editable, but editing it does not update the PDF: revise normalized input and regenerate, or document any manual artifact amendments. The sample is a training artifact, not a client deliverable. A release gate can enforce metadata but cannot prove a human actually reviewed or that findings are true.

## Current format and architecture decisions

The user-provided OSCP reference is read-only evidence. Reuse a cover, contents, numbered introduction, high-level summary/recommendations, methodology, detailed findings and appendices. Use original wording and existing client-facing evidence/status fields. Exclude embedded exam instructions, sample exploit/credential/proof data and source screenshots; no activities are authorized by section names. DOCX outline/styles/section dimensions were inspected; source rasterization failed for absent LibreOffice, so exact visual fidelity is not claimed.

Both renderers consume one ordered report block model. PDF uses Letter/one-inch margins, local fonts, restrained title color, separate cover/contents, actual contents page numbers via deterministic multi-pass ReportLab layout, and stable page/data markings. No remote assets or Word runtime are needed. Large narratives still split; unsupported glyphs fail atomically. Existing reviewed literal escaping and JSON failure diagnostics remain.

Authoring extension tradeoff: optional schema 1.1 fields let an analyst supply an objective, high-level recommendations and information-gathering/service-enumeration/validation/cleanup narratives without inferring them from scanner records. A missing objective/recommendation is described as not supplied; omitted activity sections do not claim execution. Core findings remain unchanged. Business priorities and cleanup outcomes are never synthesized.

Farm-toolkit is still an Analyst catalog, not forty deployed producers. The public design maps every TOOL-001–040, preserving its holds and distinguishing planned native exports, generic helper envelopes and reference-only content. Prefer selected native metadata formats (Nmap XML, TShark selected-field exports, Zeek JSON, EVE JSON, and later enum4linux/testssl/ffuf fixtures) over arbitrary text scraping. Protocol libraries/lab helpers should emit the proposed cptc.tool-run/1.0 envelope directly.

The proposed intake layer is deliberately separate from rendering. It records run state/provenance and typed metadata observations before human finding curation; it cannot populate confirmed findings, impact, severity or remediation automatically. Future report schema must expose run/observation ledgers. Do not silently treat the envelope as current report input. First adapters require selected-version fixtures, closed field profiles, license decisions and positive/error/partial/duplicate/sensitive-input tests. No upstream runtime is added by this design.

Compatibility and verification: preserve 1.0 rendering, strict 1.1 bounds, release/offline/atomicity/error gates and original samples. Check both serializers for all supplied facts, actual TOC page numbers, page images for sample/long/empty reports, deterministic same-runtime hashes, and complete catalog ID coverage. Original DOCX/farm artifacts and existing repository tools stay unchanged. Independent review must identify the exact code/design version before PR update.

## Later implementation

1. Inspect existing team repo and synthetic November-script output before porting. Preserve established conventions and student ownership.
2. Implement per-tool adapters with visible error/partial-run state and hash-preserved raw output in authorized private storage.
3. Add a public, hashed metadata cache for exact-CVE lookup before product/version suggestions; keep uncertainty, dates, licensing and applicability explicit.
4. Pursue local AI as a separate proposal after policy and runtime feasibility checks. Prompt/output stores remain derived client data; model output has no tools or release authority.
