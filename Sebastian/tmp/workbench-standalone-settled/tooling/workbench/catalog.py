"""A live catalog view, never a replacement farmkit registry."""
from __future__ import annotations

import re

from common import ROOT, load, need

ALIASES = {"TOOL-001": ["linpeas.sh", "linux enumeration"],
           "TOOL-002": ["winpeasx64", "windows enumeration"],
           "TOOL-003": ["wireshark", "packet", "capture", "pcap"],
           "TOOL-013": ["modbus", "register client"],
           "TOOL-020": ["opcua", "opc ua"],
           "TOOL-028": ["open dnp3", "opendnp3"]}
OPERATION = {"P": "offline/passive-capable", "A": "active-query-capable",
             "H": "host-enumeration", "W": "write/control-capable", "L": "lab"}


def tools():
    source = load(ROOT / "tooling/farmkit/catalog.json")
    result = []
    for tool in source["tools"]:
        row = dict(tool)
        row["aliases"] = ALIASES.get(row["id"], [])
        row["platform"] = "windows" if row["id"] == "TOOL-002" else "linux/windows" if "python" in row["runtime"].lower() else "linux"
        row["operation_classes"] = [OPERATION.get(op, op) for op in row["operations"]]
        row["input"] = "pcap/capture" if row["id"] in ("TOOL-003", "TOOL-004", "TOOL-005") else "operator-supplied parameters"
        row["input_note"] = "Capability candidate, not a tested import/operation."
        row["ready"] = False  # Farm declarations are not authenticated installed/event evidence.
        row["readiness"] = {"cataloged": True, "downloaded": row["acquisition_status"],
                            "integrity_checked": "not verified here", "tested": row["runtime_status"],
                            "reviewed": "tool review not verified here", "accepted": "pending",
                            "published": "not verified here", "event_approved": "pending"}
        row["lifecycle"] = {"state": row.get("maintenance", {}).get("state", "not established here"),
                            "replacement": None, "gap": None}
        if row["lifecycle"]["state"] in ("archived", "inactive", "retired"):
            row["lifecycle"]["gap"] = row["license"]["summary"]
            row["next_lifecycle_action"] = "Review the documented gap; no maintained replacement accepted here"
        row["declaration_note"] = "Catalog state is a dated declaration; installed image evidence is separate."
        row["next_actions"] = ["Read tooling/farmkit/" + row["runbook"],
                               "Check selected runtime and approval", "Review output route: native adapters not implemented"]
        result.append(row)
    for identifier, name, purpose, output in (
        ("LEGACY-NMAP", "Super Nmap", "Legacy network scanning wrapper; known limitations", "xml/html/pdf"),
        ("HELPER-REPORT", "Report generator", "Render completed synthetic report JSON", "markdown/pdf"),
        ("HELPER-WORKBENCH", "Development workbench", "Find tools and curate synthetic workflow records", "json/markdown")):
        result.append({"id": identifier, "name": name, "purpose": purpose, "aliases": [],
                       "platform": "linux" if identifier == "LEGACY-NMAP" else "linux/windows",
                       "runtime": "Python 3.10+", "protocols": [], "operations": [],
                       "operation_classes": ["active-query-capable"] if identifier == "LEGACY-NMAP" else ["offline"],
                       "input": "completed report JSON" if identifier == "HELPER-REPORT" else "operator-supplied parameters",
                       "outputs": [output], "disposition": "legacy" if identifier == "LEGACY-NMAP" else "preparation",
                       "ready": False, "needs": {"privileges": "Check the selected operation/runtime"},
                       "owner": "unassigned", "license": {"review": "team review required"},
                       "acquisition_status": "local source", "runtime_status": "see recorded verification",
                       "next_actions": ["Read the tool README and current verification limits"]})
    for row in result:
        legacy = row["id"] == "LEGACY-NMAP"
        row.setdefault("readiness", {"cataloged": True, "downloaded": "local source only",
                                   "integrity_checked": "not verified here" if legacy else "see source manifest",
                                   "tested": "not_run" if legacy else "see synthetic verification",
                                   "reviewed": "not verified here" if legacy else "see scoped independent review", "accepted": "pending",
                                   "published": "not verified here", "event_approved": "pending"})
        row.setdefault("lifecycle", {"state": "legacy" if row["id"] == "LEGACY-NMAP" else "preparation",
                                     "replacement": None, "gap": None})
    return result


def search(query="", **filters):
    words = re.findall(r"[a-z0-9]+", query.lower())
    hits = []
    for row in tools():
        haystack = " ".join(str(row.get(key, "")) for key in
                            ("id", "name", "purpose", "aliases", "protocols", "input", "outputs")).lower()
        score = sum(word in haystack for word in words)
        if words and score != len(words):
            continue
        eligible = True
        reasons = []
        for field, value in filters.items():
            if not value:
                continue
            key = {"protocol": "protocols", "operation": "operation_classes", "output": "outputs",
                   "privilege": "needs", "readiness": "runtime_status"}.get(field, field)
            if field == "readiness" and value in ("ready", "not-ready"):
                matches = row["ready"] if value == "ready" else not row["ready"]
            else:
                matches = str(value).lower() in str(row.get(key, "")).lower()
            eligible &= matches
            reasons.append(field + (":match" if matches else ":incompatible"))
        hits.append({"id": row["id"], "name": row["name"], "eligible": eligible,
                     "disposition": row["disposition"], "ready": False,
                     "reasons": reasons or ["task/name match"], "next_actions": row["next_actions"],
                     "score": score, "lifecycle": row["lifecycle"]})
    return sorted(hits, key=lambda item: (not item["eligible"], -item["score"], item["id"]))


def card(identifier):
    rows = [row for row in tools() if row["id"] == identifier]
    need(len(rows) == 1, "unknown_tool")
    return rows[0]


def compare(identifiers):
    return [{key: row.get(key) for key in ("id", "name", "platform", "runtime", "input", "outputs",
             "disposition", "license", "needs", "ready", "readiness", "next_actions")}
            for row in [card(identifier) for identifier in identifiers]]


def choose(task):
    aliases = {"analyze existing capture": "pcap", "windows host": "windows enumeration",
               "linux host": "linux enumeration", "modbus endpoint": "modbus",
               "opc ua endpoint": "opcua", "render report": "report generator"}
    query = aliases.get(task.lower(), task)
    matches = search(query)
    return {"task": task, "candidates": matches, "coverage_gap": not bool(matches),
            "operation_approved": False, "executed": False}
