---
name: project-health-check
description: |
  Individual project health assessment skill for evaluating project status across
  multiple dimensions. Provides early warning of troubled projects.

trigger: |
  - Need to assess single project health
  - Project showing warning signs
  - Milestone review required
  - Stakeholder escalation received

skip_when: |
  - Portfolio-level view → use portfolio-planning
  - Resource-only issue → use resource-allocation
  - Risk-only analysis → use risk-management

related:
  complementary: [portfolio-planning, risk-management]
---

# Project Health Check Skill

Systematic assessment of individual project health across multiple dimensions.

## Purpose

This skill provides a framework for:
- Comprehensive project status assessment
- Early warning identification
- Root cause analysis
- Recovery recommendation
- Stakeholder communication

---

## Prerequisites

Before health check, ensure:

| Prerequisite | Required For | Source |
|--------------|--------------|--------|
| Project baseline | Variance calculation | Project plan |
| Current status data | Health assessment | Project manager |
| Stakeholder feedback | Satisfaction assessment | Stakeholders |
| Risk register | Risk health | Risk analyst |

---

## Health Check Dimensions

### Dimension 1: Schedule Health

**Metrics:**

| Metric | Formula | Green | Yellow | Red |
|--------|---------|-------|--------|-----|
| SPI | EV / PV | >= 0.95 | 0.85-0.94 | < 0.85 |
| Schedule Variance | EV - PV | >= 0 | -5% to 0 | < -5% |
| Milestone Status | On-time % | >= 90% | 70-89% | < 70% |

**Assessment Questions:**
- Is the project on schedule?
- Are milestones being met?
- What is causing any delays?
- Is the critical path protected?

---

### Dimension 2: Cost Health

**Metrics:**

| Metric | Formula | Green | Yellow | Red |
|--------|---------|-------|--------|-----|
| CPI | EV / AC | >= 0.95 | 0.85-0.94 | < 0.85 |
| Cost Variance | EV - AC | >= 0 | -5% to 0 | < -5% |
| EAC vs Budget | EAC / BAC | <= 1.05 | 1.05-1.15 | > 1.15 |

**Assessment Questions:**
- Is the project within budget?
- What is driving cost variance?
- Is the estimate at completion acceptable?
- Are there unplanned costs emerging?

---

### Dimension 3: Scope Health

**Metrics:**

| Metric | Green | Yellow | Red |
|--------|-------|--------|-----|
| Scope Changes | < 3 | 3-5 | > 5 |
| Change Impact | < 5% baseline | 5-10% | > 10% |
| Requirements Stability | Stable | Some changes | Significant flux |

**Assessment Questions:**
- Is scope under control?
- How many changes since baseline?
- What is driving scope changes?
- Is there scope creep occurring?

---

### Dimension 4: Quality Health

**Metrics:**

| Metric | Green | Yellow | Red |
|--------|-------|--------|-----|
| Defect Rate | Below target | At target | Above target |
| Rework % | < 10% | 10-20% | > 20% |
| Test Pass Rate | > 95% | 85-95% | < 85% |

**Assessment Questions:**
- Is quality acceptable?
- What is the defect trend?
- Is rework manageable?
- Are acceptance criteria being met?

---

### Dimension 5: Risk Health

**Metrics:**

| Metric | Green | Yellow | Red |
|--------|-------|--------|-----|
| Open Critical Risks | 0 | 1-2 | > 2 |
| Risk Trend | Decreasing | Stable | Increasing |
| Mitigation Progress | On track | Delayed | Blocked |

**Assessment Questions:**
- Are risks being managed?
- Are mitigations effective?
- Any new critical risks?
- Are issues being resolved?

---

### Dimension 6: Stakeholder Health

**Metrics:**

| Metric | Green | Yellow | Red |
|--------|-------|--------|-----|
| Stakeholder Satisfaction | Satisfied | Concerns | Escalations |
| Communication Effectiveness | Good | Gaps noted | Major issues |
| Decision Timeliness | Timely | Some delays | Blocked |

**Assessment Questions:**
- Are stakeholders satisfied?
- Is communication effective?
- Are decisions being made timely?
- Any relationship issues?

---

## Health Check Gates

### Gate 1: Data Collection

**Objective:** Gather current project data

**Actions:**
1. Collect schedule data (actuals, forecasts)
2. Collect cost data (actuals, forecasts)
3. Review scope changes
4. Review quality metrics
5. Update risk register
6. Gather stakeholder feedback

**Output:** `docs/pmo/{date}/project-{name}-data.md`

---

### Gate 2: Health Assessment

**Objective:** Assess each dimension and overall health

**Actions:**
1. Score each dimension (1-10)
2. Calculate overall health score
3. Identify red flags
4. Document root causes

**Health Score Calculation:**

| Dimension | Weight |
|-----------|--------|
| Schedule | 25% |
| Cost | 20% |
| Scope | 15% |
| Quality | 20% |
| Risk | 10% |
| Stakeholder | 10% |

**Overall Score Interpretation:**
- 8-10: Healthy
- 6-7.9: Manageable
- 4-5.9: At Risk
- < 4: Critical

**Output:** `docs/pmo/{date}/project-{name}-assessment.md`

---

### Gate 3: Recommendations

**Objective:** Provide actionable recommendations

**Actions:**
1. Prioritize issues by impact
2. Identify quick wins
3. Recommend recovery actions
4. Define success criteria

**Recommendation Categories:**

| Category | Urgency | Examples |
|----------|---------|----------|
| **Immediate** | This week | Escalation, resource injection |
| **Short-term** | This month | Process change, replan |
| **Medium-term** | This quarter | Restructure, descope |
| **Long-term** | Future | Lessons learned, prevention |

**Output:** `docs/pmo/{date}/project-{name}-recommendations.md`

---

## Anti-Rationalization Table

See [shared-patterns/anti-rationalization.md](../shared-patterns/anti-rationalization.md) for universal anti-rationalizations.

### Health Check-Specific Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "PM says project is green" | Self-reported status often optimistic. Verify with data. | **Validate with metrics** |
| "One dimension is off, overall is fine" | One critical dimension can sink a project. | **Address all yellow/red dimensions** |
| "Wait and see if it improves" | Delays compound problems. Early intervention is cheaper. | **Act on warning signs** |
| "They're aware of the issues" | Awareness ≠ action. Verify mitigation progress. | **Confirm corrective actions** |

---

## Pressure Resistance

See [shared-patterns/pressure-resistance.md](../shared-patterns/pressure-resistance.md) for universal pressure scenarios.

### Health Check-Specific Pressures

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| "Make the status green for the exec report" | "Status must reflect reality. Will provide accurate status with context and recovery plan." |
| "Don't dig into that dimension" | "All dimensions must be assessed. Selective assessment misses problems." |
| "The PM has it under control" | "PM optimism is natural. Independent assessment provides balance." |

---

## Blocker Criteria - STOP and Report

**ALWAYS pause and report blocker for:**

| Situation | Required Action |
|-----------|-----------------|
| Overall health < 4 (Critical) | STOP. Immediate executive escalation required. |
| Multiple dimensions Red | STOP. Recovery intervention needed. |
| Data unavailable for assessment | STOP. Cannot assess without data. Request information. |
| Stakeholder loss of confidence | STOP. Relationship repair needed before project work. |

---

## Output Format

### Health Check Report

```markdown
# Project Health Check - [Project Name] - [Date]

## Overall Health Score: X/10 - [Green/Yellow/Red]

## Dimension Scores

| Dimension | Score | Status | Trend |
|-----------|-------|--------|-------|
| Schedule | X/10 | G/Y/R | Up/Stable/Down |
| Cost | X/10 | G/Y/R | Up/Stable/Down |
| Scope | X/10 | G/Y/R | Up/Stable/Down |
| Quality | X/10 | G/Y/R | Up/Stable/Down |
| Risk | X/10 | G/Y/R | Up/Stable/Down |
| Stakeholder | X/10 | G/Y/R | Up/Stable/Down |

## Key Findings

### Red Flags
1. [Finding with evidence]

### Yellow Flags
1. [Finding with evidence]

### Positive Signs
1. [Finding with evidence]

## Root Cause Analysis

| Issue | Root Cause | Impact |
|-------|------------|--------|
| [Issue] | [Cause] | [Impact] |

## Recommendations

### Immediate (This Week)
1. [Action] - Owner: [Name]

### Short-term (This Month)
1. [Action] - Owner: [Name]

## Decisions Required

1. [Decision needed with options]
```

---

## Execution Report

Base metrics per [shared-patterns/execution-report.md](../shared-patterns/execution-report.md):

| Metric | Value |
|--------|-------|
| Analysis Date | YYYY-MM-DD |
| Scope | [Project name] |
| Duration | Xh Ym |
| Result | COMPLETE/PARTIAL/BLOCKED |

### Health Check-Specific Details

| Metric | Value |
|--------|-------|
| health_score | X/10 |
| schedule_variance | X% |
| cost_variance | X% |
| scope_changes | N |
