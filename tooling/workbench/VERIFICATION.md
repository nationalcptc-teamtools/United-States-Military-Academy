# Workbench verification and review

Version 1.0.1; 2026-10-15. This contribution contains reusable source, documentation, notices and synthetic tests. [Scope/acceptance](SPEC.md) preserves 120 explicit idea choices and 44 requirement dispositions; [contracts](CONTRACTS.md) define bounds and failure behavior.

Current continuation adds the existing reporter's Word format to workbench snapshots, retains its Word regression coverage/public scope in source packages, and separates application/workspace versions. Earlier evidence below describes the prior 1.0.0 release and is preserved as history, including its original package checksum/member count.

## Version 1.0.1 integration results

- Windows CPython 3.12.14, ReportLab 4.4.9, python-docx 1.2.0 and pypdf 6.10.0: all 20 workbench tests passed in 12.167 s and all 43 reporter tests passed in 3.127 s. The added workbench test exercises the actual CLI with Word/PDF together, Word alone, inherited appendix status/markings, every artifact hash and a renderer failure that leaves no output directory or snapshot mutation.
- Existing workspace format 1.0.0 remains readable/editable despite a changed application version; unsupported format 2.0.0 rejects. Application 1.0.1, workspace 1.0.0 and reporter 0.4.1 are separate identities.
- Existing no-network Linux preparation image, CPython 3.14.7/ReportLab 4.4.9: 18 workbench tests passed and two optional tests skipped in 1.290 s. pypdf extraction QA and Word integration were unavailable in that image; actual Linux PDF generation succeeded. No dependencies were installed. Windows validates Word structure/content; native Word pagination/layout remains outside these checks.
- Independent read-only continuation review passed: six changed Python files compile, existing/default CLI argument semantics are preserved, Word is passed by keyword, workspace format stays stable, and the explicit package allowlist retains Word tests/public records. Root's file-writing/render/process suites above are separately attributed.
- The source package now enumerates 54 members including its manifest, with public scope/verification and all seven existing reporter Word regression tests retained. Final package identity, standalone checks, complete role records and publication manifests are maintained under the repository's `Sebastian/` project records. Historical checkout copies there are not runtime sources.

The reporter, farm toolkit, installer and existing Linux/Windows runners are preserved from the published base. Only workbench integration, compatibility, packaging and related documentation changed. No original idea choice changed.

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


## Incremental reports and guides — 16 October 2026

Workbench 1.1.0 and reporter 0.5.0 were checked on Windows Python 3.12, including a freshly extracted source package with exact current-file hash comparisons. Reporter: 58 tests passed. Workbench: 28 tests passed. Farmkit: 39 tests ran successfully with one platform-specific skip. The workbench supervisor test required permission to stop its own fixed synthetic process tree; no scanner or installer was launched.

The README's create/preview/update/all-format workflow was exercised with the supplied synthetic update fixture. Updated PDF QA verified all nine pages, literal source text, actual contents page numbers, every-page markings, hashes and inactive content. Markdown QA passed 196 complete-report cases. Word package tests confirm evidence and markings in native editable content; native Word pagination/layout remains unverified here. Both SVG guide graphics were rendered and visually inspected. Documentation review confirmed all 48 workbench commands and all 40 catalog entries covered with valid local procedure links.

Independent source review repaired cross-import ID collisions and canonical numeric-change accounting; dedicated regressions cover both. Preview, stale fingerprint/revision/review, idempotent duplicate/no-op state, batch rollback, preservation and source-package completeness passed. Workspace format remains 1.0.0; no migration is required. User/event acceptance and real-data/native-import support remain outside these checks.
