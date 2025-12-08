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

## Pressure Resistance

**Gate 2 (SRE/Observability) is MANDATORY before production. Pressure scenarios and required responses:**

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| **Later** | "Add observability post-launch" | "No observability = no visibility into production issues. REQUIRED before deploy." |
| **Logs Only** | "Logs are enough for MVP" | "Logs show what happened. Metrics show it's happening. Health enables recovery. All required." |
| **Optional** | "Health checks are optional" | "Without health checks, Kubernetes can't detect failures. REQUIRED." |
| **MVP** | "It's just MVP, skip metrics" | "MVP without metrics = blind MVP. You won't know if it's working." |

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

When user or stakeholder pushes back on observability:

**Response template:**
"Observability is not optional for production services. Without it:
- We cannot detect failures automatically
- We cannot measure SLO compliance
- We cannot debug production issues efficiently
- We cannot enable auto-recovery

If time-constrained, reduce FEATURE scope, not observability scope."

## Prerequisites

Before starting Gate 2:

1. **Gate 0 Complete**: Code implementation is done
2. **Gate 1 Complete**: DevOps setup (Dockerfile, docker-compose) is done
3. **Standards**: `docs/PROJECT_RULES.md` (local project) + Ring SRE Standards via WebFetch (`https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/sre.md`)

## Step 1: Analyze Observability Implementation

Review what developers implemented in Gate 0 and validate:

```
From Gate 0/1 Handoff:
- Service type: API / Worker / Batch Job
- Language: Go / TypeScript / Python
- External dependencies: {list databases, caches, APIs}

Observability to Validate:
- [ ] Health endpoints (/health, /ready)
- [ ] Structured logging
- [ ] Distributed tracing (if external calls exist)
- [ ] Grafana dashboard (optional)
- [ ] Alert rules (optional)

Current Status (from Gate 0 implementation):
- Health checks: EXISTS/MISSING
- Logging: STRUCTURED/UNSTRUCTURED/MISSING
- Tracing: EXISTS/MISSING/N/A
```

## Step 2: Dispatch SRE Agent for Validation

Dispatch `ring-dev-team:sre` to VALIDATE observability implementation:

```
Task tool:
  subagent_type: "ring-dev-team:sre"
  model: "opus"
  prompt: |
    VALIDATE observability implementation for the service.

    **Your role is VALIDATION, not implementation. Developers already implemented observability in Gate 0.**

    ## Service Information
    - Language: {Go/TypeScript/Python}
    - Service type: {API/Worker/Batch}
    - External dependencies: {list}

    ## Implementation Summary from Gate 0/1
    {paste Gate 0/1 handoff - should include observability code already implemented}

    ## Validation Checklist

    ### 1. Health Checks (Required)
    VALIDATE that:
    - GET /health returns 200 when process running
    - GET /ready returns 200 when dependencies are healthy
    - GET /ready returns 503 when dependencies are down

    ### 2. Structured Logging (Required)
    VALIDATE that logs:
    - Are JSON formatted
    - Include: timestamp, level, message, service
    - Include trace_id when tracing enabled
    - Do NOT log sensitive data (passwords, tokens)

    ### 3. Tracing (If external calls exist)
    VALIDATE that:
    - Spans created for HTTP handlers
    - Spans created for database calls
    - Trace context propagated

    ## Output
    Report:
    - Validation results (PASS/FAIL per component)
    - Issues found (with severity: CRITICAL/HIGH/MEDIUM/LOW)
    - Verification commands used
    - Next steps for developers (if issues found)
```

## Step 3: Validate Health Checks

```bash
# Liveness check
curl http://localhost:8080/health
# Expected: 200 OK

# Readiness check
curl http://localhost:8080/ready
# Expected: 200 OK with dependency status

# Readiness when dependency down
docker-compose stop db
curl http://localhost:8080/ready
# Expected: 503 Service Unavailable
```

**Verification checklist:**
- [ ] `/health` returns 200 when process running
- [ ] `/ready` returns 200 when all dependencies up
- [ ] `/ready` returns 503 when dependency down
- [ ] Response includes dependency status details

## Step 4: Validate Logging

```bash
# Check log format
docker-compose logs api | head -5

# Expected JSON format:
# {"timestamp":"2024-01-15T10:30:00Z","level":"info","message":"Request completed",...}
```

**Verification checklist:**
- [ ] Logs are JSON formatted
- [ ] Required fields present: timestamp, level, message, service
- [ ] trace_id/span_id present when tracing enabled
- [ ] No sensitive data logged (passwords, tokens)

## Step 5: Validate Tracing (If Applicable)

```bash
# Make a request that triggers external calls
curl http://localhost:8080/api/users

# Check Jaeger UI (if configured)
# http://localhost:16686

# Or check logs for trace context
docker-compose logs api | grep trace_id
```

**Verification checklist:**
- [ ] Spans created for HTTP handlers
- [ ] Spans created for database calls
- [ ] Spans created for external API calls
- [ ] Trace context propagated across services

## Step 6: Prepare Handoff to Gate 3

Package the following for Gate 3 (Testing):

```markdown
## Gate 2 Handoff

**SRE Validation Status:** COMPLETE/PARTIAL/NEEDS_FIXES

**Observability Validated:**
- [ ] Health endpoint at /health
- [ ] Ready endpoint at /ready
- [ ] Structured JSON logging
- [ ] OpenTelemetry tracing (if applicable)

**Validation Results:**
- Health checks: PASS/FAIL
- Logging: PASS/FAIL
- Tracing: PASS/FAIL (or N/A)

**Issues Found:**
- {list issues by severity: CRITICAL/HIGH/MEDIUM/LOW}
- Or "None"

**Ready for Testing:**
- [ ] All observability endpoints validated
- [ ] Logs are structured
- [ ] No critical/high issues remaining
```

## Observability by Service Type

### API Service
```
Required:
- Health checks (/health, /ready)
- Structured logging
- Tracing (if calls external services)

Optional:
- Grafana dashboard
- Alert rules
```

### Background Worker
```
Required:
- Health check (/health)
- Structured logging

Optional:
- Tracing
```

### Batch Job
```
Required:
- Structured logging
- Exit code handling
```

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
