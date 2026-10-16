"""Report revisions through real workspace transactions and CLI dispatch."""
import copy
import io
import json
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path

MODULE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(MODULE))
import common
import reports
import workbench
import workspace as ws


class ReportUpdateTests(unittest.TestCase):
    def setUp(self):
        base = common.ROOT / "tmp/workbench-update-tests"
        base.mkdir(parents=True, exist_ok=True)
        self.temporary = tempfile.TemporaryDirectory(dir=base)
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.directory = self.root / "workspace"
        ws.init(self.directory, "Synthetic owner")
        fixture = common.ROOT / "tooling/reporting/examples/report-marked.json"
        self.identifier = reports.import_report(self.directory, fixture)["id"]
        self.module = reports.reporter()

    def item(self):
        return ws.get(self.directory, "imports", self.identifier)

    def update(self):
        item = self.item()
        evidence = dict(copy.deepcopy(item["report"]["findings"][0]["evidence"][0]), id="E-NEW")
        patch = {"contract_version": "cptc.report-update/1.0", "data_category": "synthetic", "id": "U-001",
                 "engagement_id": item["report"]["engagement"]["id"],
                 "base_sha256": self.module.describe(item["report"])["report_sha256"],
                 "actor": "Synthetic analyst", "reason": "Add a new synthetic output",
                 "operations": [{"op": "append_evidence", "finding_id": "F-001", "evidence": [evidence]}]}
        return patch

    def file(self, patch):
        path = self.root / "update.json"
        path.write_bytes(common.encoded(patch))
        return path

    def test_preview_apply_and_replay_preserve_unaffected_acceptance(self):
        for identifier in ("F-001", "F-002"):
            reports.review(self.directory, self.identifier, identifier, "accept", "Training review", "Reviewer")
        before = ws.state(self.directory)
        revision = self.item()["revision"]
        path = self.file(self.update())
        preview = reports.update_report(self.directory, self.identifier, path, revision, True)
        self.assertTrue(preview["modified"])
        self.assertFalse(preview["written"])
        self.assertEqual(ws.state(self.directory), before)
        result = reports.update_report(self.directory, self.identifier, path, revision)
        self.assertTrue(result["written"])
        item = self.item()
        self.assertEqual(item["source_report"], before["imports"][self.identifier]["source_report"])
        self.assertNotIn("F-001", item["dispositions"])
        self.assertEqual(item["dispositions"]["F-002"], "accept")
        self.assertEqual(item["report"]["findings"][1]["status"], "confirmed")
        reports.review(self.directory, self.identifier, "F-001", "accept", "Reviewed latest output", "Reviewer")
        settled = (self.directory / "state.json").read_bytes()
        replay = reports.update_report(self.directory, self.identifier, path, revision)
        self.assertTrue(replay["duplicate"])
        self.assertEqual((self.directory / "state.json").read_bytes(), settled)

    def test_conflicting_reused_update_id_is_rejected(self):
        patch = self.update()
        revision = self.item()["revision"]
        reports.update_report(self.directory, self.identifier, self.file(patch), revision)
        patch["reason"] = "Different payload"
        before = (self.directory / "state.json").read_bytes()
        with self.assertRaisesRegex(common.Error, "update_id_conflict"):
            reports.update_report(self.directory, self.identifier, self.file(patch), revision)
        self.assertEqual((self.directory / "state.json").read_bytes(), before)

    def test_stale_revision_and_digest_leave_ledger_unchanged(self):
        path = self.file(self.update())
        before = (self.directory / "state.json").read_bytes()
        with self.assertRaisesRegex(common.Error, "revision_conflict"):
            reports.update_report(self.directory, self.identifier, path, 90)
        patch = self.update()
        patch["base_sha256"] = "0" * 64
        with self.assertRaisesRegex(common.Error, "stale base"):
            reports.update_report(self.directory, self.identifier, self.file(patch), self.item()["revision"])
        self.assertEqual((self.directory / "state.json").read_bytes(), before)

    def test_noop_update_does_not_change_workspace_or_reviews(self):
        patch = self.update()
        patch["operations"][0]["evidence"] = copy.deepcopy(self.item()["report"]["findings"][0]["evidence"])
        before = (self.directory / "state.json").read_bytes()
        result = reports.update_report(self.directory, self.identifier, self.file(patch), self.item()["revision"])
        self.assertFalse(result["modified"])
        self.assertFalse(result["written"])
        self.assertEqual((self.directory / "state.json").read_bytes(), before)

    def test_stale_review_is_refused(self):
        revision = self.item()["revision"]
        reports.update_report(self.directory, self.identifier, self.file(self.update()), revision)
        with self.assertRaisesRegex(common.Error, "revision_conflict"):
            reports.review(self.directory, self.identifier, "F-001", "accept", "Stale", "Reviewer", revision)

    def test_new_finding_cannot_collide_with_another_import(self):
        other = copy.deepcopy(self.item()["source_report"])
        other["findings"] = [other["findings"][0]]
        other["findings"][0]["id"] = "F-OTHER"
        other["findings"][0]["evidence"][0]["id"] = "E-OTHER"
        source = self.root / "other.json"
        source.write_bytes(common.encoded(other))
        reports.import_report(self.directory, source)
        patch = self.update()
        patch["operations"] = [{"op": "add_finding", "finding": other["findings"][0]}]
        before = (self.directory / "state.json").read_bytes()
        with self.assertRaisesRegex(common.Error, "conflicting_finding_ids"):
            reports.update_report(self.directory, self.identifier, self.file(patch), self.item()["revision"])
        self.assertEqual((self.directory / "state.json").read_bytes(), before)

    def test_cli_state_and_update_preview(self):
        output = io.StringIO()
        with redirect_stdout(output):
            code = workbench.main(["report-state", str(self.directory), self.identifier])
        self.assertEqual(code, 0)
        state = json.loads(output.getvalue())
        self.assertEqual(state["revision"], self.item()["revision"])
        path = self.file(self.update())
        output = io.StringIO()
        with redirect_stdout(output):
            code = workbench.main(["update-report", str(self.directory), self.identifier, str(path),
                                   "--base", str(state["revision"]), "--preview"])
        self.assertEqual(code, 0)
        self.assertFalse(json.loads(output.getvalue())["written"])

    def test_snapshot_retains_prior_bundle_and_update_receipts(self):
        first = reports.snapshot(self.directory, self.identifier, self.root / "first")
        old_files = {p.name: p.read_bytes() for p in (self.root / "first").iterdir()}
        reports.update_report(self.directory, self.identifier, self.file(self.update()), self.item()["revision"])
        second = reports.snapshot(self.directory, self.identifier, self.root / "second")
        self.assertEqual(second["changes"]["evidence"]["F-001"]["added"], ["E-NEW"])
        self.assertEqual(second["changes"]["updates"]["added"], ["U-001"])
        receipts = common.load(self.root / "second/updates.json")
        self.assertIn("U-001", receipts)
        self.assertEqual({p.name: p.read_bytes() for p in (self.root / "first").iterdir()}, old_files)
        for name, expected in second["manifest"]["artifacts"].items():
            self.assertEqual(common.digest((self.root / "second" / name).read_bytes()), expected)


if __name__ == "__main__":
    unittest.main()
