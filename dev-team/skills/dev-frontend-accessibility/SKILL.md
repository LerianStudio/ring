---
name: ring:dev-frontend-accessibility
description: |
  Gate 2 of frontend development cycle - ensures all components pass axe-core
  automated accessibility scans with zero WCAG 2.1 AA violations.
  Runs at TASK cadence (after all subtasks complete Gate 0 + Gate 3 + Gate 8).

trigger: |
  - After DevOps setup complete (Gate 1)
  - MANDATORY for all frontend development tasks
  - Validates WCAG 2.1 AA compliance

skip_when: |
  - Not inside a frontend development cycle (ring:dev-cycle-frontend)
  - Backend-only project with no UI components
  - Task is documentation-only, configuration-only, or non-code
  - Changes are limited to build tooling, CI/CD, or infrastructure with no UI impact

NOT_skip_when: |
  - "It's an internal tool" - WCAG compliance is mandatory for all applications.
  - "The component library handles accessibility" - Library components can be misused.
  - "We'll add accessibility later" - Retrofitting costs 10x more.

sequence:
  after: [ring:dev-devops]
  before: [ring:dev-unit-testing]

related:
  complementary: [ring:dev-cycle-frontend, ring:dev-devops, ring:qa-analyst-frontend]

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
    - name: language
      type: string
      enum: [typescript]
      description: "Programming language (TypeScript only)"
  optional:
    - name: gate1_handoff
      type: object
      description: "Full handoff from Gate 1 (DevOps)"

output_schema:
  format: markdown
  required_sections:
    - name: "Accessibility Testing Summary"
      pattern: "^## Accessibility Testing Summary"
      required: true
    - name: "Violations Report"
      pattern: "^## Violations Report"
      required: true
    - name: "Handoff to Next Gate"
      pattern: "^## Handoff to Next Gate"
      required: true
  metrics:
    - name: result
      type: enum
      values: [PASS, FAIL]
    - name: components_tested
      type: integer
    - name: violations_found
      type: integer
    - name: keyboard_nav_tests
      type: integer
    - name: iterations
      type: integer

verification:
  automated:
    - command: "grep -rn 'toHaveNoViolations\\|axe(' --include='*.test.tsx' --include='*.test.ts' ."
      description: "axe-core tests exist"
      success_pattern: 'toHaveNoViolations\|axe('
    - command: "grep -rn 'getByRole\\|getByLabel' --include='*.test.tsx' --include='*.test.ts' ."
      description: "Semantic selector tests exist"
      success_pattern: 'getByRole\|getByLabel'
  manual:
    - "axe-core scans return 0 WCAG AA violations"
    - "Keyboard navigation tests cover all interactive elements"
    - "Focus management tests exist for modals and dialogs"

---

# Dev Frontend Accessibility Testing (Gate 2)

## Overview

Ensure all frontend components meet **WCAG 2.1 AA** accessibility standards through automated axe-core scanning, keyboard navigation testing, and focus management validation.

**Core principle:** Accessibility is not optional. All components MUST be accessible to all users, including those using keyboard navigation, screen readers, and assistive technologies.

<block_condition>
- Any WCAG AA violation = FAIL
- Missing keyboard navigation tests = FAIL
- Missing focus management for modals = FAIL
</block_condition>

## CRITICAL: Role Clarification

**This skill ORCHESTRATES. Frontend QA Analyst Agent (accessibility mode) EXECUTES.**

| Who | Responsibility |
|-----|----------------|
| **This Skill** | Gather requirements, dispatch agent, track iterations |
| **QA Analyst Frontend Agent** | Run axe-core, write keyboard tests, verify ARIA |

---

## Standards Reference

> **Standards Source (Cache-First Pattern):** This sub-skill reads standards from `state.cached_standards` populated by dev-cycle Step 1.5. If invoked outside a cycle (standalone), it falls back to direct WebFetch with a warning. See `shared-patterns/standards-cache-protocol.md` for protocol details.

**MANDATORY:** Load testing-accessibility.md standards using the cache-first pattern below.

Required URL: `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/frontend/testing-accessibility.md`

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
https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/frontend/testing-accessibility.md
</fetch_required>

---

## Step 1: Validate Input

```text
REQUIRED INPUT:
- unit_id: [TASK id — this gate runs at task cadence, aggregating all subtasks]
- implementation_files: [union of changed files across all subtasks of the task]
- gate0_handoffs: [array of per-subtask implementation handoffs, one per subtask]
- language: [typescript only]

OPTIONAL INPUT:
- gate1_handoff: [full Gate 1 output]

if any REQUIRED input is missing:
  → STOP and report: "Missing required input: [field]"

if gate0_handoffs is not an array:
  → STOP and report: "gate0_handoffs must be an array of per-subtask handoffs"

if language != "typescript":
  → STOP and report: "Frontend accessibility testing only supported for TypeScript/React"
```

## Step 2: Dispatch Frontend QA Analyst Agent (Accessibility Mode)

```text
Task tool:
  subagent_type: "ring:qa-analyst-frontend"
  prompt: |
    **MODE:** ACCESSIBILITY TESTING (Gate 2)

    **Standards:** Load testing-accessibility.md

    **Input:**
    - Task ID: {unit_id} (task-level — aggregates all subtasks)
    - Implementation Files (union across all subtasks): {implementation_files}
    - Per-Subtask Gate 0 Handoffs: {gate0_handoffs}
    - Language: typescript

    **Scope:** Validate accessibility for the task (all subtasks aggregated), not a single subtask.

    **Requirements:**
    1. Run axe-core scans on all components (all states: default, loading, error, empty, disabled)
    2. Test keyboard navigation (Tab, Enter, Escape, Arrow keys)
    3. Test focus management (trap, restoration, auto-focus)
    4. Verify semantic HTML usage
    5. Check ARIA attributes
    6. Verify color contrast

    **Output Sections Required:**
    - ## Accessibility Testing Summary
    - ## Violations Report
    - ## Handoff to Next Gate
```

## Step 3: Evaluate Results

```text
Parse agent output:

if "Status: PASS" in output:
  → Gate 2 PASSED
  → Return success with metrics

if "Status: FAIL" in output:
  → Dispatch fix to implementation agent (ring:frontend-engineer or ring:ui-engineer)
  → Re-run accessibility tests (max 3 iterations)
  → If still failing: ESCALATE to user
```

## Step 4: Generate Output

```text
## Accessibility Testing Summary
**Status:** {PASS|FAIL}
**Components Tested:** {count}
**Violations Found:** {count}
**Keyboard Nav Tests:** {count}
**Focus Management Tests:** {count}

## Violations Report
| Component | States Scanned | Violations | Status |
|-----------|---------------|------------|--------|
| {component} | {states} | {count} | {PASS|FAIL} |

## Handoff to Next Gate
- Ready for Gate 3 (Unit Testing): {YES|NO}
- Iterations: {count}
```

---

## Severity Calibration

| Severity | Criteria | Examples |
|----------|----------|----------|
| **CRITICAL** | Legal compliance risk, users blocked | Missing alt text on images, no keyboard access, form without labels |
| **HIGH** | WCAG AA violation, significant barrier | Color contrast fails, missing focus indicators, no skip links |
| **MEDIUM** | Minor accessibility gaps | Non-semantic HTML, missing ARIA on complex widgets |
| **LOW** | Best practices, enhancements | Optional ARIA improvements, landmark suggestions |

Report all severities. CRITICAL = immediate fix (legal risk). HIGH = fix before gate pass. MEDIUM = fix in iteration. LOW = document.

---

## Anti-Rationalization Table

See [shared-patterns/shared-anti-rationalization.md](../shared-patterns/shared-anti-rationalization.md) for universal anti-rationalizations. Gate-specific:

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "It's an internal tool" | WCAG compliance is mandatory for all applications. | **Run accessibility tests** |
| "The library handles it" | Components can be misused. axe-core catches misuse. | **Run axe-core scans** |
| "We'll fix accessibility later" | Retrofitting costs 10x. Fix now. | **Fix violations now** |
| "Only one violation, it's minor" | One violation = FAIL. No exceptions. | **Fix all violations** |
| "Keyboard nav works, I tested manually" | Manual ≠ automated. Tests must be repeatable. | **Write automated tests** |

---
