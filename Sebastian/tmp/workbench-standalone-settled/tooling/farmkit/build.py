#!/usr/bin/env python3
"""Build the fixed, team-authored preparation package. No upstream payloads."""

import argparse
import hashlib
import io
import json
import sys
import zipfile
from pathlib import Path

import kit

FILES = (
    "LICENSE", "README.md", "CATALOG.md", "RUNBOOKS.md", "NOTICES.md",
    "kit.py", "build.py", "catalog.json", "sources.json", "artifact-lock.json",
    "readiness.json", "examples/synthetic-lock.json", "examples/run-statuses.json",
    "examples/artifacts/fixture.txt", "tests/test_kit.py", "tests/test_install.py",
    "install.py", "install-manifest.json", "INSTALL.md", "VERIFICATION.md",
    "proposal.md", "spec.md", "design.md",
)


def build(destination):
    destination = Path(destination).absolute()
    kit.need(not destination.resolve().is_relative_to(kit.BASE), "package", "output must be outside source directory")
    payloads = {}
    for relative in sorted(FILES):
        path = kit.regular_path(kit.BASE, relative)
        with path.open("rb") as source:
            raw = source.read(kit.MAX_JSON + 1)
        kit.need(len(raw) <= kit.MAX_JSON, "package", "source file exceeds package bound")
        payloads["tooling/farmkit/" + relative] = raw
    manifest = {"package_version": kit.VERSION, "kind": "team-authored-preparation-only",
                "upstream_software_included": False,
                "files": {name: {"size": len(raw), "sha256": hashlib.sha256(raw).hexdigest()}
                          for name, raw in payloads.items()}}
    payloads["MANIFEST.json"] = (json.dumps(manifest, indent=2, sort_keys=True) + "\n").encode("utf-8")
    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name, raw in sorted(payloads.items()):
            info = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            archive.writestr(info, raw)
    raw = buffer.getvalue()
    with destination.open("xb") as target:
        target.write(raw)
    return hashlib.sha256(raw).hexdigest()


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path, help="New ZIP path outside source directory; parent must exist")
    args = parser.parse_args(argv)
    try:
        digest = build(args.output)
        print(f"Built preparation-only package: {len(FILES)} files plus MANIFEST.json; SHA-256 {digest}")
        return 0
    except kit.Invalid as exc:
        print(f"Invalid package request: {exc}", file=sys.stderr)
        return 2
    except OSError:
        print("Package file operation failed; existing output is never overwritten.", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
