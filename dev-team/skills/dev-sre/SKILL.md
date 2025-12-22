---
name: dev-sre
description: |
  Gate 2 of the development cycle. VALIDATES that observability was correctly implemented
  by developers. Does NOT implement observability code - only validates it.

trigger: |
  - Gate 2 of development cycle
  - Gate 0 (Implementation) complete with observability code
  - Gate 1 (DevOps) setup complete
  - Service needs observability validation (logging, tracing)

skip_when: |
  - No service implementation (documentation only)

NOT_skip_when: |
  - "Task says observability not required" → AI cannot self-exempt. ALL services need observability.
  - "Pure frontend" → If it calls ANY API, backend needs observability. Frontend-only = static HTML.
  - "MVP doesn't need observability" → MVP without observability = blind MVP. No exceptions.

sequence:
  after: [dev-devops]
  before: [dev-testing]

related:
  complementary: [dev-cycle, dev-devops, dev-testing]

verification:
  automated:
    - command: "docker-compose logs app 2>&1 | head -5 | jq -e '.level'"
      description: "Logs are JSON structured"
      success_pattern: "info|debug|warn|error"
  manual:
    - "Verify logs include trace_id when tracing is enabled"

examples:
  - name: "API service observability validation"
    context: "Go API with PostgreSQL dependency"
    expected_output: |
      - JSON structured logging with trace correlation
  - name: "Background worker observability validation"
    context: "Job processor service"
    expected_output: |
      - Structured JSON logging
---

## Standards Loading (MANDATORY)

**Before ANY SRE validation, you MUST load Ring SRE standards:**

See [CLAUDE.md](https://raw.githubusercontent.com/LerianStudio/ring/main/CLAUDE.md) and [dev-team/docs/standards/sre.md](https://raw.githubusercontent.com/LerianStudio/ring/main/docs/standards/sre.md) for canonical requirements. This section summarizes the loading process.

**MANDATORY ACTION:** You MUST use the WebFetch tool NOW:

| Parameter | Value |
|-----------|-------|
| url | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/sre.md` |
| prompt | "Extract all SRE standards, observability requirements, metric patterns, and health check specifications" |

**Execute this WebFetch before proceeding.** Do NOT continue until standards are loaded and understood.

If WebFetch fails → STOP and report blocker. Cannot proceed without Ring SRE standards.

### Standards Loading Verification

**After WebFetch, confirm in your analysis:**
```markdown
| Ring SRE Standards | ✅ Loaded |
| Sections Extracted | Health Endpoints, Logging, Tracing |
```

**CANNOT proceed without successful standards loading.**


# SRE Validation (Gate 2)

## Overview

This skill VALIDATES that observability was correctly implemented by developers:
- Structured logging with trace correlation
- OpenTelemetry tracing instrumentation

## CRITICAL: Role Clarification

**Developers IMPLEMENT observability. SRE VALIDATES it.**

| Who | Responsibility |
|-----|----------------|
| **Developers** (Gate 0) | IMPLEMENT observability following Ring Standards |
| **SRE Agent** (Gate 2) | VALIDATE that observability is correctly implemented |

**If observability is missing or incorrect:**
1. SRE reports issues with severity levels
2. Issues go back to developers to fix
3. SRE re-validates after fixes

## Blocker Criteria - STOP and Report

| Decision Type | Examples | Action |
|---------------|----------|--------|
| **HARD BLOCK** | Service lacks JSON structured logs, verification commands not run (no evidence), user says "feature complete, add observability later" | **STOP immediately** - Return to Gate 0. Cannot proceed. User CANNOT override. |
| **CRITICAL** | Logs are fmt.Println/echo, not JSON structured | **Report CRITICAL severity** - Return to Gate 0. Must fix. User CANNOT override. |

### Cannot Be Overridden

**These requirements are NON-NEGOTIABLE and cannot be waived by:**

| Requirement | Cannot Be Waived By | Rationale |
|-------------|---------------------|-----------|
| Gate 2 execution | CTO, PM, "MVP" arguments | Observability prevents production blindness |
| Automated verification | "Developer confirms it works" | Evidence required for Gate 2 PASS |
| JSON structured logs | "Plain text is enough" | Minimum viable observability - structured logs required |
| "Complete" includes observability | Deadline pressure | Definition of done is non-negotiable |

**If pressured:** "Observability is PART of completion, not an addition to it. Gate 2 cannot be skipped regardless of authority or deadline."

## Severity Calibration

| Severity | Scenario | Gate 2 Status | Can Proceed? |
|----------|----------|---------------|--------------|
| **CRITICAL** | Missing ALL observability (no structured logs) | FAIL | ❌ Return to Gate 0 |
| **CRITICAL** | fmt.Println/echo instead of JSON logs | FAIL | ❌ Return to Gate 0 |
| **CRITICAL** | Verification commands not run | FAIL | ❌ Cannot mark complete |
| **CRITICAL** | "DEFERRED" appears in validation output | FAIL | ❌ Return to Gate 0 |
| **LOW** | Dashboard not yet created (dashboards are optional) | PARTIAL | ✅ Can proceed with note |

## Pressure Resistance

See [shared-patterns/shared-pressure-resistance.md](../shared-patterns/shared-pressure-resistance.md) for universal pressure scenarios (including Combined Pressure Scenarios).

**Gate 2-specific note:** Minimum viable observability = structured JSON logs. No exceptions.

## Common Rationalizations - REJECTED

See [shared-patterns/shared-anti-rationalization.md](../shared-patterns/shared-anti-rationalization.md) for universal anti-rationalizations.

**Gate 2-specific rationalizations:**

| Excuse | Reality |
|--------|---------|
| "Add tracing later" | Later = never. Retrofitting is 10x harder. |
| "Dashboard can come later" | Dashboard is optional but structured logging is not. |
| "Task says observability not needed" | AI cannot self-exempt. Tasks don't override gates. |
| "Basic fmt.Println logs are enough" | fmt.Println is not structured, not searchable, not alertable. JSON logs required. |
| "Feature complete, observability later" | Feature without observability is NOT complete. Redefine "complete". |

## Red Flags - STOP

See [shared-patterns/shared-red-flags.md](../shared-patterns/shared-red-flags.md) for universal red flags (including Observability section).

If you catch yourself thinking ANY of those patterns, STOP immediately. Return to developers to implement observability.

## Component Type Decision Tree

**Not all code is a service. Use this tree to determine observability requirements:**

```plaintext
Is it runnable code?
├── NO (library/package) → No observability required
│   └── Libraries are consumed by services that have observability
│
└── YES → Does it expose HTTP/gRPC/TCP endpoints?
    ├── YES (API Service) → FULL OBSERVABILITY REQUIRED
    │   └── /health + /ready + structured logs + tracing
    │
    └── NO → Does it run continuously?
        ├── YES (Background Worker) → WORKER OBSERVABILITY
        │   └── /health + structured logs + tracing
        │
        └── NO (Script/Job) → SCRIPT OBSERVABILITY
            └── Structured logs + exit codes + optional /health
```

### Component Type Requirements

| Type | JSON Logs | Tracing | Exit Codes |
|------|-----------|---------|------------|
| **API Service** | REQUIRED | Recommended | N/A |
| **Background Worker** | REQUIRED | Optional | N/A |
| **CLI Tool** | REQUIRED | N/A | REQUIRED |
| **One-time Script** | REQUIRED | N/A | REQUIRED |
| **Library** | N/A | N/A | N/A |

### Migration Scripts and One-Time Jobs

**Migration scripts still need observability, but different kind:**

| Requirement | Why | Example |
|-------------|-----|---------|
| **Structured logs** | Track progress, debug failures | `{"level":"info","step":"migrate_users","count":1500}` |
| **Exit codes** | Orchestration needs success/failure signal | `exit 0` success, `exit 1` failure |
| **Idempotency logging** | Know if re-run is safe | `{"already_migrated":true,"skipping":true}` |

## Anti-Rationalization Table

See [shared-patterns/shared-anti-rationalization.md](../shared-patterns/shared-anti-rationalization.md) for universal anti-rationalizations.

### Gate-Specific Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Core functionality works, observability is enhancement" | Observability is PART of definition of done, not addition to it. Feature is NOT complete. | **STOP. Return to Gate 0. Gate 2 is REQUIRED.** |
| "It's just MVP, add structured logging Monday" | MVP without structured logging = debugging nightmare. "Later" = never. Retrofitting is 10x harder. | **STOP. Implement JSON logging before Gate 2.** |
| "Tech lead approved skipping Gate 2" | Gates are NON-NEGOTIABLE. Authority cannot waive mandatory gates. | **STOP. Inform user gates cannot be waived.** |
| "Plain text logs exist, that's enough" | Minimum = JSON structured logs. Plain text = Gate 2 FAIL. | **STOP. Implement JSON structured logging.** |
| "Developer confirms it works" | Confirmation ≠ Verification. MUST run automated validation commands. | **STOP. Run verification checklist.** |
| "It's just a script, runs once" | Scripts fail. Logs tell you why. | **Add structured logging** |
| "Library doesn't need observability" | Correct! Libraries are exempt. | **Verify it's truly a library** |
| "Exit code 0 is enough" | Exit code + logs = complete picture. | **Add structured logs** |
| "Migration runs in CI only" | CI failures need debugging too. | **Structured logs required** |

## "Feature Complete" Redefinition Prevention

**A feature is NOT complete without observability:**

| What "Complete" Means | Includes Observability? |
|----------------------|------------------------|
| "Code works" | ❌ NO - Only partial |
| "Tests pass" | ❌ NO - Only partial |
| "Ready for review" | ❌ NO - Gate 2 before Gate 4 |
| "Gate 2 passed" | ✅ YES - This is complete |

**If someone says "feature is complete, just needs structured logging":**
- That statement is a contradiction
- Feature is NOT complete
- Gate 2 is PART of completion, not addition to it
- Correct response: "Feature is at Gate 1. Gate 2 (structured logging) required for completion."

**Observability is definition of done, not enhancement.**

## Verification Checklist (MANDATORY)

**Before marking Gate 2 complete, verify ALL:**

| Check | Command | Expected |
|-------|---------|----------|
| Structured logs | `docker-compose logs app \| head -1 \| jq .level` | Returns log level |

**This check MUST pass.**

## Mandatory Requirements

**Gate 2 is NOT OPTIONAL.** Services cannot proceed to production without:

| Requirement | Status | Notes |
|-------------|--------|-------|
| Structured JSON logs | **REQUIRED** | With trace_id correlation |

**Distributed tracing** is optional for standalone workers (no external calls).

## Handling Pushback

**Response:** "Observability is not optional. Without it: no auto-detection of failures, no efficient debugging, no auto-recovery. If time-constrained, reduce FEATURE scope, not observability scope."

## Prerequisites

Before starting Gate 2:

1. **Gate 0 Complete**: Code implementation is done
2. **Gate 1 Complete**: DevOps setup (Dockerfile, docker-compose) is done
3. **Standards**: `docs/PROJECT_RULES.md` (local project) + Ring SRE Standards via WebFetch (`https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/sre.md`)

## Step 1: Analyze Observability Implementation

Review Gate 0/1 handoff: Service type (API/Worker/Batch), Language, External dependencies. Check status of: Health endpoints, Structured logging, Tracing, Dashboard/Alerts (optional).

## Step 2: Dispatch SRE Agent for Validation

**Dispatch:** `Task(subagent_type: "sre")` - VALIDATE observability (not implement). Include service info (type, language, deps) and Gate 0/1 handoff. Agent validates: JSON logging, Tracing. Returns: PASS/FAIL per component, issues by severity.

## Steps 3-5: Validate Health, Logging, Tracing

| Component | Validation Commands | Expected |
|-----------|--------------------|---------:|
| **Logging** | `docker-compose logs app \| head -5 \| jq .` | JSON with timestamp/level/message/service |
| **Tracing** | `docker-compose logs app \| grep trace_id` | trace_id/span_id present |

## Step 6: Prepare Handoff to Gate 3

**Gate 2 Handoff contents:**

| Section | Content |
|---------|---------|
| **Status** | COMPLETE/PARTIAL/NEEDS_FIXES |
| **Validated** | JSON logging ✓, Tracing (if applicable) ✓ |
| **Results** | Logging: PASS/FAIL, Tracing: PASS/FAIL/N/A |
| **Issues** | List by severity (CRITICAL/HIGH/MEDIUM/LOW) or "None" |
| **Ready for Testing** | Logs structured ✓, No Critical/High ✓ |

## Observability by Service Type

| Service Type | Required | Optional |
|--------------|----------|----------|
| **API Service** | Structured logging, Tracing (if calls external services) | — |
| **Background Worker** | Structured logging | Tracing |
| **Batch Job** | Structured logging, Exit code handling | — |

## Execution Report

Base metrics per [shared-patterns/output-execution-report.md](../shared-patterns/output-execution-report.md):

| Metric | Value |
|--------|-------|
| Duration | Xm Ys |
| Iterations | N |
| Result | PASS/FAIL/NEEDS_FIXES |

### Validation Details
- logging_structured: YES/NO
- tracing_enabled: YES/NO/N/A

### Issues Found
- List issues by severity (CRITICAL/HIGH/MEDIUM/LOW) or "None"

### Handoff to Next Gate
- SRE validation status (complete/needs_fixes)
- Observability endpoints validated
- Issues for developers to fix (if any)
- Ready for testing: YES/NO
