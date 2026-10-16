"""Behavioral regressions for incremental reports and immutable exports."""
import copy
import importlib.util
import io
import json
import tempfile
import unittest
from contextlib import redirect_stdout, redirect_stderr
from pathlib import Path
from unittest.mock import patch

MODULE = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("update_reportgen", MODULE / "reportgen.py")
reportgen = importlib.util.module_from_spec(spec)
spec.loader.exec_module(reportgen)


class UpdateTests(unittest.TestCase):
    def tmpdir(self):
        base = reportgen.ROOT / "tmp/report-update-tests"
        base.mkdir(parents=True, exist_ok=True)
        return tempfile.TemporaryDirectory(dir=base)

    def setUp(self):
        self.raw = (MODULE / "examples/report-marked.json").read_bytes()
        self.data = reportgen.load(self.raw)
        self.engine = reportgen.update_engine()
        self.evidence = dict(copy.deepcopy(self.data["findings"][0]["evidence"][0]),
                             id="E-NEW", summary="Synthetic second output; no request performed.")

    def update(self, operations=None, data=None):
        base = self.data if data is None else data
        return {"contract_version": self.engine.CONTRACT, "data_category": "synthetic", "id": "U-001",
                "engagement_id": base["engagement"]["id"], "base_sha256": self.engine.fingerprint(base),
                "actor": "Synthetic analyst", "reason": "Incorporate a second synthetic observation",
                "operations": operations if operations is not None else
                    [{"op": "append_evidence", "finding_id": "F-001", "evidence": [self.evidence]}]}

    def test_append_preserves_authorship_and_unrelated_findings(self):
        before = copy.deepcopy(self.data)
        revised, receipt = reportgen.apply_update(self.data, self.update())
        self.assertEqual(self.data, before)
        self.assertEqual(revised["findings"][0]["description"], before["findings"][0]["description"])
        self.assertEqual(revised["findings"][0]["evidence"][:-1], before["findings"][0]["evidence"])
        self.assertEqual(revised["findings"][1], before["findings"][1])
        self.assertEqual(revised["findings"][0]["status"], "candidate")
        self.assertEqual(receipt["changes"]["evidence"]["F-001"]["added"], ["E-NEW"])
        self.assertEqual(receipt["affected_findings"], ["F-001"])
        self.assertFalse(receipt["evidence_files_opened"])

    def test_explicit_amendment_and_new_finding(self):
        finding = copy.deepcopy(self.data["findings"][0])
        finding.update(id="F-003", evidence=[self.evidence])
        operations = [{"op": "add_finding", "finding": finding},
                      {"op": "amend_finding", "finding_id": "F-002", "fields": {"remediation": "Revised human advice."}},
                      {"op": "amend_engagement", "fields": {"executive_summary": "Three synthetic observations."}}]
        revised, receipt = reportgen.apply_update(self.data, self.update(operations))
        self.assertEqual(revised["findings"][2]["status"], "candidate")
        self.assertEqual(revised["findings"][1]["remediation"], "Revised human advice.")
        self.assertEqual(revised["findings"][0], self.data["findings"][0])
        self.assertEqual(receipt["changes"]["added"], ["F-003"])
        self.assertTrue(receipt["changes"]["engagement_changed"])

    def test_stale_base_and_wrong_engagement_reject_atomically(self):
        for field, value in (("base_sha256", "0" * 64), ("engagement_id", "WRONG")):
            update = self.update()
            update[field] = value
            with self.subTest(field=field), self.assertRaises(reportgen.ContractError):
                reportgen.apply_update(self.data, update)
        self.assertEqual(len(self.data["findings"][0]["evidence"]), 1)

    def test_evidence_idempotency_preserves_review(self):
        self.data["review"] = {"reviewer": "Training reviewer", "reviewed_at": "2026-10-15"}
        existing = copy.deepcopy(self.data["findings"][0]["evidence"][0])
        operations = [{"op": "append_evidence", "finding_id": "F-001", "evidence": [existing, existing]}]
        revised, receipt = reportgen.apply_update(self.data, self.update(operations))
        self.assertEqual(revised, self.data)
        self.assertFalse(receipt["modified"])
        self.assertEqual(receipt["affected_findings"], [])

    def test_conflicting_evidence_content_or_owner_rejected(self):
        existing = copy.deepcopy(self.data["findings"][0]["evidence"][0])
        for owner, entry in (("F-002", existing), ("F-001", dict(existing, summary="Changed history"))):
            with self.subTest(owner=owner), self.assertRaises(reportgen.ContractError):
                reportgen.apply_update(self.data, self.update([
                    {"op": "append_evidence", "finding_id": owner, "evidence": [entry]}]))

    def test_invalid_later_operation_rejects_entire_batch(self):
        update = self.update()
        update["operations"].append({"op": "amend_finding", "finding_id": "F-001", "fields": {"status": "confirmed"}})
        before = copy.deepcopy(self.data)
        with self.assertRaises(reportgen.ContractError):
            reportgen.apply_update(self.data, update)
        self.assertEqual(self.data, before)
        for operations in ([{"op": "add_finding", "finding": {"id": "F-BAD"}}],
                           [{"op": "append_evidence", "finding_id": "F-001", "evidence": [None]}],
                           [{"op": "delete_finding", "finding_id": "F-001"}]):
            with self.subTest(operations=operations), self.assertRaises(reportgen.ContractError):
                reportgen.apply_update(self.data, self.update(operations))

    def test_handling_cannot_downgrade_and_new_evidence_escalates(self):
        self.evidence["markings"] = ["PII Red"]
        revised, _ = reportgen.apply_update(self.data, self.update())
        self.assertEqual(reportgen.handling(revised)["report"], "ORCON//PROPIN//PII Red//FI")
        with self.assertRaises(reportgen.ContractError):
            reportgen.apply_update(self.data, self.update([
                {"op": "amend_finding", "finding_id": "F-001", "fields": {"markings": ["ORCON"]}}]))

    def test_legacy_report_accepts_plain_evidence_and_promotes_marked_evidence(self):
        legacy = reportgen.load((MODULE / "examples/report.json").read_bytes())
        self.evidence.pop("markings", None)
        revised, _ = reportgen.apply_update(legacy, self.update(data=legacy))
        self.assertEqual(revised["schema_version"], legacy["schema_version"])
        self.evidence["markings"] = ["PII Red"]
        revised, _ = reportgen.apply_update(legacy, self.update(data=legacy))
        self.assertEqual(revised["schema_version"], "1.2")
        self.assertIn("PII Red", reportgen.handling(revised)["report"])

    def test_noop_amendment_preserves_review_and_changed_content_removes_it(self):
        self.data["review"] = {"reviewer": "Training reviewer", "reviewed_at": "2026-10-15"}
        operations = [{"op": "amend_finding", "finding_id": "F-001",
                       "fields": {"description": self.data["findings"][0]["description"]}}]
        revised, _ = reportgen.apply_update(self.data, self.update(operations))
        self.assertIn("review", revised)
        revised, _ = reportgen.apply_update(self.data, self.update())
        self.assertNotIn("review", revised)

    def test_fingerprint_ignores_input_whitespace(self):
        same = reportgen.load(json.dumps(self.data).encode())
        self.assertEqual(reportgen.describe(same), reportgen.describe(self.data))

    def test_numeric_representation_change_has_consistent_identity_and_review(self):
        cvss = {"version": "3.1", "score": 7, "vector": "CVSS:3.1/AV:N", "source": "Synthetic",
                "retrieved_at": "2026-10-15"}
        self.data["findings"][0]["cvss"] = cvss
        self.data["findings"][0]["status"] = "candidate"
        revised, receipt = reportgen.apply_update(self.data, self.update([
            {"op": "amend_finding", "finding_id": "F-001", "fields": {"cvss": dict(cvss, score=7.0)}}]))
        self.assertTrue(receipt["modified"])
        self.assertNotEqual(receipt["base_sha256"], receipt["result_sha256"])
        self.assertEqual(revised["findings"][0]["status"], "candidate")
        self.assertEqual(receipt["affected_findings"], ["F-001"])
        self.assertEqual(receipt["changes"]["changed"], ["F-001"])

    def test_cli_preview_and_export_bundle_hashes(self):
        with self.tmpdir() as tmp:
            root = Path(tmp)
            update = root / "update.json"
            update.write_bytes(self.engine.encoded(self.update()))
            output = io.StringIO()
            with redirect_stdout(output):
                code = reportgen.main([str(MODULE / "examples/report-marked.json"), "--update", str(update), "--preview"])
            self.assertEqual(code, 0)
            self.assertFalse(json.loads(output.getvalue())["written"])
            self.assertEqual(sorted(p.name for p in root.iterdir()), ["update.json"])
            destination = root / "revision-2"
            manifest = reportgen.generate(self.raw, destination, update_raw=update.read_bytes())
            for name, expected in manifest["artifacts"].items():
                self.assertEqual(reportgen.sha256((destination / name).read_bytes()), expected)
            revised = reportgen.load((destination / "input.json").read_bytes())
            self.assertEqual(manifest["report_sha256"], self.engine.fingerprint(revised))
            self.assertEqual(manifest["input_sha256"], reportgen.sha256(self.raw))
            self.assertEqual(manifest["update"]["base_sha256"], self.engine.fingerprint(self.data))
            with self.assertRaises(reportgen.ContractError):
                reportgen.generate(self.raw, destination, update_raw=update.read_bytes())
            self.assertTrue((destination / "changes.json").is_file())

    def test_render_failure_leaves_no_partial_bundle(self):
        with self.tmpdir() as tmp:
            destination = Path(tmp) / "revision-2"
            with patch.object(reportgen, "render_docx", side_effect=RuntimeError("render failure")):
                with self.assertRaises(RuntimeError):
                    reportgen.generate(self.raw, destination, docx=True,
                                       update_raw=self.engine.encoded(self.update()))
            self.assertFalse(destination.exists())

    @unittest.skipUnless(all(importlib.util.find_spec(name) for name in ("reportlab", "docx", "pypdf")),
                         "optional PDF/Word verification dependencies unavailable")
    def test_updated_evidence_reaches_both_optional_formats(self):
        from pypdf import PdfReader
        from zipfile import ZipFile
        from xml.etree import ElementTree as ET
        with self.tmpdir() as tmp:
            destination = Path(tmp) / "all-formats"
            manifest = reportgen.generate(self.raw, destination, pdf=True, docx=True,
                                          update_raw=self.engine.encoded(self.update()))
            pdf = PdfReader(destination / "report.pdf")
            pdf_text = " ".join(page.extract_text() or "" for page in pdf.pages)
            self.assertIn("E-NEW", pdf_text)
            self.assertIn("Synthetic second output", pdf_text)
            with ZipFile(destination / "report.docx") as package:
                xml = ET.fromstring(package.read("word/document.xml"))
                word_text = " ".join(xml.itertext())
                self.assertIn("E-NEW", word_text)
                self.assertIn(self.evidence["summary"], word_text)
            revised = reportgen.load((destination / "input.json").read_bytes())
            self.assertEqual(revised["findings"][0]["status"], "candidate")
            self.assertEqual(manifest["report_sha256"], self.engine.fingerprint(revised))

    def test_update_cannot_retain_release_label(self):
        self.data["review"] = {"reviewer": "Training reviewer", "reviewed_at": "2026-10-15"}
        with self.tmpdir() as tmp, self.assertRaises(reportgen.ContractError):
            reportgen.generate(self.engine.encoded(self.data), Path(tmp) / "out", release=True,
                               update_raw=self.engine.encoded(self.update()))


if __name__ == "__main__":
    unittest.main()
