# Synthetic manual handoff

Handling: ORCON//PROPIN//PII Red//FI

External cloud processing and final acceptance are separate human decisions.

No local AI, AI correction, API request or automatic upload occurred.

Review owner: Synthetic export exercise

```json
{
  "ai_correction": false,
  "automatic_transfer": false,
  "data_category": "synthetic",
  "handling": {
    "custodian": "Synthetic exercise owner",
    "deletion": "No automatic deletion",
    "export": "Synthetic files only",
    "retention": "Preparation example only; actual policy unresolved"
  },
  "local_ai": false,
  "markings": [
    "ORCON",
    "PROPIN",
    "PII Red",
    "FI"
  ],
  "purpose": "Manual cloud-system handoff; external processing is outside this application",
  "redaction_note": "Known metadata/assignment patterns redacted; markings preserved; human inspection still required",
  "report": {
    "classification": "SYNTHETIC TRAINING DATA",
    "data_category": "synthetic",
    "engagement": {
      "client": "Synthetic Training Organization",
      "executive_summary": "Two synthetic observations demonstrate the workflow: one confirmed training finding about unnecessary information exposure and one candidate requiring validation. The generator carries supplied evidence and remediation into a draft report; it makes no independent vulnerability judgments.",
      "id": "TRAINING-001",
      "limitations": [
        "No real systems, credentials, client data, or actual CPTC environment were tested.",
        "Candidate observations require human validation; this report is not an event submission.",
        "CVE/CVSS values are intentionally omitted because no public vulnerability match was established.",
        "Handling tags in this invented fixture demonstrate inheritance only; no actual personal or financial information is included."
      ],
      "methodology": "This report demonstrates importing structured findings from future team-script adapters. The observations and evidence below are invented training data. Analysts would verify actual findings against authorized evidence before submission.",
      "methodology_sections": {
        "cleanup": "No target state was changed in this exercise. Remediation and retest actions below are proposed checks for an authorized environment, not completed work.",
        "information_gathering": "The fixture author defined a synthetic web application and two invented response examples. No customer inventory or scope was inferred.",
        "service_enumeration": "Only synthetic response metadata was reviewed. No port scan, active request, or service discovery was performed.",
        "validation": "The training analyst reviewed each fixture and retained the supplied confirmed or candidate status. No exploitation or access gain is claimed."
      },
      "objective": "Demonstrate a structured assessment report using invented observations. No actual client, host, or network was assessed.",
      "recommendations": [
        "In the synthetic scenario, keep detailed diagnostics in protected logs and return a generic public error with a correlation ID.",
        "Validate the complete session flow before deciding whether the candidate cookie configuration needs remediation."
      ],
      "report_date": "2026-10-14",
      "scope": [
        "Synthetic web application at training.example.test",
        "Demonstration observations only; no network actions were performed"
      ],
      "team": "Training assessment team"
    },
    "findings": [
      {
        "assets": [
          "training.example.test / application error handler"
        ],
        "business_impact": "In an actual deployment, unnecessary implementation details could aid reconnaissance. The demonstration does not establish access to client records or an exploitation chain.",
        "description": "A synthetic error-response fixture includes an internal path and application component names. The training analyst marked this finding confirmed after reviewing the fixture. This status describes the exercise only.",
        "evidence": [
          {
            "artifact": "evidence/synthetic-error-response.txt",
            "collector": "Training analyst",
            "id": "E-001",
            "markings": [
              "FI"
            ],
            "observed_at": "2026-10-14T14:00:00-04:00",
            "summary": "Invented response excerpt: error at /opt/training/app/handler.py. No actual host or file was accessed.",
            "tool": "synthetic-response-fixture",
            "tool_version": "1.0"
          }
        ],
        "id": "F-001",
        "markings": [
          "PROPIN"
        ],
        "remediation": "Configure the application error handler to return a generic message and correlation ID. Keep diagnostic paths and stack traces in access-controlled application logs. Add regression coverage for unauthenticated error responses.",
        "retest_steps": [
          "In an authorized test environment, trigger the same error and verify the response contains only the generic message and correlation ID.",
          "Confirm authorized operators can still correlate the ID with protected diagnostic logs."
        ],
        "severity": "medium",
        "severity_rationale": "In the training scenario, internal paths and component details are exposed without authentication; no sensitive records or access gain were demonstrated.",
        "status": "confirmed",
        "title": "Unnecessary internal details in a public error response",
        "validation_steps": [
          "2026-10-14T14:00:00-04:00: reviewed the synthetic application response fixture.",
          "Compared the response against the training requirement that public errors contain only a correlation ID."
        ]
      },
      {
        "assets": [
          "training.example.test / session creation"
        ],
        "business_impact": "If confirmed in context, weaker cookie handling could reduce protection against certain session attacks. No session compromise is claimed.",
        "description": "A training fixture suggests that one session-cookie attribute may be missing. The excerpt alone does not prove a vulnerability or an exploitable session flow.",
        "evidence": [
          {
            "collector": "Training analyst",
            "id": "E-002",
            "markings": [
              "PII Red"
            ],
            "observed_at": "2026-10-14T14:10:00-04:00",
            "summary": "Invented header excerpt: Set-Cookie: training_session=[REDACTED]; Path=/. This is a fabricated value, not a credential.",
            "tool": "synthetic-header-fixture",
            "tool_version": "1.0"
          }
        ],
        "id": "F-002",
        "markings": [
          "PII"
        ],
        "remediation": "First validate the complete session flow and identify the intended browser security controls. If a required cookie attribute is missing, configure it in the session middleware and verify application compatibility.",
        "retest_steps": [
          "Review session creation and renewal responses in the authorized environment.",
          "Verify the intended attributes persist throughout the flow and document any compensating controls."
        ],
        "severity": "low",
        "severity_rationale": "A synthetic header suggests a missing attribute, but the full session flow and compensating controls have not been validated.",
        "status": "candidate",
        "title": "Candidate: incomplete session-cookie configuration",
        "validation_steps": [
          "2026-10-14T14:10:00-04:00: reviewed only the synthetic header excerpt.",
          "Full session behavior, transport settings, and compensating controls remain untested."
        ]
      }
    ],
    "markings": [
      "ORCON"
    ],
    "schema_version": "1.2"
  },
  "reviewer": "Synthetic export exercise",
  "status": {
    "acceptance": {
      "event": "pending",
      "implementation": "see verification",
      "user": "pending"
    },
    "counts": {
      "conflicts": 0,
      "decisions": 1,
      "imports": 1,
      "incidents": 1,
      "merges": 0,
      "metrics": 0,
      "notes": 1,
      "owners": 1,
      "plans": 1,
      "requests": 1,
      "retests": 1,
      "reviews": 1,
      "runs": 5,
      "snapshots": 1
    },
    "data_category": "synthetic",
    "log_truncated": false,
    "markings": [
      "ORCON",
      "PROPIN",
      "PII Red",
      "FI"
    ],
    "next_action": "Resolve blockers, review candidates and inspect actual records; no automatic dispatch",
    "records": {
      "incidents": [
        {
          "age_seconds": 4,
          "id": "incident-52560a14c0054ada",
          "revision": 1,
          "status": "recorded",
          "updated_at": "2026-10-15T20:57:39+00:00"
        }
      ],
      "owners": [
        {
          "age_seconds": 12,
          "id": "TOOL-013",
          "revision": 1,
          "status": "assigned",
          "updated_at": "2026-10-15T20:57:31+00:00"
        }
      ],
      "requests": [
        {
          "age_seconds": 13,
          "id": "request-9ef5903540d04772",
          "revision": 1,
          "status": "recorded",
          "updated_at": "2026-10-15T20:57:30+00:00"
        }
      ],
      "runs": [
        {
          "age_seconds": 8,
          "id": "run-15767639e1264b1e",
          "revision": 2,
          "status": "not_run",
          "updated_at": "2026-10-15T20:57:35+00:00"
        },
        {
          "age_seconds": 7,
          "id": "run-19dd7231e6814fe6",
          "revision": 4,
          "status": "success",
          "updated_at": "2026-10-15T20:57:36+00:00"
        },
        {
          "age_seconds": 8,
          "id": "run-21ab8cad4ed1426b",
          "revision": 2,
          "status": "failed",
          "updated_at": "2026-10-15T20:57:35+00:00"
        },
        {
          "age_seconds": 9,
          "id": "run-414fccce497743a5",
          "revision": 2,
          "status": "partial",
          "updated_at": "2026-10-15T20:57:34+00:00"
        },
        {
          "age_seconds": 8,
          "id": "run-bab2097963b645bc",
          "revision": 2,
          "status": "cancelled",
          "updated_at": "2026-10-15T20:57:35+00:00"
        }
      ],
      "snapshots": [
        {
          "age_seconds": 2,
          "id": "snapshot-38cdf0ce68a54894",
          "revision": 1,
          "status": "draft",
          "updated_at": "2026-10-15T20:57:41+00:00"
        }
      ]
    },
    "revision": 25,
    "updated_at": "2026-10-15T20:57:42+00:00",
    "version": "1.0.0"
  },
  "version": "1.0.0",
  "workspace_revision": 25
}

```
