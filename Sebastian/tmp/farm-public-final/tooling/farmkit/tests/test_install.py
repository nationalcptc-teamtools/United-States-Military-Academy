"""Installer contracts with synthetic files and mocked privileged/network work."""
import contextlib
import copy
import hashlib
import importlib.util
import io
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

BASE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BASE))
import install as suite


class InstallerTests(unittest.TestCase):
    def setUp(self):
        self.data = suite.manifest()
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.prefix = Path(self.temp.name) / "suite"

    def test_manifest_complete_and_pinned(self):
        self.assertEqual(len(self.data["coverage"]), 40)
        self.assertEqual(set(self.data["sources"]), suite.KINDS)
        self.assertEqual(len(self.data["payloads"]), 2)
        self.assertTrue(set(self.data["profiles"]["core"]["apt"]) <= set(self.data["profiles"]["full"]["apt"]))

    def test_preview_has_no_side_effects(self):
        with patch.object(suite.subprocess, "run", side_effect=AssertionError("subprocess")), patch.object(suite.urllib.request, "urlopen", side_effect=AssertionError("network")), contextlib.redirect_stdout(io.StringIO()) as output:
            self.assertEqual(suite.main(["plan", "--prefix", str(self.prefix)]), 0)
        self.assertFalse(self.prefix.exists())
        self.assertFalse(json.loads(output.getvalue())["mutations_performed"])

    def test_command_failure_and_timeout_are_errors(self):
        with patch.object(suite.subprocess, "run", return_value=subprocess.CompletedProcess([], 9)), self.assertRaises(suite.InstallError):
            suite.run(["synthetic"])
        with patch.object(suite.subprocess, "run", side_effect=subprocess.TimeoutExpired("synthetic", 1)), self.assertRaises(subprocess.TimeoutExpired):
            suite.run(["synthetic"])

    def test_failure_preserves_incomplete_state(self):
        with patch.object(suite.platform, "system", return_value="Linux"), patch.object(Path, "read_text", return_value='ID=kali\n'), patch.object(suite.shutil, "which", return_value="/usr/bin/apt-get"), patch.object(suite.os, "geteuid", return_value=0, create=True), patch.object(suite, "run", side_effect=suite.InstallError("synthetic failure")), self.assertRaises(suite.InstallError):
            suite.install(self.data, "full", self.prefix)
        state = json.loads((self.prefix / "install-state.json").read_text())
        self.assertFalse(state["complete"])
        self.assertEqual(state["failed_step"], "system package index")

    def test_broken_venv_refuses_pip(self):
        (self.prefix / "venvs/ot").mkdir(parents=True)
        with patch.object(suite, "run") as runner, self.assertRaises(suite.InstallError):
            suite.python_group(self.prefix, "ot", ["sample==1"])
        runner.assert_not_called()

    def test_system_interpreter_refuses_pip(self):
        path = self.prefix / "venvs/ot"
        path.mkdir(parents=True)
        (path / "pyvenv.cfg").write_text("home = /usr/bin\n")
        with patch.object(suite, "run", return_value='["/usr", "/usr"]') as runner, self.assertRaises(suite.InstallError):
            suite.python_group(self.prefix, "ot", ["sample==1"])
        self.assertEqual(runner.call_count, 1)
        self.assertIn("-I", runner.call_args.args[0])

    def test_redirected_child_refused_before_commands(self):
        self.prefix.mkdir()
        redirected = self.prefix / "bin"
        redirected.mkdir()
        # Platform-independent coverage; actual POSIX symlinks are covered in Kali.
        original = Path.is_symlink
        with patch.object(Path, "is_symlink", lambda p: p == redirected or original(p)), patch.object(suite, "run") as runner, self.assertRaises(suite.InstallError):
            suite.managed_path(self.prefix, "bin/cptc-report")
        runner.assert_not_called()

    def test_download_mismatch_and_oversize_never_accepted(self):
        self.prefix.mkdir()
        for body, size in ((b"wrong", 5), (b"oversize", 2)):
            response = io.BytesIO(body)
            response.geturl = lambda: "https://example.invalid/fixture"
            with patch.object(suite.urllib.request, "urlopen", return_value=response), self.assertRaises(suite.InstallError):
                suite.fetch("https://example.invalid/fixture", self.prefix / "asset", expected_size=size, expected_sha="0" * 64)
            self.assertEqual(list(self.prefix.iterdir()), [])

    def test_download_exact_and_existing_tamper_preserved(self):
        self.prefix.mkdir()
        response = io.BytesIO(b"fixture")
        response.geturl = lambda: "https://example.invalid/fixture"
        digest = hashlib.sha256(b"fixture").hexdigest()
        destination = self.prefix / "asset"
        with patch.object(suite.urllib.request, "urlopen", return_value=response):
            suite.fetch("https://example.invalid/fixture", destination, expected_size=7, expected_sha=digest)
        with patch.object(suite.urllib.request, "urlopen", side_effect=AssertionError("network")):
            suite.fetch("https://example.invalid/fixture", destination, expected_size=7, expected_sha=digest)
        destination.write_bytes(b"tampered")
        with self.assertRaises(suite.InstallError):
            suite.fetch("https://example.invalid/fixture", destination, expected_size=7, expected_sha=digest)
        self.assertEqual(destination.read_bytes(), b"tampered")

    def test_checkout_wrong_or_dirty_preserved(self):
        path = self.prefix / "src/mbpoll"
        path.mkdir(parents=True)
        for replies in (("0" * 40, ""), (self.data["sources"]["mbpoll"]["commit"], " M file")):
            with patch.object(suite, "run", side_effect=replies), self.assertRaises(suite.InstallError):
                suite.checkout(self.prefix, "mbpoll", self.data["sources"]["mbpoll"])
        self.assertTrue(path.is_dir())

    def test_checker_rejects_empty_required_inventories(self):
        self.prefix.mkdir()
        state = {"complete": True, "profile": "full", "manifest_sha256": suite.file_hash(suite.MANIFEST), "options": {"prowler": False, "legacy_pdf": False}, "apt_packages": [], "native": {}, "python_groups": {}}
        suite.save_state(self.prefix, state)
        with patch.object(suite, "run") as runner, self.assertRaises(suite.InstallError):
            suite.check(self.prefix, self.data, "full")
        runner.assert_not_called()

    def test_installer_does_not_define_target_or_service_commands(self):
        # Fixed manifest contains acquisition/build packages, never lab daemons.
        apt = self.data["profiles"]["full"]["apt"]
        self.assertNotIn("mosquitto", apt)
        self.assertNotIn("suricata", apt)
        self.assertNotIn("zeek", apt)
        self.assertEqual({p["name"] for p in self.data["payloads"]}, {"linpeas.sh", "winPEASx64.exe"})


if __name__ == "__main__":
    unittest.main()
