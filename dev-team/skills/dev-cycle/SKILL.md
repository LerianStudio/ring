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
  - Already in a specific gate skill -> let that gate complete
  - Need to plan tasks first -> use ring-default:writing-plans or ring-pm-team:pre-dev-full
  - Human explicitly requests manual implementation (non-AI workflow)

NOT_skip_when: |
  - "Task is simple" → Simple ≠ risk-free. Execute gates.
  - "Tests already pass" → Tests ≠ review. Different concerns.
  - "Time pressure" → Pressure ≠ permission. Document and proceed.
  - "Already did N gates" → Sunk cost is irrelevant. Complete all gates.

sequence:
  before: [ring-dev-team:dev-feedback-loop]

related:
  complementary: [ring-dev-team:dev-implementation, ring-dev-team:dev-devops, ring-dev-team:dev-sre, ring-dev-team:dev-testing, ring-dev-team:dev-review, ring-dev-team:dev-validation, ring-dev-team:dev-feedback-loop]

verification:
  automated:
    - command: "test -f .ring/dev-team/state/cycle-state.json"
      description: "State file exists"
      success_pattern: "exit 0"
    - command: "cat .ring/dev-team/state/cycle-state.json | jq '.current_gate'"
      description: "Current gate is valid"
      success_pattern: "[0-5]"
  manual:
    - "All gates for current task show PASS in state file"
    - "No tasks have status 'blocked' for more than 3 iterations"

examples:
  - name: "New feature from PM workflow"
    invocation: "/ring-dev-team:dev-cycle docs/pre-dev/auth/tasks.md"
    expected_flow: |
      1. Load tasks with subtasks from tasks.md
      2. Ask user for checkpoint mode (per-task/per-gate/continuous)
      3. Execute Gate 0-5 for each task sequentially
      4. Generate feedback report after completion
  - name: "Resume interrupted cycle"
    invocation: "/ring-dev-team:dev-cycle --resume"
    expected_state: "Continues from last saved gate in cycle-state.json"
  - name: "Execute with per-gate checkpoints"
    invocation: "/ring-dev-team:dev-cycle tasks.md --checkpoint per-gate"
    expected_flow: |
      1. Execute Gate 0, pause for approval
      2. User approves, execute Gate 1, pause
      3. Continue until all gates complete
---

# Development Cycle Orchestrator

## Overview

The development cycle orchestrator loads tasks/subtasks from PM team output (or manual task files) and executes through 6 quality gates. Tasks are loaded at initialization - no separate import gate.

**Announce at start:** "I'm using the dev-cycle skill to orchestrate task execution through 6 gates."

## Pressure Resistance

**This skill enforces MANDATORY gates. Pressure scenarios and required responses:**

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| **Time** | "Production down, skip gates" | "Gates prevent production issues. Automatic mode = 20 min. Skipping gates increases risk." |
| **Sunk Cost** | "Already did 4 gates, skip review" | "Each gate catches different issues. Prior gates don't reduce review value. Review = 10 min." |
| **Authority** | "Director override, ship now" | "Cannot skip GATES based on authority. Can skip CHECKPOINTS (automatic mode). Gates are non-negotiable." |
| **Simplicity** | "Simple fix, skip gates" | "Simple tasks have complex impacts. AI doesn't negotiate. ALL tasks require ALL gates. No exceptions." |

**Non-negotiable principle:** Execution mode selection affects CHECKPOINTS (user approval pauses), not GATES (quality checks). ALL gates execute regardless of mode.

## Common Rationalizations - REJECTED

| Excuse | Reality |
|--------|---------|
| "Task is simple, skip gates" | Simple tasks have complex impacts. Gates catch what you don't see. |
| "Already passed N gates" | Each gate catches different issues. Sunk cost is irrelevant. |
| "Manager approved skipping" | Authority cannot override quality gates. Document the pressure. |
| "Tests pass, skip review" | Tests verify code works. Review verifies code is correct, secure, maintainable. |
| "Automatic mode means faster" | Automatic mode skips CHECKPOINTS, not GATES. Same quality, less interruption. |
| "We'll fix issues post-merge" | Post-merge fixes are 10x more expensive. Gates exist to prevent this. |

## Red Flags - STOP

If you catch yourself thinking ANY of these, STOP immediately:

- "This task is too simple for gates"
- "We already passed most gates"
- "Manager/Director said to skip"
- "Tests pass, review is redundant"
- "We can fix issues later"
- "Automatic mode will handle it"
- "Just this once won't hurt"

**All of these indicate you're about to violate mandatory workflow. Return to gate execution.**

## The 6 Gates

| Gate | Skill | Purpose | Agent |
|------|-------|---------|-------|
| 0 | dev-implementation | Write code following TDD | Based on task language/domain |
| 1 | dev-devops | Infrastructure and deployment | ring-dev-team:devops-engineer |
| 2 | dev-sre | Observability (metrics, health, logging) | ring-dev-team:sre |
| 3 | dev-testing | Unit tests for acceptance criteria | ring-dev-team:qa-analyst |
| 4 | dev-review | Parallel code review | ring-default:code-reviewer, ring-default:business-logic-reviewer, ring-default:security-reviewer (3x parallel) |
| 5 | dev-validation | Final acceptance validation | N/A (verification) |

## Integrated PM → Dev Workflow

```text
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

### Core Principle: One Unit = All 6 Gates

Each execution unit (task OR subtask) passes through **all 6 gates** before moving to the next unit.

### Tasks Only (no subtasks)

```text
For each task in order (T-001 → T-002 → T-003):
  Gate 0: Implementation (TDD)
  Gate 1: DevOps (if needed)
  Gate 2: SRE (observability)
  Gate 3: Testing
  Gate 4: Review (3 parallel)
  Gate 5: Validation
  ──────────────────────────────────
  🔒 CHECKPOINT: Unit Approval (Step 7.1)      [if manual_per_subtask]
     - Present completion summary
     - Wait for: Continue / Test First / Stop
  ──────────────────────────────────
  🔒 CHECKPOINT: Task Approval (Step 7.2)      [if manual_per_subtask OR manual_per_task]
     - Present task summary
     - Wait for: Continue / Integration Test / Stop
  ──────────────────────────────────
  → Next task

  [automatic mode: no checkpoints, continuous execution]
```

### Tasks with Subtasks

When a task has subtasks, **each subtask is an execution unit**:

```text
T-001 (has 3 subtasks):
  │
  ├─ ST-001-01:
  │    Gate 0: Implementation
  │    Gate 1: DevOps (if needed)
  │    Gate 2: SRE (if needed)
  │    Gate 3: Testing
  │    Gate 4: Review (3 parallel)
  │    Gate 5: Validation
  │    ──────────────────────────────────
  │    🔒 CHECKPOINT: Unit Approval       [if manual_per_subtask]
  │    ──────────────────────────────────
  │    ✓ Subtask complete
  │
  ├─ ST-001-02:
  │    Gate 0 → Gate 5 (same as above)
  │    ──────────────────────────────────
  │    🔒 CHECKPOINT: Unit Approval       [if manual_per_subtask]
  │    ──────────────────────────────────
  │    ✓ Subtask complete
  │
  └─ ST-001-03:
       Gate 0 → Gate 5 (same as above)
       ──────────────────────────────────
       🔒 CHECKPOINT: Unit Approval       [if manual_per_subtask]
       ──────────────────────────────────
       ✓ Subtask complete

  ══════════════════════════════════════
  🔒 CHECKPOINT: Task Approval (Step 7.2) [if manual_per_subtask OR manual_per_task]
     - Present full task summary
     - Wait for: Continue / Integration Test / Stop
  ══════════════════════════════════════
  ✓ T-001 complete

T-002 (no subtasks → task is execution unit):
  Gate 0 → Gate 5
  ──────────────────────────────────
  🔒 CHECKPOINT: Unit Approval            [if manual_per_subtask]
  🔒 CHECKPOINT: Task Approval            [if manual_per_subtask OR manual_per_task]
  ──────────────────────────────────
  ✓ T-002 complete

→ Next task...

EXECUTION MODES SUMMARY:
┌────────────────────┬─────────────────────┬───────────────────┐
│ Mode               │ Step 7.1 (unit)     │ Step 7.2 (task)   │
├────────────────────┼─────────────────────┼───────────────────┤
│ manual_per_subtask │ ✓ Every unit        │ ✓ Every task      │
│ manual_per_task    │ ✗ Skip              │ ✓ Every task      │
│ automatic          │ ✗ Skip              │ ✗ Skip            │
└────────────────────┴─────────────────────┴───────────────────┘
```

### Execution Unit Definition

| Scenario | Execution Unit | Gates Per Unit |
|----------|----------------|----------------|
| Task without subtasks | Task itself | 6 gates |
| Task with subtasks | Each subtask | 6 gates per subtask |

## State Management

State is persisted to `.ring/dev-team/current-cycle.json`:

```json
{
  "version": "1.0.0",
  "cycle_id": "uuid",
  "started_at": "ISO timestamp",
  "updated_at": "ISO timestamp",
  "source_file": "path/to/tasks.md",
  "execution_mode": "manual_per_subtask|manual_per_task|automatic",
  "status": "in_progress|completed|failed|paused|paused_for_approval|paused_for_testing|paused_for_task_approval|paused_for_integration_testing",
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

## Step 0: Verify PROJECT_RULES.md Exists (HARD GATE)

**This step is NON-NEGOTIABLE. Cycle CANNOT proceed without project standards.**

Before initializing or resuming any cycle, verify that project standards exist:

```text
Check sequence:
1. Check: docs/PROJECT_RULES.md
2. Check: docs/STANDARDS.md (legacy name)
3. If --resume: Check state file references a valid standards path

Decision:
├── Found → Proceed to Step 1
└── NOT Found → STOP with blocker
```

**If PROJECT_RULES.md is missing:**

```yaml
# STOP - Do not proceed. Report blocker:
Blocker:
  type: "missing_prerequisite"
  message: |
    Cannot start development cycle without project standards.

    REQUIRED: docs/PROJECT_RULES.md must exist.

    Why is this mandatory?
    - Agents need standards to follow during implementation
    - Code review validates against YOUR standards, not generic ones
    - TDD tests must verify YOUR requirements, not assumptions
```

**Pressure Resistance for Step 0:**

| Pressure | Response |
|----------|----------|
| "Standards slow us down" | "No standards = no target. Agents will guess. Guessing = rework." |
| "Use defaults" | "Defaults are generic. YOUR project has specific conventions." |
| "Create standards later" | "Later = after implementation = refactoring. Define now." |

---

## Step 1: Initialize or Resume

### New Cycle (with task file path)

```text
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
   - T-003: 2 subtasks (TDD autonomous)"

5. **ASK EXECUTION MODE using AskUserQuestion tool:**

   Question: "How would you like to control the development cycle?"
   Options:
     a) "Manual (per subtask)" - Approve after each subtask before continuing
     b) "Manual (per task)" - Approve only after complete tasks (not individual subtasks)
     c) "Automatic" - Run all tasks without interruptions

   Store selection in state as `execution_mode`:
     - "manual_per_subtask" → Checkpoint after every subtask (Step 7.1) + after every task (Step 7.2)
     - "manual_per_task" → Checkpoint only after tasks complete (Step 7.2 only)
     - "automatic" → No checkpoints, continuous execution

   **MANDATORY - Do NOT skip this step:**
   - Do NOT infer mode from user hints ("run quickly", "trivial tasks", "simple fixes")
   - Do NOT skip the question to save time - it takes 5 seconds
   - User comments about speed are CONTEXT, not mode selection
   - Only EXPLICIT selection (a/b/c) from AskUserQuestion is valid
   - "Simple task" is NOT an excuse to skip mode selection

6. Confirm and start:
   - Display selected mode
   - Output: "Starting development cycle in [mode] mode..."
   - Proceed to Gate 0 for first task
```

### Resume Cycle (with --resume flag)

```text
Input: --resume

1. Load .ring/dev-team/current-cycle.json
2. Validate state file exists and is valid
3. Display resume summary:
   - Cycle started: [timestamp]
   - Tasks: [completed]/[total]
   - Current task: [id] - [title]
   - Current subtask: [id] (if applicable)
   - Current gate: [gate_name]
   - Paused reason: [status explanation]

4. Handle paused states:

   If status = "paused_for_approval":
     - Display: "Paused waiting for unit approval after [unit_id]"
     - Re-present Step 7.1 checkpoint (unit summary + approval question)

   If status = "paused_for_testing":
     - Display: "Paused for manual testing of unit [unit_id]"
     - Ask: "Have you finished testing? Ready to continue?"
     - If yes: Proceed to next unit (or Step 7.2 if last unit)
     - If no: Keep paused

   If status = "paused_for_task_approval":
     - Display: "Paused waiting for task approval after [task_id]"
     - Re-present Step 7.2 checkpoint (task summary + approval question)

   If status = "paused_for_integration_testing":
     - Display: "Paused for integration testing of task [task_id]"
     - Ask: "Have you finished integration testing? Ready to continue?"
     - If yes: Proceed to next task
     - If no: Keep paused

   If status = "paused" (generic):
     - Display: "Cycle manually paused"
     - Ask user to confirm resume
     - Continue from current position

   If status = "in_progress":
     - Display: "Cycle was interrupted mid-execution"
     - Resume from current gate of current execution unit

5. Continue from appropriate position based on status
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

## Step 2: Gate 0 - Implementation (Per Execution Unit)

**REQUIRED SUB-SKILL:** Use ring-dev-team:dev-implementation

**Execution Unit:** Task (if no subtasks) OR Subtask (if task has subtasks)

```text
For current execution unit:

1. Record gate start timestamp

2. Determine appropriate agent based on content:
   - Go files/go.mod → ring-dev-team:backend-engineer-golang
   - TypeScript backend → ring-dev-team:backend-engineer-typescript
   - React/Frontend → ring-dev-team:frontend-engineer-typescript
   - Infrastructure → ring-dev-team:devops-engineer

3. Dispatch to selected agent:
   Task tool:
     subagent_type: "[selected_agent]"
     prompt: |
       Implement: [unit_id] - [title]

       Requirements:
       [requirements from task/subtask file]

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

## Step 3: Gate 1 - DevOps (Per Execution Unit)

**REQUIRED SUB-SKILL:** Use ring-dev-team:dev-devops

```text
For current execution unit:

1. Record gate start timestamp
2. Check if unit requires DevOps work:
   - Infrastructure changes?
   - New service deployment?
   - CI/CD updates?

3. If DevOps needed:
   Task tool:
     subagent_type: "ring-dev-team:devops-engineer"
     prompt: |
       Review and update infrastructure for: [unit_id]

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

## Step 4: Gate 2 - SRE (Per Execution Unit)

**REQUIRED SUB-SKILL:** Use ring-dev-team:dev-sre

```text
For current execution unit:

1. Record gate start timestamp
2. Check if unit requires SRE observability:
   - New service or API?
   - External dependencies added?
   - Performance-critical changes?

3. If SRE needed:
   Task tool:
     subagent_type: "ring-dev-team:sre"
     prompt: |
       Implement observability for: [unit_id]

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

## Step 5: Gate 3 - Testing (Per Execution Unit)

**REQUIRED SUB-SKILL:** Use ring-dev-team:dev-testing

```text
For current execution unit:

1. Record gate start timestamp
2. Dispatch QA analyst:
   Task tool:
     subagent_type: "ring-dev-team:qa-analyst"
     prompt: |
       Create and run tests for: [unit_id] - [title]

       Acceptance Criteria:
       [acceptance_criteria]

       Implementation:
       [implementation_artifacts]

       Write:
       - Unit tests (coverage ≥ 80%)
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

## Step 6: Gate 4 - Review (Per Execution Unit)

**REQUIRED SUB-SKILL:** Use ring-default:requesting-code-review

```text
For current execution unit:

1. Record gate start timestamp
2. Dispatch all 3 reviewers in parallel (single message, 3 Task calls):

   Task tool #1:
     subagent_type: "ring-default:code-reviewer"
     model: "opus"
     prompt: |
       Review implementation for: [unit_id]
       BASE_SHA: [pre-implementation commit]
       HEAD_SHA: [current commit]
       REQUIREMENTS: [unit requirements]

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

## Step 7: Gate 5 - Validation (Per Execution Unit)

```text
For current execution unit:

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

4. If validation fails:
   - Log failure reasons
   - Determine which gate to revisit
   - Loop back to appropriate gate

5. If validation passes:
   - Set unit status = "completed"
   - Record gate end timestamp
   - Proceed to Step 7.1 (Execution Unit Approval)
```

## Step 7.1: Execution Unit Approval (Conditional)

**This checkpoint depends on `execution_mode`:**
- `manual_per_subtask` → Execute this checkpoint (approve each execution unit)
- `manual_per_task` → Skip (proceed directly to next unit, or Step 7.2 if last unit)
- `automatic` → Skip entirely

```text
After Gate 5 validation passes:

0. Check execution_mode from state:
   - If "automatic": Skip to next execution unit (no checkpoint)
   - If "manual_per_task": Skip to next unit (or Step 7.2 if last unit)
   - If "manual_per_subtask": Continue with checkpoint below

1. Set status = "paused_for_approval"
2. Save state immediately (allow resume if session interrupted)

3. Present completion summary to user:
   ┌─────────────────────────────────────────────────┐
   │ ✓ EXECUTION UNIT COMPLETED                      │
   ├─────────────────────────────────────────────────┤
   │ Unit: [unit_id] - [title]                       │
   │ Parent Task: [task_id] - [task_title]           │
   │                                                  │
   │ Gates Passed:                                    │
   │   ✓ Gate 0: Implementation                      │
   │   ✓ Gate 1: DevOps                              │
   │   ✓ Gate 2: SRE                                 │
   │   ✓ Gate 3: Testing                             │
   │   ✓ Gate 4: Review                              │
   │   ✓ Gate 5: Validation                          │
   │                                                  │
   │ Acceptance Criteria: X/X passed                 │
   │ Review Iterations: N                            │
   │ Duration: Xm Ys                                 │
   │                                                  │
   │ Files Changed:                                  │
   │   - file1.go                                    │
   │   - file2_test.go                               │
   │   - ...                                         │
   │                                                  │
   │ Next: [next_unit_id] - [next_title]             │
   │       OR "Last unit - proceed to task approval" │
   └─────────────────────────────────────────────────┘

4. **ASK FOR EXPLICIT APPROVAL using AskUserQuestion tool:**

   Question: "Ready to proceed to the next execution unit?"
   Options:
     a) "Continue" - Proceed to next unit
     b) "Test First" - Manually test this unit before continuing
     c) "Stop Here" - Pause cycle (can resume later with --resume)

5. Handle user response:

   If "Continue":
     - Set status = "in_progress"
     - Check if more units in current task
     - If yes: Move to next unit, reset to Gate 0
     - If no: Proceed to Step 7.2 (Task Approval Checkpoint)

   If "Test First":
     - Set status = "paused_for_testing"
     - Save state
     - Output: "Cycle paused. Test unit [unit_id] and run:
                /ring-dev-team:dev-cycle --resume
                when ready to continue."
     - STOP execution (do not proceed)

   If "Stop Here":
     - Set status = "paused"
     - Save state
     - Output: "Cycle paused at unit [unit_id]. Resume with:
                /ring-dev-team:dev-cycle --resume"
     - STOP execution (do not proceed)
```

## Step 7.2: Task Approval Checkpoint (Conditional)

**This checkpoint depends on `execution_mode`:**
- `manual_per_subtask` → Execute this checkpoint
- `manual_per_task` → Execute this checkpoint
- `automatic` → Skip entirely (proceed to next task)

**When all subtasks of a task are completed**, require human approval before moving to the next task (unless automatic mode).

```text
After completing all subtasks of a task:

0. Check execution_mode from state:
   - If "automatic": Skip to next task (no checkpoint)
   - If "manual_per_subtask" OR "manual_per_task": Continue with checkpoint below

1. Set task status = "completed"
2. Set cycle status = "paused_for_task_approval"
3. Save state

4. Present task completion summary:
   ┌─────────────────────────────────────────────────┐
   │ ✓ TASK COMPLETED                                │
   ├─────────────────────────────────────────────────┤
   │ Task: [task_id] - [task_title]                  │
   │                                                  │
   │ Subtasks Completed: X/X                         │
   │   ✓ ST-001-01: [title]                          │
   │   ✓ ST-001-02: [title]                          │
   │   ✓ ST-001-03: [title]                          │
   │                                                  │
   │ Total Duration: Xh Xm                           │
   │ Total Review Iterations: N                      │
   │                                                  │
   │ All Files Changed This Task:                    │
   │   - file1.go                                    │
   │   - file2.go                                    │
   │   - ...                                         │
   │                                                  │
   │ Next Task: [next_task_id] - [next_task_title]   │
   │            Subtasks: N (or "TDD autonomous")    │
   │            OR "No more tasks - cycle complete"  │
   └─────────────────────────────────────────────────┘

5. **ASK FOR EXPLICIT APPROVAL using AskUserQuestion tool:**

   Question: "Task [task_id] complete. Ready to start the next task?"
   Options:
     a) "Continue" - Proceed to next task
     b) "Integration Test" - User wants to test the full task integration
     c) "Stop Here" - Pause cycle

6. Handle user response:

   If "Continue":
     - Set status = "in_progress"
     - Move to next task
     - Set current_task_index += 1
     - Set current_subtask_index = 0
     - Reset to Gate 0
     - Continue execution

   If "Integration Test":
     - Set status = "paused_for_integration_testing"
     - Save state
     - Output: "Cycle paused for integration testing.
                Test task [task_id] integration and run:
                /ring-dev-team:dev-cycle --resume
                when ready to continue."
     - STOP execution

   If "Stop Here":
     - Set status = "paused"
     - Save state
     - Output: "Cycle paused after task [task_id]. Resume with:
                /ring-dev-team:dev-cycle --resume"
     - STOP execution
```

**Note:** For tasks without subtasks, the task itself is the execution unit, so both Step 7.1 (unit approval) and Step 7.2 (task approval) are executed in sequence.

## Step 8: Cycle Completion

```text
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
```text
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
