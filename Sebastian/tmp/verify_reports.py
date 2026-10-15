"""Preparation-only PDF artifact QA; no client data."""
import hashlib
import importlib.util
import json
import re
from pathlib import Path
from pypdf import PdfReader

root = Path(__file__).resolve().parents[1]
module_path = root / "tooling/reporting/reportgen.py"
spec = importlib.util.spec_from_file_location("reportgen", module_path)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
source = root / "tooling/reporting/examples/report.json"
raw = source.read_bytes()
data = json.loads(raw)
sample = root / "output/pdf/sample-report"

def compact(value):
    return re.sub(r"\s+", "", value).casefold()

def check_pdf(path, expected):
    reader = PdfReader(path)
    whole = "".join(
        line + "\n"
        for page in reader.pages
        for line in page.extract_text().splitlines()
        if not line.startswith(("DRAFT | SYNTHETIC", "CPTC reporting starter",
                                "Synthetic training artifact |", "Page "))
    )
    for value in module.all_strings(expected):
        # JSON control metadata not shown verbatim in prose.
        if value in ("1.0", "synthetic"):
            continue
        assert compact(value) in compact(whole), ("missing source value", len(value))
    for page in reader.pages:
        assert "SYNTHETIC" in page.extract_text()
        assert not page.get("/Annots"), "unexpected active links/widgets"
    assert "/JavaScript" not in reader.trailer["/Root"].get("/Names", {})
    return len(reader.pages)

manifest = json.loads((sample / "manifest.json").read_text())
assert manifest["input_sha256"] == hashlib.sha256(raw).hexdigest()
for name, digest in manifest["artifacts"].items():
    assert hashlib.sha256((sample / name).read_bytes()).hexdigest() == digest
sample_pages = check_pdf(sample / "report.pdf", data)

stress = json.loads(raw)
stress["findings"][0]["description"] = ('Literal <img src="https://example.test/"> résumé Δ. ' * 120)
stress["findings"][0]["evidence"][0]["summary"] = "Long evidence " + "A" * 1000
stress_raw = json.dumps(stress, ensure_ascii=False).encode()
stress_path = root / "tmp/pdfs/stress-report-current"
module.generate(stress_raw, stress_path, pdf=True)
stress_pages = check_pdf(stress_path / "report.pdf", stress)
replica_path = root / "tmp/pdfs/sample-replica-current"
replica_manifest = module.generate(raw, replica_path, pdf=True)
assert replica_manifest == manifest, "repeat output changed on the same runtime/fonts"
print(json.dumps({
    "sample_pages": sample_pages,
    "stress_pages": stress_pages,
    "supplied_strings_present": True,
    "no_pdf_active_content": True,
    "manifest_hashes_verified": True,
    "same_runtime_pdf_deterministic": True,
    "generator_sha256": hashlib.sha256(module_path.read_bytes()).hexdigest(),
}, indent=2))
