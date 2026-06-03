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
       appears in requirements_delivered), AND Gate 8 review for the task passed
       (`gate_progress.review.status == "completed"`).
     - FAIL otherwise.
   Read the verdicts Gate 0 and Gate 8 already wrote to state. Gate 9 does NOT
   recompute test results, coverage, or review findings.

4. If any criterion is FAIL:
   - Log which subtask + criterion failed and why.
   - Write `gate_progress.validation.status = "completed"`, `result = "rejected"`,
     `criteria_results = [{subtask_id, criterion, status}]`. Save state.
   - Set `current_subtask_index` to the failing subtask and `current_gate = 0`, then
     re-enter Gate 0 (Build) for that subtask with remediation instructions.
     After it rebuilds, re-run Gate 8 (task) and return here for Gate 9.
   - This is the only reject path: criterion failure loops back automatically,
     before the human checkpoint (Step 11.1) is ever reached.

5. If all criteria PASS:
   - Record gate end timestamp.
   - Write `gate_progress.validation.status = "completed"`, `result = "approved"`,
     `criteria_results = [{subtask_id, criterion, status}]`. Save state.
   - Proceed to Step 11.1 (Task Approval Checkpoint).
```

## Step 11.1: Task Approval Checkpoint (Conditional)

**Checkpoint depends on `execution_mode`:** `manual_per_subtask` / `manual_per_task` → Execute | `automatic` → Skip

⛔ **This checkpoint gates ADVANCEMENT, not correctness.** Criterion correctness was settled in Step 11 — a FAIL there already looped back to Gate 0, so this point is reached only with `validation.result == "approved"`. Here the user decides whether to advance: Continue / Integration Test (both accept the task and move on) or Stop Here (pause the cycle). Self-approval by the orchestrator is PROHIBITED — the orchestrator never advances on the user's behalf.

> The per-subtask pause for `manual_per_subtask` mode lives after Gate 0 (see the `[checkpoint if manual_per_subtask mode]` step in the Execution Order). There is NO per-subtask validation pause here — Gate 9 validation is task-level only.

0. **COMMIT CHECK (before checkpoint):**
   - `commit_timing == "per_task"` → execute `/ring:commit` with message `feat({task_id}): {task_title}`, including all files changed across the task's subtasks.
   - `commit_timing == "per_subtask"` → already committed per subtask.
   - else → defer to cycle end.

0b. **VISUAL CHANGE REPORT (opt-in):**
   - `state.visual_report_granularity == "task"` → invoke `Skill("ring:visualize")` for an aggregate code-diff of all subtasks in the task, save to `docs/ring:dev-cycle/reports/task-{task_id}-report.html`, and tell the user the path.
   - Default (`"none"`): skip.

1. **Accumulate task metrics into state** (always, independent of mode — NO dev-report dispatch here):
   Write into `state.tasks[current_task_index].accumulated_metrics`:
   - `gate_durations_ms`: {gate_name: duration_ms for each completed gate}
   - `review_iterations`: `state.tasks[current].agent_outputs.review.iterations`
   - `testing_iterations`: implementation-owned TDD/coverage iterations from Gate 0
   - `issues_by_severity`: {CRITICAL, HIGH, MEDIUM, LOW counts from Gate 8 output}

   Set `state.tasks[current].feedback_loop_completed = true`. Save state.
   (The single `ring:dev-report` dispatch runs at cycle end, Step 12.1 — aggregate data yields stronger insight than N per-task runs.)

   | Rationalization | Why It's WRONG | Required Action |
   |-----------------|----------------|-----------------|
   | "Should dispatch dev-report now" | dev-report runs ONCE at cycle end (Step 12.1). Per-task metrics are accumulated into state, not analyzed here. | **Accumulate metrics into state, proceed.** |

2. Set cycle `status = "paused_for_task_approval"`, save state. **The task stays `in_progress`** — it is not marked `completed` until the user advances (step 5).

3. Present aggregated AC evidence + summary:
   ┌─────────────────────────────────────────────────┐
   │ ✓ TASK VALIDATED — AWAITING APPROVAL            │
   ├─────────────────────────────────────────────────┤
   │ Task: [task_id] - [task_title]                  │
   │ Subtasks Completed: X/X                         │
   │ Acceptance Criteria (all subtasks): X/X PASS    │
   │ Total Duration: Xh Xm                           │
   │ Review Iterations: N                            │
   │ Assertiveness Score: XX% (Rating)               │
   │ Files Changed: [list]                           │
   │ Commit Status: [committed | deferred]           │
   │ Next Task: [next_task_id] or "cycle complete"   │
   └─────────────────────────────────────────────────┘

4. **AskUserQuestion:** "Task [task_id] complete and validated. Ready for the next task?"
   - (a) Continue — accept the task and proceed to the next
   - (b) Integration Test — accept the task, pause to test the full integration
   - (c) Stop Here — pause the cycle without advancing

5. **Handle response:**

| Response | Action |
|----------|--------|
| Continue | Set `task.status = "completed"`, tasks.md Status → `✅ Done`. Set cycle `status = "in_progress"`, `current_task_index += 1`, `current_subtask_index = 0`, `current_gate = 0`. Save. Proceed to the next task. |
| Integration Test | Set `task.status = "completed"`, tasks.md Status → `✅ Done`. Set cycle `status = "paused_for_integration_testing"`. Save. Output: `Cycle paused for integration testing. Resume with /ring:dev-cycle --resume`. STOP. |
| Stop Here | Leave `task.status = "in_progress"` (NOT completed; the cycle re-enters this checkpoint on resume). Set cycle `status = "paused"`. Save. Output: `Cycle paused after task [task_id]. Resume with /ring:dev-cycle --resume`. STOP. |

**Note:** Tasks without subtasks treat the task-itself as a single subtask; their aggregated criteria set is just that one unit's acceptance criteria.
