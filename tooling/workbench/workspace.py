"""Revision-safe synthetic workflow records, without a collaboration server."""
from __future__ import annotations

from copy import deepcopy
from datetime import datetime, timezone
from pathlib import Path

from common import VERSION, WORKSPACE_VERSION, atomic, bundle, encoded, identity, load, locked, need, now, output_path, text

COLLECTIONS = ("requests", "decisions", "notes", "conflicts", "plans", "runs", "reviews", "merges",
               "retests", "incidents", "metrics", "snapshots", "imports", "owners", "events")
MARKINGS = ("ORCON", "PROPIN", "PII", "PII Red", "FI")


def inherit(value, tags):
    need(isinstance(tags, list) and all(tag in MARKINGS for tag in tags), "invalid_markings")
    combined = set(value["markings"]) | set(tags) | {"ORCON"}
    if "PII Red" in combined:
        combined.discard("PII")
    value["markings"] = [tag for tag in MARKINGS if tag in combined]


def init(destination, owner):
    text(owner, 120)
    state = {"version": WORKSPACE_VERSION, "data_category": "synthetic", "revision": 0, "owner": owner,
             "created_at": now(), "markings": ["ORCON"], "log_truncated": False,
             "handling": {"custodian": owner, "retention": "unresolved", "export": "human decision",
                          "deletion": "separately authorized, no automatic deletion"},
             **{key: {} for key in COLLECTIONS}}
    bundle(destination, {"state.json": encoded(state)})
    return state


def state(directory):
    value = load(output_path(directory) / "state.json")
    need(isinstance(value, dict) and value.get("version") == WORKSPACE_VERSION
         and value.get("data_category") == "synthetic", "unsupported_workspace")
    need(type(value.get("revision")) is int and value["revision"] >= 0, "invalid_revision")
    need(all(isinstance(value.get(key), dict) for key in COLLECTIONS), "invalid_workspace")
    for collection in COLLECTIONS:
        for record in value[collection].values():
            synthetic_record(record)
    return value


def synthetic_record(record):
    need(isinstance(record, dict) and record.get("data_category", "synthetic") == "synthetic",
         "synthetic_record_required")


def change(directory, action, expected=None):
    directory = output_path(directory)
    with locked(directory):
        value = state(directory)
        need(expected is None or value["revision"] == expected, "revision_conflict")
        before = encoded(value)
        result = action(value)
        if encoded(value) == before:
            return result
        value["revision"] += 1
        atomic(directory / "state.json", value)
        return result


def event(value, action, status, reference=""):
    identifier = identity("event")
    # Only caller-built concise metadata, never raw input or process output.
    value["events"][identifier] = {"time": now(), "sequence": value["revision"] + 1,
                                    "action": action, "status": status, "reference": reference}
    if len(value["events"]) > 500:
        oldest = min(value["events"], key=lambda key: value["events"][key].get("sequence", 0))
        del value["events"][oldest]
        value["log_truncated"] = True


def add(directory, collection, record, expected=None):
    need(collection in COLLECTIONS and collection not in ("events", "conflicts"), "unsupported_collection")
    need(isinstance(record, dict), "invalid_record")
    synthetic_record(record)
    identifier = record.get("id", identity(collection[:-1] or "item"))
    text(identifier, 64)
    def action(value):
        need(identifier not in value[collection], "record_exists")
        item = deepcopy(record)
        item.update(id=identifier, updated_at=now(), revision=1)
        inherit(value, item.get("markings", []))
        value[collection][identifier] = item
        event(value, "add_" + collection, "recorded", identifier)
        return item
    return change(directory, action, expected)


def get(directory, collection, identifier):
    value = state(directory)
    need(collection in COLLECTIONS and identifier in value[collection], "record_missing")
    return value[collection][identifier]


def edit(directory, collection, identifier, patch, base_revision):
    need(collection in COLLECTIONS and isinstance(patch, dict)
         and not ({"id", "revision", "updated_at"} & patch.keys()), "invalid_edit")
    synthetic_record(patch)
    def action(value):
        need(identifier in value[collection], "record_missing")
        current = value[collection][identifier]
        if current["revision"] != base_revision:
            conflict = {"id": identity("conflict"), "collection": collection, "record": identifier,
                        "current": deepcopy(current), "proposed_patch": deepcopy(patch), "time": now()}
            value["conflicts"][conflict["id"]] = conflict
            inherit(value, patch.get("markings", []))
            return {"conflict": conflict["id"], "current_revision": current["revision"]}
        inherit(value, patch.get("markings", []))
        current.update(deepcopy(patch))
        current.update(revision=current["revision"] + 1, updated_at=now())
        event(value, "edit_" + collection, "recorded", identifier)
        return current
    return change(directory, action)


def intake(directory, request):
    fields = ("problem", "user", "input", "output", "acceptance", "owner", "backup", "reviewer", "kind")
    need(all(key in request for key in fields), "request_fields_missing")
    for key in fields:
        text(request[key], 2000)
    need(request["kind"] in ("tool", "adapter", "repair", "documentation", "retirement"), "invalid_request_kind")
    for key in ("value", "frequency", "effort", "risk", "confidence"):
        number = request.get(key)
        need(type(number) in (int, float) and 1 <= number <= 5, "invalid_priority_score")
    request = deepcopy(request)
    request["priority_score"] = round(request["value"] * request["frequency"] * request["confidence"] /
                                      (request["effort"] * request["risk"]), 3)
    request["priority_basis"] = "value * frequency * confidence / (effort * risk); estimates, not measured gains"
    request.setdefault("dependencies", [])
    request.setdefault("reuse_check", "pending: search catalog and prior decisions")
    return add(directory, "requests", request)


def decision(directory, record):
    for key in ("topic", "owner", "choice", "reason"):
        text(record.get(key), 2000)
    need(record["choice"] in ("accepted", "rejected", "deferred", "blocked"), "invalid_decision")
    if record["choice"] in ("deferred", "blocked"):
        text(record.get("trigger"), 2000)
        text(record.get("benefit"), 2000)
    return add(directory, "decisions", record)


def owner(directory, capability, primary, backup, reviewer):
    for item in (capability, primary, backup, reviewer):
        text(item, 120)
    return add(directory, "owners", {"id": capability, "owner": primary, "backup": backup,
                                    "reviewer": reviewer, "status": "assigned"})


def transfer(directory, capability, base_revision, actor, new_owner=None):
    text(actor, 120)
    if new_owner is not None:
        text(new_owner, 120)
    return edit(directory, "owners", capability, {"owner": new_owner or "unassigned",
                "status": "transferred" if new_owner else "released", "changed_by": actor}, base_revision)


def metric(directory, record):
    for key in ("task", "operator", "environment"):
        text(record.get(key), 200)
    for key in ("seconds", "search_misses", "retyping", "duplicate_work", "review_corrections", "errors"):
        value = record.get(key, 0)
        need(type(value) in (int, float) and 0 <= value < 1e9, "invalid_metric")
    record = dict(record, collection="manual entry; no search telemetry")
    return add(directory, "metrics", record)


def handling(directory, record):
    need(isinstance(record, dict) and set(record) <= {"custodian", "retention", "export", "deletion"}, "invalid_handling_record")
    for value in record.values():
        text(value, 2000)
    def action(value):
        value["handling"].update(record)
        return {"handling": value["handling"], "performed_transfer_or_deletion": False}
    return change(directory, action)


def status(directory):
    return status_value(state(directory))


def status_value(value):
    """Describe one loaded workspace snapshot without independently rereading it."""
    return {"version": VERSION, "revision": value["revision"], "updated_at": now(),
            "data_category": "synthetic", "markings": value["markings"],
            "counts": {key: len(value[key]) for key in COLLECTIONS if key != "events"},
            "records": {key: [{"id": item.get("id", identifier), "revision": item.get("revision"),
                               "updated_at": item.get("updated_at"),
                               "age_seconds": max(0, round((datetime.now(timezone.utc) - datetime.fromisoformat(item["updated_at"])).total_seconds())) if item.get("updated_at") else None,
                               "status": item.get("status", "recorded")}
                              for identifier, item in value[key].items()]
                        for key in ("requests", "owners", "runs", "snapshots", "incidents")},
            "log_truncated": value["log_truncated"],
            "acceptance": {"implementation": "see verification", "user": "pending", "event": "pending"},
            "next_action": "Resolve blockers, review candidates and inspect actual records; no automatic dispatch"}
