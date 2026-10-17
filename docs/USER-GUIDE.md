# User guide

For per-tool one-line acquisition, optional sensor/lab staging, SBOMs, dependency locks and Word conversion, see [tool onboarding](../tooling/farmkit/ONBOARDING.md). Use `python3 tools.py list` to see selections.

Run examples from the repository root. Use the root products and `tooling/`. Python commands require Python 3.10+; substitute `python3` for `python` on Linux. On Windows, use **PowerShell**, not Command Prompt, for PowerShell examples. Run each command separately and wait for the prompt to return.

## Choose a tool

| Goal | Entrypoint | Result / next guide |
| --- | --- | --- |
| Enumerate authorized scope from Linux | `cptc-linux.sh` | Evidence directory and Markdown/HTML/CSV/JSON; [Linux](#linux-runner) |
| Enumerate authorized scope from Windows | `cptc-windows.ps1` | Evidence directory and HTML; [Windows](#windows-runner) |
| Record your own activity on a box | `cptc-linux.sh logging enable` | Shell history, session transcripts, auditd and sudo I/O; `logging verify` proves events are recorded |
| Collect your activity logs before leaving a box | `cptc-collect-logs.sh` | One hashed zip on the Desktop with a manifest of what was skipped or truncated |
| Prepare the Kali assessment suite | `install.sh`, `tooling/farmkit/install.py` | Installed suite and inventory; [installation](#assessment-suite-installation) |
| Inspect metadata, integrity and readiness | `tooling/farmkit/kit.py` | Local results and status; [farmkit](#farmkit-metadata-and-packaging) |
| Package farmkit source | `tooling/farmkit/build.py` | Source-only ZIP; [packaging](#farmkit-metadata-and-packaging) |
| Find tools, curate reports and record preparation | `tooling/workbench/workbench.py` | JSON results, workspace and snapshots; [workbench](#workbench) |
| Create or revise a synthetic report | `tooling/reporting/reportgen.py` | JSON, Markdown, optional PDF/Word and hashes; [reporting](#report-generator) |
| Create the old scope configuration | `config.py` | Operator-selected JSON; [legacy](#legacy-compatibility) |
| Inspect retired scanner migration guidance | `super_nmap.py --help` | No scan or config writes; [legacy](#legacy-compatibility) |

Enumeration runners perform network activity and require authorized scope. Acknowledgement flags do not grant permission. Farmkit metadata and reporting/workbench are passive preparation tools. Reporting/workbench accept **synthetic data only**. The suite installer downloads software; it does not run assessments.

The [individual tool guides](TOOL-GUIDES.md), [forty-tool catalog](../tooling/farmkit/CATALOG.md) and [runbooks](../tooling/farmkit/RUNBOOKS.md) cover upstream clients, libraries, held candidates and lab systems. Read the applicable runbook before using an upstream tool. Catalog selection does not establish installation or rehearsal; do not assume general scanner profiles are suitable for OT/controllers.

## First report, without a network or optional packages

```powershell
python --version
python tooling/reporting/reportgen.py tooling/reporting/examples/report-marked.json --preview
python tooling/reporting/reportgen.py tooling/reporting/examples/report-marked.json --output-dir output/first-report
```

Expect a preview containing `report_sha256`, `engagement_id` and finding/evidence IDs, then a new directory with `input.json`, `report.md`, and `manifest.json`. The final message says `Generated Markdown`. Open `output/first-report/report.md` in your editor. An existing destination is refused; use another name for the next revision.

For PDF/Word, prepare optional dependencies first:

```powershell
python -m pip install -r tooling/reporting/requirements.txt
python tooling/reporting/reportgen.py tooling/reporting/examples/report-marked.json --output-dir output/first-all-formats --pdf --docx
Invoke-Item ./output/first-all-formats/report.docx
```

The `pip` step needs network/package access during preparation. Export itself is offline. [Update an existing report](REPORT-UPDATES.md) after a new synthetic tool result.

## Linux runner

Requires Bash 5, Kali/Debian/Ubuntu and the prerequisites checked by `doctor`. Privileged Nmap operations require root. Installation needs Internet and uses sudo for apt; prepare templates before offline operation.

```bash
bash cptc-linux.sh install --all --yes
bash cptc-linux.sh doctor
bash cptc-linux.sh help
```

`install --core` requests the foundation; `--all` is the default and attempts optional packages. Optional-package failures are warnings: inspect `doctor` before relying on a phase. This is separate from the broader suite's `install.sh`.

Scope files accept one authorized IP, CIDR or hostname per line, blank lines and `#` comments. Keep exclusions in a separate file. Copy values from engagement authorization. Example lab scope:

```text
# scope.txt — replace with authorized lab values
10.10.10.0/24
app.lab.example
```

```text
# exclude.txt
10.10.10.1
```

```bash
sudo bash cptc-linux.sh run --scope scope.txt --exclude exclude.txt \
  --authorized --profile standard --label lab-1
```

Hostnames resolve once and their addresses are frozen. Linux supports IPv4 and IPv6. `--dry-run` records scanner commands instead of executing them; it still prepares files and resolves supplied hostnames, and requires local prerequisites.

| Option | Meaning/default |
| --- | --- |
| `--scope FILE`, repeated `--target VALUE` | Explicit scope |
| `--exclude FILE`, `--authorized` | Exclusions and required acknowledgement |
| `--profile quick\|standard\|deep` | Default `standard` |
| `--udp` | Profile-dependent UDP pass |
| `--active-web`, `--enable-vuln-scans` | Separate noisier optional checks; verify ROE |
| `--domain DOMAIN`, `--interface IFACE` | DNS/AD domain and Nmap interface |
| `--phases LIST` | Subset of `discovery,tcp,udp,services,followups,vuln,report` |
| `--output DIR`, `--label LABEL` | Artifact parent and run label |
| `--jobs N` | Nuclei concurrency; 4 |
| `--max-rate N`, `--min-rate N` | Nmap packet rate; max 1000, min 0 disables floor |
| `--max-retries N` | Nmap retransmissions; 3 |
| `--host-timeout DURATION`, `--command-timeout DURATION` | Per-host `20m`, per-command `4h` |
| `--max-addresses N`, `--allow-large-scope` | Default ceiling 4096; explicit expansion override |
| `--max-followups N` | Per-protocol follow-up ceiling; 512 |
| `--snmp-community-file FILE` | Approved communities; one per line, file mode 0600/0400 |
| `--dry-run`, `-v`/`--verbose`, `-h`/`--help` | Command preview, verbosity and help |

`quick` uses discovery and top-1000 TCP with service/protocol follow-ups. `standard` adds all TCP ports on hosts found by discovery or the first TCP pass. `deep` scans all TCP ports across the full scope. Optional UDP uses top 20/100/250 ports respectively.

Resume or regenerate using the **exact directory printed by the original run**:

```bash
sudo bash cptc-linux.sh resume artifacts/RETURNED-RUN-DIRECTORY --authorized
sudo bash cptc-linux.sh report artifacts/RETURNED-RUN-DIRECTORY
```

Resume retains frozen scope and scan choices. Rate/retry/timeout/concurrency/follow-up limits may change. Repeat the original `--snmp-community-file` option when applicable. Altered covered evidence is refused; an interrupted run without a completed artifact manifest rebuilds phases.

| Run location | Contents |
| --- | --- |
| `logs/run.log` | Console transcript |
| `logs/commands.sanitized.sh` | Command journal with configured SNMP communities redacted |
| `logs/events.tsv`, `logs/errors.tsv` | Outcomes, exit codes, durations, log references |
| `raw/` | Nmap exports and command output |
| `scope/` | Frozen scope, DNS mapping and hashes |
| `targets/` | Parsed host/service/protocol lists |
| `reports/` | Markdown, HTML, CSV, JSON and manifests |

Archive the complete run directory, including raw evidence and logs.

## Windows runner

Use Windows PowerShell 5.1 in FullLanguage mode. Administrator rights plus Npcap enable privileged Nmap checks; otherwise TCP uses connect scanning. Inspect `doctor` for unavailable optional capabilities.

```powershell
Get-Help ./cptc-windows.ps1 -Full
./cptc-windows.ps1 -Action Install -InstallTool Nmap,httpx,nuclei,ffuf -Verbose
./cptc-windows.ps1 -Action Doctor -TargetsFile ./scope.txt -Verbose
./cptc-windows.ps1 -Action Run -TargetsFile ./scope.txt -Exclude 10.10.10.1 -Profile Standard -AcknowledgeScope -Verbose
```

Installation needs Internet, verifies publisher checksum manifests, and prepares Nuclei templates. Check installed Nmap/Npcap versions; WinGet's Nmap can lag upstream. Scope accepts `-Target 10.10.10.2,10.10.10.3`, `-TargetsFile`, or legacy `-ConfigPath`. Expansion is IPv4-only, capped at 4096 by default, with explicit `-AllowPublicTargets` required for non-private addresses.

| Parameter | Meaning/default |
| --- | --- |
| `-Action Install\|Doctor\|Run\|Report` | Default Run; alias `-Mode` |
| `-Target`, `-TargetsFile`, `-ConfigPath`, `-Exclude` | Scope; `-Targets` aliases `-Target` |
| `-ScanProfile Quick\|Standard\|Deep` | Default Standard; alias `-Profile` |
| `-OutputDirectory`, `-RunDirectory` | New-run parent (`./cptc-results`) or existing run |
| `-ToolsDirectory`, `-NucleiTemplatesDirectory` | Tool parent (`./.cptc-tools/windows`) and prepared templates |
| `-InstallTool` | Nmap/httpx/nuclei/ffuf; all four by default |
| `-MaxTargets`, `-MaxRate`, `-Throttle` | 4096, 1000, 20 |
| `-HostTimeoutMinutes`, `-CommandTimeoutSeconds` | 15, 3600 |
| `-WebRateLimit`, `-AdObjectLimit` | 25, 10000 |
| `-AcknowledgeScope`, `-NonInteractive` | Scope acknowledgement; supply acknowledgements when noninteractive |
| `-AllowPublicTargets`, `-EnableUdp`, `-EnableNuclei` | Explicit optional coverage |
| `-EnableFfuf -Wordlist FILE` | Content discovery; freezes/hashes run-owned wordlist |
| `-EnableAd -AuthorizedAdDomain DOMAIN -AcknowledgeAdDomain` | Domain metadata using current identity and available RSAT |
| `-SkipLocalInventory`, `-SkipWeb` | Skip selected collection |
| `-Resume`, `-Force` | Resume selected run; Force permits managed installer replacement |
| `-Verbose`, `-WhatIf`, `-Confirm` | Common/ShouldProcess controls; WhatIf still permits initialization/logging |

`Quick` uses Nmap's fast TCP set, `Standard` top 1000, `Deep` all TCP ports. Optional UDP uses top 20/50/100 ports. Every profile follows discovered services with version detection and explicit enumeration scripts. Enable optional network/AD phases only within authorization.

```powershell
./cptc-windows.ps1 -Action Run -Resume -RunDirectory ./cptc-results/RETURNED-RUN-DIRECTORY -Profile Standard -AcknowledgeScope -Verbose
./cptc-windows.ps1 -Action Report -RunDirectory ./cptc-results/RETURNED-RUN-DIRECTORY
```

Use original scope/profile. A missing checksum baseline disables checkpoint reuse; changed checksums refuse resume; missing/failed Nmap XML reruns its scan. Preserve `logs/`, `raw/`, `scope/`, `normalized/`, `report/index.html`, `run-manifest.json` and `SHA256SUMS.txt` together.

## Assessment-suite installation

The suite targets Kali Linux x86-64, Python 3.10+, Internet and several GB free. Run as a normal user; apt uses sudo. Staging WinPEAS does not make this a Windows installer.

```bash
bash install.sh --plan
bash install.sh --profile full
source .cptc-suite/activate
bash install.sh --check --profile full
```

Equivalent direct interface:

```bash
python3 tooling/farmkit/install.py plan --profile full
python3 tooling/farmkit/install.py install --profile full
python3 tooling/farmkit/install.py check --profile full
```

| Option | Use |
| --- | --- |
| `--profile core\|full` | Full default; core reduces extended components |
| `--prefix PATH` | Trusted prefix; repeat for install/check |
| `--skip-system` | Require already installed apt prerequisites |
| `--with-prowler` | Explicit optional Prowler package |
| `--with-legacy-pdf` | Optional wkhtmltopdf for old Nmap wrapper |

The wrapper maps `--plan` to plan, `--check` to check, otherwise install. `CPTC_PYTHON` selects its interpreter. The prefix contains `bin/`, `venvs/`, `src/`, native libraries, payloads, `activate` and `install-state.json`. `bin/cptc-report` forwards to the repository reporter. Do not move the repository/prefix afterward; paths are recorded. Select a group interpreter explicitly, such as `.cptc-suite/venvs/cip/bin/python`.

`check` is offline and verifies packages, recorded versions/source identities, hashes and notices. Setup never launches assessments, payloads or lab servers. Neither command proves operational readiness or creates an offline reinstallation cache.

On failure inspect the failed step in `install-state.json`. Correct temporary prerequisite/network issues and retry the same prefix/profile. Preserve modified sources or mismatched assets for investigation. Apt changes are system-wide and are not rolled back. See [installation and recovery](../tooling/farmkit/INSTALL.md).

## Farmkit metadata and packaging

`kit.py` uses the standard library, reads local metadata and never executes cataloged tools.

```powershell
python tooling/farmkit/kit.py validate
python tooling/farmkit/kit.py list --disposition selected
python tooling/farmkit/kit.py list --protocol modbus-tcp
python tooling/farmkit/kit.py readiness
python tooling/farmkit/kit.py verify --lock tooling/farmkit/examples/synthetic-lock.json --root tooling/farmkit/examples/artifacts
```

`validate` checks structure/cross-references. `list` uses exact protocol labels and dispositions `selected`, `conditional`, `lab`, `hold`. `verify --root DIR` checks local bytes against a lock; the example is synthetic. The default upstream inventory is empty/pending. `readiness` exposes acquisition, review and rehearsal gaps. Override records with `--catalog`, `--sources`, `--lock`, `--readiness`; all supplied record sets are validated before action.

Exit status: 0 action complete, 1 file failure, 2 invalid record, 3 pending inventory/readiness. Hash matching does not prove authenticity or suitability.

Create an output parent, then build the fixed source allowlist:

```powershell
New-Item -ItemType Directory -Force output
python tooling/farmkit/build.py output/farmkit-preparation.zip
```

The new ZIP contains module source and a size/hash manifest. Existing files are refused; output must be outside `tooling/farmkit/`. It omits root install.sh and sibling reporting code; use the complete repository for suite installation.

## Workbench

Prefix commands below with `python tooling/workbench/workbench.py`. Use `COMMAND --help` for syntax and the global `--version` flag for the application version. This offline tool handles synthetic records and curated completed-report JSON, with no target dispatch or cloud transfer.

```powershell
python tooling/workbench/workbench.py search modbus --protocol modbus
python tooling/workbench/workbench.py choose "analyze existing capture"
python tooling/workbench/workbench.py preflight output/workbench/session --require python
python tooling/workbench/workbench.py init output/workbench/session --owner "Training owner"
```

The authoritative workspace file is `state.json`. Commands print returned IDs/revisions. In the command index, `W`, `I`, `F`, `R`, `P`, `ID`, `REV`, `FILE`, `DEST` are placeholders: workspace, import, finding, run, plan, record ID, revision, JSON file and new destination. Replace them with returned values. They are not literal paths/identifiers.

### Discover and develop

| Command | Purpose / arguments |
| --- | --- |
| `search [QUERY]` | Filters `--platform`, `--runtime`, `--protocol`, `--privilege`, `--operation`, `--input`, `--output`, `--readiness`, `--disposition`; `--explain-excluded` |
| `choose TASK` | Find candidates for a task |
| `card TOOL_ID [--workspace W]` | Prerequisites, holds, ownership |
| `compare TOOL_ID...` | Compare consistent catalog fields |
| `platforms` | Declared/tested platform boundaries |
| `preflight DEST [--require NAME] [--platform windows\|linux] [--free-bytes N]` | Local checks; require repeats |
| `init DEST --owner NAME` | New workspace |
| `intake W FILE` | Capability/reuse/priority request |
| `decision W FILE` | Accepted/rejected/deferred/blocked decision |
| `owner W CAPABILITY --primary NAME --backup NAME --reviewer NAME` | Assign owner/backup/reviewer |
| `transfer W CAPABILITY --base REV --actor NAME [--new-owner NAME]` | Transfer/release assignment |
| `scaffold DEST --name NAME --owner NAME [--license MIT]` | General tool starter |
| `check-docs DIRECTORY` | Scaffold help/version consistency |
| `check-links [MARKDOWN_FILE...]` | Local links and catalog/runbook identifiers |
| `select-checks CHANGED_PATH...` | Suggestions only; executes no checks |

Scaffold names start with a lowercase letter and use lowercase letters, digits, underscores/hyphens. A generated starter returns 3/pending until implemented.

Request JSON fields: `problem`, `user`, `input`, `output`, `acceptance`, `owner`, `backup`, `reviewer`, `kind`; numeric estimates `value`, `frequency`, `confidence`, `effort`, `risk` each 1–5. Kinds: tool/adapter/repair/documentation/retirement. Optional `dependencies`, `reuse_query`. Priority is estimated, not measured. Decision JSON: `topic`, `owner`, `choice`, `reason`; deferred/blocked also need `benefit`, `trigger`.

### Notes, plans and outcomes

| Command | Purpose / arguments |
| --- | --- |
| `note W FILE` | Authored note object |
| `edit-note W ID FILE --base REV` | Revision-safe note patch |
| `show W COLLECTION ID` | Inspect record |
| `plan W FILE` | Record a manual command preview |
| `revalidate W P FILE --reviewer NAME [--accept-change]` | Check supplied scope/profile metadata |
| `deviation W P --reason TEXT --approval-ref REF --actor NAME` | Profile exception record |
| `run-record W --tool NAME --version V --operator NAME --status STATUS` | Operator-supplied synthetic outcome |
| `event W R --stage STAGE --status STATUS --code CODE [--exit-code N]` | Separate stage outcome |
| `simulate W [--seconds N]` | Fixed synthetic worker, 0.2–30 seconds |
| `cancel W R` | Stop synthetic worker; manual runs get external stop guidance |
| `resume W R --disposition repeat\|skip --actor NAME` | Record decision; no automatic execution |
| `handling W FILE` | Custodian/retention/export/deletion responsibilities |
| `metric W FILE` | Manually measured metrics |

Run-record also accepts `--exit-code`, `--stage tool\|import\|render`, `--profile`, `--binary-sha256`, `--config-sha256`, `--limitations`, `--scope-ref`, repeated `--evidence-ref`, `--plan-id`. Statuses: queued/running/success/partial/failed/cancelled/not_run. Success requires exit 0. Keep tool/import/render outcomes and limitations separate.

Plan JSON requires `command`, `scope_ref`, `profile`, `effects`, `limits`, `destination`; optional lists `targets`, `approved_targets`, `excluded_targets`, `discovered`. Commands are never executed and DNS is never resolved. Revalidation JSON contains exactly `scope_ref`, `profile`, `targets`, `approved_targets`, `excluded_targets`. Accepting metadata change cannot approve an excluded/outside target.

Handling JSON uses `custodian`, `retention`, `export`, `deletion` and performs no action. Metrics require `task`, `operator`, `environment`, with optional nonnegative `seconds`, `search_misses`, `retyping`, `duplicate_work`, `review_corrections`, `errors`. For a note, a simple input is `{"title":"Training shift","text":"Review F-001 before next snapshot"}`.

### Reports and review

```powershell
python tooling/workbench/workbench.py preview-import tooling/reporting/examples/report-marked.json
python tooling/workbench/workbench.py import-report output/workbench/session tooling/reporting/examples/report-marked.json
```

| Command | Purpose / arguments |
| --- | --- |
| `preview-import FILE` | Validate completed report and provenance |
| `import-report W FILE` | Preserve original and create candidates |
| `report-state W I` | Current report fingerprint, revision and IDs |
| `update-report W I FILE --base REV [--preview]` | Curated incremental update; [walkthrough](REPORT-UPDATES.md) |
| `prefill W I F` | Finding template, current report identity/revision |
| `author W I F FILE --base REV` | Complete finding replacement; preserve required evidence explicitly |
| `review W I F --decision accept\|reject --reason TEXT --reviewer NAME [--base REV]` | Human decision; use base to guard stale review |
| `duplicates W I` | Explainable suggestions; no automatic merge |
| `merge W I PRIMARY SECONDARY --actor NAME --reason TEXT` | Preserve originals in reversible merge history |
| `undo-merge W MERGE_ID --actor NAME` | Refuse overwriting later author changes |
| `complete W I [--rubric FIELD]` | Authorship/review/CVE gaps; rubric repeats |
| `retest W FILE` | Recommended/applied/verified remediation |
| `incident W FILE` | Incident actions; sends no message |
| `snapshot W I DEST [--pdf] [--docx] [--reviewer NAME] [--rubric FIELD]` | Immutable synchronized export |
| `integrity FILE SHA256` | Explicit local checksum check |

Import supports report schemas 1.0/1.1/1.2, not raw scanner formats or proposed tool-run envelopes. Exact-byte duplicate imports are no-ops. A separate import with conflicting finding IDs is rejected; use `update-report` to revise an existing import.

`author` replaces a whole finding; start from `prefill`'s `finding` object and retain all required evidence/markings. Prefer incremental updates for new evidence or selected-field edits. Stale authoring preserves a conflict for reconciliation. `--base` for author/update/review uses the **import record revision**; note editing/ownership transfer use their individual record revisions. Read current records before retrying.

Retest JSON: `finding`, `actor`, `summary`, `status` (recommended/applied/verified); verified requires nonempty `evidence[]`. Incident JSON: `run`, `actor`, `summary`; optional stop/containment/notification/cleanup default to pending. References are human-supplied, not proof of action.

Snapshots include authoritative input, Markdown, requested PDF/Word, changes, update receipts when applicable, and hashes. A new destination is always required. `--reviewer` requests the reviewed-training label after completeness checks; it does not approve official submission. Editing one rendered file does not update other formats.

### Status and delivery

| Command | Purpose / arguments |
| --- | --- |
| `status W [--destination DEST]` | Inspect or export status |
| `handoff W DEST --reviewer NAME [--import-id I]` | Preview neutral synthetic bundle |
| `handoff W DEST --reviewer NAME --approve-export [--import-id I]` | Create inspected bundle; no transfer |
| `review-packet W DEST EVIDENCE.json` | Source hashes and supplied verification |
| `package DEST` | Deterministic allowlisted source release |
| `compare-releases OLD.zip NEW.zip` | Compare member hashes |

Review-packet evidence must contain `"data_category":"synthetic"`. Handoff scrubs known secret forms; inspect content before manual use. No cloud API/local AI/automatic transfer is implemented. Keep prior reviewed releases for recovery into a new directory.

Workbench exits: 0 completed, 1 local/dependency failure, 2 rejected input, 3 conflict/pending/not-ready/mismatch. These are local outcomes, not event acceptance.

## Report generator

See the [input contract](../tooling/reporting/README.md) and [step-by-step update guide](REPORT-UPDATES.md).

| Argument | Use |
| --- | --- |
| `INPUT` | Complete UTF-8 synthetic report JSON; `-` reads stdin |
| `--preview` | Identity or update plan as JSON; writes nothing |
| `--update FILE` | Curated incremental update envelope |
| `--output-dir DIR` | New destination; required except preview |
| `--pdf`, `--docx` | Independent optional formats |
| `--release` | Reviewed-training label; requires review and confirmed findings/verified CVE applicability |
| `--version`, `--help` | Version/help |

Markdown uses the standard library. PDF/Word require local declared dependencies. Exports publish together after successful rendering; no partial bundle or overwrite. `input.json` is authoritative for subsequent revisions. Evidence paths are printed, never opened, and supplied evidence hashes are not verified. New content clears affected review rather than confirming claims. Exits: 0 success, 1 unexpected I/O/render/publish failure, 2 contract/destination/dependency/font rejection.

## Legacy compatibility

`python config.py` still creates `{"ranges":[],"hosts":[]}` JSON for compatible consumers such as the Windows runner's `-ConfigPath`. It can overwrite the selected file; preserve a copy. It validates ranges and IP/ASCII hostname syntax without DNS and does not grant scan authorization. Literal IP hosts must lie within any supplied ranges; host-only configurations remain possible. Invalid ranges, host bits/default routes, malformed/option-like hosts and malformed loaded JSON records are rejected. Validation precedes overwrite; read and save both expand home paths. Reading an explicit `~/` path or default home fallback now expands the home directory. A missing explicitly selected nondefault file fails instead of using unrelated scope; the default lookup still offers standalone interactive creation if no default/home file exists.

`super_nmap.py` is retired. `python super_nmap.py --help` displays the old option names and migration guidance; all non-help invocations exit 2 without a prompt, subprocess, config read/write or scan artifacts. Its old modes/custom arguments are never translated automatically. Use the [Linux](#linux-runner) or [Windows](#windows-runner) consolidated runner, supplying reviewed scope and options deliberately. The original wrapper is recoverable at baseline commit `78dc1388b2b2f83afb89f80f19187156491695f0` for historical inspection; it is not the supported execution path.

## Troubleshooting

| Symptom | Recovery |
| --- | --- |
| PowerShell shows `>>` or command never completes | Cancel incomplete input with Ctrl+C; run one complete line in PowerShell, without copied prompt/fence characters |
| Missing command/runtime | Run doctor/preflight and prepare documented dependencies |
| Nmap user override directory nonempty | Preserve overrides elsewhere; runners reject ambient `~/.nmap` or `%APPDATA%/nmap` contents |
| Scope/cap/public-address/DNS failure | Correct authorized scope/exclusions and inspect platform limits before changing explicit caps |
| Optional phase skipped | Check tool/template/wordlist and stage logs; skipped does not mean clean |
| Resume checksum mismatch | Preserve evidence/baseline; do not rewrite checksums to force reuse |
| Nuclei templates absent | Prepare through runner installation before offline operation |
| FullLanguage/RSAT/Npcap/privilege missing | Use an authorized supported workstation; inspect doctor |
| Suite hash/source mismatch | Preserve modified component and review identity before retry |
| Existing destination | Choose a new directory/file |
| Stale report SHA or revision | Read current state, reconcile intended changes, preview with updated base; [details](REPORT-UPDATES.md#conflicts-and-recovery) |
| Active workspace lock | Coordinate with writer; never remove an active lock |
| Abandoned `.write-lock` | Verify no writer remains and preserve workspace before operator recovery |
| Unsupported import | Supply completed synthetic report JSON or a curated update, not PCAP/XML/raw scanner output |
| PDF/Word dependency or font failure | Prepare declared dependencies/local font, then repeat passive export |
| Incomplete review | Use complete and address author/review/CVE gaps |
| Snapshot published but ledger write failed | Inspect bundle manifest/revision before reconciliation; do not repeat target activity |

Keep engagement evidence outside public source control. Preserve complete run/export bundles. See each module's verification document for platform and rehearsal limits.
