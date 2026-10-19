# Tasks

| Task | Depends | Owner / deliverable | Acceptance / evidence |
| --- | --- | --- | --- |
| T-01 | — | Root + read-only analyst: inspect inventory/upstream, preserve baseline | FR-01 scope and source identities; baseline retained locally |
| T-02 | T-01 | Root: registry, selection CLI, passive checker | FR-01..05; meaningful selection/integrity tests |
| T-03 | T-02 | Root: guide, diagram, links and package allowlists | FR-06..07; extracted packages and visual inspection |
| T-04 | T-02,03 | Root tester: synthetic regression + disposable Linux acquisitions | NFR-03; dated verification with exact limitations |
| T-05 | T-04 | Independent read-only reviewer: spec and quality review | All actionable R-* resolved or explicitly accepted |
| T-06 | T-05 | Root: branch/PR publication and handoff | FR-08; PR attached, no merge; acceptance remains pending |

T-01..T-06 completed. Analyst/design advice was independently provided read-only; root implemented and tested. Verification evidence and all remediated R-ON-* findings are in verification.md and review.md. Branch codex/tool-onboarding and [pull request #3](https://github.com/nationalcptc-teamtools/United-States-Military-Academy/pull/3) are published; the PR is attached to the task and remains unmerged. User/event acceptance remains pending. A portable legacy test fixture additionally supplies its own synthetic reporting prerequisite instead of assuming the full repository exists; no installer precondition was weakened.
