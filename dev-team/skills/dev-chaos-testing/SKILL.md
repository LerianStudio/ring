---
name: ring:dev-chaos-testing
description: |
  Gate 7 of development cycle - ensures chaos tests exist using Toxiproxy
  to verify graceful degradation under connection loss, latency, and partitions.
  Runs at TASK cadence (after all subtasks complete Gate 0 + Gate 3 + Gate 9):
  write mode runs per task, execute mode runs per cycle.

trigger: |
  - After integration testing complete (Gate 6)
  - MANDATORY for all development tasks with external dependencies
  - Verifies system behavior under failure conditions

skip_when: |
  - Not inside a development cycle (ring:dev-cycle)
  - Service has no external dependencies (no database, cache, queue, or external API)
  - Task is documentation-only, configuration-only, or non-code
  - Frontend-only project with no backend service dependencies

NOT_skip_when: |
  - "Infrastructure is reliable" - All infrastructure fails eventually. Be prepared.
  - "Integration tests cover failures" - Integration tests verify happy path. Chaos verifies failures.
  - "Toxiproxy is complex" - One container, 20 minutes setup. Prevents production incidents.

sequence:
  after: [ring:dev-integration-testing]
  before: [ring:codereview]

related:
  complementary: [ring:dev-cycle, ring:dev-integration-testing, ring:qa-analyst]

input_schema:
  required:
    - name: unit_id
      type: string
      description: "TASK identifier (not a subtask id). This skill's write mode runs at TASK cadence — unit_id is always a task id. Execute mode runs per cycle."
    - name: external_dependencies
      type: array
      items: string
      description: "External services (postgres, redis, rabbitmq, etc.)"
    - name: language
      type: string
      enum: [go, typescript]
      description: "Programming language"
    - name: implementation_files
      type: array
      items: string
      description: "Union of changed files across all subtasks of this task."
    - name: gate0_handoffs
      type: array
      description: "Array of per-subtask implementation handoffs (one entry per subtask). NOT a single gate0_handoff object."
  optional:
    - name: gate6_handoff
      type: object
      description: "Full handoff from Gate 6 (integration testing)"

output_schema:
  format: markdown
  required_sections:
    - name: "Chaos Testing Summary"
      pattern: "^## Chaos Testing Summary"
      required: true
    - name: "Failure Scenarios"
      pattern: "^## Failure Scenarios"
      required: true
    - name: "Handoff to Next Gate"
      pattern: "^## Handoff to Next Gate"
      required: true
  metrics:
    - name: result
      type: enum
      values: [PASS, FAIL]
    - name: dependencies_tested
      type: integer
    - name: scenarios_tested
      type: integer
    - name: recovery_verified
      type: boolean
    - name: iterations
      type: integer

verification:
  automated:
    - command: "grep -rn 'TestIntegration_Chaos_' --include='*_test.go' ."
      description: "Chaos test functions exist"
      success_pattern: "TestIntegration_Chaos_"
    - command: "grep -rn 'CHAOS.*1' --include='*_test.go' ."
      description: "CHAOS env check present"
      success_pattern: "CHAOS"
  manual:
    - "Chaos tests follow TestIntegration_Chaos_{Component}_{Scenario} naming"
    - "All external dependencies have failure scenarios"
    - "Recovery verified after each failure injection"

---

# Dev Chaos Testing (Gate 7)

## Overview

Ensure code handles **failure conditions gracefully** by injecting faults using Toxiproxy. Verify connection loss, latency, and network partitions don't cause crashes.

**Core principle:** All infrastructure fails. Chaos testing ensures your code handles it gracefully.

<block_condition>
- No chaos tests = FAIL
- Any dependency without failure test = FAIL
- Recovery not verified = FAIL
- System crashes on failure = FAIL
</block_condition>

## CRITICAL: Role Clarification

**This skill ORCHESTRATES. QA Analyst Agent (chaos mode) EXECUTES.**

| Who | Responsibility |
|-----|----------------|
| **This Skill** | Gather requirements, dispatch agent, track iterations |
| **QA Analyst Agent** | Write chaos tests, setup Toxiproxy, verify recovery |

---

## Standards Source (Cache-First Pattern)

**Standards Source (Cache-First Pattern):** This sub-skill reads standards from `state.cached_standards` populated by dev-cycle Step 1.5. If invoked outside a cycle (standalone), it falls back to direct WebFetch with a warning. See `shared-patterns/standards-cache-protocol.md` for protocol details.

## Standards Reference

**MANDATORY:** Load testing-chaos.md standards via the cache-first pattern below.

URL: https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/testing-chaos.md

**Cache-first loading protocol:**
For each required standards URL:
  IF state.cached_standards[url] exists:
    → Read content from state.cached_standards[url].content
    → Log: "Using cached standard: {url} (fetched {state.cached_standards[url].fetched_at})"
  ELSE:
    → WebFetch url (fallback — should not happen if orchestrator ran Step 1.5)
    → Log warning: "Standard {url} was not pre-cached; fetched inline"

<fetch_required>
https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/testing-chaos.md
</fetch_required>

---

## Step 0: Detect External Dependencies (Auto-Detection)

**MANDATORY:** When `external_dependencies` is empty or not provided, scan the codebase to detect them automatically before validation.

```text
if external_dependencies is empty or not provided:

  detected_dependencies = []

  1. Scan docker-compose.yml / docker-compose.yaml for service images:
     - Grep tool: pattern "postgres" in docker-compose* files → add "postgres"
     - Grep tool: pattern "mongo" in docker-compose* files → add "mongodb"
     - Grep tool: pattern "valkey" in docker-compose* files → add "valkey"
     - Grep tool: pattern "redis" in docker-compose* files → add "redis"
     - Grep tool: pattern "rabbitmq" in docker-compose* files → add "rabbitmq"

  2. Scan dependency manifests:
     if language == "go":
       - Grep tool: pattern "github.com/lib/pq" in go.mod → add "postgres"
       - Grep tool: pattern "github.com/jackc/pgx" in go.mod → add "postgres"
       - Grep tool: pattern "go.mongodb.org/mongo-driver" in go.mod → add "mongodb"
       - Grep tool: pattern "github.com/redis/go-redis" in go.mod → add "redis"
       - Grep tool: pattern "github.com/valkey-io/valkey-go" in go.mod → add "valkey"
       - Grep tool: pattern "github.com/rabbitmq/amqp091-go" in go.mod → add "rabbitmq"

     if language == "typescript":
       - Grep tool: pattern "\"pg\"" in package.json → add "postgres"
       - Grep tool: pattern "@prisma/client" in package.json → add "postgres"
       - Grep tool: pattern "\"mongodb\"" in package.json → add "mongodb"
       - Grep tool: pattern "\"mongoose\"" in package.json → add "mongodb"
       - Grep tool: pattern "\"redis\"" in package.json → add "redis"
       - Grep tool: pattern "\"ioredis\"" in package.json → add "redis"
       - Grep tool: pattern "@valkey" in package.json → add "valkey"
       - Grep tool: pattern "\"amqplib\"" in package.json → add "rabbitmq"
       - Grep tool: pattern "amqp-connection-manager" in package.json → add "rabbitmq"

  3. Deduplicate detected_dependencies
  4. Set external_dependencies = detected_dependencies

  Log: "Auto-detected external dependencies: [detected_dependencies]"
```

<auto_detect_reason>
PM team task files often omit external_dependencies. If the codebase uses postgres, mongodb, valkey, or rabbitmq, these are external dependencies that MUST have chaos tests. Auto-detection prevents silent skips.
</auto_detect_reason>

---

## Step 1: Validate Input

```text
REQUIRED INPUT:
- unit_id: [TASK id — write mode runs at task cadence, not per subtask]
- external_dependencies: [postgres, mongodb, valkey, redis, rabbitmq, etc.] (from input OR auto-detected in Step 0)
- language: [go|typescript]
- implementation_files: [union of changed files across all subtasks of this task]
- gate0_handoffs: [array of per-subtask Gate 0 handoffs — one entry per subtask]

OPTIONAL INPUT:
- gate6_handoff: [full Gate 6 output]

if any REQUIRED input is missing:
  → STOP and report: "Missing required input: [field]"

if external_dependencies is empty (AFTER auto-detection in Step 0):
  → STOP and report: "No external dependencies found after codebase scan - chaos testing requires dependencies"
```

## Step 2: Dispatch QA Analyst Agent (Chaos Mode)

```text
Task tool:
  subagent_type: "ring:qa-analyst"
  prompt: |
    **MODE:** CHAOS TESTING (Gate 7)

    **Standards:** Load testing-chaos.md

    **Input:**
    - Unit ID: {unit_id}
    - External Dependencies: {external_dependencies}
    - Language: {language}

    **Requirements:**
    1. Setup Toxiproxy infrastructure in tests/utils/chaos/
    2. Create chaos tests (TestIntegration_Chaos_{Component}_{Scenario} naming)
    3. Use dual-gate pattern (CHAOS=1 env + testing.Short())
    4. Test failure scenarios: Connection Loss, High Latency, Network Partition
    5. Verify 5-phase structure: Normal → Inject → Verify → Restore → Recovery

    **Output Sections Required:**
    - ## Chaos Testing Summary
    - ## Failure Scenarios
    - ## Handoff to Next Gate
```

## Step 3: Evaluate Results

```text
Parse agent output:

if "Status: PASS" in output:
  → Gate 7 PASSED
  → Return success with metrics

if "Status: FAIL" in output:
  → Dispatch fix to implementation agent
  → Re-run chaos tests (max 3 iterations)
  → If still failing: ESCALATE to user
```

## Step 4: Generate Output

```text
## Chaos Testing Summary
**Status:** {PASS|FAIL}
**Dependencies Tested:** {count}
**Scenarios Tested:** {count}
**Recovery Verified:** {Yes|No}

## Failure Scenarios
| Component | Scenario | Status | Recovery |
|-----------|----------|--------|----------|
| {component} | {scenario} | {PASS|FAIL} | {Yes|No} |

## Handoff to Next Gate
- Ready for Gate 8 (Code Review): {YES|NO}
- Iterations: {count}
```

---

## Failure Scenarios by Dependency

| Dependency | Required Scenarios |
|------------|-------------------|
| PostgreSQL | Connection Loss, High Latency, Network Partition |
| MongoDB | Connection Loss, High Latency, Network Partition |
| Valkey | Connection Loss, High Latency, Timeout |
| Redis | Connection Loss, High Latency, Timeout |
| RabbitMQ | Connection Loss, Network Partition, Slow Consumer |
| HTTP APIs | Timeout, 5xx Errors, Connection Refused |

---

## Severity Calibration

| Severity | Criteria | Examples |
|----------|----------|----------|
| **CRITICAL** | System crashes on failure, data loss | Panic on connection loss, corrupted state on partition |
| **HIGH** | No recovery, missing dependency tests | System doesn't recover after failure, untested dependency |
| **MEDIUM** | Partial recovery, missing scenarios | Recovery takes too long, missing latency test |
| **LOW** | Cleanup issues, documentation | Test artifacts not cleaned, missing chaos docs |

Report all severities. CRITICAL = immediate fix (production risk). HIGH = fix before gate pass. MEDIUM = fix in iteration. LOW = document.

---

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Infrastructure is reliable" | AWS, GCP, Azure all have outages. Your code must handle them. | **Write chaos tests** |
| "Integration tests cover failures" | Integration tests verify happy path. Chaos tests verify failure handling. | **Write chaos tests** |
| "Toxiproxy is complex" | One container. 20 minutes setup. Prevents production incidents. | **Write chaos tests** |
| "We have monitoring" | Monitoring detects problems. Chaos testing prevents them. | **Write chaos tests** |
| "Circuit breakers handle it" | Circuit breakers need testing too. Chaos tests verify they work. | **Write chaos tests** |

---
