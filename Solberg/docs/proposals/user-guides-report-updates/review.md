# Independent review

Two read-only specialists reviewed reporting behavior and human documentation; neither implemented source edits. Root retained the editing slot and remediated findings.

| Finding | Disposition |
| --- | --- |
| R-RU-001 Cross-import finding IDs could collide during updates | Fixed: check every other import before preview/apply; regression preserves ledger on failure. |
| R-RU-002 Numeric equality could disagree with canonical report hashes | Fixed: compare canonical bytes for modifications/touched findings; regression checks score 7 versus 7.0. |
| R-UG-001 Duplicate/no-op documentation must match workspace revision semantics | Verified: transaction guard retains exact state bytes; replay/no-op tests cover behavior. |
| R-UG-002 Supplied-byte provenance was ambiguous for updates | Fixed: original input bytes retain input_sha256; canonical rendered input/result identities are separate. |
| R-UG-003 Six upstream procedure routes were misleading | Fixed: dedicated remote host/directory and TLS/web procedures, matching catalog and guide links. |
| R-UG-004 Stale version/dependency/exit-code/format prose | Fixed: current application/minimum reporter versions, dependency/font rejection status and Word appendix wording. |
| R-UG-005 Evaluation metadata was confused with actual installer inventory | Fixed: guide/catalog distinguish evaluation holds, selected-release notes, installation inventory and operational acceptance. |

Final independent source/docs re-review returned no remaining material findings. Settled verification passed, including canonical differences for already-candidate numeric edits and freshly extracted source tests. User and event acceptance remain separate and pending.
