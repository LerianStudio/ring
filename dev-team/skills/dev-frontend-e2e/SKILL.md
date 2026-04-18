---
name: ring:dev-frontend-e2e
description: |
  Gate 5 of frontend development cycle - ensures all user flows from
  product-designer have passing E2E tests with Playwright across browsers.
  Runs at TASK cadence (after all subtasks complete Gate 0 + Gate 3 + Gate 8).

trigger: |
  - After visual testing complete (Gate 4)
  - MANDATORY for all frontend development tasks
  - Validates user flows end-to-end

skip_when: |
  - Not inside a frontend development cycle (ring:dev-cycle-frontend)
  - Backend-only project with no UI components
  - Task is documentation-only, configuration-only, or non-code
  - No user-facing flows were added or changed in this cycle

NOT_skip_when: |
  - "Unit tests cover the flow" - Unit tests don't test real browser + API interaction.
  - "We only need Chromium" - Users use Firefox and Safari too.
  - "Happy path is enough" - Error handling MUST be tested.

sequence:
  after: [ring:dev-frontend-visual]
  before: [ring:dev-frontend-performance]

related:
  complementary: [ring:dev-cycle-frontend, ring:dev-frontend-visual, ring:qa-analyst-frontend]

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
    - name: user_flows_path
      type: string
      description: "Path to user-flows.md from product-designer"
    - name: backend_handoff
      type: object
      description: "Backend endpoints and contracts from backend dev cycle"
    - name: gate4_handoff
      type: object
      description: "Full handoff from Gate 4 (visual testing)"

output_schema:
  format: markdown
  required_sections:
    - name: "E2E Testing Summary"
      pattern: "^## E2E Testing Summary"
      required: true
    - name: "Flow Coverage"
      pattern: "^## Flow Coverage"
      required: true
    - name: "Handoff to Next Gate"
      pattern: "^## Handoff to Next Gate"
      required: true
  metrics:
    - name: result
      type: enum
      values: [PASS, FAIL]
    - name: flows_tested
      type: integer
    - name: happy_path_tests
      type: integer
    - name: error_path_tests
      type: integer
    - name: browsers_passed
      type: integer
    - name: iterations
      type: integer

verification:
  automated:
    - command: "grep -rn 'test(' --include='*.spec.ts' --include='*.e2e.ts' ."
      description: "Playwright tests exist"
      success_pattern: "test("
    - command: "grep -rn 'getByRole\\|getByTestId\\|getByLabel' --include='*.spec.ts' ."
      description: "Semantic selectors used"
      success_pattern: 'getByRole\|getByTestId\|getByLabel'
  manual:
    - "All user flows from product-designer have E2E tests"
    - "Error paths tested (API 500, timeout, validation)"
    - "Tests pass on Chromium, Firefox, and WebKit"
    - "Responsive viewports covered"
    - "3 consecutive passes without flaky failures"

---

# Dev Frontend E2E Testing (Gate 5)

## Overview

Ensure all user flows from `ring:product-designer` have passing **Playwright E2E tests** across Chromium, Firefox, and WebKit with responsive viewport coverage.

**Core principle:** If the product-designer defined a user flow, it must have an E2E test. If the user can encounter an error, it must be tested.

<block_condition>
- Untested user flow = FAIL
- No error path tests = FAIL
- Fails on any browser = FAIL
- Flaky tests (fail on consecutive runs) = FAIL
</block_condition>

## CRITICAL: Role Clarification

**This skill ORCHESTRATES. Frontend QA Analyst Agent (e2e mode) EXECUTES.**

| Who | Responsibility |
|-----|----------------|
| **This Skill** | Gather requirements, dispatch agent, track iterations |
| **QA Analyst Frontend Agent** | Write Playwright tests, run cross-browser, verify flows |

---

## Standards Reference

> **Standards Source (Cache-First Pattern):** This sub-skill reads standards from `state.cached_standards` populated by dev-cycle Step 1.5. If invoked outside a cycle (standalone), it falls back to direct WebFetch with a warning. See `shared-patterns/standards-cache-protocol.md` for protocol details.

**MANDATORY:** Load testing-e2e.md standards using the cache-first pattern below.

Required URL: `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/frontend/testing-e2e.md`

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
https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/frontend/testing-e2e.md
</fetch_required>

---

## Step 1: Validate Input

```text
REQUIRED INPUT:
- unit_id: [TASK id — this gate runs at task cadence, aggregating all subtasks]
- implementation_files: [union of changed files across all subtasks of the task]
- gate0_handoffs: [array of per-subtask implementation handoffs, one per subtask]

OPTIONAL INPUT:
- user_flows_path: [path to user-flows.md]
- backend_handoff: [endpoints, contracts from backend cycle]
- gate4_handoff: [full Gate 4 output]

if any REQUIRED input is missing:
  → STOP and report: "Missing required input: [field]"

if gate0_handoffs is not an array:
  → STOP and report: "gate0_handoffs must be an array of per-subtask handoffs"

if user_flows_path provided:
  → Load user flows as E2E test scenarios
  → All flows MUST be covered

if backend_handoff provided:
  → Verify E2E tests exercise backend endpoints
  → Verify request payloads match contracts
```

## Step 2: Dispatch Frontend QA Analyst Agent (E2E Mode)

```text
Task tool:
  subagent_type: "ring:qa-analyst-frontend"
  prompt: |
    **MODE:** E2E TESTING (Gate 5)

    **Standards:** Load testing-e2e.md

    **Input:**
    - Task ID: {unit_id} (task-level — aggregates all subtasks)
    - Implementation Files (union across all subtasks): {implementation_files}
    - Per-Subtask Gate 0 Handoffs: {gate0_handoffs}
    - User Flows: {user_flows_path or "N/A"}
    - Backend Handoff: {backend_handoff or "N/A"}

    **Scope:** Validate E2E flows for the task (all subtasks aggregated), not a single subtask.

    **Requirements:**
    1. Create Playwright tests for all user flows
    2. Test happy path + error paths (API 500, timeout, validation)
    3. Run on Chromium, Firefox, WebKit
    4. Test responsive viewports (mobile, tablet, desktop)
    5. Use data-testid or semantic role selectors only
    6. Run 3x consecutively to verify no flaky tests

    **Output Sections Required:**
    - ## E2E Testing Summary
    - ## Flow Coverage
    - ## Handoff to Next Gate
```

## Step 3: Evaluate Results

```text
Parse agent output:

if "Status: PASS" in output:
  → Gate 5 PASSED
  → Return success with metrics

if "Status: FAIL" in output:
  → If flow not covered: re-dispatch agent to add missing tests
  → If browser failure: re-dispatch implementation agent to fix
  → If flaky: re-dispatch agent to stabilize tests
  → Re-run E2E tests (max 3 iterations)
  → If still failing: ESCALATE to user
```

## Step 4: Generate Output

```text
## E2E Testing Summary
**Status:** {PASS|FAIL}
**Flows Tested:** {X/Y}
**Happy Path Tests:** {count}
**Error Path Tests:** {count}
**Browsers Passed:** {X/3}
**Consecutive Passes:** {X/3}

## Flow Coverage
| User Flow | Happy Path | Error Paths | Browsers | Viewports | Status |
|-----------|------------|-------------|----------|-----------|--------|
| {flow} | {PASS|FAIL} | {descriptions} | {X/3} | {X/3} | {PASS|FAIL} |

## Backend Handoff Verification
| Endpoint | Method | Contract Verified | Status |
|----------|--------|-------------------|--------|
| {endpoint} | {method} | {fields} | {PASS|FAIL} |

## Handoff to Next Gate
- Ready for Gate 6 (Performance Testing): {YES|NO}
- Iterations: {count}
```

---

## Severity Calibration

| Severity | Criteria | Examples |
|----------|----------|----------|
| **CRITICAL** | User flow completely broken, data corruption | Transaction fails, user data lost, checkout blocked |
| **HIGH** | Missing user flow tests, flaky tests, browser failure | Untested flow from product-designer, test fails intermittently |
| **MEDIUM** | Error path gaps, viewport issues | Missing error handling test, mobile viewport untested |
| **LOW** | Selector improvements, test organization | Non-semantic selectors, test file structure |

Report all severities. CRITICAL = immediate fix. HIGH = fix before gate pass. MEDIUM = fix in iteration. LOW = document.

---

## Anti-Rationalization Table

See [shared-patterns/shared-anti-rationalization.md](../shared-patterns/shared-anti-rationalization.md) for universal anti-rationalizations. Gate-specific:

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Unit tests cover the flow" | Unit tests don't test real browser interaction. | **Write E2E tests** |
| "Only Chromium matters" | Firefox and Safari have different behavior. | **Test all 3 browsers** |
| "Happy path is enough" | Users encounter errors. Test error handling. | **Add error path tests** |
| "CSS selectors are fine" | CSS changes with refactors. Use semantic selectors. | **Use roles and testids** |
| "Product-designer flows are suggestions" | Flows define acceptance criteria. Cover all. | **Test all flows** |
| "Test is flaky, skip it" | Flaky tests indicate real instability. | **Fix the test** |

---
