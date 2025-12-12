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
    - command: "test -f .ring/dev-team/current-cycle.json"
      description: "State file exists"
      success_pattern: "exit 0"
    - command: "cat .ring/dev-team/current-cycle.json | jq '.current_gate'"
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
    expected_state: "Continues from last saved gate in current-cycle.json"
  - name: "Execute with per-gate checkpoints"
    invocation: "/ring-dev-team:dev-cycle tasks.md --checkpoint per-gate"
    expected_flow: |
      1. Execute Gate 0, pause for approval
      2. User approves, execute Gate 1, pause
      3. Continue until all gates complete
---

# Development Cycle Orchestrator

## Standards Loading (MANDATORY)

**Before ANY gate execution, you MUST load Ring standards:**

See [CLAUDE.md](https://raw.githubusercontent.com/LerianStudio/ring/main/CLAUDE.md) as the canonical source. This table summarizes the loading process.

| Parameter | Value |
|-----------|-------|
| url | \`https://raw.githubusercontent.com/LerianStudio/ring/main/CLAUDE.md\` |
| prompt | "Extract Agent Modification Verification requirements, Anti-Rationalization Tables requirements, and Critical Rules" |

**Execute WebFetch before proceeding.** Do NOT continue until standards are loaded.

If WebFetch fails → STOP and report blocker. Cannot proceed without Ring standards.

## Overview

The development cycle orchestrator loads tasks/subtasks from PM team output (or manual task files) and executes through 6 quality gates. Tasks are loaded at initialization - no separate import gate.

**Announce at start:** "I'm using the dev-cycle skill to orchestrate task execution through 6 gates."

## Blocker Criteria - STOP and Report

| Decision Type | Examples | Action |
|---------------|----------|--------|
| **Gate Failure** | Tests not passing, review failed | STOP. Cannot proceed to next gate. |
| **Missing Standards** | No PROJECT_RULES.md | STOP. Report blocker and wait. |
| **Agent Failure** | Specialist agent returned errors | STOP. Diagnose and report. |
| **User Decision Required** | Architecture choice, framework selection | STOP. Present options with trade-offs. |

You CANNOT proceed when blocked. Report and wait for resolution.

### Cannot Be Overridden

| Requirement | Rationale | Consequence If Skipped |
|-------------|-----------|------------------------|
| **All 6 gates must execute** | Each gate catches different issues | Missing critical defects, security vulnerabilities |
| **Gates execute in order (0→5)** | Dependencies exist between gates | Testing untested code, reviewing unobservable systems |
| **Gate 4 requires ALL 3 reviewers** | Different review perspectives are complementary | Missing security issues, business logic flaws |
| **Coverage threshold ≥ 85%** | Industry standard for quality code | Untested edge cases, regression risks |
| **PROJECT_RULES.md must exist** | Cannot verify standards without target | Arbitrary decisions, inconsistent implementations |

## Severity Calibration

| Severity | Criteria | Examples |
|----------|----------|----------|
| **CRITICAL** | Blocks deployment, security risk, data loss | Gate violation, skipped mandatory step |
| **HIGH** | Major functionality broken, standards violation | Missing tests, wrong agent dispatched |
| **MEDIUM** | Code quality, maintainability issues | Incomplete documentation, minor gaps |
| **LOW** | Best practices, optimization | Style improvements, minor refactoring |

Report ALL severities. Let user prioritize.

### Reviewer Verdicts Are Final

**MEDIUM issues found in Gate 4 MUST be fixed. No exceptions.**

| Request | Why It's WRONG | Required Action |
|---------|----------------|-----------------|
| "Can reviewer clarify if MEDIUM can defer?" | Reviewer already decided. MEDIUM means FIX. | **Fix the issue, re-run reviewers** |
| "Ask if this specific case is different" | Reviewer verdict accounts for context already. | **Fix the issue, re-run reviewers** |
| "Request exception for business reasons" | Reviewers know business context. Verdict is final. | **Fix the issue, re-run reviewers** |

**Severity mapping is absolute:**
- CRITICAL/HIGH/MEDIUM → Fix NOW, re-run all 3 reviewers
- LOW → Add TODO(review): comment
- Cosmetic → Add FIXME(nitpick): comment

No negotiation. No exceptions. No "special cases".

**This skill enforces MANDATORY gates. Pressure scenarios and required responses:**

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| **Time** | "Production down, skip gates" | "Gates prevent production issues. Automatic mode = 20 min. Skipping gates increases risk." |
| **Sunk Cost** | "Already did 4 gates, skip review" | "Each gate catches different issues. Prior gates don't reduce review value. Review = 10 min." |
| **Authority** | "Director override, ship now" | "Cannot skip GATES based on authority. Can skip CHECKPOINTS (automatic mode). Gates are non-negotiable." |
| **Simplicity** | "Simple fix, skip gates" | "Simple tasks have complex impacts. AI doesn't negotiate. ALL tasks require ALL gates. No exceptions." |
| **Demo** | "Demo at 9 AM, ship without gates" | "Demos with unverified code = demos that crash. Gates BEFORE demo to ensure success. Automatic mode = 20 min." |
| **Fatigue** | "It's late, exhausted, finish tomorrow" | "Fatigue reduces judgment. This is why gates are automated checklists. Gates prevent fatigue-induced errors." |
| **Economic** | "$XM deal depends on skipping gates" | "Revenue at risk from shipping broken code >> revenue from delayed demo. Gates protect business outcomes." |

**Non-negotiable principle:** Execution mode selection affects CHECKPOINTS (user approval pauses), not GATES (quality checks). ALL gates execute regardless of mode.

## Common Rationalizations - REJECTED

| Excuse | Reality |
|--------|---------|
| "Task is simple, skip gates" | Simple tasks have complex impacts. Gates catch what you don't see. |
| "Already passed N gates" | Each gate catches different issues. Sunk cost is irrelevant. |
| "Manager approved skipping" | Authority cannot override quality gates. Document the pressure. |
| "Tests pass, skip review" | Tests verify code works. Review verifies code is correct, secure, maintainable. |
| "Automatic mode means faster" | Automatic mode skips CHECKPOINTS, not GATES. Same quality, less interruption. |
| "Automatic mode will skip review" | Automatic mode affects user approval pauses, NOT quality gates. ALL gates execute regardless. |
| "We'll fix issues post-merge" | Post-merge fixes are 10x more expensive. Gates exist to prevent this. |
| "Defense in depth exists (frontend validates)" | Frontend can be bypassed. Backend is the last line. Fix at source. |
| "Backlog the Medium issue, it's documented" | Documented risk ≠ mitigated risk. Medium in Gate 4 = fix NOW, not later. |
| "Risk-based prioritization allows deferral" | Gates ARE the risk-based system. Reviewers define severity, not you. |
| "Business context justifies exception" | Business context informed gate design. Gates already account for it. |
| "Demo tomorrow, we'll fix after" | "Fix after" = never-fix. Demo crashes are worse than delayed demos. | **Gates BEFORE demo (automatic mode = 20 min)** |
| "Just this one gate, then catch up" | One skipped gate = precedent. Next gate also "just one". No incremental compromise. |
| "90% done, finish without remaining gates" | 90% done with 0% gates = 0% verified. Gates verify the 90%. |
| "Ship now, gates as fast-follow" | Fast-follow = never-follow. Gates now or not at all. |

## Red Flags - STOP

If you catch yourself thinking ANY of these, STOP immediately:

- "This task is too simple for gates"
- "We already passed most gates"
- "Manager/Director said to skip"
- "Tests pass, review is redundant"
- "We can fix issues later"
- "Automatic mode will handle it"
- "Automatic mode will skip review"
- "Just this once won't hurt"
- "Frontend already validates this"
- "I'll document it in backlog/TODO"
- "Medium severity can wait"
- "Business context is different here"
- "Risk-based approach says defer"
- "Demo tomorrow, fix after"
- "Just this one gate"
- "90% done, almost there"
- "Ship now, gates as fast-follow"

**All of these indicate you're about to violate mandatory workflow. Return to gate execution.**

## Incremental Compromise Prevention

**The "just this once" pattern leads to complete gate erosion:**

```text
Day 1: "Skip review just this once" → Approved (precedent set)
Day 2: "Skip testing, we did it last time" → Approved (precedent extended)
Day 3: "Skip implementation checks, pattern established" → Approved (gates meaningless)
Day 4: Production incident from Day 1 code
```

**Prevention rules:**
1. **No incremental exceptions** - Each exception becomes the new baseline
2. **Document every pressure** - Log who requested, why, outcome
3. **Escalate patterns** - If same pressure repeats, escalate to team lead
4. **Gates are binary** - Complete or incomplete. No "mostly done".

## Gate Completion Definition (HARD GATE)

**A gate is COMPLETE only when ALL components finish successfully:**

| Gate | Components Required | Partial = FAIL |
|------|---------------------|----------------|
| 0 | Implementation agent completes + TDD RED verified | 1 file done ≠ gate done |
| 1 | Dockerfile + docker-compose + .env.example | Missing any = FAIL |
| 2 | /health + /ready + /metrics + structured logs | 3/4 endpoints = FAIL |
| 3 | Coverage ≥ 85% + all AC tested | 84% = FAIL |
| 4 | **ALL 3 reviewers PASS** | 2/3 reviewers = FAIL |
| 5 | Explicit "APPROVED" from user | "Looks good" = NOT approved |

**CRITICAL for Gate 4:** Running 2 of 3 reviewers is NOT a partial pass - it's a FAIL. Re-run ALL 3 reviewers.

**Anti-Rationalization for Partial Gates:**

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "2 of 3 reviewers passed" | Gate 4 requires ALL 3. 2/3 = 0/3. | **Re-run ALL 3 reviewers** |
| "Gate mostly complete" | Mostly ≠ complete. Binary: done or not done. | **Complete ALL components** |
| "Can finish remaining in next cycle" | Gates don't carry over. Complete NOW. | **Finish current gate** |
| "Core components done, optional can wait" | No component is optional within a gate. | **Complete ALL components** |

## Gate Order Enforcement (HARD GATE)

**Gates MUST execute in order: 0 → 1 → 2 → 3 → 4 → 5. No exceptions.**

| Violation | Why It's WRONG | Consequence |
|-----------|----------------|-------------|
| Skip Gate 1 (DevOps) | "No infra changes" | Code without container = works on my machine only |
| Skip Gate 2 (SRE) | "Observability later" | Blind production = debugging nightmare |
| Reorder Gates | "Review before test" | Reviewing untested code wastes reviewer time |
| Parallel Gates | "Run 2 and 3 together" | Dependencies exist. Order is intentional. |

**Gates are NOT parallelizable across different gates. Sequential execution is MANDATORY.**

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

**PM Team Output** → **Dev Team Execution** (`/ring-dev-team:dev-cycle`)

| Input Type | Path | Structure |
|------------|------|-----------|
| **Tasks only** | `docs/pre-dev/{feature}/tasks.md` | T-001, T-002, T-003 with requirements + acceptance criteria |
| **Tasks + Subtasks** | `docs/pre-dev/{feature}/` | tasks.md + `subtasks/{task-id}/ST-XXX-01.md, ST-XXX-02.md...` |

## Execution Order

**Core Principle:** Each execution unit (task OR subtask) passes through **all 6 gates** before the next unit.

**Flow:** Unit → Gate 0-5 → 🔒 Unit Checkpoint (Step 7.1) → 🔒 Task Checkpoint (Step 7.2) → Next Unit

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
      "artifacts": {},
      "agent_outputs": {
        "implementation": {
          "agent": "ring-dev-team:backend-engineer-golang",
          "output": "## Summary\n...",
          "timestamp": "ISO timestamp",
          "duration_ms": 0
        },
        "devops": null,
        "sre": {
          "agent": "ring-dev-team:sre",
          "output": "## Summary\n...",
          "timestamp": "ISO timestamp",
          "duration_ms": 0
        },
        "testing": {
          "agent": "ring-dev-team:qa-analyst",
          "output": "## Summary\n...",
          "verdict": "PASS",
          "coverage_actual": 87.5,
          "coverage_threshold": 85,
          "iteration": 1,
          "timestamp": "ISO timestamp",
          "duration_ms": 0
        },
        "review": {
          "code_reviewer": {"agent": "ring-default:code-reviewer", "output": "...", "timestamp": "..."},
          "business_logic_reviewer": {"agent": "ring-default:business-logic-reviewer", "output": "...", "timestamp": "..."},
          "security_reviewer": {"agent": "ring-default:security-reviewer", "output": "...", "timestamp": "..."}
        },
        "validation": {
          "result": "approved|rejected",
          "timestamp": "ISO timestamp"
        }
      }
    }
  ],
  "metrics": {
    "total_duration_ms": 0,
    "gate_durations": {},
    "review_iterations": 0,
    "testing_iterations": 0
  }
}
```

## Step 0: Verify PROJECT_RULES.md Exists (HARD GATE)

| Mode | Step 7.1 (unit) | Step 7.2 (task) |
|------|-----------------|-----------------|
| `manual_per_subtask` | ✓ Every unit | ✓ Every task |
| `manual_per_task` | ✗ Skip | ✓ Every task |
| `automatic` | ✗ Skip | ✗ Skip |

**Checkpoint Options:** Continue / Test First / Stop (7.1) | Continue / Integration Test / Stop (7.2)

## State Management

State persisted to `.ring/dev-team/current-cycle.json`:

| Field | Type | Values |
|-------|------|--------|
| `execution_mode` | string | `manual_per_subtask` \| `manual_per_task` \| `automatic` |
| `status` | string | `in_progress` \| `completed` \| `failed` \| `paused` \| `paused_for_approval` \| `paused_for_testing` \| `paused_for_task_approval` \| `paused_for_integration_testing` |
| `current_task_index` | int | Current task position |
| `current_gate` | int | 0-5 |
| `tasks[].status` | string | `pending` \| `in_progress` \| `completed` \| `failed` \| `blocked` |
| `tasks[].gate_progress` | object | Status per gate (implementation, devops, sre, testing, review, validation) |
| `metrics` | object | `total_duration_ms`, `gate_durations`, `review_iterations` |

## Step 0: Verify PROJECT_RULES.md Exists (HARD GATE)

**NON-NEGOTIABLE. Cycle CANNOT proceed without project standards.**

**Check:** (1) docs/PROJECT_RULES.md (2) docs/STANDARDS.md (legacy) (3) --resume state file → Found: Proceed | NOT Found: STOP with blocker `missing_prerequisite`

**Pressure Resistance:** "Standards slow us down" → No target = guessing = rework | "Use defaults" → Defaults are generic, YOUR project has specific conventions | "Create later" → Later = refactoring

---

## Step 1: Initialize or Resume

### New Cycle (with task file path)

**Input:** `path/to/tasks.md` OR `path/to/pre-dev/{feature}/`

1. **Detect input:** File → Load directly | Directory → Load tasks.md + discover subtasks/
2. **Build order:** Read tasks, check for subtasks (ST-XXX-01, 02...) or TDD autonomous mode
3. **Initialize state:** Generate cycle_id, create `.ring/dev-team/current-cycle.json`, set indices to 0
4. **Display plan:** "Loaded X tasks with Y subtasks"
5. **ASK EXECUTION MODE (MANDATORY - AskUserQuestion):**
   - Options: (a) Manual per subtask (b) Manual per task (c) Automatic
   - **Do NOT skip:** User hints ≠ mode selection. Only explicit a/b/c is valid.
6. **Start:** Display mode, proceed to Gate 0

### Resume Cycle (--resume flag)

1. Load `.ring/dev-team/current-cycle.json`, validate
2. Display: cycle started, tasks completed/total, current task/subtask/gate, paused reason
3. **Handle paused states:**

| Status | Action |
|--------|--------|
| `paused_for_approval` | Re-present Step 7.1 checkpoint |
| `paused_for_testing` | Ask if testing complete → continue or keep paused |
| `paused_for_task_approval` | Re-present Step 7.2 checkpoint |
| `paused_for_integration_testing` | Ask if integration testing complete |
| `paused` (generic) | Ask user to confirm resume |
| `in_progress` | Resume from current gate |

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
   - agent_outputs.implementation = {
       agent: "[selected_agent]",
       output: "[full agent output for feedback analysis]",
       timestamp: "[ISO timestamp]",
       duration_ms: [execution time]
     }
6. Proceed to Gate 1

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
   - agent_outputs.devops = null

5. If DevOps executed:
   - agent_outputs.devops = {
       agent: "ring-dev-team:devops-engineer",
       output: "[full agent output for feedback analysis]",
       timestamp: "[ISO timestamp]",
       duration_ms: [execution time]
     }

6. Update state and proceed to Gate 2
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
       Validate observability for: [unit_id]

       Service Information:
       - Language: [Go/TypeScript/Python]
       - Service type: [API/Worker/Batch]
       - External dependencies: [list]
       - Implementation from Gate 0: [summary of what was implemented]

       Validation Requirements:
       - Verify /health endpoint responds correctly
       - Verify OpenTelemetry tracing (if external calls)

       Report: validation results with PASS/FAIL for each component (/health, tracing), issues found by severity, verification commands executed.

4. If SRE not needed:
   - Mark as "skipped" with reason
   - agent_outputs.sre = null

5. If SRE executed:
   - agent_outputs.sre = {
       agent: "ring-dev-team:sre",
       output: "[full agent output for feedback analysis]",
       timestamp: "[ISO timestamp]",
       duration_ms: [execution time]
     }

6. Update state and proceed to Gate 3
```

## Step 5: Gate 3 - Testing (Per Execution Unit)

**REQUIRED SUB-SKILL:** Use ring-dev-team:dev-testing

### Simple Flow

```
┌─────────────────────────────────────────────────────────┐
│  QA runs tests → checks coverage against threshold      │
│                                                         │
│  PASS (coverage ≥ threshold) → Proceed to Gate 4       │
│  FAIL (coverage < threshold) → Return to Gate 0        │
│                                                         │
│  Max 3 attempts, then escalate to user                 │
└─────────────────────────────────────────────────────────┘
```

### Threshold

- Default: **85%** (Ring minimum)
- Can be higher if defined in `docs/PROJECT_RULES.md`
- Cannot be lower than 85%

### Execution

```text
1. Dispatch QA analyst with acceptance criteria and threshold
2. QA writes tests, runs them, checks coverage
3. QA returns VERDICT: PASS or FAIL

   PASS → Proceed to Gate 4 (Review)

   FAIL → Return to Gate 0 (Implementation) to add tests
          QA provides: what lines/branches need coverage

4. Track iteration count (state.testing.iteration)
   - Max 3 iterations allowed
   - After 3rd failure: STOP and escalate to user
   - Do NOT attempt 4th iteration automatically
```

### State Tracking

```json
{
  "testing": {
    "verdict": "PASS|FAIL",
    "coverage_actual": 87.5,
    "coverage_threshold": 85,
    "iteration": 1
  }
}
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
4. Store all reviewer outputs:
   - agent_outputs.review = {
       code_reviewer: {
         agent: "ring-default:code-reviewer",
         output: "[full output for feedback analysis]",
         timestamp: "[ISO timestamp]"
       },
       business_logic_reviewer: {
         agent: "ring-default:business-logic-reviewer",
         output: "[full output for feedback analysis]",
         timestamp: "[ISO timestamp]"
       },
       security_reviewer: {
         agent: "ring-default:security-reviewer",
         output: "[full output for feedback analysis]",
         timestamp: "[ISO timestamp]"
       }
     }
5. Aggregate findings by severity:
   - Critical/High/Medium: Must fix
   - Low: Add TODO(review): comment
   - Cosmetic: Add FIXME(nitpick): comment

6. If Critical/High/Medium issues found:
   - Dispatch fix to implementation agent
   - Re-run all 3 reviewers in parallel
   - Increment metrics.review_iterations
   - Repeat until clean (max 3 iterations)

7. When all issues resolved:
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
   - agent_outputs.validation = {
       result: "approved",
       timestamp: "[ISO timestamp]",
       criteria_results: [{criterion, status}]
     }
   - Proceed to Step 7.1 (Execution Unit Approval)
```

## Step 7.1: Execution Unit Approval (Conditional)

**Checkpoint depends on `execution_mode`:** `manual_per_subtask` → Execute | `manual_per_task` / `automatic` → Skip

1. Set `status = "paused_for_approval"`, save state
2. Present summary: Unit ID, Parent Task, Gates 0-5 status, Criteria X/X, Duration, Files Changed
3. **AskUserQuestion:** "Ready to proceed?" Options: (a) Continue (b) Test First (c) Stop Here
4. **Handle response:**

| Response | Action |
|----------|--------|
| Continue | Set in_progress, move to next unit (or Step 7.2 if last) |
| Test First | Set `paused_for_testing`, STOP, output resume command |
| Stop Here | Set `paused`, STOP, output resume command |

## Step 7.2: Task Approval Checkpoint (Conditional)

**Checkpoint depends on `execution_mode`:** `manual_per_subtask` / `manual_per_task` → Execute | `automatic` → Skip

1. Set task `status = "completed"`, cycle `status = "paused_for_task_approval"`, save state
2. Present summary: Task ID, Subtasks X/X, Total Duration, Review Iterations, Files Changed
3. **AskUserQuestion:** "Task complete. Ready for next?" Options: (a) Continue (b) Integration Test (c) Stop Here
4. **Handle response:**

```text
After completing all subtasks of a task:

0. Check execution_mode from state:
   - If "automatic": Still run feedback, then skip to next task
   - If "manual_per_subtask" OR "manual_per_task": Continue with checkpoint below

1. Set task status = "completed"

2. **Run dev-feedback-loop skill (MANDATORY)**
   This skill now handles BOTH assertiveness metrics AND prompt quality analysis.

   Invoke: Skill "ring-dev-team:dev-feedback-loop"

   The skill will:
   a) Calculate assertiveness score for the task
   b) Dispatch prompt-quality-reviewer agent with agent_outputs from state
   c) Generate improvement suggestions
   d) Write feedback to docs/feedbacks/cycle-{date}/{agent}.md

3. Set cycle status = "paused_for_task_approval"
4. Save state

5. Present task completion summary (with feedback metrics):
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
   │ ═══════════════════════════════════════════════ │
   │ FEEDBACK METRICS                                │
   │ ═══════════════════════════════════════════════ │
   │                                                  │
   │ Assertiveness Score: XX% (Rating)               │
   │                                                  │
   │ Prompt Quality by Agent:                        │
   │   backend-engineer-golang: 90% (Excellent)     │
   │   qa-analyst: 75% (Acceptable)                 │
   │   code-reviewer: 88% (Good)                    │
   │                                                  │
   │ Improvements Suggested: N                       │
   │ Feedback Location:                              │
   │   docs/feedbacks/cycle-YYYY-MM-DD/             │
   │                                                  │
   │ ═══════════════════════════════════════════════ │
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

6. **ASK FOR EXPLICIT APPROVAL using AskUserQuestion tool:**

   Question: "Task [task_id] complete. Ready to start the next task?"
   Options:
     a) "Continue" - Proceed to next task
     b) "Integration Test" - User wants to test the full task integration
     c) "Stop Here" - Pause cycle

7. Handle user response:

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

**Note:** Tasks without subtasks execute both 7.1 and 7.2 in sequence.

## Step 8: Cycle Completion

1. **Calculate metrics:** total_duration_ms, average gate durations, review iterations, pass/fail ratio
2. **Update state:** `status = "completed"`, `completed_at = timestamp`
3. **Generate report:** Task | Subtasks | Duration | Review Iterations | Status
4. **REQUIRED:** Invoke `ring-dev-team:dev-feedback-loop` for metrics tracking
5. **Report:** "Cycle completed. Tasks X/X, Subtasks Y, Time Xh Xm, Review iterations X"

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

| Type | Condition | Action |
|------|-----------|--------|
| **Recoverable** | Network timeout | Retry with exponential backoff |
| **Recoverable** | Agent failure | Retry once, then pause for user |
| **Recoverable** | Test flakiness | Re-run tests up to 2 times |
| **Non-Recoverable** | Missing required files | Stop and report |
| **Non-Recoverable** | Invalid state file | Must restart (cannot resume) |
| **Non-Recoverable** | Max review iterations | Pause for user |

**On any error:** Update state → Set status (failed/paused) → Save immediately → Report (what failed, why, how to recover, resume command)

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
