"""Manual operation records and a fixed synthetic process supervisor."""
from __future__ import annotations

import os
import signal
import subprocess
import sys
import time
from copy import deepcopy

from common import digest, encoded, identity, need, now, output_path, redact, text
import workspace as ws

STATUSES = ("queued", "running", "success", "partial", "failed", "cancelled", "not_run")


def plan(directory, record):
    record = deepcopy(record)
    for key in ("command", "scope_ref", "profile", "effects", "limits", "destination"):
        text(record.get(key), 4000)
    for key in ("targets", "approved_targets", "excluded_targets", "discovered"):
        need(isinstance(record.get(key, []), list) and len(record.get(key, [])) <= 200, "invalid_target_list")
        for value in record.get(key, []):
            text(value, 240)
        record.setdefault(key, [])
    output_path(record["destination"])
    original = digest(encoded(record))
    record["command"] = redact(record["command"])
    allowed = set(record["targets"]) <= set(record["approved_targets"])
    allowed &= not bool(set(record["targets"]) & set(record["excluded_targets"]))
    record.update(input_sha256=original, plan_sha256=digest(encoded(record)),
                  validated=bool(allowed and record["targets"]), executed=False,
                  validation_basis="operator-supplied scope metadata, not authorization", status="preview")
    return ws.add(directory, "plans", record)


def revalidate(directory, identifier, current, reviewer, accept_change=False):
    previous = ws.get(directory, "plans", identifier)
    text(reviewer, 120)
    allowed_fields = {"scope_ref", "profile", "targets", "approved_targets", "excluded_targets"}
    need(isinstance(current, dict) and set(current) == allowed_fields, "unsupported_revalidation_fields")
    text(current["scope_ref"], 240)
    text(current["profile"], 240)
    for key in ("scope_ref", "profile", "targets", "approved_targets", "excluded_targets"):
        need(key in current, "revalidation_fields_missing")
    for key in ("targets", "approved_targets", "excluded_targets"):
        need(isinstance(current[key], list) and all(isinstance(item, str) for item in current[key]), "invalid_target_list")
    changed = any(previous.get(key) != current[key] for key in current)
    valid = bool(current["targets"]) and set(current["targets"]) <= set(current["approved_targets"])
    valid &= not bool(set(current["targets"]) & set(current["excluded_targets"]))
    valid &= not changed or accept_change
    patch = {"validated": bool(valid), "revalidated_by": reviewer,
             "changed_since_preview": changed, "status": "preview" if valid else "needs_review",
             "current_scope_sha256": digest(encoded(current))}
    if valid:
        patch.update({key: deepcopy(current[key]) for key in current})
    return ws.edit(directory, "plans", identifier, patch, previous["revision"])


def deviation(directory, plan_id, reason, approval_ref, actor):
    ws.get(directory, "plans", plan_id)
    for value in (reason, approval_ref, actor):
        text(value, 2000)
    return ws.add(directory, "notes", {"kind": "profile_deviation", "plan": plan_id,
                  "reason": reason, "approval_ref": approval_ref, "actor": actor,
                  "status": "exception-recorded; original-profile acceptance not inherited"})


def record_run(directory, tool, version, operator, status, exit_code=None, stage="tool",
               profile="manual", binary_sha256="unknown", config_sha256="unknown", limitations="Not independently verified",
               scope_ref="not supplied", evidence_refs=(), plan_id=None):
    for value in (tool, version, operator, profile, binary_sha256, config_sha256, limitations):
        text(value, 2000)
    need(status in STATUSES and stage in ("tool", "import", "render"), "invalid_run_status")
    need(exit_code is None or type(exit_code) is int, "invalid_exit_code")
    need(status != "success" or exit_code == 0, "success_requires_zero_exit")
    need(status not in ("partial", "failed", "not_run", "cancelled") or bool(limitations.strip()), "limitations_required")
    text(scope_ref, 240)
    need(isinstance(evidence_refs, (list, tuple)) and len(evidence_refs) <= 50, "invalid_evidence_references")
    for reference in evidence_refs:
        text(reference, 240)
    if plan_id:
        ws.get(directory, "plans", plan_id)
    row = {"tool": tool, "tool_version": version, "operator": operator, "status": status,
           "exit_code": exit_code, "stage": stage, "profile": profile,
           "binary_sha256": binary_sha256, "config_sha256": config_sha256,
           "limitations": limitations, "kind": "manual", "data_category": "synthetic",
           "scope_ref": scope_ref, "evidence_refs": list(evidence_refs), "plan": plan_id}
    result = ws.add(directory, "runs", row)
    stage_event(directory, result["id"], stage, status, "recorded", exit_code)
    return ws.get(directory, "runs", result["id"])


def stage_event(directory, run_id, stage, status, code, exit_code=None):
    need(stage in ("tool", "import", "render"), "invalid_stage")
    need(status in STATUSES, "invalid_run_status")
    text(code, 100)
    need(exit_code is None or type(exit_code) is int, "invalid_exit_code")
    need(status != "success" or exit_code == 0, "success_requires_zero_exit")
    def action(value):
        need(run_id in value["runs"], "run_missing")
        run = value["runs"][run_id]
        ws.event(value, stage, status, run_id)
        event = value["events"][next(reversed(value["events"]))]
        event.update(stage=stage, exit_code=exit_code, operator=redact(run["operator"]),
                     tool=redact(run["tool"]), profile=redact(run["profile"]),
                     binary_sha256=run["binary_sha256"], config_sha256=run["config_sha256"],
                     scope_ref=redact(run.get("scope_ref", "not supplied")), plan=run.get("plan"),
                     evidence_refs=[redact(ref) for ref in run.get("evidence_refs", [])],
                     diagnostic_code=redact(code))
        run.setdefault("stages", {})[stage] = {"status": status, "exit_code": exit_code,
                                               "diagnostic_code": redact(code), "updated_at": now()}
        run.update(revision=run["revision"] + 1, updated_at=now())
        return event
    return ws.change(directory, action)


def cancel(directory, identifier):
    run = ws.get(directory, "runs", identifier)
    need(run["status"] == "running", "run_not_running")
    if run["kind"] != "synthetic_supervisor":
        return {"stopped": False, "next_action": "Use the external runner stop control; record its actual outcome"}
    return ws.edit(directory, "runs", identifier, {"cancel_requested": True}, run["revision"])


def stop_group(process):
    if os.name == "nt":
        if process.poll() is None:
            executable = os.path.join(os.environ.get("SystemRoot", r"C:\Windows"), "System32", "taskkill.exe")
            result = subprocess.run([executable, "/PID", str(process.pid), "/T", "/F"],
                                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                                    creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
            need(result.returncode == 0 or process.poll() is not None, "child_cleanup_failed")
    else:
        try:
            os.killpg(process.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
    try:
        process.wait(timeout=5)
    except subprocess.TimeoutExpired:
        if os.name == "nt":
            process.kill()
        else:
            os.killpg(process.pid, signal.SIGKILL)
        process.wait(timeout=5)


def simulate(directory, seconds=2):
    """Only this fixed sleep worker is launched. No imported command is dispatched."""
    need(type(seconds) in (int, float) and 0.2 <= seconds <= 30, "invalid_simulation_duration")
    run = record_run(directory, "fixed synthetic worker", "1", "synthetic operator", "running")
    run = ws.edit(directory, "runs", run["id"], {"kind": "synthetic_supervisor"}, run["revision"])
    worker = "import subprocess,sys,time; child=subprocess.Popen([sys.executable,'-c','import time; time.sleep(120)']); print(child.pid,flush=True); time.sleep(120)"
    options = {"creationflags": subprocess.CREATE_NEW_PROCESS_GROUP | subprocess.CREATE_NO_WINDOW} if os.name == "nt" else {"start_new_session": True}
    process = None
    status = "success"
    try:
        process = subprocess.Popen([sys.executable, "-c", worker], stdout=subprocess.PIPE,
                                   stderr=subprocess.DEVNULL, stdin=subprocess.DEVNULL, **options)
        child_pid = int(process.stdout.readline(32))
        latest = ws.get(directory, "runs", run["id"])
        ws.edit(directory, "runs", run["id"], {"child_pid": child_pid}, latest["revision"])
        deadline = time.monotonic() + seconds
        while time.monotonic() < deadline:
            if ws.get(directory, "runs", run["id"]).get("cancel_requested"):
                status = "cancelled"
                break
            need(process.poll() is None, "synthetic_worker_exited")
            time.sleep(0.05)
    except KeyboardInterrupt:
        status = "cancelled"
    except Exception:
        status = "failed"
    finally:
        if process is not None:
            stop_group(process)
            if process.stdout is not None:
                process.stdout.close()
        latest = ws.get(directory, "runs", run["id"])
        result = ws.edit(directory, "runs", run["id"], {"status": status,
                         "exit_code": 0 if status == "success" else None,
                         "cleanup": process is not None and process.poll() is not None,
                         "limitations": "Fixed synthetic worker only; no actual assessment-tool integration"}, latest["revision"])
        stage_event(directory, run["id"], "tool", status, "synthetic_supervision", 0 if status == "success" else None)
    return result


def resume(directory, identifier, disposition, actor):
    run = ws.get(directory, "runs", identifier)
    need(run["status"] in ("partial", "failed", "cancelled", "not_run"), "run_not_resumable")
    need(disposition in ("repeat", "skip"), "explicit_resume_disposition_required")
    text(actor, 120)
    return ws.add(directory, "notes", {"kind": "resume_decision", "run": identifier,
                  "disposition": disposition, "actor": actor, "executed": False,
                  "next_action": "Operator must explicitly start a separately authorized attempt" if disposition == "repeat" else "Retain coverage limitation"})
