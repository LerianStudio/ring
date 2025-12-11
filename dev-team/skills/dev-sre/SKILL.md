---
name: dev-sre
description: |
  Gate 2 of the development cycle. VALIDATES that observability was correctly implemented
  by developers. Does NOT implement observability code - only validates it.

trigger: |
  - Gate 2 of development cycle
  - Gate 0 (Implementation) complete with observability code
  - Gate 1 (DevOps) setup complete
  - Service needs observability validation (metrics, logging, tracing)

skip_when: |
  - No service implementation (documentation only)

NOT_skip_when: |
  - "Task says observability not required" → AI cannot self-exempt. ALL services need observability.
  - "Pure frontend" → If it calls ANY API, backend needs observability. Frontend-only = static HTML.
  - "MVP doesn't need metrics" → MVP without metrics = blind MVP. No exceptions.

sequence:
  after: [ring-dev-team:dev-devops]
  before: [ring-dev-team:dev-testing]

related:
  complementary: [ring-dev-team:dev-cycle, ring-dev-team:dev-devops, ring-dev-team:dev-testing]

verification:
  automated:
    - command: "curl -sf http://localhost:8080/health"
      description: "Health endpoint responds 200"
      success_pattern: "200|ok|healthy"
    - command: "curl -sf http://localhost:8080/ready"
      description: "Ready endpoint responds"
      success_pattern: "200|ready"
    - command: "docker-compose logs app 2>&1 | head -5 | jq -e '.level'"
      description: "Logs are JSON structured"
      success_pattern: "info|debug|warn|error"
  manual:
    - "Verify /ready returns 503 when database is down"
    - "Verify logs include trace_id when tracing is enabled"

examples:
  - name: "API service observability validation"
    context: "Go API with PostgreSQL dependency"
    expected_output: |
      - /health returns 200 when process running
      - /ready checks database connectivity
      - JSON structured logging with trace correlation
  - name: "Background worker observability validation"
    context: "Job processor service"
    expected_output: |
      - /health returns 200 when worker running
      - Structured JSON logging
---

## Standards Loading (MANDATORY)

**Before ANY SRE validation, you MUST load Ring SRE standards:**

See [CLAUDE.md](../../../CLAUDE.md#agent-modification-verification-mandatory) and [dev-team/docs/standards/sre.md](../../docs/standards/sre.md) for canonical requirements. This section summarizes the loading process.

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
| Sections Extracted | Health Endpoints, Metrics, Logging, Tracing |
```

**CANNOT proceed without successful standards loading.**


# SRE Validation (Gate 2)

## Overview

This skill VALIDATES that observability was correctly implemented by developers:
- Prometheus metrics exposed at `/metrics`
- Health check endpoints (`/health`, `/ready`)
- Structured logging with trace correlation
- OpenTelemetry tracing instrumentation
- Grafana dashboard (if required)
- Alert rules (if required)

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

| Decision Type | Scenario | Action | Can User Override? |
|---------------|----------|--------|-------------------|
| **HARD BLOCK** | Service lacks /health + /ready + /metrics + JSON logs | STOP. Return to Gate 0. Cannot proceed to Gate 3. | ❌ NO |
| **HARD BLOCK** | Verification commands not run (no evidence) | STOP. Cannot mark Gate 2 complete without automated verification. | ❌ NO |
| **HARD BLOCK** | User says "feature complete, add observability later" | STOP. Observability is part of completion. Gate 2 required. | ❌ NO |
| **HIGH** | Only /health exists, missing /ready or /metrics | Report HIGH severity. Return to developers. | ❌ NO |
| **MEDIUM** | Logs are fmt.Println/echo, not JSON structured | Report MEDIUM severity. Must fix before Gate 3. | ❌ NO |

## Cannot Be Overridden

**These requirements are NON-NEGOTIABLE and cannot be waived by:**

| Requirement | Cannot Be Waived By | Rationale |
|-------------|---------------------|-----------|
| Gate 2 execution | CTO, PM, "MVP" arguments | Observability prevents production blindness |
| Automated verification | "Developer confirms it works" | Evidence required for Gate 2 PASS |
| /health + /ready + /metrics + JSON logs | "Health is enough" | Minimum viable observability - ALL 4 required |
| "Complete" includes observability | Deadline pressure | Definition of done is non-negotiable |

**If pressured:** "Observability is PART of completion, not an addition to it. Gate 2 cannot be skipped regardless of authority or deadline."

## Severity Calibration

| Severity | Scenario | Gate 2 Status | Can Proceed? |
|----------|----------|---------------|--------------|
| **CRITICAL** | Missing ALL observability (no /health, /ready, /metrics, logs) | FAIL | ❌ Return to Gate 0 |
| **CRITICAL** | fmt.Println/echo instead of JSON logs | FAIL | ❌ Return to Gate 0 |
| **CRITICAL** | Verification commands not run | FAIL | ❌ Cannot mark complete |
| **HIGH** | Missing 1-2 of required endpoints (/ready or /metrics) | NEEDS_FIXES | ❌ Return to developers |
| **MEDIUM** | /ready returns 200 when dependencies down | NEEDS_FIXES | ⚠️ Fix before Gate 3 |
| **LOW** | Dashboard deferred for non-critical service | PARTIAL | ✅ Can proceed with note |

## Pressure Resistance

**Gate 2 (SRE/Observability) is MANDATORY before production. Pressure scenarios and required responses:**

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| **Later** | "Add observability post-launch" | "No observability = no visibility into production issues. REQUIRED before deploy." |
| **Logs Only** | "Logs are enough for MVP" | "Logs show what happened. Metrics show it's happening. Health enables recovery. All required." |
| **Optional** | "Health checks are optional" | "Without health checks, Kubernetes can't detect failures. REQUIRED." |
| **MVP** | "It's just MVP, skip metrics" | "MVP without metrics = blind MVP. You won't know if it's working." |

## Combined Pressure Scenarios

| Pressure Combination | Request | Agent Response |
|---------------------|---------|----------------|
| **Time + Authority + Sunk Cost** | "Tech lead says ship Friday, 8 hours invested, add observability Monday" | "Gate 2 is NON-NEGOTIABLE. Authority cannot waive gates. Reduce FEATURE scope, not observability scope." |
| **Pragmatic + Exhaustion + Time** | "MVP launch in 2 hours, PM says observability optional, just launch" | "MVP without observability = blind MVP. Cannot detect failures, cannot debug efficiently. Gate 2 REQUIRED." |
| **All Pressures** | "CEO watching demo in 1 hour, just show feature working, skip gates" | "Gates prevent production blindness. CEO will want metrics when issues occur. Cannot skip Gate 2." |

**Non-negotiable principle:** Minimum viable observability = metrics + health checks + structured logs. No exceptions.

## Common Rationalizations - REJECTED

| Excuse | Reality |
|--------|---------|
| "Add metrics later" | Later = never. Retrofitting is 10x harder. |
| "Logs are sufficient" | Logs are forensic. Metrics are preventive. Both required. |
| "Health checks are optional" | Without /health, you can't detect service death. Required. |
| "It's just an internal tool" | Internal tools fail too. Observability required. |
| "Dashboard can come later" | Dashboard is optional. Metrics endpoint is not. |
| "Too much overhead for MVP" | Observability is minimal overhead, maximum value. |
| "Task says observability not needed" | AI cannot self-exempt. Tasks don't override gates. |
| "Pure frontend, no backend calls" | If it calls ANY API, backend needs observability. Frontend-only = static HTML. |
| "It's just MVP" | MVP without metrics = blind MVP. You won't know if it's working. |
| "YAGNI - we don't need it yet" | YAGNI doesn't apply to observability. You need it BEFORE problems occur. |
| "Only N users, no need for metrics" | User count is irrelevant. 1 user with silent failure = bad experience. |
| "Basic fmt.Println logs are enough" | fmt.Println is not structured, not searchable, not alertable. JSON logs required. |
| "Single server, no Kubernetes" | /health is for ANY environment. Load balancers, systemd, monitoring all need it. |
| "Just /health is enough for now" | /health + /ready + /metrics is the MINIMUM. Partial observability = partial blindness. |
| "45 min overhead not worth it" | 45 min now prevents 4+ hours debugging blind production issues. |
| "Feature complete, observability later" | Feature without observability is NOT complete. Redefine "complete". |
| "Core functionality works" | Core functionality + observability = complete. Core alone = partial. |
| "Observability is enhancement, not feature" | Observability is REQUIREMENT, not enhancement. It's part of definition of done. |

## Red Flags - STOP

If you catch yourself thinking ANY of these, STOP immediately:

- "We'll add observability after launch"
- "Logs are enough for now"
- "Health checks aren't critical for MVP"
- "Metrics add too much overhead"
- "It's just an internal service"
- "We can monitor manually"
- "Task says observability not required"
- "Pure frontend, no backend impact"
- "It's just MVP, we'll add metrics later"
- "YAGNI - don't need it yet"
- "Only N users, doesn't justify"
- "fmt.Println is fine for now"
- "Single server doesn't need /ready"
- "Just /health endpoint is enough"
- "45 min not worth it"
- "Feature complete, add observability later"
- "Core functionality done"
- "Observability is enhancement"

**All of these indicate Gate 2 violation. Return to developers to implement observability.**

## Component Type Decision Tree

**Not all code is a service. Use this tree to determine observability requirements:**

```plaintext
Is it runnable code?
├── NO (library/package) → No observability required
│   └── Libraries are consumed by services that have observability
│
└── YES → Does it expose HTTP/gRPC/TCP endpoints?
    ├── YES (API Service) → FULL OBSERVABILITY REQUIRED
    │   └── /health + /ready + /metrics + structured logs + tracing
    │
    └── NO → Does it run continuously?
        ├── YES (Background Worker) → WORKER OBSERVABILITY
        │   └── /health + structured logs + tracing
        │
        └── NO (Script/Job) → SCRIPT OBSERVABILITY
            └── Structured logs + exit codes + optional /health
```

### Component Type Requirements

| Type | /health | /ready | /metrics | JSON Logs | Tracing | Exit Codes |
|------|---------|--------|----------|-----------|---------|------------|
| **API Service** | REQUIRED | REQUIRED | REQUIRED | REQUIRED | Recommended | N/A |
| **Background Worker** | REQUIRED | Optional | Recommended | REQUIRED | Optional | N/A |
| **CLI Tool** | Optional | N/A | N/A | REQUIRED | N/A | REQUIRED |
| **One-time Script** | N/A | N/A | N/A | REQUIRED | N/A | REQUIRED |
| **Library** | N/A | N/A | N/A | N/A | N/A | N/A |

### Migration Scripts and One-Time Jobs

**Migration scripts still need observability, but different kind:**

| Requirement | Why | Example |
|-------------|-----|---------|
| **Structured logs** | Track progress, debug failures | `{"level":"info","step":"migrate_users","count":1500}` |
| **Exit codes** | Orchestration needs success/failure signal | `exit 0` success, `exit 1` failure |
| **Idempotency logging** | Know if re-run is safe | `{"already_migrated":true,"skipping":true}` |
| **/health (optional)** | Only if long-running (>5min) | For orchestrator health checks |

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Core functionality works, observability is enhancement" | Observability is PART of definition of done, not addition to it. Feature is NOT complete. | **STOP. Return to Gate 0. Gate 2 is REQUIRED.** |
| "It's just MVP, add metrics Monday" | MVP without metrics = blind MVP. "Later" = never. Retrofitting is 10x harder. | **STOP. Implement /metrics before Gate 2.** |
| "Tech lead approved skipping Gate 2" | Gates are NON-NEGOTIABLE. Authority cannot waive mandatory gates. | **STOP. Inform user gates cannot be waived.** |
| "Health endpoint exists, that's enough" | Minimum = /health + /ready + /metrics + JSON logs. Partial = Gate 2 FAIL. | **STOP. Implement all 4 requirements.** |
| "Developer confirms it works" | Confirmation ≠ Verification. MUST run automated validation commands. | **STOP. Run verification checklist.** |
| "It's just a script, runs once" | Scripts fail. Logs tell you why. | **Add structured logging** |
| "Library doesn't need observability" | Correct! Libraries are exempt. | **Verify it's truly a library** |
| "Worker is simple, no /health" | Simple workers crash silently. | **Add /health endpoint** |
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

**If someone says "feature is complete, just needs observability":**
- That statement is a contradiction
- Feature is NOT complete
- Gate 2 is PART of completion, not addition to it
- Correct response: "Feature is at Gate 1. Gate 2 (observability) required for completion."

**Observability is definition of done, not enhancement.**

## Verification Checklist (MANDATORY)

**Before marking Gate 2 complete, verify ALL:**

| Check | Command | Expected |
|-------|---------|----------|
| Health endpoint | `curl -sf http://localhost:8080/health` | 200 OK |
| Metrics endpoint | `curl -sf http://localhost:8080/metrics` | Contains `http_requests_total` |
| Ready endpoint | `curl -sf http://localhost:8080/ready` | 200 OK |
| Structured logs | `docker-compose logs app \| head -1 \| jq .level` | Returns log level |

**All 4 checks MUST pass. Partial = Gate 2 FAIL.**

## Mandatory Requirements

**Gate 2 is NOT OPTIONAL.** Services cannot proceed to production without:

| Requirement | Status | Notes |
|-------------|--------|-------|
| `/metrics` endpoint | **REQUIRED** | Prometheus-compatible metrics |
| `/health` endpoint | **REQUIRED** | Returns 200 when healthy |
| `/ready` endpoint | **REQUIRED** | Returns 200 when ready for traffic |
| Structured JSON logs | **REQUIRED** | With trace_id correlation |
| Grafana dashboard | Recommended | Can defer for non-critical services |
| Alert rules | Recommended | Required if service has SLO |

**Can be deferred with explicit approval:**
- Grafana dashboard (if service non-critical)
- Alert rules (if no SLOs defined yet)
- Distributed tracing (for standalone workers only)

## Handling Pushback

**Response:** "Observability is not optional. Without it: no auto-detection of failures, no SLO measurement, no efficient debugging, no auto-recovery. If time-constrained, reduce FEATURE scope, not observability scope."

## Prerequisites

Before starting Gate 2:

1. **Gate 0 Complete**: Code implementation is done
2. **Gate 1 Complete**: DevOps setup (Dockerfile, docker-compose) is done
3. **Standards**: `docs/PROJECT_RULES.md` (local project) + Ring SRE Standards via WebFetch (`https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/sre.md`)

## Step 1: Analyze Observability Implementation

Review Gate 0/1 handoff: Service type (API/Worker/Batch), Language, External dependencies. Check status of: Health endpoints, Structured logging, Tracing, Dashboard/Alerts (optional).

## Step 2: Dispatch SRE Agent for Validation

**Dispatch:** `Task(subagent_type: "ring-dev-team:sre")` - VALIDATE observability (not implement). Include service info (type, language, deps) and Gate 0/1 handoff. Agent validates: Health endpoints, JSON logging, Tracing. Returns: PASS/FAIL per component, issues by severity.

## Steps 3-5: Validate Health, Logging, Tracing

| Component | Validation Commands | Expected |
|-----------|--------------------|---------:|
| **Health** | `curl localhost:8080/health` | 200 OK |
| **Ready** | `curl localhost:8080/ready` | 200 OK (with dep status) |
| **Ready (dep down)** | `docker-compose stop db && curl localhost:8080/ready` | 503 |
| **Logging** | `docker-compose logs app \| head -5 \| jq .` | JSON with timestamp/level/message/service |
| **Tracing** | `docker-compose logs app \| grep trace_id` | trace_id/span_id present |

## Step 6: Prepare Handoff to Gate 3

**Gate 2 Handoff contents:**

| Section | Content |
|---------|---------|
| **Status** | COMPLETE/PARTIAL/NEEDS_FIXES |
| **Validated** | /health ✓, /ready ✓, JSON logging ✓, Tracing (if applicable) ✓ |
| **Results** | Health: PASS/FAIL, Logging: PASS/FAIL, Tracing: PASS/FAIL/N/A |
| **Issues** | List by severity (CRITICAL/HIGH/MEDIUM/LOW) or "None" |
| **Ready for Testing** | All endpoints validated ✓, Logs structured ✓, No Critical/High ✓ |

## Observability by Service Type

| Service Type | Required | Optional |
|--------------|----------|----------|
| **API Service** | Health checks (/health, /ready), Structured logging, Tracing (if calls external services) | Grafana dashboard, Alert rules |
| **Background Worker** | Health check (/health), Structured logging | Tracing |
| **Batch Job** | Structured logging, Exit code handling | — |

## Execution Report

| Metric | Value |
|--------|-------|
| Duration | Xm Ys |
| Iterations | N |
| Result | PASS/FAIL/NEEDS_FIXES |

### Validation Details
- health_endpoint: VERIFIED/MISSING
- ready_endpoint: VERIFIED/MISSING
- logging_structured: YES/NO
- tracing_enabled: YES/NO/N/A

### Issues Found
- List issues by severity (CRITICAL/HIGH/MEDIUM/LOW) or "None"

### Handoff to Next Gate
- SRE validation status (complete/needs_fixes)
- Observability endpoints validated
- Issues for developers to fix (if any)
- Ready for testing: YES/NO
