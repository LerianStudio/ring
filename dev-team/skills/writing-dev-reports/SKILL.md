---
name: ring:writing-dev-reports
description: "Writing a structured markdown dev report for a completed development epic: reads accumulated epic metrics (TDD, coverage, delivery, lint, file-size, license), computes a quality score with tiers, and records root-cause and next-cycle improvements. Use after an epic completes in ring:running-dev-cycle or when asked for a development feedback report. Skip for documentation-only epics or outside a dev cycle."
---

# Dev Report — Feedback Loop

## When to use
- After epic completion in any dev cycle
- User requests a development report or feedback summary
- ring:running-dev-cycle Gate 10 handoff

## Skip when
- Epic was documentation-only with no code changes
- Not inside a development cycle


Collects metrics and writes a structured report for completed development epics.

## Step 1: Collect Metrics

Read `accumulated_metrics` from each completed epic (`state.epics[].accumulated_metrics`),
then gather the following per epic:

```yaml
epic_id: {unit_id}
completed_at: {ISO timestamp}
agent_used: {ring:backend-go | ring:frontend | etc.}
language: {go | typescript | python}
service_type: {api | worker | batch | cli | frontend | bff}

tdd:
  red_status: completed | skipped | failed
  green_status: completed | skipped | failed

coverage:
  actual_percent: {float}
  threshold: {float}
  verdict: PASS | FAIL

delivery:
  requirements_total: {int}
  requirements_delivered: {int}
  verdict: PASS | PARTIAL | FAIL

quality:
  lint_pass: true | false
  file_size_violations: {int}
  license_violations: {int}
  migration_safety: PASS | FAIL | N/A
```

## Step 2: Calculate Score

```
score = 0

TDD RED completed:    +20
TDD GREEN completed:  +20
Coverage ≥ threshold: +20
Delivery PASS:        +20
Lint pass:            +10
No file size violations: +5
License headers OK:   +5

Total: 100 possible
```

Score tiers:
- 90-100: Excellent
- 80-89: Good
- 70-79: Acceptable
- < 70: Needs attention → root cause required

## Step 3: Write Report

Save to `docs/ring:writing-dev-reports/{epic_id}-{timestamp}.md`:

```markdown
# Dev Report: {epic_id}

**Completed:** {timestamp}
**Agent:** {agent_used}
**Language:** {language} | **Service Type:** {service_type}

## Score: {score}/100 ({tier})

## Metrics

| Metric | Value | Status |
|--------|-------|--------|
| TDD RED | {status} | ✅/❌ |
| TDD GREEN | {status} | ✅/❌ |
| Coverage | {actual}% (threshold: {threshold}%) | ✅/❌ |
| Delivery | {delivered}/{total} requirements | ✅/⚠️/❌ |
| Lint | {pass/fail} | ✅/❌ |
| File Size | {violations} violations | ✅/❌ |
| License | {violations} violations | ✅/❌ |

## Delivery Traceability

| Requirement | Status | Evidence |
|-------------|--------|----------|
{per-requirement rows}

## Issues Found

{list of ISSUE-XXX with severity and description}

## Root Cause (if score < 70)

{mandatory analysis: what caused the gaps, pattern identification}

## Improvements for Next Cycle

{1-3 concrete, actionable improvements}
```

## Severity Reference

| Severity | Criteria |
|----------|----------|
| CRITICAL | Score 0 (rejected), complete workflow failure |
| HIGH | Score < 70, threshold breach |
| MEDIUM | Score 70-79, recurring pattern emerging |
| LOW | Score 80-89, minor improvements available |
