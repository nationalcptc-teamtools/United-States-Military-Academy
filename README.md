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
