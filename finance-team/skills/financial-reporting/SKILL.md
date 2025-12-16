---
name: financial-reporting
description: |
  Financial reporting workflow covering report preparation, management reporting,
  board presentations, and investor communications. Delivers polished, accurate reports.

trigger: |
  - Preparing financial reports
  - Management or board presentations
  - Investor communications
  - Regulatory filings support

skip_when: |
  - Detailed analysis needed → use financial-analysis
  - Building models → use financial-modeling
  - Accounting entries → use financial-close

related:
  similar: [financial-analysis, metrics-dashboard]
  uses: [financial-analyst, metrics-analyst]
---

# Financial Reporting Workflow

This skill provides a structured workflow for preparing financial reports using the `financial-analyst` and `metrics-analyst` agents.

## Workflow Overview

The financial reporting workflow follows 5 phases:

| Phase | Name | Description |
|-------|------|-------------|
| 1 | Requirements | Define report scope and audience |
| 2 | Data Collection | Gather and verify source data |
| 3 | Report Preparation | Build report content |
| 4 | Review | Quality control and approval |
| 5 | Distribution | Finalize and distribute |

---

## Phase 1: Requirements

**MANDATORY: Define report requirements before building**

### Questions to Answer

| Question | Purpose |
|----------|---------|
| Who is the audience? | Tailors content and detail |
| What period is covered? | Sets data scope |
| What is the deadline? | Sets timeline |
| What format is required? | Determines output |
| What comparisons needed? | Prior period, budget, forecast |

### Report Types

| Type | Audience | Content Focus |
|------|----------|---------------|
| Management Report | Leadership | Operations, KPIs, variances |
| Board Package | Directors | Strategic, summary, governance |
| Investor Report | Shareholders | Performance, guidance, risks |
| Regulatory Filing | Regulators | Compliance, disclosures |

### Blocker Check

**If ANY of these are unclear, STOP and ask:**
- Report audience
- Required content sections
- Comparison basis
- Approval requirements

---

## Phase 2: Data Collection

**MANDATORY: Verify all data before reporting**

### Data Requirements

| Report Type | Required Data |
|-------------|---------------|
| Management | Actuals, budget, forecast, KPIs |
| Board | Summary financials, strategic metrics |
| Investor | Audited financials, guidance |
| Regulatory | Per filing requirements |

### Data Verification Checklist

| Check | Validation |
|-------|------------|
| Source documented | Each number has source |
| Period correct | Data from correct period |
| Reconciled | Ties to source system |
| Approved | Data has been reviewed |

---

## Phase 3: Report Preparation

**Dispatch to specialist(s) with full context**

### Agent Dispatch for Analysis-Heavy Reports

```
Task tool:
  subagent_type: "financial-analyst"
  model: "opus"
  prompt: |
    Prepare financial analysis for [report type]:

    **Period**: [reporting period]
    **Audience**: [from Phase 1]
    **Comparisons**: [prior period/budget/forecast]

    **Data Provided**:
    [Verified data from Phase 2]

    **Required Sections**:
    - Executive summary
    - Financial highlights
    - Variance analysis
    - Key metrics
    - Outlook commentary

    **Format Requirements**:
    [Specific format needs]
```

### Agent Dispatch for KPI/Dashboard Reports

```
Task tool:
  subagent_type: "metrics-analyst"
  model: "opus"
  prompt: |
    Prepare KPI summary for [report type]:

    **Period**: [reporting period]
    **Audience**: [from Phase 1]

    **KPIs Required**:
    [List of required metrics]

    **Format Requirements**:
    - Visualization specifications
    - Trend indicators
    - Target comparisons
```

### Required Output Elements

| Element | Requirement |
|---------|-------------|
| Executive Summary | Key messages in 3-5 points |
| Financial Statements | Per reporting standards |
| Variance Commentary | Explanations for material items |
| KPI Dashboard | Key metrics with visuals |
| Forward Look | Guidance or outlook (if applicable) |
| Disclosures | Required disclosures |

---

## Phase 4: Review

**MANDATORY: Quality control before distribution**

### Review Checklist

| Check | Validation |
|-------|------------|
| Numbers accurate | Verified against source |
| Math correct | Totals foot and cross-foot |
| Commentary consistent | Story aligns with numbers |
| Comparisons accurate | Prior period/budget correct |
| Disclosures complete | All required disclosures |
| Format correct | Per template/requirements |

### Approval Workflow

| Level | Approver | Focus |
|-------|----------|-------|
| Preparer | Analyst | Accuracy |
| Reviewer | Manager | Completeness |
| Approver | Controller/CFO | Messaging |
| Final | Designated signatory | Authority |

---

## Phase 5: Distribution

**MANDATORY: Control distribution**

### Distribution Checklist

| Item | Status |
|------|--------|
| Final version confirmed | Required |
| Approvals documented | Required |
| Distribution list verified | Required |
| Confidentiality noted | Required |
| Archive copy saved | Required |

---

## Pressure Resistance

See [shared-patterns/pressure-resistance.md](../shared-patterns/pressure-resistance.md) for universal pressures.

### Reporting-Specific Pressures

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| "Just use last month's format" | "Each report needs verification. I'll validate data and format." |
| "Skip the review, deadline is now" | "Review is required for accuracy. I'll expedite but not skip." |
| "Round the numbers for presentation" | "Accuracy requires precise figures. I'll note rounding methodology." |
| "Remove that unfavorable variance" | "All material variances must be disclosed. I'll include explanation." |

---

## Anti-Rationalization Table

See [shared-patterns/anti-rationalization.md](../shared-patterns/anti-rationalization.md) for universal anti-rationalizations.

### Reporting-Specific Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Same report as last month" | Each period is independent | **VERIFY all data fresh** |
| "Minor variance, not worth explaining" | All variances need explanation | **EXPLAIN all variances** |
| "Audience won't notice" | Accuracy is non-negotiable | **BE ACCURATE** |
| "Format is good enough" | Format affects understanding | **FOLLOW requirements** |

---

## Execution Report

Upon completion, report:

| Metric | Value |
|--------|-------|
| Duration | Xm Ys |
| Data Sources | N verified |
| Sections Completed | N |
| Variances Explained | N |
| Approvals | N/N obtained |
| Result | COMPLETE/PARTIAL |

### Quality Indicators

| Indicator | Status |
|-----------|--------|
| All data verified | YES/NO |
| All approvals obtained | YES/NO |
| Format requirements met | YES/NO |
| Distribution controlled | YES/NO |
