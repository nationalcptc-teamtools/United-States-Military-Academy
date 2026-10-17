#!/usr/bin/env python3
"""One-line individual CPTC tool preparation; use --help for commands."""
import runpy
import sys
from pathlib import Path

base = Path(__file__).resolve().parent / 'tooling/farmkit'
sys.path.insert(0, str(base))
runpy.run_path(str(base / 'onboard.py'), run_name='__main__')
