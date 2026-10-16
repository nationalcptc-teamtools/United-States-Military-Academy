# Design

`tooling/reporting/updates.py` owns canonical report identity, the closed `cptc.report-update/1.0` operation envelope and finding/evidence differences. It accepts the reporter's contract helpers by injection, returns a deep-copied validated candidate plus receipt, and has no filesystem/render/target dependency. Canonical sorted-key UTF-8 JSON provides a whitespace/BOM-independent fingerprint. Equality uses canonical bytes consistently, including numeric representation.

`reportgen.py` owns bounded input reading, contract validation, previews and atomic all-format publication. Every bundle includes the actual rendered input. Supplied-byte input identity remains separate from canonical result identity. Updated bundles preserve exact update bytes and receipts; no standalone replay ledger is implied. Existing shared Markdown/PDF/Word rendering remains authoritative.

Workbench `reports.py` reuses the engine under `workspace.change`'s exclusive lock and import revision check. It preserves original imports, clears affected dispositions, checks global finding uniqueness, inherits restrictions and retains applied receipts. Identical effective-update replay is checked before stale-base failure; conflicting reused IDs reject. Unchanged transactions avoid persistence and revision changes. Optional review revision guards stale acceptance. Snapshot differences include evidence and applied update receipts.

Human guides separate owned command interfaces from upstream library/client/runbook routes. Six misleading procedure routes receive dedicated remote-metadata and TLS/web sections. New native parsers, automatic severity/CVE mapping, claim graphs, execution profiles, target operations and CI are excluded.

Tradeoff: generated Markdown/Word edits are not imported; authoritative fields must be amended explicitly. Lists replace only when explicitly named in authored amendments. Historical evidence correction uses a newly identified observation. Workspace storage remains a bounded local ledger, retaining the established complete-bundle/failed-ledger limitation.
