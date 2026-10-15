The team needs reports that connect supplied technical observations to business impact, evidence, remediation and review status. This adds an offline reporting module under tooling/reporting and a report structure loosely informed by a conventional assessment/exam report: cover, contents, introduction, high-level summary and recommendations, methodology, detailed findings and evidence/review appendices. Markdown and PDF use the same ordered content; PDF contents show actual page numbers.

Version 0.2.0 retains report schema 1.0 and adds schema 1.1 with bounded optional objective, recommendations and methodology narratives. Missing activity is not inferred. Supplied findings, candidate/confirmed status, CVE/CVSS claims and provenance remain literal; no automatic scoring or confirmation occurs. Inputs remain synthetic only.

The intake design maps all forty proposed farm-toolkit candidates plus Nmap XML to planned native metadata adapters, helper-produced envelopes, reference-only inputs or holds. It defines run/observation/import provenance, success/partial/failure/not-run/duplicate behavior, metadata minimization and human finding curation. The synthetic tool-run example is a design fixture. Direct imports are not implemented; the current CLI accepts completed report JSON only.

Existing scanner, configuration, installer, root dependency file, license and enumeration policy are preserved. No source template, screenshots, generated reports, local planning records, private evidence or credentials are included. No new reporting runtime dependencies were added by the format update.

Validation from this repository copy:

- 29 Python unit tests passed, including legacy compatibility, authoring bounds, release gates, socket-blocked PDF export, safe failures, output atomicity and hash provenance.
- 196 complete-report Markdown parser cases passed using Marked 17.0.5, including all new source fields and injected-link checks.
- Actual 8-page sample export passed source-text/hash/inactive-content checks and verified all contents page numbers.
- Sample, long-text and empty-report PDFs were visually inspected across all 25 pages; legacy schema 1.0 and same-runtime deterministic output checks passed.
- Exact public-file allowlist, source/catalog integrity, unchanged existing tools, ignored outputs, local links and Git whitespace checks passed.

Independent read-only agent review of commit ec767e4 returned a scoped positive verdict with no new actionable findings. It independently reran all 196 Markdown cases, checked sample/stress/empty/legacy PDFs and focused contract/release/parser paths, verified all forty routes and catalog holds, and inspected representative page images. Actual upstream adapters, approved client-data handling, competition-host validation and event approval remain separate work. The reporter performs no scanning, network/model calls, evidence-file reads or publication.
