"""Meaningful synthetic regressions for the reporting boundary and real export path."""
import copy
import hashlib
import importlib.util
import io
import json
import socket
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

MODULE_PATH = Path(__file__).resolve().parents[1] / "reportgen.py"
spec = importlib.util.spec_from_file_location("reportgen", MODULE_PATH)
reportgen = importlib.util.module_from_spec(spec)
spec.loader.exec_module(reportgen)
FIXTURE = MODULE_PATH.parent / "examples" / "report.json"


class ReportTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.test_tmp = reportgen.ROOT / "tmp" / "reportgen-tests"
        cls.test_tmp.mkdir(parents=True, exist_ok=True)

    def tmpdir(self):
        return tempfile.TemporaryDirectory(dir=self.test_tmp)

    def setUp(self):
        self.raw = FIXTURE.read_bytes()
        self.data = json.loads(self.raw)

    def raw_for(self, data=None):
        return json.dumps(data or self.data, ensure_ascii=False).encode("utf-8")

    def test_valid_fixture_preserves_observation_and_candidate(self):
        data = reportgen.validate(self.data)
        rendered = reportgen.render_markdown(data)
        self.assertIn("Candidate: 1", rendered)
        self.assertIn("Normalized evidence summary:", rendered)
        self.assertIn("CANDIDATE", rendered)
        self.assertIn(reportgen.md(data["findings"][0]["description"]), rendered)
        self.assertNotIn("CVE-", rendered)

    def test_empty_findings_are_explicit(self):
        self.data["findings"] = []
        reportgen.validate(self.data)
        self.assertIn("Total: 0", reportgen.render_markdown(self.data))

    def marked_data(self):
        data = copy.deepcopy(self.data)
        data["schema_version"] = "1.2"
        data["markings"] = ["ORCON"]
        return data

    def test_mixed_source_markings_roll_into_analysis_without_mutation(self):
        data = self.marked_data()
        data["findings"][0]["markings"] = ["PROPIN"]
        data["findings"][0]["evidence"][0]["markings"] = ["FI"]
        data["findings"][1]["markings"] = ["PII"]
        data["findings"][1]["evidence"][0]["markings"] = ["PII Red"]
        original = copy.deepcopy(data)
        controls = reportgen.handling(reportgen.validate(data))
        self.assertEqual(controls["report"], "ORCON//PROPIN//PII Red//FI")
        self.assertEqual(controls["findings"]["F-001"], "ORCON//PROPIN//FI")
        self.assertEqual(controls["evidence"]["E-002"], "ORCON//PII Red")
        self.assertIn("ORCON//PROPIN//PII Red//FI", reportgen.render_markdown(data))
        self.assertEqual(data, original)

    def test_descendants_cannot_remove_ancestor_restrictions(self):
        data = self.marked_data()
        data["markings"] = ["ORCON", "PII Red", "FI"]
        data["findings"][0]["markings"] = ["PROPIN"]
        data["findings"][0]["evidence"][0]["markings"] = ["PII"]
        controls = reportgen.handling(reportgen.validate(data))
        self.assertEqual(controls["evidence"]["E-001"], "ORCON//PROPIN//PII Red//FI")
        self.assertEqual(controls["findings"]["F-002"], "ORCON//PII Red//FI")

    def test_explicit_document_label_cannot_lose_known_restrictions(self):
        data = self.marked_data()
        data["classification"] = "ORCON//PII Red//FI"
        controls = reportgen.handling(reportgen.validate(data))
        self.assertEqual(controls["report"], "ORCON//PII Red//FI")
        self.assertEqual(controls["evidence"]["E-001"], "ORCON//PII Red//FI")

    def test_invalid_markings_reject_without_output_or_value_echo(self):
        bad_values = [[], "ORCON", ["PUBLIC-SENTINEL"], ["ORCON", "ORCON"],
                      [None], [["ORCON"]], ["PII Red"] * 6]
        with self.tmpdir() as tmp:
            for level in ("report", "finding", "evidence"):
                for i, value in enumerate(bad_values):
                    data = self.marked_data()
                    target = data if level == "report" else data["findings"][0]
                    if level == "evidence":
                        target = target["evidence"][0]
                    target["markings"] = value
                    with self.subTest(level=level, case=i):
                        with self.assertRaises(reportgen.ContractError) as error:
                            reportgen.generate(self.raw_for(data), Path(tmp) / f"{level}-{i}")
                        self.assertNotIn("PUBLIC-SENTINEL", str(error.exception))
            self.assertEqual(list(Path(tmp).iterdir()), [])
        for value in (None, ["PROPIN"]):
            data = self.marked_data()
            if value is None:
                del data["markings"]
            else:
                data["markings"] = value
            with self.assertRaises(reportgen.ContractError):
                reportgen.validate(data)

    def test_structured_markings_require_new_schema(self):
        for schema in ("1.0", "1.1"):
            for level in ("report", "finding", "evidence"):
                data = self.legacy_data() if schema == "1.0" else copy.deepcopy(self.data)
                target = data if level == "report" else data["findings"][0]
                if level == "evidence":
                    target = target["evidence"][0]
                target["markings"] = ["ORCON"]
                with self.subTest(schema=schema, level=level):
                    with self.assertRaises(reportgen.ContractError):
                        reportgen.validate(data)

    def test_legacy_marking_limits_and_severity_method_are_visible(self):
        data = self.legacy_data()
        data["classification"] = "PROPIN//FI"
        controls = reportgen.handling(reportgen.validate(data))
        self.assertEqual(controls["report"], "ORCON//PROPIN//FI")
        self.assertEqual(controls["status"], "legacy_unverified")
        rendered = reportgen.render_markdown(data)
        self.assertIn("classification inheritance is not verified", rendered)
        self.assertIn("matrix not configured", rendered)
        self.assertIn("No likelihood/impact scoring", rendered)

    def test_manifest_records_handling_even_for_reviewed_training_copy(self):
        data = self.marked_data()
        data["markings"].append("PII Red")
        data["review"] = {"reviewer": "Synthetic Reviewer", "reviewed_at": "2026-10-15"}
        for finding in data["findings"]:
            finding["status"] = "confirmed"
        with self.tmpdir() as tmp:
            manifest = reportgen.generate(self.raw_for(data), Path(tmp) / "out", release=True)
            self.assertEqual(manifest["effective_markings"], "ORCON//PII Red")
            self.assertEqual(manifest["classification_inheritance"], "structured")
            self.assertEqual(manifest["marking_policy"], "cptc.handling/1.0")

    def legacy_data(self):
        data = copy.deepcopy(self.data)
        data["schema_version"] = "1.0"
        for key in ("objective", "recommendations", "methodology_sections"):
            data["engagement"].pop(key, None)
        return data

    def test_legacy_report_preserves_facts_under_new_layout(self):
        data = self.legacy_data()
        original = copy.deepcopy(data)
        rendered = reportgen.render_markdown(reportgen.validate(data))
        self.assertEqual(data, original)
        self.assertIn("Candidate: 1", rendered)
        self.assertIn("## 1 Introduction", rendered)
        self.assertIn("## 3 Methodology", rendered)
        self.assertIn("## 4 Detailed Findings", rendered)
        self.assertIn("## 5 Appendices", rendered)
        self.assertIn("An assessment objective was not supplied", rendered)
        self.assertIn("recommendations were not supplied", rendered)
        self.assertNotIn("Cleanup and retest", rendered)
        self.assertIn("Human review pending", rendered)

    def test_supplied_authoring_sections_and_chapter_order(self):
        data = copy.deepcopy(self.data)
        data["schema_version"] = "1.1"
        data["engagement"]["objective"] = "OBJECTIVESENTINEL"
        data["engagement"]["recommendations"] = ["RECOMMENDATIONSENTINEL"]
        data["engagement"]["methodology_sections"] = {"cleanup": "CLEANUPSENTINEL"}
        rendered = reportgen.render_markdown(reportgen.validate(data))
        for value in ("OBJECTIVESENTINEL", "RECOMMENDATIONSENTINEL", "CLEANUPSENTINEL"):
            self.assertIn(value, rendered)
        positions = [rendered.index("## " + str(i) + " ") for i in range(1, 6)]
        self.assertEqual(positions, sorted(positions))
        self.assertIn("## Contents", rendered)
        self.assertIn("(#4-detailed-findings)", rendered)
        self.assertIn("### Cleanup and retest", rendered)
        self.assertNotIn("### Service enumeration", rendered)

    def test_authoring_extension_rejects_unknown_or_malformed_fields(self):
        mutations = [
            lambda e: e.update(objective=""),
            lambda e: e.update(objective=["SECRET-SENTINEL"]),
            lambda e: e.update(recommendations=[]),
            lambda e: e.update(recommendations=["a"] * 21),
            lambda e: e.update(recommendations=["a" * 2001]),
            lambda e: e.update(methodology_sections={}),
            lambda e: e.update(methodology_sections={"untrusted": "SECRET-SENTINEL"}),
            lambda e: e.update(methodology_sections={"cleanup": []}),
        ]
        with self.tmpdir() as tmp:
            for i, mutate in enumerate(mutations):
                data = copy.deepcopy(self.data)
                data["schema_version"] = "1.1"
                mutate(data["engagement"])
                with self.subTest(i=i):
                    with self.assertRaises(reportgen.ContractError) as error:
                        reportgen.generate(self.raw_for(data), Path(tmp) / str(i))
                    self.assertNotIn("SECRET-SENTINEL", str(error.exception))
            self.assertEqual(list(Path(tmp).iterdir()), [])
        data = self.legacy_data()
        data["engagement"]["objective"] = "New keys require an explicit schema change."
        with self.assertRaises(reportgen.ContractError):
            reportgen.validate(data)

    def test_design_envelope_is_not_accepted_as_report_input(self):
        envelope = json.loads((FIXTURE.parent / "tool-run.json").read_bytes())
        with self.assertRaises(reportgen.ContractError):
            reportgen.validate(envelope)

    def test_invalid_contracts_fail_without_destination(self):
        mutations = [
            lambda d: d.update(schema_version="9.0"),
            lambda d: d.update(data_category="client"),
            lambda d: d["engagement"].update(report_date="2026-02-30"),
            lambda d: d["engagement"].update(unknown="SECRET-SENTINEL"),
            lambda d: d["engagement"].update(scope=[]),
            lambda d: d["findings"][0].update(severity="urgent"),
            lambda d: d["findings"][0].update(status="approved"),
            lambda d: d["findings"][0].update(evidence=[]),
            lambda d: d["findings"][0]["evidence"][0].update(observed_at="2026-10-14T14:00:00"),
            lambda d: d["findings"][1].update(id=d["findings"][0]["id"]),
            lambda d: d["findings"][1]["evidence"][0].update(id="E-001"),
            lambda d: d["findings"][0].update(title="two\nlines"),
            lambda d: d["findings"][0].update(description="a\u202eb"),
        ]
        with self.tmpdir() as tmp:
            for i, mutate in enumerate(mutations):
                with self.subTest(i=i):
                    data = copy.deepcopy(self.data)
                    mutate(data)
                    out = Path(tmp) / str(i)
                    with self.assertRaises(reportgen.ContractError) as error:
                        reportgen.generate(self.raw_for(data), out)
                    self.assertFalse(out.exists())
                    self.assertNotIn("SECRET-SENTINEL", str(error.exception))

    def test_unsafe_artifact_references_rejected(self):
        for value in ("../secret.txt", "/etc/passwd", "C:/secret", r"C:\secret",
                      "https://example.test/file", "//server/share", "a/../b", "a//b"):
            with self.subTest(value=value):
                data = copy.deepcopy(self.data)
                data["findings"][0]["evidence"][0]["artifact"] = value
                with self.assertRaises(reportgen.ContractError):
                    reportgen.validate(data)

    def test_evidence_files_are_never_opened(self):
        self.data["findings"][0]["evidence"][0]["artifact"] = "does-not-exist/artifact.txt"
        self.data["findings"][0]["evidence"][0]["sha256"] = "a" * 64
        with self.tmpdir() as tmp:
            manifest = reportgen.generate(self.raw_for(), Path(tmp) / "report")
            self.assertFalse(manifest["evidence_files_opened"])

    def test_bad_json_and_duplicate_keys(self):
        for raw in (b'{"schema_version":"1.0","schema_version":"2.0"}',
                    b'{"score":NaN}', b'{"score":Infinity}', b'{"a":', b"\xff"):
            with self.subTest(raw=raw):
                with self.assertRaises(reportgen.ContractError):
                    reportgen.load(raw)

    def test_json_contract_diagnostics_are_preserved(self):
        cases = [
            (b'{"a":1,"a":2}', "input JSON: duplicate object key"),
            (b'{"score":NaN}', "input JSON: non-finite numbers are prohibited"),
            (b'{"score":Infinity}', "input JSON: non-finite numbers are prohibited"),
        ]
        for raw, expected in cases:
            with self.subTest(raw=raw):
                with self.assertRaises(reportgen.ContractError) as error:
                    reportgen.load(raw)
                self.assertEqual(str(error.exception), expected)

    def test_json_parser_value_error_is_sanitized(self):
        with patch.object(reportgen.json, "loads", side_effect=ValueError("SECRET-SENTINEL")):
            with self.assertRaises(reportgen.ContractError) as error:
                reportgen.load(self.raw)
        self.assertEqual(str(error.exception), "input JSON: invalid UTF-8 JSON")

    def test_large_json_integer_is_rejected_without_destination(self):
        self.data["findings"][0]["cvss"] = self.cvss()
        raw = json.dumps(self.data, separators=(",", ":")).encode().replace(
            b'"score":9.8', b'"score":' + b"1" * 5000)
        with self.tmpdir() as tmp:
            out = Path(tmp) / "report"
            stdin = io.TextIOWrapper(io.BytesIO(raw), encoding="utf-8")
            with (patch("sys.stdin", stdin),
                  patch("sys.stderr", new_callable=io.StringIO) as error,
                  patch("sys.stdout", new_callable=io.StringIO) as output):
                result = reportgen.main(["-", "--output-dir", str(out)])
            self.assertEqual(result, 2)
            self.assertIn("Report rejected:", error.getvalue())
            self.assertNotIn("1" * 100, error.getvalue())
            self.assertNotIn("filesystem", error.getvalue())
            self.assertEqual(output.getvalue(), "")
            self.assertEqual(list(Path(tmp).iterdir()), [])
            stdin.close()

    def test_input_size_bounded(self):
        with self.assertRaises(reportgen.ContractError):
            reportgen.load(b" " * (reportgen.MAX_INPUT_BYTES + 1))

    def test_release_requires_human_review(self):
        with self.assertRaises(reportgen.ContractError):
            reportgen.validate(self.data, release=True)

    def test_release_rejects_candidates_even_with_reviewer(self):
        self.data["review"] = {"reviewer": "Synthetic Reviewer", "reviewed_at": "2026-10-14"}
        with self.assertRaises(reportgen.ContractError):
            reportgen.validate(self.data, release=True)

    def test_release_label_does_not_promote_status(self):
        self.data["review"] = {"reviewer": "Synthetic Reviewer", "reviewed_at": "2026-10-14"}
        for finding in self.data["findings"]:
            finding["status"] = "confirmed"
        reportgen.validate(self.data, release=True)
        self.assertIn("REVIEWED TRAINING COPY", reportgen.render_markdown(self.data, release=True))
        self.assertEqual(self.data["findings"][1]["status"], "confirmed")

    def cvss(self):
        return {"version": "3.1", "score": 9.8,
                "vector": "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H",
                "source": "Synthetic supplied metadata fixture; not a public lookup",
                "retrieved_at": "2026-10-14"}

    def test_cvss_is_supplied_and_not_inferred(self):
        self.data["findings"][0]["cvss"] = self.cvss()
        reportgen.validate(self.data)
        rendered = reportgen.render_markdown(self.data)
        self.assertIn("not recalculated", rendered)
        self.assertIn(reportgen.md(self.cvss()["vector"]), rendered)
        self.assertNotIn("CVE-", rendered)
        self.assertEqual(self.data["findings"][0]["severity"], "medium")

    def test_cvss_bad_score_version_shape(self):
        cases = [{"score": True}, {"score": -1}, {"score": 11}, {"score": 10 ** 1000},
                 {"score": -(10 ** 1000)}, {"score": "9.8"},
                 {"score": float("nan")}, {"score": float("inf")}, {"version": "2.0"},
                 {"vector": "CVSS:4.0/AV:N"}, {"vector": "not-a-vector"},
                 {"retrieved_at": "yesterday"}]
        for change in cases:
            with self.subTest(change=change):
                data = copy.deepcopy(self.data)
                data["findings"][0]["cvss"] = {**self.cvss(), **change}
                with self.assertRaises(reportgen.ContractError):
                    reportgen.validate(data)

    def test_candidate_cve_remains_candidate_and_blocks_release(self):
        self.data["findings"][0]["cves"] = [{
            "id": "CVE-2021-44228", "applicability": "candidate",
            "match_basis": "Synthetic matching example only; no actual product or vulnerability claim",
            "source": "Synthetic fixture", "retrieved_at": "2026-10-14",
        }]
        self.data["review"] = {"reviewer": "Synthetic Reviewer", "reviewed_at": "2026-10-14"}
        for finding in self.data["findings"]:
            finding["status"] = "confirmed"
        reportgen.validate(self.data)
        with self.assertRaises(reportgen.ContractError):
            reportgen.validate(self.data, release=True)
        self.assertEqual(self.data["findings"][0]["cves"][0]["applicability"], "candidate")

    def test_markdown_literal_input(self):
        hostile = '<img src="https://example.test/image"> [click](https://example.test) # run *command*'
        self.data["findings"][0]["description"] = hostile
        rendered = reportgen.render_markdown(reportgen.validate(self.data))
        self.assertNotIn('<img src=', rendered)
        self.assertNotIn('[click](', rendered)
        self.assertIn("&lt;img", rendered)
        self.assertIn(r"\*command\*", rendered)

    def test_cve_ids_use_ascii_digits(self):
        self.data["findings"][0]["cves"] = [{
            "id": "CVE-٢٠٢١-٤٤٢٢٨", "applicability": "candidate",
            "match_basis": "Synthetic invalid identifier", "source": "Synthetic fixture",
            "retrieved_at": "2026-10-14",
        }]
        with self.assertRaises(reportgen.ContractError):
            reportgen.validate(self.data)

    def test_manifest_hashes_and_deterministic_markdown(self):
        with self.tmpdir() as tmp:
            out_a, out_b = Path(tmp) / "a", Path(tmp) / "b"
            first = reportgen.generate(self.raw, out_a)
            second = reportgen.generate(self.raw, out_b)
            self.assertEqual(first, second)
            self.assertEqual(first["input_sha256"], hashlib.sha256(self.raw).hexdigest())
            for name, digest in first["artifacts"].items():
                self.assertEqual(digest, hashlib.sha256((out_a / name).read_bytes()).hexdigest())

    def test_existing_destination_is_preserved(self):
        with self.tmpdir() as tmp:
            out = Path(tmp) / "out"
            out.mkdir()
            (out / "report.md").write_text("KEEP", encoding="utf-8")
            with self.assertRaises(reportgen.ContractError):
                reportgen.generate(self.raw, out)
            self.assertEqual((out / "report.md").read_text(), "KEEP")

    def test_forbidden_output_targets(self):
        for name in ("sources", "tooling"):
            with self.subTest(name=name):
                with self.assertRaises(reportgen.ContractError):
                    reportgen.generate(self.raw, reportgen.ROOT / name / "forbidden-test")

    def test_renderer_failure_publishes_nothing_and_cleans_staging(self):
        with self.tmpdir() as tmp:
            out = Path(tmp) / "out"
            with patch.object(reportgen, "render_pdf", side_effect=RuntimeError("SECRET-SENTINEL")):
                with self.assertRaises(RuntimeError):
                    reportgen.generate(self.raw, out, pdf=True)
            self.assertEqual(list(Path(tmp).iterdir()), [])

    def test_cli_failure_does_not_echo_raw_values(self):
        with self.tmpdir() as tmp:
            source = Path(tmp) / "bad.json"
            source.write_text('{"secret":"SECRET-SENTINEL"}', encoding="utf-8")
            with patch("sys.stderr", new_callable=io.StringIO) as error:
                result = reportgen.main([str(source), "--output-dir", str(Path(tmp) / "out")])
            self.assertEqual(result, 2)
            self.assertNotIn("SECRET-SENTINEL", error.getvalue())

    def test_pdf_real_export_literal_unicode_long_text_and_offline(self):
        self.data["findings"][0]["description"] = (
            'Literal <img src="https://example.test/"> résumé Δ. ' * 120)
        self.data["findings"][0]["evidence"][0]["summary"] = "Long evidence " + "A" * 1000
        with self.tmpdir() as tmp:
            with (patch.object(socket, "create_connection", side_effect=AssertionError("network")),
                  patch.object(socket.socket, "connect", side_effect=AssertionError("network")),
                  patch.object(socket.socket, "connect_ex", side_effect=AssertionError("network"))):
                out = Path(tmp) / "out"
                manifest = reportgen.generate(self.raw_for(), out, pdf=True)
            self.assertTrue((out / "report.pdf").read_bytes().startswith(b"%PDF-"))
            self.assertIn("report.pdf", manifest["artifacts"])
            self.assertFalse(manifest["cvss_recalculated"])
            self.assertIn("&lt;img", (out / "report.md").read_text(encoding="utf-8"))

    def test_missing_pdf_glyph_fails_without_publishing(self):
        self.data["findings"][0]["description"] = "Synthetic unsupported glyph \U0001f9d1"
        with self.tmpdir() as tmp:
            out = Path(tmp) / "out"
            with self.assertRaises(reportgen.ContractError):
                reportgen.generate(self.raw_for(), out, pdf=True)
            self.assertEqual(list(Path(tmp).iterdir()), [])


if __name__ == "__main__":
    unittest.main()
