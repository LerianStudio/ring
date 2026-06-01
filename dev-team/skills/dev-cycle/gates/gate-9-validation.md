## Step 11: Gate 9 - Validation (Per Execution Unit)

ℹ️ **CADENCE:** Subtask-level. Runs after Gate 0 for the current subtask (or task-itself when no subtasks). Writes to `state.tasks[i].subtasks[j].gate_progress.validation`. Task-level Gate 8 only runs AFTER every subtask of the task has passed Gates 0 and 9.

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
   - Proceed to Step 11.1 (Execution Unit Approval)
```

## Step 11.1: Execution Unit Approval (Conditional)

**Checkpoint depends on `execution_mode`:** `manual_per_subtask` → Execute | `manual_per_task` / `automatic` → Skip

0. **COMMIT CHECK (before checkpoint):**
   - if `commit_timing == "per_subtask"`:
     - Execute `/ring:commit` command with message: `feat({unit_id}): {unit_title}`
     - Include all changed files from this subtask
   - else: Skip commit (will happen at task or cycle end)

0b. **VISUAL CHANGE REPORT (subtask-level — OPT-IN ONLY):**
   - Default: SKIP per-subtask visual report. Task-level aggregate report is generated in Step 11.2.
   - Opt-in: If `state.visual_report_granularity == "subtask"`, generate per-subtask report.
     Default value is "task".
   - Rationale: Task-level aggregate covers all subtasks' diffs; per-subtask reports are
     rarely consumed and cost one visualize dispatch each.

1. Set `status = "paused_for_approval"`, save state
2. Present summary: Unit ID, Parent Task, Gate 0 + Gate 9 status, Criteria X/X, Duration, Files Changed, Commit Status
3. **AskUserQuestion:** "Ready to proceed?" Options: (a) Continue (b) Test First (c) Stop Here
4. **Handle response:**

| Response | Action |
|----------|--------|
| Continue | Set in_progress, move to next unit (or Step 11.2 if last) |
| Test First | Set `paused_for_testing`, STOP, output resume command |
| Stop Here | Set `paused`, STOP, output resume command |

## Step 11.2: Task Approval Checkpoint (Conditional)

**Checkpoint depends on `execution_mode`:** `manual_per_subtask` / `manual_per_task` → Execute | `automatic` → Skip

0. **COMMIT CHECK (before task checkpoint):**
   - if `commit_timing == "per_task"`:
     - Execute `/ring:commit` command with message: `feat({task_id}): {task_title}`
     - Include all changed files from this task (all subtasks combined)
   - else if `commit_timing == "per_subtask"`: Already committed per subtask
   - else: Skip commit (will happen at cycle end)

0b. **VISUAL CHANGE REPORT (MANDATORY - before task checkpoint):**
   - MANDATORY: Invoke `Skill("ring:visualize")` to generate an aggregate code-diff HTML report for all subtasks in this task
   - Read `default/skills/visualize/templates/code-diff.html` to absorb the patterns before generating
   - Content aggregated from all subtask executions:
     * **Task Overview:** Task ID, title, all subtask IDs and their gate statuses
     * **Combined File Changes:** All files modified across all subtasks with before/after diff panels
     * **Aggregate Metrics:** Total tests added, total review iterations, total lines changed
   - Save to: `docs/ring:dev-cycle/reports/task-{task_id}-report.html`
   - Open in browser:
     ```text
     macOS: open docs/ring:dev-cycle/reports/task-{task_id}-report.html
     Linux: xdg-open docs/ring:dev-cycle/reports/task-{task_id}-report.html
     ```
   - Tell the user the file path
   - See [shared-patterns/anti-rationalization-visual-report.md](../../shared-patterns/anti-rationalization-visual-report.md) for anti-rationalization table

1. Set task `status = "completed"`, cycle `status = "paused_for_task_approval"`, save state, and update tasks.md Status → `✅ Done` (per Step 11.2 row in State Persistence Checkpoints table)

2. Present summary: Task ID, Subtasks X/X, Total Duration, Review Iterations, Files Changed, Commit Status
3. **AskUserQuestion:** "Task complete. Ready for next?" Options: (a) Continue (b) Integration Test (c) Stop Here
4. **Handle response:**

```text
After completing all subtasks of a task:

0. Check execution_mode from state:
   - If "automatic": Still run feedback, then skip to next task
   - If "manual_per_subtask" or "manual_per_task": Continue with checkpoint below

1. Set task status = "completed"

2. **Accumulate task metrics into state (NO dev-report dispatch here):**

   Write into `state.tasks[current_task_index].accumulated_metrics`:
   - `gate_durations_ms`: {gate_name: duration_ms for each completed gate}
   - `review_iterations`: `state.tasks[current].gate_progress.review.iterations`
   - `testing_iterations`: implementation-owned TDD/coverage iterations from Gate 0
   - `issues_by_severity`: {CRITICAL, HIGH, MEDIUM, LOW counts from Gate 8 output}

   Set `state.tasks[current].feedback_loop_completed = true`
   (Actual dev-report dispatch happens ONCE at cycle end in Step 12.1.)

   MANDATORY: Save state to file.

   Rationale: Feedback analysis is stronger on aggregate data. A single cycle-end
   dev-report run produces the same or better insights than N per-task runs.

   | Rationalization | Why It's WRONG | Required Action |
   |-----------------|----------------|-----------------|
   | "Should dispatch dev-report now" | dev-report runs ONCE at cycle end (Step 12.1). Per-task metrics are accumulated into state, not analyzed here. | **Accumulate metrics into state, proceed to next task** |

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
   │   ring:backend-engineer-golang: 90% (Excellent)     │
   │   ring:code-reviewer: 88% (Good)               │
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
   │            or "No more tasks - cycle complete"  │
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
                /ring:dev-cycle --resume
                when ready to continue."
     - STOP execution

   If "Stop Here":
     - Set status = "paused"
     - Save state
     - Output: "Cycle paused after task [task_id]. Resume with:
                /ring:dev-cycle --resume"
     - STOP execution
```

**Note:** Tasks without subtasks execute both 7.1 and 7.2 in sequence.
