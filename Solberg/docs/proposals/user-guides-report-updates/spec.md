# Requirements

| ID | Observable acceptance |
| --- | --- |
| FR-UG-001 | Every repository-owned human CLI/action family has prerequisites, exact usage, outputs, limitations and recovery guidance; all workbench command names occur in the guide. |
| FR-UG-002 | README contains a runnable standard-library offline quick start, optional PDF/Word route, graphics with alt text and deeper guide links. |
| FR-UG-003 | All forty catalog IDs have individual operator entries and valid procedure links; libraries/holds/lab routes and installer state are distinguished. |
| FR-RU-001 | Standalone/workbench use one pure update policy for appended evidence, new findings and explicit authored-field amendments. |
| FR-RU-002 | Update previews write nothing; application rejects stale fingerprint/revision, wrong engagement and conflicting IDs atomically. |
| FR-RU-003 | Original evidence/authored fields/unrelated findings, effective restrictions and previous exports are preserved. Changed findings lose review; no-op changes retain it. |
| FR-RU-004 | New immutable exports contain authoritative input, synchronized requested formats, hashes and finding/evidence differences. Workbench retains update/review history and handles exact applied-ID replay without writes. |
| NFR-RU-001 | Inputs remain bounded, synthetic-only, passive/offline; no scanner/evidence access, AI or automatic confirmation. |
| NFR-RU-002 | Existing workspaces, report schemas and positional render/snapshot API calls remain compatible; source packages include new modules/guides/tests. |

Failure cases: malformed operation, partial invalid batch, wrong owner for evidence ID, cross-import finding ID collision, numeric representation/hash mismatch, stale reviewer, failed rendering, existing destination, unavailable dependency/font and ledger I/O failure after complete snapshot publication. Preserve explicit limitations rather than infer successful zero findings.
