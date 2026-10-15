# Local interface evaluation

Decision: deliver the command-line interface and JSON/Markdown status/handoff exports. Do not build a browser server in this scope. User approved evaluating a browser interface, not choosing one automatically.

| Criterion | Current CLI/static exports | Candidate local browser interface |
| --- | --- | --- |
| Offline use | No accounts, remote assets, browser or listener; actual passive checks in verification | Could be local/offline, but assets/authentication/listener/CSRF and packaging need design |
| Find tools / review status | Search/filter/card/compare/chooser/status commands expose results as JSON; Markdown exports readable in an editor | Could improve visual browsing; no measured participant benefit is available |
| Dependencies/resources | Python standard library, existing optional PDF dependency; source package is small | Adds a server/UI dependency or local static build; implementation/maintenance cost unmeasured |
| Authoring friction | JSON forms and explicit revisions are inspectable but require file/command familiarity | Forms may reduce repeated entry; would need accessibility, conflict and data-handling verification |
| Handoff/recovery | Plain files, manifests and immutable snapshots are already implemented | Must retain exactly the same file/text fallback and honest status boundaries |

There is no controlled usability/time-saving study: the user excluded timed drills and broad practice initiatives. Manual efficiency records can later supply actual task success, retyping/error/review-correction and time evidence. A browser implementation should require demonstrated need, an approved local runtime/data boundary, keyboard accessibility and a resource comparison. It should not be introduced merely because a web framework is available.

Current practical result: the implemented commands supply a complete deterministic path and require no new service to deploy. Actual machine/runtime/package measurements in verification characterize the CLI only; they are not claims about participant efficiency or hypothetical browser performance. Revisit the presentation decision only with new evidence/user direction.
