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
  - Task explicitly marks observability as not required
  - Pure frontend changes without backend calls

sequence:
  after: [dev-devops]
  before: [dev-testing]

related:
  complementary: [dev-cycle, dev-devops, dev-testing]
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

## Prerequisites

Before starting Gate 2:

1. **Gate 0 Complete**: Code implementation is done
2. **Gate 1 Complete**: DevOps setup (Dockerfile, docker-compose) is done
3. **SRE Standards**: `docs/standards/sre.md` or `dev-team/docs/standards/sre.md`

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
