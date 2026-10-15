"""Local workbench primitives. No network, installation or target dispatch."""
from __future__ import annotations

import hashlib
import json
import math
import os
import re
import shutil
import tempfile
import time
import unicodedata
import uuid
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path

VERSION = "1.0.0"
ROOT = Path(__file__).resolve().parents[2]
MAX_BYTES = 2_000_000


class Error(ValueError):
    """Trusted diagnostic codes; no source values in errors."""


def need(condition, code):
    if not condition:
        raise Error(code)


def now():
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def identity(prefix="item"):
    return prefix + "-" + uuid.uuid4().hex[:16]


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


def encoded(value):
    return (json.dumps(value, ensure_ascii=False, sort_keys=True, indent=2,
                       allow_nan=False) + "\n").encode("utf-8")


def text(value, limit=10000):
    need(isinstance(value, str) and 0 < len(value.strip()) <= limit, "invalid_text")
    need(not any(unicodedata.category(c) in ("Cc", "Cf", "Cs") and c != "\n"
                 for c in value), "unsupported_text")
    return value


def pairs(items):
    result = {}
    for key, value in items:
        need(key not in result, "duplicate_json_key")
        result[key] = value
    return result


def load_bytes(raw):
    need(len(raw) <= MAX_BYTES, "input_too_large")
    try:
        value = json.loads(raw, object_pairs_hook=pairs,
                           parse_constant=lambda _: (_ for _ in ()).throw(Error("nonfinite_number")))
        pending = [(value, 0)]
        while pending:
            item, depth = pending.pop()
            need(depth <= 32, "input_too_deep")
            if isinstance(item, str):
                need(not any(unicodedata.category(c) == "Cs" for c in item), "unsupported_text")
            elif isinstance(item, dict):
                pending.extend((v, depth + 1) for v in item.values())
            elif isinstance(item, list):
                pending.extend((v, depth + 1) for v in item)
            elif isinstance(item, float):
                need(math.isfinite(item), "nonfinite_number")
        return value
    except (ValueError, UnicodeError, RecursionError, OverflowError):
        raise Error("invalid_json") from None


def no_redirect(path):
    path = Path(path).absolute()
    for item in (path, *path.parents):
        if item.exists() or item.is_symlink():
            need(not item.is_symlink(), "redirected_path")
            need(not (getattr(item.lstat(), "st_file_attributes", 0) & 0x400), "redirected_path")
    return path


def read(path):
    path = no_redirect(path)
    need(path.is_file(), "input_not_regular_file")
    for attempt in range(8):
        try:
            with path.open("rb") as handle:
                raw = handle.read(MAX_BYTES + 1)
            break
        except PermissionError:
            if attempt == 7:
                raise
            time.sleep(0.02 * (attempt + 1))
    need(len(raw) <= MAX_BYTES, "input_too_large")
    return raw


def digest_file(path, maximum=512 * 1024 * 1024):
    path = no_redirect(path)
    need(path.is_file() and path.stat().st_size <= maximum, "evidence_file_limit")
    result = hashlib.sha256()
    total = 0
    with path.open("rb") as handle:
        while True:
            raw = handle.read(65536)
            if not raw:
                break
            total += len(raw)
            need(total <= maximum, "evidence_file_limit")
            result.update(raw)
    return result.hexdigest(), total


def load(path):
    return load_bytes(read(path))


def output_path(path):
    path = no_redirect(path)
    resolved = path.resolve()
    for blocked in (ROOT / "sources", ROOT / "tooling"):
        need(resolved != blocked and blocked not in resolved.parents, "protected_destination")
    return path


def bundle(destination, files):
    destination = output_path(destination)
    need(not destination.exists(), "destination_exists")
    for name in files:
        need(isinstance(name, str) and not Path(name).is_absolute()
             and "\\" not in name and ":" not in name
             and all(part not in ("", ".", "..") for part in name.split("/")), "unsafe_member")
    destination.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=".workbench-", dir=destination.parent) as temporary:
        stage = Path(temporary)
        for name, raw in files.items():
            target = stage / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(raw)
        need(not destination.exists(), "destination_exists")
        stage.rename(destination)
    return {name: digest(raw) for name, raw in sorted(files.items())}


def redact(value):
    value = re.sub(r"(?i)\bauthorization\s*[:=]\s*bearer\s+[^\s,;]+", "Authorization=[REDACTED]", str(value))
    value = re.sub(r'''(?ix)(--?(?:password|passwd|pass|token|secret|api[-_]?key|authorization|credential))
                       (?:\s*=\s*|\s+)(?:"[^"]*"|'[^']*'|[^\s,;]+)''',
                   r"\1=[REDACTED]", value)
    value = re.sub(r'''(?ix)\b(password|passwd|token|secret|api[_-]?key|authorization)["']?\s*[:=]\s*
                       (?:"[^"]*"|'[^']*'|[^\s,;]+)''',
                   r"\1=[REDACTED]", str(value))
    return value


def atomic(path, value):
    path = no_redirect(path)
    raw = encoded(value)
    need(len(raw) <= MAX_BYTES, "workspace_limit_reached")
    descriptor, temporary = tempfile.mkstemp(prefix=".state-", dir=path.parent)
    try:
        with os.fdopen(descriptor, "wb") as handle:
            handle.write(raw)
            handle.flush()
            os.fsync(handle.fileno())
        for attempt in range(8):
            try:
                os.replace(temporary, path)
                break
            except PermissionError:
                if attempt == 7:
                    raise
                time.sleep(0.02 * (attempt + 1))
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


@contextmanager
def locked(directory):
    lock = no_redirect(Path(directory) / ".write-lock")
    try:
        handle = lock.open("x", encoding="utf-8")
    except FileExistsError:
        raise Error("workspace_busy") from None
    try:
        handle.write("Work in progress. Do not remove while an editor is active.\n")
        handle.close()
        yield
    finally:
        handle.close()
        lock.unlink(missing_ok=True)


def preflight(destination, required=(), platform=None, free_bytes=1_000_000):
    import sys
    actual = "windows" if os.name == "nt" else "linux" if sys.platform.startswith("linux") else sys.platform
    path = output_path(destination)
    parent = path
    while not parent.exists():
        parent = parent.parent
    checks = {"python_3_10": sys.version_info >= (3, 10),
              "platform": platform in (None, actual),
              "parent_writable": os.access(parent, os.W_OK),
              "free_space": shutil.disk_usage(parent).free >= free_bytes,
              "new_destination": not path.exists()}
    for index, executable in enumerate(required):
        checks[f"dependency_{index + 1}"] = shutil.which(executable) is not None
    return {"platform": actual, "checks": checks, "ready": all(checks.values()),
            "installed_or_executed": False, "event_approved": False}
