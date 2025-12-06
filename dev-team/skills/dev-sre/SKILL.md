---
name: dev-sre
description: |
  Gate 2 of the development cycle. Validates and implements observability requirements
  including metrics, health checks, logging, tracing, and dashboards following SRE standards.

trigger: |
  - Gate 2 of development cycle
  - DevOps setup complete from Gate 1
  - Service needs observability (metrics, logging, tracing)

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
    - command: "curl -sf http://localhost:8080/metrics"
      description: "Metrics endpoint responds"
      success_pattern: "http_requests_total|process_|go_"
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
    - "Verify /metrics includes custom metrics (http_requests_total, etc.)"
    - "Verify /ready returns 503 when database is down"
    - "Verify logs include trace_id when tracing is enabled"

examples:
  - name: "API service observability"
    context: "Go API with PostgreSQL dependency"
    expected_output: |
      - /metrics endpoint with http_requests_total, http_request_duration_seconds
      - /health returns 200 when process running
      - /ready checks database connectivity
      - JSON structured logging with trace correlation
  - name: "Background worker observability"
    context: "Job processor service"
    expected_output: |
      - /metrics with jobs_processed_total, job_duration_seconds
      - /health returns 200 when worker running
      - Queue depth metrics if applicable
---

# SRE Validation (Gate 2)

## Overview

This skill validates and implements observability requirements for the implemented service:
- Prometheus metrics exposed at `/metrics`
- Health check endpoints (`/health`, `/ready`)
- Structured logging with trace correlation
- OpenTelemetry tracing instrumentation
- Grafana dashboard (if required)
- Alert rules (if required)

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

**All of these indicate Gate 2 violation. Implement observability now.**

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

## Step 1: Analyze Observability Requirements

Review implementation and determine what's needed:

```
From Gate 0/1 Handoff:
- Service type: API / Worker / Batch Job
- Language: Go / TypeScript / Python
- External dependencies: {list databases, caches, APIs}

Observability Requirements:
- [ ] Metrics endpoint (/metrics)
- [ ] Health endpoints (/health, /ready)
- [ ] Structured logging
- [ ] Distributed tracing
- [ ] Grafana dashboard
- [ ] Alert rules

Current Status:
- Metrics: EXISTS/MISSING
- Health checks: EXISTS/MISSING
- Logging: STRUCTURED/UNSTRUCTURED/MISSING
- Tracing: EXISTS/MISSING
```

## Step 2: Dispatch SRE Agent

Dispatch `ring-dev-team:sre` for observability implementation:

```
Task tool:
  subagent_type: "ring-dev-team:sre"
  model: "opus"
  prompt: |
    Implement observability for the service.

    ## Service Information
    - Language: {Go/TypeScript/Python}
    - Service type: {API/Worker/Batch}
    - External dependencies: {list}

    ## Implementation Summary
    {paste Gate 0/1 handoff}

    ## Requirements

    ### 1. Metrics (Required)
    Add Prometheus metrics:
    - http_requests_total (counter) - method, endpoint, status
    - http_request_duration_seconds (histogram) - method, endpoint
    - Any business-specific metrics

    Expose at GET /metrics

    ### 2. Health Checks (Required)
    - GET /health - Liveness (process running)
    - GET /ready - Readiness (can serve traffic, checks dependencies)

    ### 3. Structured Logging (Required)
    Ensure all logs are JSON with fields:
    - timestamp, level, message, service, trace_id, span_id

    ### 4. Tracing (If external calls exist)
    Add OpenTelemetry instrumentation:
    - HTTP client calls
    - Database queries
    - Message queue operations

    ### 5. Dashboard (If new service)
    Create Grafana dashboard JSON with:
    - Request rate, error rate, latency
    - Resource usage (CPU, memory)
    - Dependency health

    ## Output
    Report:
    - Files created/modified
    - Metrics added
    - Endpoints added
    - Verification commands
```

## Step 3: Verify Metrics Endpoint

After implementation, verify metrics are exposed:

```bash
# Start service
docker-compose up -d

# Check metrics endpoint
curl http://localhost:8080/metrics

# Expected output should include:
# - http_requests_total
# - http_request_duration_seconds_bucket
# - go_* or nodejs_* or python_* runtime metrics
```

**Verification checklist:**
- [ ] `/metrics` returns 200
- [ ] Custom metrics present (http_requests_total, etc.)
- [ ] Labels are correct (method, endpoint, status)
- [ ] Histograms have appropriate buckets

## Step 4: Verify Health Checks

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

## Step 5: Verify Logging

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

## Step 6: Verify Tracing (If Applicable)

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

## Step 7: Prepare Handoff to Gate 3

Package the following for Gate 3 (Testing):

```markdown
## Gate 2 Handoff

**SRE Status:** COMPLETE/PARTIAL

**Observability Implemented:**
- [ ] Metrics endpoint at /metrics
- [ ] Health endpoint at /health
- [ ] Ready endpoint at /ready
- [ ] Structured JSON logging
- [ ] OpenTelemetry tracing

**Metrics Added:**
- http_requests_total{method,endpoint,status}
- http_request_duration_seconds{method,endpoint}
- {list any custom metrics}

**Files Created/Modified:**
- {list files}

**Verification Results:**
- Metrics: PASS/FAIL
- Health checks: PASS/FAIL
- Logging: PASS/FAIL
- Tracing: PASS/FAIL (or N/A)

**Dashboard Location:** (if created)
- grafana/dashboards/api.json

**Alert Rules Location:** (if created)
- prometheus/rules/api.yml

**Ready for Testing:**
- [ ] All observability endpoints verified
- [ ] Logs are structured
- [ ] No errors in service startup
```

## Observability by Service Type

### API Service
```
Required:
- Metrics (http_requests_total, http_request_duration_seconds)
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
- Metrics (jobs_processed_total, job_duration_seconds, jobs_failed_total)
- Health check (/health)
- Structured logging

Optional:
- Queue depth metrics
- Tracing
```

### Batch Job
```
Required:
- Metrics (batch_runs_total, batch_duration_seconds, batch_items_processed)
- Structured logging
- Exit code handling

Optional:
- Progress metrics
```

## Execution Report

| Metric | Value |
|--------|-------|
| Duration | Xm Ys |
| Iterations | N |
| Result | PASS/FAIL/PARTIAL |

### Details
- metrics_endpoint: VERIFIED/MISSING
- health_endpoint: VERIFIED/MISSING
- ready_endpoint: VERIFIED/MISSING
- logging_structured: YES/NO
- tracing_enabled: YES/NO/N/A
- dashboard_created: YES/NO/N/A
- alerts_created: YES/NO/N/A

### Issues Encountered
- List any issues or "None"

### Handoff to Next Gate
- SRE status (complete/partial)
- Observability endpoints verified
- Files created/modified
- Ready for testing: YES/NO
