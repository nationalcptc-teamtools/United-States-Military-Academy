# Requirements

| ID | Requirement / acceptance |
| --- | --- |
| FR-01 | All TOOL-001..040 have unique typed acquisition records or explicit holds; additional tools use distinct stable names. |
| FR-02 | One-line list/show/plan/install/check interface; explicit selections install only their declared components. A held selection fails before any mutation. |
| FR-03 | Reuse existing pins and acquisition helpers; preserve core/full behavior and separate selection state. New source/assets/images use immutable identities; distro/transitives are honestly recorded. |
| FR-04 | Optional sensors, broker and lab images are acquired without starting services, assessments or containers. Source-only acquisitions are explicitly staged. |
| FR-05 | Passive checks reject altered recipes, incomplete inventories, modified files, absent images/packages and malformed state before following saved paths. |
| FR-06 | Document prerequisites, exact commands, outputs, standalone use, recovery and limitations; provide SVG matching existing guides. Cover existing runner extras and platform exclusions. |
| FR-07 | Both source packaging paths include new scripts, manifests, tests and guides; extracted package entrypoints work. |
| FR-08 | Publish reviewed changes on a branch/PR against current upstream, preserving contributor changes; no automatic merge. |
| NFR-01 | Standard library controller; no target discovery, arbitrary command execution API, credentials or telemetry. Dry plan is read-only and invokes no subprocess. |
| NFR-02 | Deterministic bounded selection and safe trusted installation paths; failures remain incomplete and preserve existing content. |
| NFR-03 | Meaningful synthetic tests plus bounded disposable Linux installation evidence, independent review and explicitly recorded skips/limits. |

Explicit exclusions: native scanner adapters, broader CI, live testing, hardware readiness, full offline reinstall cache, universal cross-platform locks and client-data handling. Held projects retain their recorded reasons. Windows may inspect plans; Kali Linux amd64 is the acquisition host. Runtime services require a separate explicit operator action and approved lab configuration.
