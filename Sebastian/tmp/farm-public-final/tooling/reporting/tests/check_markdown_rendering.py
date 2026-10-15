"""Opt-in synthetic Markdown QA using a separately available Node/Marked parser.

No generator runtime dependencies are added. This check writes no reports.
"""
import argparse
import copy
import importlib.util
import json
import re
import subprocess
from html.parser import HTMLParser
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
MODULE_PATH = ROOT / "tooling/reporting/reportgen.py"
spec = importlib.util.spec_from_file_location("reportgen_markdown_qa", MODULE_PATH)
reportgen = importlib.util.module_from_spec(spec)
spec.loader.exec_module(reportgen)


class VisibleReport(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.text = []
        self.headings = []
        self.unexpected_tags = []
        self.links = []

    def handle_starttag(self, tag, attrs):
        if tag in ("h1", "h2", "h3"):
            self.headings.append(tag)
        if tag in ("pre", "code", "img", "em", "script"):
            self.unexpected_tags.append(tag)
        if tag == "a":
            self.links.append(dict(attrs).get("href"))
        if tag == "br":
            self.text.append("\n")

    def handle_data(self, data):
        self.text.append(data)


def compact(value):
    # Paragraph wrapping and Markdown hard breaks may change whitespace.
    # Literal punctuation, entity-looking text and backslashes must survive.
    return re.sub(r"\s+", "", value)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--node", required=True, help="available Node executable")
    parser.add_argument("--marked-module", required=True, help="available marked.esm.js file")
    parser.add_argument("--fixture", type=Path, default=MODULE_PATH.parent / "examples/report.json",
                        help="synthetic report fixture for the schema under test")
    args = parser.parse_args()
    fixture = json.loads(args.fixture.read_bytes())
    cases = [
        "R-02 literal heading\n=====",
        "    R-02 *indented* [x](url) <img src=\"https://example.test/\">",
        "R-02 paragraph\n\n    *indented after blank line*",
        "R-02 underline\n =",
        "R-02 underline\n  ==",
        "R-02 underline\n   ===",
        "    R-02 C:\\local\\raw_[capture].txt",
        "R-02 literal entities &lt; &amp; &#32;",
        "# R-02 heading\n> quote\n- item\n1. step\n~~~\n<em>literal</em>",
        "R-02 [label](https://example.test/) ![image](https://example.test/image)",
        "R-02 `literal code` and **literal emphasis**",
        "R-02 first\n    \n    second",
        "\n\n    R-02 leading blank lines and indentation\n\n",
        "R-02 trailing spaces  \n    next line",
    ]
    targets = [
        ("executive_summary", lambda d, v: d["engagement"].update(executive_summary=v)),
        ("methodology", lambda d, v: d["engagement"].update(methodology=v)),
        ("description", lambda d, v: d["findings"][0].update(description=v)),
        ("remediation", lambda d, v: d["findings"][0].update(remediation=v)),
        ("scope", lambda d, v: d["engagement"].update(scope=[v])),
        ("limitations", lambda d, v: d["engagement"].update(limitations=[v])),
        ("validation_steps", lambda d, v: d["findings"][0].update(validation_steps=[v])),
        ("evidence_summary", lambda d, v: d["findings"][0]["evidence"][0].update(summary=v)),
        ("objective", lambda d, v: d["engagement"].update(objective=v)),
        ("recommendations", lambda d, v: d["engagement"].update(recommendations=[v])),
        ("methodology_information_gathering", lambda d, v: d["engagement"]["methodology_sections"].update(information_gathering=v)),
        ("methodology_service_enumeration", lambda d, v: d["engagement"]["methodology_sections"].update(service_enumeration=v)),
        ("methodology_validation", lambda d, v: d["engagement"]["methodology_sections"].update(validation=v)),
        ("methodology_cleanup", lambda d, v: d["engagement"]["methodology_sections"].update(cleanup=v)),
    ]
    markdown = [reportgen.render_markdown(reportgen.validate(copy.deepcopy(fixture)))]
    expected = []
    for name, assign in targets:
        for value in cases:
            data = copy.deepcopy(fixture)
            assign(data, value)
            markdown.append(reportgen.render_markdown(reportgen.validate(data)))
            expected.append((name, value))
    script = """
import { readFileSync } from 'node:fs';
const { marked } = await import(process.argv[1]);
const inputs = JSON.parse(readFileSync(0, 'utf8'));
process.stdout.write(JSON.stringify(inputs.map(text => marked.parse(text, {gfm: false}))));
"""
    result = subprocess.run(
        [args.node, "--input-type=module", "-e", script,
         Path(args.marked_module).resolve().as_uri()],
        input=json.dumps(markdown), text=True, capture_output=True, check=True, timeout=30)
    rendered = json.loads(result.stdout)
    assert len(rendered) == len(markdown), "parser returned an incomplete result"
    baseline = VisibleReport()
    baseline.feed(rendered[0])
    failures = []
    for (name, value), html in zip(expected, rendered[1:]):
        report = VisibleReport()
        report.feed(html)
        if report.headings != baseline.headings or report.unexpected_tags or report.links != baseline.links:
            failures.append((name, cases.index(value), "source changed report structure"))
        if compact(value) not in compact("".join(report.text)):
            failures.append((name, cases.index(value), "literal source text changed"))
    if failures:
        raise AssertionError(f"Markdown rendering regressions: {failures}")
    print(f"Passed {len(expected)} complete-report Markdown rendering cases.")


if __name__ == "__main__":
    main()
