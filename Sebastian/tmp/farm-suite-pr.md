The team can prepare the supported farming IT/OT assessment suite from the repository with `bash install.sh --profile full`, activate it, and verify the installation without Internet. This replaces the legacy interactive installer with profile-based setup, isolated Python environments, source-pinned native builds, hash-checked LinPEAS/WinPEAS downloads and an explicit local installation inventory. Setup launches no assessment tool, payload or lab service.

The contribution includes a forty-tool catalog, source/license evidence, bounded protocol runbooks, passive integrity/readiness helper, stable requirements, design, verification notes and synthetic tests. Full installs supported IT/OT assessment clients and libraries; lab servers, sensors, hardware paths and held legacy/integration components have separate visible dispositions and upstream setup guidance. ReportLab is included; Prowler and legacy wkhtmltopdf are explicit options.

This PR is stacked on **#1 / `codex/report-generator` at 5fc9b7d**. It adds no reporting-source or scanner/configuration changes. Concurrent master c2468f2 adds independent Linux/Windows runners and a 19 October note; their operational behavior and installers remain separate. PR #1 currently needs reconciliation with updated master before the stack can merge. No merge is requested.

Validation:

- 39 contract tests pass on Kali Python 3.14.7; Windows Python 3.12.14 passes 38 with one native-symlink privilege skip. Root shell syntax, passive preview, catalog and deterministic source-only archive checks pass.
- A disposable clean Kali image installed full prerequisites and all Python groups. After correcting BACnet's routing build default, installation resumed and completed the native clients/SDKs, staged PEASS bytes and final check. Exact final-manifest same-prefix rerun passes with container networking disabled and `PIP_NO_INDEX=1`.
- Thirteen disconnected installed-state cases verify intact/restored state and reject incomplete inventories, removed native/library/source-link/venv components, changed payloads, dirty sources, absent dpkg installed status and redirected writes.
- Independent review identified and rechecked incomplete-inventory and redirected-path defects; full-profile membership, venv identity, dependency status, required native outputs and source/link integrity are now checked.

Only reusable code/docs/notices and invented fixtures are published. No downloaded upstream software, local prefix, private planning, customer material, credentials, captures or real findings are included. CI adds Linux/Windows contract checks.

Installation is separate from operational/event acceptance. Rolling distro/transitive Python versions are resolved and recorded, not a fully immutable offline reinstall cache. Windows execution, protocol/traffic/hardware rehearsals, full license/dependency closure and event-specific staging/SOW/freeze decisions remain explicit gates. See `tooling/farmkit/INSTALL.md`, `VERIFICATION.md` and `spec.md`.
