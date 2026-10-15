# Workbench verification and review

Version 1.0.0; 2026-10-15. This contribution contains reusable source, documentation, notices and synthetic tests. [Scope/acceptance](SPEC.md) preserves 120 explicit idea choices and 44 requirement dispositions; [contracts](CONTRACTS.md) define bounds and failure behavior.

## Reviewed source and prior preparation evidence

The independent read-only reviewer returned a scoped positive specification/code verdict after rechecking six corrections: chronological snapshot parent selection, inherited authored/conflict markings, spaced/quoted secret redaction and revalidation keys, separate downstream stage outcomes, literal Markdown names and complete-file checksums. Final catalog cautions were also resolved: archived-name results expose documented gaps and all 43 cards distinguish eight readiness declarations. No remaining actionable finding was reported.

The reviewer independently exercised in-memory reporter/catalog/remediation checks, verified exact source hashes and built a repeatable 51-member source package. Root separately ran file-writing, process and PDF checks. The source-only package SHA-256 was fc2e71072a2d3becb5516ec35e3a1edc3bd7b656bffb49aa273f3a9a001c2550; supplemental SPEC.md/VERIFICATION.md and repository navigation are not members of that explicit source-package allowlist.

Prior preparation evidence on these code bytes: Windows CPython 3.12.14, ReportLab 4.4.9, pypdf 6.10.0; 18 workbench tests passed after standalone extraction, 36 existing reporter tests passed, 39 CLI actions completed, and all 10 pages of a synthetic sample PDF were inspected. Existing offline Linux image: CPython 3.14.7, ReportLab 4.4.9; 17 workbench tests passed, one optional pypdf extraction test skipped, and actual PDF generation succeeded. This image is not an approved competition host. No participant speed gain was measured.

## Repository integration checks

The actual integration checkout passed all 18 workbench tests (8.370 s) and all 36 reporter tests (0.648 s) on Windows CPython 3.12.14 with the existing PDF dependencies. Reviewed reusable source files match the settled preparation manifest exactly. Existing farm installation/catalog files, Linux/Windows runners and their published changes were preserved; no operational runner or installer was launched. Local documentation links and the staged public-file inventory were checked before commit.

Reproduce from the repository root using Python 3.10+ and the existing reporting dependency for PDF:

```sh
python -B -m unittest discover -s tooling/workbench/tests -v
python -B -m unittest discover -s tooling/reporting/tests -v
python -B tooling/workbench/workbench.py check-links tooling/workbench/README.md tooling/workbench/CONTRACTS.md tooling/workbench/HANDOVER.md tooling/workbench/UI-EVALUATION.md tooling/workbench/SPEC.md tooling/workbench/VERIFICATION.md
```

The process test supervises and stops only its own fixed synthetic worker tree; on Windows the environment must permit that local cleanup. No scanners, installs, actual targets, client data, model calls or cloud transfers are used. Imported report data remains synthetic; supplied review strings, evidence references and hashes do not authenticate claims. Actual tools/hosts, licensing closure, storage/retention, event rules/rubric/deadlines and cloud permissions remain external acceptance gates. The repository's existing Linux/Windows runners and installer are preserved.
