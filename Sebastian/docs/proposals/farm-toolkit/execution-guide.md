# Farming toolkit execution guidance

Prepared 2026-10-15. Root owns the sole editing slot across docs, code and tests. `/root/architecture`, `/root/provenance` and `/root/validation_review` are read-only specialists. None has repository write, publication, installation or target authority. Preserve `sources/`, reporting artifacts and integration checkout.

Execute T-FT-03 then T-FT-04/05, T-FT-06, independent T-FT-07/remediation, then T-FT-08. External T-FT-09 remains separate. Each changed requirement returns through Architect/Planner; no silent scope reduction. Use the design's `tooling/farmkit/` path consistently.

Developer assignment: build all forty catalog records, source references, empty actual artifact inventory, strict offline helper, synthetic artifact fixtures/tests, readiness/evidence/runbooks/notices. Distinguish selected-for-evaluation from staged/tested. Preserve all holds; do not build a scanner, generic installer, downloader or report adapter. Check the actual CLI and malformed cases before returning current paths/hashes to Tester.

Tester assignment: inspect actual implementation; exercise positive and adversarial paths, integrity/missing-data/path/type/dependency failures, held staging, expected pending readiness, and no network/process execution. Inspect all requirement mappings and public-package contents. Use synthetic data only. Record exact runtime/version/results and skipped/not-run paths; never equate synthetic hash verification with upstream tool execution. Root may write test fixtures; independent specialist checks in memory or read-only.

Reviewer assignment: `/root/validation_review` independently inspects settled actual files and representative CLI paths, source evidence and validation material. Return severity, exact location, impact/correction and disposition for each `R-FT-*` issue; state specification gaps and implementation quality separately. Root implements corrections, reruns affected checks and asks reviewer to recheck. Record current hashes and scope; do not reuse reporting's review verdict.

Delivery assignment: create a local package from a fixed public file list with hashes and deterministic ZIP metadata. Inspect ZIP contents, validate the extracted package read-only where possible, and keep planning/client/source/private records out. Update proposal/tasks/journal with actual evidence. No consolidated proposal README until explicit user acceptance and full scoped completion.

Review focus: misleading readiness, unresolved PEASS/BACpypes3/modified licenses, custom license relabeling, artifact path escapes/reparse points, malformed JSON/duplicate keys, fake hashes, dependency cycles, moving source pins, source/protocol output treated as instructions, executable defaults in OT guidance, reporting-contract drift and accidental changes to the existing PR.
