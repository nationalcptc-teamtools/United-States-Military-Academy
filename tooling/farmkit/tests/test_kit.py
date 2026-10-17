import contextlib
import copy
import hashlib
import importlib.util
import io
import json
import os
import re
import socket
import subprocess
import tempfile
import unittest
import zipfile
from pathlib import Path
from unittest.mock import patch

BASE = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("farmkit", BASE / "kit.py")
kit = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(kit)
BUILD_SPEC = importlib.util.spec_from_file_location("farmkit_build", BASE / "build.py")
builder = importlib.util.module_from_spec(BUILD_SPEC)
with patch.dict("sys.modules", {"kit": kit}):
    BUILD_SPEC.loader.exec_module(builder)


class KitTests(unittest.TestCase):
    def setUp(self):
        self.data = kit.load(BASE / "catalog.json")
        self.tools = kit.catalog(self.data)
        self.lock = kit.load(BASE / "examples/synthetic-lock.json")

    def test_forty_dispositions_and_named_holds(self):
        self.assertEqual(len(self.tools), 40)
        self.assertEqual(sum(t["disposition"] == "selected" for t in self.tools.values()), 8)
        self.assertEqual(sum(t["disposition"] == "hold" for t in self.tools.values()), 7)
        self.assertEqual(self.tools["TOOL-001"]["name"], "LinPEAS")
        self.assertEqual(self.tools["TOOL-002"]["name"], "WinPEAS")
        self.assertTrue(all(t["runtime_status"] == "not_run" for t in self.tools.values()))

    def test_missing_duplicate_unknown_and_nontext_tool_id(self):
        for change in (lambda x: x["tools"].pop(),
                       lambda x: x["tools"][0].update(id="TOOL-002"),
                       lambda x: x["tools"][0].update(id="TOOL-999"),
                       lambda x: x["tools"][0].update(id=[])):
            with self.subTest(change=change):
                data = copy.deepcopy(self.data)
                change(data)
                with self.assertRaises(kit.Invalid):
                    kit.catalog(data)

    def test_unknown_schema_field_enum_and_type(self):
        changes = [("schema_version", "2.0"), ("unknown", "x")]
        for key, value in changes:
            data = copy.deepcopy(self.data)
            data[key] = value
            with self.assertRaises(kit.Invalid):
                kit.catalog(data)
        for key, value in [("disposition", "ready"), ("operations", "O"), ("runbook", []),
                           ("priority", False), ("runtime_status", "approved")]:
            with self.subTest(key=key):
                data = copy.deepcopy(self.data)
                data["tools"][0][key] = value
                with self.assertRaises(kit.Invalid):
                    kit.catalog(data)

    def test_hold_and_inactive_cannot_be_selected(self):
        for n in (0, 18, 27):
            data = copy.deepcopy(self.data)
            data["tools"][n]["disposition"] = "selected"
            with self.assertRaises(kit.Invalid):
                kit.catalog(data)

    def test_control_characters_rejected_without_echo(self):
        data = copy.deepcopy(self.data)
        data["tools"][0]["name"] = "SECRET-SENTINEL\x1b[2J"
        with self.assertRaises(kit.Invalid) as caught:
            kit.catalog(data)
        self.assertNotIn("SECRET-SENTINEL", str(caught.exception))

    def test_surrogate_text_and_nul_input_path_rejected(self):
        data = copy.deepcopy(self.data)
        data["tools"][0]["name"] = "SECRET-SENTINEL\ud800"
        with self.assertRaises(kit.Invalid) as caught:
            kit.catalog(data)
        self.assertNotIn("SECRET-SENTINEL", str(caught.exception))
        with contextlib.redirect_stderr(io.StringIO()) as err:
            self.assertEqual(kit.main(["validate", "--catalog", "invalid\x00path"]), 2)
        self.assertNotIn("invalid\x00path", err.getvalue())

    def test_unsafe_credentials_and_bad_ports_in_references(self):
        for value in ("http://example.invalid", "https://user:secret@example.invalid",
                      "https://example.invalid:bad", "https://example.invalid/has space"):
            with self.subTest(value=value), self.assertRaises(kit.Invalid):
                kit.url(value, "reference")

    def test_sources_bind_exact_commits_and_licenses(self):
        sources = kit.load(BASE / "sources.json")
        kit.sources(sources, self.tools)
        for key, value in [("commit", "main"), ("sha256", "a" * 64),
                           ("archive_candidate", "https://example.invalid/latest.tar.gz"),
                           ("license_evidence", ["https://example.invalid/license"])]:
            bad = copy.deepcopy(sources)
            bad["projects"][0][key] = value
            with self.assertRaises(kit.Invalid):
                kit.sources(bad, self.tools)

    def test_selected_coverage_and_source_coverage_required(self):
        data = copy.deepcopy(self.data)
        data["tools"][16]["protocols"] = ["unknown"]
        with self.assertRaises(kit.Invalid):
            kit.catalog(data)
        refs = kit.load(BASE / "sources.json")
        refs["projects"].pop()
        with self.assertRaises(kit.Invalid):
            kit.sources(refs, self.tools)

    def test_good_synthetic_integrity_and_no_input_mutation(self):
        before = (BASE / "examples/artifacts/fixture.txt").read_bytes()
        items = kit.artifact_lock(self.lock, self.tools)
        kit.verify(items, BASE / "examples/artifacts")
        self.assertEqual((BASE / "examples/artifacts/fixture.txt").read_bytes(), before)

    def test_tampered_missing_and_wrong_size(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            items = kit.artifact_lock(self.lock, self.tools)
            with self.assertRaises(OSError):
                kit.verify(items, root)
            (root / "fixture.txt").write_bytes(b"tampered")
            with self.assertRaises(kit.Invalid):
                kit.verify(items, root)
            bad = copy.deepcopy(self.lock)
            bad["artifacts"][0]["size"] = 1
            with self.assertRaises(kit.Invalid):
                kit.verify(kit.artifact_lock(bad, self.tools), BASE / "examples/artifacts")

    def test_bad_paths_and_duplicate_casefold_paths(self):
        for path in ("../secret", "folder/../secret", "/etc/passwd", "C:/secret", "\\\\server\\share",
                     "a\\b", "CON.txt", "foo/NUL", "foo.", "foo ", "foo//bar", "a%2fb", "a:b"):
            with self.subTest(path=path), self.assertRaises(kit.Invalid):
                kit.safe_path(path, "path")
        bad = copy.deepcopy(self.lock)
        other = copy.deepcopy(bad["artifacts"][0])
        other.update(id="SYNTHETIC-2", path="FIXTURE.TXT")
        bad["artifacts"].append(other)
        with self.assertRaises(kit.Invalid):
            kit.artifact_lock(bad, self.tools)

    def test_size_bool_digest_commit_and_dependency_errors(self):
        for key, value in [("size", True), ("size", -1), ("size", kit.MAX_ARTIFACT + 1),
                           ("sha256", None), ("sha256", "A"*64), ("source_commit", "latest"),
                           ("dependencies", ["UNKNOWN"]), ("dependencies", ["SYNTHETIC-ARTIFACT-001"])]:
            with self.subTest(key=key, value=value):
                bad = copy.deepcopy(self.lock)
                bad["artifacts"][0][key] = value
                with self.assertRaises(kit.Invalid):
                    kit.artifact_lock(bad, self.tools)

    def test_dependency_cycle_and_duplicate_id(self):
        bad = copy.deepcopy(self.lock)
        other = copy.deepcopy(bad["artifacts"][0])
        other.update(id="SYNTHETIC-2", path="another.txt", dependencies=["SYNTHETIC-ARTIFACT-001"])
        bad["artifacts"][0]["dependencies"] = ["SYNTHETIC-2"]
        bad["artifacts"].append(other)
        with self.assertRaises(kit.Invalid):
            kit.artifact_lock(bad, self.tools)
        other["id"] = "SYNTHETIC-ARTIFACT-001"
        with self.assertRaises(kit.Invalid):
            kit.artifact_lock(bad, self.tools)

    def test_synthetic_cannot_claim_upstream_and_hold_cannot_stage(self):
        for tid in ("TOOL-001", "TOOL-003"):
            bad = copy.deepcopy(self.lock)
            bad["artifacts"][0]["tool_ids"] = [tid]
            with self.assertRaises(kit.Invalid):
                kit.artifact_lock(bad, self.tools)
            bad["data_category"] = "upstream"
            bad["artifacts"][0]["license_review"] = "reviewed"
            with self.assertRaises(kit.Invalid):
                kit.artifact_lock(bad, self.tools)

    def test_successful_hash_does_not_clear_readiness(self):
        ledger = kit.load(BASE / "readiness.json")
        gaps = kit.readiness(ledger, self.tools)
        self.assertIn("windows-host", gaps)
        self.assertIn("OD-FT-01", gaps)
        self.assertIn("TOOL-013:runtime", gaps)
        with contextlib.redirect_stdout(io.StringIO()) as out:
            result = kit.main(["readiness", "--lock", str(BASE / "examples/synthetic-lock.json")])
        self.assertEqual(result, 3)
        self.assertIn("upstream-artifacts:not-acquired", out.getvalue())

    def test_all_human_records_still_cannot_substitute_tool_acquisition(self):
        data = kit.load(BASE / "readiness.json")
        for group in ("gates", "rehearsals"):
            for item in data[group]:
                item.update(state="recorded", evidence=["synthetic-review-reference"])
        self.assertIn("TOOL-003:runtime", kit.readiness(data, self.tools))
        data["gates"][0]["evidence"] = []
        with self.assertRaises(kit.Invalid):
            kit.readiness(data, self.tools)

    def test_recorded_readiness_requires_complete_unique_ids(self):
        data = kit.load(BASE / "readiness.json")
        data["gates"][0]["id"] = []
        with self.assertRaises(kit.Invalid):
            kit.readiness(data, self.tools)
        data = kit.load(BASE / "readiness.json")
        data["rehearsals"].pop()
        with self.assertRaises(kit.Invalid):
            kit.readiness(data, self.tools)

    def test_json_duplicate_nonfinite_utf8_oversize_and_deep(self):
        inputs = [b'{"x":1,"x":2}', b'{"x":NaN}', b'\xff', b'{',
                  b' '*(kit.MAX_JSON+1), b'['*1500+b']'*1500,
                  b'{"x":'+b'9'*5000+b'}']
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "input.json"
            for raw in inputs:
                path.write_bytes(raw)
                with self.subTest(size=len(raw)), self.assertRaises(kit.Invalid):
                    kit.load(path)

    def test_cli_no_network_no_process_and_pending_empty_inventory(self):
        with patch.object(socket, "socket", side_effect=AssertionError("network forbidden")), \
             patch.object(socket, "getaddrinfo", side_effect=AssertionError("DNS forbidden")), \
             patch.object(subprocess, "Popen", side_effect=AssertionError("process forbidden")), \
             contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(kit.main(["validate"]), 0)
            self.assertEqual(kit.main(["list", "--disposition", "selected"]), 0)
            self.assertEqual(kit.main(["verify", "--root", str(BASE / "examples/artifacts")]), 3)
            self.assertEqual(kit.main(["verify", "--lock", str(BASE / "examples/synthetic-lock.json"),
                                       "--root", str(BASE / "examples/artifacts")]), 0)
            self.assertEqual(kit.main(["readiness"]), 3)

    def test_cli_bad_input_does_not_echo_or_traceback(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "input.json"
            path.write_text('{"SECRET-SENTINEL": NaN}', encoding="utf-8")
            with contextlib.redirect_stderr(io.StringIO()) as err:
                self.assertEqual(kit.main(["validate", "--catalog", str(path)]), 2)
            self.assertNotIn("SECRET-SENTINEL", err.getvalue())
            self.assertNotIn("Traceback", err.getvalue())

    def test_reparse_and_mocked_symlink_rejected(self):
        class Reparse:
            st_mode = 0o040755
            st_file_attributes = 0x400

        class Symlink:
            st_mode = 0o120777
            st_file_attributes = 0

        for redirected in (Reparse(), Symlink()):
            with patch.object(Path, "lstat", return_value=redirected), self.assertRaises(kit.Invalid):
                kit.regular_path(BASE / "examples/artifacts", "fixture.txt")

    def test_native_symlink_rejected_when_permitted(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root/"target").write_text("synthetic", encoding="utf-8")
            try:
                os.symlink(root/"target", root/"link")
            except OSError:
                self.skipTest("Native symlink privilege unavailable; mocked reparse/symlink checks are separate.")
            with self.assertRaises(kit.Invalid):
                kit.regular_path(root, "link")

    def test_nonregular_file_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            (Path(tmp)/"nested").mkdir()
            with self.assertRaises(kit.Invalid):
                kit.regular_path(Path(tmp), "nested")

    def test_package_hashes_allowlist_and_repeatability(self):
        with tempfile.TemporaryDirectory() as tmp:
            one, two = Path(tmp)/"one.zip", Path(tmp)/"two.zip"
            first, second = builder.build(one), builder.build(two)
            self.assertEqual(first, second)
            self.assertEqual(one.read_bytes(), two.read_bytes())
            with zipfile.ZipFile(one) as archive:
                self.assertEqual(set(archive.namelist()), {"MANIFEST.json", *["tooling/farmkit/"+f for f in builder.FILES], *builder.EXTRA_FILES})
                manifest = json.loads(archive.read("MANIFEST.json"))
                self.assertFalse(manifest["upstream_software_included"])
                for name, meta in manifest["files"].items():
                    raw = archive.read(name)
                    self.assertEqual(len(raw), meta["size"])
                    self.assertEqual(hashlib.sha256(raw).hexdigest(), meta["sha256"])

    def test_package_refuses_overwrite_and_source_output(self):
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp)/"existing.zip"
            out.write_bytes(b"preserve")
            with self.assertRaises(OSError):
                builder.build(out)
            self.assertEqual(out.read_bytes(), b"preserve")
        with self.assertRaises(kit.Invalid):
            builder.build(BASE/"forbidden.zip")

    def test_module_references_and_document_metadata_match_catalog(self):
        guide = (BASE/"CATALOG.md").read_text(encoding="utf-8")
        for tid, tool in self.tools.items():
            self.assertIn(tid+" ["+tool["name"]+"]", guide)
            file, fragment = tool["runbook"].split("#", 1)
            document = (BASE/file).read_text(encoding="utf-8")
            headings = re.findall(r"^#{1,6} (.+)$", document, re.M)
            slugs = {re.sub(r"[^\w -]", "", heading.lower()).replace(" ", "-") for heading in headings}
            self.assertIn(fragment, slugs, tool["runbook"])
        examples = kit.load(BASE/"examples/run-statuses.json")
        self.assertEqual(examples["data_category"], "synthetic")
        self.assertEqual({e["status"] for e in examples["examples"]}, {"success-empty", "partial", "failed", "not-run"})
        self.assertTrue(all(e["source_sha256"] is None for e in examples["examples"]))
        self.assertEqual(self.tools["TOOL-037"]["license"]["evidence"],
                         ["https://github.com/Autonomy-Logic/openplc-runtime/blob/main/LICENSE"])


    def test_audit_windows_reserved_name_variants_rejected(self):
        for name in ('CON .txt', 'NUL .txt', 'COM\u00b9.log', 'LPT\u00b2.log', 'nested/COM\u00b3.txt'):
            with self.subTest(name=name), self.assertRaises(kit.Invalid):
                kit.safe_path(name, 'fixture')

    def test_audit_nul_package_destination_is_clean_rejection(self):
        with contextlib.redirect_stderr(io.StringIO()) as error, \
             patch.object(Path, 'resolve', side_effect=AssertionError('destination access')):
            self.assertEqual(builder.main(['SENTINEL\x00output.zip']), 2)
        self.assertNotIn('Traceback', error.getvalue())
        self.assertNotIn('SENTINEL', error.getvalue())

if __name__ == "__main__":
    unittest.main()
