# Word requirements

FR-12: Optional --docx adds report.docx to existing Markdown and optional PDF exports, plus its SHA-256 in the same manifest. All requested formats publish together or none publish; prior positional API calls and existing destinations remain safe.

Acceptance: editable native Word paragraphs, headings and lists contain the same source facts, statuses, severity-method notice, evidence references and review record as the shared view. Contents links target actual chapter bookmarks without claiming PDF page numbers. Repeated headers/footers carry overall inherited handling, draft/training status and page-number field. Plain source text cannot become fields, external links, macros or commands.

NFR-08: Word dependencies load only when requested; missing dependency and illegal XML characters yield sanitized rejection without partial outputs. Same-runtime output is deterministic with fixed non-personal metadata and ZIP timestamps. Existing synthetic/review/offline/atomicity/legacy/schema handling remains; no client evidence or source template is embedded. New dependency pinned to exercised python-docx 1.2.0.

Verification includes all-format export, source-content/OOXML/internal-nav/numbering/metadata/manifest inspection, legacy/empty/release/failure/dependency tests, retained Markdown/PDF tests and packaged DOCX renderer attempt plus all-page visual QA if available. Current runtime has no bundled LibreOffice; visual verification availability is an explicit gap to resolve or report, never fabricate. The severity matrix remains unresolved and no new scoring is added.

