# Plan: Dev-Cycle & Dev-Refactor Speedup

> Codename: **"I agree with the prancy Bentley"**
>
> Owner: Fred Amaral
> Target: Reduce dev-cycle and dev-refactor wall-clock time by ~40–50% without quality regression.
> Scope: `dev-team/skills/dev-cycle`, `dev-team/skills/dev-cycle-frontend`, `dev-team/skills/dev-refactor`, `dev-team/skills/dev-refactor-frontend`, their sub-skills, and `default/skills/codereview`.

---

## 1. Context

### The Problem

The 11-gate backend dev-cycle and 9-gate frontend dev-cycle are producing high-quality output, but their wall-clock time is dominated by **granularity mismatch**: most gates run per-subtask when they only change meaning per-task (or per-cycle). For a task with 5 subtasks, this manifests as:

- **8 reviewers × 5 subtasks = 40 reviewer runs** where a single 8-reviewer run on the cumulative task diff would catch equal or more bugs (interaction bugs across subtasks are invisible to per-subtask review).
- **DevOps/SRE gates validating Dockerfile and instrumentation coverage** 5 times when the artifacts stabilize after the first subtask.
- **Fuzz and property tests executing per subtask** when invariants are domain-scoped, not subtask-scoped.
- **WebFetch of standards happens 15–25+ times per cycle** because every sub-skill lazy-loads its own standards, defeating the 5-minute prompt cache TTL.
- **Read-after-Write state verification** after every gate, adding an I/O roundtrip that catches nothing (since `Write` already errors on failure).
- **Visual HTML reports generated per subtask AND per task** — 11 reports for a 10-subtask task.
- **dev-report feedback loop runs after each task AND at cycle end** — dispatching `prompt-quality-reviewer` N+1 times when a single aggregate run produces stronger insights.
- **dev-refactor's rigid 1:1 FINDING→REFACTOR mapping** converts 30 findings into 30 full dev-cycles when most findings naturally cluster by `(file, pattern_category)`.

### The Goal

Reclassify gate **cadence** (when they run) without reducing gate **count** (how many checks run). All 8 reviewers still run. All 85% coverage thresholds still enforce. All WCAG AA checks still execute. All invariants still get fuzzed. We are removing redundant *operations*, not redundant *verifications*.

### What This Plan Explicitly Does NOT Do

- Does **not** reduce reviewer count (still 8 backend / 5 frontend).
- Does **not** introduce conditional/classifier-based reviewer dispatch.
- Does **not** lower any quality threshold (coverage %, WCAG, CWV, Lighthouse).
- Does **not** skip any gate. Every gate still runs — at a smarter cadence.
- Does **not** remove TDD RED→GREEN enforcement.
- Does **not** delete `dev-delivery-verification/SKILL.md`. Its checks move into Gate 0 exit criteria; the skill file stays as a preserved orchestration entry (marked "inlined into ring:dev-implementation").

---

## 2. Change Summary (The Two Maps)

### Map A: Cadence Migration

| Gate | Current Cadence | New Cadence | Backend/Frontend |
|------|----------------|-------------|------------------|
| Gate 0 Implementation | subtask | **subtask** (unchanged) | both |
| Gate 0.5 Delivery Verification | subtask (separate gate) | **merged into Gate 0 exit criteria** | backend only |
| Gate 1 DevOps | subtask | **task** | both |
| Gate 2 SRE (backend) / Accessibility (frontend) | subtask | **task** | both |
| Gate 3 Unit Testing | subtask | **subtask** (unchanged) | both |
| Gate 4 Fuzz (backend) / Visual (frontend) | subtask | **task** | both |
| Gate 5 Property (backend) / E2E (frontend) | subtask | **task** | both |
| Gate 6 Integration write (backend) / Performance (frontend) | subtask | **task** | both |
| Gate 7 Chaos write (backend) / Review (frontend) | subtask | **task** | both |
| Gate 8 Review (backend) | subtask | **task** | backend only |
| Gate 9 Validation (backend) / Gate 8 Validation (frontend) | subtask | **subtask** (unchanged) | both |

### Map B: Complete Removals

| # | What | Where | Why |
|---|------|-------|-----|
| R1 | Read-after-Write state verification | `dev-cycle/SKILL.md` + `dev-cycle-frontend/SKILL.md` | `Write` already errors on failure |
| R2 | Gate 0.5 as separate dispatched gate | `dev-cycle/SKILL.md` (Step 2.5) | Checks become Gate 0 exit criteria |
| R3 | Per-sub-skill WebFetch of standards | all 12+ sub-skills | Replaced by cycle-level cache in state |
| R4 | Per-subtask visual reports | `dev-cycle/SKILL.md` (Step 11.1 0b) + frontend equivalent | Task-level report is the one users consume |
| R5 | Per-task dev-report dispatch | `dev-cycle/SKILL.md` (Step 11.2 point 2) | Single cycle-end aggregate is stronger |
| R6 | 1:1 FINDING→REFACTOR mapping | `dev-refactor/SKILL.md` + frontend | Cluster by `(file, pattern_category)` with traceability |

---

## 3. State Schema Changes

The cycle state file (`docs/ring:dev-cycle/current-cycle.json` and `docs/ring:dev-cycle-frontend/current-cycle.json`) needs **four schema additions**. These are additive — existing readers that don't know about them won't break.

### 3.1 Cycle-level `cached_standards` dictionary

```json
{
  "version": "1.1.0",
  "cached_standards": {
    "https://raw.githubusercontent.com/LerianStudio/ring/main/CLAUDE.md": {
      "fetched_at": "ISO timestamp",
      "content": "..."
    },
    "https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang.md": {
      "fetched_at": "ISO timestamp",
      "content": "..."
    }
    // ... one entry per WebFetched URL
  }
}
```

Populated at Step 1.5 of dev-cycle (new "Standards Pre-Cache" step). Sub-skills read from this dict instead of calling WebFetch directly.

### 3.2 Subtask-level `gate_progress` (new field on subtasks)

Currently `gate_progress` only exists on tasks (`state.tasks[i].gate_progress`). Add it to subtasks too:

```json
{
  "tasks": [{
    "id": "T-001",
    "gate_progress": {
      // TASK-LEVEL gates: 1 (DevOps), 2 (SRE), 4 (Fuzz), 5 (Property), 6w (Integration), 7w (Chaos), 8 (Review)
      "devops": { "status": "pending|completed", ... },
      "sre": { "status": "..." },
      "fuzz_testing": { "status": "..." },
      // ...
    },
    "subtasks": [{
      "id": "ST-001-01",
      "gate_progress": {
        // SUBTASK-LEVEL gates: 0 (Implementation), 3 (Unit Testing), 9 (Validation)
        "implementation": { "status": "pending|completed", "tdd_red": {...}, "tdd_green": {...} },
        "unit_testing": { "status": "...", "coverage_actual": 87.5 },
        "validation": { "status": "...", "result": "approved|rejected" }
      }
    }]
  }]
}
```

### 3.3 Cycle-level `visual_report_granularity` setting

```json
{
  "visual_report_granularity": "task"  // default; allow "subtask" as opt-in
}
```

### 3.4 Task-level accumulated metrics (for cycle-end dev-report)

```json
{
  "tasks": [{
    "id": "T-001",
    "accumulated_metrics": {
      "gate_durations_ms": {"implementation": 12000, "devops": 3000, ...},
      "review_iterations": 1,
      "testing_iterations": 1,
      "issues_by_severity": {"CRITICAL": 0, "HIGH": 0, "MEDIUM": 2, "LOW": 5}
    }
  }]
}
```

Replaces the need to dispatch `ring:dev-report` per task.

---

## 4. File-by-File Edit List

Each entry specifies: **file path**, **which section to edit**, **current behavior**, **new behavior**, and **verification check**.

### 4.1 `dev-team/skills/dev-cycle/SKILL.md` (3428 lines — the big one)

**Heaviest changes. Sections affected: 14. Estimated net line delta: ~+150 lines (new cache step + cadence comments) −400 lines (removed read-verify blocks, removed Gate 0.5 section, simplified per-subtask loops).**

#### Edit 4.1.1 — Update `version` in state schema

- **Section:** "State File Structure" (~line 556)
- **Change:** `"version": "1.0.0"` → `"version": "1.1.0"`
- **Why:** Schema additions in Section 3 of this plan.

#### Edit 4.1.2 — Add Step 1.5 "Standards Pre-Cache"

- **Section:** Between "Step 1: Initialize or Resume" and existing "Step 1.5: Detect External Dependencies"
- **Rename existing Step 1.5** → **Step 1.6: Detect External Dependencies**
- **New Step 1.5 content:**

```text
## Step 1.5: Standards Pre-Cache (MANDATORY)

Cache all standards URLs the cycle will need, ONCE, into state.cached_standards.
Sub-skills read from this cache instead of calling WebFetch themselves.

Required URLs to pre-fetch (MUST succeed all):
1. https://raw.githubusercontent.com/LerianStudio/ring/main/CLAUDE.md
2. Language-specific:
   - If Go project: golang.md, golang/core.md, golang/bootstrap.md, golang/domain.md,
     golang/api-patterns.md, golang/security.md, golang/quality.md,
     golang/multi-tenant.md, golang/testing-fuzz.md, golang/testing-property.md,
     golang/testing-integration.md, golang/testing-chaos.md
   - If TypeScript backend: typescript.md, typescript/multi-tenant.md
3. devops.md
4. sre.md
5. migration-safety.md (if SQL migrations detected in project)

For each URL:
  WebFetch: [URL]
  Write to state.cached_standards[URL] = {
    "fetched_at": current_iso_timestamp,
    "content": <fetched content>
  }

MANDATORY: Save state to file after cache populated.

Blocker: If ANY URL fails to fetch, STOP cycle and report. Cache MUST be complete.
```

#### Edit 4.1.3 — Remove Step 3: "Verify persistence (MANDATORY - use Read tool)"

- **Section:** "After every Gate Transition" (~lines 936–956)
- **Current text:**
  ```yaml
  # Step 3: Verify persistence (MANDATORY - use Read tool)
  Read tool:
    file_path: [state.state_path]
  # Confirm current_gate and gate_progress match expected values
  ```
- **Action:** Delete this block entirely. Keep Steps 1 (update object) and 2 (Write tool).
- **Also delete:** "Verification Command" section (~lines 1008–1015) describing the "After each gate, the state file MUST reflect..." verification.
- **Anti-Rationalization Table for State Persistence** (~lines 998–1006): Keep the table but update the entry "I updated the state variable" to remove reference to "verification fails".

#### Edit 4.1.4 — Merge Gate 0.5 into Gate 0 exit criteria

- **Sections affected:**
  - "The 10 Gates" table (~line 450): Remove row for Gate 0.5 as separate entry; add footnote "Gate 0 includes delivery verification exit criteria (formerly Gate 0.5)."
  - "Gate Completion Definition (HARD GATE)" table (~line 398): Remove Gate 0.5 row; expand Gate 0 row to include "Delivery verification: all requirements delivered, 0 dead code items."
  - **Delete Step 2.5 entirely** (~lines 2001–2068): The whole "Step 2.5: Gate 0.5 - Delivery Verification (Per Execution Unit)" section.
  - **Update Step 2.3 "Gate 0 Complete"** (~lines 1947–2000): After "Standards compliance gaps" block, add new "Delivery Verification Exit Check" block:

```text
### Step 2.3.1: Delivery Verification Exit Check (MANDATORY before Gate 1)

After Gate 0 PASS, run delivery verification AS EXIT CRITERIA (not as separate gate):

REQUIRED: Invoke ring:dev-implementation skill's exit verifier with:
  unit_id: state.current_unit.id
  requirements: state.current_unit.acceptance_criteria
  files_changed: agent_outputs.implementation.files_changed
  gate0_handoff: agent_outputs.implementation

Expected result: PASS | PARTIAL | FAIL

IF PASS:
  → Update state.tasks[current].subtasks[current].gate_progress.implementation.delivery_verified = true
  → Proceed to Gate 1
IF PARTIAL or FAIL:
  → Return to Step 2.2 with explicit fix instructions (max 2 retries)
  → After 2 retries → escalate to user

No state.gate_progress.delivery_verification field — delivery verification is now a sub-check of implementation, tracked inline.
```

- **State Persistence Checkpoints table** (~line 960): Remove the row "Gate 0.5 (Delivery Verification)".
- **Agent Modification Verification sections**: Search for any other references to "Gate 0.5" and update to "Gate 0 exit criteria".

#### Edit 4.1.5 — Reclassify Gates 1, 2, 4, 5, 6(w), 7(w), 8 to TASK-level

- **Sections affected:** Step 3 through Step 10 (the per-unit gate execution steps).
- **Strategy:** Keep each gate's inner logic intact (agent dispatch, validation, etc.). Change only the LOOP that wraps them.

**Current loop structure:**
```
for each task:
  for each subtask (or task itself if no subtasks):
    Gate 0 → Gate 0.5 → Gate 1 → Gate 2 → Gate 3 → Gate 4 → Gate 5 → Gate 6(w) → Gate 7(w) → Gate 8 → Gate 9
  end subtask loop
end task loop
end of cycle: Gate 6(exec) + Gate 7(exec) + multi-tenant verify + final commit
```

**New loop structure:**
```
for each task:
  for each subtask (or task itself if no subtasks):
    Gate 0 (includes delivery verification exit check) → Gate 3 → Gate 9
    → Subtask-level visual report NOT generated (see Edit 4.1.6)
    → Subtask checkpoint (if execution_mode = manual_per_subtask)
  end subtask loop

  # TASK-LEVEL GATES (run once per task after all subtasks' 0/3/9 complete)
  Gate 1 (DevOps) → Gate 2 (SRE) → Gate 4 (Fuzz) → Gate 5 (Property) →
  Gate 6 write (Integration) → Gate 7 write (Chaos) → Gate 8 (Review, 8 reviewers) →
  Task-level visual report
  → Task checkpoint (if execution_mode = manual_per_task or manual_per_subtask)
end task loop

end of cycle: Gate 6(exec) + Gate 7(exec) + multi-tenant verify + cycle-end dev-report + final commit
```

**Specific edits to Step headings:**

- **Step 2 (Gate 0):** Keep header as "Per Execution Unit" but clarify: "Execution unit is always a subtask (or task-itself if no subtasks)."
- **Step 3 (Gate 1 DevOps):** Change heading "Step 3: Gate 1 - DevOps (Per Execution Unit)" → **"Step 3: Gate 1 - DevOps (Per Task — after all subtasks complete Gate 0 + Gate 3 + Gate 9)"**. Add explicit note at top:
  ```
  ⛔ CADENCE: This gate runs ONCE per task, NOT per subtask.
  Input `implementation_files` is the UNION of all subtasks' changed files.
  ```
- **Step 4 (Gate 2 SRE):** Same cadence note — "Per Task".
- **Step 5 (Gate 3 Unit Testing):** Keep as "Per Execution Unit" (subtask-level, unchanged).
- **Step 6 (Gate 4 Fuzz):** Change to "Per Task". Input is union of files changed in all subtasks of this task.
- **Step 7 (Gate 5 Property):** Change to "Per Task".
- **Step 8 (Gate 6 Integration write):** Change to "Per Task". (Execution at end-of-cycle stays the same.)
- **Step 9 (Gate 7 Chaos write):** Change to "Per Task".
- **Step 10 (Gate 8 Review):** Change to "Per Task". Reviewers see cumulative diff of all subtasks in the task.
- **Step 11 (Gate 9 Validation):** Keep as "Per Execution Unit" (subtask-level).

**Input preparation for task-level gates** (e.g., Step 3.1 "Prepare Input for ring:dev-devops Skill"):

```yaml
devops_input = {
  unit_id: state.tasks[current_task_index].id,  # TASK id, not subtask id
  language: state.tasks[current_task_index].language,
  service_type: state.tasks[current_task_index].service_type,
  implementation_files: [
    # UNION of files_changed across all subtasks of this task
    ...state.tasks[current_task_index].subtasks.flatMap(st =>
      st.gate_progress.implementation.files_changed
    )
  ],
  gate0_handoffs: state.tasks[current_task_index].subtasks.map(st =>
    st.gate_progress.implementation
  ),  # ARRAY of subtask handoffs, not single
  ...
}
```

Apply the same "aggregate from subtasks" pattern to devops, sre, unit-testing (if cross-subtask coverage), fuzz, property, integration, chaos, review inputs.

#### Edit 4.1.6 — Remove per-subtask visual reports

- **Section:** Step 11.1 "Execution Unit Approval (Conditional)" — Step 0b "VISUAL CHANGE REPORT (MANDATORY - before checkpoint)" (~lines 3016–3032)
- **Action:** Replace the entire Step 0b block with:

```text
0b. **VISUAL CHANGE REPORT (subtask-level — OPT-IN ONLY):**
   - Default: SKIP per-subtask visual report. Task-level aggregate report is generated in Step 11.2.
   - Opt-in: If `state.visual_report_granularity == "subtask"`, generate per-subtask report
     as previously documented. Default value is "task".
   - Rationale: Task-level aggregate covers all subtasks' diffs; per-subtask reports are
     rarely consumed and cost one visualize dispatch each.
```

- **Section:** Step 11.2 "Task Approval Checkpoint" — Step 0b "VISUAL CHANGE REPORT (MANDATORY)" (~lines 3056–3070)
- **Action:** Keep as-is. This is the task-level report, which we're keeping.

#### Edit 4.1.7 — Remove per-task dev-report dispatch

- **Section:** Step 11.2, point 2 "⛔ MANDATORY: Run ring:dev-report skill" (~lines 3087–3121)
- **Action:** Replace the entire "point 2" block with:

```text
2. **Accumulate task metrics into state (NO dev-report dispatch here):**

   Write into state.tasks[current_task_index].accumulated_metrics:
   - gate_durations_ms: {gate_name: duration_ms for each completed gate}
   - review_iterations: state.tasks[current].gate_progress.review.iterations
   - testing_iterations: sum across all testing gates
   - issues_by_severity: {CRITICAL, HIGH, MEDIUM, LOW counts from Gate 8 output}

   Set state.tasks[current].feedback_loop_completed = true
   (Actual dev-report dispatch happens ONCE at cycle end in Step 12.1.)

   MANDATORY: Save state to file.

   Rationale: Feedback analysis is stronger on aggregate data. A single cycle-end
   dev-report run produces the same or better insights than N per-task runs.
```

- **Update Anti-Rationalization table in this section** (~lines 3110–3116): Replace all 5 rows with one entry:
  | Rationalization | Why It's WRONG | Required Action |
  |---|---|---|
  | "Should dispatch dev-report now" | dev-report runs ONCE at cycle end (Step 12.1). Per-task metrics are accumulated into state, not analyzed here. | **Accumulate metrics into state, proceed to next task** |

#### Edit 4.1.8 — Step 12.1 Final Commit updates

- **Section:** Step 12.1 (~line 3286)
- **Change point 4 "⛔ MANDATORY: Run ring:dev-report skill for cycle metrics":**
  - Keep this block but add clarification: "This is the ONE and ONLY dev-report dispatch in the cycle. Per-task runs were removed (see Edit 4.1.7). ring:dev-report reads accumulated_metrics from all tasks in state and generates aggregate analysis."

#### Edit 4.1.9 — State Persistence Checkpoints table updates

- **Section:** "State Persistence Checkpoints" (~lines 957–994)
- **Changes:**
  - Remove row for "Gate 0.5 (Delivery Verification)".
  - Split "Gate 0.1 (TDD-RED)" / "Gate 0.2 (TDD-GREEN)" to clarify they write to `state.tasks[i].subtasks[j].gate_progress.implementation` (subtask-level).
  - Add new rows for task-level gates explicitly showing write path: `state.tasks[i].gate_progress.<gate_name>`.
  - Update "Step 11.2 (Task Approval)" row: `accumulated_metrics` populated; no dev-report dispatch.

#### Edit 4.1.10 — Gate Order Enforcement updates

- **Section:** "Gate Order Enforcement (HARD GATE)" (~line 428)
- **Change:** Rewrite the gate-order statement:
  > **"Gates MUST execute in this order within each task:
  > 1. Subtask loop: Gate 0 (with delivery verification exit check) → Gate 3 → Gate 9, per subtask.
  > 2. After all subtasks complete subtask-level gates: Gate 1 → Gate 2 → Gate 4 → Gate 5 → Gate 6(write) → Gate 7(write) → Gate 8, at task level.
  > End of cycle: Gate 6(execute) → Gate 7(execute) → Multi-Tenant Verify → dev-report → Final Commit."**
- Update the violation table to reflect new order.

#### Edit 4.1.11 — Anti-Rationalization additions

Add two new rows to the "Common Rationalizations - REJECTED" table (~line 351):

| Excuse | Reality |
|---|---|
| "I'll WebFetch standards again for this gate" | Standards are pre-cached at Step 1.5 in `state.cached_standards`. Read from state, do not re-fetch. |
| "Task-level Gate 8 misses bugs from subtask 2" | Cumulative task diff shows ALL subtasks' changes. Cross-subtask interactions are MORE visible, not less. |

---

### 4.2 `dev-team/skills/dev-cycle-frontend/SKILL.md` (1222 lines)

Identical treatment to 4.1 but for the 9-gate frontend cycle. Applies the same edits with frontend-specific gate names.

#### Edit 4.2.1 — Version bump + cached_standards schema

- Section: "State File Structure" (~line 584). `"version": "1.0.0"` → `"version": "1.1.0"`. Add `cached_standards` and per-subtask `gate_progress` fields per Section 3 of this plan.

#### Edit 4.2.2 — Add "Standards Pre-Cache" step

- Section: Between "UI Library Mode Detection" (~line 149) and "Backend Handoff Loading" (~line 182)
- Insert identical Step 1.5 structure as Edit 4.1.2, but with frontend URLs:
  1. CLAUDE.md
  2. frontend.md
  3. frontend/testing-accessibility.md
  4. frontend/testing-visual.md
  5. frontend/testing-e2e.md
  6. frontend/testing-performance.md
  7. devops.md
  8. sre.md
  9. typescript.md (if BFF layer detected)

#### Edit 4.2.3 — Remove Read-after-Write verification

- Section: "After every Gate Transition" (~lines 841–856). Delete the `# Step 3: Verify persistence` block.
- Section: Delete "Verification Command" anchor references (if any).

#### Edit 4.2.4 — Reclassify Gates 1, 2, 4, 5, 6, 7 to task-level

- Steps 3 through 9 (per-unit gate execution steps). Apply same "loop restructure" from Edit 4.1.5.
- New loop structure for frontend:
  ```
  for each task:
    for each subtask:
      Gate 0 (Implementation) → Gate 3 (Unit Testing) → Gate 8 (Validation)
    end subtask loop

    # TASK-LEVEL
    Gate 1 (DevOps) → Gate 2 (Accessibility) → Gate 4 (Visual) → Gate 5 (E2E) →
    Gate 6 (Performance) → Gate 7 (Review, 5 reviewers) →
    Task-level visual report → Task checkpoint
  end task loop
  ```

#### Edit 4.2.5 — Remove per-subtask visual reports

- Section: Unit Checkpoint "VISUAL CHANGE REPORT (MANDATORY - before checkpoint question)" (~lines 902–918)
- Same treatment as Edit 4.1.6: default to skip, opt-in via `visual_report_granularity = "subtask"`.

#### Edit 4.2.6 — Gate Completion Definition updates

- Section: "Gate Completion Definition (HARD GATE)" (~line 473). Update table to show which gates are subtask-level vs task-level. Preserve all quality thresholds.

#### Edit 4.2.7 — Update "The 9 Gates" table

- Add a "Cadence" column to the table at ~line 388 showing subtask/task for each gate.

---

### 4.3 `dev-team/skills/dev-implementation/SKILL.md` (776 lines)

Gate 0's sub-skill. Needs to absorb delivery verification exit criteria.

#### Edit 4.3.1 — Read from cached_standards, not WebFetch

- **Sections affected:**
  - Standards loading at lines 219–223, 326–349, 344–348, 348
- **Current pattern:** Each standards URL triggers a WebFetch call.
- **New pattern:**
  ```yaml
  For each required standards URL:
    IF state.cached_standards[url] exists:
      → Read content from state.cached_standards[url].content
      → Log: "Using cached standard: {url} (fetched {state.cached_standards[url].fetched_at})"
    ELSE:
      → WebFetch url (fallback — should not happen if orchestrator ran Step 1.5)
      → Log warning: "Standard {url} was not pre-cached; fetched inline"
  ```
- Add a new "Standards Source" section at the top of the "Standards Loading" block explaining the cache-first pattern.

#### Edit 4.3.2 — Add Delivery Verification exit check (absorbing Gate 0.5)

- **Section:** After "Step 6: TDD-GREEN" (~line 629), BEFORE "Handoff to Next Gate" section (~line 663).
- **Action:** Insert new Step 7: "Delivery Verification Exit Check".
- **Content:** Inline the core logic from `dev-delivery-verification/SKILL.md`:

```text
## Step 7: Delivery Verification Exit Check (MANDATORY — absorbed from former Gate 0.5)

Before emitting the "Ready for Gate 1: YES" handoff, verify that every requirement in the
task/subtask's acceptance criteria is DELIVERED (reachable, integrated, not dead code).

Checks to run (copied from deprecated dev-delivery-verification skill):

1. **Requirement Coverage Matrix**
   For each acceptance criterion in input.requirements:
     - Locate the file(s) that implement it
     - Verify it's callable from a public entry point (handler, route, CLI command)
     - Mark as ✅ DELIVERED | ⚠️ PARTIAL | ❌ NOT DELIVERED

2. **Dead Code Detection**
   For each newly-created struct/interface/function in files_changed:
     - Verify it's referenced from at least one caller (other than tests)
     - If created but uncalled → dead code item

3. **Integration Verification**
   - Check that new middleware is wired into router/server
   - Check that new repositories are registered in DI container
   - Check that new types are exported where consumers expect them

Output to handoff:
  delivery_verification: {
    result: "PASS" | "PARTIAL" | "FAIL",
    requirements_total: N,
    requirements_delivered: N,
    requirements_missing: N,
    dead_code_items: N
  }

IF result != "PASS":
  → Re-run Step 6 (TDD-GREEN) with remediation instructions
  → Max 2 retries before escalating to orchestrator
```

- Full detailed checks should be copied from `dev-delivery-verification/SKILL.md`. Since that file stays preserved (see Edit 4.4), the implementer can reference it rather than duplicating all 902 lines.

#### Edit 4.3.3 — Update Handoff to Next Gate

- **Section:** "## Handoff to Next Gate" (~lines 663–670)
- **Add field:** `delivery_verification: {...}` to the handoff output schema.

#### Edit 4.3.4 — Update frontmatter `description`

- Add to description: "Includes delivery verification exit criteria (merged from deprecated ring:dev-delivery-verification)."

---

### 4.4 `dev-team/skills/dev-delivery-verification/SKILL.md` (902 lines)

**Do NOT delete.** Mark as deprecated-but-preserved.

#### Edit 4.4.1 — Add deprecation banner

- **Section:** Top of file, immediately after frontmatter.
- **Content:**

```markdown
---

> ⚠️ **DEPRECATION NOTICE (since "prancy Bentley" speedup)**
>
> This skill's functionality has been **inlined into `ring:dev-implementation` as Step 7:
> Delivery Verification Exit Check**. New cycles should NOT dispatch this skill as a
> separate gate — the checks run as exit criteria of Gate 0.
>
> This file is preserved for:
> 1. Historical reference of the full check list
> 2. External consumers that may still reference the skill by name
> 3. Potential future use as a standalone audit tool outside the cycle
>
> If you are modifying dev-cycle or dev-implementation, do NOT add dispatches to this skill.

---
```

#### Edit 4.4.2 — Update frontmatter

- Set `trigger` to: `"Deprecated — use ring:dev-implementation instead (includes these checks as Gate 0 exit criteria)."`
- Add `skip_when: "always — this skill is preserved but not dispatched in normal cycles."`

---

### 4.5 `dev-team/skills/dev-devops/SKILL.md` (494 lines)

Gate 1's sub-skill. Now runs at task cadence.

#### Edit 4.5.1 — Read from cached_standards

- Section: Line 239 WebFetch call.
- Same treatment as Edit 4.3.1: cache-first pattern.

#### Edit 4.5.2 — Accept task-level input

- Section: "Input Schema" (~line 35–60) and "Prepare Input" in the orchestrator call pattern.
- **Change:** `unit_id` parameter interpretation: document that this is now always a TASK id, never a subtask id.
- **Add field:** `implementation_files: array` (union of all subtasks' changed files).
- **Add field:** `gate0_handoffs: array` (array of per-subtask implementation handoffs).
- Update all prompt templates that reference "the subtask's files" to "the task's files (union of subtasks)".

#### Edit 4.5.3 — Update frontmatter

- Add to description: "Runs at TASK cadence (after all subtasks complete Gate 0)."

---

### 4.6 `dev-team/skills/dev-sre/SKILL.md` (590 lines)

Gate 2's sub-skill. Now runs at task cadence.

Apply identical treatment to Edit 4.5:
- **4.6.1:** Cached standards read (lines 195–196).
- **4.6.2:** Accept task-level input (union files).
- **4.6.3:** Frontmatter update.

---

### 4.7 `dev-team/skills/dev-unit-testing/SKILL.md` (586 lines)

Gate 3's sub-skill. **Stays at subtask cadence.** Only WebFetch cache change needed.

#### Edit 4.7.1 — Read from cached_standards

- Lines 207–210 (golang.md + typescript.md WebFetch). Same cache-first pattern.

No cadence or input changes.

---

### 4.8 `dev-team/skills/dev-fuzz-testing/SKILL.md` (227 lines)

Gate 4's sub-skill. Now task cadence.

- **4.8.1:** Cached standards read (lines 116–119).
- **4.8.2:** Accept task-level input. Input `implementation_files` = union.
- **4.8.3:** Frontmatter update.

---

### 4.9 `dev-team/skills/dev-property-testing/SKILL.md` (241 lines)

Gate 5's sub-skill. Now task cadence.

Identical treatment to 4.8.

---

### 4.10 `dev-team/skills/dev-integration-testing/SKILL.md` (550 lines)

Gate 6's sub-skill (write mode). Now task cadence for write mode.
**Execute mode stays at cycle-end** (unchanged).

- **4.10.1:** Cached standards read (lines 273–276).
- **4.10.2:** Accept task-level input. In write mode, input scope is all subtasks' changes within the task.
- **4.10.3:** Frontmatter update — clarify "write mode runs per task, execute mode runs per cycle."

---

### 4.11 `dev-team/skills/dev-chaos-testing/SKILL.md` (291 lines)

Gate 7's sub-skill (write mode). Now task cadence for write mode.

Same treatment as 4.10.

---

### 4.12 `default/skills/codereview/SKILL.md` (path to verify before edit)

Gate 8's sub-skill. Now runs at task cadence.

#### Edit 4.12.0 — Pre-edit verification

- **Action first:** Read `default/skills/codereview/SKILL.md` to confirm path. If not there, `grep -r "name: ring:codereview" default/ dev-team/` to locate.
- **Expected location:** `default/skills/codereview/SKILL.md` (per CLAUDE.md documentation sync checklist).

#### Edit 4.12.1 — Update input expectations

- All 8 reviewers currently receive per-subtask diffs. Change to receive **cumulative task diff**.
- Input schema additions:
  - `scope: "task"` (vs current implicit subtask scope)
  - `task_id: string`
  - `subtask_ids: array` (all subtasks in the task)
  - `cumulative_diff_range: {base_sha, head_sha}` where base_sha is before the first subtask, head_sha is after the last.

#### Edit 4.12.2 — Reviewer dispatch context

- In the parallel dispatch block that sends to the 8 reviewers, add context:
  ```
  **REVIEW SCOPE: TASK-LEVEL**
  This review covers the CUMULATIVE diff of task {task_id}, which includes changes from
  {N} subtasks: {subtask_ids}. Review the full task as an integrated unit; subtask
  boundaries are implementation detail, not review boundaries.
  ```

#### Edit 4.12.3 — Read from cached_standards

- Each reviewer loads its own standards. All should read from `state.cached_standards` via the cache-first pattern.

---

### 4.13 `dev-team/skills/dev-validation/SKILL.md` (323 lines)

Gate 9's sub-skill. **Stays at subtask cadence.** No changes needed other than:

#### Edit 4.13.1 — Note in description

- Add to frontmatter description: "Runs at subtask (execution unit) cadence. Task-level approval happens in dev-cycle Step 11.2."

---

### 4.14 `dev-team/skills/dev-report/SKILL.md` (627 lines)

Now runs ONCE per cycle, not per task.

#### Edit 4.14.1 — Remove per-task entry path

- **Section:** Input/invocation context (top of file).
- **Add:** Explicit statement that this skill is invoked exactly ONCE per cycle, at Step 12.1 of dev-cycle.
- Per-task invocations have been removed.

#### Edit 4.14.2 — Read accumulated_metrics from state

- **Section:** Step 1 (~lines 263–304) — current state read.
- **Add:** New source — `state.tasks[*].accumulated_metrics` replaces the per-task feedback data that previously would have been computed at per-task dispatch time.
- **Semantic:** Instead of analyzing one task's agent_outputs, analyze ALL tasks' aggregated metrics + the full agent_outputs for the cycle.

#### Edit 4.14.3 — Update prompt to prompt-quality-reviewer

- The dispatched `ring:prompt-quality-reviewer` agent should receive aggregated cycle data, not single-task data.
- Update prompt template accordingly.

---

### 4.15 `dev-team/skills/dev-frontend-accessibility/SKILL.md` (232 lines)

Now task cadence.

- **4.15.1:** Cached standards read (lines 113–119).
- **4.15.2:** Accept task-level input (union across subtasks).
- **4.15.3:** Frontmatter update.

---

### 4.16 `dev-team/skills/dev-frontend-visual/SKILL.md` (236 lines)

Now task cadence.

Same treatment as 4.15.

---

### 4.17 `dev-team/skills/dev-frontend-e2e/SKILL.md` (255 lines)

Now task cadence.

Same treatment as 4.15.

---

### 4.18 `dev-team/skills/dev-frontend-performance/SKILL.md` (257 lines)

Now task cadence.

Same treatment as 4.15.

---

### 4.19 `dev-team/skills/dev-refactor/SKILL.md` (1124 lines)

Introduce clustering at Step 6 + 7.

#### Edit 4.19.1 — Add clustering rule to Step 6

- **Section:** "Step 6: Map Findings to Tasks (1:1)" (~lines 850–885)
- **Rename section to:** "Step 6: Map Findings to Tasks (Clustered by file + pattern)"
- **Replace the 1:1 Mapping Rule** with:

```markdown
## Clustering Rule (replaces former 1:1 mapping)

Findings are clustered into REFACTOR tasks by the tuple `(file_path, pattern_category)`.

### Clustering Algorithm

1. Group all findings by their `file` field (from agent report).
2. Within each file group, sub-group by `pattern_category`:
   - `pattern_category` is derived from the finding's "Category" field
   - (e.g., "error-handling", "logging", "multi-tenant", "file-size", etc.)
3. Each `(file, pattern_category)` tuple becomes ONE REFACTOR-XXX task.
4. If a file has findings in 3 different pattern categories → 3 REFACTOR tasks for that file.
5. If a pattern category spans multiple files → one task per (file, pattern) pair (no cross-file clustering).

### Traceability Preservation (MANDATORY)

Every REFACTOR task MUST include a `findings:` array listing all FINDING-XXX IDs it covers:

```markdown
## REFACTOR-005: Error Wrapping Pattern in internal/handler/user.go

**Cluster Key:** (internal/handler/user.go, error-handling)
**Findings Covered:** [FINDING-012, FINDING-015, FINDING-018]
**Severity:** HIGH  (max of covered findings' severities)
**Effort:** {sum of covered findings' effort estimates}

### Findings Breakdown
| Finding | Line | Description | Status |
|---------|------|-------------|--------|
| FINDING-012 | user.go:45 | `return err` without wrap | pending |
| FINDING-015 | user.go:78 | `return err` without wrap | pending |
| FINDING-018 | user.go:102 | `return err` without wrap | pending |
```

During dev-cycle execution, each finding's status is tracked per-line inside the
REFACTOR task. A REFACTOR task completes only when all covered findings are resolved.

### Mapping Verification (updated)

Before proceeding to Step 7, verify:
- Total FINDING-XXX in findings.md: X
- Total REFACTOR-XXX in tasks.md: Y (Y ≤ X — clustering reduces count)
- Every FINDING-XXX appears in exactly ONE REFACTOR task's `findings:` array
- NO FINDING-XXX is missing from all REFACTOR tasks
- NO FINDING-XXX appears in multiple REFACTOR tasks

If any finding is orphan or duplicated → STOP. Fix clustering.
```

#### Edit 4.19.2 — Update Anti-Rationalization table

- **Section:** Anti-Rationalization Table for Step 6 (~lines 876–884)
- **Replace entries** with:

| Rationalization | Why It's WRONG | Required Action |
|---|---|---|
| "Just keep 1:1 mapping, it's simpler" | 1:1 mapping multiplies cycle cost ~5x for typical refactors. Clustering preserves traceability. | **Apply (file, pattern) clustering** |
| "Cluster across files to reduce tasks more" | Cross-file clustering hides file-specific blast radius. Only cluster within a file. | **Cluster only within file** |
| "Skip the findings: array, it's redundant" | Without traceability array, findings get lost inside tasks. | **ALWAYS populate findings: array** |
| "One finding can be in multiple tasks" | Duplicates cause double-fix attempts. One finding → one task. | **Each FINDING in exactly one REFACTOR** |

#### Edit 4.19.3 — Update Step 7 tasks.md template

- **Section:** "Step 7: Generate tasks.md" (~line 889)
- **Update the markdown template** to show the new structure (cluster_key + findings breakdown table).

#### Edit 4.19.4 — Update handoff to dev-cycle

- **Section:** "Step 10: Handoff to ring:dev-cycle" (~line 1044)
- **No change** to the invocation itself, but add a note:

```
Note: Each REFACTOR task covering N findings is treated as ONE execution unit with N
internal acceptance criteria. dev-cycle does not need to know about clustering — it
consumes the task as-if it were any other task.
```

---

### 4.20 `dev-team/skills/dev-refactor-frontend/SKILL.md` (1305 lines)

Apply identical clustering treatment to 4.19.

- **4.20.1:** Step 6 clustering rule (section ~line 989).
- **4.20.2:** Anti-rationalization table update (~line 1015).
- **4.20.3:** Step 7 tasks.md template update (~line 1028).
- **4.20.4:** Handoff note to `ring:dev-cycle-frontend`.

---

### 4.21 Shared patterns — UPDATES (existing files)

#### Edit 4.21.1 — `dev-team/skills/shared-patterns/standards-coverage-table.md`

- **No structural change.** But add a brief note in the "Standards Source" section:

```markdown
## Standards Source (new, since "prancy Bentley" speedup)

Agents and sub-skills MUST read standards from `state.cached_standards` (populated by
dev-cycle Step 1.5) instead of calling WebFetch directly. This eliminates ~15–25
redundant network fetches per cycle.

If a sub-skill is invoked outside of a dev-cycle context (standalone testing, manual
dispatch), it MAY fall back to direct WebFetch — but it MUST log a warning and
operators should expect slower execution.
```

#### Edit 4.21.2 — `dev-team/skills/shared-patterns/shared-orchestrator-principle.md`

- Add new section "Gate Cadence Classification":

```markdown
## Gate Cadence Classification

Gates in dev-cycle operate at three cadences:

| Cadence | Gates (backend) | Gates (frontend) |
|---------|-----------------|------------------|
| **Subtask** | 0 (impl + delivery verify), 3 (unit test), 9 (validation) | 0, 3, 8 |
| **Task** | 1 (devops), 2 (sre), 4 (fuzz), 5 (property), 6 write, 7 write, 8 (review) | 1, 2, 4, 5, 6, 7 |
| **Cycle** | 6 execute, 7 execute, multi-tenant verify, dev-report, final commit | (minimal cycle-level) |

Sub-skills that run at task cadence receive input aggregated across all subtasks of
the task (e.g., `implementation_files` = UNION of all subtasks' changed files).

Sub-skills that run at subtask cadence receive input scoped to that single subtask.
```

---

### 4.22 New files to create

#### New file 4.22.1 — `dev-team/skills/shared-patterns/standards-cache-protocol.md`

Documents the cache-first WebFetch pattern that all sub-skills now follow.

```markdown
---
name: shared-pattern:standards-cache-protocol
description: Protocol for reading cached standards from cycle state instead of WebFetching directly.
---

# Standards Cache Protocol

## Purpose

Eliminate redundant WebFetch calls during a dev-cycle by pre-caching all required
standards at cycle start (dev-cycle Step 1.5) and having sub-skills read from state.

## Protocol

### For Sub-Skills

When a sub-skill needs a standards document:

```yaml
STEP 1: Check state cache
  IF state.cached_standards[URL] exists:
    content = state.cached_standards[URL].content
    log: "Using cached standard: {URL} (fetched {fetched_at})"
    proceed with content
  ELSE:
    goto STEP 2

STEP 2: Fallback WebFetch (only if cache miss)
  log WARNING: "Standard {URL} not in cache; fetching inline"
  content = WebFetch(URL)
  proceed with content
```

### For Orchestrators (dev-cycle, dev-cycle-frontend)

At Step 1.5 of the cycle:
1. Detect project stack (Go / TypeScript / Frontend)
2. Build URL list (see dev-cycle Step 1.5 for current list)
3. WebFetch each URL once
4. Write to `state.cached_standards[URL] = {fetched_at, content}`
5. MANDATORY: Save state to file
6. Blocker if ANY URL fails to fetch

## Why

Before: ~15–25 WebFetch calls per cycle (one per sub-skill dispatch). Prompt cache TTL
of 5 min is regularly exceeded, causing repeated network fetches of identical content.

After: Exactly ONE WebFetch per unique URL per cycle. Same content, ~5x fewer network
operations.

## Safety

If the cache mechanism fails or is bypassed:
- Sub-skills fall back to direct WebFetch (with warning log).
- No correctness regression; only performance regression.
- Operators can monitor "Standard {URL} not in cache" warnings to detect misconfigurations.
```

#### New file 4.22.2 — `dev-team/skills/shared-patterns/gate-cadence-classification.md`

Dedicated reference for the cadence taxonomy. Could alternatively live as a section in `shared-orchestrator-principle.md` (see Edit 4.21.2) — decide during implementation. If creating standalone:

```markdown
---
name: shared-pattern:gate-cadence-classification
description: Classification of dev-cycle gates by execution cadence (subtask/task/cycle).
---

# Gate Cadence Classification

## Three Cadences

### Subtask Cadence
Runs for every subtask (or task itself if no subtasks). Input scoped to a single unit.
- Backend: Gate 0 (Implementation + delivery verify), Gate 3 (Unit Testing), Gate 9 (Validation)
- Frontend: Gate 0 (Implementation), Gate 3 (Unit Testing), Gate 8 (Validation)

### Task Cadence
Runs once per task, after all subtasks complete their subtask-level gates. Input is
UNION of all subtasks' changes.
- Backend: Gate 1 (DevOps), Gate 2 (SRE), Gate 4 (Fuzz), Gate 5 (Property), Gate 6 write
  (Integration), Gate 7 write (Chaos), Gate 8 (Review — 8 reviewers)
- Frontend: Gate 1 (DevOps), Gate 2 (Accessibility), Gate 4 (Visual), Gate 5 (E2E),
  Gate 6 (Performance), Gate 7 (Review — 5 reviewers)

### Cycle Cadence
Runs once per cycle at cycle end.
- Backend: Gate 6 execute (Integration), Gate 7 execute (Chaos), Multi-Tenant Verify,
  dev-report, Final Commit
- Frontend: Final Commit (minimal cycle-level processing)

## Why Cadence Matters

Running task-cadence gates at subtask cadence causes redundant work: Dockerfile
validation, observability coverage checks, fuzz seed generation, and cumulative diff
review all have outputs that stabilize at the task boundary, not the subtask boundary.
The task-level cumulative diff is strictly more informative for review than N
per-subtask fragments because interaction bugs between subtasks are visible only in
the cumulative view.

## Implementation Requirement

Sub-skills that run at task cadence MUST accept aggregated input:
- `implementation_files`: array (union across all subtasks of the task)
- `gate0_handoffs`: array (one entry per subtask)

Sub-skills that run at subtask cadence MUST continue to accept scoped input:
- `implementation_files`: array (this subtask's changes only)
- `gate0_handoff`: object (this subtask's handoff)
```

---

## 5. Cross-File Consistency Checklist

After all edits, verify the following stays consistent across files:

- [ ] `state.version = "1.1.0"` in dev-cycle/SKILL.md AND dev-cycle-frontend/SKILL.md.
- [ ] Every sub-skill has a "Standards Source" section describing cache-first pattern (reference Edit 4.21.1 note).
- [ ] Frontmatter `description` field of every task-cadence sub-skill mentions "Runs at TASK cadence".
- [ ] All references to "Gate 0.5" in dev-cycle/SKILL.md are either deleted or changed to "Gate 0 exit criteria".
- [ ] Any grep for `Read tool:\n  file_path: \[state\.state_path\]` after a Write returns ZERO matches in dev-cycle/SKILL.md and dev-cycle-frontend/SKILL.md.
- [ ] standards-coverage-table.md has the new "Standards Source" section.
- [ ] shared-orchestrator-principle.md OR gate-cadence-classification.md exists with the cadence table.
- [ ] standards-cache-protocol.md exists in shared-patterns/.
- [ ] dev-delivery-verification/SKILL.md has deprecation banner.
- [ ] dev-implementation/SKILL.md has new Step 7 with delivery verification checks.
- [ ] dev-refactor + dev-refactor-frontend have clustering rule in Step 6.
- [ ] No reference to "ring:dev-delivery-verification" remains in dev-cycle/SKILL.md's gate dispatch logic.

---

## 6. Verification Plan

### 6.1 Static checks (grep-based)

Run these checks after all edits are applied. Each should return EXPECTED output:

```bash
# 1. Read-after-write removed
grep -c "Verify persistence (MANDATORY" dev-team/skills/dev-cycle/SKILL.md
# Expected: 0

grep -c "Verify persistence (MANDATORY" dev-team/skills/dev-cycle-frontend/SKILL.md
# Expected: 0

# 2. Gate 0.5 as separate step removed
grep -c "^## Step 2\.5: Gate 0\.5" dev-team/skills/dev-cycle/SKILL.md
# Expected: 0

# 3. Cached standards cache step added
grep -c "Standards Pre-Cache" dev-team/skills/dev-cycle/SKILL.md
# Expected: ≥1

grep -c "Standards Pre-Cache" dev-team/skills/dev-cycle-frontend/SKILL.md
# Expected: ≥1

# 4. cached_standards appears in state schema
grep -c "cached_standards" dev-team/skills/dev-cycle/SKILL.md
# Expected: ≥3 (schema def + step 1.5 + reference)

# 5. Cadence annotation on task-level gates
grep -c "Per Task" dev-team/skills/dev-cycle/SKILL.md
# Expected: ≥7 (for Gates 1,2,4,5,6w,7w,8)

# 6. Deprecation banner on dev-delivery-verification
grep -c "DEPRECATION NOTICE" dev-team/skills/dev-delivery-verification/SKILL.md
# Expected: 1

# 7. Delivery verification step inline in dev-implementation
grep -c "Delivery Verification Exit Check" dev-team/skills/dev-implementation/SKILL.md
# Expected: ≥1

# 8. Clustering rule in dev-refactor
grep -c "Clustering Rule" dev-team/skills/dev-refactor/SKILL.md
# Expected: ≥1

grep -c "Clustering Rule" dev-team/skills/dev-refactor-frontend/SKILL.md
# Expected: ≥1

# 9. Shared pattern files created
test -f dev-team/skills/shared-patterns/standards-cache-protocol.md
test -f dev-team/skills/shared-patterns/gate-cadence-classification.md
# Both should exist (or the latter content embedded in shared-orchestrator-principle.md)

# 10. dev-report per-task dispatch removed
grep -c 'Skill tool:\n    skill: "ring:dev-report"' dev-team/skills/dev-cycle/SKILL.md
# Expected: 1 (only in Step 12.1, cycle end — not in Step 11.2)
```

### 6.2 Functional smoke test

The safest functional test is a **real dev-cycle run** on a small, isolated feature.

**Test plan:**

1. **Baseline measurement (before any edits)**: Run `ring:dev-cycle` on a small synthetic task file with 1 task × 2 subtasks. Record:
   - Total wall-clock time
   - Number of agent dispatches (count from state file)
   - Number of WebFetch calls (from logs)
   - Number of state writes (from logs)

2. **Apply edits** per this plan.

3. **Post-edit measurement**: Run same dev-cycle on same task file. Record same metrics.

4. **Expected deltas:**
   - Wall-clock time: −40% to −50%
   - Agent dispatches: −60% to −75%
   - WebFetch calls: ≥ −80%
   - State writes: ≥ −50%
   - Output quality: Identical (same code produced, same tests pass, same review issues found)

5. **Quality verification** (CRITICAL — do not skip):
   - Diff the implementation files produced by baseline vs post-edit runs. Should be functionally equivalent (same behavior, may differ in comments/ordering).
   - Review issue counts should match or be reduced (not increased).
   - Coverage % should match baseline.

### 6.3 Frontend cycle smoke test

Same structure as 6.2 but with `ring:dev-cycle-frontend` on a small React component task.

### 6.4 dev-refactor clustering smoke test

Run `ring:dev-refactor` on a repo with a known set of findings (e.g., 10+ error-handling issues in the same file). Verify:
- tasks.md has fewer REFACTOR tasks than findings (clustering occurred).
- Every FINDING-XXX appears in exactly one REFACTOR task's `findings:` array.
- No orphan findings.
- No duplicate findings across tasks.

### 6.5 Resume-from-state test

Critical regression test: after edits, an interrupted cycle MUST still be resumable.

1. Start a dev-cycle.
2. Interrupt (e.g., kill process) mid-task, after subtask 1 but before subtask 2.
3. Run `/ring:dev-cycle --resume`.
4. Verify cycle continues from correct state, including reading `cached_standards` (not re-fetching), and correctly distinguishing subtask-level vs task-level gate progress.

---

## 7. Rollout Sequence (Recommended Execution Order)

Execute edits in this order to minimize risk and enable incremental verification:

### Phase R1 — Pure removals (lowest risk)

1. Edit 4.1.3 + 4.2.3: Remove read-after-write verification.
2. Edit 4.1.6 + 4.2.5: Remove per-subtask visual reports.
3. Run verification check 6.1 steps 1 and static grep checks.

**Checkpoint:** Smoke test 6.2 with just Phase R1 changes. Expect small speedup (~15%), zero quality change.

### Phase R2 — Standards caching (pure I/O optimization)

4. Create new file 4.22.1: `standards-cache-protocol.md`.
5. Edit 4.1.2 + 4.2.2: Add Step 1.5 Standards Pre-Cache.
6. Edit 4.21.1: Update standards-coverage-table.md with Standards Source section.
7. Edits 4.3.1, 4.5.1, 4.6.1, 4.7.1, 4.8.1, 4.9.1, 4.10.1, 4.11.1, 4.12.3, 4.15.1, 4.16.1, 4.17.1, 4.18.1: Cache-first pattern in each sub-skill.

**Checkpoint:** Smoke test 6.2. Expect additional ~10% speedup from eliminated WebFetch calls.

### Phase R3 — Gate 0.5 merge (low risk, structural)

8. Edit 4.4.1 + 4.4.2: Deprecation banner on dev-delivery-verification.
9. Edit 4.3.2, 4.3.3, 4.3.4: Add Step 7 to dev-implementation.
10. Edit 4.1.4: Remove Step 2.5 from dev-cycle.
11. Edit 4.1.10: Update gate order enforcement.

**Checkpoint:** Smoke test 6.2. Verify delivery verification still runs (just now inline).

### Phase R4 — dev-report aggregation

12. Edit 4.1.7: Remove per-task dev-report dispatch.
13. Edit 4.1.8: Update cycle-end dev-report to read accumulated_metrics.
14. Edit 4.14.1, 4.14.2, 4.14.3: dev-report reads aggregated data.

**Checkpoint:** Smoke test 6.2. Verify only one dev-report dispatch at cycle end.

### Phase R5 — Cadence migration (HIGHEST complexity)

15. Create new file 4.22.2: `gate-cadence-classification.md` (or embed in shared-orchestrator-principle.md per Edit 4.21.2).
16. Edit 4.21.2: Update shared-orchestrator-principle.md.
17. State schema update per Section 3 (adds `tasks[i].subtasks[j].gate_progress` and `tasks[i].accumulated_metrics`).
18. Edit 4.1.5 + 4.2.4: Restructure main loop in dev-cycle + dev-cycle-frontend.
19. Edit 4.1.9: Update State Persistence Checkpoints table.
20. Edits 4.5.2, 4.6.2, 4.8.2, 4.9.2, 4.10.2, 4.11.2, 4.12.1, 4.12.2, 4.15.2, 4.16.2, 4.17.2, 4.18.2: Task-level input in each task-cadence sub-skill.
21. Edits 4.5.3, 4.6.3, 4.8.3, 4.9.3, 4.10.3, 4.11.3, 4.15.3, 4.16.3, 4.17.3, 4.18.3: Frontmatter clarifications.
22. Edit 4.1.11: Anti-rationalization additions.

**Checkpoint:** Smoke test 6.2 AND 6.3 AND 6.5 (resume test). Expect remaining ~25% speedup.

### Phase R6 — Refactor clustering

23. Edit 4.19.1, 4.19.2, 4.19.3, 4.19.4: Clustering rule in dev-refactor.
24. Edit 4.20.1, 4.20.2, 4.20.3, 4.20.4: Clustering rule in dev-refactor-frontend.

**Checkpoint:** Smoke test 6.4 (clustering verification).

### Final phase — Documentation + Commit

25. Run full static check suite (6.1).
26. Run all smoke tests (6.2, 6.3, 6.4, 6.5).
27. Update CHANGELOG.md for dev-team plugin version bump.
28. Version bump in `.claude-plugin/marketplace.json` for ring-dev-team.
29. Commit per Ring's commit policy (use `ring:commit` skill — MUST NOT commit manually per CLAUDE.md rule 6).

---

## 8. Critical Files Reference

Full absolute paths for the implementing agent:

### Main SKILL files (heavy edits)
- `/Users/fredamaral/repos/lerianstudio/ring/dev-team/skills/dev-cycle/SKILL.md`
- `/Users/fredamaral/repos/lerianstudio/ring/dev-team/skills/dev-cycle-frontend/SKILL.md`
- `/Users/fredamaral/repos/lerianstudio/ring/dev-team/skills/dev-refactor/SKILL.md`
- `/Users/fredamaral/repos/lerianstudio/ring/dev-team/skills/dev-refactor-frontend/SKILL.md`

### Sub-skill files (moderate edits)
- `/Users/fredamaral/repos/lerianstudio/ring/dev-team/skills/dev-implementation/SKILL.md`
- `/Users/fredamaral/repos/lerianstudio/ring/dev-team/skills/dev-delivery-verification/SKILL.md`
- `/Users/fredamaral/repos/lerianstudio/ring/dev-team/skills/dev-devops/SKILL.md`
- `/Users/fredamaral/repos/lerianstudio/ring/dev-team/skills/dev-sre/SKILL.md`
- `/Users/fredamaral/repos/lerianstudio/ring/dev-team/skills/dev-unit-testing/SKILL.md`
- `/Users/fredamaral/repos/lerianstudio/ring/dev-team/skills/dev-fuzz-testing/SKILL.md`
- `/Users/fredamaral/repos/lerianstudio/ring/dev-team/skills/dev-property-testing/SKILL.md`
- `/Users/fredamaral/repos/lerianstudio/ring/dev-team/skills/dev-integration-testing/SKILL.md`
- `/Users/fredamaral/repos/lerianstudio/ring/dev-team/skills/dev-chaos-testing/SKILL.md`
- `/Users/fredamaral/repos/lerianstudio/ring/dev-team/skills/dev-validation/SKILL.md`
- `/Users/fredamaral/repos/lerianstudio/ring/dev-team/skills/dev-report/SKILL.md`
- `/Users/fredamaral/repos/lerianstudio/ring/dev-team/skills/dev-frontend-accessibility/SKILL.md`
- `/Users/fredamaral/repos/lerianstudio/ring/dev-team/skills/dev-frontend-visual/SKILL.md`
- `/Users/fredamaral/repos/lerianstudio/ring/dev-team/skills/dev-frontend-e2e/SKILL.md`
- `/Users/fredamaral/repos/lerianstudio/ring/dev-team/skills/dev-frontend-performance/SKILL.md`

### Default plugin (verify path first)
- `/Users/fredamaral/repos/lerianstudio/ring/default/skills/codereview/SKILL.md` (expected location)

### Shared patterns (updates + creates)
- `/Users/fredamaral/repos/lerianstudio/ring/dev-team/skills/shared-patterns/standards-coverage-table.md` (UPDATE)
- `/Users/fredamaral/repos/lerianstudio/ring/dev-team/skills/shared-patterns/shared-orchestrator-principle.md` (UPDATE)
- `/Users/fredamaral/repos/lerianstudio/ring/dev-team/skills/shared-patterns/standards-cache-protocol.md` (CREATE)
- `/Users/fredamaral/repos/lerianstudio/ring/dev-team/skills/shared-patterns/gate-cadence-classification.md` (CREATE — or embed in shared-orchestrator-principle.md)

---

## 9. Rollback Strategy

Each phase is independently reversible via git revert. Commit per phase (using `ring:commit` skill) so that if a phase regresses quality:

- Phase R1, R2, R3, R4: Independently revertible; no state schema dependency.
- Phase R5: Includes state schema addition. Rolling back R5 requires also clearing any `cached_standards` / subtask `gate_progress` / `accumulated_metrics` fields from existing state files (they become unused but don't break anything — additive schema).
- Phase R6: Independent of R5; revertible alone.

**Forward compatibility:** Old state files written before Phase R5 will still be readable by post-R5 code (missing fields default to empty).

**Backward compatibility:** Post-R5 state files with new fields are readable by pre-R5 code (new fields ignored) — but resume operations MAY behave incorrectly. Recommendation: complete any in-flight cycle before rolling back.

---

## 10. Key Insights & Warnings for the Implementing Agent

### Insights

1. **The heaviest file is `dev-cycle/SKILL.md` (3428 lines).** Do NOT attempt to rewrite it in one pass. Work section-by-section, committing after each phase.

2. **Sub-skills DO NOT write to current-cycle.json.** State management is centralized in the orchestrator. This means the cache-first WebFetch pattern only requires sub-skills to READ state, never write. Simpler than it appears.

3. **State schema additions are strictly additive.** No field is removed or renamed. Old code paths gracefully ignore new fields. This enables safe phased rollout.

4. **Delivery verification (former Gate 0.5) has 902 lines of detailed checks.** When inlining into dev-implementation Step 7, do NOT copy all 902 lines — copy the essential checks (Requirement Coverage Matrix, Dead Code Detection, Integration Verification) and reference the preserved dev-delivery-verification/SKILL.md for the full list.

5. **The 8 reviewers in codereview still all run.** Only the cadence changes from subtask-level to task-level. Reviewer count, reviewer types, parallelism — all unchanged.

### Warnings

1. **DO NOT introduce conditional reviewer dispatch.** The user explicitly rejected reducing reviewer count via classifiers in Category 3 of the pre-plan discussion. All 8 reviewers run, every task.

2. **DO NOT delete dev-delivery-verification/SKILL.md.** External consumers may reference it. Mark deprecated; keep file.

3. **DO NOT change any quality threshold.** 85% coverage, WCAG AA, CWV values, Lighthouse score — all unchanged.

4. **DO NOT skip the resume-from-state test (6.5).** State schema changes are the only place where a resume regression could occur. Test it.

5. **WebFetch cache mechanism needs fallback.** If `state.cached_standards[URL]` is missing (e.g., sub-skill invoked outside cycle context), the sub-skill MUST fall back to direct WebFetch with a warning log. Never hard-fail on cache miss.

6. **codereview lives in `default/skills/`, NOT `dev-team/skills/`.** Verify path before editing. Changes to codereview cross plugin boundaries.

7. **Per-task visual reports are KEPT.** Only per-subtask visual reports are removed. Do not accidentally remove the task-level report.

8. **`feedback_loop_completed` semantics change slightly.** Previously set per-task after per-task dev-report. Now set per-task after accumulated_metrics are populated (no dev-report dispatch). Cycle-level `feedback_loop_completed` still set after the single cycle-end dev-report dispatch. Update both places in state schema and logic.

---

## 11. Expected Outcome

After all phases complete and verification passes:

| Dimension | Before | After | Delta |
|-----------|--------|-------|-------|
| Gate executions per typical 1-task-5-subtask cycle | ~55 | ~25 | −55% |
| Reviewer agent dispatches | 40 | 8 | −80% |
| WebFetch calls | ~50 | ~5 | −90% |
| State file writes | ~55 | ~22 | −60% |
| State file reads (verification) | ~55 | 0 | −100% |
| Visual report generations | 6 | 1 | −83% |
| dev-report dispatches | 2 | 1 | −50% |
| **Wall-clock time** | **baseline** | **~50–60% of baseline** | **~−40–50%** |
| Code quality (coverage, review issues, compliance) | baseline | **identical** | **0** |
| Review catches (empirical — needs validation) | baseline | **≥ baseline** (task-level cumulative diff catches more interaction bugs) | **≥ 0** |

For dev-refactor with 30 clustered findings: ~84% reduction in gate executions.

---

## 12. Plan Author's Note

This plan was developed in a two-phase analysis:

1. **Phase 1 (Analysis):** Honest diagnosis of bottlenecks, separating waste (free wins) from tradeoffs (measurable risk).
2. **Phase 2 (Refinement):** User pushback on quality — "are we not gonna lose depth?" — led to walking back Category 3 (conditional reviewers, subtask→task review with no subtask review). What remains is the **safe envelope**: cadence migration + pure waste elimination, with all reviewer counts and quality thresholds preserved.

The implementing agent should treat this plan as authoritative. Do NOT reintroduce conditional reviewer logic or threshold reductions "because they seem like obvious additional wins" — they were considered and explicitly rejected.

If something in this plan conflicts with current state of the codebase (file moved, section renamed, etc.), STOP and ask — do not improvise fixes to the plan itself. The verification checks in Section 6 exist precisely to catch drift.

End of plan.
