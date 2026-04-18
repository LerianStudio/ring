---
name: ring:dev-frontend-visual
description: |
  Gate 4 of frontend development cycle - ensures all components have snapshot
  tests covering all states, viewports, and edge cases.
  Runs at TASK cadence (after all subtasks complete Gate 0 + Gate 3 + Gate 8).

trigger: |
  - After unit testing complete (Gate 3)
  - MANDATORY for all frontend development tasks
  - Catches visual regressions before review

skip_when: |
  - Not inside a frontend development cycle (ring:dev-cycle-frontend)
  - Backend-only project with no UI components
  - Task is documentation-only, configuration-only, or non-code
  - No new UI components were added or visual changes made in this cycle

NOT_skip_when: |
  - "Snapshots are brittle" - Brittle snapshots catch unintended changes.
  - "We test visually in the browser" - Manual testing doesn't catch regressions.
  - "Only default state matters" - Users see error, loading, and empty states too.

sequence:
  after: [ring:dev-unit-testing]
  before: [ring:dev-frontend-e2e]

related:
  complementary: [ring:dev-cycle-frontend, ring:dev-unit-testing, ring:qa-analyst-frontend]

input_schema:
  required:
    - name: unit_id
      type: string
      description: "Task identifier (always a TASK id; runs at task cadence)"
    - name: implementation_files
      type: array
      items: string
      description: "Union of changed files across all subtasks of this task"
    - name: gate0_handoffs
      type: array
      items: object
      description: "Array of per-subtask implementation handoffs (one per subtask). NOT a single gate0_handoff object."
  optional:
    - name: ux_criteria_path
      type: string
      description: "Path to ux-criteria.md from product-designer"
    - name: gate3_handoff
      type: object
      description: "Full handoff from Gate 3 (unit testing)"

output_schema:
  format: markdown
  required_sections:
    - name: "Visual Testing Summary"
      pattern: "^## Visual Testing Summary"
      required: true
    - name: "Snapshot Coverage"
      pattern: "^## Snapshot Coverage"
      required: true
    - name: "Component Duplication Check"
      pattern: "^## Component Duplication Check"
      required: true
    - name: "Handoff to Next Gate"
      pattern: "^## Handoff to Next Gate"
      required: true
  metrics:
    - name: result
      type: enum
      values: [PASS, FAIL]
    - name: components_with_snapshots
      type: integer
    - name: total_snapshots
      type: integer
    - name: snapshot_failures
      type: integer
    - name: iterations
      type: integer

verification:
  automated:
    - command: "grep -rn 'toMatchSnapshot' --include='*.test.tsx' --include='*.snapshot.test.tsx' ."
      description: "Snapshot tests exist"
      success_pattern: "toMatchSnapshot"
    - command: "find . -name '*.snap' -type f | head -5"
      description: "Snapshot files generated"
      success_pattern: ".snap"
  manual:
    - "All component states have snapshots"
    - "Responsive viewports covered (375px, 768px, 1280px)"
    - "No sindarian-ui component duplication in components/ui/"

---

# Dev Frontend Visual Testing (Gate 4)

## Overview

Ensure all frontend components have **snapshot tests** covering all states, responsive viewports, and edge cases. Detect visual regressions before code review.

**Core principle:** If a user can see it, it must have a snapshot. All states, all viewports.

<block_condition>
- Missing state snapshots = FAIL
- Snapshot test failures = FAIL
- sindarian-ui component duplicated in shadcn = FAIL
</block_condition>

## CRITICAL: Role Clarification

**This skill ORCHESTRATES. Frontend QA Analyst Agent (visual mode) EXECUTES.**

| Who | Responsibility |
|-----|----------------|
| **This Skill** | Gather requirements, dispatch agent, track iterations |
| **QA Analyst Frontend Agent** | Write snapshot tests, verify states, check duplication |

---

## Standards Reference

> **Standards Source (Cache-First Pattern):** This sub-skill reads standards from `state.cached_standards` populated by dev-cycle Step 1.5. If invoked outside a cycle (standalone), it falls back to direct WebFetch with a warning. See `shared-patterns/standards-cache-protocol.md` for protocol details.

**MANDATORY:** Load testing-visual.md standards using the cache-first pattern below.

Required URL: `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/frontend/testing-visual.md`

```yaml
For the required standards URL above:
  IF state.cached_standards[url] exists:
    → Read content from state.cached_standards[url].content
    → Log: "Using cached standard: {url} (fetched {state.cached_standards[url].fetched_at})"
  ELSE:
    → WebFetch url (fallback — should not happen if orchestrator ran Step 1.5)
    → Log warning: "Standard {url} was not pre-cached; fetched inline"
```

<fetch_required>
https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/frontend/testing-visual.md
</fetch_required>

---

## Step 1: Validate Input

```text
REQUIRED INPUT:
- unit_id: [TASK id — this gate runs at task cadence, aggregating all subtasks]
- implementation_files: [union of changed files across all subtasks of the task]
- gate0_handoffs: [array of per-subtask implementation handoffs, one per subtask]

OPTIONAL INPUT:
- ux_criteria_path: [path to ux-criteria.md]
- gate3_handoff: [full Gate 3 output]

if any REQUIRED input is missing:
  → STOP and report: "Missing required input: [field]"

if gate0_handoffs is not an array:
  → STOP and report: "gate0_handoffs must be an array of per-subtask handoffs"
```

## Step 2: Dispatch Frontend QA Analyst Agent (Visual Mode)

```text
Task tool:
  subagent_type: "ring:qa-analyst-frontend"
  prompt: |
    **MODE:** VISUAL TESTING (Gate 4)

    **Standards:** Load testing-visual.md

    **Input:**
    - Task ID: {unit_id} (task-level — aggregates all subtasks)
    - Implementation Files (union across all subtasks): {implementation_files}
    - Per-Subtask Gate 0 Handoffs: {gate0_handoffs}
    - UX Criteria: {ux_criteria_path or "N/A"}

    **Scope:** Validate visual/snapshot coverage for the task (all subtasks aggregated), not a single subtask.

    **Requirements:**
    1. Create snapshot tests for all components
    2. Cover all states (Default, Empty, Loading, Error, Success, Disabled)
    3. Add responsive snapshots (375px, 768px, 1280px) for layout components
    4. Test edge cases (long text, 0 items, special characters)
    5. Verify no sindarian-ui component duplication in components/ui/

    **Output Sections Required:**
    - ## Visual Testing Summary
    - ## Snapshot Coverage
    - ## Component Duplication Check
    - ## Handoff to Next Gate
```

## Step 3: Evaluate Results

```text
Parse agent output:

if "Status: PASS" in output:
  → Gate 4 PASSED
  → Return success with metrics

if "Status: FAIL" in output:
  → If missing snapshots: re-dispatch agent to add missing
  → If duplication found: re-dispatch implementation agent to fix
  → Re-run visual tests (max 3 iterations)
  → If still failing: ESCALATE to user
```

## Step 4: Generate Output

```text
## Visual Testing Summary
**Status:** {PASS|FAIL}
**Components with Snapshots:** {count}
**Total Snapshots:** {count}
**Snapshot Failures:** {count}

## Snapshot Coverage
| Component | States | Viewports | Edge Cases | Status |
|-----------|--------|-----------|------------|--------|
| {component} | {X/Y} | {X/Y or N/A} | {description} | {PASS|FAIL} |

## Component Duplication Check
| Component in components/ui/ | In sindarian-ui? | Status |
|-----------------------------|------------------|--------|
| {component} | {Yes|No} | {PASS|FAIL} |

## Handoff to Next Gate
- Ready for Gate 5 (E2E Testing): {YES|NO}
- Iterations: {count}
```

---

## Severity Calibration

| Severity | Criteria | Examples |
|----------|----------|----------|
| **CRITICAL** | Component duplication, major visual regression | sindarian-ui duplicated in shadcn, layout completely broken |
| **HIGH** | Missing state snapshots, snapshot failures | No loading/error state snapshot, unexpected diff |
| **MEDIUM** | Incomplete coverage, minor visual issues | Missing viewport size, edge case not tested |
| **LOW** | Documentation, test organization | Missing snapshot descriptions, file naming |

Report all severities. CRITICAL = immediate fix. HIGH = fix before gate pass. MEDIUM = fix in iteration. LOW = document.

---

## Anti-Rationalization Table

See [shared-patterns/shared-anti-rationalization.md](../shared-patterns/shared-anti-rationalization.md) for universal anti-rationalizations. Gate-specific:

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Snapshots are brittle" | Brittle = catches unintended changes. That's the point. | **Write snapshot tests** |
| "We test visually in browser" | Manual testing misses regressions. Automated is repeatable. | **Add snapshot tests** |
| "Only default state matters" | Error and loading states are user-facing. | **Test all states** |
| "Mobile is just smaller" | Layout changes at breakpoints. Test all viewports. | **Add responsive snapshots** |
| "This shadcn component is better" | sindarian-ui is PRIMARY. Don't duplicate. | **Check sindarian-ui first** |

---
