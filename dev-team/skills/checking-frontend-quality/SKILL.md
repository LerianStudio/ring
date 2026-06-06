---
name: ring:checking-frontend-quality
description: "Checking frontend quality against changed UI via ring:qa-frontend in accessibility, visual, e2e, or performance mode and aggregating pass/fail verdicts. Use when a frontend change needs standalone a11y, visual-snapshot, Playwright e2e, or Lighthouse/Core-Web-Vitals validation outside the dev cycle. Skip for backend-only or non-UI work, or inside ring:running-dev-cycle-frontend, which already runs these in Gate 0."
---

# Frontend Quality Checks

## When to use
- A frontend task needs standalone quality validation outside ring:running-dev-cycle-frontend
  (which owns these checks in Gate 0).
- You want to run one specific check (a11y, visual, e2e, or performance) against
  changed UI components, or `all` of them at once.

## Skip when
- Backend-only project with no UI components.
- Task is documentation-only, configuration-only, or non-code.
- Changes limited to build tooling, CI/CD, or infrastructure.
- Inside ring:running-dev-cycle-frontend — that orchestrator already runs these in Gate 0.

## Related
**Complementary:** ring:running-dev-cycle-frontend, ring:qa-frontend

## Modes

| Mode | What it checks |
|------|----------------|
| `accessibility` | axe-core automated scans, zero WCAG 2.1 AA critical/serious violations, keyboard nav, focus management |
| `visual` | Snapshot tests across all component states and viewports (mobile 375px / tablet 768px / desktop 1280px) |
| `e2e` | Playwright user-flow tests across Chromium, Firefox, and WebKit (happy + error paths) |
| `performance` | Lighthouse > 90 and Core Web Vitals (LCP < 2.5s, CLS < 0.1, INP < 200ms), bundle budget |
| `all` | Runs all four modes in parallel and aggregates the verdicts |

The deep per-mode requirements live in the agent's mode files
(`dev-team/agents/qa-frontend-modes/{accessibility,visual,e2e,performance}.md`).
Do not duplicate them here.

## Step 1: Validate Input

Required: `unit_id` (TASK id), `implementation_files`, `gate0_handoffs`.
Required: `mode` — one of `accessibility | visual | e2e | performance | all`.
Optional: `components_list`, `user_flows_path`, `performance_baseline`.

## Step 2: Dispatch

For a single mode, dispatch the QA analyst with the selected mode:

```yaml
Task:
  subagent_type: "ring:qa-frontend"
  description: "Frontend {mode} checks for {unit_id}"
  prompt: |
    mode: {mode}
    unit_id: {unit_id}
    implementation_files: {implementation_files filtered to UI files}
    gate0_handoffs: {gate0_handoffs}
    # optional, when relevant to the mode:
    # user_flows_path, performance_baseline, components_list

    Load qa-frontend-modes/{mode}.md and follow it.
```

For `mode: all`, dispatch the four modes **in parallel** (one Task batch — four
Task calls in a single message), each with the same inputs and its own `mode`.
Aggregate the four verdicts into the output below.

## Output

Aggregated pass/fail per mode:

```markdown
## Frontend Quality Result
unit_id | mode(s): {mode or all}

| Mode | Result | Violations / Failures | Iterations |
|------|--------|-----------------------|------------|
| accessibility | PASS/FAIL | N | N |
| visual | PASS/FAIL | N | N |
| e2e | PASS/FAIL | N | N |
| performance | PASS/FAIL | N | N |

## Overall: PASS | FAIL
(FAIL if any dispatched mode failed.)
```
