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

NOT_skip_when: |
  - "Task says observability not required" → AI cannot self-exempt. ALL services need observability.
  - "Pure frontend" → If it calls ANY API, backend needs observability. Frontend-only = static HTML.
  - "MVP doesn't need observability" → MVP without observability = blind MVP. No exceptions.

sequence:
  after: [dev-devops]
  before: [dev-testing]

related:
  complementary: [dev-cycle, dev-devops, dev-testing]

input_schema:
  required:
    - name: unit_id
      type: string
      description: "Task or subtask identifier being validated"
    - name: language
      type: string
      enum: [go, typescript, python]
      description: "Programming language of the implementation"
    - name: service_type
      type: string
      enum: [api, worker, batch, cli, library]
      description: "Type of service being validated"
    - name: implementation_agent
      type: string
      description: "Agent that performed Gate 0 (e.g., backend-engineer-golang)"
    - name: implementation_files
      type: array
      items: string
      description: "List of files created/modified in Gate 0"
  optional:
    - name: external_dependencies
      type: array
      items: string
      description: "External services called (HTTP, gRPC, queues)"
    - name: gate0_handoff
      type: object
      description: "Summary from Gate 0 implementation"
    - name: gate1_handoff
      type: object
      description: "Summary from Gate 1 DevOps setup"

output_schema:
  format: markdown
  required_sections:
    - name: "Validation Result"
      pattern: "^## Validation Result"
      required: true
    - name: "Instrumentation Coverage"
      pattern: "^## Instrumentation Coverage"
      required: true
    - name: "Issues Found"
      pattern: "^## Issues Found"
      required: true
    - name: "Handoff to Next Gate"
      pattern: "^## Handoff to Next Gate"
      required: true
  metrics:
    - name: result
      type: enum
      values: [PASS, FAIL, NEEDS_FIXES]
    - name: instrumentation_coverage_percent
      type: float
    - name: iterations
      type: integer
    - name: issues_critical
      type: integer
    - name: issues_high
      type: integer
    - name: issues_medium
      type: integer
    - name: issues_low
      type: integer

verification:
  automated:
    - command: "docker-compose logs app 2>&1 | head -5 | jq -e '.level'"
      description: "Logs are JSON structured"
      success_pattern: "info|debug|warn|error"
  manual:
    - "Verify logs include trace_id when tracing is enabled"

examples:
  - name: "API service observability validation"
    input:
      unit_id: "task-001"
      language: "go"
      service_type: "api"
      implementation_agent: "backend-engineer-golang"
      implementation_files: ["internal/handler/user.go", "internal/service/user.go"]
    expected_output: |
      ## Validation Result
      **Status:** PASS
      **Iterations:** 1
      
      ## Instrumentation Coverage
      | Layer | Instrumented | Total | Coverage |
      |-------|--------------|-------|----------|
      | Handlers | 5 | 5 | 100% |
      | Services | 8 | 8 | 100% |
      | Repositories | 4 | 4 | 100% |
      | **TOTAL** | 17 | 17 | **100%** |
      
      ## Issues Found
      None
      
      ## Handoff to Next Gate
      - Ready for Gate 3: YES
---

# SRE Validation (Gate 2)

## Overview

This skill VALIDATES that observability was correctly implemented by developers:
- Structured logging with trace correlation
- OpenTelemetry tracing instrumentation
- Code instrumentation coverage (90%+ required)
- Context propagation for distributed tracing

## CRITICAL: Role Clarification

**Developers IMPLEMENT observability. SRE VALIDATES it.**

| Who | Responsibility |
|-----|----------------|
| **Developers** (Gate 0) | IMPLEMENT observability following Ring Standards |
| **SRE Agent** (Gate 2) | VALIDATE that observability is correctly implemented |
| **Implementation Agent** | FIX issues found by SRE (if any) |

**If observability is missing or incorrect:**
1. SRE reports issues with severity levels
2. This skill dispatches fixes to the implementation agent
3. SRE re-validates after fixes
4. Max 3 iterations, then escalate to user

---

## Step 1: Validate Input

```text
REQUIRED INPUT (from dev-cycle orchestrator):
- unit_id: [task/subtask being validated]
- language: [go|typescript|python]
- service_type: [api|worker|batch|cli|library]
- implementation_agent: [agent that did Gate 0]
- implementation_files: [list of files from Gate 0]

OPTIONAL INPUT:
- external_dependencies: [HTTP clients, gRPC clients, queues]
- gate0_handoff: [summary from Gate 0]
- gate1_handoff: [summary from Gate 1]

IF any REQUIRED input is missing:
  → STOP and report: "Missing required input: [field]"
  → Return to orchestrator with error
```

## Step 2: Initialize Validation State

```text
validation_state = {
  iteration: 1,
  max_iterations: 3,
  sre_result: null,
  issues: [],
  instrumentation_coverage: null
}
```

## Step 3: Dispatch SRE Agent for Validation

```yaml
Task:
  subagent_type: "sre"
  model: "opus"
  description: "Validate observability for [unit_id]"
  prompt: |
    ⛔ VALIDATE Observability Implementation

    ## Input Context
    - **Unit ID:** [unit_id]
    - **Language:** [language]
    - **Service Type:** [service_type]
    - **Implementation Agent:** [implementation_agent]
    - **Files to Validate:** [implementation_files]
    - **External Dependencies:** [external_dependencies or "None"]

    ## Standards Reference
    WebFetch: https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/sre.md

    ## Your Role
    - VALIDATE that observability is implemented correctly
    - Do NOT implement - only verify and report
    - Check structured JSON logging
    - Check OpenTelemetry instrumentation coverage
    - Check context propagation for external calls

    ## Validation Checklist

    ### 1. Structured Logging
    - [ ] JSON format with timestamp, level, message, service
    - [ ] trace_id correlation in logs
    - [ ] No fmt.Println/console.log in production code

    ### 2. Instrumentation Coverage (90%+ required)
    For [language], check these patterns:

    **Go (lib-commons):**
    ```go
    logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)
    ctx, span := tracer.Start(ctx, "layer.operation")
    defer span.End()
    ```

    **TypeScript:**
    ```typescript
    const span = tracer.startSpan('layer.operation');
    try { /* work */ } finally { span.end(); }
    ```

    Count spans in:
    - Handlers: grep "tracer.Start" in *handler*.go or *controller*.ts
    - Services: grep "tracer.Start" in *service*.go or *service*.ts
    - Repositories: grep "tracer.Start" in *repo*.go or *repository*.ts

    ### 3. Context Propagation
    For external calls, verify:
    - HTTP: InjectHTTPContext (Go) or equivalent
    - gRPC: InjectGRPCContext (Go) or equivalent
    - Queues: PrepareQueueHeaders (Go) or equivalent

    ## Required Output Format

    ### Validation Summary
    | Check | Status | Evidence |
    |-------|--------|----------|
    | Structured Logging | ✅/❌ | [file:line or "NOT FOUND"] |
    | Tracing Enabled | ✅/❌ | [file:line or "NOT FOUND"] |
    | Instrumentation ≥90% | ✅/❌ | [X%] |
    | Context Propagation | ✅/❌/N/A | [file:line or "N/A"] |

    ### Instrumentation Coverage Table
    | Layer | Instrumented | Total | Coverage |
    |-------|--------------|-------|----------|
    | Handlers | X | Y | Z% |
    | Services | X | Y | Z% |
    | Repositories | X | Y | Z% |
    | HTTP Clients | X | Y | Z% |
    | gRPC Clients | X | Y | Z% |
    | **TOTAL** | X | Y | **Z%** |

    ### Issues Found (if any)
    For each issue:
    - **Severity:** CRITICAL/HIGH/MEDIUM/LOW
    - **Category:** [Logging|Tracing|Instrumentation|Propagation]
    - **Description:** [what's wrong]
    - **File:** [path:line]
    - **Expected:** [what should exist]
    - **Fix Required By:** [implementation_agent]

    ### Verdict
    - **ALL CHECKS PASSED:** ✅ YES / ❌ NO
    - **Instrumentation Coverage:** [X%]
    - **If NO, blocking issues:** [list]
```

## Step 4: Parse SRE Agent Output

```text
Parse agent output:

1. Extract Validation Summary table
2. Extract Instrumentation Coverage table
3. Extract Issues Found list
4. Extract Verdict

validation_state.sre_result = {
  logging_ok: [true/false],
  tracing_ok: [true/false],
  instrumentation_coverage: [percentage],
  context_propagation_ok: [true/false/na],
  issues: [list of issues],
  verdict: [PASS/FAIL]
}
```

## Step 5: Handle Validation Result

```text
IF validation_state.sre_result.verdict == "PASS" 
   AND validation_state.sre_result.instrumentation_coverage >= 90:
  → Go to Step 8 (Success)

IF validation_state.sre_result.verdict == "FAIL"
   OR validation_state.sre_result.instrumentation_coverage < 90:
  → Go to Step 6 (Dispatch Fix)

IF validation_state.iteration >= validation_state.max_iterations:
  → Go to Step 9 (Escalate)
```

## Step 6: Dispatch Fix to Implementation Agent

```yaml
Task:
  subagent_type: "[implementation_agent from input]"  # e.g., "backend-engineer-golang"
  model: "opus"
  description: "Fix observability issues for [unit_id]"
  prompt: |
    ⛔ FIX REQUIRED - Observability Issues Found

    ## Context
    - **Unit ID:** [unit_id]
    - **Iteration:** [validation_state.iteration] of [validation_state.max_iterations]
    - **Your Previous Implementation:** [implementation_files]

    ## Issues to Fix (from SRE Validation)
    [paste issues from validation_state.sre_result.issues]

    ## Current Instrumentation Coverage
    [paste Instrumentation Coverage table from SRE output]
    **Required:** ≥90%
    **Current:** [validation_state.sre_result.instrumentation_coverage]%

    ## Standards Reference
    For Go: https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang.md
    For TS: https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/typescript.md

    Focus on: Telemetry & Observability section

    ## Required Fixes

    ### If Logging Issues:
    - Replace fmt.Println/console.log with structured logger
    - Add trace_id to log context
    - Use JSON format

    ### If Instrumentation Coverage < 90%:
    - Add spans to ALL handlers: `tracer.Start(ctx, "handler.name")`
    - Add spans to ALL services: `tracer.Start(ctx, "service.domain.operation")`
    - Add spans to ALL repositories: `tracer.Start(ctx, "db.operation")`
    - Add `defer span.End()` after each span creation

    ### If Context Propagation Issues:
    - Add InjectHTTPContext for outgoing HTTP calls
    - Add InjectGRPCContext for outgoing gRPC calls
    - Add PrepareQueueHeaders for queue publishing

    ## Required Output
    - Files modified with fixes
    - New Instrumentation Coverage calculation
    - Confirmation all issues addressed
```

## Step 7: Re-Validate After Fix

```text
validation_state.iteration += 1

IF validation_state.iteration > validation_state.max_iterations:
  → Go to Step 9 (Escalate)

→ Go back to Step 3 (Dispatch SRE Agent)
```

## Step 8: Success - Prepare Output

```text
Generate skill output:

## Validation Result
**Status:** PASS
**Iterations:** [validation_state.iteration]
**Instrumentation Coverage:** [validation_state.sre_result.instrumentation_coverage]%

## Instrumentation Coverage
[paste final Instrumentation Coverage table]

## Issues Found
None (all resolved)

## Handoff to Next Gate
- SRE validation: COMPLETE
- Logging: ✅ Structured JSON with trace_id
- Tracing: ✅ OpenTelemetry instrumented
- Instrumentation: ✅ [X]% coverage
- Ready for Gate 3 (Testing): YES
```

## Step 9: Escalate - Max Iterations Reached

```text
Generate skill output:

## Validation Result
**Status:** FAIL
**Iterations:** [validation_state.iteration] (MAX REACHED)
**Instrumentation Coverage:** [validation_state.sre_result.instrumentation_coverage]%

## Instrumentation Coverage
[paste final Instrumentation Coverage table]

## Issues Found
[list remaining unresolved issues]

## Handoff to Next Gate
- SRE validation: FAILED
- Remaining issues: [count]
- Ready for Gate 3 (Testing): NO
- **Action Required:** User must manually resolve remaining issues

⛔ ESCALATION: Max iterations (3) reached. User intervention required.
```

---

## Severity Calibration

| Severity | Scenario | Gate 2 Status | Action |
|----------|----------|---------------|--------|
| **CRITICAL** | Missing ALL observability (no structured logs) | FAIL | ❌ Return to Gate 0 |
| **CRITICAL** | fmt.Println/echo instead of JSON logs | FAIL | ❌ Return to Gate 0 |
| **CRITICAL** | Instrumentation coverage < 50% | FAIL | ❌ Return to Gate 0 |
| **CRITICAL** | "DEFERRED" appears in validation output | FAIL | ❌ Return to Gate 0 |
| **HIGH** | Instrumentation coverage 50-89% | NEEDS_FIXES | ⚠️ Fix and re-validate |
| **MEDIUM** | Missing context propagation | NEEDS_FIXES | ⚠️ Fix and re-validate |
| **LOW** | Minor logging improvements | PASS | ✅ Note for future |

## Blocker Criteria - STOP and Report

| Decision Type | Examples | Action |
|---------------|----------|--------|
| **HARD BLOCK** | Service lacks JSON structured logs | **STOP** - Dispatch fix to implementation agent |
| **HARD BLOCK** | Instrumentation coverage < 50% | **STOP** - Dispatch fix to implementation agent |
| **HARD BLOCK** | Max iterations reached | **STOP** - Escalate to user |

### Cannot Be Overridden

| Requirement | Cannot Be Waived By | Rationale |
|-------------|---------------------|-----------|
| Gate 2 execution | CTO, PM, "MVP" arguments | Observability prevents production blindness |
| 90% instrumentation coverage | "We'll add spans later" | Later = never. Instrument during implementation. |
| JSON structured logs | "Plain text is enough" | Plain text is unsearchable in production |

## Pressure Resistance

See [shared-patterns/shared-pressure-resistance.md](../shared-patterns/shared-pressure-resistance.md) for universal pressure scenarios.

| User Says | Your Response |
|-----------|---------------|
| "Skip SRE validation" | "Observability is MANDATORY. Dispatching SRE agent now." |
| "90% coverage is too high" | "90% is the Ring Standard minimum. Cannot lower." |
| "Will add instrumentation later" | "Instrumentation is part of implementation. Fix now." |

## Anti-Rationalization Table

See [shared-patterns/shared-anti-rationalization.md](../shared-patterns/shared-anti-rationalization.md) for universal anti-rationalizations.

### Gate 2-Specific Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "OpenTelemetry library is installed" | Installation ≠ Instrumentation | **Verify spans exist in code** |
| "Middleware handles tracing" | Middleware = root span only | **Add child spans in ALL layers** |
| "Small function doesn't need span" | Size is irrelevant | **Add span to EVERY function** |
| "Only external calls need tracing" | Internal ops need tracing too | **Instrument ALL layers** |
| "Feature complete, observability later" | Observability IS completion | **Fix NOW before Gate 3** |

## Component Type Requirements

| Type | JSON Logs | Tracing | Instrumentation |
|------|-----------|---------|-----------------|
| **API Service** | REQUIRED | REQUIRED | 90%+ |
| **Background Worker** | REQUIRED | REQUIRED | 90%+ |
| **CLI Tool** | REQUIRED | N/A | N/A |
| **Library** | N/A | N/A | N/A |

---

## Execution Report Format

```markdown
## Validation Result
**Status:** [PASS|FAIL|NEEDS_FIXES]
**Iterations:** [N]
**Duration:** [Xm Ys]

## Instrumentation Coverage
| Layer | Instrumented | Total | Coverage |
|-------|--------------|-------|----------|
| Handlers | X | Y | Z% |
| Services | X | Y | Z% |
| Repositories | X | Y | Z% |
| HTTP Clients | X | Y | Z% |
| gRPC Clients | X | Y | Z% |
| **TOTAL** | X | Y | **Z%** |

**Coverage Status:** [PASS (≥90%) | NEEDS_FIXES (50-89%) | FAIL (<50%)]

## Issues Found
- [List by severity or "None"]

## Handoff to Next Gate
- SRE validation status: [complete|needs_fixes|failed]
- Instrumentation coverage: [X%]
- Ready for testing: [YES|NO]
```
