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
