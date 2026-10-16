"""Human curation of existing completed-report JSON; no native tool adapters."""
from __future__ import annotations

import importlib.util
import tempfile
from copy import deepcopy
from difflib import SequenceMatcher
from pathlib import Path

from common import ROOT, VERSION, MAX_BYTES, bundle, digest, digest_file, encoded, identity, load, need, now, output_path, read, text
import workspace as ws


def reporter():
    spec = importlib.util.spec_from_file_location("workbench_reportgen", ROOT / "tooling/reporting/reportgen.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def preview(path):
    module = reporter()
    raw = read(path)
    try:
        data = module.validate(module.load(raw))
    except module.ContractError:
        from common import Error
        raise Error("report_contract_rejected") from None
    return {"source_sha256": digest(raw), "schema": data["schema_version"],
            "data_category": data["data_category"], "findings": len(data["findings"]),
            "statuses": [f["status"] for f in data["findings"]],
            "limitations": data["engagement"]["limitations"],
            "markings": module.handling(data)["report"], "mutated": False,
            "source_hashes": "Supplied evidence hashes remain unverified; no evidence file opened"}


def import_report(directory, path):
    details = preview(path)
    module = reporter()
    raw = read(path)
    need(digest(raw) == details["source_sha256"], "input_changed_since_preview")
    source = module.validate(module.load(raw))
    key = "import-" + details["source_sha256"][:20]
    def action(value):
        if key in value["imports"]:
            return {"id": key, "duplicate": True}
        existing = {finding["id"] for item in value["imports"].values() for finding in item["report"]["findings"]}
        need(not existing.intersection(f["id"] for f in source["findings"]), "conflicting_finding_ids")
        working = deepcopy(source)
        working.pop("review", None)
        for finding in working["findings"]:
            finding["status"] = "candidate"
        item = {"id": key, "source_sha256": details["source_sha256"], "source_report": source,
                "report": working, "revision": 1, "updated_at": now(), "dispositions": {}}
        value["imports"][key] = item
        ws.inherit(value, module.handling(source)["report"].split("//"))
        ws.event(value, "import", "success", key)
        return {"id": key, "duplicate": False, "findings": len(working["findings"]), "human_review": "pending"}
    return ws.change(directory, action)


def find(item, identifier):
    rows = [f for f in item["report"]["findings"] if f["id"] == identifier]
    need(len(rows) == 1, "finding_missing")
    return rows[0]


def review(directory, import_id, finding_id, decision, reason, reviewer_name):
    need(decision in ("accept", "reject"), "invalid_review_decision")
    text(reason, 2000)
    text(reviewer_name, 120)
    def action(value):
        need(import_id in value["imports"], "import_missing")
        item = value["imports"][import_id]
        finding = find(item, finding_id)
        finding["status"] = "confirmed" if decision == "accept" else "candidate"
        item["dispositions"][finding_id] = decision
        item["revision"] += 1
        item["updated_at"] = now()
        record = {"id": identity("review"), "finding": finding_id, "import": import_id,
                  "decision": decision, "reason": reason, "reviewer": reviewer_name, "updated_at": now()}
        value["reviews"][record["id"]] = record
        ws.event(value, "human_review", "recorded", record["id"])
        return record
    return ws.change(directory, action)


def author(directory, import_id, finding_id, replacement, base_revision):
    item = ws.get(directory, "imports", import_id)
    need(isinstance(replacement, dict) and replacement.get("id") == finding_id, "finding_identity_changed")
    report = deepcopy(item["report"])
    found = False
    for index, finding in enumerate(report["findings"]):
        if finding["id"] == finding_id:
            report["findings"][index] = dict(replacement, status="candidate")
            found = True
    need(found, "finding_missing")
    reporter().validate(report)
    dispositions = dict(item["dispositions"])
    dispositions.pop(finding_id, None)
    tags = reporter().handling(report)["report"].split("//")
    return ws.edit(directory, "imports", import_id, {"report": report, "dispositions": dispositions,
                                                    "markings": tags}, base_revision)


def prefill(directory, import_id, finding_id):
    finding = deepcopy(find(ws.get(directory, "imports", import_id), finding_id))
    return {"finding": finding, "author_must_verify": ["business_impact", "severity", "remediation", "retest_steps"],
            "confirmed_by_template": False}


def duplicates(directory, import_id):
    item = ws.get(directory, "imports", import_id)
    findings = item["report"]["findings"]
    result = []
    for index, first in enumerate(findings):
        for second in findings[index + 1:]:
            score = SequenceMatcher(None, first["title"].lower(), second["title"].lower()).ratio()
            common_assets = sorted(set(first["assets"]) & set(second["assets"]))
            if score >= 0.75 and (common_assets or score == 1):
                result.append({"first": first["id"], "second": second["id"], "score": round(score, 3),
                               "reason": "similar titles" + (" and shared assets" if common_assets else ""),
                               "merged": False})
    return result


def merge(directory, import_id, primary_id, secondary_id, actor, reason):
    need(primary_id != secondary_id, "same_finding")
    text(actor, 120)
    text(reason, 2000)
    def action(value):
        need(import_id in value["imports"], "import_missing")
        item = value["imports"][import_id]
        primary, secondary = find(item, primary_id), find(item, secondary_id)
        before = [deepcopy(primary), deepcopy(secondary)]
        primary["assets"] = list(dict.fromkeys(primary["assets"] + secondary["assets"]))
        known = {e["id"] for e in primary["evidence"]}
        primary["evidence"].extend(deepcopy(e) for e in secondary["evidence"] if e["id"] not in known)
        tags = set(primary.get("markings", [])) | set(secondary.get("markings", []))
        if tags:
            if "PII Red" in tags:
                tags.discard("PII")
            primary["markings"] = [tag for tag in reporter().MARKINGS if tag in tags]
        primary["status"] = "candidate"
        item["report"]["findings"] = [f for f in item["report"]["findings"] if f["id"] != secondary_id]
        reporter().validate(item["report"])
        item["dispositions"].pop(primary_id, None)
        item["revision"] += 1
        item["updated_at"] = now()
        record = {"id": identity("merge"), "import": import_id, "primary": primary_id,
                  "secondary": secondary_id, "originals": before, "after_sha256": digest(encoded(primary)),
                  "actor": actor, "reason": reason, "active": True, "updated_at": now()}
        value["merges"][record["id"]] = record
        return {"id": record["id"], "active": True, "human_review": "pending",
                "narratives": "Primary wording retained; both originals preserved in merge record"}
    return ws.change(directory, action)


def undo_merge(directory, identifier, actor):
    text(actor, 120)
    def action(value):
        need(identifier in value["merges"], "merge_missing")
        record = value["merges"][identifier]
        need(record["active"], "merge_not_active")
        item = value["imports"][record["import"]]
        current = find(item, record["primary"])
        # Human acceptance only changes status; authoring changes must not be overwritten.
        comparison = dict(current, status="candidate")
        need(digest(encoded(comparison)) == record["after_sha256"], "finding_changed_after_merge")
        need(not any(f["id"] == record["secondary"] for f in item["report"]["findings"]), "secondary_already_present")
        item["report"]["findings"] = [f for f in item["report"]["findings"] if f["id"] != record["primary"]]
        for original in record["originals"]:
            item["report"]["findings"].append(dict(deepcopy(original), status="candidate"))
            item["dispositions"].pop(original["id"], None)
        item["revision"] += 1
        item["updated_at"] = now()
        record.update(active=False, undone_by=actor, updated_at=now())
        return {"id": identifier, "active": False, "human_review": "pending"}
    return ws.change(directory, action)


def retest(directory, record):
    for key in ("finding", "actor", "summary"):
        text(record.get(key), 2000)
    need(record.get("status") in ("recommended", "applied", "verified"), "invalid_retest_status")
    evidence = record.get("evidence", [])
    need(isinstance(evidence, list) and all(isinstance(e, str) and e.strip() for e in evidence), "invalid_retest_evidence")
    need(record["status"] != "verified" or bool(evidence), "verified_retest_requires_evidence")
    value = ws.state(directory)
    need(any(f["id"] == record["finding"] for item in value["imports"].values()
             for f in item["report"]["findings"]), "finding_missing")
    return ws.add(directory, "retests", dict(record, evidence_verification="human supplied references, not automatically proven"))


def incident(directory, record):
    for key in ("run", "summary", "actor"):
        text(record.get(key), 2000)
    ws.get(directory, "runs", record["run"])
    row = dict(record)
    for key in ("stop", "containment", "notification", "cleanup"):
        row.setdefault(key, "pending")
        text(row[key], 2000)
    row["automatically_notified"] = False
    return ws.add(directory, "incidents", row)


def completeness(directory, import_id, rubric=()):
    item = ws.get(directory, "imports", import_id)
    issues = []
    for finding in item["report"]["findings"]:
        if item["dispositions"].get(finding["id"]) == "reject":
            continue
        for key in ("business_impact", "remediation", "retest_steps", "evidence", "severity_rationale"):
            if not finding.get(key) or "not supplied" in str(finding[key]).lower():
                issues.append({"finding": finding["id"], "field": key, "code": "needs_author"})
        if item["dispositions"].get(finding["id"]) != "accept":
            issues.append({"finding": finding["id"], "code": "human_review_pending"})
        if any(c["applicability"] != "verified" for c in finding.get("cves", [])):
            issues.append({"finding": finding["id"], "code": "cve_applicability_pending"})
    for field in rubric:
        if not item["report"]["engagement"].get(field):
            issues.append({"field": field, "code": "rubric_field_missing"})
    return {"ready_for_reviewed_training_copy": not issues, "issues": issues,
            "event_submission_approved": False}


def appendix(value):
    blocks = [("heading", (2, "Workbench run results (operator supplied)"))]
    for key, run in value["runs"].items():
        blocks.append(("paragraph", f"{key} | {run['tool']} {run['tool_version']} | stage={run['stage']} | status={run['status']} | exit={run['exit_code']} | {run['limitations']}"))
        for stage, outcome in run.get("stages", {}).items():
            blocks.append(("paragraph", f"{key} | stage={stage} | status={outcome['status']} | exit={outcome['exit_code']} | {outcome['diagnostic_code']}"))
    if not value["runs"]:
        blocks.append(("paragraph", "No run records supplied; this does not establish successful testing."))
    if value["log_truncated"]:
        blocks.append(("paragraph", "Operational log is truncated; recorded log coverage is incomplete."))
    for collection, label in (("incidents", "Incident timeline (recorded actions)"), ("retests", "Remediation and retest status")):
        blocks.append(("heading", (2, label)))
        for key, row in value[collection].items():
            if collection == "incidents":
                value_text = f"{key} | run={row['run']} | {row['summary']} | stop={row['stop']} | containment={row['containment']} | notification={row['notification']} | cleanup={row['cleanup']}"
            else:
                value_text = f"{key} | finding={row['finding']} | {row['status']} | {row['summary']} | supplied evidence={', '.join(row.get('evidence', []))}"
            blocks.append(("paragraph", value_text))
        if not value[collection]:
            blocks.append(("paragraph", "No records supplied; no action inferred."))
    return blocks


def changed(previous, current):
    before = {f["id"]: f for f in previous["findings"]} if previous else {}
    after = {f["id"]: f for f in current["findings"]}
    return {"added": sorted(after.keys() - before.keys()), "removed": sorted(before.keys() - after.keys()),
            "changed": sorted(k for k in before.keys() & after.keys() if before[k] != after[k]),
            "engagement_changed": previous is not None and previous["engagement"] != current["engagement"]}


def snapshot(directory, import_id, destination, pdf=False, reviewer_name=None, rubric=(), *, docx=False):
    value = ws.state(directory)
    need(import_id in value["imports"], "import_missing")
    item = value["imports"][import_id]
    report = deepcopy(item["report"])
    rejected = {key for key, decision in item["dispositions"].items() if decision == "reject"}
    report["findings"] = [f for f in report["findings"] if f["id"] not in rejected]
    report["engagement"]["limitations"].append(f"Workbench snapshot; {len(rejected)} explicitly rejected findings omitted; imported source preserved. Run results are operator-supplied, not complete assessment proof.")
    module = reporter()
    inherited = set(value["markings"]) | set(module.handling(item["source_report"])["report"].split("//"))
    for collection in ("incidents", "retests"):
        for row in value[collection].values():
            inherited.update(row.get("markings", []))
    if "PII Red" in inherited:
        inherited.discard("PII")
    markings = [tag for tag in module.MARKINGS if tag in inherited]
    module.validate_markings(list(inherited), "workbench.markings")
    report["schema_version"] = "1.2"
    report["markings"] = markings
    ready = completeness(directory, import_id, rubric)
    if reviewer_name:
        need(ready["ready_for_reviewed_training_copy"], "report_review_incomplete")
        text(reviewer_name, 120)
        report["review"] = {"reviewer": reviewer_name, "reviewed_at": now()[:10]}
    module.validate(report, bool(reviewer_name))
    prior = [row for row in value["snapshots"].values() if row["import"] == import_id]
    latest = max(prior, key=lambda row: row["manifest"]["workspace_revision"]) if prior else None
    previous = latest["report"] if latest else None
    delta = changed(previous, report)
    context = {key: {identifier: digest(encoded(row)) for identifier, row in value[key].items()}
               for key in ("runs", "retests", "incidents")}
    previous_context = latest.get("context", {}) if latest else {}
    for key, current_records in context.items():
        old_records = previous_context.get(key, {})
        delta[key] = {"added": sorted(current_records.keys() - old_records.keys()),
                      "removed": sorted(old_records.keys() - current_records.keys()),
                      "changed": sorted(k for k in current_records.keys() & old_records.keys() if current_records[k] != old_records[k])}
    delta["markings_changed"] = previous is not None and previous.get("markings") != report["markings"]
    target = output_path(destination)
    need(not target.exists(), "destination_exists")
    target.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=".snapshot-", dir=target.parent) as temporary:
        rendered = Path(temporary) / "rendered"
        manifest = module.generate(encoded(report), rendered, pdf, bool(reviewer_name), appendix(value), markings, docx=docx)
        files = {path.name: path.read_bytes() for path in rendered.iterdir() if path.name != "manifest.json"}
    files.update({"input.json": encoded(report), "changes.json": encoded(delta)})
    manifest.update(workbench_version=VERSION, workspace_revision=value["revision"],
                    imported_export_sha256=item["source_sha256"],
                    source_schema_version=item["source_report"]["schema_version"],
                    artifacts={name: digest(raw) for name, raw in sorted(files.items())})
    files["manifest.json"] = encoded(manifest)
    row = {"import": import_id, "report": report, "context": context, "destination": str(target.absolute()),
           "manifest": manifest, "changes": delta, "status": "reviewed_training" if reviewer_name else "draft"}
    def publish(current):
        row.update(id=identity("snapshot"), revision=1, updated_at=now())
        current["snapshots"][row["id"]] = row
        need(len(encoded(current)) <= MAX_BYTES, "workspace_limit_reached")
        bundle(target, files)
        return row
    # A complete bundle may survive a subsequent ledger I/O error, but no partial report is published.
    # On failure inspect manifest/workspace revision before attaching it; never rerun target activity.
    return ws.change(directory, publish, expected=value["revision"])


def integrity(path, expected):
    text(expected, 64)
    actual, size = digest_file(path)
    return {"matches": actual == expected, "computed_sha256": actual, "bytes": size, "authenticity_proven": False}
