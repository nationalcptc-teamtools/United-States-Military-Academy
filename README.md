the last commit to this repo will be NLT 16OCT.
# cptc-tools
CPTC Globals tooling for C3T.

From CPTC ROE:
"The Operations Team must be provided a request for access to or the creation of a repository for
approval prior to the competition. The submission deadline will be a minimum of two (2) weeks
prior to any CPTC event."

# Config Wizard (config.py)

A wizard to help you set the IP address ranges and hosts in scope for the competition. This will generate a config file that can be used by the other tools.

# Installation Script (install.sh)

A script to install all the packages needed for the tools to run. This script is intended to be run on a fresh install of Kali Linux.

Installs:
- prowler

# Super Nmap (super_nmap.py)

 A wrapper for nmap that automatically converts the output to pdf/xml and caches hosts in the config file for more scans.

```
usage: Usage: super_nmap.py [options]

A wrapper for nmap that automatically converts the output to html and caches hosts in the config file for more scans

options:
  -h, --help            show this help message and exit
  -C CONFIG, --config CONFIG
                        The config file to use
  -s {ping,port,fast,full,udp,custom}, --scan-type {ping,port,fast,full,udp,custom,vulscan}
                        Scan type
  -H, --hosts-only      Only scan hosts, not ranges
  -o OUTPUT, --output OUTPUT
                        Output directory
  -c CUSTOM_ARGS, --custom-args CUSTOM_ARGS
                        Custom arguments to pass to nmap
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
