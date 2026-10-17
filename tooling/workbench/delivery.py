"""Allowlisted source packages and manual synthetic handoff; no upload client."""
from __future__ import annotations

import io
import ast
import re
import zipfile
from pathlib import Path

from common import ROOT, VERSION, bundle, digest, encoded, load, need, read, redact, text
import reports
import workspace as ws

MODULE_FILES = ("common.py", "catalog.py", "workspace.py", "operations.py", "reports.py", "delivery.py",
                "workbench.py", "README.md", "CONTRACTS.md", "HANDOVER.md", "UI-EVALUATION.md", "SPEC.md", "VERIFICATION.md", "LICENSE",
                "tests/test_workbench.py", "tests/test_report_updates.py")
REPORT_FILES = ("reportgen.py", "updates.py", "requirements.txt", "README.md", "design.md", "examples/report.json",
                "examples/report-marked.json", "examples/tool-run.json", "templates/report.md",
                "templates/finding.md", "templates/incident.md", "tests/test_reportgen.py", "tests/test_docx.py",
                "tests/check_pdf_rendering.py", "tests/check_markdown_rendering.py", "tests/test_updates.py",
                "examples/update-evidence.json")
GUIDE_FILES = ("docs/USER-GUIDE.md", "docs/REPORT-UPDATES.md", "docs/TOOL-GUIDES.md",
               "docs/assets/quick-start.svg", "docs/assets/report-update.svg", "docs/assets/tool-onboarding.svg",
               "tools.py", "docs/tool-onboarding/verification.md", "docs/tool-onboarding/spec.md",
               "docs/tool-onboarding/proposal.md", "docs/tool-onboarding/design.md", "docs/tool-onboarding/tasks.md",
               "docs/tool-onboarding/execution-guide.md", "docs/tool-onboarding/review.md")
FARM_FILES = ("catalog.json", "LICENSE", "NOTICES.md", "RUNBOOKS.md", "CATALOG.md", "README.md",
              "kit.py", "sources.json", "artifact-lock.json", "readiness.json", "INSTALL.md",
              "VERIFICATION.md", "install.py", "install-manifest.json", "spec.md", "design.md",
              "proposal.md", "build.py", "tests/test_kit.py", "tests/test_install.py",
    "onboard.py", "onboarding.json", "ONBOARDING.md", "syft-local.yaml", "tests/test_onboard.py", "requirements/reporting.in", "requirements/ot.in", "requirements/cip.in", "requirements/extended.in", "requirements/onboarding.in",
              "examples/synthetic-lock.json", "examples/run-statuses.json", "examples/artifacts/fixture.txt")


def package(destination):
    files = {}
    files["LICENSE"] = read(ROOT / "LICENSE")
    for name in GUIDE_FILES:
        files[name] = read(ROOT / name)
    for folder, names in (("workbench", MODULE_FILES), ("reporting", REPORT_FILES), ("farmkit", FARM_FILES)):
        for name in names:
            path = ROOT / "tooling" / folder / name
            files["tooling/" + folder + "/" + name] = read(path)
    manifest = {"version": VERSION, "kind": "source-only-preparation", "data_category": "synthetic",
                "notice": "No upstream tools, private workspace, client evidence or event approval",
                "files": {name: digest(raw) for name, raw in sorted(files.items())}}
    files["MANIFEST.json"] = encoded(manifest)
    output = io.BytesIO()
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name, raw in sorted(files.items()):
            info = zipfile.ZipInfo(name, (1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            archive.writestr(info, raw)
    raw = output.getvalue()
    filename = "workbench-" + VERSION + ".zip"
    hashes = bundle(destination, {filename: raw, "MANIFEST.json": encoded(manifest),
                                 filename + ".sha256": (digest(raw) + "  " + filename + "\n").encode()})
    return {"files": len(files), "zip_sha256": digest(raw), "artifacts": hashes,
            "published": False, "rollback": "Keep prior reviewed bundle; verify its manifest before restoring into a new directory"}


def inspect_package(path):
    raw = read(path)
    with zipfile.ZipFile(io.BytesIO(raw)) as archive:
        names = archive.namelist()
        need(len(names) == len(set(names)) and len(names) <= 100, "invalid_package_members")
        for info in archive.infolist():
            need(info.file_size <= 2_000_000 and not info.is_dir(), "package_member_limit")
        need("MANIFEST.json" in names, "package_manifest_missing")
        from common import load_bytes
        manifest = load_bytes(archive.read("MANIFEST.json"))
        need(set(names) == set(manifest["files"]) | {"MANIFEST.json"}, "package_members_mismatch")
        need(all(digest(archive.read(name)) == value for name, value in manifest["files"].items()), "package_hash_mismatch")
    return manifest


def compare_packages(first, second):
    before, after = inspect_package(first), inspect_package(second)
    left, right = before["files"], after["files"]
    return {"added": sorted(right.keys() - left.keys()), "removed": sorted(left.keys() - right.keys()),
            "changed": sorted(key for key in left.keys() & right.keys() if left[key] != right[key]),
            "review_focus": "Inspect changed interfaces, licenses, dependencies, behavior and examples; hashes alone do not accept a release"}


def scrub(value):
    if isinstance(value, dict):
        return {key: "[REDACTED]" if re.search(r"(?i)password|token|secret|api.?key|authorization", key)
                else scrub(item) for key, item in value.items()}
    if isinstance(value, list):
        return [scrub(item) for item in value]
    return redact(value) if isinstance(value, str) else value


def handoff(directory, destination, reviewer_name, approved=False, import_id=None):
    text(reviewer_name, 120)
    value = ws.state(directory)
    content = {"version": VERSION, "data_category": "synthetic", "purpose": "Manual cloud-system handoff; external processing is outside this application",
               "reviewer": reviewer_name, "workspace_revision": value["revision"],
               "status": ws.status_value(value), "handling": value["handling"], "markings": value["markings"],
               "automatic_transfer": False, "local_ai": False, "ai_correction": False,
               "redaction_note": "Known metadata/assignment patterns redacted; markings preserved; human inspection still required"}
    if import_id:
        need(import_id in value["imports"], "import_missing")
        item = value["imports"][import_id]
        content["report"] = item["report"]
        tags = (set(content["markings"]) | set(reports.reporter().handling(item["source_report"])["report"].split("//"))
                | set(reports.reporter().handling(item["report"])["report"].split("//")))
        if "PII Red" in tags:
            tags.discard("PII")
        content["markings"] = [tag for tag in reports.reporter().MARKINGS if tag in tags]
    content = scrub(content)
    raw = encoded(content)
    if not approved:
        return {"preview": True, "files": ["handoff.json", "handoff.md", "manifest.json"],
                "source_sha256": digest(raw), "markings": content["markings"], "written": False,
                "next_action": "Inspect synthetic content; explicitly approve export to create files"}
    lines = ["# Synthetic manual handoff", "", "Handling: " + "//".join(content["markings"]), "",
             "External cloud processing and final acceptance are separate human decisions.", "",
             "No local AI, AI correction, API request or automatic upload occurred.", "",
             "Review owner: " + reports.reporter().md(redact(reviewer_name)), "", "```json", raw.decode().replace("```", "[literal backticks]"), "```", ""]
    files = {"handoff.json": raw, "handoff.md": "\n".join(lines).encode()}
    files["manifest.json"] = encoded({"data_category": "synthetic", "markings": content["markings"],
                                     "artifacts": {name: digest(data) for name, data in files.items()},
                                     "automatic_transfer": False})
    return {"artifacts": bundle(destination, files), "transferred": False, "data_category": "synthetic"}


def review_packet(directory, destination, evidence_path):
    value = ws.state(directory)
    evidence = load(evidence_path)
    need(isinstance(evidence, dict) and evidence.get("data_category") == "synthetic", "synthetic_verification_record_required")
    content = scrub({"status": ws.status_value(value), "checks": evidence,
                     "source_hashes": {name: digest(read(ROOT / "tooling/workbench" / name)) for name in MODULE_FILES},
                     "limits": ["No target/client/cloud operation", "Inspect scope decisions and actual work; test totals alone are insufficient"]})
    return bundle(destination, {"review.json": encoded(content), "README.md": b"# Review packet\n\nSynthetic evidence only. Inspect current design, source and actual checks.\n"})


def scaffold(destination, name, owner, license_name="MIT"):
    need(re.fullmatch(r"[a-z][a-z0-9_-]{0,40}", name) is not None, "invalid_tool_name")
    for value in (owner, license_name):
        text(value, 120)
    metadata = {"name": name, "version": "0.1.0", "owner": owner, "license": license_name,
                "dependencies": [], "input": "Author must define", "output": "Author must define",
                "status_codes": {"0": "completed", "1": "local failure", "2": "invalid input", "3": "pending"},
                "contract_version": "0.1.0", "options": ["--input", "--version"]}
    script = '''"""Synthetic preparation tool skeleton. Author the actual behavior before use."""
import argparse
import json
from pathlib import Path

VERSION = "0.1.0"
EXIT_CODES = {"0": "completed", "1": "local failure", "2": "invalid input", "3": "pending"}

def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", action="version", version=VERSION)
    parser.add_argument("--input", help="future documented input; no file is read by the skeleton")
    parser.parse_args(argv)
    print("Pending: implement the tool and document its input/output contract.")
    return 3

if __name__ == "__main__":
    raise SystemExit(main())
'''
    helpers = '''"""Small reusable identity/time/hash helpers; no tool-output envelope."""
from datetime import datetime, timezone
from hashlib import sha256
from uuid import uuid4
def new_id(): return uuid4().hex
def timestamp(): return datetime.now(timezone.utc).isoformat()
def checksum(raw): return sha256(raw).hexdigest()
'''
    guide = f"# {name}\n\nOwner: {reports.reporter().md(owner)}\n\nLicense: {reports.reporter().md(license_name)}\n\nVersion: 0.1.0\n\nOptions: --input (future documented input), --version (declared version), --help (usage).\n\nDefine purpose, validated inputs, outputs, prerequisites, effects, errors, stop/recovery and reporting handoff before use.\n\nStatus codes: 0 completed; 1 local failure; 2 invalid input; 3 pending.\n\nThe skeleton performs no acquisition or target action. It is intentionally pending until implemented.\n"
    return bundle(destination, {"tool.py": script.encode(), "helpers.py": helpers.encode(),
                                "METADATA.json": encoded(metadata), "RUNBOOK.md": guide.encode()})


def check_scaffold(directory):
    metadata = load(Path(directory) / "METADATA.json")
    code = read(Path(directory) / "tool.py").decode("utf-8")
    guide = read(Path(directory) / "RUNBOOK.md").decode("utf-8")
    version = metadata.get("version")
    syntax = ast.parse(code)
    declarations = {node.targets[0].id: ast.literal_eval(node.value) for node in syntax.body
                    if isinstance(node, ast.Assign) and len(node.targets) == 1
                    and isinstance(node.targets[0], ast.Name) and node.targets[0].id in ("VERSION", "EXIT_CODES")}
    options = sorted(node.args[0].value for node in ast.walk(syntax) if isinstance(node, ast.Call)
                     and isinstance(node.func, ast.Attribute) and node.func.attr == "add_argument"
                     and node.args and isinstance(node.args[0], ast.Constant) and isinstance(node.args[0].value, str))
    checks = {"version": bool(version and declarations.get("VERSION") == version and "Version: " + version in guide),
              "declared_status_codes": declarations.get("EXIT_CODES") == metadata.get("status_codes"),
              "declared_options": options == sorted(metadata.get("options", [])),
              "runbook_options": all(option in guide for option in metadata.get("options", []))}
    return {"consistent": all(checks.values()), "checks": checks, "executed": False,
            "limits": "Declarations/help options only; no claim that every tool behavior is verified"}


def check_links(paths=()):
    from urllib.parse import unquote
    import catalog
    def slug(value):
        value = re.sub(r"[^\w\s-]", "", value.strip().lower())
        return re.sub(r"\s", "-", value)
    def valid(base, target):
        file_part, _, fragment = unquote(target).partition("#")
        target_path = (base.parent / file_part) if file_part else base
        if not target_path.is_file():
            return False
        if fragment and target_path.suffix.lower() == ".md":
            content = read(target_path).decode("utf-8")
            anchors = {slug(match.group(1)) for match in re.finditer(r"(?m)^#{1,6}\s+(.+)$", content)}
            return fragment.lower() in anchors
        return True
    files = [Path(path) for path in paths] if paths else list((ROOT / "tooling/workbench").glob("*.md"))
    issues, count = [], 0
    for path in files:
        for index, target in enumerate(re.findall(r"\[[^\]]+\]\(([^)]+)\)", read(path).decode("utf-8"))):
            if re.match(r"^[A-Za-z][A-Za-z0-9+.-]*://", target):
                continue
            count += 1
            if not valid(path, target):
                issues.append({"file": path.name, "reference": index, "code": "local_link_missing"})
    rows = catalog.tools()[:40]
    ids = {row["id"] for row in rows}
    for row in rows:
        count += 1
        if not valid(ROOT / "tooling/farmkit/catalog.json", row["runbook"]):
            issues.append({"tool": row["id"], "code": "runbook_link_missing"})
    need(ids == {f"TOOL-{i:03d}" for i in range(1, 41)}, "catalog_id_mismatch")
    return {"consistent": not issues, "references": count, "issues": issues, "network_used": False}
