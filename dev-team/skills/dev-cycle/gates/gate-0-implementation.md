## Step 2: Gate 0 - Implementation (Per Execution Unit)

ℹ️ **CADENCE:** Subtask-level. Execution unit is always a subtask (or the task-itself when the task has no subtasks). Writes to `state.tasks[i].subtasks[j].gate_progress.implementation`. Task-level review (Gate 8) MUST NOT be dispatched from inside this step — it runs after the subtask loop.

**REQUIRED SUB-SKILL:** Use ring:dev-implementation

**Execution Unit:** Task-itself (if no subtasks) or a Subtask (if task has subtasks). Either way, the unit is a SUBTASK-LEVEL scope.

### Pre-Dispatch: Before Gate 0 Checkpoint (MANDATORY)

MUST execute the **Before Gate 0 (task start)** row from the State Persistence Checkpoints table before sub-steps 2.1–2.3:
- Set `task.status = "in_progress"` in state JSON
- Update tasks.md Status → `🔄 Doing` (per tasks.md Status update rules in that table)
- Write state to file

CANNOT proceed to sub-steps 2.1–2.3 without completing this checkpoint.

### ⛔ MANDATORY: Invoke ring:dev-implementation Skill (not inline execution)

See [shared-patterns/shared-orchestrator-principle.md](../../shared-patterns/shared-orchestrator-principle.md) for full details.

**⛔ FORBIDDEN: Executing TDD-RED/GREEN logic directly from this step.**
MUST invoke the ring:dev-implementation skill via the Skill tool; it handles all TDD phases, agent selection, agent dispatch, standards verification, and fix iteration.

### ⛔ Post-Generation Panic Check (MANDATORY)

After ring:dev-implementation completes, verify generated code:

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
- **Gate 0 exit check (inline in ring:dev-implementation Step 7):** Delivery verification runs 7 checks as exit criteria: (A) file-size, (B) license headers, (C) linting, (D) migration safety, (E) vulnerability scanning, (F) API backward compatibility, (G) multi-tenant dual-mode. Any FAIL → ring:dev-implementation re-iterates with specific fix instructions.
- **Gate 8:** Code reviewers MUST flag any file > 1000 lines as a MEDIUM+ issue (apply cohesion judgment); files > 1500 lines are CRITICAL.

### Step 2.1: Prepare Input for ring:dev-implementation Skill

```text
Gather from current execution unit:

implementation_input = {
  // REQUIRED - from current execution unit
  unit_id: state.current_unit.id,
  requirements: state.current_unit.acceptance_criteria,

  // REQUIRED - detected from project
  language: state.current_unit.language,  // "go" | "typescript" | "python"
  service_type: state.current_unit.service_type,  // "api" | "worker" | "batch" | "cli" | "frontend" | "bff"

  // OPTIONAL - additional context
  technical_design: state.current_unit.technical_design || null,
  existing_patterns: state.current_unit.existing_patterns || [],
  project_rules_path: "docs/PROJECT_RULES.md"
}
```

### Step 2.2: Invoke ring:dev-implementation Skill

```text
1. Record gate start timestamp

2. REQUIRED: Invoke ring:dev-implementation skill with structured input:

   Skill("ring:dev-implementation") with input:
     unit_id: implementation_input.unit_id
     requirements: implementation_input.requirements
     language: implementation_input.language
     service_type: implementation_input.service_type
     technical_design: implementation_input.technical_design
     existing_patterns: implementation_input.existing_patterns
     project_rules_path: implementation_input.project_rules_path

   The skill handles:
   - Selecting appropriate agent (Go/TS/Frontend based on language)
   - TDD-RED phase (writing failing test, capturing failure output)
   - TDD-GREEN phase (implementing code to pass test)
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
5. When ring:dev-implementation skill returns PASS:

   REQUIRED: Parse from skill output:
   - agent_used: extract from "## Implementation Summary"
   - tdd_red_status: extract from "## TDD Results" table
   - tdd_green_status: extract from "## TDD Results" table
   - files_changed: extract from "## Files Changed" table
   - standards_compliance: extract from Standards Coverage Table

   - agent_outputs.implementation = {
       skill: "ring:dev-implementation",
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
   │ Skill: ring:dev-implementation                  │
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
This check is performed inside `ring:dev-implementation` as its Step 7 (Delivery
Verification Exit Check). The orchestrator DOES NOT dispatch a separate skill.

Verify that the dev-implementation handoff includes `delivery_verification` field:

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
  → Update state.tasks[current].subtasks[current].gate_progress.implementation.delivery_verified = true
  → Gate 0 is complete

IF delivery_verification.result == "PARTIAL" or "FAIL":
  → Return control to dev-implementation with remediation instructions (max 2 retries)
  → After 2 retries → escalate to user

Anti-Rationalization:
| Rationalization | Why It's WRONG | Required Action |
|---|---|---|
| "Gate 0.5 still exists, just renamed" | Gate 0.5 was DELETED as a separate dispatch. Checks now run inline in Gate 0. | **Read `delivery_verification` from Gate 0 handoff; do NOT dispatch a separate skill.** |
| "I'll just skip this check if Gate 0 passed" | Gate 0 passing without `delivery_verification` means Gate 0 is incomplete. | **Verify `delivery_verification` exists in handoff. If absent → Gate 0 failed.** |

No separate `state.gate_progress.delivery_verification` field — delivery verification is a sub-check of implementation, tracked inline.

### Anti-Rationalization: Gate 0 Skill Invocation

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "I can run TDD-RED/GREEN directly from here" | Inline TDD = skipping the skill. Skill has iteration logic and validation. | **Invoke Skill("ring:dev-implementation")** |
| "I already know which agent to dispatch" | Agent selection is the SKILL's job, not the orchestrator's. | **Invoke Skill("ring:dev-implementation")** |
| "The TDD steps are documented here, I'll follow them" | These steps are REFERENCE, not EXECUTABLE. The skill is executable. | **Invoke Skill("ring:dev-implementation")** |
| "Skill adds overhead for simple tasks" | Overhead = compliance checks. Simple ≠ exempt. | **Invoke Skill("ring:dev-implementation")** |
| "I'll dispatch the agent and verify output myself" | Self-verification skips the skill's re-dispatch loop. | **Invoke Skill("ring:dev-implementation")** |
| "Agent already did TDD internally" | Internal ≠ verified by skill. Skill validates output structure. | **Invoke Skill("ring:dev-implementation")** |

---
