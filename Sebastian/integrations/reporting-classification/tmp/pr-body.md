This adds an offline reporting module under tooling/reporting: structured synthetic finding JSON produces editable Markdown, optional PDF and a hash manifest. The original assessment-report layout includes a cover, contents with actual PDF page numbers, introduction, executive summary/recommendations, methodology, detailed findings and evidence/review appendices.

Version 0.3.0 adds structured handling inheritance in report schema 1.2. ORCON is mandatory; PROPIN, PII, PII Red and FI restrictions are retained from parent/source records into derived findings and the whole report. PII Red supersedes ordinary PII, while unrelated categories remain combined. The resulting marking appears on every PDF page, Markdown and the manifest. Recognized explicit labels survive migration; schemas 1.0/1.1 remain usable with unverified-inheritance warnings. Labels do not detect sensitive prose, authorize disclosure or enable real client input.

Business severity remains analyst-supplied. Reports explicitly state that no severity matrix is configured and no likelihood/impact scoring is performed. CVSS remains separate supplied metadata; no client matrix or mapping is invented. Candidate/review status and source facts remain literal, with no automatic scoring or confirmation.

The intake design maps forty proposed farm-tool candidates plus Nmap XML to planned native metadata adapters, producer envelopes, reference-only input or holds. It covers run/observation/import provenance, failure/partial/not-run/duplicate behavior and human finding curation. Direct adapters remain design-only; current commands accept completed report JSON.

Validation of the classification update:

- 36 unit tests pass in the isolated repository checkout, including inheritance, migration, malformed tags, review/synthetic gates, offline PDF generation, safe failure and output atomicity.
- 392 complete-report Markdown cases pass across schemas 1.1/1.2.
- The nine-page mixed-source sample passes source-text/hash/TOC/inactive-content checks, with ORCON//PROPIN//PII Red//FI on every page. All nine pages visually inspected; deterministic output checked.
- Legacy and empty PDFs pass the same automatic checks. Existing tools/dependencies unchanged in this reporting contribution; exact public-file allowlist, private-source audit and whitespace checks pass.
- Independent read-only review at commit 5fc9b7d found no new actionable issues, independently checking 392 Markdown cases, 4096 inheritance combinations, malformed/migration paths and every-page PDF markings.

Only generic code/design/templates and invented fixtures are included. No source workbook, source template, contacts, client values, generated reports or local planning records are uploaded. No new runtime dependencies, scans, network/model calls, evidence-file reads or publication paths are added to the reporter. Native adapters, actual severity-matrix support, approved client handling and event-host validation remain separate work. Existing concurrent farm-toolkit work is excluded from this reporting commit. PR remains draft; no merge requested.
