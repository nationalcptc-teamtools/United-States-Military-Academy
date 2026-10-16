"""Pure, bounded report revisions. No filesystem, renderer, or tool execution."""
from __future__ import annotations

import hashlib
import json
from copy import deepcopy

CONTRACT = "cptc.report-update/1.0"
FINDING_FIELDS = ("title", "severity", "severity_rationale", "assets", "description",
                  "validation_steps", "business_impact", "remediation", "retest_steps", "cves", "cvss")
ENGAGEMENT_FIELDS = ("report_date", "objective", "recommendations", "methodology_sections",
                     "methodology", "executive_summary", "limitations")


def encoded(value):
    return (json.dumps(value, ensure_ascii=False, sort_keys=True, indent=2,
                       allow_nan=False) + "\n").encode("utf-8")


def fingerprint(value):
    """Semantic identity: canonical UTF-8 JSON, independent of input whitespace/BOM."""
    return hashlib.sha256(encoded(value)).hexdigest()


def describe(data):
    return {"report_sha256": fingerprint(data), "engagement_id": data["engagement"]["id"],
            "findings": [{"id": f["id"], "status": f["status"],
                          "evidence": [e["id"] for e in f["evidence"]]} for f in data["findings"]]}


def changes(previous, current):
    before = {f["id"]: f for f in previous["findings"]} if previous else {}
    after = {f["id"]: f for f in current["findings"]}
    evidence = {}
    for key, finding in after.items():
        old = {e["id"]: e for e in before.get(key, {}).get("evidence", [])}
        new = {e["id"]: e for e in finding["evidence"]}
        if encoded(old) != encoded(new):
            evidence[key] = {"added": sorted(new.keys() - old.keys()),
                             "removed": sorted(old.keys() - new.keys()),
                             "changed": sorted(k for k in old.keys() & new.keys() if encoded(old[k]) != encoded(new[k]))}
    return {"added": sorted(after.keys() - before.keys()), "removed": sorted(before.keys() - after.keys()),
            "changed": sorted(k for k in before.keys() & after.keys() if encoded(before[k]) != encoded(after[k])),
            "unchanged": sorted(k for k in before.keys() & after.keys() if encoded(before[k]) == encoded(after[k])),
            "engagement_changed": previous is not None and encoded(previous["engagement"]) != encoded(current["engagement"]),
            "evidence": evidence}


def validate_update(patch, contract):
    c = contract
    c.obj(patch, "update", ("contract_version", "data_category", "id", "engagement_id", "base_sha256",
                             "actor", "reason", "operations"))
    c.require(patch["contract_version"] == CONTRACT, "update.contract_version", "unsupported update contract")
    c.require(patch["data_category"] == "synthetic", "update.data_category", "synthetic data only")
    for field in ("id", "engagement_id"):
        c.identifier(patch[field], "update." + field)
    c.text(patch["actor"], "update.actor", 120, True)
    c.text(patch["reason"], "update.reason", 2000)
    import re
    c.require(isinstance(patch["base_sha256"], str) and re.fullmatch(r"[a-f0-9]{64}", patch["base_sha256"]),
              "update.base_sha256", "expected canonical report SHA-256")
    c.items(patch["operations"], "update.operations", maximum=200)
    return patch


def apply(data, patch, contract):
    """Return a validated new report and receipt; never mutate caller objects."""
    c = contract
    c.validate(data)
    validate_update(patch, c)
    c.require(patch["engagement_id"] == data["engagement"]["id"], "update.engagement_id", "engagement mismatch")
    c.require(patch["base_sha256"] == fingerprint(data), "update.base_sha256", "stale base; preview current report and rebase update")
    result = deepcopy(data)
    touched = set()
    for index, operation in enumerate(patch["operations"]):
        at = f"update.operations[{index}]"
        c.require(isinstance(operation, dict), at, "expected operation object")
        kind = operation.get("op")
        if kind == "add_finding":
            c.obj(operation, at, ("op", "finding"))
            finding = deepcopy(operation["finding"])
            c.require(isinstance(finding, dict), at, "finding object required")
            c.identifier(finding.get("id"), at + ".finding.id")
            probe = deepcopy(data)
            probe.update(schema_version="1.2", markings=c.handling(data)["report"].split("//"))
            probe["findings"] = [dict(finding, status="candidate")]
            c.validate(probe)
            existing = next((f for f in result["findings"] if f["id"] == finding["id"]), None)
            finding["status"] = "candidate"
            if existing is not None:
                c.require(dict(existing, status="candidate") == finding, at, "finding ID conflict")
            else:
                result["findings"].append(finding)
                touched.add(finding["id"])
        elif kind == "amend_engagement":
            c.obj(operation, at, ("op", "fields"))
            fields = operation["fields"]
            c.obj(fields, at + ".fields", (), ENGAGEMENT_FIELDS)
            c.require(bool(fields), at, "at least one authored field required")
            result["engagement"].update(deepcopy(fields))
        elif kind in ("append_evidence", "amend_finding"):
            payload = "evidence" if kind == "append_evidence" else "fields"
            c.obj(operation, at, ("op", "finding_id", payload))
            c.identifier(operation["finding_id"], at + ".finding_id")
            finding = next((f for f in result["findings"] if f["id"] == operation["finding_id"]), None)
            c.require(finding is not None, at + ".finding_id", "finding missing")
            before = deepcopy(finding)
            if kind == "amend_finding":
                fields = operation["fields"]
                c.obj(fields, at + ".fields", (), FINDING_FIELDS)
                c.require(bool(fields), at, "at least one authored field required")
                finding.update(deepcopy(fields))
            else:
                c.items(operation["evidence"], at + ".evidence", maximum=50)
                for entry in operation["evidence"]:
                    c.require(isinstance(entry, dict), at + ".evidence", "evidence object required")
                    c.identifier(entry.get("id"), at + ".evidence.id")
                    owners = [(f["id"], e) for f in result["findings"] for e in f["evidence"] if e["id"] == entry["id"]]
                    if owners:
                        c.require(len(owners) == 1 and owners[0] == (finding["id"], entry), at, "evidence ID conflict")
                    else:
                        finding["evidence"].append(deepcopy(entry))
            if encoded(finding) != encoded(before):
                touched.add(finding["id"])
        else:
            c.require(False, at + ".op", "unsupported operation")
    # A repeated observation or an amendment with the same value preserves human review.
    originals = {f["id"]: f for f in data["findings"]}
    touched = {f["id"] for f in result["findings"] if f["id"] in touched
               and encoded(originals.get(f["id"])) != encoded(f)}
    modified = encoded(result) != encoded(data)
    if modified:
        result.pop("review", None)
        for finding in result["findings"]:
            if finding["id"] in touched:
                finding["status"] = "candidate"
        # Promote legacy inputs only when structured markings occur in newly added content.
        structured = result["schema_version"] == "1.2" or any(
            "markings" in f or any("markings" in e for e in f["evidence"]) for f in result["findings"])
        if structured:
            result["schema_version"] = "1.2"
            result["markings"] = c.handling(data)["report"].split("//")
    c.validate(result)
    c.require(len(encoded(result)) <= c.MAX_INPUT_BYTES, "update.result", "updated report exceeds 2 MB")
    delta = changes(data, result)
    receipt = {"contract_version": CONTRACT, "id": patch["id"], "actor": patch["actor"], "reason": patch["reason"],
               "update_sha256": fingerprint(patch), "base_sha256": fingerprint(data),
               "result_sha256": fingerprint(result), "affected_findings": sorted(touched),
               "modified": modified, "changes": delta, "evidence_files_opened": False,
               "evidence_hashes_verified": False}
    return result, receipt
