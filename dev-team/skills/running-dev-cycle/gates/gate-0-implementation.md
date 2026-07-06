## Step 2: Gate 0 - Implementation (Per Execution Unit)

ℹ️ **CADENCE:** Task-level. Execution unit is always a task Task N.M.T (or the epic-itself when the epic has no task breakdown — FALLBACK plans). Writes to `state.epics[i].tasks[j].gate_progress.implementation`. Epic-level review (Gate 8) MUST NOT be dispatched from inside this step — it runs after the task loop.

⛔ **Phase gate:** Before entering Gate 0 for the current epic, confirm its phase (`state.phases[]` lookup via `epic.phase`) has status `detailed` or `in_progress`. An epic in an un-elaborated (`epic-level`) phase is NOT dispatch-ready — its `tasks[]` is empty. The hook also blocks this; do not attempt it.

**REQUIRED SUB-SKILL:** Use ring:implementing-tasks

**Execution Unit:** Epic-itself (if no task breakdown) or a Task N.M.T (if epic has tasks). Either way, the unit is a TASK-LEVEL scope.

### Pre-Dispatch: Before Gate 0 Checkpoint (MANDATORY)

MUST execute the **Before Gate 0 (epic start)** row from the State Persistence Checkpoints table before sub-steps 2.1–2.3:
- Set `epic.status = "in_progress"` in state JSON
- Update the epic's plan `**Status:**` line → `Doing` (per the plan Status update rules in that table)
- Write state to file

CANNOT proceed to sub-steps 2.1–2.3 without completing this checkpoint. (The `epic.base_sha` captured here is the lower bound of the Gate 8 cumulative review diff — the SHA before the epic's first task.)

### ⛔ MANDATORY: Invoke ring:implementing-tasks Skill (not inline execution)

See [shared-patterns/shared-orchestrator-principle.md](../../shared-patterns/shared-orchestrator-principle.md) for full details.

**⛔ FORBIDDEN: Executing TDD-RED/GREEN logic directly from this step.**
MUST invoke the ring:implementing-tasks skill via the Skill tool; it handles all TDD phases, agent selection, agent dispatch, standards verification, and fix iteration.

### ⛔ Post-Generation Panic Check (MANDATORY)

After ring:implementing-tasks completes, verify generated code:

| Check | Command | Expected | If Found |
|-------|---------|----------|----------|
| No panic() | `grep -rn "panic(" --include="*.go" --exclude="*_test.go"` | 0 results | Return to Gate 0 with fix instructions |
| No log.Fatal() | `grep -rn "log.Fatal" --include="*.go"` | 0 results | Return to Gate 0 with fix instructions |
| No Must* helpers | `grep -rn "Must[A-Z]" --include="*.go" \| grep -v "regexp\.MustCompile"` | 0 results | Return to Gate 0 with fix instructions |
| No os.Exit() | `grep -rn "os.Exit" --include="*.go" --exclude="main.go"` | 0 results | Return to Gate 0 with fix instructions |

**If any check fails: DO NOT proceed. Return to Gate 0 with specific fix instructions.**

### ⛔ File Size Enforcement (MANDATORY — All Gates)

See [shared-patterns/file-size-enforcement.md](../../shared-patterns/file-size-enforcement.md) for thresholds, cohesion judgment, verification commands, split strategies, and agent instructions.

**Summary:** Soft limit 1000 lines per file; hard block at 1500 lines. Files in the 1001-1500 band require cohesion review — keep if coherent (state machine, parser, schema, table-driven tests, tightly-coupled domain logic), split if fragmentable without artificial boundaries. Files > 1500 lines are hard-blocked unless explicit cohesion justification is documented in the PR description. Enforcement points:

- **Gate 0:** Implementation agent receives file-size instructions; orchestrator runs verification command after agent completes. Files 1001-1500 → cohesion review; files > 1500 → hard block.
- **Gate 0 exit check (inline in ring:implementing-tasks's Delivery Verification Exit Check):** Delivery verification runs 7 checks as exit criteria: (A) file-size, (B) license headers, (C) linting, (D) migration safety, (E) vulnerability scanning, (F) API backward compatibility, (G) multi-tenant dual-mode. Any FAIL → ring:implementing-tasks re-iterates with specific fix instructions.
- **Gate 8:** Code reviewers MUST flag any file > 1000 lines as a MEDIUM+ issue (apply cohesion judgment); files > 1500 lines are CRITICAL.

### Step 2.1: Prepare Input for ring:implementing-tasks Skill

```text
current_task = state.epics[current_epic_index].tasks[current_task_index]

Gather from current execution unit (a task Task N.M.T, or the epic-itself for FALLBACK plans):

implementation_input = {
  // REQUIRED - the current task's identity
  unit_id: current_task.id,  // Task N.M.T (or the epic id for the synthetic epic-itself unit)

  // REQUIRED - the task's FULL block from the plan (read live from state.source_file
  //            under this epic): Context (with file:line refs), Implementation vision,
  //            Files, Verification, Done when. This replaces legacy acceptance_criteria
  //            sourcing — the dispatch-ready task block IS the requirement.
  requirements: current_task_block_from_plan,

  // REQUIRED - detected from project / inherited from the epic
  language: epic.language,  // "go" | "typescript" | "python"
  service_type: epic.service_type,  // "api" | "worker" | "batch" | "cli" | "frontend" | "bff"

  // OPTIONAL - additional context
  technical_design: current_task.technical_design || null,
  existing_patterns: current_task.existing_patterns || [],
  project_rules_path: "docs/PROJECT_RULES.md"
}
```

### Step 2.2: Invoke ring:implementing-tasks Skill

```text
1. Record gate start timestamp

2. REQUIRED: Invoke ring:implementing-tasks skill with structured input:

   Skill("ring:implementing-tasks") with input:
     unit_id: implementation_input.unit_id
     requirements: implementation_input.requirements
     language: implementation_input.language
     service_type: implementation_input.service_type
     technical_design: implementation_input.technical_design
     existing_patterns: implementation_input.existing_patterns
     project_rules_path: implementation_input.project_rules_path

   The skill handles:
   - Selecting appropriate agent (Go/TS/Frontend based on language)
   - TDD RED→GREEN in one dispatch (failing test with captured failure output, then implementation to pass)
   - Standards compliance verification (iteration loop, max 3 attempts)
   - Re-dispatching agent for compliance fixes
   - Outputting Standards Coverage Table with evidence

3. REQUIRED: Parse skill output for results:

   Expected output sections:
   - "## Implementation Summary" → status (PASS/FAIL), agent used
   - "## TDD Results" → RED/GREEN phase status
   - "## Files Changed" → created/modified files list
   - "## Handoff to Next Gate" → ready_for_review: YES/NO

   if skill output contains "Status: PASS" and "Ready for Review: YES":
     → Gate 0 PASSED. Proceed to Step 2.3.

   if skill output contains "Status: FAIL" or "Ready for Review: NO":
     → Gate 0 BLOCKED.
     → Skill already dispatched fixes to implementation agent
     → Skill already re-ran TDD and standards verification
     → If "ESCALATION" in output: STOP and report to user

4. **MANDATORY: ⛔ Save state to file — Write tool → [state.state_path]**
```

### Step 2.3: Gate 0 Complete

```text
5. When ring:implementing-tasks skill returns PASS:

   REQUIRED: Parse from skill output:
   - agent_used: extract from "## Implementation Summary"
   - tdd_red_status: extract from "## TDD Results" table
   - tdd_green_status: extract from "## TDD Results" table
   - files_changed: extract from "## Files Changed" table
   - standards_compliance: extract from Standards Coverage Table

   - agent_outputs.implementation = {
       skill: "ring:implementing-tasks",
       agent: "[agent used by skill]",
       output: "[full skill output]",
       timestamp: "[ISO timestamp]",
       duration_ms: [execution time],
       tdd_red: {
         status: "completed",
         test_file: "[from skill output]",
         failure_output: "[from skill output]"
       },
       tdd_green: {
         status: "completed",
         implementation_files: "[from skill output]",
         pass_output: "[from skill output]"
       },
       standards_compliance: {
         total_sections: [N from skill output],
         compliant: [N sections with ✅],
         not_applicable: [N sections with N/A],
         non_compliant: 0
       }
     }

6. Display to user:
   ┌─────────────────────────────────────────────────┐
   │ ✓ GATE 0 COMPLETE                              │
   ├─────────────────────────────────────────────────┤
   │ Skill: ring:implementing-tasks                  │
   │ Agent: [agent_used]                             │
   │ TDD-RED:   FAIL captured ✓                     │
   │ TDD-GREEN: PASS verified ✓                     │
   │ STANDARDS: [N]/[N] sections compliant ✓        │
   │                                                 │
   │ Ready for validation/review flow.              │
   └─────────────────────────────────────────────────┘

7. MANDATORY: ⛔ Save state to file — Write tool → [state.state_path]
   See "State Persistence Rule" section.

8. Proceed to Step 2.3.1 (Delivery Verification Exit Check)
```

### Step 2.3.1: Delivery Verification Exit Check (MANDATORY before Gate 0 completion)

After Gate 0 PASS, delivery verification runs AS EXIT CRITERIA (not as a separate gate).
This check is performed inside `ring:implementing-tasks` as its Delivery Verification
Exit Check. The orchestrator DOES NOT dispatch a separate skill.

Verify that the ring:implementing-tasks handoff includes `delivery_verification` field:

  required_handoff_fields:
    - implementation_summary
    - files_changed
    - tests_written
    - tdd_red_evidence
    - tdd_green_evidence
    - delivery_verification:
        result: "PASS|PARTIAL|FAIL"
        requirements_total: int
        requirements_delivered: int
        requirements_missing: int
        dead_code_items: int

IF delivery_verification.result == "PASS":
  → Update state.epics[current_epic_index].tasks[current_task_index].gate_progress.implementation.delivery_verified = true
  → Gate 0 is complete

IF delivery_verification.result == "PARTIAL" or "FAIL":
  → Return control to ring:implementing-tasks with remediation instructions (max 2 retries)
  → After 2 retries → escalate to user

Anti-Rationalization:
| Rationalization | Why It's WRONG | Required Action |
|---|---|---|
| "There's a separate Gate 0.5 / delivery-verification dispatch" | Delivery verification is a sub-check inside Gate 0, not a separate dispatch. | **Read `delivery_verification` from the Gate 0 handoff; do NOT dispatch a separate skill.** |
| "I'll just skip this check if Gate 0 passed" | Gate 0 passing without `delivery_verification` means Gate 0 is incomplete. | **Verify `delivery_verification` exists in handoff. If absent → Gate 0 failed.** |

No separate `state.gate_progress.delivery_verification` field — delivery verification is a sub-check of implementation, tracked inline under `state.epics[i].tasks[j].gate_progress.implementation`.

### Anti-Rationalization: Gate 0 Skill Invocation

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "I can run TDD-RED/GREEN directly from here" | Inline TDD = skipping the skill. Skill has iteration logic and validation. | **Invoke Skill("ring:implementing-tasks")** |
| "I already know which agent to dispatch" | Agent selection is the SKILL's job, not the orchestrator's. | **Invoke Skill("ring:implementing-tasks")** |
| "The TDD steps are documented here, I'll follow them" | These steps are REFERENCE, not EXECUTABLE. The skill is executable. | **Invoke Skill("ring:implementing-tasks")** |
| "Skill adds overhead for simple tasks" | Overhead = compliance checks. Simple ≠ exempt. | **Invoke Skill("ring:implementing-tasks")** |
| "I'll dispatch the agent and verify output myself" | Self-verification skips the skill's re-dispatch loop. | **Invoke Skill("ring:implementing-tasks")** |
| "Agent already did TDD internally" | Internal ≠ verified by skill. Skill validates output structure. | **Invoke Skill("ring:implementing-tasks")** |

### Step 2.4: Task Checkpoint (Conditional — `manual_per_task` only)

**Checkpoint depends on `execution_mode`:** `manual_per_task` → Execute | `manual_per_epic` / `automatic` → Skip

This is the ONLY per-task pause. It fires after the task's Gate 0 completes (the `[checkpoint if manual_per_task mode]` step in the Execution Order). Epic review (Gate 8) and epic validation (Gate 9) run later, once per epic.

0. **COMMIT CHECK (before checkpoint):**
   - if `commit_timing == "per_task"`:
     - Execute `/ring:committing-changes` command with message: `feat({task_id}): {task_title}`
     - Include all changed files from this task
   - else: Skip commit (will happen at epic or cycle end)

0b. **VISUAL CHANGE REPORT (opt-in):**
   - If `state.visual_report_granularity == "task"`: invoke `Skill("ring:visualizing")` for a per-task code-diff and tell the user the path.
   - Default (`"none"`): skip.

1. Set `status = "paused_for_approval"`, save state
2. Present summary: Task ID, Parent Epic, Gate 0 status, Duration, Files Changed, Commit Status
3. **AskUserQuestion:** "Ready to proceed?" Options: (a) Continue (b) Test First (c) Stop Here
4. **Handle response:**

| Response | Action |
|----------|--------|
| Continue | Set in_progress, move to next task (or to Gate 8 if this was the last task of the epic) |
| Test First | Set `paused_for_testing`, STOP, output resume command |
| Stop Here | Set `paused`, STOP, output resume command |

---
