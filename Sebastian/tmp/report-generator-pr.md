Existing Nmap exports describe individual scans, but the team also needs structured reports with business impact, remediation, retest steps, provenance and explicit review status. This adds a passive reporting starter under tooling/reporting: normalized synthetic JSON produces editable Markdown, optional PDF and a hash manifest, alongside reusable report/finding/incident templates.

The module is version 0.1.1 with schema 1.0. Source text is rendered literally; candidate observations and supplied CVE/CVSS claims are preserved without automatic confirmation or scoring. Inputs are synthetic only. Actual-script adapters and approved client-data handling remain future work.

Existing configuration, scanner, installer, dependency file, license and enumeration policy are preserved. Root changes only add reporting usage guidance and ignore generated report/private-data folders. The contribution contains code, templates, documentation, synthetic fixtures and tests; no generated reports or local planning material.

Validation from this repository copy:

- All 25 Python unit tests pass, including socket-blocked PDF export, review gates, safe failure behavior and hash provenance.
- All 112 optional complete-report Markdown parser cases pass using Marked 17.0.5.
- The documented synthetic example generates Markdown/PDF/manifest successfully; artifact hashes and version/schema fields match.
- Staged-file allowlist, local links, unchanged existing tools and Git whitespace checks pass.

No scanning, evidence-file reads, network/model calls, vulnerability lookup or publication are performed by the reporting tool. Runtime/event-host approval and final submission integration are not established by these preparation checks.
