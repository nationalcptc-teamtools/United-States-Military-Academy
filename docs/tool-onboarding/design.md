# Design

D-01 (FR-01..03): add onboard.py alongside install.py with a versioned onboarding.json. Reuse validated legacy manifest data through explicit source/group/asset identifiers, never parse coverage prose. Select by stable ID or slug. Existing install.py remains the profile implementation.

D-02 (FR-02,05, NFR-02): separate trusted prefix and per-selection state. Identity binds selected recipe definitions and inherited manifest bytes. Mark incomplete before work. Record distro versions, isolated Python packages, native/asset file hashes, source commit and OCI identities. Validate against expected selected closure before checker subprocesses. Plan prints JSON without writes or subprocesses.

D-03 (FR-04): immutable Linux amd64 OCI image acquisition for sensors, broker and service labs. No docker run, compose up, systemctl or upstream bootstrap scripts during acquisition. Source recipes use pinned checkout/build where appropriate; ChirpStack configuration and every constituent image are acquired. Conpot/OpenPLC may use pinned source image builds where official release images cannot be verified. Checks use file hashing, metadata commands and local docker image inspection only.

D-04 (FR-06): one shared guide and generated installation matrix, retaining catalog/tool runbooks for operation boundaries. Navy/teal Segoe UI SVG follows existing quick-start.svg. Hold reasons remain visible; staged assets never become operationally accepted by acquisition.

D-05 (FR-07): extend fixed farmkit/workbench allowlists without exceeding existing package limits. Direct onboard.py must work from extracted farmkit; root tools.py is a convenience shim.

Rejected alternatives: installing the full profile for each tool (unrelated dependencies/held assets), automatic service startup, a universal shell-command registry and copying every vendor source into Git.
