from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
module = root / 'tooling/farmkit'
repo = root / 'integrations/United-States-Military-Academy'

readme = (module / 'README.md').read_text(encoding='utf-8')
readme = readme.replace('Version 1.0.0, 2026-10-15.', 'Version 1.1.0, 2026-10-15.')
readme = readme.replace('**Selected means selected for evaluation. No upstream software is included, acquired, installed or runtime accepted.**', '**Selected means selected for evaluation. Upstream software is not vendored here; the separate installer acquires supported assessment components. Installation and operational acceptance are distinct.**')
readme = readme.replace('## Selection', '## Install from the repository\n\nSee [INSTALL.md](INSTALL.md) for the complete suite, platform requirements, optional lab systems and recovery. From the repository root on Kali:\n\n```sh\nbash install.sh --plan\nbash install.sh --profile full\nsource .cptc-suite/activate\nbash install.sh --check --profile full\n```\n\nThe installer uses the network during preparation, records resolved versions and never launches an assessment tool, payload or lab server. [Verification evidence](VERIFICATION.md), [proposal](proposal.md), [specification](spec.md) and [design](design.md) distinguish actual installation checks from pending runtime/event acceptance.\n\n## Selection')
readme = readme.replace('Current reporting v0.2.0 accepts completed report schemas 1.0/1.1;', 'The reporting base accepts completed report schemas 1.0/1.1;')
readme = readme.replace('Exact Kali/Windows images, hardware, clean-image offline installation, host enumeration, selected protocol queries, traffic captures, measured stop behavior and resource footprint are all **not run**.', 'The online Kali assessment installation and disconnected installation check are recorded in VERIFICATION.md. Fresh offline reinstallation, Windows execution, hardware, host enumeration, selected protocol queries, traffic captures, measured stop behavior and full resource footprint remain **not run**.')
readme = readme.replace('No selected item is promoted to staged or runtime passed by this release.', 'The historical readiness ledger is not automatically promoted by installation on a separate test workstation; no selected operation is marked runtime passed.')
readme = readme.replace('farmkit-1.0.0.zip', 'farmkit-1.1.0.zip').replace('It includes exactly 15 allowlisted module files', 'It includes exactly the files allowlisted in build.py')
(module / 'README.md').write_text(readme, encoding='utf-8', newline='\n')
p = module / 'kit.py'
p.write_text(p.read_text(encoding='utf-8').replace('VERSION = "1.0.0"', 'VERSION = "1.1.0"'), encoding='utf-8', newline='\n')
p = module / 'build.py'
p.write_text(p.read_text(encoding='utf-8').replace('"examples/artifacts/fixture.txt", "tests/test_kit.py",', '"examples/artifacts/fixture.txt", "tests/test_kit.py", "tests/test_install.py",\n    "install.py", "install-manifest.json", "INSTALL.md", "VERIFICATION.md",\n    "proposal.md", "spec.md", "design.md",'), encoding='utf-8', newline='\n')

private_spec = (root / 'docs/proposals/farm-toolkit/spec.md').read_text(encoding='utf-8')
functional = private_spec.split('| ID | Required outcome | Observable acceptance criterion |')[1].split('## Quality constraints')[0]
quality = private_spec.split('| ID | Constraint | Observable acceptance criterion |')[1].split('##')[0]
extension = private_spec.split('| ID | Required outcome | Observable acceptance |')[1].split('\n\n')[0]
public_spec = '''# Farming toolkit specification

Stable requirements for proposal `farm-toolkit`, v1.1.0, 2026-10-15. Original Analyst IDs remain unchanged. This public extract excludes private customer/planning context. All agriculture scenarios are hypotheses.

Baseline: config/Nmap orchestration and exports already exist; reporting PR #1 supplies the passive normalized-JSON reporter. The former installer used moving Vulscan and optional global pip. The desired result adds a researched catalog, integrity/readiness contracts and a separate easy assessment installer. No asset inventory or event-specific permission is available.

## Functional acceptance

| ID | Required outcome | Observable acceptance criterion |'''+functional+'''## Quality acceptance

| ID | Constraint | Observable acceptance criterion |'''+quality+'''## Authorized installer/publication extension

The requester authorized commit/PR and selected the assessment suite by default, with lab servers optional.

| ID | Required outcome | Observable acceptance |'''+extension+'''

## Boundaries, evidence and remaining decisions

Canonical evidence appears per tool in [CATALOG.md](CATALOG.md), source/asset evidence in [sources.json](sources.json) and [install-manifest.json](install-manifest.json), actual results in [VERIFICATION.md](VERIFICATION.md). The [October 2025 rules](https://cp.tc/docs/cptc-rules.pdf) are the requested working rulebook baseline. Current package candidates are researched in October 2026; historical availability in October 2025 is not asserted.

Preserved decisions: OD-FT-01 actual event/start/timezone/SOW; OD-FT-02 assigned repository/eligible student owner/frozen revision (publication authorized, event approval separate); OD-FT-03 exact team OS/Windows/.NET/resources; OD-FT-04 permitted acquisition/staging/snapshots; OD-FT-05 artifact/dependency/license and output-integration review; OD-FT-06 actual in-scope protocols and allowed reads; OD-FT-07 lab/hardware/rehearsal owner; OD-FT-08 provisional eight core routes, package budget and future adapter funding. Captain/runtime/license owners must resolve their respective gates. README NLT 16OCT lacks year/event/timezone, so deadlines cannot be derived from it.

Reversible assumptions: Kali x86-64 plus separate Windows x64 payload destination; offline operation after online acquisition; broad protocol candidates rather than all forty auto-installed; only synthetic preparation data. No real-farm reconnaissance, controller writes/logic/firmware/start-stop, injection/RF, credential attacks or operational testing is included. Legacy scanner timing/exit/parsing defects are static observations and remain separate work. Setup does not repair scanner behavior.

Missing scope means no target activity. Missing artifacts, changed bytes, failed dependencies, redirected paths, wrong source commits and command failures must fail explicitly. Partial/timeout/authentication/unsupported/empty outcomes remain distinct. No hardware means not run, never inferred compatible. Full FR-FT-006 offline dependency closure and FR-FT-005/010 operational rehearsals remain acceptance gaps despite successful software installation. See [design](design.md) for mappings and [runbooks](RUNBOOKS.md) for bounded operations.
'''
(module / 'spec.md').write_text(public_spec, encoding='utf-8', newline='\n')

install_section = '''# Installation Script (install.sh)

Install the supported assessment suite on Kali Linux x86-64. Setup acquires packages during preparation; the installed workstation can then be checked without Internet. Lab servers are optional and separately documented.

```sh
git clone https://github.com/nationalcptc-teamtools/United-States-Military-Academy.git
cd United-States-Military-Academy
bash install.sh --plan
bash install.sh --profile full
source .cptc-suite/activate
bash install.sh --check --profile full
```

Includes protocol/IT clients, isolated Python libraries, source-built OT clients/SDKs, reporting dependencies and hash-checked LinPEAS/WinPEAS downloads. Setup never runs payloads, assessment tools or lab servers. Use `--profile core` for the smaller selected-protocol profile; Prowler and legacy wkhtmltopdf are explicit options. All forty candidates have installation or held/lab dispositions.

Read [installation and offline-use guidance](tooling/farmkit/INSTALL.md), [the catalog](tooling/farmkit/CATALOG.md) and [actual checks and limitations](tooling/farmkit/VERIFICATION.md). No full offline reinstallation cache or operational/event approval is claimed. The [proposal/spec/design](tooling/farmkit/proposal.md) record requirements, source evidence and unresolved gates. Existing scanner/configuration behavior is preserved; its general Nmap defaults are not approved OT profiles.

'''
p = repo / 'README.md'
current = p.read_text(encoding='utf-8')
current = re.sub(r'# Installation Script \(install.sh\).*?(?=# Super Nmap)', lambda m: install_section, current, flags=re.S)
p.write_text(current, encoding='utf-8', newline='\n')
# Only our README hunk will be staged; preserve the independent reporting edits.
(root / 'tmp/farm-readme-section.txt').write_text(install_section, encoding='utf-8', newline='\n')

with (repo / '.gitignore').open('a', encoding='utf-8', newline='\n') as handle:
    handle.write('\n# Local assessment installation and legacy source link\n/.cptc-suite/\n/vulscan\n')
(repo / '.gitattributes').write_text('/install.sh text eol=lf\n/tooling/farmkit/*.py text eol=lf\n/tooling/farmkit/*.json text eol=lf\n/tooling/farmkit/*.md text eol=lf\n/tooling/farmkit/tests/*.py text eol=lf\n', encoding='utf-8', newline='\n')
workflow = repo / '.github/workflows/farmkit.yml'
workflow.parent.mkdir(parents=True, exist_ok=True)
workflow.write_text('''name: Farm toolkit contracts
on:
  push:
    paths: ['tooling/farmkit/**', 'install.sh', '.github/workflows/farmkit.yml']
  pull_request:
    paths: ['tooling/farmkit/**', 'install.sh', '.github/workflows/farmkit.yml']
permissions:
  contents: read
jobs:
  contracts:
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest]
        python: ['3.10', '3.12']
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python }}
      - run: python -B -m unittest discover -s tooling/farmkit/tests -v
      - run: python -B tooling/farmkit/kit.py validate
      - run: python -B tooling/farmkit/install.py plan
''', encoding='utf-8', newline='\n')
