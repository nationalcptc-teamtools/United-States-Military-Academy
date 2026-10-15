## Review extension — handling inheritance and severity provenance

Reviewed: 2026-10-15
Reviewer: /root/format_intake_review, independently and read-only under the user's existing authorization. Root retained editing ownership of the isolated reporting checkout. Proposed for the shared review.md editor; no global records overwritten during concurrent work.

Scope: FR-10, FR-11, NFR-07 and T-15–T-18. Inspected proposal/spec/design/tasks/execution guidance, public code/design/template/test delta, synthetic fixtures, existing outputs and representative page images.

Commit: 5fc9b7d3619daf6b491d692891d3f9511e34538c, generator v0.3.0, integrations/reporting-classification; baseline ec767e4. Final worktree clean; whitespace check passed. Eleven-file reporting/root-guidance delta.

### Specification compliance

Scoped positive verdict. Schema1.2 requires structured report markings with ORCON and accepts additional finding/evidence restrictions. Descendants retain their declared ancestor baseline; evidence restrictions roll into derived findings and all findings into the overall report marking. Orthogonal categories are unioned; PII Red supersedes PII. Computation does not mutate input.

Recognized exact tags in the original document label add restrictions in every supported schema, including1.2 migration. Document labels cannot remove structured restrictions. Schemas1.0/1.1 remain compatible with explicit unverified-inheritance warnings.

Canonical markings appear in Markdown, manifest and every PDF page; finding/evidence markings remain visible. These metadata controls do not detect sensitive prose, implement access control, authorize disclosure or enable real-client input.

Severity remains analyst-supplied. Reports explicitly state matrix not configured/no likelihood-impact scoring; CVSS stays separate metadata. No unsupported client-matrix algorithm or mapping was introduced. Actual matrix remains unresolved.

### Implementation quality and independent verification

Inspection confirmed bounded closed marking fields, sanitized rejection, canonical display, literal rendering and existing review/synthetic/offline/atomic-publication boundaries.

Independent write-free checks passed:

- 392 complete-report Markdown cases, 196 each schemas1.1/1.2.
- 4,096 in-memory inheritance combinations across baseline/finding/evidence, PII/PII Red and input immutability.
- 21 malformed marking cases across all three levels without diagnostic value leakage.
- Known PII Red/FI document-label preservation across1.0/1.1/1.2, legacy status, synthetic-only and candidate-release gates.
- Sample/legacy/empty PDF QA (9/9/7 pages): supplied text, hashes, contents page numbers, inactive content and every-page markings.
- Current sample/isolated export byte-identical including manifest; workbook hash unchanged.
- Visually inspected sample pages1/3/4/6/7/8: readable cover/section/source labels, combined footers and severity-method notice, no clipping/overlap.

Root separately ran all36 unit tests in the isolated copy and inspected all9 final sample pages. Reviewer did not independently rerun the full suite, create PDFs or inspect every page. Workbook interpretation was assessed from recorded evidence, with independent file-identity verification rather than rereading every cell.

### Exact hashes

Generator fdecf7b89b6eeb7272f9c8351b87928c62832064e2ca1b866fc54f00337b2f70
Design f6114538382e328efd6225b62207e7c5341b45d50917f6cc0be637c7b0347437
Tests 7d48ea5243bbf2138961244f63fd3c0c8fc7892b5e0b4524f4ba67f9d4e0c4eb
Markdown QA d2c6c5c87d4e03a74c125c56f829723b044012ee7d6f6d2ac86923d0d196b460
PDF QA e58114728b2bb200327b305895284ef0ddc4ef5dbeaa09bb4d9b4f66a001d45e
Fixture36bf23c09401943eda0177c20cbe240e4cb77050b4ee10f9d80125d149b71cdd
PDF a7f2fc39ba1e387812278a531e643635cf97b0748970ff8b73f6cc5adc1ed23e
Workbook f7a9b3e77e0ee69410f9ebf9359e7afc443a3044da040c56ecd9029a402dd3b9

### Findings and verdict

No new actionable findings or R-04. R-01–R-03 remain resolved. Scoped positive review; ready for already-authorized PR update after final status/remote-head/public-content checks. No conclusion about concurrent farm-toolkit/shared-checkout changes. Native adapters, actual severity-matrix support, real-data authorization, event-host validation, user acceptance and event approval remain outside scope.
