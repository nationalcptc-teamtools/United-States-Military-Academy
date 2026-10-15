from pathlib import Path

root = Path(__file__).resolve().parents[1]
docs = root / 'docs/proposals/development-functions'
path = docs / 'tasks.md'
content = path.read_text(encoding='utf-8')
replacements = {
    'Known-query/metadata/scaffold/preflight/priority checks; pending': 'Complete; V-DF-01/04, scope rows 001–060/113/119; no measured speed claim',
    'Actual CLI workflows, concurrent/revision and synthetic process checks; pending': 'Complete; V-DF-01/03/04; cancellation owns fixed synthetic tree only',
    'Actual report-to-curation-to-Markdown/PDF path, statuses/markings/hashes; pending': 'Complete; V-DF-01/02/04/05; ten PDF pages inspected',
    'Exact package members/hash/repeatability/no upload; pending': 'Complete; V-DF-06/09; manual neutral handoff, no local AI/API',
    'Real CLI exercise, existing reporter regressions and PDF content/visual check; pending': 'Complete; V-DF-01–06; failures/corrections/optional Linux skip retained',
    'Exact hashes and explicit independent/root attribution; pending': 'Code review complete; V-DF-07 and review.md; R-DF-01–06 resolved; final document check separately recorded',
    'Final identity/link/baseline checks; user acceptance/event gates separate; pending': 'Complete on passing V-DF-08/09; local bundle identity in verification.md; acceptance/event gates separate',
}
for before, after in replacements.items():
    assert before in content, before
    content = content.replace(before, after)
content = content.replace('runnable procedures/actual results will be recorded in verification.md', 'runnable procedures/actual results are recorded in [verification.md](verification.md)')
path.write_text(content, encoding='utf-8')
journal = root / 'docs/journal.md'
with journal.open('a', encoding='utf-8') as target:
    target.write('''

### Development functions — final decisions and full local role cycle

2026-10-15. Batch 10 explicitly included IDEA-DF-113/118/119/120 and excluded 109–112/114–117. All 120 decisions are recorded: 70 Include, 6 Defer, 44 Exclude. The user then removed local AI/correction, selected neutral JSON/Markdown for manual cloud handoff, and authorized an independent read-only reviewer. Root retained sole editing; no new editor was delegated. Sources, AGENTS, farm files and integration were preserved.

Architect/Planner/Tech Lead reconciled all 44 requirement IDs and all chosen outcomes before implementation. Workbench 1.0.0 extends the live farm catalog and existing reporter, with CLI discovery/creation/intake/readiness, revision-safe manual workflow, synthetic lifecycle example, existing-report curation/snapshots, explicit stage failures, handling/status/incident/retest records and deterministic source/manual handoff bundles. Reporter 0.3.1 adds only the bounded shared appendix API; schemas/ordinary CLI remain unchanged. Native adapters, target runner/profile budgets, global evidence graph/claim allocator, CI, timed drills and local AI were not added. Static legacy D-DF defects remain outside this delivery.

Root verification: settled Windows workbench 18/18 (8.311 s), existing reporter 36/36 (0.798 s), isolated no-network Linux 17 passed/1 optional pypdf skip (1.212 s), plus actual Linux PDF generation. Thirty-nine CLI subprocess actions passed; a ten-page synthetic PDF retained all handling labels and separate stage failures, had no annotations/OpenAction and was visually inspected page by page. The 51-member source ZIP is deterministic, every member hash verified, all Python compiled, and extracted standalone tests passed18/18 (9.304 s). Source ZIP SHA-256 68d95199a8ecd86a5a93d0f55579094c59ac2df8f45130b62242428902d552e5; it is local only.

Independent reviewer returned six substantive R-DF findings (snapshot order, authored markings, spaced secrets/revalidation keys, downstream stage failures, Markdown literal text, prefix checksum) and rechecked each correction on exact source bytes. Scoped positive code verdict; independent in-memory regressions/package checks are attributed separately. Initial sandbox restrictions, fixture assertions, Windows sharing/test-cleanup race and incomplete Linux test copy/quoting failures are preserved with correction/retest evidence in verification.md. Final role-document check, baseline/link/ID checks and exact identities are in review.md and the final artifact record.

Implementation/verification/independent code review complete for the reconciled local synthetic workbench. Explicit user acceptance remains pending; no proposal README consolidation. No scans/install/acquisition/actual client/model/cloud transfer/publication/remote repository activity was performed. Actual event rules/hosts/owners/storage/retention/rubric/cloud authorization remain separate gates; no participant speed improvement is claimed. Handoff: [proposal](proposals/development-functions/proposal.md), [scope](proposals/development-functions/scope.md), [verification](proposals/development-functions/verification.md), [review](proposals/development-functions/review.md), [usage](../tooling/workbench/README.md).
''')
print('Task status and journal updated')
