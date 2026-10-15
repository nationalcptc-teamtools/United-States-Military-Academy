"""Real synthetic Word exports and all-format publication boundary checks."""
import hashlib
import importlib.util
import io
import json
import socket
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
from xml.etree import ElementTree as ET
from zipfile import ZipFile

MODULE = Path(__file__).resolve().parents[1] / "reportgen.py"
spec = importlib.util.spec_from_file_location("word_reportgen", MODULE)
reportgen = importlib.util.module_from_spec(spec)
spec.loader.exec_module(reportgen)
NS = {"w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main"}


class WordTests(unittest.TestCase):
    def setUp(self):
        self.raw = (MODULE.parent / "examples/report-marked.json").read_bytes()
        self.data = json.loads(self.raw)
        self.parent = reportgen.ROOT / "tmp/word-tests"
        self.parent.mkdir(parents=True, exist_ok=True)
        self.temporary = tempfile.TemporaryDirectory(dir=self.parent)
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)

    def encoded(self):
        return json.dumps(self.data, ensure_ascii=False).encode("utf-8")

    def test_complete_bundle_has_literal_facts_markings_and_safe_word_package(self):
        hostile = '<w:fldSimple w:instr="INCLUDETEXT https://example.test/secret"> *literal* résumé Δ\n    indented'
        self.data["findings"][0]["description"] = hostile
        raw = self.encoded()
        with (patch.object(socket.socket, "connect", side_effect=AssertionError("network")),
              patch.object(socket.socket, "connect_ex", side_effect=AssertionError("network")),
              patch.object(socket, "create_connection", side_effect=AssertionError("network"))):
            manifest = reportgen.generate(raw, self.root / "out", pdf=True, docx=True)
        self.assertEqual(set(manifest["artifacts"]), {"report.md", "report.pdf", "report.docx"})
        for name, expected in manifest["artifacts"].items():
            self.assertEqual(hashlib.sha256((self.root / "out" / name).read_bytes()).hexdigest(), expected)
        self.assertEqual(manifest["input_sha256"], hashlib.sha256(raw).hexdigest())
        from docx import Document
        reopened = Document(self.root / "out/report.docx")
        self.assertEqual(len(reopened.sections), 1)
        self.assertFalse(reopened.sections[0].different_first_page_header_footer)
        self.assertFalse(reopened.settings.odd_and_even_pages_header_footer)
        with ZipFile(self.root / "out/report.docx") as package:
            self.assertFalse(any(n.startswith("customXml/") or n.endswith((".bin", ".jpeg")) for n in package.namelist()))
            roots = {n: ET.fromstring(package.read(n)) for n in package.namelist() if n.endswith((".xml", ".rels"))}
            body = roots["word/document.xml"]
            visible = "".join(node.text or "" for node in body.iter("{" + NS["w"] + "}t"))
            # Newlines are represented by real Word text breaks; source strings stay literal.
            normalized = "".join(visible.split()).casefold()
            for value in reportgen.all_strings(self.data):
                self.assertIn("".join(value.split()).casefold(), normalized)
            self.assertIn("INCLUDETEXT", visible)
            self.assertTrue(body.findall(".//w:br", NS))
            anchors = [node.get("{" + NS["w"] + "}anchor") for node in body.findall(".//w:hyperlink", NS)]
            bookmarks = [node.get("{" + NS["w"] + "}name") for node in body.findall(".//w:bookmarkStart", NS)]
            self.assertEqual(anchors, [f"chapter_{i}" for i in range(1, 6)])
            self.assertEqual(bookmarks, anchors)
            self.assertTrue(body.findall(".//w:numPr", NS))
            for name, root in roots.items():
                if name.endswith(".rels"):
                    self.assertFalse(any(node.get("TargetMode") == "External" for node in root))
                self.assertFalse(any(key.rsplit("}", 1)[-1].startswith("rsid") for node in root.iter() for key in node.attrib))
            fields = [node.get("{" + NS["w"] + "}instr") for root in roots.values()
                      for node in root.findall(".//w:fldSimple", NS)]
            self.assertEqual(fields, ["PAGE"])
            header = "".join(node.text or "" for node in roots["word/header1.xml"].iter("{" + NS["w"] + "}t"))
            self.assertIn("ORCON//PROPIN//PII Red//FI", header)
            self.assertIn("DRAFT", header)
            self.assertFalse(body.findall(".//w:instrText", NS))
            props = package.read("docProps/core.xml").decode()
            self.assertNotIn(str(self.root), props)
            self.assertIn("CPTC reporting starter", props)
            self.assertTrue(all(entry.date_time == (2000, 1, 1, 0, 0, 0) for entry in package.infolist()))

    def test_word_only_is_deterministic_and_legacy_warning_survives(self):
        raw = (MODULE.parent / "examples/report.json").read_bytes()
        first = reportgen.generate(raw, self.root / "one", docx=True)
        second = reportgen.generate(raw, self.root / "two", docx=True)
        self.assertEqual(first, second)
        self.assertEqual((self.root / "one/report.docx").read_bytes(), (self.root / "two/report.docx").read_bytes())
        self.assertEqual(set(first["artifacts"]), {"report.md", "report.docx"})
        with ZipFile(self.root / "one/report.docx") as package:
            self.assertIn(b"LEGACY MARKINGS UNVERIFIED", package.read("word/header1.xml"))
        old = json.loads(raw)
        old["schema_version"] = "1.0"
        for name in ("objective", "recommendations", "methodology_sections"):
            old["engagement"].pop(name, None)
        reportgen.generate(json.dumps(old).encode(), self.root / "legacy", docx=True)

    def test_empty_reviewed_training_copy_keeps_markings(self):
        self.data["findings"] = []
        self.data["markings"] = ["ORCON", "PII Red", "FI"]
        self.data["review"] = {"reviewer": "Synthetic reviewer", "reviewed_at": "2026-10-15"}
        manifest = reportgen.generate(self.encoded(), self.root / "out", release=True, docx=True)
        self.assertEqual(manifest["effective_markings"], "ORCON//PII Red//FI")
        with ZipFile(self.root / "out/report.docx") as package:
            self.assertIn(b"REVIEWED TRAINING COPY", package.read("word/header1.xml"))
            self.assertIn(b"No findings were supplied", package.read("word/document.xml"))

    def test_word_failure_cleans_all_requested_formats(self):
        with patch.object(reportgen, "render_docx", side_effect=RuntimeError("PRIVATE-SENTINEL")):
            with self.assertRaises(RuntimeError):
                reportgen.generate(self.raw, self.root / "out", pdf=True, docx=True)
        self.assertEqual(list(self.root.iterdir()), [])

    def test_missing_word_dependency_is_optional_and_sanitized(self):
        with patch.dict("sys.modules", {"docx": None}):
            reportgen.generate(self.raw, self.root / "markdown")
            with self.assertRaises(reportgen.ContractError) as error:
                reportgen.generate(self.raw, self.root / "word", docx=True)
        self.assertIn("python-docx", str(error.exception))
        self.assertFalse((self.root / "word").exists())

    def test_illegal_xml_fails_safely_and_cli_exposes_word_flag(self):
        self.data["findings"][0]["description"] = "PRIVATE-SENTINEL\uffff"
        with self.assertRaises(reportgen.ContractError) as error:
            reportgen.generate(self.encoded(), self.root / "invalid", docx=True)
        self.assertNotIn("PRIVATE-SENTINEL", str(error.exception))
        source = self.root / "input.json"
        source.write_bytes(self.raw)
        failures = []
        generate = reportgen.generate
        def checked_generate(*args, **kwargs):
            try:
                return generate(*args, **kwargs)
            except Exception as exc:
                failures.append(repr(exc))
                raise
        with (patch("sys.stdout", new_callable=io.StringIO) as output,
              patch.object(reportgen, "generate", side_effect=checked_generate)):
            result = reportgen.main([str(source), "--output-dir", str(self.root / "cli"), "--pdf", "--docx"])
        self.assertEqual(result, 0, failures)
        self.assertIn("Markdown + PDF + Word", output.getvalue())


if __name__ == "__main__":
    unittest.main()
