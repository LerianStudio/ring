---
name: development-cycle
description: |
  Main orchestrator for the 8-gate development cycle system. Manages task execution
  through import, analysis, design, implementation, devops, testing, review, and
  validation gates with state persistence and metrics collection.

trigger: |
  - Starting a new development cycle with a task file
  - Resuming an interrupted development cycle (--resume flag)
  - Need structured, gate-based task execution with quality checkpoints

skip_when: |
  - Single simple task without quality gates -> execute directly
  - Already in a specific gate skill -> let that gate complete
  - Need to plan tasks first -> use ring-default:writing-plans

sequence:
  after: [dev-import-tasks]
  before: [dev-feedback-loop]

related:
  complementary: [dev-import-tasks, dev-analysis, dev-design, dev-implementation, dev-devops, dev-testing, dev-review, dev-validation, dev-feedback-loop]
---

# Development Cycle Orchestrator

## Overview

The development cycle orchestrator manages task execution through 8 quality gates. It receives a markdown file with tasks (or a --resume flag), iterates through each task individually, and ensures quality at every stage.

**Announce at start:** "I'm using the development-cycle skill to orchestrate task execution through 8 gates."

## The 8 Gates

| Gate | Skill | Purpose | Agent |
|------|-------|---------|-------|
| 0 | dev-import-tasks | Parse and validate task markdown | N/A (parsing) |
| 1 | dev-analysis | Analyze codebase context, recommend agent | ring-default:codebase-explorer |
| 2 | dev-design | Create technical design | Recommended from Gate 1 |
| 3 | dev-implementation | Write code following TDD | Recommended from Gate 1 |
| 4 | dev-devops | Infrastructure and deployment | ring-dev-team:devops-engineer |
| 5 | dev-testing | E2E and integration tests | ring-dev-team:qa-analyst |
| 6 | dev-review | Parallel code review | ring-default:*-reviewer (3x parallel) |
| 7 | dev-validation | Final acceptance validation | N/A (verification) |

## State Management

State is persisted to `dev-team/state/current-cycle.json`:

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
  "tasks": [
    {
      "id": "TASK-001",
      "title": "Task title",
      "status": "pending|in_progress|completed|failed|blocked",
      "gate_progress": {
        "import": {"status": "completed", "started_at": "...", "completed_at": "..."},
        "analysis": {"status": "in_progress", "started_at": "..."},
        "design": {"status": "pending"},
        "implementation": {"status": "pending"},
        "devops": {"status": "pending"},
        "testing": {"status": "pending"},
        "review": {"status": "pending"},
        "validation": {"status": "pending"}
      },
      "recommended_agent": null,
      "complexity": null,
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
Input: path/to/tasks.md

1. Verify file exists
2. Generate cycle_id (UUID)
3. Initialize state file at dev-team/state/current-cycle.json
4. Record started_at timestamp
5. Proceed to Gate 0
```

### Resume Cycle (with --resume flag)

```
Input: --resume

1. Load dev-team/state/current-cycle.json
2. Validate state file exists and is valid
3. Display resume summary:
   - Cycle started: [timestamp]
   - Tasks: [completed]/[total]
   - Current task: [id] - [title]
   - Current gate: [gate_name]
4. Ask user to confirm resume
5. Continue from current_gate of current_task
```

## Step 2: Gate 0 - Import Tasks

**REQUIRED SUB-SKILL:** Use ring-dev-team:dev-import-tasks

```
1. Record gate start timestamp
2. Invoke: Skill tool: "ring-dev-team:dev-import-tasks"
   - Pass: source_file path
3. Receive: List of validated tasks
4. Update state:
   - Populate tasks array
   - Set current_task_index = 0
   - Set current_gate = 1
5. Record gate end timestamp
6. Calculate and store gate duration
```

**On ERROR:**
- Log error to state
- Set status = "failed"
- Report to user with remediation steps
- Do NOT proceed

**On WARNING:**
- Log warnings to state
- Continue to next gate

## Step 3: Gate 1 - Analysis (Per Task)

**REQUIRED SUB-SKILL:** Use ring-dev-team:dev-analysis

```
For current task:

1. Record gate start timestamp
2. Invoke: Skill tool: "ring-dev-team:dev-analysis"
   - Pass: task details from state
3. Receive:
   - recommended_agent (e.g., ring-dev-team:backend-engineer-golang)
   - complexity (S/M/L/XL)
   - affected_files list
   - risks list
   - project_config (from docs/STANDARDS.md if exists)
4. Update task in state:
   - recommended_agent
   - complexity
   - gate_progress.analysis.status = "completed"
   - artifacts.analysis = {affected_files, risks, project_config}
5. Record gate end timestamp
6. Proceed to Gate 2
```

## Step 4: Gate 2 - Design (Per Task)

**REQUIRED SUB-SKILL:** Use ring-dev-team:dev-design

```
For current task:

1. Record gate start timestamp
2. Invoke: Skill tool: "ring-dev-team:dev-design"
   - Pass: task details, analysis artifacts
3. Receive: Technical design document
4. Update state:
   - gate_progress.design.status = "completed"
   - artifacts.design = {document_path, decisions}
5. Record gate end timestamp
6. Proceed to Gate 3
```

## Step 5: Gate 3 - Implementation (Per Task)

**REQUIRED SUB-SKILL:** Use ring-dev-team:dev-implementation

```
For current task:

1. Record gate start timestamp
2. Dispatch to recommended_agent (from Gate 1):
   Task tool:
     subagent_type: "[recommended_agent]"
     prompt: |
       Implement task: [task_id] - [title]

       Requirements:
       [functional_requirements]

       Technical Specs:
       [technical_requirements]

       Design:
       [design_document_content]

       Affected Files:
       [affected_files]

       Follow TDD (ring-default:test-driven-development).
       Commit your changes.
       Report: files changed, tests written, test results.

3. Receive: Implementation report
4. Update state:
   - gate_progress.implementation.status = "completed"
   - artifacts.implementation = {files_changed, commit_sha}
5. Record gate end timestamp
6. Proceed to Gate 4
```

## Step 6: Gate 4 - DevOps (Per Task)

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
5. Update state and proceed to Gate 5
```

## Step 7: Gate 5 - Testing (Per Task)

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
   - Loop back to Gate 3 (Implementation) with failure details
   - Increment metrics.review_iterations
5. If tests pass:
   - Update state
   - Proceed to Gate 6
```

## Step 8: Gate 6 - Review (Per Task)

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
   - Low: Add TODO comment
   - Cosmetic: Add FIXME comment

5. If Critical/High/Medium issues found:
   - Dispatch fix to recommended_agent
   - Re-run all 3 reviewers in parallel
   - Increment metrics.review_iterations
   - Repeat until clean

6. When all issues resolved:
   - Update state
   - Proceed to Gate 7
```

## Step 9: Gate 7 - Validation (Per Task)

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
   - Reset current_gate = 1

5. If validation fails:
   - Log failure reasons
   - Determine which gate to revisit
   - Loop back to appropriate gate

6. Record gate end timestamp
```

## Step 10: Cycle Completion

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
   | Task | Duration | Review Iterations | Status |
   |------|----------|-------------------|--------|
   | TASK-001 | 45m | 2 | PASS |
   | TASK-002 | 32m | 1 | PASS |

4. Invoke dev-feedback-loop skill (if defined)

5. Report to user:
   "Development cycle completed.
   Tasks: X/X completed
   Total time: Xh Xm
   Review iterations: X

   See detailed report in state file."
```

## Review Gate Failure Handling

When Gate 6 (Review) returns FAIL:

```
1. Parse reviewer findings
2. Categorize issues by severity
3. For Critical/High/Medium:
   a. Dispatch fix to recommended_agent with specific issues
   b. Agent makes fixes and commits
   c. Re-run ALL 3 reviewers in parallel
   d. Repeat until clean or max iterations (3)

4. If max iterations exceeded:
   - Set task status = "blocked"
   - Pause cycle
   - Report to user for manual intervention
   - Store detailed failure context in state
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
| Import | Xm Ys | completed |
| Analysis | Xm Ys | completed |
| Design | Xm Ys | completed |
| Implementation | Xm Ys | in_progress |
| DevOps | - | pending |
| Testing | - | pending |
| Review | - | pending |
| Validation | - | pending |

### Issues Encountered
- [List any errors, warnings, or blockers]
- Or "None"

### State File Location
`dev-team/state/current-cycle.json`

### Handoff to Next Gate
- Current task: [task_id]
- Next gate: [gate_name]
- Prerequisites met: [yes/no]
- Blocking issues: [list or "none"]
