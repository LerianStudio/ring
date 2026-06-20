## Step 11: Gate 9 - Validation (Per Epic)

⛔ **CADENCE:** Epic-level. Runs ONCE per epic, AFTER Gate 8 (Review) passes for that epic. Writes to `state.epics[i].gate_progress.validation` (alongside `review`). This gate aggregates the acceptance criteria of EVERY task of the epic into a single validation + one human approval.

**Gate 8 vs Gate 9:** Gate 8 (Review) verifies the code is *well-built* (defects, security, quality). Gate 9 (Validate) verifies it is *the right thing* (acceptance criteria + human judgment of intent). These are DIFFERENT gates — Gate 9 runs AFTER review passes, at epic cadence. Do NOT merge Gate 9 into Gate 8.

```text
For the current epic:

1. Record gate start timestamp

2. Aggregate acceptance criteria across ALL tasks of the epic:
   - Build the criteria set by reading, for EACH task of the epic:
     * The task's "Done when" acceptance criteria (from its `#### Task N.M.T:` block in the plan), AND
     * The delivery-verification evidence already written at Gate 0:
       `state.epics[i].tasks[j].gate_progress.implementation`
       (delivery_verified, and the requirements_delivered mapping produced by
        ring:implementing-tasks's Delivery Verification Exit Check)
   - If the epic itself carries epic-level acceptance_criteria, include those too.
   - ⛔ Every task's criteria MUST appear in the aggregated set. A criterion
     defined on any task of the epic that is dropped here is a silent bug.
   - EXCEPTION — tasks skipped at the Map Body Hard Gate (`tasks[j].status ==
     "blocked"`, set by `gates/gate-0-implementation.md` Step 2.1.5 option b):
     EXCLUDE them from the criteria aggregation (they have no Gate 0 evidence)
     and from Gate 8's cumulative-diff expectations. Report each in
     criteria_results as `{task_id, criterion: "—", status: "SKIPPED (no contract)"}`.
     Skipped tasks do NOT trigger the step-4 FAIL loop. The epic may pass Gate 9
     with skipped tasks ONLY via explicit user acknowledgment at the Step 11.1
     human approval — list them in the Step 11.1 summary. Skipped tasks force
     the Step 11.1 checkpoint EVEN when `execution_mode == "automatic"` — a
     task with no implementation contract is a plan-correctness signal, not a
     routine pause (same treatment as Step 11.5.5's scope-divergence rule).
     A skipped task's checklist item stays `done=false` (never flips); the
     epic card follows the normal `testing` / `to_review` / `done` status
     pushes unaffected.

3. Mark PASS/FAIL per aggregated criterion — DO NOT re-run tests or review:
   For each criterion in the aggregated set:
     - PASS if its owning task's Gate 0 delivery verification marked the
       requirement delivered (delivery_verified == true and the requirement
       appears in requirements_delivered), AND Gate 8 review for the epic passed
       (`gate_progress.review.status == "completed"`).
     - FAIL otherwise.
   Read the verdicts Gate 0 and Gate 8 already wrote to state. Gate 9 does NOT
   recompute test results, coverage, or review findings.

4. If any criterion is FAIL:
   - Log which task + criterion failed and why.
   - Write `gate_progress.validation.status = "completed"`, `result = "rejected"`,
     `criteria_results = [{task_id, criterion, status}]`. Save state.
   - Set `current_task_index` to the failing task and `current_gate = 0`, then
     re-enter Gate 0 (Build) for that task with remediation instructions.
     After it rebuilds, re-run Gate 8 (epic) and return here for Gate 9.
   - This is the only reject path: criterion failure loops back automatically,
     before the human checkpoint (Step 11.1) is ever reached.

5. If all criteria PASS:
   - Record gate end timestamp.
   - Write `gate_progress.validation.status = "completed"`, `result = "approved"`,
     `criteria_results = [{task_id, criterion, status}]`. Save state.
   - Proceed to Step 11.1 (Epic Approval Checkpoint).
```

## Step 11.1: Epic Approval Checkpoint (Conditional)

**Checkpoint depends on `execution_mode`:** `manual_per_task` / `manual_per_epic` → Execute | `automatic` → Skip (EXCEPTION: an epic with `SKIPPED (no contract)` tasks forces this checkpoint even in `automatic` — see the Step 11 aggregation exception)

⛔ **This checkpoint gates ADVANCEMENT, not correctness.** Criterion correctness was settled in Step 11 — a FAIL there already looped back to Gate 0, so this point is reached only with `validation.result == "approved"`. Here the user decides whether to advance: Continue / Integration Test (both accept the epic and move on) or Stop Here (pause the cycle). Self-approval by the orchestrator is PROHIBITED — the orchestrator never advances on the user's behalf.

> The per-task pause for `manual_per_task` mode lives after Gate 0 (see the `[checkpoint if manual_per_task mode]` step in the Execution Order). There is NO per-task validation pause here — Gate 9 validation is epic-level only.

**Lerian Map Sync hook (only when `state.lerian_map_sync.enabled`):** once Gate 9 passes and the epic enters this checkpoint awaiting the user's manual test, fire the async board push → absolute column `testing` on the EPIC `card_id` (`epic_matches[].status_dispatch`; the card STAYS in `testing` through approval). The same flow posts the ONE epic-approved evidence comment (review summary, aggregated criteria PASS, PR link) on the EPIC card per SKILL.md '### Evidence & enrichment (comments, repositoryPath)' — an Epic IS a task-card now, so it is always commentable; there is no FEATURE branch and nothing-to-post case. With `commit_timing == "per_epic"`, the Step 11.1 epic commit is also the COMMIT moment where each task's evidence comment POSTs on the epic card, tagged `**Task N.M.T:** …` (see the same SKILL.md section). When the user advances (Continue / Integration Test below) and the PR is opened, fire `to_review` on the EPIC `card_id` — the same push fills the pending PR link into the per-task evidence comments and the epic-approved comment via comment UPDATE — gated by `state.lerian_map_sync.testing_gate`: `gate` waits for the user's OK before opening the PR; `bypass` auto-opens it. ⚠️ This is independent of and never overrides Gate 9 acceptance. All pushes are non-blocking (fire-and-forget); see SKILL.md '## Lerian Map Sync (optional)'.

0. **COMMIT CHECK (before checkpoint):**
   - `commit_timing == "per_epic"` → execute `/ring:committing-changes` with message `feat({epic_id}): {epic_title}`, including all files changed across the epic's tasks.
   - `commit_timing == "per_task"` → already committed per task.
   - else → defer to cycle end.

0b. **VISUAL CHANGE REPORT (opt-in):**
   - `state.visual_report_granularity == "epic"` → invoke `Skill("ring:visualizing")` for an aggregate code-diff of all tasks in the epic, save to `docs/ring:running-dev-cycle/reports/epic-{epic_id}-report.html`, and tell the user the path.
   - Default (`"none"`): skip.

1. **Accumulate epic metrics into state** (always, independent of mode — NO dev-report dispatch here):
   Write into `state.epics[current_epic_index].accumulated_metrics`:
   - `gate_durations_ms`: {gate_name: duration_ms for each completed gate}
   - `review_iterations`: `state.epics[current_epic_index].agent_outputs.review.iterations`
   - `testing_iterations`: implementation-owned TDD/coverage iterations from Gate 0
   - `issues_by_severity`: {CRITICAL, HIGH, MEDIUM, LOW counts from Gate 8 output}

   Set `state.epics[current_epic_index].feedback_loop_completed = true`. Save state.
   (The single `ring:writing-dev-reports` dispatch runs at cycle end, Step 12.1 — aggregate data yields stronger insight than N per-epic runs.)

   | Rationalization | Why It's WRONG | Required Action |
   |-----------------|----------------|-----------------|
   | "Should dispatch dev-report now" | dev-report runs ONCE at cycle end (Step 12.1). Per-epic metrics are accumulated into state, not analyzed here. | **Accumulate metrics into state, proceed.** |

2. Set cycle `status = "paused_for_epic_approval"`, save state. **The epic stays `in_progress`** — it is not marked `completed` until the user advances (step 5).

3. Present aggregated AC evidence + summary:
   ┌─────────────────────────────────────────────────┐
   │ ✓ EPIC VALIDATED — AWAITING APPROVAL            │
   ├─────────────────────────────────────────────────┤
   │ Epic: [epic_id] - [epic_title]                  │
   │ Tasks Completed: X/X                            │
   │ Acceptance Criteria (all tasks): X/X PASS       │
   │ Total Duration: Xh Xm                           │
   │ Review Iterations: N                            │
   │ Assertiveness Score: XX% (Rating)               │
   │ Files Changed: [list]                           │
   │ Commit Status: [committed | deferred]           │
   │ Next Epic: [next_epic_id] or "phase boundary" or "cycle complete" │
   └─────────────────────────────────────────────────┘

4. **AskUserQuestion:** "Epic [epic_id] complete and validated. Ready for the next epic?"
   - (a) Continue — accept the epic and proceed to the next
   - (b) Integration Test — accept the epic, pause to test the full integration
   - (c) Stop Here — pause the cycle without advancing

5. **Handle response:**

⛔ **Phase-boundary routing (Continue / Integration Test resume):** after marking the epic `Done`, determine the next epic in plan order. If the next epic's `phase` differs from the just-completed epic's `phase`, OR there is no next epic → the current phase is closing: enter **Step 11.5 (Phase Boundary)** — read `gates/phase-boundary.md` — instead of advancing `current_epic_index` directly. Otherwise advance to the next epic in the same phase.

| Response | Action |
|----------|--------|
| Continue | Set `epic.status = "completed"`, plan epic `**Status:**` → `Done`. **If next epic is in the same phase:** set cycle `status = "in_progress"`, `current_epic_index += 1`, `current_task_index = 0`, `current_gate = 0`, save, proceed to the next epic. **If next epic crosses a phase boundary or no epic remains:** enter Step 11.5 (gates/phase-boundary.md). |
| Integration Test | Set `epic.status = "completed"`, plan epic `**Status:**` → `Done`. Set cycle `status = "paused_for_integration_testing"`. Save. Output: `Cycle paused for integration testing. Resume with /ring:running-dev-cycle --resume`. STOP. (On resume, apply the phase-boundary routing above.) |
| Stop Here | Leave `epic.status = "in_progress"` (NOT completed; the cycle re-enters this checkpoint on resume). Set cycle `status = "paused"`. Save. Output: `Cycle paused after epic [epic_id]. Resume with /ring:running-dev-cycle --resume`. STOP. |

**Note:** Epics without a task breakdown (FALLBACK plans) treat the epic-itself as a single task; their aggregated criteria set is just that one unit's acceptance criteria.
