---
name: ring:dev-frontend-performance
description: |
  Gate 6 of frontend development cycle - ensures Core Web Vitals compliance,
  Lighthouse performance score > 90, and bundle size within budget.
  Runs at TASK cadence (after all subtasks complete Gate 0 + Gate 3 + Gate 8).

trigger: |
  - After E2E testing complete (Gate 5)
  - MANDATORY for all frontend development tasks
  - Validates performance before code review

skip_when: |
  - Not inside a frontend development cycle (ring:dev-cycle-frontend)
  - Backend-only project with no UI components
  - Task is documentation-only, configuration-only, or non-code
  - Changes are limited to test files, CI/CD, or non-rendered code

NOT_skip_when: |
  - "Performance is fine on my machine" - Users have slower devices.
  - "We'll optimize later" - Performance debt compounds.
  - "It's a small change" - Small changes can cause big regressions.

sequence:
  after: [ring:dev-frontend-e2e]
  before: [ring:codereview]

related:
  complementary: [ring:dev-cycle-frontend, ring:dev-frontend-e2e, ring:qa-analyst-frontend]

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
    - name: performance_baseline
      type: object
      description: "Previous performance metrics for comparison"
    - name: gate5_handoff
      type: object
      description: "Full handoff from Gate 5 (E2E testing)"

output_schema:
  format: markdown
  required_sections:
    - name: "Performance Testing Summary"
      pattern: "^## Performance Testing Summary"
      required: true
    - name: "Core Web Vitals Report"
      pattern: "^## Core Web Vitals Report"
      required: true
    - name: "Handoff to Next Gate"
      pattern: "^## Handoff to Next Gate"
      required: true
  metrics:
    - name: result
      type: enum
      values: [PASS, FAIL]
    - name: lcp_ms
      type: integer
    - name: cls_score
      type: float
    - name: inp_ms
      type: integer
    - name: lighthouse_score
      type: integer
    - name: bundle_size_change_percent
      type: float
    - name: iterations
      type: integer

verification:
  automated:
    - command: "npx lighthouse http://localhost:3000 --output=json --quiet 2>/dev/null | jq '.categories.performance.score'"
      description: "Lighthouse performance score"
      success_pattern: "0\\.[9-9]"
    - command: "grep -rn \"'use client'\" --include='*.tsx' --include='*.ts' src/ | wc -l"
      description: "Count client components"
      success_pattern: "[0-9]+"
  manual:
    - "LCP < 2.5s on all pages"
    - "CLS < 0.1 on all pages"
    - "INP < 200ms on all pages"
    - "Bundle size increase < 10%"
    - "No bare <img> tags (all use next/image)"

---

# Dev Frontend Performance Testing (Gate 6)

## Overview

Ensure all frontend pages meet **Core Web Vitals** thresholds, achieve **Lighthouse Performance > 90**, maintain **bundle size within budget**, and minimize **client component** usage.

**Core principle:** Performance is a feature. Users on slow devices and connections deserve a fast experience. Performance budgets are enforced, not suggested.

<block_condition>
- LCP > 2.5s on any page = FAIL
- CLS > 0.1 on any page = FAIL
- INP > 200ms on any page = FAIL
- Lighthouse Performance < 90 = FAIL
- Bundle size increase > 10% without justification = FAIL
</block_condition>

## CRITICAL: Role Clarification

**This skill ORCHESTRATES. Frontend QA Analyst Agent (performance mode) EXECUTES.**

| Who | Responsibility |
|-----|----------------|
| **This Skill** | Gather requirements, dispatch agent, track iterations |
| **QA Analyst Frontend Agent** | Run Lighthouse, measure CWV, analyze bundles, audit components |

---

## Standards Reference

> **Standards Source (Cache-First Pattern):** This sub-skill reads standards from `state.cached_standards` populated by dev-cycle Step 1.5. If invoked outside a cycle (standalone), it falls back to direct WebFetch with a warning. See `shared-patterns/standards-cache-protocol.md` for protocol details.

**MANDATORY:** Load testing-performance.md standards using the cache-first pattern below.

Required URL: `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/frontend/testing-performance.md`

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
https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/frontend/testing-performance.md
</fetch_required>

---

## Step 1: Validate Input

```text
REQUIRED INPUT:
- unit_id: [TASK id — this gate runs at task cadence, aggregating all subtasks]
- implementation_files: [union of changed files across all subtasks of the task]
- gate0_handoffs: [array of per-subtask implementation handoffs, one per subtask]

OPTIONAL INPUT:
- performance_baseline: [previous metrics for comparison]
- gate5_handoff: [full Gate 5 output]

if any REQUIRED input is missing:
  → STOP and report: "Missing required input: [field]"

if gate0_handoffs is not an array:
  → STOP and report: "gate0_handoffs must be an array of per-subtask handoffs"
```

## Step 2: Dispatch Frontend QA Analyst Agent (Performance Mode)

```text
Task tool:
  subagent_type: "ring:qa-analyst-frontend"
  prompt: |
    **MODE:** PERFORMANCE TESTING (Gate 6)

    **Standards:** Load testing-performance.md

    **Input:**
    - Task ID: {unit_id} (task-level — aggregates all subtasks)
    - Implementation Files (union across all subtasks): {implementation_files}
    - Per-Subtask Gate 0 Handoffs: {gate0_handoffs}
    - Baseline: {performance_baseline or "N/A"}

    **Scope:** Validate performance for the task (all subtasks aggregated), not a single subtask.

    **Requirements:**
    1. Measure Core Web Vitals (LCP, CLS, INP) on all affected pages
    2. Run Lighthouse audit (Performance score > 90)
    3. Analyze bundle size change vs baseline
    4. Audit 'use client' usage (should be < 40% of components)
    5. Detect performance anti-patterns (bare <img>, useEffect for fetching, etc.)
    6. Verify sindarian-ui imports are tree-shakeable

    **Output Sections Required:**
    - ## Performance Testing Summary
    - ## Core Web Vitals Report
    - ## Handoff to Next Gate
```

## Step 3: Evaluate Results

```text
Parse agent output:

if "Status: PASS" in output:
  → Gate 6 PASSED
  → Return success with metrics

if "Status: FAIL" in output:
  → Dispatch fix to implementation agent (ring:frontend-engineer)
  → Re-run performance tests (max 3 iterations)
  → If still failing: ESCALATE to user
```

## Step 4: Generate Output

```text
## Performance Testing Summary
**Status:** {PASS|FAIL}
**LCP:** {value}s (< 2.5s)
**CLS:** {value} (< 0.1)
**INP:** {value}ms (< 200ms)
**Lighthouse:** {score} (> 90)
**Bundle Change:** {+X%} (< 10%)

## Core Web Vitals Report
| Page | LCP | CLS | INP | Status |
|------|-----|-----|-----|--------|
| {page} | {value} | {value} | {value} | {PASS|FAIL} |

## Bundle Analysis
| Metric | Current | Baseline | Change | Status |
|--------|---------|----------|--------|--------|
| Total JS (gzipped) | {size} | {size} | {change}% | {PASS|FAIL} |

## Server Component Audit
| Metric | Value |
|--------|-------|
| Total .tsx files | {count} |
| Client components | {count} |
| Client ratio | {percent}% (< 40%) |

## Anti-Pattern Detection
| Pattern | Occurrences | Status |
|---------|-------------|--------|
| Bare <img> | {count} | {PASS|FAIL} |
| useEffect for fetching | {count} | {PASS|FAIL} |
| Wildcard sindarian imports | {count} | {PASS|FAIL} |

## Handoff to Next Gate
- Ready for Gate 7 (Code Review): {YES|NO}
- Iterations: {count}
```

---

## Severity Calibration

| Severity | Criteria | Examples |
|----------|----------|----------|
| **CRITICAL** | Core Web Vitals fail, page unusable | LCP > 4s, CLS > 0.25, INP > 500ms |
| **HIGH** | Threshold violations, major regressions | Lighthouse < 90, bundle +20%, LCP > 2.5s |
| **MEDIUM** | Minor threshold concerns, optimization opportunities | Client ratio > 40%, bare img tags |
| **LOW** | Best practices, minor optimizations | Code splitting suggestions, cache improvements |

Report all severities. CRITICAL = immediate fix (UX broken). HIGH = fix before gate pass. MEDIUM = fix in iteration. LOW = document.

---

## Anti-Rationalization Table

See [shared-patterns/shared-anti-rationalization.md](../shared-patterns/shared-anti-rationalization.md) for universal anti-rationalizations. Gate-specific:

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Works fine on my machine" | Your machine ≠ user's device. Measure objectively. | **Run Lighthouse** |
| "We'll optimize later" | Performance debt compounds. Fix during development. | **Meet thresholds now** |
| "Bundle size doesn't matter" | Mobile 3G users exist. Every KB matters. | **Stay within budget** |
| "Everything needs use client" | Server components reduce JS. Audit first. | **Minimize client components** |
| "next/image is too complex" | next/image gives free optimization. Always use it. | **Use next/image** |
| "Lighthouse 85 is close enough" | 90 is the threshold. 85 = FAIL. | **Optimize to 90+** |

---
