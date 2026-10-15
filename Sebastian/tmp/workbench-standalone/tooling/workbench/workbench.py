#!/usr/bin/env python3
"""CPTC offline development workbench. Synthetic preparation and manual records."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import catalog
import delivery
import operations
import reports
import workspace as ws
from common import Error, VERSION, bundle, encoded, load, need, preflight


def parser():
    root = argparse.ArgumentParser(description=__doc__)
    root.add_argument("--version", action="version", version=VERSION)
    commands = root.add_subparsers(dest="command", required=True)
    p = commands.add_parser("search", help="Search existing catalog; no telemetry or download")
    p.add_argument("query", nargs="?", default="")
    for field in ("platform", "runtime", "protocol", "privilege", "operation", "input", "output", "readiness", "disposition"):
        p.add_argument("--" + field)
    p.add_argument("--explain-excluded", action="store_true")
    p = commands.add_parser("choose", help="Find candidates for a task")
    p.add_argument("task")
    p = commands.add_parser("card", help="Show tool prerequisites, holds and next actions")
    p.add_argument("id")
    p.add_argument("--workspace")
    p = commands.add_parser("compare", help="Compare candidates against consistent fields")
    p.add_argument("ids", nargs="+")
    p = commands.add_parser("init", help="Create a new synthetic workspace")
    p.add_argument("destination")
    p.add_argument("--owner", required=True)
    p = commands.add_parser("preflight", help="Inspect local prerequisites without installing/executing")
    p.add_argument("destination")
    p.add_argument("--require", action="append", default=[])
    p.add_argument("--platform", choices=("windows", "linux"))
    p.add_argument("--free-bytes", type=int, default=1_000_000)
    p = commands.add_parser("platforms", help="Show declared/tested platform boundaries")
    p = commands.add_parser("scaffold", help="Create general tool skeleton; no adapter/fixture kit")
    p.add_argument("destination")
    p.add_argument("--name", required=True)
    p.add_argument("--owner", required=True)
    p.add_argument("--license", default="MIT")
    p = commands.add_parser("check-docs", help="Check one scaffold's declared help/version consistency")
    p.add_argument("directory")
    p = commands.add_parser("check-links", help="Check explicit local Markdown and existing catalog/runbook links")
    p.add_argument("paths", nargs="*")
    p = commands.add_parser("intake", help="Record a capability request and reuse/priority evidence")
    p.add_argument("workspace")
    p.add_argument("input")
    p = commands.add_parser("decision", help="Record accepted/rejected/deferred/blocked alternative")
    p.add_argument("workspace")
    p.add_argument("input")
    p = commands.add_parser("handling", help="Record named handling/retention/export/deletion responsibilities; performs none")
    p.add_argument("workspace")
    p.add_argument("input")
    p = commands.add_parser("owner", help="Assign capability owner/backup/reviewer; no target claims")
    p.add_argument("workspace")
    p.add_argument("capability")
    for field in ("primary", "backup", "reviewer"):
        p.add_argument("--" + field, required=True)
    p = commands.add_parser("transfer", help="Release/transfer an existing owner record")
    p.add_argument("workspace")
    p.add_argument("capability")
    p.add_argument("--base", type=int, required=True)
    p.add_argument("--actor", required=True)
    p.add_argument("--new-owner")
    p = commands.add_parser("note", help="Record an authored note or shift handoff")
    p.add_argument("workspace")
    p.add_argument("input")
    p = commands.add_parser("edit-note", help="Preserve conflicts on stale authored edits")
    p.add_argument("workspace")
    p.add_argument("id")
    p.add_argument("input")
    p.add_argument("--base", type=int, required=True)
    p = commands.add_parser("show", help="Inspect a specific local workflow record")
    p.add_argument("workspace")
    p.add_argument("collection", choices=ws.COLLECTIONS)
    p.add_argument("id")
    p = commands.add_parser("plan", help="Record/preview a manual plan; does not dispatch its command")
    p.add_argument("workspace")
    p.add_argument("input")
    p = commands.add_parser("revalidate", help="Recheck supplied targets/scope/profile metadata without DNS")
    p.add_argument("workspace")
    p.add_argument("id")
    p.add_argument("input")
    p.add_argument("--reviewer", required=True)
    p.add_argument("--accept-change", action="store_true")
    p = commands.add_parser("deviation", help="Record an external profile exception decision")
    p.add_argument("workspace")
    p.add_argument("id")
    for field in ("reason", "approval-ref", "actor"):
        p.add_argument("--" + field, required=True)
    p = commands.add_parser("run-record", help="Record supplied synthetic run outcome; never launches tool")
    p.add_argument("workspace")
    for field in ("tool", "version", "operator", "status"):
        p.add_argument("--" + field, required=True)
    p.add_argument("--exit-code", type=int)
    p.add_argument("--stage", choices=("tool", "import", "render"), default="tool")
    p.add_argument("--profile", default="manual")
    p.add_argument("--binary-sha256", default="unknown")
    p.add_argument("--config-sha256", default="unknown")
    p.add_argument("--limitations", default="Operator supplied; not independently verified")
    p.add_argument("--scope-ref", default="not supplied")
    p.add_argument("--evidence-ref", action="append", default=[])
    p.add_argument("--plan-id")
    p = commands.add_parser("event", help="Record a separate tool/import/render stage outcome")
    p.add_argument("workspace")
    p.add_argument("id")
    for field in ("stage", "status", "code"):
        p.add_argument("--" + field, required=True)
    p.add_argument("--exit-code", type=int)
    p = commands.add_parser("simulate", help="Supervise a fixed synthetic worker, never a user command")
    p.add_argument("workspace")
    p.add_argument("--seconds", type=float, default=2)
    p = commands.add_parser("cancel", help="Cancel this workbench's synthetic worker; manual runner stop guidance otherwise")
    p.add_argument("workspace")
    p.add_argument("id")
    p = commands.add_parser("resume", help="Record explicit repeat/skip decision; never automatically reruns")
    p.add_argument("workspace")
    p.add_argument("id")
    p.add_argument("--disposition", choices=("repeat", "skip"), required=True)
    p.add_argument("--actor", required=True)
    p = commands.add_parser("preview-import", help="Preview supported completed-report JSON only")
    p.add_argument("input")
    p = commands.add_parser("import-report", help="Import supported synthetic report; human review required")
    p.add_argument("workspace")
    p.add_argument("input")
    p = commands.add_parser("review", help="Record human accept/reject and reason for a finding")
    p.add_argument("workspace")
    p.add_argument("import_id")
    p.add_argument("finding")
    p.add_argument("--decision", choices=("accept", "reject"), required=True)
    p.add_argument("--reason", required=True)
    p.add_argument("--reviewer", required=True)
    for command, help_text in (("prefill", "Return finding template with author verification fields"),
                               ("author", "Replace a finding using existing report schema; preserves conflicts")):
        p = commands.add_parser(command, help=help_text)
        p.add_argument("workspace")
        p.add_argument("import_id")
        p.add_argument("finding")
        if command == "author":
            p.add_argument("input")
            p.add_argument("--base", type=int, required=True)
    for command, help_text in (("duplicates", "Suggest explainable duplicates without merging"),
                               ("complete", "Check report author/reviewer/rubric gaps")):
        p = commands.add_parser(command, help=help_text)
        p.add_argument("workspace")
        p.add_argument("import_id")
        if command == "complete":
            p.add_argument("--rubric", action="append", default=[])
    p = commands.add_parser("merge", help="Human merge; retain originals and reversible history")
    p.add_argument("workspace")
    p.add_argument("import_id")
    p.add_argument("primary")
    p.add_argument("secondary")
    p.add_argument("--actor", required=True)
    p.add_argument("--reason", required=True)
    p = commands.add_parser("undo-merge", help="Restore originals without overwriting later author changes")
    p.add_argument("workspace")
    p.add_argument("id")
    p.add_argument("--actor", required=True)
    for command, help_text in (("retest", "Record recommended/applied/verified remediation"),
                               ("incident", "Record linked incident timeline; never notifies"),
                               ("metric", "Record manually measured time/rework/errors")):
        p = commands.add_parser(command, help=help_text)
        p.add_argument("workspace")
        p.add_argument("input")
    p = commands.add_parser("snapshot", help="Create immutable Markdown/optional PDF draft and changes")
    p.add_argument("workspace")
    p.add_argument("import_id")
    p.add_argument("destination")
    p.add_argument("--pdf", action="store_true")
    p.add_argument("--reviewer")
    p.add_argument("--rubric", action="append", default=[])
    p = commands.add_parser("integrity", help="Explicit selected-file checksum check; no authenticity claim")
    p.add_argument("input")
    p.add_argument("sha256")
    p = commands.add_parser("status", help="Linked private status with acceptance states")
    p.add_argument("workspace")
    p.add_argument("--destination", help="new directory for JSON/Markdown export")
    p = commands.add_parser("handoff", help="Preview or create neutral synthetic cloud handoff; no transfer")
    p.add_argument("workspace")
    p.add_argument("destination")
    p.add_argument("--reviewer", required=True)
    p.add_argument("--approve-export", action="store_true")
    p.add_argument("--import-id")
    p = commands.add_parser("review-packet", help="Bundle settled source hashes and supplied verification record")
    p.add_argument("workspace")
    p.add_argument("destination")
    p.add_argument("evidence")
    p = commands.add_parser("package", help="Create allowlisted source-only preparation release")
    p.add_argument("destination")
    p = commands.add_parser("compare-releases", help="Inspect differences; preserve old release and rollback guidance")
    p.add_argument("first")
    p.add_argument("second")
    p = commands.add_parser("select-checks", help="Suggest affected checks; does not run a combined test command")
    p.add_argument("changed", nargs="+")
    return root


def dispatch(a):
    command = a.command
    if command == "search":
        options = {key: getattr(a, key) for key in ("platform", "runtime", "protocol", "privilege", "operation", "input", "output", "readiness", "disposition")}
        hits = catalog.search(a.query, **options)
        return {"results": hits if a.explain_excluded else [row for row in hits if row["eligible"]],
                "coverage_gap": not any(row["eligible"] for row in hits),
                "executed": False, "telemetry": False}
    if command == "choose": return catalog.choose(a.task)
    if command == "card":
        row = catalog.card(a.id)
        if a.workspace:
            assigned = ws.state(a.workspace)["owners"].get(a.id)
            if assigned: row["ownership"] = assigned
        return row
    if command == "compare": return catalog.compare(a.ids)
    if command == "init": return {"revision": ws.init(a.destination, a.owner)["revision"], "data_category": "synthetic"}
    if command == "preflight": return preflight(a.destination, a.require, a.platform, a.free_bytes)
    if command == "platforms":
        return {"Windows": {"runtime": "Python 3.10+; ReportLab optional for PDF", "status": "see verification.md", "needs": "write access to chosen output; font for PDF"},
                "Linux": {"runtime": "Python 3.10+; ReportLab optional for PDF", "status": "see verification.md", "needs": "write access; DejaVu/approved font for Unicode PDF"},
                "actual_event_hosts": "not tested", "upstream_tools": "use existing installer/runtime evidence"}
    if command == "scaffold": return delivery.scaffold(a.destination, a.name, a.owner, a.license)
    if command == "check-docs": return delivery.check_scaffold(a.directory)
    if command == "check-links": return delivery.check_links(a.paths)
    if command == "intake":
        item = load(a.input)
        need(isinstance(item, dict), "invalid_request")
        item["reuse_results"] = [row["id"] for row in catalog.search(item.get("reuse_query", item.get("problem", ""))) if row["eligible"]]
        item["reuse_check"] = "existing catalog searched; user must justify duplicate development or coverage gap"
        return ws.intake(a.workspace, item)
    if command == "decision": return ws.decision(a.workspace, load(a.input))
    if command == "handling": return ws.handling(a.workspace, load(a.input))
    if command == "owner": return ws.owner(a.workspace, a.capability, a.primary, a.backup, a.reviewer)
    if command == "transfer": return ws.transfer(a.workspace, a.capability, a.base, a.actor, a.new_owner)
    if command == "note": return ws.add(a.workspace, "notes", load(a.input))
    if command == "edit-note": return ws.edit(a.workspace, "notes", a.id, load(a.input), a.base)
    if command == "show": return ws.get(a.workspace, a.collection, a.id)
    if command == "plan": return operations.plan(a.workspace, load(a.input))
    if command == "revalidate": return operations.revalidate(a.workspace, a.id, load(a.input), a.reviewer, a.accept_change)
    if command == "deviation": return operations.deviation(a.workspace, a.id, a.reason, a.approval_ref, a.actor)
    if command == "run-record": return operations.record_run(a.workspace, a.tool, a.version, a.operator, a.status, a.exit_code, a.stage, a.profile, a.binary_sha256, a.config_sha256, a.limitations, a.scope_ref, a.evidence_ref, a.plan_id)
    if command == "event": return operations.stage_event(a.workspace, a.id, a.stage, a.status, a.code, a.exit_code)
    if command == "simulate": return operations.simulate(a.workspace, a.seconds)
    if command == "cancel": return operations.cancel(a.workspace, a.id)
    if command == "resume": return operations.resume(a.workspace, a.id, a.disposition, a.actor)
    if command == "preview-import": return reports.preview(a.input)
    if command == "import-report": return reports.import_report(a.workspace, a.input)
    if command == "review": return reports.review(a.workspace, a.import_id, a.finding, a.decision, a.reason, a.reviewer)
    if command == "prefill": return reports.prefill(a.workspace, a.import_id, a.finding)
    if command == "author": return reports.author(a.workspace, a.import_id, a.finding, load(a.input), a.base)
    if command == "duplicates": return reports.duplicates(a.workspace, a.import_id)
    if command == "merge": return reports.merge(a.workspace, a.import_id, a.primary, a.secondary, a.actor, a.reason)
    if command == "undo-merge": return reports.undo_merge(a.workspace, a.id, a.actor)
    if command == "complete": return reports.completeness(a.workspace, a.import_id, a.rubric)
    if command == "retest": return reports.retest(a.workspace, load(a.input))
    if command == "incident": return reports.incident(a.workspace, load(a.input))
    if command == "metric": return ws.metric(a.workspace, load(a.input))
    if command == "snapshot": return reports.snapshot(a.workspace, a.import_id, a.destination, a.pdf, a.reviewer, a.rubric)
    if command == "integrity": return reports.integrity(a.input, a.sha256)
    if command == "status":
        result = ws.status(a.workspace)
        if a.destination:
            content = encoded(delivery.scrub(result))
            markdown = "# Synthetic private status\n\n```json\n" + content.decode().replace("```", "[literal backticks]") + "```\n"
            bundle(a.destination, {"status.json": content, "status.md": markdown.encode()})
        return result
    if command == "handoff": return delivery.handoff(a.workspace, a.destination, a.reviewer, a.approve_export, a.import_id)
    if command == "review-packet": return delivery.review_packet(a.workspace, a.destination, a.evidence)
    if command == "package": return delivery.package(a.destination)
    if command == "compare-releases": return delivery.compare_packages(a.first, a.second)
    if command == "select-checks":
        checks = set()
        for path in a.changed:
            if "catalog" in path: checks.add("WorkbenchTests.test_catalog")
            if "report" in path: checks.update(("WorkbenchTests.test_report_workflow", "existing reporting tests"))
            if "operation" in path: checks.add("WorkbenchTests.test_operations")
            if "workspace" in path or "common" in path: checks.add("WorkbenchTests.test_conflicts")
            if "delivery" in path: checks.add("WorkbenchTests.test_delivery")
        return {"suggested": sorted(checks or {"inspect changed behavior and choose relevant workbench checks"}),
                "integration": "Include affected actual CLI path and compatibility checks", "omissions": "Review dependencies; this suggestion is not proof omitted checks are irrelevant", "executed": False}
    raise Error("unknown_command")


def main(argv=None):
    args = parser().parse_args(argv)
    try:
        result = dispatch(args)
        print(json.dumps(delivery.scrub(result), ensure_ascii=True, sort_keys=True, indent=2))
        if isinstance(result, dict) and (result.get("conflict") or result.get("ready") is False
                                       or result.get("consistent") is False or result.get("matches") is False
                                       or result.get("ready_for_reviewed_training_copy") is False):
            return 3
        return 0
    except Error as error:
        print("Workbench rejected: " + str(error), file=sys.stderr)
        return 2
    except (Exception, KeyboardInterrupt):
        print("Workbench failed: check the input contract, local permissions, workspace lock and dependencies. No target or cloud action was dispatched.", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
