# Workbench execution guidance

Tech Lead/root, 2026-10-15. Root retains the sole editing slot across code, docs and tests. Authorized separate reviewer operates read-only. User's all-idea decision gate is satisfied; seventy included outcomes control delivery, with later local-AI correction replaced by a manual cloud handoff. Sources and integration checkout remain reference-only.

Implement T-DF-02 → 03 → 04 → 05; validate settled work in 06; independent review/remediation in 07; package/handoff in 08. Run appropriate focused checks after each behavior change, then one complete meaningful final verification. Record actual failures and fix them; do not expand into excluded products to improve test totals.

Developer scope: new `tooling/workbench/` plus optional appendix API in existing reporter. Preserve farm catalog/installer/contracts, reporter CLI and accepted schemas, source originals and independent runners. Explicit local synthetic data only. No native parser/producer envelope, target dispatch, model inference, upload, CI or new global ID/claim system. No public repository write in this request.

Tester scope: inspect actual changed contracts and exercise synthetic CLI intake/search/preflight/scaffold/plan/run/log/review/merge/retest/snapshot/handoff paths. Compare structured outcomes, source/hash/marking preservation and meaningful failure behavior. Run existing reporter regressions and inspect generated sample PDF text/pages. Distinguish Windows preparation, Linux process path if available, actual hosts and cloud delivery. Never claim participant speed gain from machine timings.

Reviewer scope (user authorized): inspect request/decisions/reconciled design, actual modules and tests/evidence. Return independent specification/quality conclusions with exact inspected identities, R-DF IDs, location/evidence/impact/correction and resolved/pending disposition. Do not edit, create files, execute scanner/install/model/network paths or publish. Read-only/in-memory test functions may be reproduced; root runs file-writing checks and attributes them separately. Root records review and makes changes, then affected validation and reviewer recheck.

Route design conflicts through Architect/Planner. Ask only for consequential missing decisions; routine reversible details stay within current scope. Real event/runtime/data/cloud approvals remain explicit gates and do not become inferred authorization through feature implementation. Keep active role artifacts; no proposal README consolidation before complete scoped work and explicit user acceptance.
