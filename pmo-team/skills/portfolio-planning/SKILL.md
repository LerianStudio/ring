---
name: portfolio-planning
description: |
  Strategic portfolio planning skill for multi-project coordination, capacity assessment,
  and portfolio optimization. Provides framework for portfolio-level decision making.

trigger: |
  - Need to assess portfolio health
  - Planning portfolio for next quarter/year
  - Evaluating new project against portfolio
  - Rebalancing portfolio priorities

skip_when: |
  - Single project planning → use pre-dev-feature
  - Immediate status report → use executive-reporting
  - Resource-only analysis → use resource-allocation

related:
  similar: [pre-dev-feature]
  complementary: [resource-allocation, risk-management, executive-reporting]
---

# Portfolio Planning Skill

Strategic portfolio planning for multi-project coordination and optimization.

## Purpose

This skill provides a systematic approach to:
- Assess current portfolio health
- Evaluate strategic alignment
- Plan portfolio composition
- Optimize resource allocation across projects
- Balance risk across portfolio

---

## Prerequisites

Before starting portfolio planning, ensure:

| Prerequisite | Required For | Source |
|--------------|--------------|--------|
| Project list | Portfolio scope | Project registry |
| Strategic objectives | Alignment scoring | Strategy documents |
| Resource availability | Capacity planning | Resource planner |
| Budget constraints | Financial planning | Finance team |

---

## Portfolio Planning Gates

### Gate 1: Portfolio Inventory

**Objective:** Create complete picture of current portfolio

**Actions:**
1. List all active projects
2. Capture status of each project
3. Document resource allocations
4. Identify dependencies

**Output:** `docs/pmo/{date}/portfolio-inventory.md`

**Checklist:**
- [ ] All active projects listed
- [ ] Status captured (Green/Yellow/Red)
- [ ] Resources identified per project
- [ ] Dependencies documented

---

### Gate 2: Strategic Alignment Assessment

**Objective:** Evaluate how each project aligns with strategic objectives

**Actions:**
1. Map projects to strategic objectives
2. Score alignment (1-5 scale)
3. Identify orphan projects (no strategic link)
4. Flag misaligned projects

**Alignment Scoring:**

| Score | Meaning |
|-------|---------|
| 5 | Directly enables strategic objective |
| 4 | Strongly supports strategic objective |
| 3 | Moderately supports strategy |
| 2 | Weak strategic connection |
| 1 | No clear strategic value |

**Output:** `docs/pmo/{date}/strategic-alignment.md`

---

### Gate 3: Capacity Assessment

**Objective:** Understand portfolio capacity constraints

**Actions:**
1. Aggregate resource demand across projects
2. Compare to available capacity
3. Identify over/under allocation
4. Document skill gaps

**Dispatch:** `resource-planner` for detailed analysis

**Output:** `docs/pmo/{date}/capacity-assessment.md`

---

### Gate 4: Risk Portfolio View

**Objective:** Aggregate and correlate risks across portfolio

**Actions:**
1. Collect project-level risks
2. Identify correlated risks
3. Assess portfolio risk exposure
4. Plan portfolio-level mitigations

**Dispatch:** `risk-analyst` for detailed analysis

**Output:** `docs/pmo/{date}/portfolio-risks.md`

---

### Gate 5: Portfolio Optimization

**Objective:** Recommend portfolio changes for optimal value delivery

**Actions:**
1. Analyze portfolio balance (run/grow/transform)
2. Identify optimization opportunities
3. Recommend project prioritization
4. Propose resource reallocation

**Optimization Criteria:**

| Criterion | Weight | Description |
|-----------|--------|-------------|
| Strategic value | 30% | Alignment with objectives |
| Resource efficiency | 25% | Resource utilization optimization |
| Risk balance | 20% | Portfolio risk distribution |
| Dependencies | 15% | Dependency health |
| Timeline | 10% | Schedule alignment |

**Output:** `docs/pmo/{date}/portfolio-recommendations.md`

---

## Anti-Rationalization Table

See [shared-patterns/anti-rationalization.md](../shared-patterns/anti-rationalization.md) for universal anti-rationalizations.

### Portfolio-Specific Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "We know our portfolio well" | Familiarity breeds blind spots. Fresh analysis required. | **Complete full inventory** |
| "All projects are strategic" | If everything is strategic, nothing is. Differentiation required. | **Score alignment objectively** |
| "Capacity is fine, teams said so" | Self-reported capacity often optimistic. Validation required. | **Verify with utilization data** |
| "Risk aggregation is overkill" | Portfolio risk > sum of project risks. Correlation matters. | **Aggregate and correlate risks** |

---

## Pressure Resistance

See [shared-patterns/pressure-resistance.md](../shared-patterns/pressure-resistance.md) for universal pressure scenarios.

### Portfolio-Specific Pressures

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| "Just add this project, it's approved" | "Approval ≠ capacity. Portfolio impact assessment required before adding." |
| "Don't question the strategic projects" | "All projects require alignment verification. No exemptions for labeled 'strategic' projects." |
| "We don't have time for full planning" | "Incomplete planning causes downstream delays. Completing full planning cycle." |

---

## Blocker Criteria - STOP and Report

**ALWAYS pause and report blocker for:**

| Situation | Required Action |
|-----------|-----------------|
| Portfolio capacity exceeded by >20% | STOP. Report overload. Wait for prioritization decision. |
| Strategic objectives unclear | STOP. Cannot score alignment. Request strategy clarification. |
| Resource data unavailable | STOP. Cannot assess capacity. Request resource information. |
| Multiple high-risk projects correlated | STOP. Report compound risk. Wait for risk mitigation decision. |

---

## Output Format

### Portfolio Status Summary

```markdown
# Portfolio Status Summary - [Date]

## Portfolio Overview

| Metric | Value | Status |
|--------|-------|--------|
| Active Projects | N | - |
| Total Investment | $X | - |
| Capacity Utilization | X% | Green/Yellow/Red |
| Portfolio Risk Score | X/10 | Green/Yellow/Red |

## Strategic Alignment

| Objective | Projects | Coverage |
|-----------|----------|----------|
| [Objective 1] | [List] | X% |
| [Objective 2] | [List] | X% |

## Health Summary

| Status | Count | Projects |
|--------|-------|----------|
| Green | N | [List] |
| Yellow | N | [List] |
| Red | N | [List] |

## Recommendations

1. [Recommendation with rationale]
2. [Recommendation with rationale]

## Decisions Required

1. [Decision needed with options]
2. [Decision needed with options]
```

---

## Execution Report

Base metrics per [shared-patterns/execution-report.md](../shared-patterns/execution-report.md):

| Metric | Value |
|--------|-------|
| Analysis Date | YYYY-MM-DD |
| Scope | [Portfolio name/scope] |
| Duration | Xh Ym |
| Result | COMPLETE/PARTIAL/BLOCKED |

### Portfolio-Specific Details

| Metric | Value |
|--------|-------|
| projects_reviewed | N |
| capacity_utilization | X% |
| strategic_alignment_avg | X.X/5 |
| recommendations_count | N |
