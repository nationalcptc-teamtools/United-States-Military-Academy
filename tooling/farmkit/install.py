#!/usr/bin/env python3
"""Install supported assessment software. Separate from the passive kit checker."""

import argparse
import hashlib
import json
import os
import platform
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

import kit

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[1]
MANIFEST = BASE / "install-manifest.json"
KINDS = {"mbpoll", "bacnet", "lib60870", "libiec61850", "vulscan"}


class InstallError(RuntimeError):
    pass


def manifest(path=MANIFEST):
    data = kit.load(path)
    kit.obj(data, "schema_version python_groups sources payloads profiles coverage", "install")
    kit.need(data["schema_version"] == "cptc.install/1.0", "install", "unsupported schema")
    kit.need(isinstance(data["python_groups"], dict) and bool(data["python_groups"]), "install", "missing Python groups")
    for name, requirements in data["python_groups"].items():
        kit.need(re.fullmatch(r"[a-z][a-z0-9-]{0,31}", name), "group", "invalid name")
        kit.strings(requirements, "group.requirements")
        kit.need(all(re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_.-]*==[A-Za-z0-9][A-Za-z0-9_.+-]*", r)
                     for r in requirements), "group", "exact package versions required")
    kit.need(isinstance(data["sources"], dict), "sources", "invalid sources")
    for name, source in data["sources"].items():
        kit.obj(source, "repository commit kind version notice", "source")
        kit.need(name in KINDS and source["kind"] == name, "source", "unsupported build kind")
        kit.need(re.fullmatch(r"https://github.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", source["repository"]), "source", "canonical GitHub repository required")
        kit.need(re.fullmatch(r"[0-9a-f]{40}", source["commit"]), "source", "full source commit required")
        kit.string(source["version"], "source.version")
        kit.string(source["notice"], "source.notice")
    kit.need(set(data["profiles"]) == {"core", "full"}, "profiles", "core/full profiles required")
    for profile in data["profiles"].values():
        kit.obj(profile, "apt groups sources", "profile")
        for field in ("apt", "groups", "sources"):
            kit.strings(profile[field], "profile." + field)
        kit.need(all(re.fullmatch(r"[a-z0-9][a-z0-9+.-]*", name) for name in profile["apt"]), "apt", "invalid package name")
        kit.need(set(profile["groups"]) <= set(data["python_groups"]), "profile", "unknown Python group")
        kit.need(set(profile["sources"]) <= set(data["sources"]), "profile", "unknown source")
    kit.need(isinstance(data["payloads"], list) and len(data["payloads"]) == 2, "payloads", "two PEASS assets required")
    names = set()
    for payload in data["payloads"]:
        kit.obj(payload, "name url size sha256 license_url", "payload")
        kit.need(payload["name"] in ("linpeas.sh", "winPEASx64.exe") and payload["name"] not in names, "payload", "invalid payload name")
        names.add(payload["name"])
        kit.need(re.fullmatch(r"https://github.com/peass-ng/PEASS-ng/releases/download/[A-Za-z0-9_.-]+/" + re.escape(payload["name"]), payload["url"]), "payload", "pinned release asset required")
        kit.need(re.fullmatch(r"https://raw.githubusercontent.com/peass-ng/PEASS-ng/[0-9a-f]{40}/LICENSE", payload["license_url"]), "payload", "pinned license required")
        kit.need(type(payload["size"]) is int and 0 < payload["size"] <= 32 * 1024 * 1024, "payload", "invalid size")
        kit.need(re.fullmatch(r"[a-f0-9]{64}", payload["sha256"]), "payload", "digest required")
    kit.need(isinstance(data["coverage"], list) and len(data["coverage"]) == 40, "coverage", "forty records required")
    ids = []
    for item in data["coverage"]:
        kit.obj(item, "tool_id method component note", "coverage")
        kit.string(item["tool_id"], "coverage.id")
        kit.need(item["method"] in ("apt", "python", "source", "payload", "dependency", "optional", "held", "lab"), "coverage", "unknown method")
        kit.string(item["component"], "coverage.component")
        kit.string(item["note"], "coverage.note")
        ids.append(item["tool_id"])
    kit.need(set(ids) == kit.TOOL_IDS and len(set(ids)) == 40, "coverage", "unknown or duplicate tool IDs")
    return data


def prefix_path(value):
    kit.string(str(value), "prefix", 1000)
    path = Path(value).expanduser().absolute()
    kit.need(not path.is_symlink() and ".git" not in path.parts, "prefix", "symlink/Git path rejected")
    resolved = path.resolve()
    kit.need(resolved != Path(resolved.anchor) and not ROOT.is_relative_to(resolved)
             and not resolved.is_relative_to(BASE) and not resolved.is_relative_to(ROOT / "sources"),
             "prefix", "choose a separate suite installation directory")
    for parent in (path, *path.parents):
        if parent.exists():
            st = parent.lstat()
            kit.need(not parent.is_symlink() and not getattr(st, "st_file_attributes", 0) & 0x400,
                     "prefix", "redirected directory rejected")
    return resolved


def run(argv, *, capture=False, env=None, cwd=None, timeout=1800):
    print("+ " + shlex.join([str(a) for a in argv]), flush=True)
    result = subprocess.run([str(a) for a in argv], check=False, text=True,
                            stdout=subprocess.PIPE if capture else None,
                            stderr=subprocess.PIPE if capture else None,
                            env=env, cwd=cwd, timeout=timeout)
    if result.returncode:
        raise InstallError(f"Command failed ({result.returncode}): {Path(str(argv[0])).name}")
    return result.stdout if capture else None


def managed_path(prefix, relative):
    """Check every installer-controlled component before creating/replacing it."""
    current = prefix
    for part in kit.safe_path(relative, "installation path"):
        current = current / part
        if current.exists() or current.is_symlink():
            st = current.lstat()
            if current.is_symlink() or getattr(st, "st_file_attributes", 0) & 0x400:
                raise InstallError("Redirected managed installation path rejected")
    return current


def check_existing_links(prefix):
    """A suite directory must be trusted and quiescent, not concurrently modified."""
    if not prefix.exists():
        return
    for path in prefix.rglob("*"):
        if path.is_symlink():
            target = path.resolve()
            interpreter_link = (path.parent.parent.parent == prefix / "venvs" and path.parent.name == "bin"
                                and (re.fullmatch(r"python[0-9.]*", path.name) or path.name == "𝜋thon")
                                and target == Path(sys.executable).resolve())
            if not target.is_relative_to(prefix) and not interpreter_link:
                raise InstallError("Existing suite contains an external redirect")


def save_state(prefix, state):
    destination = managed_path(prefix, "install-state.json")
    fd, tmp = tempfile.mkstemp(prefix=".install-state-", dir=prefix)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            json.dump(state, handle, indent=2)
            handle.write("\n")
        os.replace(tmp, destination)
    finally:
        if Path(tmp).exists():
            Path(tmp).unlink()


def file_hash(path):
    digest = hashlib.sha256()
    with Path(path).open("rb") as handle:
        while chunk := handle.read(1024 * 1024):
            digest.update(chunk)
    return digest.hexdigest()


def fetch(url, destination, *, expected_size=None, expected_sha=None, limit=32 * 1024 * 1024):
    destination = Path(destination)
    if destination.exists():
        if expected_sha and destination.is_file() and not destination.is_symlink() and file_hash(destination) == expected_sha:
            return
        raise InstallError("Existing download differs from expected bytes; preserve it and choose a clean prefix.")
    fd, tmp = tempfile.mkstemp(prefix=".download-", dir=destination.parent)
    total, digest = 0, hashlib.sha256()
    try:
        request = urllib.request.Request(url, headers={"User-Agent": "CPTC-suite-installer/1.1"})
        with os.fdopen(fd, "wb") as target, urllib.request.urlopen(request, timeout=60) as source:
            if not source.geturl().startswith("https://"):
                raise InstallError("Download redirected away from HTTPS")
            while chunk := source.read(1024 * 1024):
                total += len(chunk)
                if total > limit or (expected_size is not None and total > expected_size):
                    raise InstallError("Download exceeds expected size")
                target.write(chunk)
                digest.update(chunk)
        if (expected_size is not None and total != expected_size) or (expected_sha and digest.hexdigest() != expected_sha):
            raise InstallError("Download size/SHA-256 mismatch; asset was not accepted")
        os.replace(tmp, destination)
    finally:
        if Path(tmp).exists():
            Path(tmp).unlink()


def checkout(prefix, name, source):
    path = managed_path(prefix, "src/" + name)
    if path.exists():
        actual = run(["git", "-C", path, "rev-parse", "HEAD"], capture=True).strip()
        dirty = run(["git", "-C", path, "status", "--porcelain"], capture=True).strip()
        if actual != source["commit"] or dirty:
            raise InstallError("Existing source has a different commit or modifications; it was preserved")
        return path
    path.parent.mkdir(parents=True, exist_ok=True)
    path.mkdir()
    run(["git", "-C", path, "init", "-q"])
    run(["git", "-C", path, "remote", "add", "origin", source["repository"]])
    run(["git", "-C", path, "fetch", "--quiet", "--depth=1", "origin", source["commit"]])
    run(["git", "-C", path, "checkout", "--quiet", "--detach", "FETCH_HEAD"])
    if run(["git", "-C", path, "rev-parse", "HEAD"], capture=True).strip() != source["commit"]:
        raise InstallError("Fetched source commit mismatch")
    return path


def native(prefix, name, source):
    src = checkout(prefix, name, source)
    build = managed_path(prefix, "build/" + name)
    if name == "vulscan":
        if not (src / "vulscan.nse").is_file():
            raise InstallError("Pinned Vulscan source missing entry point")
        link = ROOT / "vulscan"
        if link.is_symlink() and link.resolve() != src.resolve():
            raise InstallError("Existing repository Vulscan link was preserved; choose the pinned source explicitly")
        if link.exists() and not link.is_symlink():
            raise InstallError("Existing repository Vulscan directory was preserved; move it aside before using this installer")
        if not link.exists() and not link.is_symlink():
            link.symlink_to(src, target_is_directory=True)
        return {"commit": source["commit"], "files": {p.relative_to(prefix).as_posix(): file_hash(p)
                for p in (src / "vulscan.nse", src / "COPYING.TXT")}, "notice": source["notice"]}
    cmake_source = src / "lib60870-C" if name == "lib60870" else src
    flags = ["-DCMAKE_BUILD_TYPE=Release", "-DCMAKE_INSTALL_PREFIX=" + str(prefix), "-DCMAKE_INSTALL_LIBDIR=lib"]
    target = None
    if name == "bacnet":
        flags += ["-DBACNET_STACK_BUILD_APPS=ON", "-DBAC_ROUTING=OFF", "-DBACDL_BIP=ON", "-DBACDL_BIP6=OFF", "-DBACDL_ZIGBEE=OFF", "-DBACDL_BSC=OFF"]
        target = "readprop"
    elif name in ("lib60870", "libiec61850"):
        flags += ["-DBUILD_EXAMPLES=OFF", "-DBUILD_TESTS=OFF", "-DBUILD_PYTHON_BINDINGS=OFF"]
    run(["cmake", "-S", cmake_source, "-B", build, *flags])
    run(["cmake", "--build", build, "--parallel", "2", *(["--target", target] if target else [])])
    if name in ("mbpoll", "bacnet"):
        filename = "mbpoll" if name == "mbpoll" else "readprop"
        matches = [p for p in build.rglob(filename) if p.is_file() and os.access(p, os.X_OK)]
        if len(matches) != 1:
            raise InstallError("Native build did not produce one expected client binary")
        installed = managed_path(prefix, "bin/" + ("mbpoll" if name == "mbpoll" else "bacnet-readprop"))
        shutil.copy2(matches[0], installed)
        return {"commit": source["commit"], "files": {installed.relative_to(prefix).as_posix(): file_hash(installed)}, "notice": source["notice"]}
    managed_path(prefix, "lib")
    managed_path(prefix, "include")
    run(["cmake", "--install", build])
    fragment = "60870" if name == "lib60870" else "iec61850"
    libraries = [p for p in (prefix / "lib").rglob("*" + fragment + "*") if p.is_file() and not p.is_symlink()]
    header = "cs104_connection.h" if name == "lib60870" else "iec61850_client.h"
    headers = list((prefix / "include").rglob(header))
    if not libraries or not headers:
        raise InstallError("Expected installed native library/header missing")
    return {"commit": source["commit"], "files": {p.relative_to(prefix).as_posix(): file_hash(p) for p in [*libraries, *headers]}, "notice": source["notice"]}


def venv_python(prefix, name):
    venv = managed_path(prefix, "venvs/" + name)
    if not managed_path(prefix, "venvs/" + name + "/pyvenv.cfg").is_file():
        raise InstallError("Python environment configuration missing; pip was not run")
    interpreter = venv / "bin/python"
    identity = json.loads(run([interpreter, "-I", "-c", "import json,sys; print(json.dumps([sys.prefix,sys.base_prefix]))"], capture=True))
    if len(identity) != 2 or Path(identity[0]).resolve() != venv.resolve() or identity[0] == identity[1]:
        raise InstallError("Python interpreter is not the expected isolated environment; pip was not run")
    return interpreter


def python_group(prefix, name, requirements):
    venv = managed_path(prefix, "venvs/" + name)
    if not venv.exists():
        run([sys.executable, "-m", "venv", venv])
    interpreter = venv_python(prefix, name)
    run([interpreter, "-m", "pip", "--disable-pip-version-check", "install", "--no-input", "--progress-bar", "off", *requirements])
    run([interpreter, "-m", "pip", "check"])
    installed = json.loads(run([interpreter, "-m", "pip", "list", "--format=json", "--disable-pip-version-check"], capture=True))
    return {"requirements": requirements, "packages": installed, "interpreter": str(interpreter)}


def validate_state(state):
    """Validate persisted inventory before looking up paths or invoking metadata tools."""
    if not isinstance(state, dict) or state.get("schema_version") != "cptc.install-state/1.0":
        raise InstallError("Invalid installation inventory schema")
    options = state.get("options")
    if not isinstance(options, dict) or set(options) != {"prowler", "legacy_pdf"} or any(type(v) is not bool for v in options.values()):
        raise InstallError("Invalid installation choices")
    if not isinstance(state.get("apt_packages"), list) or not all(isinstance(v, str) for v in state["apt_packages"]):
        raise InstallError("Invalid distro inventory")
    if not isinstance(state.get("native"), dict) or not isinstance(state.get("python_groups"), dict):
        raise InstallError("Invalid component inventory")
    for source in state["native"].values():
        if not isinstance(source, dict) or not isinstance(source.get("commit"), str) or not re.fullmatch(r"[a-f0-9]{40}", source["commit"]):
            raise InstallError("Invalid native source inventory")
        files = source.get("files")
        if not isinstance(files, dict) or not files:
            raise InstallError("Invalid native file inventory")
        for relative, digest in files.items():
            try:
                kit.safe_path(relative, "native file")
            except kit.Invalid:
                raise InstallError("Invalid native file path") from None
            if not isinstance(digest, str) or not re.fullmatch(r"[a-f0-9]{64}", digest):
                raise InstallError("Invalid native file digest")


def check(prefix, data, profile):
    check_existing_links(prefix)
    state_path = managed_path(prefix, "install-state.json")
    if not state_path.is_file():
        raise InstallError("No installation inventory found; run install first")
    state = kit.load(state_path)
    validate_state(state)
    if state.get("complete") is not True or state.get("profile") != profile:
        raise InstallError("Installation is incomplete or uses a different profile")
    if state.get("manifest_sha256") != file_hash(MANIFEST):
        raise InstallError("Installation manifest changed; rerun installation/check the update")
    expected = data["profiles"][profile]
    options = state.get("options")
    if not isinstance(options, dict) or set(options) != {"prowler", "legacy_pdf"} or any(type(v) is not bool for v in options.values()):
        raise InstallError("Installation choices missing or invalid")
    apt = [*expected["apt"], *(["prowler"] if options["prowler"] else []), *(["wkhtmltopdf"] if options["legacy_pdf"] else [])]
    if state.get("apt_packages") != apt or set(state.get("native", {})) != set(expected["sources"]) or set(state.get("python_groups", {})) != set(expected["groups"]):
        raise InstallError("Required installation inventory is incomplete")
    for name in data["profiles"][profile]["groups"]:
        interpreter = venv_python(prefix, name)
        if not interpreter.is_file():
            raise InstallError("Missing installed Python environment")
        # Reads distribution metadata; imports/entry points of assessment tools are not executed.
        actual = json.loads(run([interpreter, "-m", "pip", "list", "--format=json", "--disable-pip-version-check"], capture=True))
        versions = {p["name"].lower().replace("_", "-"): p["version"] for p in actual}
        for requirement in data["python_groups"][name]:
            package, version = requirement.split("==")
            if versions.get(package.lower().replace("_", "-")) != version:
                raise InstallError("Installed Python version differs from manifest")
        run([interpreter, "-m", "pip", "check"])
    for payload in data["payloads"]:
        path = prefix / "payloads" / payload["name"]
        if not path.is_file() or path.is_symlink() or path.stat().st_size != payload["size"] or file_hash(path) != payload["sha256"]:
            raise InstallError("Missing or changed PEASS asset")
    for name in expected["sources"]:
        source = state["native"][name]
        if source.get("commit") != data["sources"][name]["commit"] or not isinstance(source.get("files"), dict) or not source["files"]:
            raise InstallError("Required native artifact/commit inventory missing")
        paths = set(source["files"])
        required = {"mbpoll": {"bin/mbpoll"}, "bacnet": {"bin/bacnet-readprop"},
                    "vulscan": {"src/vulscan/vulscan.nse", "src/vulscan/COPYING.TXT"}}
        if name in required and paths != required[name]:
            raise InstallError("Required native artifact identity missing")
        if name in ("lib60870", "libiec61850"):
            fragment = "60870" if name == "lib60870" else "iec61850"
            header = "cs104_connection.h" if name == "lib60870" else "iec61850_client.h"
            if not any(p.startswith("lib/") and fragment in Path(p).name for p in paths) or not any(p.startswith("include/") and Path(p).name == header for p in paths):
                raise InstallError("Required native library/header identity missing")
        source_dir = managed_path(prefix, "src/" + name)
        actual_commit = run(["git", "-C", source_dir, "rev-parse", "HEAD"], capture=True).strip()
        dirty = run(["git", "-C", source_dir, "status", "--porcelain"], capture=True).strip()
        if actual_commit != source["commit"] or dirty:
            raise InstallError("Installed source differs from pinned clean checkout")
        for relative, digest in source["files"].items():
            path = managed_path(prefix, relative)
            if not path.is_file() or file_hash(path) != digest:
                raise InstallError("Missing or changed native artifact")
    for required in ("payloads/PEASS-LICENSE", "payloads/SOURCE.txt", "activate", "bin/cptc-report"):
        if not managed_path(prefix, required).is_file():
            raise InstallError("Required notice/activation/entry point missing")
    status = run(["dpkg-query", "-W", "-f=${Package}\t${db:Status-Status}\t${Version}\n", *apt], capture=True)
    rows = [line.split("\t") for line in status.splitlines()]
    if len(rows) != len(apt) or any(len(row) != 3 or row[1] != "installed" for row in rows) or {r[0] for r in rows} != set(apt):
        raise InstallError("Required distro package is not installed")
    if "vulscan" in expected["sources"] and (not (ROOT / "vulscan").is_symlink() or (ROOT / "vulscan").resolve() != (prefix / "src/vulscan").resolve()):
        raise InstallError("Legacy Vulscan source link missing or changed")
    print("Installed assessment profile verified. No target, payload or lab service was launched.")
    print("Operational, license/output-integration and event readiness remain separate.")
    return state


def install(data, profile, prefix, *, skip_system=False, prowler=False, legacy_pdf=False):
    if platform.system() != "Linux" or shutil.which("apt-get") is None:
        raise InstallError("Execution requires Kali/Linux with apt-get; preview works on other platforms")
    distro = Path("/etc/os-release").read_text(encoding="utf-8")
    if profile == "full" and not re.search(r'^ID=(?:"kali"|kali)$', distro, re.M):
        raise InstallError("The full profile targets Kali Linux; use an isolated Kali environment")
    if not (ROOT / "tooling/reporting/reportgen.py").is_file():
        raise InstallError("Complete repository checkout including tooling/reporting is required")
    apt = list(data["profiles"][profile]["apt"])
    if prowler:
        apt.append("prowler")
    if legacy_pdf:
        apt.append("wkhtmltopdf")
    check_existing_links(prefix)
    for directory in ("bin", "lib", "include", "venvs", "src", "build", "payloads"):
        managed_path(prefix, directory)
    for leaf in ("activate", "install-state.json", "bin/cptc-report", "payloads/SOURCE.txt", "payloads/PEASS-LICENSE"):
        managed_path(prefix, leaf)
    state = {"schema_version": "cptc.install-state/1.0", "profile": profile, "options": {"prowler": prowler, "legacy_pdf": legacy_pdf},
             "manifest_sha256": file_hash(MANIFEST), "started_at": datetime.now(timezone.utc).isoformat(),
             "complete": False, "steps": [], "apt_packages": apt, "native": {}, "python_groups": {}, "payloads": []}
    prefix.mkdir(parents=True, exist_ok=True)
    managed_path(prefix, "bin").mkdir(exist_ok=True)
    save_state(prefix, state)

    def step(name, action):
        print("Installing " + name, flush=True)
        state["current_step"] = name
        save_state(prefix, state)
        try:
            value = action()
        except Exception:
            state["failed_step"] = name
            save_state(prefix, state)
            raise
        state["steps"].append(name)
        save_state(prefix, state)
        return value

    if not skip_system:
        sudo = [] if os.geteuid() == 0 else ["sudo"]
        env = os.environ.copy()
        env["DEBIAN_FRONTEND"] = "noninteractive"
        step("system package index", lambda: run([*sudo, "apt-get", "update"], env=env))
        step("system packages", lambda: run([*sudo, "env", "DEBIAN_FRONTEND=noninteractive", "apt-get", "install", "-y", "--no-install-recommends", *apt]))
    state["apt_versions"] = run(["dpkg-query", "-W", "-f=${Package}=${Version}\n", *apt], capture=True)
    for name in data["profiles"][profile]["groups"]:
        state["python_groups"][name] = step("Python " + name, lambda name=name: python_group(prefix, name, data["python_groups"][name]))
    for name in data["profiles"][profile]["sources"]:
        state["native"][name] = step("source " + name, lambda name=name: native(prefix, name, data["sources"][name]))
    payload_dir = managed_path(prefix, "payloads")
    payload_dir.mkdir(exist_ok=True)
    for payload in data["payloads"]:
        destination = managed_path(prefix, "payloads/" + payload["name"])
        step("stage " + payload["name"], lambda payload=payload, destination=destination: fetch(payload["url"], destination, expected_size=payload["size"], expected_sha=payload["sha256"]))
        state["payloads"].append({"name": payload["name"], "sha256": payload["sha256"], "source": payload["url"]})
    if not (payload_dir / "PEASS-LICENSE").exists():
        step("PEASS original notice", lambda: fetch(data["payloads"][0]["license_url"], payload_dir / "PEASS-LICENSE", limit=128 * 1024))
    managed_path(prefix, "payloads/SOURCE.txt").write_text("Unmodified PEASS release assets; never executed by setup.\nSource and original license:\n" + data["payloads"][0]["license_url"] + "\nWinPEAS x64 requires Windows/.NET Framework 4.8; execution and output integration remain unverified.\n", encoding="utf-8")
    ordered_groups = ["ot", *[g for g in data["profiles"][profile]["groups"] if g != "ot"]]
    path_parts = [prefix / "bin", *[prefix / "venvs" / group / "bin" for group in ordered_groups]]
    managed_path(prefix, "activate").write_text("# Source this file in a POSIX shell. No tool is started.\nexport CPTC_SUITE_PREFIX=" + shlex.quote(str(prefix)) + "\nexport PATH=" + shlex.quote(":".join(map(str, path_parts))) + ':"$PATH"\n', encoding="utf-8")
    report = managed_path(prefix, "bin/cptc-report")
    report.write_text("#!/bin/sh\nexec " + shlex.quote(str(prefix / "venvs/reporting/bin/python")) + " " + shlex.quote(str(ROOT / "tooling/reporting/reportgen.py")) + ' "$@"\n', encoding="utf-8")
    report.chmod(0o755)
    state["complete"] = True
    state["finished_at"] = datetime.now(timezone.utc).isoformat()
    save_state(prefix, state)
    try:
        check(prefix, data, profile)
    except Exception:
        state["complete"] = False
        state["failed_step"] = "final installation check"
        save_state(prefix, state)
        raise
    print("Activate with: source " + shlex.quote(str(prefix / "activate")))


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("plan", "install", "check"))
    parser.add_argument("--profile", choices=("core", "full"), default="full")
    parser.add_argument("--prefix", type=Path, default=ROOT / ".cptc-suite")
    parser.add_argument("--skip-system", action="store_true", help="Advanced: verify already installed apt prerequisites")
    parser.add_argument("--with-prowler", action="store_true", help="Optional Kali Prowler package")
    parser.add_argument("--with-legacy-pdf", action="store_true", help="Optional wkhtmltopdf if available in selected distro")
    args = parser.parse_args(argv)
    try:
        data, prefix = manifest(), prefix_path(args.prefix)
        if args.command == "plan":
            print(json.dumps({"profile": args.profile, "prefix": str(prefix), **data["profiles"][args.profile],
                              "payloads": [{"name": p["name"], "sha256": p["sha256"]} for p in data["payloads"]],
                              "optional_prowler": args.with_prowler, "optional_legacy_pdf": args.with_legacy_pdf,
                              "coverage": data["coverage"], "mutations_performed": False}, indent=2))
        elif args.command == "check":
            check(prefix, data, args.profile)
        else:
            install(data, args.profile, prefix, skip_system=args.skip_system,
                    prowler=args.with_prowler, legacy_pdf=args.with_legacy_pdf)
        return 0
    except (kit.Invalid, InstallError, OSError, ValueError, TypeError, KeyError, subprocess.SubprocessError, urllib.error.URLError) as exc:
        detail = str(exc) if isinstance(exc, (kit.Invalid, InstallError)) else type(exc).__name__
        print("Suite operation failed (" + detail + "); installation is not accepted. See the last step and local install-state.json. No target activity was performed.", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
