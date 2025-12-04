---
name: dev-cycle
description: |
  Main orchestrator for the 6-gate development cycle system. Loads tasks/subtasks
  from PM team output and executes through implementation, devops, SRE, testing, review,
  and validation gates with state persistence and metrics collection.

trigger: |
  - Starting a new development cycle with a task file
  - Resuming an interrupted development cycle (--resume flag)
  - Need structured, gate-based task execution with quality checkpoints

skip_when: |
  - Single simple task without quality gates -> execute directly
  - Already in a specific gate skill -> let that gate complete
  - Need to plan tasks first -> use ring-default:writing-plans or ring-pm-team:pre-dev-full

sequence:
  before: [dev-feedback-loop]

related:
  complementary: [dev-implementation, dev-devops, dev-sre, dev-testing, dev-review, dev-validation, dev-feedback-loop]
---

# Development Cycle Orchestrator

## Overview

The development cycle orchestrator loads tasks/subtasks from PM team output (or manual task files) and executes through 6 quality gates. Tasks are loaded at initialization - no separate import gate.

**Announce at start:** "I'm using the dev-cycle skill to orchestrate task execution through 6 gates."

## The 6 Gates

| Gate | Skill | Purpose | Agent |
|------|-------|---------|-------|
| 0 | dev-implementation | Write code following TDD | Based on task language/domain |
| 1 | dev-devops | Infrastructure and deployment | ring-dev-team:devops-engineer |
| 2 | dev-sre | Observability (metrics, health, logging) | ring-dev-team:sre |
| 3 | dev-testing | Unit tests for acceptance criteria | ring-dev-team:qa-analyst |
| 4 | dev-review | Parallel code review | ring-default:*-reviewer (3x parallel) |
| 5 | dev-validation | Final acceptance validation | N/A (verification) |

## Integrated PM → Dev Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                      PM TEAM OUTPUT                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Option A: Tasks only                                           │
│  └─ docs/pre-dev/{feature}/tasks.md                             │
│     ├─ T-001: Task with requirements + acceptance criteria      │
│     ├─ T-002: Task with requirements + acceptance criteria      │
│     └─ T-003: Task with requirements + acceptance criteria      │
│                                                                  │
│  Option B: Tasks + Subtasks                                     │
│  └─ docs/pre-dev/{feature}/                                     │
│     ├─ tasks.md (T-001, T-002, T-003)                          │
│     └─ subtasks/                                                │
│        ├─ T-001/                                                │
│        │  ├─ ST-001-01.md (step-by-step instructions)          │
│        │  ├─ ST-001-02.md                                      │
│        │  └─ ST-001-03.md                                      │
│        ├─ T-002/                                                │
│        │  └─ ST-002-01.md                                      │
│        └─ T-003/                                                │
│           ├─ ST-003-01.md                                      │
│           └─ ST-003-02.md                                      │
│                                                                  │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                   DEV TEAM EXECUTION                             │
│              /ring-dev-team:dev-cycle                            │
└─────────────────────────────────────────────────────────────────┘
```

## Execution Order

### Tasks Only (no subtasks)

```
For each task in order (T-001 → T-002 → T-003):
  Gate 0: Implementation (TDD autonomous)
  Gate 1: DevOps (if needed)
  Gate 2: SRE (observability)
  Gate 3: Testing
  Gate 4: Review (3 parallel)
  Gate 5: Validation
  → Next task
```

### Tasks + Subtasks

```
For each task in order (T-001 → T-002 → T-003):
  │
  ├─ Gate 0: Implementation
  │  │
  │  │  For each subtask in order (ST-001-01 → ST-001-02 → ST-001-03):
  │  │    Execute step-by-step instructions
  │  │    Commit after each subtask
  │  │
  │  └─ All subtasks complete for this task
  │
  ├─ Gate 1: DevOps (if needed)
  ├─ Gate 2: SRE (observability)
  ├─ Gate 3: Testing
  ├─ Gate 4: Review (3 parallel)
  └─ Gate 5: Validation

  → Next task (T-002)
```

## State Management

State is persisted to `.ring/dev-team/current-cycle.json`:

```json
{
  "version": "1.0.0",
  "cycle_id": "uuid",
  "started_at": "ISO timestamp",
  "updated_at": "ISO timestamp",
  "source_file": "path/to/tasks.md",
  "status": "in_progress|completed|failed|paused",
  "current_task_index": 0,
  "current_gate": 0,
  "current_subtask_index": 0,
  "tasks": [
    {
      "id": "T-001",
      "title": "Task title",
      "status": "pending|in_progress|completed|failed|blocked",
      "subtasks": [
        {
          "id": "ST-001-01",
          "file": "subtasks/T-001/ST-001-01.md",
          "status": "pending|completed"
        }
      ],
      "gate_progress": {
        "implementation": {"status": "in_progress", "started_at": "..."},
        "devops": {"status": "pending"},
        "sre": {"status": "pending"},
        "testing": {"status": "pending"},
        "review": {"status": "pending"},
        "validation": {"status": "pending"}
      },
      "artifacts": {}
    }
  ],
  "metrics": {
    "total_duration_ms": 0,
    "gate_durations": {},
    "review_iterations": 0
  }
}
```

## Step 1: Initialize or Resume

### New Cycle (with task file path)

```
Input: path/to/tasks.md OR path/to/pre-dev/{feature}/

1. Detect input type:
   - If file: Load tasks.md directly
   - If directory: Load tasks.md + discover subtasks/

2. Build execution order:
   a. Read tasks from tasks.md (ordered by appearance)
   b. For each task, check for subtasks directory:
      - If exists: Load subtask files in order (ST-XXX-01, 02, 03...)
      - If not: Task will use TDD autonomous mode

3. Initialize state:
   - Generate cycle_id (UUID)
   - Create .ring/dev-team/current-cycle.json
   - Populate tasks array with subtask references
   - Set current_task_index = 0
   - Set current_gate = 0
   - Set current_subtask_index = 0

4. Display execution plan:
   "Loaded X tasks with Y total subtasks:
   - T-001: 3 subtasks
   - T-002: 1 subtask
   - T-003: 2 subtasks (TDD autonomous)

   Starting execution..."

5. Proceed to Gate 0 for first task
```

### Resume Cycle (with --resume flag)

```
Input: --resume

1. Load .ring/dev-team/current-cycle.json
2. Validate state file exists and is valid
3. Display resume summary:
   - Cycle started: [timestamp]
   - Tasks: [completed]/[total]
   - Current task: [id] - [title]
   - Current subtask: [id] (if applicable)
   - Current gate: [gate_name]
4. Ask user to confirm resume
5. Continue from current position
```

## Input Validation

Task files are generated by `/ring-pm-team:pre-dev-*` or `/ring-dev-team:dev-refactor`, which handle content validation. The dev-cycle performs basic format checks:

### Format Checks

| Check | Validation | Action |
|-------|------------|--------|
| File exists | Task file path is readable | Error: abort |
| Task headers | At least one `## Task:` found | Error: abort |
| Task ID format | `## Task: {ID} - {Title}` | Warning: use line number as ID |
| Acceptance criteria | At least one `- [ ]` per task | Warning: task may fail validation gate |

## Step 2: Gate 0 - Implementation (Per Task)

**REQUIRED SUB-SKILL:** Use ring-dev-team:dev-implementation

### With Subtasks

```
For current task with subtasks:

1. Record gate start timestamp
2. Determine agent based on task content (same logic as without subtasks)

3. For each subtask in order:
   a. Read subtask file (ST-XXX-NN.md)
   b. Dispatch agent with subtask instructions:
      Task tool:
        subagent_type: "[selected_agent]"
        prompt: |
          Execute subtask: [subtask_id]

          Follow these step-by-step instructions exactly:
          [subtask file content]

          Commit after completing this subtask.
          Report: files changed, tests run, results.

   c. Update state:
      - Mark subtask as completed
      - Increment current_subtask_index

   d. Continue to next subtask

4. When all subtasks complete:
   - gate_progress.implementation.status = "completed"
   - Reset current_subtask_index = 0
   - Proceed to Gate 1
```

### Without Subtasks (TDD Autonomous)

```
For current task without subtasks:

1. Record gate start timestamp
2. Determine appropriate agent based on task content:
   - Go files/go.mod → ring-dev-team:backend-engineer-golang
   - TypeScript backend → ring-dev-team:backend-engineer-typescript
   - Python → ring-dev-team:backend-engineer-python
   - React/Frontend → ring-dev-team:frontend-engineer-typescript
   - Infrastructure → ring-dev-team:devops-engineer
   - Generic → ring-dev-team:backend-engineer

3. Dispatch to selected agent:
   Task tool:
     subagent_type: "[selected_agent]"
     prompt: |
       Implement task: [task_id] - [title]

       Functional Requirements:
       [functional_requirements]

       Technical Requirements:
       [technical_requirements]

       Acceptance Criteria:
       [acceptance_criteria]

       Follow TDD methodology (ring-default:test-driven-development):
       1. Write failing test
       2. Run test (verify RED)
       3. Implement minimal code
       4. Run test (verify GREEN)
       5. Refactor if needed
       6. Commit

       Report: files changed, tests written, test results.

4. Receive: Implementation report
5. Update state:
   - gate_progress.implementation.status = "completed"
   - artifacts.implementation = {files_changed, commit_sha}
6. Proceed to Gate 1
```

## Step 3: Gate 1 - DevOps (Per Task)

**REQUIRED SUB-SKILL:** Use ring-dev-team:dev-devops

```
For current task:

1. Record gate start timestamp
2. Check if task requires DevOps work:
   - Infrastructure changes?
   - New service deployment?
   - CI/CD updates?

3. If DevOps needed:
   Task tool:
     subagent_type: "ring-dev-team:devops-engineer"
     prompt: |
       Review and update infrastructure for: [task_id]

       Implementation changes:
       [implementation_artifacts]

       Check:
       - Dockerfile updates needed?
       - K8s manifests needed?
       - CI/CD pipeline updates?
       - Environment variables?

       Report: changes made, deployment notes.

4. If DevOps not needed:
   - Mark as "skipped" with reason

5. Update state and proceed to Gate 2
```

## Step 4: Gate 2 - SRE (Per Task)

**REQUIRED SUB-SKILL:** Use ring-dev-team:dev-sre

```
For current task:

1. Record gate start timestamp
2. Check if task requires SRE observability:
   - New service or API?
   - External dependencies added?
   - Performance-critical changes?

3. If SRE needed:
   Task tool:
     subagent_type: "ring-dev-team:sre"
     prompt: |
       Implement observability for: [task_id]

       Service Information:
       - Language: [Go/TypeScript/Python]
       - Service type: [API/Worker/Batch]
       - External dependencies: [list]

       Requirements:
       - Prometheus metrics at /metrics
       - Health endpoints (/health, /ready)
       - Structured JSON logging
       - OpenTelemetry tracing (if external calls)

       Report: files created, metrics added, endpoints verified.

4. If SRE not needed:
   - Mark as "skipped" with reason

5. Update state and proceed to Gate 3
```

## Step 5: Gate 3 - Testing (Per Task)

**REQUIRED SUB-SKILL:** Use ring-dev-team:dev-testing

```
For current task:

1. Record gate start timestamp
2. Dispatch QA analyst:
   Task tool:
     subagent_type: "ring-dev-team:qa-analyst"
     prompt: |
       Create and run tests for: [task_id] - [title]

       Acceptance Criteria:
       [acceptance_criteria]

       Implementation:
       [implementation_artifacts]

       Write:
       - Integration tests
       - E2E tests (if applicable)

       Run all tests.
       Report: test coverage, test results, any failures.

3. Receive: Test report
4. If tests fail:
   - Log failure
   - Loop back to Gate 0 (Implementation) with failure details
   - Increment metrics.review_iterations
5. If tests pass:
   - Update state
   - Proceed to Gate 4
```

## Step 6: Gate 4 - Review (Per Task)

**REQUIRED SUB-SKILL:** Use ring-default:requesting-code-review

```
For current task:

1. Record gate start timestamp
2. Dispatch all 3 reviewers in parallel (single message, 3 Task calls):

   Task tool #1:
     subagent_type: "ring-default:code-reviewer"
     model: "opus"
     prompt: |
       Review implementation for: [task_id]
       BASE_SHA: [pre-implementation commit]
       HEAD_SHA: [current commit]
       REQUIREMENTS: [task requirements]

   Task tool #2:
     subagent_type: "ring-default:business-logic-reviewer"
     model: "opus"
     prompt: [same structure]

   Task tool #3:
     subagent_type: "ring-default:security-reviewer"
     model: "opus"
     prompt: [same structure]

3. Wait for all reviewers to complete
4. Aggregate findings by severity:
   - Critical/High/Medium: Must fix
   - Low: Add TODO(review): comment
   - Cosmetic: Add FIXME(nitpick): comment

5. If Critical/High/Medium issues found:
   - Dispatch fix to implementation agent
   - Re-run all 3 reviewers in parallel
   - Increment metrics.review_iterations
   - Repeat until clean (max 3 iterations)

6. When all issues resolved:
   - Update state
   - Proceed to Gate 5
```

## Step 7: Gate 5 - Validation (Per Task)

```
For current task:

1. Record gate start timestamp
2. Verify acceptance criteria:
   For each criterion in acceptance_criteria:
     - Check if implemented
     - Check if tested
     - Mark as PASS/FAIL

3. Run final verification:
   - All tests pass?
   - No Critical/High/Medium review issues?
   - All acceptance criteria met?

4. If validation passes:
   - Set task status = "completed"
   - Move to next task (current_task_index++)
   - Reset current_gate = 0

5. If validation fails:
   - Log failure reasons
   - Determine which gate to revisit
   - Loop back to appropriate gate

6. Record gate end timestamp
```

## Step 8: Cycle Completion

```
When all tasks completed:

1. Calculate final metrics:
   - total_duration_ms
   - Average gate durations
   - Total review iterations
   - Pass/fail ratio per gate

2. Update state:
   - status = "completed"
   - completed_at = timestamp

3. Generate cycle report:
   | Task | Subtasks | Duration | Review Iterations | Status |
   |------|----------|----------|-------------------|--------|
   | T-001 | 3 | 45m | 2 | PASS |
   | T-002 | 1 | 32m | 1 | PASS |
   | T-003 | 0 (TDD) | 28m | 0 | PASS |

4. **REQUIRED:** Invoke dev-feedback-loop skill for metrics tracking

5. Report to user:
   "Development cycle completed.
   Tasks: X/X completed
   Subtasks executed: Y
   Total time: Xh Xm
   Review iterations: X

   See detailed report in state file."
```

## Quick Commands

```bash
# Full PM workflow then dev execution
/ring-pm-team:pre-dev-full my-feature
/ring-dev-team:dev-cycle docs/pre-dev/my-feature/

# Simple PM workflow then dev execution
/ring-pm-team:pre-dev-feature my-feature
/ring-dev-team:dev-cycle docs/pre-dev/my-feature/tasks.md

# Manual task file
/ring-dev-team:dev-cycle docs/tasks/sprint-001.md

# Resume interrupted cycle
/ring-dev-team:dev-cycle --resume
```

## Error Recovery

### Recoverable Errors
- Network timeouts: Retry with exponential backoff
- Agent failure: Retry once, then pause for user
- Test flakiness: Re-run tests up to 2 times

### Non-Recoverable Errors
- Missing required files: Stop and report
- Invalid state file: Cannot resume, must restart
- Max review iterations exceeded: Pause for user

### Recovery Actions
```
On any error:
1. Update state with error details
2. Set appropriate status (failed/paused)
3. Save state immediately
4. Report to user with:
   - What failed
   - Why it failed
   - How to recover
   - Command to resume when ready
```

## Execution Report

| Metric | Value |
|--------|-------|
| Duration | Xh Xm Ys |
| Tasks Processed | N/M |
| Current Gate | Gate X - [name] |
| Review Iterations | N |
| Result | PASS/FAIL/IN_PROGRESS |

### Gate Timings
| Gate | Duration | Status |
|------|----------|--------|
| Implementation | Xm Ys | in_progress |
| DevOps | - | pending |
| SRE | - | pending |
| Testing | - | pending |
| Review | - | pending |
| Validation | - | pending |

### State File Location
`.ring/dev-team/current-cycle.json`
