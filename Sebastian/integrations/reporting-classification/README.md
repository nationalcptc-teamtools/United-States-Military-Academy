# CPTC tools

Competition enumeration runners for Linux and Windows. **The last commit to this repository must be made no later than 19 October.** Install and test a known-good tool set before that cutoff. The [official CPTC rules](https://cp.tc/docs/cptc-rules.pdf) require pre-staged code to use the CPTC-managed public repository and prohibit repository changes during the week before the event.

These scripts are for systems listed in the competition ROE. They require explicit scope, cap target expansion, keep follow-up checks tied to discovered in-scope addresses, and do not automate exploitation, password spraying, or credential brute force.

## Entrypoints

- `cptc-linux.sh`: Bash 5 runner for Kali, Debian, and Ubuntu.
- `cptc-windows.ps1`: Windows PowerShell 5.1 runner.

Both scripts install or locate tools, check the workstation, enumerate a supplied scope, retain raw evidence, and build a report. The older `config.py`, `install.sh`, and `super_nmap.py` remain available for compatibility.

[Nmap searches per-user directories when a requested data file is absent](https://nmap.org/book/data-files-replacing-data-files.html). The runners bind Nmap to a hashed, complete data tree and refuse nonempty per-user Nmap override directories such as `~/.nmap` or `%APPDATA%\nmap`; move intentional overrides aside before a competition run.

## Scope files

Use one IP, CIDR, or hostname per line. Blank lines and comments are allowed.

```text
# scope.txt
10.10.10.0/24
10.10.20.15
app.corp.example
```

Keep exclusions in a separate file:

```text
# exclude.txt
10.10.10.1
10.10.10.128/27
```


# Offline report generator (tooling/reporting)

The [reporting starter](tooling/reporting/README.md) converts synthetic normalized finding JSON into editable Markdown, optional PDF, and a provenance hash manifest. It supplements the Nmap scan exports with structured observations, business impact, remediation, retest steps, and explicit candidate/review status.

It is passive and offline: no scanning, evidence-file access, CVE lookup, AI, or publication. Version 0.3.0 accepts synthetic inputs only, with a cover, contents, numbered sections and evidence/review appendices. Schemas 1.0/1.1 remain supported; schema 1.2 adds structured ORCON/PROPIN/PII/PII Red/FI inheritance and combined markings on every PDF page. Business severity remains supplied, with no severity matrix configured. Existing scanner/configuration tools and their installation remain unchanged.

The [intake design](tooling/reporting/design.md) maps forty proposed farm-toolkit candidates and Nmap XML to future native adapters, helper output contracts or held/reference-only routes. Direct tool imports and approved client-data handling remain future work; current commands accept completed report JSON.

Requires Python 3.10+; PDF additionally uses the dependency declared in tooling/reporting/requirements.txt. See the module README for optional PDF installation, full input contract, and rendering QA.

```sh
python3 tooling/reporting/reportgen.py tooling/reporting/examples/report-marked.json --output-dir output/report-demo
python3 -m unittest discover -s tooling/reporting/tests -v
```

Use a new output directory for every export. Generated reports and engagement evidence belong outside public source control.
Copy the scope from the event documentation. Do not derive it from the local default route.

Hostnames are resolved once when a run starts. Both runners preserve each frozen hostname-to-IP mapping for virtual-host probes, setting HTTP Host and TLS SNI while pinning the connection to the authorized IP. Windows currently expands IPv4 addresses only; Linux supports IPv4 and IPv6.

## Linux

Install the core and optional packages available from the configured apt repositories:

```bash
chmod +x ./cptc-linux.sh
./cptc-linux.sh install --all --yes
./cptc-linux.sh doctor
```

The installer invokes `sudo` only for apt and downloads Nuclei templates for the invoking user. This avoids a first-run template download during the competition.

Run the standard competition profile:

```bash
sudo ./cptc-linux.sh run \
  --scope ./scope.txt \
  --exclude ./exclude.txt \
  --authorized \
  --profile standard \
  --udp \
  --domain corp.example \
  --label day-1
```

The standard profile performs discovery and a top-1,000 TCP pass across the full scope, then scans all TCP ports on hosts found by discovery or the first port pass. `quick` skips the full 1–65,535 TCP pass but still performs service and protocol follow-ups. `deep` scans all TCP ports across the complete scope. `--udp` adds a bounded top-20, top-100, or top-250 UDP pass based on the profile.

Web content discovery and vulnerability templates are separate switches because they are noisier and can take much longer:

```bash
sudo ./cptc-linux.sh run \
  --scope ./scope.txt \
  --authorized \
  --profile deep \
  --active-web \
  --enable-vuln-scans
```

Use those switches only when the event ROE permits them. The vulnerability phase uses a small explicit NSE set, runs Nuclei with intrusive, fuzzing, DoS, brute-force, default-login, and headless tags excluded, and performs offline SearchSploit correlation when those tools are installed.

Resume a stopped run or regenerate its report:

```bash
sudo ./cptc-linux.sh resume ./artifacts/20261014T180000Z-day-1 --authorized
sudo ./cptc-linux.sh report ./artifacts/20261014T180000Z-day-1
```

Resume reuses the original frozen scope and scan selections. It verifies the immutable settings, frozen scope, and complete inventory of covered `scope/`, `raw/`, `targets/`, and `reports/` evidence before accepting checkpoints; altered evidence is refused, while an interrupted run without a final artifact manifest rebuilds its phases. Rate, retry, timeout, concurrency, and follow-up limits may be adjusted. If the original run used `--snmp-community-file`, supply that option again on resume.

Linux results are written beneath `artifacts/<UTC timestamp>-<label>/`:

- `logs/run.log`: full console transcript.
- `logs/commands.sanitized.sh`: shell-escaped scanner and follow-up command journal with configured SNMP communities redacted.
- `logs/events.tsv` and `logs/errors.tsv`: status, exit code, duration, and raw-log path.
- `raw/`: Nmap output in all formats plus a combined-output log for each scanner or follow-up command.
- `scope/`: frozen normalized scope, DNS resolution map, and hashes.
- `targets/`: parsed host, service, and protocol-specific target lists.
- `reports/`: Markdown, HTML, CSV, JSON, Nmap HTML, and SHA-256 manifests.

Run `./cptc-linux.sh help` for all rate, timeout, phase, interface, scope-cap, and SNMP options.

## Windows

Open Windows PowerShell 5.1 in FullLanguage mode. Administrator rights plus Npcap enable SYN, UDP, and OS detection; the runner falls back to TCP connect scans without them.

Install the tools and inspect the workstation:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
./cptc-windows.ps1 -Action Install -InstallTool Nmap,httpx,nuclei,ffuf -Verbose
./cptc-windows.ps1 -Action Doctor -TargetsFile ./scope.txt -Verbose
```

The GitHub release installers verify publisher checksum manifests before extracting `httpx`, Nuclei, and ffuf. Nuclei templates are downloaded during installation and used offline during runs. The WinGet `Insecure.Nmap` package can lag the current Nmap release; the script reports that caveat. Before the event, compare `nmap --version` with the current installer at <https://nmap.org/download.html> and install the current Nmap plus Npcap if needed.

Run scoped enumeration:

```powershell
./cptc-windows.ps1 `
  -Action Run `
  -TargetsFile ./scope.txt `
  -Exclude 10.10.10.1 `
  -Profile Standard `
  -EnableUdp `
  -EnableNuclei `
  -AcknowledgeScope `
  -Verbose
```

PowerShell also accepts one or more values through `-Target` (for example, `-Target 10.0.0.1,10.0.0.2`) or the legacy JSON from `config.py` through `-ConfigPath ./config.json`. Windows scope expansion is IPv4-only, is capped at 4,096 addresses by default, and rejects non-private addresses unless `-AllowPublicTargets` is supplied explicitly.

`Quick` scans Nmap's fast TCP set, `Standard` scans the top 1,000 TCP ports, and `Deep` scans all TCP ports. Optional UDP coverage is top 20, 50, or 100 ports. Every profile follows discovered ports with version detection and an explicit service-enumeration NSE list.

Useful optional phases:

```powershell
# ffuf requires an operator-selected wordlist; the runner freezes and hashes a run-owned copy.
./cptc-windows.ps1 -Action Run -TargetsFile ./scope.txt `
  -Profile Deep -EnableFfuf -Wordlist C:/SecLists/Discovery/Web-Content/raft-small-words.txt `
  -AcknowledgeScope -Verbose

# Read-only domain metadata with the current domain identity and RSAT, when present.
./cptc-windows.ps1 -Action Run -TargetsFile ./scope.txt `
  -EnableAd -AuthorizedAdDomain corp.example -AcknowledgeAdDomain `
  -AcknowledgeScope -Verbose
```

Resume only with the same scope and profile. The runner verifies the prior evidence manifest, frozen scope, resolution map, and successful Nmap XML before accepting a checkpoint. A missing checksum baseline disables checkpoint reuse, a checksum mismatch refuses the resume, and missing or unsuccessful Nmap XML reruns the affected scan:

```powershell
./cptc-windows.ps1 -Action Run -Resume `
  -RunDirectory ./cptc-results/20261014T180000Z_TEAM_ab12cd34 `
  -Profile Standard -AcknowledgeScope -Verbose

./cptc-windows.ps1 -Action Report `
  -RunDirectory ./cptc-results/20261014T180000Z_TEAM_ab12cd34
```

Windows results are written beneath `cptc-results/<UTC timestamp>_<host>_<id>/`:

- `logs/`: PowerShell transcript, runner log, JSONL command events, and separate stdout/stderr files.
- `raw/`: Nmap, web, local workstation, and optional AD evidence.
- `scope/`: normalized target and URL lists plus the resolution map.
- `normalized/`: host, service, web, and Nuclei CSV/JSON summaries.
- `report/index.html`: HTML-encoded report.
- `run-manifest.json` and `SHA256SUMS.txt`: parameters, tool hashes, stage status, and evidence hashes.

Verbose command logs are intentionally complete and can grow large during deep scans. Archive the whole run directory so the report, raw evidence, command events, provenance, and checksums stay together.

## Suggested competition flow

1. Run each installer now, run `doctor`, and keep the resulting tool directories unchanged through the event.
2. Test both scripts against a small lab scope and review the raw commands and reports.
3. Start the event with `quick` or `standard` to build the service map.
4. Use `deep`, UDP, web content discovery, Nuclei, and AD collection on prioritized systems as time and the ROE allow.
5. Preserve the complete run directory when handing evidence to the reporting team.

Enumeration output can contain sensitive network and domain data. Generated results and downloaded tool directories are excluded by `.gitignore`.

## Legacy tools

- `config.py` interactively writes the original `{"ranges": [], "hosts": []}` JSON format.
- `super_nmap.py` is the original Nmap wrapper.
- `install.sh` is the original minimal Kali installer.

The consolidated Linux and Windows runners are the recommended entrypoints.

## Offline report generation

The [reporting module](tooling/reporting/README.md) exports structured synthetic findings as Markdown, optional PDF and editable Word, with inherited handling markings and a hash manifest. Use a new output directory for each export:

```sh
python3 tooling/reporting/reportgen.py tooling/reporting/examples/report-marked.json --output-dir output/report-demo --pdf --docx
```

PDF and Word dependencies are declared in tooling/reporting/requirements.txt. The reporting module does not run the enumeration tools or open evidence references.
