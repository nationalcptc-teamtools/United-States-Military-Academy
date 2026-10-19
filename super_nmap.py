#!/usr/bin/env python3
"""Retired legacy entrypoint. Never execute or translate assessment arguments."""
import argparse
import sys

MIGRATION = (
    "super_nmap.py is retired and performed no scan. Use cptc-linux.sh or "
    "cptc-windows.ps1 with explicitly reviewed scope and options; see "
    "docs/USER-GUIDE.md#legacy-compatibility. Legacy arguments are not "
    "translated. config.py remains available to create compatible JSON."
)

def main(argv=None):
    parser = argparse.ArgumentParser(
        prog='super_nmap.py', description=MIGRATION,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('-C', '--config', default='./config.json')
    parser.add_argument('-s', '--scan-type', choices=[
        'ping', 'port', 'fast', 'full', 'udp', 'custom', 'vulscan'], default='custom')
    parser.add_argument('-H', '--hosts-only', action='store_true')
    parser.add_argument('-o', '--output', default='.')
    parser.add_argument('-c', '--custom-args', default='')
    parser.parse_args(argv)
    print(MIGRATION, file=sys.stderr)
    return 2

if __name__ == '__main__':
    raise SystemExit(main())
