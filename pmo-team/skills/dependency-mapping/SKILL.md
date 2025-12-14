---
name: dependency-mapping
description: |
  Cross-project dependency mapping and analysis skill for identifying, tracking,
  and managing dependencies across portfolio projects.

trigger: |
  - Need to map project dependencies
  - Dependency conflict identified
  - Planning new project with dependencies
  - Critical path analysis needed

skip_when: |
  - Single project internal dependencies → handle in project scope
  - Resource dependencies only → use resource-allocation
  - Risk from dependencies → use risk-management

related:
  complementary: [portfolio-planning, risk-management]
---

# Dependency Mapping Skill

Systematic identification and management of cross-project dependencies.

## Purpose

This skill provides a framework for:
- Dependency identification
- Dependency classification
- Impact analysis
- Critical path identification
- Dependency tracking and management

---

## Prerequisites

Before dependency mapping, ensure:

| Prerequisite | Required For | Source |
|--------------|--------------|--------|
| Project schedules | Timeline analysis | Project managers |
| Project deliverables | Dependency identification | Project plans |
| External contracts | Vendor dependencies | Procurement |
| Integration points | Technical dependencies | Architecture |

---

## Dependency Types

### Internal Dependencies

| Type | Definition | Example |
|------|------------|---------|
| **Finish-to-Start (FS)** | B starts when A finishes | Development → Testing |
| **Start-to-Start (SS)** | B starts when A starts | Parallel workstreams |
| **Finish-to-Finish (FF)** | B finishes when A finishes | Code freeze → Doc freeze |
| **Start-to-Finish (SF)** | B finishes when A starts | Rare, shift handoff |

### External Dependencies

| Type | Definition | Risk Level |
|------|------------|------------|
| **Vendor** | Third-party delivery | Medium-High |
| **Regulatory** | Approval or certification | High |
| **Infrastructure** | Environment availability | Medium |
| **Integration** | API or system availability | Medium-High |
| **Resource** | Shared resource availability | Medium |

---

## Dependency Mapping Gates

### Gate 1: Dependency Identification

**Objective:** Identify all dependencies across portfolio

**Actions:**
1. Review project schedules for cross-project links
2. Interview project managers
3. Document deliverable handoffs
4. Identify external dependencies

**Identification Questions:**
- What does this project need from other projects?
- What does this project provide to other projects?
- What external inputs are needed?
- What must be complete before this can start?

**Output:** `docs/pmo/{date}/dependency-inventory.md`

---

### Gate 2: Dependency Classification

**Objective:** Classify dependencies by type and criticality

**Actions:**
1. Classify by dependency type (FS, SS, FF, SF)
2. Classify by source (internal/external)
3. Assess criticality (critical path/slack)
4. Document constraints and assumptions

**Criticality Assessment:**

| Level | Criteria | Management |
|-------|----------|------------|
| **Critical** | On critical path, no slack | Daily monitoring |
| **High** | < 1 week slack | Weekly monitoring |
| **Medium** | 1-4 weeks slack | Bi-weekly monitoring |
| **Low** | > 4 weeks slack | Monthly monitoring |

**Output:** `docs/pmo/{date}/dependency-classification.md`

---

### Gate 3: Impact Analysis

**Objective:** Understand impact of dependency failure

**Actions:**
1. Analyze schedule impact
2. Analyze cost impact
3. Identify cascade effects
4. Document mitigation options

**Impact Assessment Template:**

| Dependency | If Delayed By | Schedule Impact | Cost Impact | Cascade To |
|------------|---------------|-----------------|-------------|------------|
| [Dep] | 1 week | [Impact] | [Impact] | [Projects] |
| [Dep] | 2 weeks | [Impact] | [Impact] | [Projects] |
| [Dep] | 1 month | [Impact] | [Impact] | [Projects] |

**Output:** `docs/pmo/{date}/dependency-impact.md`

---

### Gate 4: Critical Path Analysis

**Objective:** Identify and protect the critical path

**Actions:**
1. Map critical path across projects
2. Identify dependencies on critical path
3. Analyze buffer/slack
4. Recommend protection measures

**Critical Path Visualization:**
```
Project A: [Task A1] → [Task A2] → [Deliverable A]
                                          ↓
Project B:                        [Task B1] → [Task B2] → [Deliverable B]
                                                                  ↓
Project C:                                               [Task C1] → [Task C2] → [Final]
```

**Protection Measures:**
- Buffer allocation
- Parallel path development
- Early warning triggers
- Contingency plans

**Output:** `docs/pmo/{date}/critical-path-analysis.md`

---

### Gate 5: Dependency Tracking Plan

**Objective:** Create ongoing tracking and management plan

**Actions:**
1. Define tracking frequency per criticality
2. Assign dependency owners
3. Create communication plan
4. Define escalation triggers

**Tracking Template:**

| Dependency | Owner | Update Freq | Status | Next Milestone | Risk |
|------------|-------|-------------|--------|----------------|------|
| [Dep] | [Owner] | [Freq] | [Status] | [Date: Milestone] | [Risk] |

**Escalation Triggers:**
- Critical dependency at risk
- External dependency delayed
- Cascade impact identified
- Owner not responding

**Output:** `docs/pmo/{date}/dependency-tracking-plan.md`

---

## Anti-Rationalization Table

See [shared-patterns/anti-rationalization.md](../shared-patterns/anti-rationalization.md) for universal anti-rationalizations.

### Dependency-Specific Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "We've documented the main dependencies" | Undocumented dependencies cause surprise delays. | **Document ALL dependencies** |
| "That's a soft dependency, not critical" | Soft dependencies become hard when they fail. | **Classify and track all** |
| "External vendor always delivers" | Past performance ≠ future guarantee. | **Track and verify externals** |
| "Projects will coordinate directly" | Ad-hoc coordination fails under pressure. | **Formal tracking required** |

---

## Pressure Resistance

See [shared-patterns/pressure-resistance.md](../shared-patterns/pressure-resistance.md) for universal pressure scenarios.

### Dependency-Specific Pressures

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| "We trust the other team, don't track" | "Trust doesn't prevent delays. Tracking enables early action." |
| "Too many dependencies to track" | "Complexity requires MORE tracking, not less. Will prioritize by criticality." |
| "Vendor said it's on track" | "Vendor assurance needs verification. Confirming with evidence." |

---

## Blocker Criteria - STOP and Report

**ALWAYS pause and report blocker for:**

| Situation | Required Action |
|-----------|-----------------|
| Critical dependency at risk | STOP. Immediate escalation. Cascade impact pending. |
| Circular dependency identified | STOP. Architectural issue requires resolution. |
| External dependency failed | STOP. Contingency activation required. |
| Dependency owner unresponsive | STOP. Escalate for owner assignment. |

---

## Output Format

### Dependency Map Summary

```markdown
# Cross-Project Dependency Map - [Date]

## Dependency Overview

| Metric | Value |
|--------|-------|
| Total Dependencies | N |
| Internal | N |
| External | N |
| On Critical Path | N |
| At Risk | N |

## Dependency Matrix

| From Project | To Project | Dependency | Type | Criticality | Status |
|--------------|------------|------------|------|-------------|--------|
| [Project] | [Project] | [Description] | [FS/SS/FF/SF] | [Crit/High/Med/Low] | [On Track/At Risk/Blocked] |

## Critical Path Dependencies

```
[Visual representation of critical path]
```

## External Dependencies

| Vendor/Source | Dependency | Due Date | Status | Contingency |
|---------------|------------|----------|--------|-------------|
| [Vendor] | [Dependency] | [Date] | [Status] | [Plan] |

## At-Risk Dependencies

| Dependency | Risk | Impact | Mitigation |
|------------|------|--------|------------|
| [Dep] | [Risk description] | [Impact] | [Mitigation] |

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

### Dependency-Specific Details

| Metric | Value |
|--------|-------|
| dependencies_total | N |
| critical_path_deps | N |
| external_deps | N |
| at_risk_deps | N |
