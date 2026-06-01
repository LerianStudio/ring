## Step 11: Gate 9 - Validation (Per Task)

⛔ **CADENCE:** Task-level. Runs ONCE per task, AFTER Gate 8 (Review) passes for that task. Writes to `state.tasks[i].gate_progress.validation` (alongside `review`). This gate aggregates the acceptance criteria of EVERY subtask of the task into a single validation + one human approval.

**Gate 8 vs Gate 9:** Gate 8 (Review) verifies the code is *well-built* (defects, security, quality). Gate 9 (Validate) verifies it is *the right thing* (acceptance criteria + human judgment of intent). These are DIFFERENT gates — Gate 9 runs AFTER review passes, at task cadence. Do NOT merge Gate 9 into Gate 8.

```text
For the current task:

1. Record gate start timestamp

2. Aggregate acceptance criteria across ALL subtasks of the task:
   - Build the criteria set by reading, for EACH subtask of the task:
     * The subtask's acceptance_criteria, AND
     * The delivery-verification evidence already written at Gate 0:
       `state.tasks[i].subtasks[j].gate_progress.implementation`
       (delivery_verified, and the requirements_delivered mapping produced by
        ring:dev-implementation's Delivery Verification Exit Check)
   - If the task itself carries task-level acceptance_criteria, include those too.
   - ⛔ Every subtask's criteria MUST appear in the aggregated set. A criterion
     defined on any subtask of the task that is dropped here is a silent bug.

3. Mark PASS/FAIL per aggregated criterion — DO NOT re-run tests or review:
   For each criterion in the aggregated set:
     - PASS if its owning subtask's Gate 0 delivery verification marked the
       requirement delivered (delivery_verified == true and the requirement
       appears in requirements_delivered), AND Gate 8 review for the task PASSED.
     - FAIL otherwise.
   Read the verdicts Gate 0 and Gate 8 already wrote to state. Gate 9 does NOT
   recompute test results, coverage, or review findings.

4. If any criterion is FAIL:
   - Log which subtask + criterion failed and why.
   - Loop back to Gate 0 (Build) for the affected subtask with remediation
     instructions. (Re-build → re-review → re-validate.)

5. If all criteria PASS:
   - Record gate end timestamp
   - agent_outputs.validation = {
       result: "pending_approval",
       timestamp: "[ISO timestamp]",
       criteria_results: [{subtask_id, criterion, status}]
     }
   - Proceed to Step 11.1 (Task Approval Checkpoint)
```

## Step 11.1: Task Approval Checkpoint (Conditional)

**Checkpoint depends on `execution_mode`:** `manual_per_subtask` / `manual_per_task` → Execute | `automatic` → Skip

⛔ **This is THE single human approval for the task.** It is mandatory and explicit when the checkpoint executes: the user MUST respond APPROVED (Continue / Integration Test) or REJECTED (Stop Here). Self-approval by the orchestrator is PROHIBITED — the orchestrator never approves on the user's behalf. A REJECTED task loops back to Gate 0 (Build) for the affected subtask.

> The per-subtask pause for `manual_per_subtask` mode lives after Gate 0 (see the `[checkpoint if manual_per_subtask mode]` step in the Execution Order). There is NO per-subtask validation pause here — Gate 9 validation is task-level only.

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

1. Set task `status = "completed"`, cycle `status = "paused_for_task_approval"`, save state, and update tasks.md Status → `✅ Done` (per Step 11.1 row in State Persistence Checkpoints table)

2. Present aggregated AC evidence + summary: Task ID, Subtasks X/X, aggregated acceptance criteria PASS count (every subtask's criteria), Total Duration, Review Iterations, Files Changed, Commit Status
3. **AskUserQuestion:** "Task complete. Ready for next?" Options: (a) Continue (b) Integration Test (c) Stop Here
4. **Handle response:**

```text
After completing all subtasks of a task (built, reviewed, and validated):

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
   │ Acceptance Criteria (all subtasks): X/X PASS    │
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

**Note:** Tasks without subtasks treat the task-itself as a single subtask; their aggregated criteria set is just that one unit's acceptance criteria.
