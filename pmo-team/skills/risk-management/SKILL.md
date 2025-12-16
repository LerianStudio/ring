---
name: risk-management
description: |
  Portfolio-level risk management skill for identifying, assessing, and mitigating
  risks across multiple projects. Maintains RAID logs and tracks risk responses.

trigger: |
  - Need portfolio risk assessment
  - Creating or updating RAID log
  - Risk response planning
  - Risk correlation analysis

skip_when: |
  - Single project risk → handle in project scope
  - Financial risk only → use ring-finops-team
  - Technical risk in code → use qa-analyst

related:
  complementary: [portfolio-planning, project-health-check]
---

# Risk Management Skill

Systematic portfolio-level risk identification, assessment, and mitigation.

## Purpose

This skill provides a framework for:
- Portfolio risk identification
- Risk assessment and scoring
- Risk correlation analysis
- Mitigation planning
- RAID log management

---

## Prerequisites

Before risk assessment, ensure:

| Prerequisite | Required For | Source |
|--------------|--------------|--------|
| Project risk registers | Risk aggregation | Project managers |
| Historical risk data | Pattern identification | Previous projects |
| Stakeholder input | Risk identification | Key stakeholders |
| Impact criteria | Risk scoring | PMO standards |

---

## Risk Management Gates

### Gate 1: Risk Identification

**Objective:** Identify all portfolio-level risks

**Actions:**
1. Collect project-level risks
2. Identify cross-project risks
3. Capture portfolio-level risks
4. Document assumptions and dependencies

**Risk Categories:**

| Category | Examples |
|----------|----------|
| **Strategic** | Market changes, competition, regulation |
| **Resource** | Key person departure, skill shortage, capacity |
| **Technical** | Technology obsolescence, integration, security |
| **Financial** | Budget cuts, cost overruns, currency |
| **Schedule** | Dependencies, delays, scope creep |
| **External** | Vendor, regulatory, geopolitical |

**Output:** `docs/pmo/{date}/risk-register.md`

---

### Gate 2: Risk Assessment

**Objective:** Assess probability and impact of each risk

**Actions:**
1. Assess probability (1-5 scale)
2. Assess impact (1-5 scale)
3. Calculate risk score (P x I)
4. Assign severity level

**Risk Severity Matrix:**

See [shared-patterns/pmo-metrics.md](../shared-patterns/pmo-metrics.md) for risk severity matrix.

| Impact / Likelihood | Low (1-2) | Medium (3) | High (4-5) |
|---------------------|-----------|------------|------------|
| **High (4-5)** | Medium | High | Critical |
| **Medium (3)** | Low | Medium | High |
| **Low (1-2)** | Low | Low | Medium |

**Output:** `docs/pmo/{date}/risk-assessment.md`

---

### Gate 3: Risk Correlation

**Objective:** Identify correlated risks across portfolio

**Actions:**
1. Identify shared risk factors
2. Map risk dependencies
3. Calculate compound risk exposure
4. Flag correlated critical risks

**Correlation Types:**

| Type | Description | Action |
|------|-------------|--------|
| **Shared cause** | Same root cause affects multiple projects | Mitigate root cause |
| **Sequential** | One risk triggers another | Plan cascade response |
| **Resource** | Same resource/skill shortage | Diversify or hire |
| **Vendor** | Same vendor dependency | Diversify suppliers |

**Output:** `docs/pmo/{date}/risk-correlation.md`

---

### Gate 4: Response Planning

**Objective:** Create mitigation plans for significant risks

**Actions:**
1. Select response strategy per risk
2. Define mitigation actions
3. Assign owners and dates
4. Allocate contingency

**Response Strategies:**

See [shared-patterns/pmo-metrics.md](../shared-patterns/pmo-metrics.md) for response types.

| Response | When to Use | Example |
|----------|-------------|---------|
| **Avoid** | Risk unacceptable, can change scope | Remove risky feature |
| **Transfer** | Risk better managed by others | Insurance, outsource |
| **Mitigate** | Reduce probability or impact | Testing, redundancy |
| **Accept** | Cost of mitigation > impact | Document and monitor |

**Output:** `docs/pmo/{date}/risk-response-plan.md`

---

### Gate 5: RAID Log Update

**Objective:** Maintain comprehensive RAID log

**Actions:**
1. Update Risk section
2. Update Assumptions section
3. Update Issues section
4. Update Dependencies section

**RAID Categories:**

| Category | Contents | Review Frequency |
|----------|----------|------------------|
| **R**isks | Potential future issues | Weekly |
| **A**ssumptions | Believed true, not verified | At milestones |
| **I**ssues | Current problems requiring action | Daily |
| **D**ependencies | External inputs/outputs | Weekly |

**Output:** `docs/pmo/{date}/raid-log.md`

---

## Anti-Rationalization Table

See [shared-patterns/anti-rationalization.md](../shared-patterns/anti-rationalization.md) for universal anti-rationalizations.

### Risk-Specific Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "We've seen this risk before" | Context changes. Each occurrence needs fresh assessment. | **Assess current state** |
| "Low probability, don't document" | Low probability × high impact = significant risk. | **Document ALL identified risks** |
| "Team will handle it" | Unplanned handling = crisis response. Plan required. | **Document response plan** |
| "Risk register is up to date" | Registers decay. Continuous validation required. | **Validate at every review** |
| "That won't happen" | Famous last words. Document and monitor. | **Document ALL risks** |

---

## Pressure Resistance

See [shared-patterns/pressure-resistance.md](../shared-patterns/pressure-resistance.md) for universal pressure scenarios.

### Risk-Specific Pressures

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| "Don't include that risk, it will worry people" | "Risk transparency is non-negotiable. Including with mitigation plan to provide balanced view." |
| "That's been mitigated, remove it" | "Mitigated risks remain in register until formally closed with evidence. Updating status, not removing." |
| "Risk assessment takes too long" | "Unassessed risks cause larger delays when they materialize. Completing assessment." |

---

## Blocker Criteria - STOP and Report

**ALWAYS pause and report blocker for:**

| Situation | Required Action |
|-----------|-----------------|
| Critical risk without mitigation plan | STOP. Escalate. Risk cannot be accepted without plan. |
| Multiple correlated critical risks | STOP. Report compound exposure. Wait for portfolio decision. |
| Risk owner not identified | STOP. Unowned risks are unmanaged. Require owner assignment. |
| Assumption invalidated | STOP. Trigger re-planning based on new reality. |

---

## Output Format

### Risk Summary

```markdown
# Portfolio Risk Summary - [Date]

## Risk Overview

| Metric | Value |
|--------|-------|
| Total Risks | N |
| Critical | N |
| High | N |
| Medium | N |
| Low | N |
| Mitigations Defined | N/N |
| Overdue Actions | N |

## Top Risks

| ID | Risk | Severity | Owner | Status |
|----|------|----------|-------|--------|
| R-001 | [Description] | Critical/High | [Owner] | [Status] |

## Risk Correlations

| Correlation | Risks | Combined Exposure | Action |
|-------------|-------|-------------------|--------|
| [ID] | [Risk IDs] | [Exposure] | [Action] |

## RAID Summary

| Category | Total | New | Closed | Overdue |
|----------|-------|-----|--------|---------|
| Risks | N | N | N | N |
| Assumptions | N | N | N | N |
| Issues | N | N | N | N |
| Dependencies | N | N | N | N |

## Recommendations

1. [Recommendation with rationale]
2. [Recommendation with rationale]

## Decisions Required

1. [Decision needed: Accept/Mitigate/Avoid risk X]
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

### Risk-Specific Details

| Metric | Value |
|--------|-------|
| risks_identified | N |
| risks_by_severity | C/H/M/L |
| mitigation_plans | N |
| overdue_actions | N |
