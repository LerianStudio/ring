---
name: ring:pre-dev-delivery-planning
description: |
  Gate 9 (Full Track) / Gate 4 (Small Track): Delivery roadmap and timeline planning.
  Transforms the phased plan (epics) into a realistic delivery schedule with critical
  path analysis, resource allocation, and delivery breakdown aligned to plan phases.
  MANDATORY gate for both workflows.
---

# Delivery Planning — Realistic Roadmap with Critical Path

## When to use

- Phased plan passed Gate 7 validation (Full Track) OR Gate 3 (Small Track); Phase 1 detailed (Gate 8, Full Track)
- Need realistic delivery timeline with dates
- Ready to convert epics into delivery schedule
- Team composition known or determinable

## Skip when

- Phased plan not validated → complete phases & epics first
- Proof-of-concept without delivery commitment
- Research/exploration work without delivery deadline

## Sequence

**Runs before:** ring:dev-cycle
**Runs after:** ring:pre-dev-phases-and-epics, ring:pre-dev-task-creation


Every roadmap must be grounded in reality, not optimism. Epics not validated, team composition unknown, or start date absent → STOP and gather the missing input before proceeding.

Scheduling unit is the **epic** (rows of the `## Summary` table in tasks.md). Plan phases are hard sequencing constraints: an epic never starts before its phase's predecessor phase completes. Only Phase 1 carries task-level detail — later-phase epic estimates are coarser by design (rolling wave); reflect that in confidence, not in false precision.

## Workflow Steps

| Step | Activities |
|------|------------|
| **1. Input Gathering** | Load tasks.md (phased plan); ask user for start date, team composition, delivery cadence, period configuration, velocity multiplier |
| **2. Dependency Analysis** | Build dependency graph from epics (phase order + epic dependencies), identify critical path, find parallelization opportunities within phases |
| **3. Capacity Planning** | Calculate team velocity (custom multiplier), allocate resources, identify bottlenecks |
| **4. Delivery Breakdown** | Group epics by cadence (sprint/cycle/continuous), align milestones to plan phases where the cadence allows, calculate period boundaries, identify spill overs, map parallel streams |
| **5. Risk Analysis** | Flag high-risk dependencies, add contingency buffer (10-20%), define mitigations |
| **6. Gate Validation** | Verify all epics scheduled, phase ordering respected, critical path correct, dates achievable, period boundaries respected |

## Mandatory User Questions

### Q1: Start Date
When will the team start? Format: YYYY-MM-DD

### Q2: Team Composition
How many developers? Options: 1 (solo), 2 (pair), 3-4 (squad), 5+ (large team)

### Q3: Delivery Cadence
Options: Sprints (1-2 weeks), Cycles (1-3 months), Continuous (no fixed intervals)

### Q4 (if Sprints/Cycles): Period Configuration
- Duration: 1w, 2w, 1mo, 2mo, 3mo
- Start date: YYYY-MM-DD

### Q5: Human Validation Overhead (velocity multiplier)
| Option | Multiplier | Example |
|--------|-----------|---------|
| Minimal validation | 1.2x | 4h AI → 4.8h adjusted |
| Standard validation ← recommended | 1.5x | 4h AI → 6.0h adjusted |
| Deep validation | 2.0x | 4h AI → 8.0h adjusted |
| Heavy rework | 2.5x | 4h AI → 10.0h adjusted |
| Custom | user-specified | — |

## Velocity Calculation Formula

```
adjusted_hours = ai_estimate × multiplier
calendar_hours = adjusted_hours ÷ 0.90
calendar_days  = calendar_hours ÷ 8 ÷ team_size
task_days      = calendar_days + taura_days

Where:
  ai_estimate = per epic, from tasks.md Summary table (AI-agent-hours)
  0.90        = capacity utilization (AI Agent standard)
  taura_days  = 0 (Development/Delivery) | 5 (Quality) | 10 (Quality integration)
```

## Period Boundary Rules (Sprint/Cycle)

For each task, check: `task_end_date <= period_end_date`
- If yes → fits completely (✅)
- If no → spill over (⚠️): allocate days split across periods

Continuous delivery: no period boundaries — tasks scheduled by dependency and capacity only.

## Critical Path Analysis

1. Build dependency graph from tasks.md (epic dependencies + plan-phase ordering)
2. Calculate Earliest Start Date (ESD) per epic
3. Calculate Latest Start Date (LSD) without delaying project
4. Epics where ESD = LSD → on critical path (zero slack)

## Output Files

MUST generate both:
- `docs/pre-dev/{feature}/delivery-roadmap.md` — human-readable
- `docs/pre-dev/{feature}/delivery-roadmap.json` — machine-readable (see schema below)

**Topology-aware paths:**

| Structure | Files Generated |
|-----------|-----------------|
| single-repo | `docs/pre-dev/{feature}/delivery-roadmap.{md,json}` |
| monorepo | Index + per-module `{module.path}/docs/pre-dev/{feature}/delivery-roadmap.{md,json}` |
| multi-repo | Per-repo `{repo.path}/docs/pre-dev/{feature}/delivery-roadmap.{md,json}` |

## JSON Output Schema

> Schema note: `tasks[]` rows are the plan's **epics** (IDs `E-X.Y`). The field name
> is retained for schema stability (`version 1.0.0`); `tasks[].phase` remains the
> work-type classifier (development|quality|delivery) — it is NOT the plan phase.
> Plan phases surface through `milestones[]`, which SHOULD align to phase boundaries
> when the cadence allows.

```json
{
  "version": "1.0.0",
  "gate": 9,
  "feature": "{feature-name}",
  "generatedAt": "ISO-8601",
  "dates": {
    "startDate": "YYYY-MM-DD",
    "endDate": "YYYY-MM-DD",
    "mvpEndDate": "YYYY-MM-DD or null",
    "totalDuration": "5.5 weeks"
  },
  "velocity": {
    "teamSize": 2,
    "utilizationRate": 0.9,
    "humanValidationMultiplier": 1.5,
    "multiplierSource": "default | custom"
  },
  "deliveryCadence": {
    "type": "sprint | cycle | continuous",
    "periodDuration": "2 weeks | 1 month | null",
    "periodStartDate": "YYYY-MM-DD or null"
  },
  "tasks": [{
    "id": "T-001",
    "description": "...",
    "aiEstimate": "4.5h",
    "adjusted": "6.75h",
    "calendar": "7.5h",
    "days": 0.94,
    "phase": "development | quality | delivery",
    "tauraDays": 0,
    "dependencies": [],
    "assignee": "Backend | Frontend | DevOps | QA",
    "status": "ready | blocked | in_progress | completed",
    "onCriticalPath": true
  }],
  "milestones": [{
    "name": "Sprint 1",
    "type": "sprint | cycle | milestone",
    "startDate": "YYYY-MM-DD",
    "targetDate": "YYYY-MM-DD",
    "taskIds": ["T-001"],
    "deliverable": "...",
    "spillOvers": []
  }],
  "criticalPath": {
    "taskIds": ["T-001", "T-002"],
    "totalDuration": "5.5 weeks",
    "minimumProjectDuration": "5.5 weeks"
  },
  "risks": [{"taskIds": ["T-001"], "level": "high", "impact": "...", "mitigation": "..."}],
  "cycleCapacity": {
    "grossDays": 28,
    "bugBufferDays": 5.6,
    "availableDays": 22.4,
    "allocatedDays": 19.2,
    "slackDays": 3.2
  },
  "contingencyBuffer": {"percentage": 15, "days": 4},
  "confidenceScore": 85
}
```

### JSON Validation Rules

1. `dates.startDate` and `dates.endDate` REQUIRED — not null
2. `tasks` array MUST have ≥1 item
3. Every task MUST have `id`, `description`, `aiEstimate`, `adjusted`, `calendar`, `days`
4. `confidenceScore` MUST be 0-100
5. `milestones` MUST have ≥1 item
6. `criticalPath.taskIds` MUST reference valid task IDs
7. `version` MUST be `"1.0.0"`
8. `milestones[].taskIds` and `spillOvers` MUST reference valid task IDs
9. `velocity.teamSize` > 0
10. `cycleCapacity` MUST be present with all 5 fields
11. `cycleCapacity.availableDays` = `grossDays - bugBufferDays`
12. `cycleCapacity.slackDays` = `availableDays - allocatedDays` (negative = over-committed → add risk)
13. `tasks[].phase` ∈ `{development, quality, delivery}`; `tauraDays` must match: 0 for dev/delivery, 5 or 10 for quality
14. Continuous cadence: `periodDuration` = null, `periodStartDate` = null, milestones type = `milestone`, spillOvers = `[]`

## Gate Validation Checklist

| Category | Requirements |
|----------|--------------|
| **Input Completeness** | Start date, team composition, cadence, period config (if sprint/cycle), velocity multiplier all confirmed |
| **Dependency Analysis** | Graph built, plan-phase ordering respected, critical path identified, parallel streams defined, no circular deps |
| **Capacity Planning** | Velocity calculated, resources allocated, bottlenecks identified, ≤80% utilization |
| **Delivery Breakdown** | Periods match cadence, boundaries calculated, spill overs identified, delivery goals measurable |
| **Risk Management** | High-risk deps flagged, buffer added (10-20%), mitigations defined |
| **Timeline Realism** | No best-case assumptions, critical path validated, dates achievable |

**Gate Result:** ✅ PASS → Ready for execution | ⚠️ CONDITIONAL (adjust) | ❌ FAIL (rework)

## Confidence Scoring

| Factor | Points | Criteria |
|--------|--------|----------|
| Dependency Clarity | 0-30 | All mapped: 30, Most clear: 20, Ambiguous: 10 |
| Capacity Realism | 0-25 | Realistic (70-80%): 25, Optimistic (90%+): 10, Undefined: 0 |
| Critical Path Validated | 0-25 | Full graph: 25, Partial: 15, Assumptions: 5 |
| Risk Mitigation | 0-20 | All flagged + mitigated: 20, Some: 10, None: 0 |

Score 80+: proceed with confidence. 50-79: flag assumptions. <50: resolve unknowns before committing dates.
