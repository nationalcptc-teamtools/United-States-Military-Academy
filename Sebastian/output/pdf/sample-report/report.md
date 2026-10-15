# Penetration testing report

**DRAFT | SYNTHETIC DATA**

Client: Synthetic Training Organization  
Team: Training assessment team  
Engagement: TRAINING\-001  
Report date: 2026\-10\-14  
Data marking: SYNTHETIC TRAINING DATA

Training demonstration only. No real assessment, event permission, or submission is established.

## Executive summary

Two synthetic observations demonstrate the workflow: one confirmed training finding about unnecessary information exposure and one candidate requiring validation\. The generator carries supplied evidence and remediation into a draft report; it makes no independent vulnerability judgments\.

## Scope

- Synthetic web application at training\.example\.test
- Demonstration observations only; no network actions were performed

## Methodology

This report demonstrates importing structured findings from future team\-script adapters\. The observations and evidence below are invented training data\. Analysts would verify actual findings against authorized evidence before submission\.

## Limitations

- No real systems, credentials, client data, or actual CPTC environment were tested\.
- Candidate observations require human validation; this report is not an event submission\.
- CVE/CVSS values are intentionally omitted because no public vulnerability match was established\.

## Finding summary

Total: 2 | Confirmed: 1 | Candidate: 1

Critical: 0 | High: 0 | Medium: 1 | Low: 1 | Info: 0

## F\-001: Unnecessary internal details in a public error response

### Business severity

MEDIUM \- In the training scenario, internal paths and component details are exposed without authentication; no sensitive records or access gain were demonstrated\.

### Validation status

CONFIRMED

### Affected assets

training\.example\.test / application error handler

### Observation

A synthetic error\-response fixture includes an internal path and application component names\. The training analyst marked this finding confirmed after reviewing the fixture\. This status describes the exercise only\.

### Validation steps and results

2026\-10\-14T14:00:00\-04:00: reviewed the synthetic application response fixture\.

Compared the response against the training requirement that public errors contain only a correlation ID\.

### Business impact

In an actual deployment, unnecessary implementation details could aid reconnaissance\. The demonstration does not establish access to client records or an exploitation chain\.

### Remediation

Configure the application error handler to return a generic message and correlation ID\. Keep diagnostic paths and stack traces in access\-controlled application logs\. Add regression coverage for unauthenticated error responses\.

### Retest plan

In an authorized test environment, trigger the same error and verify the response contains only the generic message and correlation ID\.

Confirm authorized operators can still correlate the ID with protected diagnostic logs\.

### Evidence E\-001

Observed: 2026\-10\-14T14:00:00\-04:00 \| Collector: Training analyst

Source: synthetic\-response\-fixture 1\.0

Normalized evidence summary: Invented response excerpt: error at /opt/training/app/handler\.py\. No actual host or file was accessed\.

Private artifact reference \(not embedded or verified\): evidence/synthetic\-error\-response\.txt

## F\-002: Candidate: incomplete session\-cookie configuration

### Business severity

LOW \- A synthetic header suggests a missing attribute, but the full session flow and compensating controls have not been validated\.

### Validation status

CANDIDATE

### Affected assets

training\.example\.test / session creation

### Observation

A training fixture suggests that one session\-cookie attribute may be missing\. The excerpt alone does not prove a vulnerability or an exploitable session flow\.

### Validation steps and results

2026\-10\-14T14:10:00\-04:00: reviewed only the synthetic header excerpt\.

Full session behavior, transport settings, and compensating controls remain untested\.

### Business impact

If confirmed in context, weaker cookie handling could reduce protection against certain session attacks\. No session compromise is claimed\.

### Remediation

First validate the complete session flow and identify the intended browser security controls\. If a required cookie attribute is missing, configure it in the session middleware and verify application compatibility\.

### Retest plan

Review session creation and renewal responses in the authorized environment\.

Verify the intended attributes persist throughout the flow and document any compensating controls\.

### Evidence E\-002

Observed: 2026\-10\-14T14:10:00\-04:00 \| Collector: Training analyst

Source: synthetic\-header\-fixture 1\.0

Normalized evidence summary: Invented header excerpt: Set\-Cookie: training\_session=\[REDACTED\]; Path=/\. This is a fabricated value, not a credential\.

## Review record

Human review pending.

Review labels are local metadata. Inspect the actual artifacts before any authorized use.

Evidence files are referenced, never opened. The manifest identifies the input and outputs by hash; it does not verify the observations.
