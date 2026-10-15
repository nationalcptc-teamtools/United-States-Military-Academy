# CPTC development workbench

Version 1.0.0. Offline Python 3.10+ command-line tools for **synthetic preparation**. Uses the sibling farm catalog and report generator. PDF also requires the existing [ReportLab dependency](../reporting/requirements.txt). The full source package preserves that sibling layout.

Run from the repository root:

```sh
python tooling/workbench/workbench.py --help
python tooling/workbench/workbench.py search modbus --protocol modbus
python tooling/workbench/workbench.py search winpeas --platform linux --explain-excluded
python tooling/workbench/workbench.py choose "analyze existing capture"
python tooling/workbench/workbench.py card TOOL-013
python tooling/workbench/workbench.py compare TOOL-013 TOOL-014
python tooling/workbench/workbench.py platforms
python tooling/workbench/workbench.py preflight output/workbench/new-destination --require python
python tooling/workbench/workbench.py init output/workbench/session --owner "Training owner"
```

Search is read-only and records no search telemetry or shortlists. Held tools are visible; catalog declarations do not prove installation or event readiness. Python-based candidate platforms are metadata hints, not tested Windows operations. Per-result next actions lead to the existing runbooks. The catalog remains the source of truth; owner/backup/reviewer assignments live in the selected workbench workspace.

Archived/inactive names supported by existing catalog evidence show an explicit lifecycle gap rather than an accepted replacement: for example, `search "open dnp3"` identifies archived OpenDNP3 and its unresolved maintained-alternative gap. This is a view of known catalog evidence, not a complete retirement inventory. Every card distinguishes cataloged, downloaded, integrity checked, tested, independently reviewed, accepted, published and event-approved declarations. Unknown/pending stays explicit; license review is separate from tool review. No promotion/approval or downloaded-artifact inventory is created by these displays.

## Work requests and decisions

Save a request as JSON using this form (replace synthetic values with your preparation request, never client evidence):

```json
{
  "problem": "modbus", "user": "Training operator",
  "input": "Synthetic metadata", "output": "Reviewable text",
  "acceptance": "Operator can explain the observed result and limitation",
  "owner": "Author", "backup": "Backup", "reviewer": "Reviewer",
  "kind": "tool", "value": 4, "frequency": 3, "confidence": 3,
  "effort": 2, "risk": 2, "dependencies": [], "reuse_query": "modbus"
}
```

```sh
python tooling/workbench/workbench.py intake output/workbench/session request.json
python tooling/workbench/workbench.py owner output/workbench/session TOOL-013 --primary Author --backup Backup --reviewer Reviewer
python tooling/workbench/workbench.py card TOOL-013 --workspace output/workbench/session
```

Kinds: tool, adapter, repair, documentation, retirement. The workbench searches the existing catalog and records reusable candidates. Priority is an explainable estimate: value × frequency × confidence ÷ (effort × risk), each input 1–5. It is not measured competition value. Inspect the request/reuse evidence before approving duplicated work.

`decision WORKSPACE FILE` records topic, owner, choice (accepted/rejected/deferred/blocked), reason; deferred/blocked records also require benefit and trigger. Link the same decision from affected work rather than copying it. `transfer WORKSPACE CAPABILITY --base REV --actor NAME [--new-owner NAME]` releases/transfers an existing capability owner. Status shows record age; this is not a new target-claim allocator.

## Create and extend tools

```sh
python tooling/workbench/workbench.py scaffold output/workbench/new-tool --name training_helper --owner Author
python tooling/workbench/workbench.py check-docs output/workbench/new-tool
python output/workbench/new-tool/tool.py --help
```

The skeleton includes help/version, an input placeholder, owner/license/dependency metadata, runbook and small ID/time/hash helpers. Its normal exit is **3/pending** until its author implements and documents real behavior. It does not pretend to execute a valid assessment. Shared exit vocabulary: 0 completed, 1 local failure, 2 invalid request/input, 3 pending/conflict/not-ready.

Extension walkthrough: (1) search for reuse; (2) create/request the tool; (3) author its validated inputs/output and operational limits; (4) keep metadata/help/runbook versions aligned; (5) choose meaningful checks for changed behavior; (6) hand completed synthetic report JSON to the existing reporting path. No adapter starter, producer-envelope contract or contributor fixture library is added. Native scanner formats remain unsupported by this workbench.

`select-checks CHANGED_PATH...` suggests affected checks and integration review needs; it runs no combined check or CI workflow. Relevant available checks are in [tests](tests/test_workbench.py). Preserve old report schemas and existing farm behavior. Public files/fixtures must be synthetic; review the actual package contents.

`check-links [MARKDOWN_FILE...]` checks local links/fragments and the existing forty catalog/runbook identifiers without following external URLs. With no file argument it checks the workbench Markdown documents. This is a focused documentation check, separate from test execution.

## Notes, plans and manual run records

`note WORKSPACE FILE` records an authored JSON note. `edit-note WORKSPACE ID FILE --base REV` preserves conflicting current/proposed versions if the author edited stale state. `show WORKSPACE COLLECTION ID` retrieves a record. State changes use a short exclusive lock and atomic replacement. If a process crashes while holding `.write-lock`, verify there is no active editor and preserve/copy the workspace before recovering; the program never silently breaks an active lock. Parent directories must be trusted and quiescent.

Operator-authored plan JSON fields: command (preview text only), scope_ref, profile, effects, limits, destination, targets[], approved_targets[], excluded_targets[], discovered[]. `plan WORKSPACE FILE` records a sanitized preview and fingerprints. Newly discovered addresses never become approved targets. `revalidate WORKSPACE PLAN CURRENT.json --reviewer NAME [--accept-change]` compares scope/profile/targets supplied by the operator; no DNS query is performed. Changed metadata needs explicit reacceptance, and excluded/outside targets remain invalid. `deviation` records reason, actor and external approval reference without inheriting original-profile acceptance. No command from a plan is dispatched.

```sh
python tooling/workbench/workbench.py run-record output/workbench/session --tool synthetic-source --version 1 --operator Author --status failed --exit-code 2 --limitations "Invented failure; not a target execution"
```

Run statuses include queued/running/success/partial/failed/cancelled/not_run. Success requires exit 0. Tool/import/render events stay distinct. `event` records later stage status and a concise diagnostic code. No arbitrary stdout or command arguments enter these logs. Binary/config identities can be supplied using the corresponding hash options; supplied hashes remain assertions, not authenticity evidence. Event history is bounded at 500 entries and surfaces truncation. Workspace JSON is limited to 2 MB; large work must be split deliberately instead of silently dropping facts.

`simulate WORKSPACE --seconds 8` supervises only a fixed harmless synthetic process group. In another terminal use `status`, then `cancel WORKSPACE RUN_ID`; Ctrl-C also cancels. The supervisor terminates its child tree and records the actual synthetic outcome. It never launches an operator-supplied command. Actual tool stop/resume remains the external runner/operator's responsibility; cancellation of a manual record returns that guidance. `resume WORKSPACE RUN_ID --disposition repeat|skip --actor NAME` records the decision and executes nothing. For a real approved run, use the existing Linux/Windows runner's scope/stop/retention procedures, preserve authorized output there, and enter only permitted metadata. An external tool crash is not a clean bill of health.

Troubleshooting: missing binary/runtime → preflight/selected installer owner; permission/AV failure → report the prerequisite, never disable controls; authentication/unsupported format → retain failed/not-run status, seek the approved credential/format; import/render failure → correct the passive stage using preserved input, never automatically repeat target work; output exists → choose a new directory; lock busy → coordinate the editor; incomplete ledger attachment after storage error → inspect the complete snapshot manifest/revision before attaching a new record.

## Human review and reports

```sh
python tooling/workbench/workbench.py preview-import tooling/reporting/examples/report-marked.json
python tooling/workbench/workbench.py import-report output/workbench/session tooling/reporting/examples/report-marked.json
```

Use the returned import ID in subsequent commands. Import accepts only the reporter's completed synthetic report JSON schemas 1.0/1.1/1.2. Unknown/native formats are rejected. Same bytes are idempotent; conflicting finding IDs block a second import. Original input remains in the workspace; imported claims require this workflow's human review. `prefill` returns the finding and fields an author must verify. `author WORKSPACE IMPORT FINDING FILE --base REV` updates using the existing finding schema, invalidates prior acceptance and preserves stale-edit conflicts.

```sh
python tooling/workbench/workbench.py duplicates WORKSPACE IMPORT_ID
python tooling/workbench/workbench.py review WORKSPACE IMPORT_ID FINDING_ID --decision accept --reason "Synthetic manual validation" --reviewer Reviewer
python tooling/workbench/workbench.py complete WORKSPACE IMPORT_ID --rubric objective
python tooling/workbench/workbench.py snapshot WORKSPACE IMPORT_ID output/workbench/draft-1 --pdf
```

Duplicate suggestions explain title similarity/shared assets and never merge automatically. `merge` requires actor/reason, preserves originals, retains combined assets/evidence/markings and returns the primary to candidate review. `undo-merge` refuses to overwrite later author changes. Human rejection explicitly omits a finding from the derived report while preserving the original and limitation. No score/impact/CVE applicability is inferred. `complete` checks author/reviewer/rubric gaps. A snapshot `--reviewer NAME` requests the reporter's reviewed-training label only after all checks; this is not official submission.

Snapshots contain authoritative `input.json`, synchronized Markdown/optional PDF, changes and a hash manifest. New output directory each time. Run outcomes and supplied limitations, incident actions and retest states appear in a shared appendix in both formats. Source and workspace/incident/retest markings are conservatively inherited; PII Red dominates PII and other categories remain combined. Imported legacy data derives a visibly versioned schema 1.2 snapshot; original source/schema/hash remain identified. `changes.json` lists finding and run/incident/retest differences. Editing Markdown alone does not update the PDF or authoritative input.

`retest WORKSPACE FILE` records finding, actor, summary, status (recommended/applied/verified), evidence[]; verified needs supplied evidence references. References are not automatic proof that a fix worked. `incident WORKSPACE FILE` records run, actor, summary and optional stop/containment/notification/cleanup text and markings; missing actions remain pending, no message is sent. `integrity FILE SHA256` explicitly checks selected bytes outside rendering; matching bytes do not prove authenticity. `handling WORKSPACE FILE` records custodian and retention/export/deletion decision references; it transfers/deletes nothing.

Integrity checks stream the complete explicitly selected file, up to 512 MiB; they never accept the checksum of a truncated prefix. JSON inputs, source-package members and workspace reads retain their separate 2 MB bound. Run records may include `--scope-ref`, repeated `--evidence-ref` and `--plan-id`; `event --exit-code` describes that stage's exit independently of the tool exit.

## Status, handoff and releases

`status WORKSPACE [--destination NEW_DIRECTORY]` exposes linked record IDs, revisions/age, stale state and separate technical/user/event acceptance. There is no new coverage dashboard or role-specific queue. Shift notes can record scope changes, active jobs, incidents, evidence location and pending reviews; use the structure in [HANDOVER.md](HANDOVER.md). `metric WORKSPACE FILE` stores manually measured seconds, search_misses, retyping, duplicate_work, review_corrections and errors with task/operator/environment. No automatic search logging or timed-drill system is installed; no speed gain has been measured.

`handoff WORKSPACE NEW_DIRECTORY --reviewer NAME [--import-id ID]` previews files/markings without writing. Add `--approve-export` after inspecting the synthetic input to create neutral JSON/Markdown/manifest for **manual cloud-system handoff**. Known secret fields/assignment patterns are redacted, and inherited restrictions remain. Human review is still needed. This application provides no local AI, AI correction, cloud API, automatic transfer or model output execution. Real data, event permission and downstream cloud authorization remain separate from this synthetic preparation workflow.

`package NEW_DIRECTORY` creates a deterministic source-only preparation ZIP, manifest and checksum from an explicit allowlist. `compare-releases OLD.zip NEW.zip` identifies changed paths for interface/license/dependency/behavior review. Preserve the old reviewed release; recovery means verifying its manifest, extracting to a new trusted directory and selecting that known version without overwriting working evidence. `review-packet WORKSPACE NEW_DIRECTORY EVIDENCE.json` combines supplied synthetic verification evidence with exact source hashes and limits. It does not authenticate the supplied test claims. See [CONTRACTS.md](CONTRACTS.md) and [UI evaluation](UI-EVALUATION.md).

No scans, installer calls, client data, native parsers, model inference or publication occur in these commands. User acceptance, actual event/host compatibility and use of external cloud systems remain explicit.
