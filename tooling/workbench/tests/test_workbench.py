"""Acceptance paths for the approved workbench; no scans, installs or model calls."""
from __future__ import annotations

import copy
import ctypes
import io
import json
import os
import socket
import subprocess
import sys
import tempfile
import threading
import time
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path
from unittest.mock import patch

MODULE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(MODULE))
import catalog
import common
import delivery
import operations
import reports
import workbench
import workspace as ws


class WorkbenchTests(unittest.TestCase):
    def setUp(self):
        base = Path(os.environ.get("CPTC_TEST_TMP", common.ROOT / "tmp/workbench-tests"))
        base.mkdir(parents=True, exist_ok=True)
        self.temporary = tempfile.TemporaryDirectory(dir=base)
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.directory = self.root / "workspace"
        ws.init(self.directory, "Synthetic owner")
        self.fixture = common.ROOT / "tooling/reporting/examples/report-marked.json"

    def file(self, name, data):
        path = self.root / name
        path.write_bytes(common.encoded(data))
        return path

    def imported(self, duplicate=False, legacy=False):
        source = common.load(self.fixture)
        if legacy:
            source = common.load(common.ROOT / "tooling/reporting/examples/report.json")
        if duplicate:
            finding = copy.deepcopy(source["findings"][0])
            finding["id"] = "F-SYNTHETIC-DUPLICATE"
            finding["evidence"][0]["id"] = "E-SYNTHETIC-DUPLICATE"
            source["findings"].append(finding)
        result = reports.import_report(self.directory, self.file("input.json", source))
        return result["id"], source

    def test_catalog(self):
        expected = {"linpeas": "TOOL-001", "winpeas": "TOOL-002", "wireshark": "TOOL-003",
                    "pcap": "TOOL-003", "modbus": "TOOL-013", "opcua": "TOOL-020",
                    "super nmap": "LEGACY-NMAP", "report generator": "HELPER-REPORT",
                    "development workbench": "HELPER-WORKBENCH", "linux enumeration": "TOOL-001"}
        for query, identifier in expected.items():
            self.assertIn(identifier, [row["id"] for row in catalog.search(query)], query)
        self.assertEqual(len(catalog.tools()), 43)
        incompatible = catalog.search("winpeas", platform="linux")
        self.assertFalse(incompatible[0]["eligible"])
        self.assertIn("platform:incompatible", incompatible[0]["reasons"])
        self.assertTrue(all(not row["eligible"] for row in catalog.search(readiness="ready")))
        self.assertEqual(catalog.card("TOOL-001")["disposition"], "hold")
        self.assertFalse(catalog.card("TOOL-001")["ready"])
        retired = next(row for row in catalog.search("open dnp3") if row["id"] == "TOOL-028")
        self.assertEqual(retired["lifecycle"]["state"], "archived")
        self.assertIn("gap", retired["lifecycle"]["gap"].lower())
        self.assertIsNone(retired["lifecycle"]["replacement"])
        for tool in catalog.tools():
            self.assertEqual(set(tool["readiness"]), {"cataloged", "downloaded", "integrity_checked", "tested",
                                                    "reviewed", "accepted", "published", "event_approved"})
            self.assertEqual(tool["readiness"]["accepted"], "pending")
            self.assertEqual(tool["readiness"]["event_approved"], "pending")
        self.assertEqual(catalog.card("TOOL-028")["readiness"]["downloaded"], "not_acquired")
        self.assertNotEqual(catalog.card("TOOL-028")["readiness"]["reviewed"], "accepted")
        self.assertEqual(len(catalog.compare(["TOOL-013", "TOOL-014"])), 2)
        self.assertTrue(catalog.choose("unsupported fictional protocol")['coverage_gap'])
        for task in ("analyze existing capture", "windows host", "linux host", "modbus endpoint", "opc ua endpoint", "render report"):
            self.assertFalse(catalog.choose(task)["coverage_gap"], task)

    def test_intake_and_decisions(self):
        request = {key: "synthetic " + key for key in ("problem", "user", "input", "output", "acceptance", "owner", "backup", "reviewer")}
        request.update(kind="tool", value=5, frequency=4, confidence=3, effort=2, risk=1)
        row = ws.intake(self.directory, request)
        self.assertEqual(row["priority_score"], 30)
        with self.assertRaises(common.Error):
            ws.decision(self.directory, {"topic": "choice", "owner": "owner", "choice": "deferred", "reason": "waiting"})
        row = ws.decision(self.directory, {"topic": "choice", "owner": "owner", "choice": "deferred", "reason": "waiting", "trigger": "fixture received", "benefit": "less retyping"})
        self.assertEqual(row["choice"], "deferred")
        request_path = self.file("request.json", dict(request, problem="modbus", reuse_query="modbus"))
        with redirect_stdout(io.StringIO()):
            self.assertEqual(workbench.main(["intake", str(self.directory), str(request_path)]), 0)
        self.assertTrue(any(row.get("reuse_results") for row in ws.state(self.directory)["requests"].values()))

    def test_conflicts(self):
        row = ws.add(self.directory, "notes", {"body": "first", "actor": "A"})
        ws.edit(self.directory, "notes", row["id"], {"body": "second", "actor": "B"}, 1)
        result = ws.edit(self.directory, "notes", row["id"], {"body": "third", "actor": "C"}, 1)
        self.assertIn("conflict", result)
        self.assertEqual(ws.get(self.directory, "notes", row["id"])["body"], "second")
        conflict = ws.state(self.directory)["conflicts"][result["conflict"]]
        self.assertEqual(conflict["proposed_patch"]["body"], "third")
        with self.assertRaises(common.Error):
            ws.change(self.directory, lambda _: None, expected=0)

    def test_owners_and_handling(self):
        row = ws.owner(self.directory, "TOOL-013", "A", "B", "R")
        result = ws.transfer(self.directory, row["id"], 1, "A", "B")
        self.assertEqual(result["owner"], "B")
        self.assertIn("age_seconds", ws.status(self.directory)["records"]["owners"][0])
        result = ws.handling(self.directory, {"custodian": "Data owner", "retention": "pending event decision"})
        self.assertFalse(result["performed_transfer_or_deletion"])

    def test_scaffold_and_preflight(self):
        destination = self.root / "new-tool"
        delivery.scaffold(destination, "test_tool", "Training author")
        self.assertTrue(delivery.check_scaffold(destination)["consistent"])
        actual = subprocess.run([sys.executable, "-B", str(destination / "tool.py"), "--help"], capture_output=True, text=True)
        self.assertEqual(actual.returncode, 0)
        self.assertIn("--input", actual.stdout)
        actual = subprocess.run([sys.executable, "-B", str(destination / "tool.py")], capture_output=True)
        self.assertEqual(actual.returncode, 3)
        metadata = common.load(destination / "METADATA.json")
        metadata["version"] = "9.0"
        (destination / "METADATA.json").write_bytes(common.encoded(metadata))
        self.assertFalse(delivery.check_scaffold(destination)["consistent"])
        with patch("socket.socket", side_effect=AssertionError("network forbidden")), patch("subprocess.Popen", side_effect=AssertionError("process forbidden")):
            self.assertFalse(common.preflight(self.root / "fresh", ["cptc-synthetic-missing-executable"])["ready"])
            self.assertTrue(catalog.search("modbus"))
            self.assertFalse(reports.preview(self.fixture)["mutated"])
        with self.assertRaises(common.Error):
            delivery.scaffold(destination, "test_tool", "Training author")

    def plan(self):
        return {"command": "synthetic-tool --token=CANARY-PRIVATE --target 192.0.2.1",
                "scope_ref": "synthetic-scope-v1", "profile": "operator supplied", "effects": "not run",
                "limits": "external runbook", "destination": str(self.root / "operation-output"),
                "targets": ["192.0.2.1"], "approved_targets": ["192.0.2.1"],
                "excluded_targets": [], "discovered": ["192.0.2.2"]}

    def test_operations(self):
        with patch("subprocess.Popen", side_effect=AssertionError("no dispatch")), patch("socket.getaddrinfo", side_effect=AssertionError("no DNS")):
            plan = operations.plan(self.directory, self.plan())
            self.assertTrue(plan["validated"])
            self.assertNotIn("CANARY-PRIVATE", plan["command"])
            self.assertNotIn("192.0.2.2", plan["approved_targets"])
            current = {key: plan[key] for key in ("scope_ref", "profile", "targets", "approved_targets", "excluded_targets")}
            current["scope_ref"] = "synthetic-scope-v2"
            row = operations.revalidate(self.directory, plan["id"], current, "Reviewer")
            self.assertFalse(row["validated"])
            row = operations.revalidate(self.directory, plan["id"], current, "Reviewer", True)
            self.assertTrue(row["validated"])
            current["targets"] = ["192.0.2.50"]
            self.assertFalse(operations.revalidate(self.directory, plan["id"], current, "Reviewer", True)["validated"])
        run = operations.record_run(self.directory, "synthetic", "1", "token=CANARY-PRIVATE", "failed", 7)
        event = operations.stage_event(self.directory, run["id"], "render", "failed", "token=CANARY-PRIVATE")
        self.assertNotIn("CANARY-PRIVATE", json.dumps(event))
        with self.assertRaises(common.Error):
            operations.record_run(self.directory, "synthetic", "1", "author", "success", 7)
        result = operations.resume(self.directory, run["id"], "skip", "author")
        self.assertFalse(result["executed"])
        self.assertFalse(operations.deviation(self.directory, plan["id"], "synthetic exception", "external-approval", "author")["status"].startswith("accepted"))

    @staticmethod
    def alive(pid):
        if os.name == "nt":
            kernel = ctypes.windll.kernel32
            kernel.OpenProcess.restype = ctypes.c_void_p
            handle = kernel.OpenProcess(0x100000, False, pid)
            if not handle:
                return False
            try:
                return kernel.WaitForSingleObject(ctypes.c_void_p(handle), 0) == 258
            finally:
                kernel.CloseHandle(ctypes.c_void_p(handle))
        try:
            os.kill(pid, 0)
            stat = Path(f"/proc/{pid}/stat")
            return not stat.exists() or stat.read_text().split(") ", 1)[1][0] != "Z"
        except ProcessLookupError:
            return False

    def test_cancel_owned_worker(self):
        results = []
        thread = threading.Thread(target=lambda: results.append(operations.simulate(self.directory, 8)))
        thread.start()
        self.addCleanup(thread.join, 15)
        run = None
        deadline = time.monotonic() + 6
        while time.monotonic() < deadline:
            rows = list(ws.state(self.directory)["runs"].values())
            if rows and rows[-1].get("child_pid"):
                run = rows[-1]
                break
            time.sleep(0.05)
        self.assertIsNotNone(run)
        operations.cancel(self.directory, run["id"])
        thread.join(10)
        self.assertFalse(thread.is_alive())
        self.assertEqual(results[0]["status"], "cancelled")
        self.assertTrue(results[0]["cleanup"])
        self.assertFalse(self.alive(run["child_pid"]))

    def test_report_workflow(self):
        imported, original = self.imported(duplicate=True)
        duplicate = reports.import_report(self.directory, self.root / "input.json")
        self.assertTrue(duplicate["duplicate"])
        self.assertTrue(reports.duplicates(self.directory, imported))
        ids = [f["id"] for f in original["findings"]]
        finding = reports.prefill(self.directory, imported, ids[0])
        self.assertFalse(finding["confirmed_by_template"])
        merged = reports.merge(self.directory, imported, ids[0], ids[-1], "Reviewer", "same synthetic observation")
        self.assertTrue(merged["active"])
        self.assertFalse(reports.undo_merge(self.directory, merged["id"], "Reviewer")["active"])
        for identifier in ids:
            reports.review(self.directory, imported, identifier, "accept", "synthetic manual validation", "Reviewer")
        self.assertTrue(reports.completeness(self.directory, imported)["ready_for_reviewed_training_copy"])
        current = ws.get(self.directory, "imports", imported)
        replacement = copy.deepcopy(current["report"]["findings"][0])
        replacement["business_impact"] = "Revised synthetic impact."
        reports.author(self.directory, imported, replacement["id"], replacement, current["revision"])
        self.assertFalse(reports.completeness(self.directory, imported)["ready_for_reviewed_training_copy"])
        conflict = reports.author(self.directory, imported, replacement["id"], replacement, current["revision"])
        self.assertIn("conflict", conflict)

    def test_snapshot_status_and_integrity(self):
        imported, source = self.imported(legacy=True)
        run = operations.record_run(self.directory, "synthetic source", "1", "author", "failed", 2)
        reports.incident(self.directory, {"run": run["id"], "summary": "Invented interruption", "actor": "author", "markings": ["FI"]})
        finding_id = source["findings"][0]["id"]
        with self.assertRaises(common.Error):
            reports.retest(self.directory, {"finding": finding_id, "status": "verified", "actor": "author", "summary": "No proof"})
        reports.retest(self.directory, {"finding": finding_id, "status": "applied", "actor": "author", "summary": "Invented application"})
        first = reports.snapshot(self.directory, imported, self.root / "draft-1")
        markdown = (self.root / "draft-1/report.md").read_text(encoding="utf-8")
        self.assertIn("status\\=failed", markdown)
        self.assertIn("ORCON//FI", markdown)
        self.assertIn("notification\\=pending", markdown)
        for name, expected in first["manifest"]["artifacts"].items():
            self.assertEqual(common.digest((self.root / "draft-1" / name).read_bytes()), expected)
        self.assertTrue(reports.integrity(self.fixture, common.digest(self.fixture.read_bytes()))["matches"])
        self.assertFalse(reports.integrity(self.fixture, "0" * 64)["matches"])
        operations.record_run(self.directory, "other synthetic", "1", "author", "not_run")
        second = reports.snapshot(self.directory, imported, self.root / "draft-2")
        self.assertEqual(len(second["changes"]["runs"]["added"]), 1)
        self.assertFalse(ws.status(self.directory)["acceptance"]["event"] == "accepted")
        with self.assertRaises(common.Error):
            reports.snapshot(self.directory, imported, self.root / "draft-1")

    def test_pdf_marking_and_literal_appendix(self):
        try:
            import reportlab
            from pypdf import PdfReader
        except ImportError:
            self.skipTest("optional PDF QA packages unavailable")
        imported, _ = self.imported()
        run = operations.record_run(self.directory, "synthetic <literal>", "1", "author", "partial", 0, limitations="Literal <script>not active</script>")
        reports.incident(self.directory, {"run": run["id"], "summary": "Synthetic incident", "actor": "author", "markings": ["FI"]})
        result = reports.snapshot(self.directory, imported, self.root / "pdf", pdf=True)
        pages = PdfReader(self.root / "pdf/report.pdf").pages
        combined = "\n".join(page.extract_text() for page in pages)
        self.assertIn("status=partial", combined)
        self.assertIn("<script>not active</script>", combined)
        for page in pages:
            self.assertIn("ORCON//PROPIN//PII Red//FI", page.extract_text())
        self.assertEqual(result["manifest"]["effective_markings"], "ORCON//PROPIN//PII Red//FI")

    def test_delivery(self):
        imported, _ = self.imported()
        operations.record_run(self.directory, "synthetic", "1", "operator", "not_run")
        preview = delivery.handoff(self.directory, self.root / "handoff", "Reviewer", import_id=imported)
        self.assertFalse(preview["written"])
        result = delivery.handoff(self.directory, self.root / "handoff", "Reviewer", True, imported)
        self.assertFalse(result["transferred"])
        handoff = common.load(self.root / "handoff/handoff.json")
        self.assertFalse(handoff["local_ai"])
        self.assertEqual(handoff["markings"], ["ORCON", "PROPIN", "PII Red", "FI"])
        self.assertNotIn("CANARY-PRIVATE", json.dumps(delivery.scrub({"token": "CANARY-PRIVATE", "notes": "Authorization: Bearer CANARY-PRIVATE"})))
        first = delivery.package(self.root / "release-1")
        second = delivery.package(self.root / "release-2")
        self.assertEqual(first["zip_sha256"], second["zip_sha256"])
        difference = delivery.compare_packages(self.root / "release-1/workbench-1.0.0.zip", self.root / "release-2/workbench-1.0.0.zip")
        self.assertEqual(difference["changed"], [])
        evidence = self.file("checks.json", {"data_category": "synthetic", "checks": ["example only, not real verification"]})
        delivery.review_packet(self.directory, self.root / "review", evidence)
        self.assertTrue((self.root / "review/review.json").is_file())

    def test_cli_and_metrics(self):
        output = io.StringIO()
        with redirect_stdout(output):
            self.assertEqual(workbench.main(["status", str(self.directory)]), 0)
        self.assertEqual(json.loads(output.getvalue())["data_category"], "synthetic")
        metric = ws.metric(self.directory, {"task": "manual synthetic task", "operator": "A", "environment": "Windows", "seconds": 12, "retyping": 2, "errors": 1})
        self.assertIn("manual", metric["collection"])
        with redirect_stderr(io.StringIO()):
            self.assertEqual(workbench.main(["card", "DOES-NOT-EXIST"]), 2)

    def test_snapshot_order_is_sequence_not_random_id(self):
        imported, source = self.imported()
        with patch.object(reports, "identity", side_effect=["snapshot-z", "snapshot-a", "snapshot-m"]):
            reports.snapshot(self.directory, imported, self.root / "ordered-1")
            current = ws.get(self.directory, "imports", imported)
            replacement = copy.deepcopy(current["report"]["findings"][0])
            replacement["business_impact"] = "Changed synthetic impact for the second draft."
            reports.author(self.directory, imported, replacement["id"], replacement, current["revision"])
            second = reports.snapshot(self.directory, imported, self.root / "ordered-2")
            self.assertIn(replacement["id"], second["changes"]["changed"])
            third = reports.snapshot(self.directory, imported, self.root / "ordered-3")
            self.assertEqual(third["changes"]["changed"], [])

    def test_authored_markings_reach_handoff_and_conflicts(self):
        source = common.load(self.fixture)
        source["markings"] = ["ORCON"]
        for finding in source["findings"]:
            finding.pop("markings", None)
            for evidence in finding["evidence"]:
                evidence.pop("markings", None)
        imported = reports.import_report(self.directory, self.file("plain.json", source))["id"]
        current = ws.get(self.directory, "imports", imported)
        replacement = copy.deepcopy(current["report"]["findings"][0])
        replacement["evidence"][0]["markings"] = ["PII Red"]
        reports.author(self.directory, imported, replacement["id"], replacement, current["revision"])
        self.assertIn("PII Red", ws.state(self.directory)["markings"])
        preview = delivery.handoff(self.directory, self.root / "author-handoff", "Reviewer", import_id=imported)
        self.assertIn("PII Red", preview["markings"])
        replacement["markings"] = ["FI"]
        conflict = reports.author(self.directory, imported, replacement["id"], replacement, current["revision"])
        self.assertIn("conflict", conflict)
        self.assertIn("FI", ws.state(self.directory)["markings"])

    def test_spaced_secret_arguments_and_revalidation(self):
        for command in ('tool --token CANARY-PRIVATE', 'tool --password "CANARY-PRIVATE value"',
                        "tool --api-key='CANARY-PRIVATE value'", 'token="CANARY-PRIVATE value"'):
            self.assertNotIn("CANARY-PRIVATE", common.redact(command), command)
        original = self.plan()
        original["command"] = 'tool --token CANARY-PRIVATE'
        row = operations.plan(self.directory, original)
        self.assertNotIn("CANARY-PRIVATE", row["command"])
        current = {key: row[key] for key in ("scope_ref", "profile", "targets", "approved_targets", "excluded_targets")}
        current["command"] = "tool --token CANARY-PRIVATE"
        with self.assertRaises(common.Error):
            operations.revalidate(self.directory, row["id"], current, "Reviewer", True)
        self.assertNotIn("CANARY-PRIVATE", ws.get(self.directory, "plans", row["id"])["command"])

    def test_separate_stage_failures_reach_appendix(self):
        run = operations.record_run(self.directory, "synthetic", "1", "author", "success", 0,
                                    scope_ref="synthetic-approved-scope", evidence_refs=["evidence-reference"])
        event = operations.stage_event(self.directory, run["id"], "import", "failed", "parse_failed", 9)
        self.assertEqual(event["exit_code"], 9)
        self.assertEqual(event["scope_ref"], "synthetic-approved-scope")
        self.assertEqual(event["evidence_refs"], ["evidence-reference"])
        operations.stage_event(self.directory, run["id"], "render", "failed", "render_failed")
        blocks = reports.appendix(ws.state(self.directory))
        paragraphs = "\n".join(value for kind, value in blocks if kind == "paragraph")
        self.assertIn("stage=import | status=failed | exit=9", paragraphs)
        self.assertIn("stage=render | status=failed | exit=None", paragraphs)

    def test_handoff_markdown_and_large_file_integrity(self):
        reviewer = '<img src="https://example.invalid/pixel">'
        delivery.handoff(self.directory, self.root / "escaped", reviewer, True)
        prefix = (self.root / "escaped/handoff.md").read_text(encoding="utf-8").split("```json")[0]
        self.assertNotIn("Review owner: <img", prefix)
        self.assertIn("&lt;img", prefix)
        raw = b"x" * (common.MAX_BYTES + 100)
        large = self.root / "large-artifact.bin"
        large.write_bytes(raw)
        with self.assertRaises(common.Error):
            common.read(large)
        self.assertFalse(reports.integrity(large, common.digest(raw[:common.MAX_BYTES + 1]))["matches"])
        self.assertTrue(reports.integrity(large, common.digest(raw))["matches"])

    def test_help_contract_and_local_links(self):
        destination = self.root / "help-contract"
        delivery.scaffold(destination, "helper", '<img src="https://example.invalid/pixel">')
        self.assertIn("&lt;img", (destination / "RUNBOOK.md").read_text())
        metadata = common.load(destination / "METADATA.json")
        metadata["status_codes"]["3"] = "completed"
        (destination / "METADATA.json").write_bytes(common.encoded(metadata))
        self.assertFalse(delivery.check_scaffold(destination)["consistent"])
        metadata["status_codes"]["3"] = "pending"
        (destination / "METADATA.json").write_bytes(common.encoded(metadata))
        code = (destination / "tool.py").read_text()
        (destination / "tool.py").write_text(code.replace('"--input"', '"--renamed"'))
        self.assertFalse(delivery.check_scaffold(destination)["consistent"])
        self.assertTrue(delivery.check_links()["consistent"])


if __name__ == "__main__":
    unittest.main()
