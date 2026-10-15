"""Optional preparation-only PDF QA. Requires pypdf; writes no reports."""
import argparse
import hashlib
import importlib.util
import json
import re
from pathlib import Path
from pypdf import PdfReader

MODULE_PATH = Path(__file__).resolve().parents[1] / "reportgen.py"
spec = importlib.util.spec_from_file_location("reportgen_pdf_qa", MODULE_PATH)
reportgen = importlib.util.module_from_spec(spec)
spec.loader.exec_module(reportgen)


def compact(value):
    return re.sub(r"\s+", "", value).casefold()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path)
    parser.add_argument("output_dir", type=Path)
    args = parser.parse_args()
    raw = args.input.read_bytes()
    manifest = json.loads((args.output_dir / "manifest.json").read_text(encoding="utf-8"))
    data = reportgen.validate(reportgen.load(raw), manifest["review_label"] == "reviewed_training_copy")
    assert manifest["generator_version"] == reportgen.VERSION
    assert manifest["schema_version"] == data["schema_version"]
    assert manifest["input_sha256"] == hashlib.sha256(raw).hexdigest()
    assert set(manifest["artifacts"]) == {"report.md", "report.pdf"}
    for name, digest in manifest["artifacts"].items():
        assert hashlib.sha256((args.output_dir / name).read_bytes()).hexdigest() == digest
    assert not manifest["evidence_files_opened"] and not manifest["cvss_recalculated"]
    reader = PdfReader(args.output_dir / "report.pdf")
    assert len(reader.pages) >= 7
    texts = [page.extract_text() for page in reader.pages]
    body = []
    frame_lines = {"DRAFT | SYNTHETIC", "REVIEWED TRAINING COPY | SYNTHETIC",
                   "CPTC reporting", "Synthetic training artifact | Human review required"}
    for i, (page, text) in enumerate(zip(reader.pages, texts), 1):
        assert f"Page {i}" in text
        assert "SYNTHETIC" in text
        assert not page.get("/Annots"), "unexpected PDF annotations"
        body.extend(line for line in text.splitlines()
                    if line not in frame_lines and line != f"Page {i}")
    assert "/JavaScript" not in reader.trailer["/Root"].get("/Names", {})
    visible = compact("\n".join(body))
    for value in reportgen.all_strings(data):
        assert compact(value) in visible, "supplied source text missing from PDF"
    contents = reader.pages[1].extract_text(extraction_mode="layout").splitlines()
    actual_pages = {}
    for chapter in reportgen.CHAPTERS:
        page_number = next(
            i + 1 for i in range(2, len(texts))
            if chapter in [line.strip() for line in texts[i].splitlines()])
        row = next(line for line in contents if line.strip().startswith(chapter + " "))
        assert int(re.search(r"(\d+)\s*$", row).group(1)) == page_number, chapter
        actual_pages[chapter] = page_number
    print(json.dumps({"pages": len(reader.pages), "source_text_preserved": True,
                      "manifest_hashes_verified": True, "contents_pages": actual_pages,
                      "no_pdf_active_content": True}))


if __name__ == "__main__":
    main()
