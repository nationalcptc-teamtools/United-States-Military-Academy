#!/usr/bin/env python3
"""Offline preparation records and local artifact integrity checks. No tool runner."""

import argparse
import hashlib
import json
import re
import stat
import sys
from datetime import date
from pathlib import Path
from urllib.parse import urlsplit

VERSION = "1.1.0"
BASE = Path(__file__).resolve().parent
MAX_JSON = 2_000_000
MAX_ARTIFACT = 512 * 1024 * 1024
TOOL_IDS = {f"TOOL-{i:03d}" for i in range(1, 41)}
GATE_IDS = {f"OD-FT-{i:02d}" for i in range(1, 9)}
REHEARSALS = {"clean-kali", "linux-host", "windows-host", "offline-pcap",
              "modbus", "s7", "cip", "opcua", "bacnet", "mqtt", "resources"}


class Invalid(ValueError):
    pass


def need(ok, where, reason):
    if not ok:
        raise Invalid(f"{where}: {reason}")


def obj(value, fields, where):
    need(isinstance(value, dict) and set(value) == set(fields.split()),
         where, "unexpected or missing fields")


def string(value, where, maximum=6000):
    need(isinstance(value, str) and 0 < len(value) <= maximum,
         where, "expected bounded nonempty text")
    need(not any(ord(c) < 32 or 127 <= ord(c) < 160 for c in value),
         where, "control characters rejected")
    need(not any(0xD800 <= ord(c) <= 0xDFFF for c in value),
         where, "unpaired Unicode surrogate rejected")


def strings(value, where, empty=False):
    need(isinstance(value, list) and (empty or bool(value)) and len(value) <= 256,
         where, "expected bounded text list")
    for item in value:
        string(item, where)
    need(len(set(value)) == len(value), where, "duplicate list entries")


def iso_date(value, where):
    string(value, where, 10)
    try:
        need(date.fromisoformat(value).isoformat() == value, where, "invalid date")
    except ValueError:
        raise Invalid(f"{where}: invalid date") from None


def url(value, where):
    string(value, where, 1000)
    try:
        u = urlsplit(value)
        need(u.scheme == "https" and bool(u.hostname) and u.username is None
             and u.password is None and u.port in (None, 443), where, "expected public HTTPS reference")
        need(not any(c.isspace() for c in value), where, "whitespace in reference")
    except ValueError:
        raise Invalid(f"{where}: invalid reference") from None


def safe_path(value, where):
    string(value, where, 240)
    parts = value.split("/")
    need(not any(c in value for c in "\\:<>\"|?*%") and not value.startswith("/"),
         where, "unsafe relative path")
    for part in parts:
        stem = part.split(".")[0].upper()
        need(part not in ("", ".", "..") and not part.endswith((" ", ".")),
             where, "unsafe path component")
        need(stem not in {"CON", "PRN", "AUX", "NUL", *[f"COM{i}" for i in range(1, 10)],
                          *[f"LPT{i}" for i in range(1, 10)]}, where, "reserved path component")
    return parts


def no_duplicates(pairs):
    out = {}
    for key, value in pairs:
        need(key not in out, "json", "duplicate key")
        out[key] = value
    return out


def load(path):
    need("\x00" not in str(path), "input.path", "NUL path rejected")
    with Path(path).open("rb") as handle:
        raw = handle.read(MAX_JSON + 1)
    need(len(raw) <= MAX_JSON, "json", "input too large")
    try:
        data = json.loads(raw.decode("utf-8"), object_pairs_hook=no_duplicates,
                          parse_constant=lambda _: (_ for _ in ()).throw(Invalid("json: nonfinite number")))
        stack = [(data, 0)]
        while stack:
            value, depth = stack.pop()
            need(depth <= 32, "json", "nesting limit exceeded")
            children = value.values() if isinstance(value, dict) else value if isinstance(value, list) else ()
            stack.extend((child, depth + 1) for child in children)
        return data
    except Invalid:
        raise
    except (ValueError, RecursionError, UnicodeError):
        raise Invalid("json: invalid UTF-8 or JSON") from None


def catalog(data):
    obj(data, "schema_version checked_at context tools", "catalog")
    need(data["schema_version"] == "cptc.farm-catalog/1.0", "catalog", "unsupported schema")
    iso_date(data["checked_at"], "catalog.checked_at")
    obj(data["context"], "platforms asset_knowledge scenario_status", "catalog.context")
    strings(data["context"]["platforms"], "platforms")
    need(data["context"]["asset_knowledge"] == "unknown" and
         data["context"]["scenario_status"] == "hypotheses", "context", "unverified asset context")
    need(isinstance(data["tools"], list) and len(data["tools"]) == 40,
         "catalog", "expected forty entries")
    ids, paths = set(), set()
    for n, tool in enumerate(data["tools"]):
        w = f"tool[{n}]"
        obj(tool, "id name upstream priority disposition rationale purpose runtime operations outputs license maintenance protocols needs limitations owner checked_at runbook acquisition_status runtime_status runtime_evidence", w)
        string(tool["id"], w + ".id", 64)
        need(tool["id"] in TOOL_IDS and tool["id"] not in ids, w, "unknown or duplicate tool ID")
        ids.add(tool["id"])
        for key in ("name", "rationale", "purpose", "runtime", "owner"):
            string(tool[key], w + "." + key)
        url(tool["upstream"], w + ".upstream")
        need(tool["priority"] in ("P0", "P1", "P2"), w, "invalid priority")
        need(tool["disposition"] in ("selected", "conditional", "lab", "hold"), w, "invalid disposition")
        for key in ("operations", "outputs", "protocols", "limitations"):
            strings(tool[key], w + "." + key)
        need(set(tool["operations"]) <= set("OPAHWL"), w, "invalid operation class")
        obj(tool["license"], "summary evidence review", w + ".license")
        string(tool["license"]["summary"], w + ".license.summary")
        strings(tool["license"]["evidence"], w + ".license.evidence")
        for ref in tool["license"]["evidence"]:
            url(ref, w + ".license.evidence")
        need(tool["license"]["review"] in ("pending", "hold", "reviewed"), w, "invalid license review")
        need(tool["license"]["review"] != "hold" or tool["disposition"] == "hold",
             w, "license hold requires held disposition")
        obj(tool["maintenance"], "state notes", w + ".maintenance")
        need(tool["maintenance"]["state"] in ("unassessed", "inactive", "archived"), w, "invalid maintenance state")
        string(tool["maintenance"]["notes"], w + ".maintenance.notes")
        need(tool["maintenance"]["state"] == "unassessed" or tool["disposition"] == "hold",
             w, "inactive project requires held disposition")
        obj(tool["needs"], "dependencies privileges hardware", w + ".needs")
        for value in tool["needs"].values():
            string(value, w + ".needs")
        iso_date(tool["checked_at"], w + ".checked_at")
        string(tool["runbook"], w + ".runbook", 240)
        safe_path(tool["runbook"].split("#")[0], w + ".runbook")
        need(tool["acquisition_status"] in ("not_acquired", "staged"), w, "invalid acquisition state")
        need(tool["runtime_status"] in ("not_run", "passed", "failed"), w, "invalid runtime state")
        if tool["runtime_status"] == "not_run":
            need(tool["runtime_evidence"] is None, w, "not-run cannot have passing evidence")
        else:
            string(tool["runtime_evidence"], w + ".runtime_evidence")
        paths.add(tool["runbook"].split("#")[0])
    need(ids == TOOL_IDS, "catalog", "missing tool IDs")
    coverage = set().union(*(set(t["protocols"]) for t in data["tools"] if t["disposition"] == "selected"))
    need({"packet-analysis", "modbus-tcp", "modbus-rtu", "s7", "cip", "opcua", "bacnet-ip", "mqtt"} <= coverage,
         "catalog", "selected primary coverage missing")
    return {t["id"]: t for t in data["tools"]}


def sources(data, tools):
    obj(data, "schema_version checked_at projects", "sources")
    need(data["schema_version"] == "cptc.source-references/1.0", "sources", "unsupported schema")
    iso_date(data["checked_at"], "sources.checked_at")
    need(isinstance(data["projects"], list) and len(data["projects"]) <= 40, "sources", "invalid projects")
    ids, covered = set(), set()
    for n, item in enumerate(data["projects"]):
        w = f"source[{n}]"
        obj(item, "id tool_ids repository release commit archive_candidate license_evidence license_summary dependency_notes acquisition_status sha256", w)
        string(item["id"], w + ".id", 64)
        need(item["id"] not in ids, w, "duplicate source ID")
        ids.add(item["id"])
        strings(item["tool_ids"], w + ".tool_ids")
        need(set(item["tool_ids"]) <= set(tools), w, "unknown source tool")
        covered.update(item["tool_ids"])
        need(isinstance(item["commit"], str) and re.fullmatch(r"[a-f0-9]{40}", item["commit"]), w, "full source commit required")
        for key in ("release", "license_summary", "dependency_notes"):
            string(item[key], w + "." + key)
        for key in ("repository", "archive_candidate"):
            url(item[key], w + "." + key)
        need(item["repository"].startswith("https://github.com/") and
             item["archive_candidate"] == item["repository"] + "/archive/" + item["commit"] + ".tar.gz",
             w, "archive must reference exact source repository and commit")
        strings(item["license_evidence"], w + ".license_evidence")
        for ref in item["license_evidence"]:
            url(ref, w + ".license_evidence")
            need(ref.startswith(item["repository"] + "/blob/" + item["commit"] + "/") or
                 ref.startswith(item["repository"] + "/tree/" + item["commit"] + "/"), w, "license evidence must bind commit")
        need(item["acquisition_status"] == "not_acquired" and item["sha256"] is None,
             w, "source references are not staged artifact records")
    required = {key for key, tool in tools.items() if tool["disposition"] == "selected"}
    need(required <= covered, "sources", "selected source references missing")


def artifact_lock(data, tools):
    obj(data, "schema_version data_category artifacts", "lock")
    need(data["schema_version"] == "cptc.artifact-lock/1.0", "lock", "unsupported schema")
    need(data["data_category"] in ("synthetic", "upstream"), "lock", "invalid data category")
    items = data["artifacts"]
    need(isinstance(items, list) and len(items) <= 256, "lock", "invalid artifact list")
    ids, paths = set(), set()
    for n, item in enumerate(items):
        w = f"artifact[{n}]"
        obj(item, "id tool_ids version source_commit origin path size sha256 platform architecture license license_review dependencies dependency_review smoke_check", w)
        string(item["id"], w + ".id", 64)
        need(item["id"] not in ids, w, "duplicate artifact ID")
        ids.add(item["id"])
        for key in ("version", "platform", "architecture", "license", "smoke_check"):
            string(item[key], w + "." + key)
        strings(item["tool_ids"], w + ".tool_ids", empty=True)
        need(set(item["tool_ids"]) <= set(tools), w, "unknown artifact tool")
        synthetic = data["data_category"] == "synthetic"
        need(bool(item["tool_ids"]) != synthetic, w, "synthetic artifacts cannot represent upstream tools")
        need(synthetic or all(tools[t]["disposition"] == "selected" and tools[t]["license"]["review"] == "reviewed"
                              for t in item["tool_ids"]), w, "tool not selected or license review unresolved")
        need(item["license_review"] == ("synthetic-only" if synthetic else "reviewed"), w, "artifact license review missing")
        need(isinstance(item["source_commit"], str) and re.fullmatch(r"[a-f0-9]{40}", item["source_commit"]), w, "full commit required")
        url(item["origin"], w + ".origin")
        safe_path(item["path"], w + ".path")
        path_key = item["path"].casefold()
        need(path_key not in paths, w, "duplicate artifact path")
        paths.add(path_key)
        need(type(item["size"]) is int and 0 <= item["size"] <= MAX_ARTIFACT, w, "invalid artifact size")
        need(isinstance(item["sha256"], str) and re.fullmatch(r"[a-f0-9]{64}", item["sha256"]), w, "SHA-256 required")
        strings(item["dependencies"], w + ".dependencies", empty=True)
        need(item["dependency_review"] in ("pending", "reviewed"), w, "invalid dependency state")
    graph = {i["id"]: i["dependencies"] for i in items}
    done, active = set(), set()

    def visit(key):
        need(key in graph, "dependencies", "unknown artifact dependency")
        need(key not in active, "dependencies", "cyclic dependency")
        if key in done:
            return
        active.add(key)
        for dep in graph[key]:
            visit(dep)
        active.remove(key)
        done.add(key)

    for key in graph:
        visit(key)
    return items


def regular_path(root, relative):
    parts = safe_path(relative, "artifact.path")
    need(root.is_dir(), "artifact.root", "directory missing")
    current = root
    for p in [root, *root.parents]:
        st = p.lstat()
        need(not (stat.S_ISLNK(st.st_mode) or getattr(st, "st_file_attributes", 0) & 0x400),
             "artifact.root", "symlink or reparse component rejected")
    for part in parts:
        current = current / part
        st = current.lstat()
        need(not (stat.S_ISLNK(st.st_mode) or getattr(st, "st_file_attributes", 0) & 0x400),
             "artifact.path", "symlink or reparse component rejected")
    need(stat.S_ISREG(st.st_mode), "artifact.path", "regular file required")
    need(current.resolve().is_relative_to(root.resolve()), "artifact.path", "path escapes artifact root")
    return current


def verify(items, root):
    for n, item in enumerate(items):
        path = regular_path(Path(root).absolute(), item["path"])
        digest, total = hashlib.sha256(), 0
        with path.open("rb") as handle:
            while chunk := handle.read(1024 * 1024):
                total += len(chunk)
                need(total <= item["size"], f"artifact[{n}]", "size mismatch")
                digest.update(chunk)
        need(total == item["size"] and digest.hexdigest() == item["sha256"],
             f"artifact[{n}]", "size or SHA-256 mismatch")


def readiness(data, tools):
    obj(data, "schema_version gates rehearsals", "readiness")
    need(data["schema_version"] == "cptc.readiness/1.0", "readiness", "unsupported schema")
    gaps, seen = [], set()
    for group, expected in (("gates", GATE_IDS), ("rehearsals", REHEARSALS)):
        values = data[group]
        need(isinstance(values, list) and len(values) == len(expected), group, "missing readiness records")
        seen.clear()
        for n, item in enumerate(values):
            w = f"{group}[{n}]"
            obj(item, "id state owner detail evidence", w)
            string(item["id"], w + ".id", 64)
            need(item["id"] in expected and item["id"] not in seen, w, "unknown or duplicate readiness ID")
            seen.add(item["id"])
            need(item["state"] in ("pending", "partial", "recorded"), w, "invalid readiness state")
            string(item["owner"], w + ".owner")
            string(item["detail"], w + ".detail")
            strings(item["evidence"], w + ".evidence", empty=True)
            if item["state"] == "recorded":
                need(bool(item["evidence"]), w, "recorded decision/check requires evidence")
            else:
                gaps.append(item["id"])
    for key, tool in tools.items():
        if tool["disposition"] == "selected" and tool["runtime_status"] != "passed":
            gaps.append(key + ":runtime")
    return gaps


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("validate", "list", "verify", "readiness"))
    parser.add_argument("--catalog", type=Path, default=BASE / "catalog.json")
    parser.add_argument("--sources", type=Path, default=BASE / "sources.json")
    parser.add_argument("--lock", type=Path, default=BASE / "artifact-lock.json")
    parser.add_argument("--readiness", type=Path, default=BASE / "readiness.json")
    parser.add_argument("--root", type=Path, help="Explicit local root required for verify")
    parser.add_argument("--disposition", choices=("selected", "conditional", "lab", "hold"))
    parser.add_argument("--protocol", help="Exact catalog protocol label")
    args = parser.parse_args(argv)
    try:
        tools = catalog(load(args.catalog))
        sources(load(args.sources), tools)
        lock = load(args.lock)
        items = artifact_lock(lock, tools)
        gaps = readiness(load(args.readiness), tools)
        if args.command == "list":
            for key, tool in tools.items():
                if (not args.disposition or tool["disposition"] == args.disposition) and (
                        not args.protocol or args.protocol in tool["protocols"]):
                    print(f"{key} | {tool['disposition']} | {tool['name']}")
        elif args.command == "verify":
            need(args.root is not None, "verify", "explicit artifact root required")
            if not items:
                print("PENDING: empty artifact inventory; no upstream tool bytes verified.")
                return 3
            verify(items, args.root)
            print(f"Integrity verified: {len(items)} {lock['data_category']} artifacts. Runtime, source authenticity and license approval are not established.")
        elif args.command == "readiness":
            if lock["data_category"] != "upstream" or not items:
                gaps.append("upstream-artifacts:not-acquired")
            if any(i["dependency_review"] != "reviewed" for i in items):
                gaps.append("dependency-closure:pending")
            covered = set().union(*(set(i["tool_ids"]) for i in items)) if items else set()
            if any(t["disposition"] == "selected" and (key not in covered or t["acquisition_status"] != "staged")
                   for key, t in tools.items()):
                gaps.append("selected-tool-acquisition:incomplete")
            if gaps:
                print("PENDING readiness: " + ", ".join(gaps))
                return 3
            print("Readiness records present. Human assertions, runtime results and external approval require independent verification.")
        else:
            print(f"Valid preparation records: {len(tools)} tools; {len(items)} staged inventory entries; {len(gaps)} pending readiness items. Validation is not runtime acceptance.")
        return 0
    except Invalid as exc:
        print(f"Invalid preparation record: {exc}", file=sys.stderr)
        return 2
    except (OSError, RecursionError):
        print("Local input/file operation failed; no artifacts changed.", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
