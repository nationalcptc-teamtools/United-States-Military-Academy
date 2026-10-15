from pathlib import Path
root = Path(__file__).resolve().parents[1]
source = root/'docs/proposals/development-functions'
module = root/'integrations/United-States-Military-Academy/tooling/workbench'
scope = (source/'scope.md').read_text(encoding='utf-8')
scope = scope.split('Current versus desired:',1)[1]
scope = 'Current versus desired:' + scope
replacements = {
    '[verification](verification.md)':'[verification](VERIFICATION.md)',
    '[independent review](review.md)':'the independent review summarized in VERIFICATION.md',
    '[tests](../../../tooling/workbench/tests/test_workbench.py)':'[tests](tests/test_workbench.py)',
    '[contracts](../../../tooling/workbench/CONTRACTS.md)':'[contracts](CONTRACTS.md)',
    'test_delivery; independent review.md':'test_delivery; VERIFICATION.md',
    'test_cli_and_metrics; execution-guide.md':'test_cli_and_metrics; README.md',
    'Existing legacy scanner defects remain listed in spec.md and are outside remediation here.':'The older scanner is outside remediation here; these commands never dispatch it.',
}
for before,after in replacements.items():
    scope = scope.replace(before,after)
design = (source/'design.md').read_text(encoding='utf-8').split('## Reconciled requirement mapping',1)[1]
design = design.split('All runtime/approval gaps remain visible;',1)[0]
text = '''# Development workbench proposal and specification

Version 1.0.0; 2026-10-15. Original preparation request: document and implement selected ideas to improve CPTC tool creation, discovery, preparation, use, logging and reporting. Priority is balanced across preparation, competition use and reporting. A decision was requested for each idea before design or implementation.

All 120 ideas received explicit choices: 70 Include, 6 Defer, 44 Exclude. The later instruction removed local AI/correction and selected neutral JSON/Markdown files for manual cloud handoff. This portable record preserves stable idea IDs, observable acceptance, all 44 original requirement dispositions and external gates. Detailed private preparation history, source assessments and generated outputs are intentionally outside this source contribution. Developer/root held the sole editing slot; a separately authorized reviewer inspected read-only. Implementation and verification are complete for this synthetic local scope; user/event acceptance remains separate.

''' + scope + '\n## Requirement dispositions\n\n' + design
(module/'SPEC.md').write_text(text,encoding='utf-8',newline='\n')
verification = '''# Workbench verification and review

Version 1.0.0; 2026-10-15. This contribution contains reusable source, documentation, notices and synthetic tests. [Scope/acceptance](SPEC.md) preserves 120 explicit idea choices and 44 requirement dispositions; [contracts](CONTRACTS.md) define bounds and failure behavior.

## Reviewed source and prior preparation evidence

The independent read-only reviewer returned a scoped positive specification/code verdict after rechecking six corrections: chronological snapshot parent selection, inherited authored/conflict markings, spaced/quoted secret redaction and revalidation keys, separate downstream stage outcomes, literal Markdown names and complete-file checksums. Final catalog cautions were also resolved: archived-name results expose documented gaps and all 43 cards distinguish eight readiness declarations. No remaining actionable finding was reported.

The reviewer independently exercised in-memory reporter/catalog/remediation checks, verified exact source hashes and built a repeatable 51-member source package. Root separately ran file-writing, process and PDF checks. The source-only package SHA-256 was fc2e71072a2d3becb5516ec35e3a1edc3bd7b656bffb49aa273f3a9a001c2550; supplemental SPEC.md/VERIFICATION.md and repository navigation are not members of that explicit source-package allowlist.

Prior preparation evidence on these code bytes: Windows CPython 3.12.14, ReportLab 4.4.9, pypdf 6.10.0; 18 workbench tests passed after standalone extraction, 36 existing reporter tests passed, 39 CLI actions completed, and all 10 pages of a synthetic sample PDF were inspected. Existing offline Linux image: CPython 3.14.7, ReportLab 4.4.9; 17 workbench tests passed, one optional pypdf extraction test skipped, and actual PDF generation succeeded. This image is not an approved competition host. No participant speed gain was measured.

## Repository integration checks

Integration recheck pending in this working copy; replace this paragraph with actual results before commit.

Reproduce from the repository root using Python 3.10+ and the existing reporting dependency for PDF:

```sh
python -B -m unittest discover -s tooling/workbench/tests -v
python -B -m unittest discover -s tooling/reporting/tests -v
python -B tooling/workbench/workbench.py check-links tooling/workbench/README.md tooling/workbench/CONTRACTS.md tooling/workbench/HANDOVER.md tooling/workbench/UI-EVALUATION.md tooling/workbench/SPEC.md tooling/workbench/VERIFICATION.md
```

The process test supervises and stops only its own fixed synthetic worker tree; on Windows the environment must permit that local cleanup. No scanners, installs, actual targets, client data, model calls or cloud transfers are used. Imported report data remains synthetic; supplied review strings, evidence references and hashes do not authenticate claims. Actual tools/hosts, licensing closure, storage/retention, event rules/rubric/deadlines and cloud permissions remain external acceptance gates. The repository's existing Linux/Windows runners and installer are preserved.
'''
(module/'VERIFICATION.md').write_text(verification,encoding='utf-8',newline='\n')
readme = root/'integrations/United-States-Military-Academy/README.md'
text=readme.read_text(encoding='utf-8').replace('See [contracts](tooling/workbench/CONTRACTS.md),','See [scope and specification](tooling/workbench/SPEC.md), [contracts](tooling/workbench/CONTRACTS.md),')
readme.write_text(text,encoding='utf-8',newline='\n')
print('Portable scope/verification records and navigation prepared')
