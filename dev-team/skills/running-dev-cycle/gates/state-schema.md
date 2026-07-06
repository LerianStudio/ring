## State Management

### State Path Selection (MANDATORY)

The state file path depends on the **source of the plan**:

| Plan Source | State Path | Use Case |
|-------------|------------|----------|
| `docs/ring:planning-backend-refactor/*/tasks.md` | `docs/ring:planning-backend-refactor/current-cycle.json` | Refactoring existing code |
| `docs/pre-dev/*/plan.md` | `docs/ring:running-dev-cycle/current-cycle.json` | New feature development. Legacy `tasks.md` (old `## Summary` table + E-/T- ids) is accepted ONLY for cycles already in flight — a `current-cycle.json` already exists and init is not re-run on them. New cycles MUST start from the canonical plan format. |
| `docs/plans/*.md` (standalone ring:writing-plans) | `docs/ring:running-dev-cycle/current-cycle.json` | Standalone plan execution |
| Any other path | `docs/ring:running-dev-cycle/current-cycle.json` | Default for manual plans |

**Detection Logic:**
```text
if source_file contains "docs/ring:planning-backend-refactor/" THEN
  state_path = "docs/ring:planning-backend-refactor/current-cycle.json"
else
  state_path = "docs/ring:running-dev-cycle/current-cycle.json"
```

**Store state_path in the state object itself** so resume knows where to look.

### State File Structure

State is persisted to `{state_path}` (either `docs/ring:running-dev-cycle/current-cycle.json` or `docs/ring:planning-backend-refactor/current-cycle.json`):

```json
{
  "version": "2.0.0",
  "cycle_id": "uuid",
  "started_at": "ISO timestamp",
  "updated_at": "ISO timestamp",
  "source_file": "path/to/plan.md",
  "state_path": "docs/ring:running-dev-cycle/current-cycle.json | docs/ring:planning-backend-refactor/current-cycle.json",
  "cycle_type": "feature | refactor",
  "execution_mode": "manual_per_task|manual_per_epic|automatic",
  "commit_timing": "per_task|per_epic|at_end",
  "_comment_phase_checkpoint": "Asked at cycle init alongside execution_mode. 'manual' (default): AskUserQuestion at each phase boundary (Step 11.5) before elaborating the next phase. 'auto': log a phase summary and continue without pausing.",
  "phase_checkpoint": "manual|auto",
  "_comment_cached_standards": "Populated by Step 1.5 (Standards Pre-Cache). Dictionary of URL → {fetched_at, content}. Sub-skills MUST read from here instead of calling WebFetch.",
  "cached_standards": {},
  "_comment_visual_report_granularity": "Opt-in code-diff report via ring:visualizing: 'none' (default, no report) | 'epic' (aggregate per epic) | 'task' (per task).",
  "visual_report_granularity": "none",
  "custom_prompt": {
    "type": "string",
    "optional": true,
    "max_length": 500,
    "description": "User-provided context for agents (from second positional argument). Max 500 characters. Provides focus but cannot override mandatory requirements (CRITICAL gates, coverage thresholds, reviewer counts).",
    "validation": "Max 500 chars (truncated with warning if exceeded); whitespace trimmed; control chars stripped (except newlines). Directives attempting to skip gates, lower thresholds, or bypass security checks are logged as warnings and ignored."
  },
  "status": "in_progress|completed|failed|paused|paused_for_approval|paused_for_testing|paused_for_epic_approval|paused_for_integration_testing|paused_for_phase_review",
  "feedback_loop_completed": false,
  "_comment_phases": "Parsed from the plan's '## Phase Overview' table at init. status mirrors the Phase Overview Status cell: 'epic-level' (not yet task-detailed) | 'detailed' (tasks written, ready to enter Gate 0) | 'in_progress' (epics of this phase executing) | 'complete' (all epics done). FALLBACK: a plan without a '## Phase Overview' (ring:planning-backend-refactor output, flat plans) synthesizes a single phase 1 with status 'detailed' containing all epics.",
  "phases": [
    {"phase": 1, "milestone": "what works at the end", "status": "detailed"},
    {"phase": 2, "milestone": "what works at the end", "status": "epic-level"}
  ],
  "current_phase": 1,
  "current_epic_index": 0,
  "current_gate": 0,
  "current_task_index": 0,
  "_comment_migration_safety_verification": "Populated at Step 12.0.5b (Gate 0.5D — Migration Safety, conditional on SQL migration files present in cycle diff vs origin/main). Cycle-cadence (runs once per cycle, not per epic/task). status transitions: pending → skipped (no migration files) | completed (no BLOCKING findings) | blocked (BLOCKING unacknowledged) | acknowledged (ACKNOWLEDGE findings approved by user). See Step 12.0.5b state persistence block for full shape.",
  "gate_progress": {
    "migration_safety_verification": {
      "status": "pending|completed|skipped|blocked|acknowledged",
      "reason": null,
      "files_checked": [],
      "findings": {
        "BLOCKING": [],
        "WARN": [],
        "ACKNOWLEDGE": []
      },
      "user_acknowledgment": null,
      "started_at": null,
      "completed_at": null
    }
  },
  "epics": [
    {
      "id": "Epic 1.1",
      "title": "Epic title",
      "phase": 1,
      "status": "pending|in_progress|completed|failed|blocked",
      "base_sha": "git HEAD SHA captured at epic start, before the first task's Gate 0; lower bound of the Gate 8 cumulative review diff",
      "feedback_loop_completed": false,
      "_comment_accumulated_metrics": "Populated at Step 11.1 (Epic Approval Checkpoint). Aggregated at cycle end by ring:writing-dev-reports (Step 12.1).",
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
      "_comment_task_gate_progress": "Task-level gate_progress holds ONLY implementation (Gate 0). Gate 0 includes TDD, coverage, local docker-compose/runtime, and delivery verification. Epic-level review (Gate 8) AND validation (Gate 9) live in epic.gate_progress, not here. An epic with no task breakdown of its own (FALLBACK plans) carries one synthetic task entry (the epic-itself unit), so every Gate 0 handoff lives under tasks[] uniformly. Later-phase epics carry tasks: [] until elaborated at their phase boundary (Step 11.5).",
      "tasks": [
        {
          "id": "Task 1.1.1",
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
              "local_runtime_verified": false,
              "files_changed": []
            }
          }
        }
      ],
      "_comment_epic_gate_progress": "Epic-level gate_progress holds review (Gate 8) AND validation (Gate 9). The only task-cadence gate (0) lives in each task's gate_progress. Gate 9 aggregates every task's acceptance criteria; criteria_results is keyed by task. gate_progress.review is the Gate 8 VERDICT only (status + completed_at); reviewer detail — iterations, pass counts, per-reviewer outputs — lives in agent_outputs.review, never duplicated here.",
      "gate_progress": {
        "review": {"status": "pending", "completed_at": null},
        "validation": {
          "status": "pending|in_progress|completed",
          "result": "pending|approved|rejected",
          "criteria_results": [],
          "completed_at": "ISO timestamp"
        }
      },
      "artifacts": {},
      "agent_outputs": {
        "implementation": {
          "agent": "ring:backend-go",
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
          "_comment_reviewer_shape": "Each reviewer is an object with the shape shown by code_reviewer below. The 9 defaults (code_reviewer, logic_reviewer, security_reviewer, test_reviewer, nil_reviewer, dead_code_reviewer, perf_reviewer, tenancy_reviewer, commons_reviewer) all use this shape. Conditional specialists (obs_reviewer, systemplane_reviewer, streaming_reviewer) use the same shape AND add \"optional\": true. Only reviewers that produce a Standards Coverage Table populate standards_compliance.",
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

### Version Guard (Init / Resume — MANDATORY)

State schema is `version: "2.0.0"` (phased rolling-wave model).

- **On resume:** if an existing `current-cycle.json` has `version` starting with `1.` (any 1.x) → ⛔ STOP. Do NOT attempt migration. Tell the user: *"This cycle was started with the pre-phased (v1.x) dev-cycle. Complete or cancel it with the prior skill version, or delete `{state_path}` to re-init under the phased model (v2.0.0)."* The schemas are not field-compatible (tasks→epics, subtasks→tasks); silent migration would corrupt the cycle.
- **On init:** always write `version: "2.0.0"`.

### Initialization (Parse the Phased Plan)

At cycle init, parse `state.source_file` (plan.md, ring:writing-plans canonical format):

1. **Phase Overview** (`## Phase Overview` table: `| Phase | Milestone | Epics | Status |`) → `phases[]`. Map the Status cell: `Epic-level` → `"epic-level"`, `Detailed` → `"detailed"`, `Complete` → `"complete"`. Set `current_phase` to the lowest phase whose status is `detailed` (the active wave; normally Phase 1). This table contract is unchanged.
2. **Epic registry** — ALL epics load into `epics[]` from the `### Epic N.M:` headings under each phase section (`## Phase N:` ...). There is NO `## Summary` table — do not look for one. Each epic's `phase` field comes from the phase section it sits under (and from `N` in its id). Each epic block carries a `**Status:**` line (`Pending` / `Doing` / `Done` / `Failed` — plain words are the contract; emoji decoration optional). Read it into `epic.status` at init; this line is also the write target for epic status updates.

   **Plan Status word ↔ `epic.status` enum mapping (both directions):**

   | Plan `**Status:**` word | `epic.status` enum value |
   |-------------------------|--------------------------|
   | `Pending` | `pending` |
   | `Doing` | `in_progress` |
   | `Done` | `completed` |
   | `Failed` | `failed` |

   On init (read): the plan word on the left sets the enum value on the right. On epic checkpoints (write): the enum transition on the right writes the plan word on the left (e.g., `epic.status = "in_progress"` → plan line becomes `Doing`). The enum value `blocked` has no plan word — a blocked epic keeps `Doing` in the plan until it resolves to `Done` or `Failed`.
3. **Task blocks** — for each epic in a `detailed` phase, parse the inline `#### Task N.M.T:` blocks under its epic section into `epics[i].tasks[]` (id, and the implementation gate_progress skeleton). A task block whose checkbox is already checked (`- [x] Done`) loads with `status: "completed"` and `gate_progress.implementation.status: "completed"` — Gate 0 skips it; execution resumes from the first unchecked task. Epics in `epic-level` phases load with `tasks: []` — they are elaborated at their phase boundary (Step 11.5).

**FALLBACK — no `## Phase Overview`** (ring:planning-backend-refactor output, flat plans):
- Synthesize a single `phases[] = [{phase: 1, milestone: "<feature> (flat plan)", status: "detailed"}]`, `current_phase = 1`. Every epic gets `phase: 1`.
- If an epic has no inline task breakdown, keep the existing synthetic single-unit mechanism: one `tasks[]` entry representing the epic itself (the epic-itself unit, id = the epic's id), so every Gate 0 handoff lives under `tasks[]` uniformly.

### ⛔ Phase-Elaboration Invariant

An epic whose phase (`phases[]` lookup via `epic.phase`) has status NOT in (`detailed`, `in_progress`) MUST NOT enter Gate 0. Later-phase epics are not dispatch-ready until elaborated at their phase boundary. The hook enforces this; the orchestrator must not attempt to start an un-elaborated epic.

### Structured Error/Issue Schemas

**These schemas enable `ring:writing-dev-reports` to analyze issues without parsing raw output.**

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
  state.epics[current_epic_index].tasks[current_task_index].gate_progress.implementation.status = "completed"
  state.epics[current_epic_index].tasks[current_task_index].gate_progress.implementation.completed_at = "[ISO timestamp]"
  state.epics[current_epic_index].tasks[current_task_index].gate_progress.implementation.delivery_verified = true
  state.epics[current_epic_index].tasks[current_task_index].gate_progress.implementation.standards_compliance = [standards result]
  state.epics[current_epic_index].tasks[current_task_index].gate_progress.implementation.coverage_actual = [coverage percent]
  state.epics[current_epic_index].tasks[current_task_index].gate_progress.implementation.coverage_threshold = [required coverage percent]
  state.epics[current_epic_index].tasks[current_task_index].gate_progress.implementation.local_runtime_verified = true
else if gate == 9:
  state.epics[current_epic_index].gate_progress.validation.status = "completed"
  state.epics[current_epic_index].gate_progress.validation.result = "[approved|rejected]"
  state.epics[current_epic_index].gate_progress.validation.criteria_results = [{task_id, criterion, status} for every task's aggregated criteria]
  state.epics[current_epic_index].gate_progress.validation.completed_at = "[ISO timestamp]"
else if gate == 8:
  state.epics[current_epic_index].gate_progress.review.status = "completed"
  state.epics[current_epic_index].gate_progress.review.completed_at = "[ISO timestamp]"
  state.epics[current_epic_index].agent_outputs.review = [all reviewer outputs]
state.current_gate = [next gate per the "current_gate Transitions and Resume" table below]
state.updated_at = "[ISO timestamp]"

# Step 2: Write to file (MANDATORY - use Write tool)
Write tool:
  file_path: [state.state_path]  # Use state_path from state object
  content: [full JSON state]
```

### `current_gate` Transitions and Resume

`current_gate ∈ {0, 8, 9}` — the gate active within the CURRENT epic. It is meaningful only during the per-epic loop; the phase boundary (Step 11.5) is driven by `status` (`paused_for_phase_review`) and the Cycle Completion phase (Steps 12.x) by `status` (`completed`), neither by `current_gate`.

| After | Outcome | Set |
|-------|---------|-----|
| Gate 0 (task) | more tasks remain | `current_gate = 0`, `current_task_index += 1` |
| Gate 0 (task) | last task of the epic done | `current_gate = 8` |
| Gate 8 (epic) | review passed | `current_gate = 9` |
| Gate 9 (epic) | criterion FAIL (Step 11) | `current_gate = 0`, `current_task_index = failing task` |
| Gate 9 (epic) | approved, Continue (Step 11.1), next epic same phase | `current_gate = 0`, `current_epic_index += 1`, `current_task_index = 0` |
| Gate 9 (epic) | approved, Continue (Step 11.1), next epic crosses a phase boundary or no epic left | enter Step 11.5 (phase boundary) — see gates/phase-boundary.md |
| Gate 9 (epic) | approved, last epic of last phase | leave the epic loop → Cycle Completion (status-driven; `current_gate` is not consulted there) |

**Resume** reads `status` + `current_epic_index` + `current_task_index` + `current_gate` jointly:
- `status` gives the macro-state (`in_progress` / `paused_*` / `completed`).
- `current_gate` + the two indices pinpoint the exact resume point inside the epic loop.
- Pause states resume by `current_gate` + the two indices:
  - `paused` / `paused_for_epic_approval` with `current_gate == 9` → validation passed; the epic (still `in_progress`) awaits the human advance decision — re-enter the Step 11.1 checkpoint.
  - `paused_for_approval` / `paused_for_testing` with `current_gate == 0` → task-level pause after Gate 0 — resume at the Gate 0 task given by the indices.
  - `paused_for_phase_review` → the last epic of `current_phase` is approved and the cycle is at the phase boundary (Step 11.5) awaiting the user's continue/pause/adjust decision (manual checkpoint) — re-enter gates/phase-boundary.md at the checkpoint step.
  - `paused_for_integration_testing` with `current_gate == 9` and the current epic already `completed` → integration test ran out-of-band; resume by advancing past it (re-enter Step 11.1's Continue path: next epic same phase, or Step 11.5 if a phase boundary is crossed), or Cycle Completion if it was the last epic of the last phase.

### State Persistence Checkpoints

⛔ **Cadence-aware write paths.** The task-level gate (0) writes to `state.epics[i].tasks[j].gate_progress.implementation`. Epic-level gates (8, 9) write to `state.epics[i].gate_progress.review` and `state.epics[i].gate_progress.validation`. Never write epic-level gate status under a task and never write task-level gate status under the epic.

| Checkpoint | Cadence | MUST Update | MUST Write File |
|------------|---------|-------------|-----------------|
| **Before Gate 0 (epic start)** | Epic | `epic.status = "in_progress"` + `epic.base_sha = current HEAD SHA` (review-diff lower bound) in JSON **+ plan epic `**Status:**` → `Doing`** | ✅ YES |
| Gate 0 TDD (RED→GREEN) | Task | `state.epics[i].tasks[j].gate_progress.implementation.tdd_red` (status + failure_output), `.tdd_green` (status + test_pass_output), `.implementation.status` | ✅ YES |
| Gate 0 exit (Quality + Delivery Verification) | Task | `state.epics[i].tasks[j].gate_progress.implementation.delivery_verified = true` + `.standards_compliance` + `.coverage_actual` + `.coverage_threshold` + `.local_runtime_verified` + `.files_changed` (union consumed by Gate 8) | ✅ YES |
| Step 2.4 (Task Checkpoint) | Task | `status = "paused_for_approval"` (task-level checkpoint; set only when `execution_mode = manual_per_task`; fires after Gate 0) | ✅ YES |
| Gate 8 (Review) | Epic | `state.epics[i].gate_progress.review.status` + `agent_outputs.review` (reviewers see cumulative epic diff) | ✅ YES |
| Gate 9 (Validation) | Epic | `state.epics[i].gate_progress.validation.status` + `.result` + `.criteria_results` (aggregated across ALL tasks; runs after Gate 8 passes) | ✅ YES |
| Step 11.1 (Epic Approval) | Epic | `epic.status = "completed"` in JSON **+ plan epic `**Status:**` → `Done`** + `epic.accumulated_metrics` populated (gate_durations_ms, review_iterations, testing_iterations, issues_by_severity); NO dev-report dispatch here (runs ONCE at Step 12.1) | ✅ YES |
| Step 11.5 (Phase Boundary) | Phase | At phase close: plan Phase Overview Status → `Complete`, `phases[]` status → `complete`, `status = "paused_for_phase_review"` (manual checkpoint). After elaboration: new phase `phases[]` status → `detailed`, Phase Overview Status → `Detailed`, load new tasks into `epics[].tasks[]`, `current_phase += 1`. See gates/phase-boundary.md. | ✅ YES |
| Step 12.0.5b (Gate 0.5D — Migration Safety, conditional) | Cycle | `state.gate_progress.migration_safety_verification = {status: "completed" \| "skipped" \| "blocked" \| "acknowledged", reason, files_checked, findings: {BLOCKING: [], WARN: [], ACKNOWLEDGE: []}, user_acknowledgment}` | ✅ YES |
| Step 12.1 (Cycle end — dev-report) | Cycle | `state.feedback_loop_completed = true` after the ONE AND ONLY `ring:writing-dev-reports` dispatch | ✅ YES |
| HARD BLOCK (any gate) | Epic | `epic.status = "failed"` in JSON **+ plan epic `**Status:**` → `Failed`** | ✅ YES |

**Plan Status update rules (apply at the epic checkpoints above):**

```text
If state.source_file is absent or file does not exist → log warning "plan Status updates skipped: source_file missing" and skip all status updates for this cycle.

epic_id = state.epics[state.current_epic_index].id
# Always the parent EPIC ID (Epic N.M) — do NOT use current_task_index

Use Edit tool on state.source_file (the plan):
- Find the `### {epic_id}:` heading and edit the `**Status:**` line in its block
- Plain words are the contract (Pending/Doing/Done/Failed); emoji decoration is optional — match whatever the line currently carries when replacing
- Before Gate 0: replace `Pending` with `Doing`
  - If already `Doing` (resumed cycle) → skip, no change needed
- Step 11.1 (all tasks done, user approved): replace `Doing` with `Done`
- HARD BLOCK (any gate, epic abandoned): replace `Doing` with `Failed`
  - If the line shows `Pending` (unexpected) → replace with target value anyway
- If the epic heading or its `**Status:**` line is not found → log warning "Status update skipped: epic {epic_id} Status line not found in {source_file}" and continue, do not abort

**Phase Overview Status sync (Step 11.5 — phase boundary):**
- Find the row starting with `| {phase} |` in the `## Phase Overview` table
- At phase close (last epic of the phase done): replace its Status cell with `Complete`
- After next-phase elaboration: replace the next phase's Status cell `Epic-level` with `Detailed`
- If the table is absent (FALLBACK single-phase plan) → skip Phase Overview sync silently
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
