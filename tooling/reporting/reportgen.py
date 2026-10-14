"""Offline synthetic reporting starter. Input text never invokes tools or a model."""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import re
import sys
import tempfile
import unicodedata
from collections import Counter
from datetime import date, datetime
from pathlib import Path, PurePosixPath
from xml.sax.saxutils import escape

VERSION = "0.1.1"
MAX_INPUT_BYTES = 2_000_000
SEVERITIES = ("critical", "high", "medium", "low", "info")
ROOT = Path(__file__).resolve().parents[2]


class ContractError(ValueError):
    """Error messages name trusted contract locations, never input contents."""


def require(condition, location, rule):
    if not condition:
        raise ContractError(f"{location}: {rule}")


def obj(value, location, required, optional=()):
    require(isinstance(value, dict), location, "expected an object")
    require(set(required) <= value.keys(), location, "required fields missing")
    require(value.keys() <= set(required) | set(optional), location, "unknown fields")


def text(value, location, limit=10000, single_line=False):
    require(isinstance(value, str) and bool(value.strip()), location, "nonempty text required")
    require(len(value) <= limit, location, "text exceeds field limit")
    require(not any(unicodedata.category(c) in ("Cc", "Cf", "Cs") and c != "\n"
                    for c in value), location, "unsupported control characters")
    require(not single_line or "\n" not in value, location, "single-line text required")


def identifier(value, location):
    require(isinstance(value, str) and re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_-]{0,63}", value),
            location, "expected a stable ID of up to 64 letters, numbers, underscores or hyphens")


def items(value, location, maximum=100, allow_empty=False):
    require(isinstance(value, list) and (allow_empty or len(value) > 0)
            and len(value) <= maximum, location, "invalid list size")


def strings(value, location, limit=2000, maximum=100, single_line=False):
    items(value, location, maximum)
    for i, item in enumerate(value):
        text(item, f"{location}[{i}]", limit, single_line)


def iso_date(value, location):
    require(isinstance(value, str) and re.fullmatch(r"\d{4}-\d{2}-\d{2}", value),
            location, "expected ISO date YYYY-MM-DD")
    try:
        date.fromisoformat(value)
    except ValueError:
        raise ContractError(f"{location}: invalid calendar date") from None


def timestamp(value, location):
    text(value, location, 50, True)
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
        require("T" in value and parsed.tzinfo is not None, location,
                "ISO timestamp with timezone required")
    except ValueError:
        raise ContractError(f"{location}: ISO timestamp with timezone required") from None


def artifact_path(value, location):
    text(value, location, 240, True)
    path = PurePosixPath(value)
    require(not path.is_absolute() and "\\" not in value and ":" not in value
            and all(p not in ("", ".", "..") for p in value.split("/")),
            location, "artifact must be a relative path without traversal or URL/drive prefixes")


def validate(data, release=False):
    obj(data, "report", ("schema_version", "data_category", "classification",
                        "engagement", "findings"), ("review",))
    require(data["schema_version"] == "1.0", "report.schema_version", "unsupported schema")
    require(data["data_category"] == "synthetic", "report.data_category",
            "this preparation starter accepts synthetic data only")
    text(data["classification"], "report.classification", 100, True)
    e = data["engagement"]
    obj(e, "engagement", ("id", "client", "team", "report_date", "scope", "methodology",
                         "executive_summary", "limitations"))
    identifier(e["id"], "engagement.id")
    for key in ("client", "team"):
        text(e[key], f"engagement.{key}", 120, True)
    iso_date(e["report_date"], "engagement.report_date")
    strings(e["scope"], "engagement.scope")
    text(e["methodology"], "engagement.methodology")
    text(e["executive_summary"], "engagement.executive_summary")
    strings(e["limitations"], "engagement.limitations")
    if "review" in data:
        obj(data["review"], "review", ("reviewer", "reviewed_at"))
        text(data["review"]["reviewer"], "review.reviewer", 120, True)
        iso_date(data["review"]["reviewed_at"], "review.reviewed_at")
    if release:
        require("review" in data, "review", "human reviewer and date required for release label")
    items(data["findings"], "findings", maximum=200, allow_empty=True)
    seen_findings, seen_evidence = set(), set()
    for i, f in enumerate(data["findings"]):
        at = f"findings[{i}]"
        obj(f, at, ("id", "title", "severity", "severity_rationale", "status", "assets",
                    "description", "validation_steps", "business_impact", "remediation",
                    "retest_steps", "evidence"), ("cves", "cvss"))
        identifier(f["id"], f"{at}.id")
        require(f["id"] not in seen_findings, f"{at}.id", "duplicate finding ID")
        seen_findings.add(f["id"])
        text(f["title"], f"{at}.title", 180, True)
        require(f["severity"] in SEVERITIES, f"{at}.severity", "invalid severity")
        require(f["status"] in ("candidate", "confirmed"), f"{at}.status", "invalid status")
        require(not release or f["status"] == "confirmed", f"{at}.status",
                "release label requires confirmed findings")
        strings(f["assets"], f"{at}.assets", 300, 100, True)
        for key in ("severity_rationale", "description", "business_impact", "remediation"):
            text(f[key], f"{at}.{key}")
        for key in ("validation_steps", "retest_steps"):
            strings(f[key], f"{at}.{key}", maximum=50)
        items(f["evidence"], f"{at}.evidence", maximum=50)
        for j, evidence in enumerate(f["evidence"]):
            loc = f"{at}.evidence[{j}]"
            obj(evidence, loc, ("id", "observed_at", "collector", "tool", "tool_version", "summary"),
                ("artifact", "sha256"))
            identifier(evidence["id"], f"{loc}.id")
            require(evidence["id"] not in seen_evidence, f"{loc}.id", "duplicate evidence ID")
            seen_evidence.add(evidence["id"])
            timestamp(evidence["observed_at"], f"{loc}.observed_at")
            for key in ("collector", "tool", "tool_version"):
                text(evidence[key], f"{loc}.{key}", 120, True)
            text(evidence["summary"], f"{loc}.summary")
            if "artifact" in evidence:
                artifact_path(evidence["artifact"], f"{loc}.artifact")
            if "sha256" in evidence:
                require("artifact" in evidence, f"{loc}.sha256", "hash requires artifact reference")
                require(isinstance(evidence["sha256"], str)
                        and re.fullmatch(r"[a-f0-9]{64}", evidence["sha256"]),
                        f"{loc}.sha256", "expected lowercase SHA-256")
        if "cves" in f:
            items(f["cves"], f"{at}.cves", maximum=30)
            seen_cves = set()
            for j, cve in enumerate(f["cves"]):
                loc = f"{at}.cves[{j}]"
                obj(cve, loc, ("id", "applicability", "match_basis", "source", "retrieved_at"))
                require(isinstance(cve["id"], str) and re.fullmatch(r"CVE-[0-9]{4}-[0-9]{4,}", cve["id"]),
                        f"{loc}.id", "invalid CVE ID")
                require(cve["id"] not in seen_cves, f"{loc}.id", "duplicate CVE reference")
                seen_cves.add(cve["id"])
                require(cve["applicability"] in ("candidate", "verified"), f"{loc}.applicability",
                        "invalid applicability")
                require(not release or cve["applicability"] == "verified", f"{loc}.applicability",
                        "release label requires verified CVE applicability")
                text(cve["match_basis"], f"{loc}.match_basis", 2000)
                text(cve["source"], f"{loc}.source", 1000, True)
                iso_date(cve["retrieved_at"], f"{loc}.retrieved_at")
        if "cvss" in f:
            c = f["cvss"]
            loc = f"{at}.cvss"
            obj(c, loc, ("version", "score", "vector", "source", "retrieved_at"))
            require(c["version"] in ("3.1", "4.0"), f"{loc}.version", "unsupported CVSS version")
            require(type(c["score"]) in (int, float) and 0 <= c["score"] <= 10
                    and math.isfinite(c["score"]), f"{loc}.score", "finite score from 0 to 10 required")
            text(c["vector"], f"{loc}.vector", 512, True)
            require(c["vector"].startswith(f"CVSS:{c['version']}/")
                    and re.fullmatch(r"CVSS:(3\.1|4\.0)(/[A-Z]{1,4}:[A-Z0-9.]+)+", c["vector"]),
                    f"{loc}.vector", "invalid vector shape or version")
            text(c["source"], f"{loc}.source", 1000, True)
            iso_date(c["retrieved_at"], f"{loc}.retrieved_at")
    return data


def _pairs(pairs):
    result = {}
    for key, value in pairs:
        require(key not in result, "input JSON", "duplicate object key")
        result[key] = value
    return result


def load(raw):
    require(len(raw) <= MAX_INPUT_BYTES, "input", "input exceeds 2 MB limit")
    try:
        return json.loads(raw.decode("utf-8-sig"), object_pairs_hook=_pairs,
                          parse_constant=lambda _: (_ for _ in ()).throw(
                              ContractError("input JSON: non-finite numbers are prohibited")))
    except ContractError:
        raise
    except (ValueError, RecursionError):
        raise ContractError("input JSON: invalid UTF-8 JSON") from None


def md(value):
    # Escape CommonMark punctuation and raw HTML; preserve visible literal text.
    value = str(value).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    punctuation = "\\" + chr(96) + "*_{}[]()#+-.!|~="
    value = "".join("\\" + c if c in punctuation else c for c in value)
    # Entities preserve source spaces without letting indentation create code.
    # Insert them after escaping so their ampersands are not escaped again.
    value = re.sub(r"(?m)^ +", lambda match: "&#32;" * len(match[0]), value)
    return value.replace("\n", "  \n")


def sections(data):
    """Shared fact sections keep Markdown and PDF aligned."""
    for f in data["findings"]:
        parts = [
            ("Business severity", [f"{f['severity'].upper()} - {f['severity_rationale']}"]),
            ("Validation status", [f["status"].upper()]),
            ("Affected assets", f["assets"]),
            ("Observation", [f["description"]]),
            ("Validation steps and results", f["validation_steps"]),
            ("Business impact", [f["business_impact"]]),
            ("Remediation", [f["remediation"]]),
            ("Retest plan", f["retest_steps"]),
        ]
        for e in f["evidence"]:
            lines = [
                f"Observed: {e['observed_at']} | Collector: {e['collector']}",
                f"Source: {e['tool']} {e['tool_version']}",
                f"Normalized evidence summary: {e['summary']}",
            ]
            if "artifact" in e:
                lines.append(f"Private artifact reference (not embedded or verified): {e['artifact']}")
            if "sha256" in e:
                lines.append(f"Supplied artifact SHA-256 (not verified): {e['sha256']}")
            parts.append((f"Evidence {e['id']}", lines))
        if "cves" in f:
            parts.append(("CVE references (supplied)", [
                f"{c['id']} | {c['applicability'].upper()} | Basis: {c['match_basis']} | "
                f"Source: {c['source']} | Retrieved: {c['retrieved_at']}"
                for c in f["cves"]]))
        if "cvss" in f:
            c = f["cvss"]
            parts.append(("CVSS metadata (supplied, not recalculated)", [
                f"CVSS {c['version']} | Score: {c['score']} | Vector: {c['vector']}",
                f"Source: {c['source']} | Retrieved: {c['retrieved_at']}",
                "Published severity metadata does not establish business risk or applicability.",
            ]))
        yield f, parts


def render_markdown(data, release=False):
    e = data["engagement"]
    label = "REVIEWED TRAINING COPY" if release else "DRAFT"
    lines = [
        "# Penetration testing report",
        "",
        f"**{label} | SYNTHETIC DATA**",
        "",
        f"Client: {md(e['client'])}  \nTeam: {md(e['team'])}  \n"
        f"Engagement: {md(e['id'])}  \nReport date: {md(e['report_date'])}  \n"
        f"Data marking: {md(data['classification'])}",
        "",
        "Training demonstration only. No real assessment, event permission, or submission is established.",
        "",
        "## Executive summary", "", md(e["executive_summary"]), "",
        "## Scope", "",
    ]
    lines += [f"- {md(s)}" for s in e["scope"]]
    lines += ["", "## Methodology", "", md(e["methodology"]), "", "## Limitations", ""]
    lines += [f"- {md(s)}" for s in e["limitations"]]
    counts = Counter(f["severity"] for f in data["findings"])
    statuses = Counter(f["status"] for f in data["findings"])
    lines += ["", "## Finding summary", "",
              f"Total: {len(data['findings'])} | Confirmed: {statuses['confirmed']} | "
              f"Candidate: {statuses['candidate']}", "",
              " | ".join(f"{s.title()}: {counts[s]}" for s in SEVERITIES), ""]
    for f, parts in sections(data):
        lines += [f"## {md(f['id'])}: {md(f['title'])}", ""]
        for title, values in parts:
            lines += [f"### {md(title)}", ""]
            lines += [md(value) + "\n" for value in values]
    lines += ["## Review record", ""]
    if "review" in data:
        lines += [f"Supplied reviewer: {md(data['review']['reviewer'])}  \n"
                  f"Supplied review date: {md(data['review']['reviewed_at'])}", ""]
    else:
        lines += ["Human review pending.", ""]
    lines += ["Review labels are local metadata. Inspect the actual artifacts before any authorized use.",
              "", "Evidence files are referenced, never opened. The manifest identifies the input "
              "and outputs by hash; it does not verify the observations.", ""]
    return "\n".join(lines)


def all_strings(value):
    if isinstance(value, str):
        yield value
    elif isinstance(value, dict):
        for item in value.values():
            yield from all_strings(item)
    elif isinstance(value, list):
        for item in value:
            yield from all_strings(item)


def render_pdf(data, destination, release=False):
    try:
        from reportlab.lib import colors
        from reportlab.lib.enums import TA_LEFT
        from reportlab.lib.pagesizes import letter
        from reportlab.lib.styles import ParagraphStyle
        from reportlab.pdfbase import pdfmetrics
        from reportlab.pdfbase.ttfonts import TTFont
        from reportlab.pdfgen import canvas
        from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak, Table, TableStyle
    except ImportError:
        raise ContractError("PDF: install the declared ReportLab dependency in an approved environment") from None

    candidates = [
        (Path("C:/Windows/Fonts/arial.ttf"), Path("C:/Windows/Fonts/arialbd.ttf")),
        (Path("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"),
         Path("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf")),
        (Path("/Library/Fonts/Arial.ttf"), Path("/Library/Fonts/Arial Bold.ttf")),
    ]
    normal, bold = "Helvetica", "Helvetica-Bold"
    glyphs = set(range(32, 256))
    for regular_path, bold_path in candidates:
        if regular_path.is_file() and bold_path.is_file():
            normal, bold = "ReportText", "ReportBold"
            pdfmetrics.registerFont(TTFont(normal, str(regular_path)))
            pdfmetrics.registerFont(TTFont(bold, str(bold_path)))
            glyphs = set(pdfmetrics.getFont(normal).face.charToGlyph) & set(
                pdfmetrics.getFont(bold).face.charToGlyph)
            break
    require(all(ord(char) in glyphs or char == "\n" for s in all_strings(data) for char in s),
            "PDF", "input contains glyphs unavailable in the installed fonts; use Markdown or approved fonts")
    navy, ink, muted = colors.HexColor("#17324D"), colors.HexColor("#243444"), colors.HexColor("#526575")
    body = ParagraphStyle("Body", fontName=normal, fontSize=10, leading=14, textColor=ink,
                          spaceAfter=7, alignment=TA_LEFT, splitLongWords=True)
    styles = {
        "body": body,
        "title": ParagraphStyle("Title", parent=body, fontName=bold, fontSize=25, leading=30,
                                textColor=navy, spaceAfter=14),
        "h1": ParagraphStyle("H1", parent=body, fontName=bold, fontSize=17, leading=22,
                             textColor=navy, spaceAfter=12, keepWithNext=True),
        "h2": ParagraphStyle("H2", parent=body, fontName=bold, fontSize=11, leading=15,
                             textColor=navy, spaceBefore=8, spaceAfter=5, keepWithNext=True),
        "small": ParagraphStyle("Small", parent=body, fontSize=8.5, leading=12, textColor=muted),
    }

    def p(value, style="body"):
        return Paragraph(escape(str(value)).replace("\n", "<br/>"), styles[style])

    def prose(value):
        # Bounded chunks allow a heading and the start of a long narrative to
        # share a page, without keeping the entire narrative with the heading.
        value = str(value)
        chunks = []
        while len(value) > 1600:
            cut = value.rfind(" ", 800, 1600)
            if cut < 0:
                cut = 1600
            chunks.append(p(value[:cut]))
            value = value[cut:]
        chunks.append(p(value))
        return chunks

    e = data["engagement"]
    label = "REVIEWED TRAINING COPY" if release else "DRAFT"
    story = [p(f"{label} | SYNTHETIC DATA", "small"), Spacer(1, 8),
             p("Penetration testing report", "title"), p(e["client"], "h1")]
    metadata = [
        ["Engagement", e["id"]],
        ["Team", e["team"]],
        ["Report date", e["report_date"]],
        ["Data marking", data["classification"]],
    ]
    table = Table([[p(key, "small"), p(value)] for key, value in metadata], colWidths=[102, 366])
    table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#EDF2F6")),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 10),
        ("TOPPADDING", (0, 0), (-1, -1), 7),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
    ]))
    story += [table, Spacer(1, 12),
              p("Training demonstration only. No real assessment, event permission, or submission is established.",
                "small"), p("Executive summary", "h2")]
    story += prose(e["executive_summary"])
    counts = Counter(f["severity"] for f in data["findings"])
    statuses = Counter(f["status"] for f in data["findings"])
    story += [p("Finding summary", "h2"),
              p(f"Total {len(data['findings'])} | Confirmed {statuses['confirmed']} | Candidate {statuses['candidate']}"),
              p(" | ".join(f"{s.title()} {counts[s]}" for s in SEVERITIES)),
              p("Scope", "h2")]
    for s in e["scope"]:
        story += prose("- " + s)
    story += [p("Methodology", "h2")]
    story += prose(e["methodology"])
    story += [p("Limitations", "h2")]
    for s in e["limitations"]:
        story += prose("- " + s)
    for f, parts in sections(data):
        story += [PageBreak(), p(f"{f['id']}: {f['title']}", "h1")]
        for title, values in parts:
            story.append(p(title, "h2"))
            for value in values:
                story += prose(value)
    story += [Spacer(1, 12), p("Review record", "h2")]
    if "review" in data:
        story.append(p(f"Supplied reviewer: {data['review']['reviewer']} | "
                       f"Date: {data['review']['reviewed_at']}"))
    else:
        story.append(p("Human review pending."))
    story.append(p("Review labels are local metadata. Evidence files are never opened; supplied "
                   "hashes and observations are not independently verified.", "small"))

    def page_frame(c, doc):
        c.saveState()
        c.setStrokeColor(colors.HexColor("#B6C5D1"))
        c.line(54, 750, 558, 750)
        c.setFont(bold, 8)
        c.setFillColor(navy)
        c.drawString(54, 760, f"{label} | SYNTHETIC")
        c.setFont(normal, 8)
        c.drawRightString(558, 760, "CPTC reporting starter")
        c.line(54, 42, 558, 42)
        c.setFillColor(muted)
        c.drawString(54, 29, "Synthetic training artifact | Human artifact review required")
        c.drawRightString(558, 29, f"Page {doc.page}")
        c.restoreState()

    class StableCanvas(canvas.Canvas):
        def __init__(self, *args, **kwargs):
            kwargs["invariant"] = 1
            super().__init__(*args, **kwargs)

    document = SimpleDocTemplate(str(destination), pagesize=letter, rightMargin=54, leftMargin=54,
                                 topMargin=58, bottomMargin=58, title="Synthetic penetration testing report",
                                 author="CPTC reporting starter", pageCompression=1)
    document.build(story, onFirstPage=page_frame, onLaterPages=page_frame, canvasmaker=StableCanvas)


def sha256(raw):
    return hashlib.sha256(raw).hexdigest()


def generate(raw, output_dir, pdf=False, release=False):
    data = validate(load(raw), release)
    output_dir = Path(output_dir).resolve()
    require(not any(output_dir == blocked or blocked in output_dir.parents
                    for blocked in (ROOT / "sources", ROOT / "tooling")),
            "destination", "outputs cannot be written under sources or reusable tooling")
    require(not output_dir.exists(), "destination", "already exists; choose a new output directory")
    output_dir.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=".report-staging-", dir=output_dir.parent) as staging:
        stage = Path(staging)
        (stage / "report.md").write_text(render_markdown(data, release), encoding="utf-8")
        if pdf:
            render_pdf(data, stage / "report.pdf", release)
        artifact_hashes = {p.name: sha256(p.read_bytes()) for p in sorted(stage.iterdir())}
        manifest = {
            "generator_version": VERSION, "schema_version": data["schema_version"],
            "data_category": data["data_category"], "classification": data["classification"],
            "review_label": "reviewed_training_copy" if release else "draft",
            "input_sha256": sha256(raw), "artifacts": artifact_hashes,
            "evidence_files_opened": False, "cvss_recalculated": False,
        }
        (stage / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
        # Refuse a destination that appeared while rendering; never intentionally overwrite it.
        require(not output_dir.exists(), "destination", "appeared during generation; choose a new directory")
        stage.rename(output_dir)
    return manifest


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", help="UTF-8 normalized JSON file, or - for stdin")
    parser.add_argument("--output-dir", required=True, help="new private output directory; never overwritten")
    parser.add_argument("--pdf", action="store_true", help="also render PDF using locally installed ReportLab")
    parser.add_argument("--release", action="store_true", help="reviewed training label; enforce review metadata")
    args = parser.parse_args(argv)
    try:
        if args.input == "-":
            raw = sys.stdin.buffer.read(MAX_INPUT_BYTES + 1)
        else:
            with Path(args.input).open("rb") as stream:
                raw = stream.read(MAX_INPUT_BYTES + 1)
        manifest = generate(raw, args.output_dir, args.pdf, args.release)
    except ContractError as exc:
        print(f"Report rejected: {exc}", file=sys.stderr)
        return 2
    except Exception:
        # Do not expose paths or document text from dependency/OS exceptions.
        print("Report failed: could not read input or render/publish artifacts; check local dependencies "
              "and filesystem permissions. No report destination was intentionally overwritten.", file=sys.stderr)
        return 1
    print(f"Generated {'Markdown + PDF' if args.pdf else 'Markdown'}; "
          f"label={manifest['review_label']}; input_sha256={manifest['input_sha256']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
