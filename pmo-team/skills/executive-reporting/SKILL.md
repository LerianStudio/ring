---
name: executive-reporting
description: |
  Executive communication and reporting skill for creating dashboards, status summaries,
  and board packages. Focuses on actionable insights for leadership.

trigger: |
  - Need executive status update
  - Board meeting preparation
  - Portfolio dashboard creation
  - Stakeholder escalation report

skip_when: |
  - Detailed project analysis → use project-health-check
  - Technical documentation → use ring-tw-team
  - Financial deep dive → use ring-finops-team

related:
  complementary: [portfolio-planning, project-health-check]
---

# Executive Reporting Skill

Creating effective executive communications that drive decisions and action.

## Purpose

This skill provides a framework for:
- Executive status summaries
- Portfolio dashboards
- Board packages
- Escalation reports
- Decision support materials

---

## Executive Communication Principles

### The Executive Pyramid

| Level | Content | Time |
|-------|---------|------|
| **Summary** | Key message in one sentence | 10 seconds |
| **Overview** | 3-5 key points | 1 minute |
| **Detail** | Supporting data and analysis | 5 minutes |
| **Appendix** | Full data for reference | As needed |

### What Executives Want

| They Want | They Don't Want |
|-----------|-----------------|
| Clear status (RAG) | Ambiguous status |
| Actionable insights | Information dumps |
| Decisions required | Problems without options |
| Trends and patterns | Raw data |
| Risks and mitigations | Surprises |
| Confidence in team | Excuses |

---

## Report Types

### Type 1: Portfolio Status Dashboard

**Audience:** Executive team
**Frequency:** Weekly/Monthly
**Length:** 1-2 pages

**Sections:**
1. Portfolio health summary (RAG)
2. Key metrics (SPI, CPI, utilization)
3. Exceptions requiring attention
4. Upcoming milestones
5. Decisions needed

---

### Type 2: Project Escalation Report

**Audience:** Sponsor/Executive
**Frequency:** As needed
**Length:** 1 page

**Sections:**
1. Issue summary (one sentence)
2. Impact assessment
3. Options with trade-offs
4. Recommendation
5. Decision requested

---

### Type 3: Board Package

**Audience:** Board of Directors
**Frequency:** Quarterly
**Length:** 5-10 pages

**Sections:**
1. Executive summary
2. Portfolio performance
3. Strategic initiative status
4. Key risks and mitigations
5. Resource and financial summary
6. Decisions and approvals needed
7. Appendix (detailed data)

---

### Type 4: Stakeholder Update

**Audience:** Key stakeholders
**Frequency:** Weekly/Bi-weekly
**Length:** 1 page

**Sections:**
1. Status summary
2. Accomplishments this period
3. Planned next period
4. Blockers/needs from stakeholders
5. Key dates

---

## Executive Reporting Gates

### Gate 1: Audience Analysis

**Objective:** Understand what the audience needs

**Actions:**
1. Identify primary audience
2. Understand their priorities
3. Determine decision authority
4. Assess communication preferences

**Audience Questions:**
- What decisions can they make?
- What do they worry about?
- How much time do they have?
- What format do they prefer?

**Output:** `docs/pmo/{date}/audience-analysis.md`

---

### Gate 2: Data Gathering

**Objective:** Collect accurate, current data

**Actions:**
1. Gather project status data
2. Collect metrics (SPI, CPI, etc.)
3. Update risk information
4. Verify with project managers

**Data Verification:**
- Cross-check with multiple sources
- Validate with PM before publishing
- Note any data gaps or assumptions
- Date-stamp all data

**Output:** `docs/pmo/{date}/report-data.md`

---

### Gate 3: Insight Development

**Objective:** Extract actionable insights from data

**Actions:**
1. Identify patterns and trends
2. Determine root causes
3. Develop recommendations
4. Prepare decision options

**Insight Framework:**
- **What?** - State the fact
- **So What?** - Explain why it matters
- **Now What?** - Recommend action

**Output:** `docs/pmo/{date}/report-insights.md`

---

### Gate 4: Report Creation

**Objective:** Create the executive report

**Actions:**
1. Apply appropriate template
2. Lead with conclusions
3. Support with evidence
4. Include clear call to action

**Quality Checklist:**
- [ ] Summary captures key message
- [ ] RAG status is clear and justified
- [ ] Decisions needed are explicit
- [ ] Recommendations are actionable
- [ ] Data is current and verified

**Output:** `docs/pmo/{date}/executive-report.md`

---

### Gate 5: Review and Delivery

**Objective:** Ensure quality and deliver effectively

**Actions:**
1. Internal review for accuracy
2. Get PM sign-off on project status
3. Prepare for questions
4. Deliver and follow up

**Pre-Delivery Checklist:**
- [ ] Spelling and formatting checked
- [ ] Numbers verified
- [ ] PM approved their project status
- [ ] Talking points prepared
- [ ] Follow-up actions noted

**Output:** Final report delivered

---

## Anti-Rationalization Table

See [shared-patterns/anti-rationalization.md](../shared-patterns/anti-rationalization.md) for universal anti-rationalizations.

### Executive Reporting-Specific Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Bad news can wait" | Delayed bad news = worse news. Executives need truth. | **Report immediately with context** |
| "Too much detail for executives" | Under-reporting creates blind spots. | **Provide right level of detail** |
| "Green because no complaints" | Silence ≠ health. Verify with data. | **Evidence-based status only** |
| "They'll ask if they want to know" | Proactive communication builds trust. | **Anticipate needs, don't wait** |
| "Keep it positive" | False positivity destroys credibility. | **Report reality with solutions** |

---

## Pressure Resistance

See [shared-patterns/pressure-resistance.md](../shared-patterns/pressure-resistance.md) for universal pressure scenarios.

### Executive Reporting-Specific Pressures

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| "Make the status green" | "Status must reflect reality. I'll provide accurate status with context and recovery plan." |
| "Don't mention that risk" | "Executives expect full picture. Including with mitigation status." |
| "Simplify it, they won't understand" | "Executives understand complexity. Will provide clear summary with detail available." |
| "We need this in 30 minutes" | "Quality over speed for executive comms. Will provide accurate summary in timeframe, full detail to follow." |

---

## Blocker Criteria - STOP and Report

**ALWAYS pause and report blocker for:**

| Situation | Required Action |
|-----------|-----------------|
| Data integrity questionable | STOP. Cannot report unreliable data. Verify before reporting. |
| PM disputes project status | STOP. Resolve disagreement before publishing. |
| Asked to misrepresent status | STOP. Cannot compromise integrity. Escalate if pressured. |
| Critical escalation discovered | STOP. Immediate verbal communication before written report. |

---

## Output Format

### Executive Status Report

```markdown
# Portfolio Status Report - [Date]

## Executive Summary

[One paragraph: Overall status, key achievements, primary concerns, decisions needed]

## Portfolio Health: [GREEN/YELLOW/RED]

| Metric | Value | Trend | Status |
|--------|-------|-------|--------|
| Projects On Track | X/Y (Z%) | Up/Down/Stable | G/Y/R |
| Budget Utilization | X% | Up/Down/Stable | G/Y/R |
| Resource Utilization | X% | Up/Down/Stable | G/Y/R |
| Open Critical Risks | N | Up/Down/Stable | G/Y/R |

## Project Status Summary

| Project | Status | SPI | CPI | Key Issue |
|---------|--------|-----|-----|-----------|
| [Name] | G/Y/R | X.XX | X.XX | [Issue or "On track"] |

## Items Requiring Attention

### Critical (Action This Week)
1. [Item] - **Decision Needed:** [Decision]

### Important (Action This Month)
1. [Item] - **Owner:** [Name]

## Key Milestones (Next 30 Days)

| Date | Project | Milestone | Status |
|------|---------|-----------|--------|
| [Date] | [Project] | [Milestone] | [On Track/At Risk] |

## Decisions Requested

| Decision | Options | Recommendation | Deadline |
|----------|---------|----------------|----------|
| [Decision] | [A, B, C] | [Recommendation] | [Date] |

## Appendix

[Detailed project status, full risk register, etc.]
```

---

## Execution Report

Base metrics per [shared-patterns/execution-report.md](../shared-patterns/execution-report.md):

| Metric | Value |
|--------|-------|
| Analysis Date | YYYY-MM-DD |
| Scope | [Portfolio/Report type] |
| Duration | Xh Ym |
| Result | COMPLETE/PARTIAL/BLOCKED |

### Executive Reporting-Specific Details

| Metric | Value |
|--------|-------|
| projects_reported | N |
| status_distribution | G/Y/R |
| escalations | N |
| decisions_needed | N |
