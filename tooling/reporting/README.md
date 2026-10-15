# Offline reporting starter

Version 0.3.0. Preparation prototype using **synthetic input only**. It generates editable Markdown, optional PDF, and a hash manifest. No network requests, AI, CVE lookup, scanner execution, remote images, or evidence-file reads.

The original report format loosely follows a conventional assessment/exam-report structure: cover, contents, numbered introduction, high-level summary/recommendations, methodology, detailed findings and evidence/review appendices. PDF contents include actual page numbers. Source text and review status are retained; section headings do not assert that any activity occurred.

Use [the report-authoring template](templates/report.md) for additional rating explanations, validated attack narratives and remediation planning. Optional authored content outside the input contract remains manual. [Historical CPTC examples](https://github.com/globalcptc/report_examples) inform reporting practice; they do not replace the actual event rubric.

## Run

Requires Python 3.10+. Markdown uses only the standard library. PDF uses ReportLab 4.4.9, declared in requirements.txt. In an approved development environment, install with your normal Python package-management process; reconfirm public availability/licensing and event installation rules before competition.

From the project root:

~~~powershell
python tooling/reporting/reportgen.py tooling/reporting/examples/report-marked.json --output-dir output/pdf/sample-report --pdf
python -m unittest discover -s tooling/reporting/tests -v
~~~

Optional development QA checks complete reports through an available Marked parser. Node and Marked are preparation-only tools; the generator and Python unit tests do not require them. With those tools already available, run:

~~~powershell
python -B tooling/reporting/tests/check_markdown_rendering.py --node node --marked-module /path/to/marked/lib/marked.esm.js --fixture tooling/reporting/examples/report-marked.json
~~~

This checks literal text and report structure across indented text, equals-sign lines, HTML, links, code-looking text and multiline source fields, without writing reports or retrieving remote content.

Optional PDF QA uses preparation-only pypdf to check source-text preservation, actual contents page numbers, hashes and inactive output. Visual page inspection is still required:

~~~powershell
python -B tooling/reporting/tests/check_pdf_rendering.py tooling/reporting/examples/report-marked.json output/pdf/sample-report
~~~

Choose a **new output directory** each time. Existing destinations are refused. Outputs are report.md, report.pdf (when requested), and manifest.json. The editable JSON is the source of truth; editing report.md does not update report.pdf. Revise JSON and regenerate to synchronize outputs.

Use - as input to consume a future adapter's JSON from stdin. --release changes the training label only when a reviewer/date and fully confirmed findings/verified CVE applicability are supplied. It neither validates evidence nor approves event submission. The sample includes a candidate, so its release request is deliberately rejected.

Client-derived inputs are rejected by this starter. A future approved handling extension and actual-script integration are required before event use. Do not label real data synthetic to bypass this boundary. This current preparation workspace may be synced and cloud assisted.

## Normalized contract (schemas 1.0, 1.1 and 1.2)

The included example is a complete contract fixture. Unknown fields are rejected so misspelled evidence does not disappear.

| Object | Fields |
| --- | --- |
| Report | schema_version, data_category (synthetic only), classification, engagement, findings; optional review |
| Engagement | id, client, team, report_date (ISO date), scope[], methodology, executive_summary, limitations[] |
| Finding | id, title, severity (critical/high/medium/low/info), severity_rationale, status (candidate/confirmed), assets[], description, validation_steps[], business_impact, remediation, retest_steps[], evidence[]; optional cves[] and cvss |
| Evidence | id (unique across report), observed_at (ISO timestamp with timezone), collector, tool, tool_version, summary; optional artifact and sha256 |
| CVE reference | id, applicability (candidate/verified), match_basis, source, retrieved_at (ISO date) |
| CVSS | version (3.1/4.0), score (finite 0–10), vector, source, retrieved_at (ISO date) |
| Review | reviewer, reviewed_at (ISO date) |

Schema 1.0 remains accepted with the same fields and review rules. Schema 1.1 additionally allows optional engagement objective (text up to 10,000 characters), recommendations (1–20 strings up to 2,000 characters each), and methodology_sections (a nonempty object containing only information_gathering, service_enumeration, validation and/or cleanup, each text up to 10,000 characters). These extra keys require schema 1.1; unknown fields and malformed/empty supplied sections fail.

The original report.json remains a 1.1 compatibility fixture. The recommended report-marked.json uses 1.2 and invented handling tags, with no actual personal or financial information. Missing objective/recommendations are identified as not supplied; omitted methodology activities do not appear. The reporter does not infer exploitation, persistence, cleanup, successful remediation or client priorities.

Schema 1.2 adds required report markings[] and optional finding/evidence markings[]. Allowed tags are ORCON, PROPIN, PII, PII Red and FI. The report must include ORCON. Children inherit ancestor restrictions and can add tags; evidence restrictions roll into derived findings and the whole report. Combined categories are retained, while PII Red supersedes ordinary PII. Unknown/duplicate/empty/malformed tags fail. For example, mixed internal-system, financial and high-sensitivity personal sources produce ORCON//PROPIN//PII Red//FI. This marking appears on every PDF page, Markdown and the manifest, even if only one source carries a restriction.

ORCON is originator/client control; PROPIN covers internal systems/methods/procedures, PII employee/customer information, PII Red identity-theft-sensitive PII and FI financial information. No total ranking between these categories is assumed. The free-text classification field is a supplied document label, not a downgrade override. Legacy 1.0/1.1 output retains recognized explicit tags and ORCON but is visibly flagged as unverified for structured inheritance. Labels must be supplied accurately; the generator does not inspect prose for sensitive data, grant disclosure permission or allow real client inputs.

Business severity is analyst-supplied and the report explicitly says “matrix not configured.” No likelihood/impact scoring or client-matrix mapping is implemented. Supply the actual matrix and its interpretation before implementing that mapping; CVSS does not substitute for it.

IDs are up to 64 letters/numbers/underscores/hyphens. Titles are up to 180 characters; narratives up to 10,000 each; input is at most 2 MB and findings at most 200. Required lists must contain at least one entry, except findings may be empty with explicit limitations. See validator for per-list limits.

CVSS checks are **shape/version/range only**, not full metric semantics or vector/score consistency. Values are supplied claims, not computed or fetched facts. Human reviewers must verify the source and score. Business severity is independent. Findings without applicable CVEs/CVSS should omit those fields.

Evidence paths use relative forward-slash form without traversal, URLs, or drive prefixes. They are printed as private references, never opened. Supplied hashes are not verified. The input hash covers exact original JSON; output hashes identify files, not truth/authenticity.

## Adapter development on 14 November 2026

[The format and intake design](design.md) maps all forty farm-toolkit candidates and existing Nmap XML to planned native-export, helper-envelope, reference-only or held routes. It specifies run/observation provenance and explicit success/partial/failure/not-run handling before human finding curation.

**These adapters are design only.** [examples/tool-run.json](examples/tool-run.json) illustrates the proposed cptc.tool-run/1.0 producer contract; it is not accepted by the current report CLI. The current command reads completed report JSON only. Selected-version fixtures, license/metadata decisions and a run-aware report schema are required before direct import is implemented. No upstream tool is installed or launched by this module.

For each actual team script, obtain a synthetic fixture and map its observations to this contract. Preserve raw output privately with a hash, tool/version, timestamp/timezone, operator, command context, and exit status. Keep normalized summaries visibly separate from originals.

Adapters must reject malformed/partial output or surface its limitations explicitly. A failed run must never be converted to a successful zero-finding report. Keep product/version or CVE matches as candidates until an analyst verifies applicability. Do not run scans from the report generator.

Real client-data ingestion, job-status records, screenshot embedding, automated duplicate grouping, cache enrichment and model inference are **not implemented**. Follow the project proposal/roadmap to define and verify those additions.

## Rendering and storage

Text is rendered literally, without interpreting source markup or instructions. Markdown escapes raw HTML and formatting controls. PDF uses locally installed Arial on Windows or DejaVu Sans on Linux, falling back to built-in fonts for supported text. Missing glyphs cause a clear failure; no fonts are downloaded.

Outputs stage together and publish only after successful rendering. No destination overwrite option is provided. The source tool directory and synced sources directory cannot be output targets. Store real engagement material only in approved, access-controlled event storage outside public code and consumer sync folders. Ignore files do not remove tracked data or prevent unrelated uploads.

Only this reusable directory's code/templates/synthetic fixtures are public-integration candidates. An eligible student must review it against the team's existing repo conventions, current rules and dependency/runtime availability before porting. This package does not claim repository approval.
