## State Management

### State Path Selection (MANDATORY)

The state file path depends on the **source of tasks**:

| Task Source | State Path | Use Case |
|-------------|------------|----------|
| `docs/ring:dev-refactor/*/tasks.md` | `docs/ring:dev-refactor/current-cycle.json` | Refactoring existing code |
| `docs/pre-dev/*/tasks.md` | `docs/ring:dev-cycle/current-cycle.json` | New feature development |
| Any other path | `docs/ring:dev-cycle/current-cycle.json` | Default for manual tasks |

**Detection Logic:**
```text
if source_file contains "docs/ring:dev-refactor/" THEN
  state_path = "docs/ring:dev-refactor/current-cycle.json"
else
  state_path = "docs/ring:dev-cycle/current-cycle.json"
```

**Store state_path in the state object itself** so resume knows where to look.

### State File Structure

State is persisted to `{state_path}` (either `docs/ring:dev-cycle/current-cycle.json` or `docs/ring:dev-refactor/current-cycle.json`):

```json
{
  "version": "1.1.0",
  "cycle_id": "uuid",
  "started_at": "ISO timestamp",
  "updated_at": "ISO timestamp",
  "source_file": "path/to/tasks.md",
  "state_path": "docs/ring:dev-cycle/current-cycle.json | docs/ring:dev-refactor/current-cycle.json",
  "cycle_type": "feature | refactor",
  "execution_mode": "manual_per_subtask|manual_per_task|automatic",
  "commit_timing": "per_subtask|per_task|at_end",
  "_comment_cached_standards": "Populated by Step 1.5 (Standards Pre-Cache). Dictionary of URL → {fetched_at, content}. Sub-skills MUST read from here instead of calling WebFetch.",
  "cached_standards": {},
  "_comment_visual_report_granularity": "Default 'task' (generate visual report once per task). Opt-in 'subtask' to generate per-subtask reports.",
  "visual_report_granularity": "task",
  "custom_prompt": {
    "type": "string",
    "optional": true,
    "max_length": 500,
    "description": "User-provided context for agents (from second positional argument). Max 500 characters. Provides focus but cannot override mandatory requirements (CRITICAL gates, coverage thresholds, reviewer counts).",
    "validation": "Max 500 chars (truncated with warning if exceeded); whitespace trimmed; control chars stripped (except newlines). Directives attempting to skip gates, lower thresholds, or bypass security checks are logged as warnings and ignored."
  },
  "status": "in_progress|completed|failed|paused|paused_for_approval|paused_for_testing|paused_for_task_approval|paused_for_integration_testing",
  "feedback_loop_completed": false,
  "current_task_index": 0,
  "current_gate": 0,
  "current_subtask_index": 0,
  "_comment_migration_safety_verification": "Populated at Step 12.0.5b (Gate 0.5D — Migration Safety, conditional on SQL migration files present in cycle diff vs origin/main). Cycle-cadence (runs once per cycle, not per task/subtask). status transitions: pending → skipped (no migration files) | completed (no BLOCKING findings) | blocked (BLOCKING unacknowledged) | acknowledged (ACKNOWLEDGE findings approved by user). See Step 12.0.5b state persistence block for full shape.",
  "gate_progress": {
    "migration_safety_verification": {
      "status": "pending|completed|skipped|blocked|acknowledged",
      "files_checked": [],
      "findings": {
        "BLOCKING": 0,
        "WARN": 0,
        "ACKNOWLEDGE": 0
      },
      "user_acknowledgment": null,
      "started_at": null,
      "completed_at": null
    }
  },
  "tasks": [
    {
      "id": "T-001",
      "title": "Task title",
      "status": "pending|in_progress|completed|failed|blocked",
      "feedback_loop_completed": false,
      "_comment_accumulated_metrics": "Populated at Step 11.2 (Task Approval Checkpoint). Aggregated at cycle end by ring:dev-report (Step 12.1).",
      "accumulated_metrics": {
        "gate_durations_ms": {},
        "review_iterations": 0,
        "testing_iterations": 0,
        "issues_by_severity": {
          "CRITICAL": 0,
          "HIGH": 0,
          "MEDIUM": 0,
          "LOW": 0
        }
      },
      "_comment_subtask_gate_progress": "Subtask-level gate_progress holds implementation (Gate 0) and validation (Gate 9). Gate 0 includes TDD, coverage, local docker-compose/runtime, and delivery verification. Task-level review (Gate 8) lives in task.gate_progress, not here.",
      "subtasks": [
        {
          "id": "ST-001-01",
          "file": "subtasks/T-001/ST-001-01.md",
          "status": "pending|completed",
          "gate_progress": {
            "implementation": {
              "status": "pending|in_progress|completed",
              "started_at": "ISO timestamp",
              "completed_at": "ISO timestamp",
              "tdd_red": {
                "status": "pending|in_progress|completed",
                "test_file": "path/to/test_file.go",
                "failure_output": "FAIL: TestFoo - expected X got nil",
                "completed_at": "ISO timestamp"
              },
              "tdd_green": {
                "status": "pending|in_progress|completed",
                "implementation_file": "path/to/impl.go",
                "test_pass_output": "PASS: TestFoo (0.003s)",
                "completed_at": "ISO timestamp"
              },
              "delivery_verified": false,
              "coverage_actual": 0.0,
              "coverage_threshold": 85,
              "local_runtime_verified": false
            },
            "validation": {
              "status": "pending|in_progress|completed",
              "result": "pending|approved|rejected",
              "completed_at": "ISO timestamp"
            }
          }
        }
      ],
      "_comment_task_gate_progress": "Task-level gate_progress holds review (Gate 8). Subtask-cadence gates (0, 9) live in each subtask's gate_progress.",
      "gate_progress": {
        "review": {"status": "pending"}
      },
      "artifacts": {},
      "agent_outputs": {
        "implementation": {
          "agent": "ring:backend-engineer-golang",
          "output": "## Summary\n...",
          "timestamp": "ISO timestamp",
          "duration_ms": 0,
          "iterations": 1,
          "coverage_actual": 87.5,
          "coverage_threshold": 85,
          "local_runtime_verified": true,
          "standards_compliance": {
            "total_sections": 15,
            "compliant": 14,
            "not_applicable": 1,
            "non_compliant": 0,
            "gaps": []
          }
        },
        "review": {
          "iterations": 1,
          "timestamp": "ISO timestamp",
          "duration_ms": 0,
          "default_reviewers_passed": "9/9",
          "conditional_specialists_triggered": [],
          "conditional_specialists_passed": "0/0",
          "selected_reviewer_count": 9,
          "_comment_reviewer_shape": "Each reviewer is an object with the shape shown by code_reviewer below. The 9 defaults (code_reviewer, business_logic_reviewer, security_reviewer, test_reviewer, nil_safety_reviewer, dead_code_reviewer, performance_reviewer, multi_tenant_reviewer, lib_commons_reviewer) all use this shape. Conditional specialists (lib_observability_reviewer, lib_systemplane_reviewer, lib_streaming_reviewer) use the same shape AND add \"optional\": true. Only reviewers that produce a Standards Coverage Table populate standards_compliance.",
          "code_reviewer": {
            "agent": "ring:code-reviewer",
            "output": "...",
            "verdict": "PASS",
            "timestamp": "...",
            "issues": [],
            "standards_compliance": {
              "total_sections": 12,
              "compliant": 12,
              "not_applicable": 0,
              "non_compliant": 0,
              "gaps": []
            }
          }
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

### Structured Error/Issue Schemas

**These schemas enable `ring:dev-report` to analyze issues without parsing raw output.**

#### Standards Compliance Gap Schema

```json
{
  "section": "Error Handling (MANDATORY)",
  "status": "❌",
  "reason": "Missing error wrapping with context",
  "file": "internal/handler/user.go",
  "line": 45,
  "evidence": "return err // should wrap with additional context"
}
```

#### Test Failure Schema

```json
{
  "test_name": "TestUserCreate_InvalidEmail",
  "test_file": "internal/handler/user_test.go",
  "error_type": "assertion",
  "expected": "ErrInvalidEmail",
  "actual": "nil",
  "message": "Expected validation error for invalid email format",
  "stack_trace": "user_test.go:42 → user.go:28"
}
```

#### Review Issue Schema

```json
{
  "severity": "MEDIUM",
  "category": "error-handling",
  "description": "Error not wrapped with context before returning",
  "file": "internal/handler/user.go",
  "line": 45,
  "suggestion": "Use fmt.Errorf(\"failed to create user: %w\", err)",
  "fixed": false,
  "fixed_in_iteration": null
}
```

### Populating Structured Data

**Each gate MUST populate its structured fields when saving to state:**

| Gate | Fields to Populate |
|------|-------------------|
| Gate 0 (Implementation) | `standards_compliance` + `coverage_actual` + `coverage_threshold` + `local_runtime_verified` + `delivery_verified` |
| Gate 8 (Review) | `standards_compliance` per reviewer + `issues[]` per reviewer |

**All gates track `standards_compliance`:**
- `total_sections`: Count from agent's standards file (via standards-coverage-table.md)
- `compliant`: Sections marked ✅ in Standards Coverage Table
- `not_applicable`: Sections marked N/A
- `non_compliant`: Sections marked ❌ (MUST be 0 to pass gate)
- `gaps[]`: Detailed info for each ❌ section (even if later fixed)

**Empty arrays `[]` indicate no issues found - this is valid data for feedback-loop.**

## ⛔ State Persistence Rule (MANDATORY)

**"Update state" means BOTH update the object and write to file. Not just in-memory.**

### After every Gate Transition

You MUST execute these steps after completing any active gate (0, 8, or 9):

```yaml
# Step 1: Update state object with gate results (cadence-aware path)
if gate == 0:
  state.tasks[current_task_index].subtasks[current_subtask_index].gate_progress.implementation.status = "completed"
  state.tasks[current_task_index].subtasks[current_subtask_index].gate_progress.implementation.completed_at = "[ISO timestamp]"
  state.tasks[current_task_index].subtasks[current_subtask_index].gate_progress.implementation.delivery_verified = true
  state.tasks[current_task_index].subtasks[current_subtask_index].gate_progress.implementation.standards_compliance = [standards result]
  state.tasks[current_task_index].subtasks[current_subtask_index].gate_progress.implementation.coverage_actual = [coverage percent]
  state.tasks[current_task_index].subtasks[current_subtask_index].gate_progress.implementation.coverage_threshold = [required coverage percent]
  state.tasks[current_task_index].subtasks[current_subtask_index].gate_progress.implementation.local_runtime_verified = true
else if gate == 9:
  state.tasks[current_task_index].subtasks[current_subtask_index].gate_progress.validation.status = "completed"
  state.tasks[current_task_index].subtasks[current_subtask_index].gate_progress.validation.result = "[approved|rejected]"
  state.tasks[current_task_index].subtasks[current_subtask_index].gate_progress.validation.completed_at = "[ISO timestamp]"
else if gate == 8:
  state.tasks[current_task_index].gate_progress.review.status = "completed"
  state.tasks[current_task_index].gate_progress.review.completed_at = "[ISO timestamp]"
  state.tasks[current_task_index].agent_outputs.review = [all reviewer outputs]
state.current_gate = [next_gate_number]
state.updated_at = "[ISO timestamp]"

# Step 2: Write to file (MANDATORY - use Write tool)
Write tool:
  file_path: [state.state_path]  # Use state_path from state object
  content: [full JSON state]
```

### State Persistence Checkpoints

⛔ **Cadence-aware write paths.** Subtask-level gates (0, 9) write to `state.tasks[i].subtasks[j].gate_progress.<gate_name>`. Task-level Gate 8 writes to `state.tasks[i].gate_progress.review`. Never write task-level gate status under a subtask and never write subtask-level gate status under the task.

| Checkpoint | Cadence | MUST Update | MUST Write File |
|------------|---------|-------------|-----------------|
| **Before Gate 0 (task start)** | Task | `task.status = "in_progress"` in JSON **+ tasks.md Status → `🔄 Doing`** | ✅ YES |
| Gate 0.1 (TDD-RED) | Subtask | `state.tasks[i].subtasks[j].gate_progress.implementation.tdd_red.status` + `.failure_output` | ✅ YES |
| Gate 0.2 (TDD-GREEN) | Subtask | `state.tasks[i].subtasks[j].gate_progress.implementation.tdd_green.status` + `.implementation.status` | ✅ YES |
| Gate 0 exit (Quality + Delivery Verification) | Subtask | `state.tasks[i].subtasks[j].gate_progress.implementation.delivery_verified = true` + `.standards_compliance` + `.coverage_actual` + `.coverage_threshold` + `.local_runtime_verified` | ✅ YES |
| Gate 9 (Validation) | Subtask | `state.tasks[i].subtasks[j].gate_progress.validation.status` + `.result` (do NOT touch task-level status here) | ✅ YES |
| Gate 8 (Review) | Task | `state.tasks[i].gate_progress.review.status` + `agent_outputs.review` (reviewers see cumulative task diff) | ✅ YES |
| Step 11.1 (Subtask Approval) | Subtask | `status = "paused_for_approval"` (subtask-level checkpoint; set only when `execution_mode = manual_per_subtask`) | ✅ YES |
| Step 11.2 (Task Approval) | Task | `task.status = "completed"` in JSON **+ tasks.md Status → `✅ Done`** + `task.accumulated_metrics` populated (gate_durations_ms, review_iterations, testing_iterations, issues_by_severity); NO dev-report dispatch here (runs ONCE at Step 12.1) | ✅ YES |
| Step 12.0.5b (Gate 0.5D — Migration Safety, conditional) | Cycle | `state.gate_progress.migration_safety_verification = {status: "completed" \| "skipped" \| "blocked" \| "acknowledged", files_checked, findings: {BLOCKING, WARN, ACKNOWLEDGE}, user_acknowledgment}` | ✅ YES |
| Step 12.1 (Cycle end — dev-report) | Cycle | `state.feedback_loop_completed = true` after the ONE AND ONLY `ring:dev-report` dispatch | ✅ YES |
| HARD BLOCK (any gate) | Task | `task.status = "failed"` in JSON **+ tasks.md Status → `❌ Failed`** | ✅ YES |

**tasks.md Status update rules (apply at the three checkpoints above):**

```text
If state.source_file is absent or file does not exist → log warning "tasks.md Status updates skipped: source_file missing" and skip all status updates for this cycle.

task_id = state.tasks[state.current_task_index].id
# Always the parent TASK ID — do NOT use current_subtask_index
# Rows where column 1 is "TOTAL" or empty → skip, not a task row

Use Edit tool on state.source_file (tasks.md):
- Find the row starting with `| {task_id} |` in the `## Summary` table
- Before Gate 0: replace `⏸️ Pending` with `🔄 Doing`
  - If already `🔄 Doing` (resumed cycle) → skip, no change needed
- Step 11.2 (all subtasks done, user approved): replace `🔄 Doing` with `✅ Done`
- HARD BLOCK (any gate, task abandoned): replace `🔄 Doing` with `❌ Failed`
  - If row shows `⏸️ Pending` (unexpected) → replace with target value anyway
- If row not found or no Status column → log warning "Status update skipped: task {task_id} row not found in {source_file}" and continue, do not abort
```

### Anti-Rationalization for State Persistence

See [shared-patterns/shared-anti-rationalization.md](../../shared-patterns/shared-anti-rationalization.md) for universal rationalizations. These are specific to state persistence:

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "I'll save state at the end" | Crash/timeout loses all progress | **Save after each gate** |
| "State is in memory, that's updated" | Memory is volatile. File is persistent. | **Write to JSON file** |
| "Only save on checkpoints" | Gates without saves = unrecoverable on resume | **Save after every gate** |
| "Write tool is slow" | Write takes <100ms. Lost progress takes hours. | **Write after every gate** |
| "I updated the state variable" | Variable ≠ file. Without Write tool, nothing persists. | **Use Write tool explicitly** |

---
