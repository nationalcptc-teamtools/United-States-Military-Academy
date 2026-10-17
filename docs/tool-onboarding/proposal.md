# Optional tool onboarding proposal

User request: load the recorded tool inventory and additions onto the repository, provide one-line preparation commands, independently useful tools and documentation matching the existing graphical guides. Authorized 16 October 2026.

Baseline: upstream master 96c7be5751f4a2ea862af58ef40428da098e5d84 plus previously reviewed local maintenance/configuration/report fixes. Upstream history was rewritten; local fixes were preserved in a stash and applied onto a new branch without merging obsolete history. Root is sole editor. Specialists inspect read-only.

Scope: individual acquisition/checking for the forty catalog entries; optional sensors and isolated lab acquisition; Syft, pip-tools, LibreOffice and existing Linux runner packages. Maintain held statuses and separate runtime acceptance. No native format adapters or expanded CI (explicitly deferred by user). No new assessment execution or automatic lab startup.

Capability matrix:

| Existing capability | Missing capability | Addition / benefit | Duplication risk / effort |
| --- | --- | --- | --- |
| core/full farm installer | Individual acquisition, optional tools | Reuse acquisition primitives with separate selection inventory | Low; medium |
| Forty capability cards/runbooks | Exact copyable preparation paths | Registry and linked guide | Low; medium |
| Source package manifests | New files in portable packages | Extend existing allowlists | Low; small |
| Reporting PDF/Word | Optional inventory, locking and visual QA preparation | Syft, pip-tools, LibreOffice routes and examples | Low; medium |

Implementation: complete for FR-01..07. Verification: complete within the documented supported-host/package scope; optional skips, Windows file-lock failures and runtime limits are recorded in verification.md. Independent implementation and specification/documentation reviews: passed after remediation. Publication FR-08: branch codex/tool-onboarding is published in [pull request #3](https://github.com/nationalcptc-teamtools/United-States-Military-Academy/pull/3), open for review and unmerged. Implementation commit: e7a0fb7744f96be708e8f2f841f80c6cc4a2c8fa; subsequent handoff documentation records publication. User/event acceptance: pending; installer success does not approve operations or licenses. This proposal has no consolidation README until explicit acceptance.
