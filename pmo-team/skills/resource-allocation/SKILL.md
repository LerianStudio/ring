---
name: resource-allocation
description: |
  Resource capacity planning and allocation skill for managing people and skills
  across multiple projects. Identifies conflicts, gaps, and optimization opportunities.

trigger: |
  - Need to allocate resources to projects
  - Capacity planning for upcoming work
  - Resource conflict resolution
  - Skills gap analysis

skip_when: |
  - Single project staffing → use ring-pm-team
  - Cost analysis → use ring-finops-team
  - Project status → use project-health-check

related:
  complementary: [portfolio-planning, risk-management]
---

# Resource Allocation Skill

Systematic resource planning across portfolio for optimal utilization.

## Purpose

This skill provides a framework for:
- Capacity planning across projects
- Resource conflict identification
- Skills gap analysis
- Allocation optimization
- Utilization monitoring

---

## Prerequisites

Before resource allocation, ensure:

| Prerequisite | Required For | Source |
|--------------|--------------|--------|
| Resource inventory | Capacity baseline | HR/Resource management |
| Project demands | Allocation needs | Project managers |
| Skills matrix | Gap analysis | HR/Training |
| Availability calendar | Time planning | Team calendars |

---

## Resource Allocation Gates

### Gate 1: Resource Inventory

**Objective:** Establish baseline of available resources

**Actions:**
1. List all available resources (people, teams)
2. Document skills per resource
3. Capture availability (FTE, dates)
4. Note constraints (PTO, training, etc.)

**Output:** `docs/pmo/{date}/resource-inventory.md`

**Inventory Template:**

| Resource | Role | Skills | Availability | Current Allocation |
|----------|------|--------|--------------|-------------------|
| [Name] | [Role] | [Skills] | [FTE] | [Projects] |

---

### Gate 2: Demand Analysis

**Objective:** Understand resource demand across portfolio

**Actions:**
1. Collect resource requests from projects
2. Categorize by role/skill
3. Map to timeline
4. Aggregate total demand

**Demand Template:**

| Project | Role/Skill | FTE Needed | Start | End | Priority |
|---------|-----------|------------|-------|-----|----------|
| [Project] | [Role] | [FTE] | [Date] | [Date] | [1-5] |

**Output:** `docs/pmo/{date}/resource-demand.md`

---

### Gate 3: Gap Analysis

**Objective:** Identify mismatches between supply and demand

**Actions:**
1. Compare inventory to demand
2. Identify capacity gaps (over/under)
3. Identify skill gaps
4. Document timeline conflicts

**Gap Types:**

| Gap Type | Definition | Impact |
|----------|------------|--------|
| **Capacity Gap** | More work than people | Project delays, burnout |
| **Skill Gap** | Work requires unavailable skills | Quality issues, training need |
| **Timeline Gap** | Resources available wrong time | Schedule conflicts |
| **Quality Gap** | Available skills below required level | Supervision needed |

**Output:** `docs/pmo/{date}/resource-gaps.md`

---

### Gate 4: Conflict Resolution

**Objective:** Resolve resource conflicts across projects

**Actions:**
1. List all conflicts
2. Analyze priority-based resolution
3. Propose alternatives (hire, defer, redistribute)
4. Document trade-offs

**Resolution Options:**

| Option | When to Use | Trade-off |
|--------|-------------|-----------|
| **Prioritize** | Clear priority difference | Lower priority project delayed |
| **Share** | Skills transferable | Context switching cost |
| **Hire** | Long-term need | Time to onboard, cost |
| **Contract** | Short-term need | Cost, knowledge transfer |
| **Defer** | Flexibility exists | Opportunity cost |
| **Descope** | Scope flexibility | Feature reduction |

**Output:** `docs/pmo/{date}/conflict-resolution.md`

---

### Gate 5: Allocation Plan

**Objective:** Create optimal resource allocation plan

**Actions:**
1. Assign resources to projects
2. Document allocation percentages
3. Define handoff points
4. Create monitoring plan

**Allocation Template:**

| Resource | Project | Allocation % | Start | End | Notes |
|----------|---------|--------------|-------|-----|-------|
| [Name] | [Project] | [%] | [Date] | [Date] | [Notes] |

**Utilization Target:** 70-85% (leaves buffer for issues)

**Output:** `docs/pmo/{date}/allocation-plan.md`

---

## Anti-Rationalization Table

See [shared-patterns/anti-rationalization.md](../shared-patterns/anti-rationalization.md) for universal anti-rationalizations.

### Resource-Specific Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Team said they can handle it" | Optimism bias is real. Validate with data. | **Verify against utilization data** |
| "We'll figure it out as we go" | Resource chaos causes project failure. Plan upfront. | **Complete allocation plan** |
| "100% utilization is optimal" | 100% = no buffer for issues, burnout. 70-85% is optimal. | **Plan for sustainable utilization** |
| "Sharing resources is fine" | Context switching costs 20-40% productivity. Account for it. | **Include switching cost in allocation** |

---

## Pressure Resistance

See [shared-patterns/pressure-resistance.md](../shared-patterns/pressure-resistance.md) for universal pressure scenarios.

### Resource-Specific Pressures

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| "Just assign everyone to both projects" | "100% allocation to multiple projects is impossible. Creating realistic allocation plan." |
| "We don't have time to document skills" | "Skills documentation prevents misallocation. Completing skills inventory." |
| "The team lead said resources are available" | "Trust and verify. Confirming with actual utilization data before committing." |

---

## Blocker Criteria - STOP and Report

**ALWAYS pause and report blocker for:**

| Situation | Required Action |
|-----------|-----------------|
| Demand exceeds capacity by >20% | STOP. Report gap. Wait for prioritization or hiring decision. |
| Critical skill unavailable | STOP. Report skill gap. Wait for training/hiring decision. |
| Key person single point of failure | STOP. Report risk. Wait for mitigation decision. |
| Conflicting executive commitments | STOP. Escalate conflict. Wait for resolution. |

---

## Output Format

### Resource Allocation Summary

```markdown
# Resource Allocation Summary - [Date]

## Capacity Overview

| Metric | Value | Status |
|--------|-------|--------|
| Total FTE Available | X | - |
| Total FTE Demanded | X | - |
| Utilization Rate | X% | Green/Yellow/Red |
| Open Positions | N | - |

## Allocation by Project

| Project | FTE Allocated | Utilization | Status |
|---------|--------------|-------------|--------|
| [Project] | X | X% | Green/Yellow/Red |

## Gaps Identified

| Gap Type | Description | Impact | Resolution |
|----------|-------------|--------|------------|
| [Type] | [Description] | [Impact] | [Proposed] |

## Conflicts

| Conflict | Projects | Resource | Proposed Resolution |
|----------|----------|----------|---------------------|
| [ID] | [Projects] | [Resource] | [Resolution] |

## Recommendations

1. [Recommendation with rationale]
2. [Recommendation with rationale]

## Decisions Required

1. [Decision needed with options]
```

---

## Execution Report

Base metrics per [shared-patterns/execution-report.md](../shared-patterns/execution-report.md):

| Metric | Value |
|--------|-------|
| Analysis Date | YYYY-MM-DD |
| Scope | [Portfolio/Projects] |
| Duration | Xh Ym |
| Result | COMPLETE/PARTIAL/BLOCKED |

### Resource-Specific Details

| Metric | Value |
|--------|-------|
| roles_analyzed | N |
| allocation_conflicts | N |
| utilization_average | X% |
| gap_count | N |
