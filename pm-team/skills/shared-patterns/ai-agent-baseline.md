---
description: |
  Canonical source for AI-agent-hours definition across pm-team skills.
  Defines baseline execution model, capacity utilization, and usage patterns.
  Referenced by: ring:decomposing-phases-and-epics (Gate 7), ring:planning-delivery (Gate 9).
---

# AI Agent Baseline Definition

**Canonical source for AI-agent-hours definition across pm-team skills.**

This pattern is referenced by:
- `ring:decomposing-phases-and-epics` (Gate 7)
- `ring:planning-delivery` (Gate 9)

---

## Baseline: AI Agent via ring:running-dev-cycle (Lerian Standard)

All time estimates in pm-team workflows use **AI-agent-hours** as the baseline unit.

### What "AI-agent-hours" Means

- **Executor:** AI agent implementing via ring:running-dev-cycle
- **Includes:** TDD, automated code review, SRE validation, DevOps setup
- **Execution:** Fully automated through dev-team gates
- **Quality:** Production-ready (all gates passed)

### What is NOT Included

**Added later via human validation multiplier (Gate 9):**
- Human code review and validation
- Requested adjustments and refactoring
- Manual exploratory testing
- Stakeholder feedback cycles
- Deployment validation
- Integration debugging

### Why This Baseline?

**Lerian Context:**
- All development uses ring:running-dev-cycle (AI Agent execution)
- Consistent measurement: AI work is predictable and repeatable
- Transparent separation: AI implementation time vs human validation time
- Trackable: Can measure AI estimate vs actual execution time

### Capacity: 90% (Fixed)

AI Agent via ring:running-dev-cycle has minimal but real overhead:

| Overhead Type | Impact |
|---------------|--------|
| API rate limits and latency | ~4% |
| Context loading (files, docs) | ~2% |
| Tool execution (compile, test) | ~3% |
| Error recovery (retry failed commands) | ~1% |
| **Total Overhead** | **~10%** |
| **Effective Capacity** | **90%** |

**Contrast with human capacity:**
- Human developer: ~75% (25% lost to meetings, context switching, breaks)
- AI Agent: 90% (10% lost to technical overhead)

---

## Usage in Skills

### Gate 7 (Task Breakdown)

**Purpose:** Estimate AI implementation time per task

**Process:**
1. Tech stack detection from TRD
2. Dispatch specialized agent (Go/TypeScript/React)
3. Agent analyzes scope and estimates per component
4. Output: AI-agent-hours with confidence level

**Output format:**
```markdown
**Effort Estimate:**
- AI Estimate: 4.5 AI-agent-hours
- Baseline: AI Agent via ring:running-dev-cycle
- Confidence: High
```

### Gate 9 (Delivery Planning)

**Purpose:** Convert AI-agent-hours to calendar time

**Formula:**
```
calendar_hours = (ai_estimate × multiplier) ÷ 0.90
calendar_days = calendar_hours ÷ 8 ÷ team_size

Where:
- ai_estimate = from Gate 7 (AI-agent-hours)
- multiplier = human validation overhead (1.2x - 2.5x)
- 0.90 = capacity (90%)
- 8 = hours per working day
```

**Example:**
```
4.5 AI-agent-hours × 1.5 multiplier = 6.75h adjusted
6.75h ÷ 0.90 capacity = 7.5h calendar
7.5h ÷ 8h/day = 0.94 developer-days ≈ 1 day
```

---

## Historical Calibration

Teams should track actual vs estimated to improve accuracy:

```markdown
Task T-001:
- AI Estimated: 4h
- AI Actual (ring:running-dev-cycle): 3.5h
- Variance: -12.5% (AI faster than estimated)

Task T-002:
- AI Estimated: 8h
- AI Actual: 9h
- Variance: +12.5% (AI slower than estimated)

Average AI accuracy: ±12% → Acceptable range
```

**When to adjust baseline:**
- Consistent +20% variance → AI estimates too optimistic
- Consistent -20% variance → AI estimates too conservative
- Adjust confidence levels, not the baseline itself
