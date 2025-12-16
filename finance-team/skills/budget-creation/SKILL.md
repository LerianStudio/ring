---
name: budget-creation
description: |
  Complete budgeting and forecasting workflow covering annual budgets, departmental budgets,
  rolling forecasts, and variance analysis. Delivers documented budgets with approval trails.

trigger: |
  - Creating annual operating budget
  - Building departmental budgets
  - Developing rolling forecasts
  - Budget-to-actual variance analysis

skip_when: |
  - Analyzing historical financials → use financial-analysis
  - Building valuation models → use financial-modeling
  - Cash flow specific work → use cash-flow-analysis

related:
  similar: [financial-analysis, financial-modeling]
  uses: [budget-planner]
---

# Budget Creation Workflow

This skill provides a structured workflow for comprehensive budget development using the `budget-planner` agent.

## Workflow Overview

The budget creation workflow follows 6 phases:

| Phase | Name | Description |
|-------|------|-------------|
| 1 | Planning | Define budget scope, methodology, timeline |
| 2 | Assumption Development | Document all budget assumptions |
| 3 | Line Item Build | Build detailed budget by line item |
| 4 | Consolidation | Consolidate and review totals |
| 5 | Approval | Obtain required approvals |
| 6 | Documentation | Finalize with version control |

---

## Phase 1: Planning

**MANDATORY: Define budget parameters before building**

### Questions to Answer

| Question | Purpose |
|----------|---------|
| What is the budget period? | Sets time scope |
| What methodology will be used? | Incremental vs ZBB |
| Who are the budget owners? | Establishes accountability |
| What is the timeline? | Sets deadlines |
| What are the constraints? | Defines boundaries |

### Methodology Selection

| Method | When to Use | Characteristics |
|--------|-------------|-----------------|
| Incremental | Stable operations | Prior year + adjustments |
| Zero-Based | Cost reduction | Every item justified |
| Driver-Based | Scalable operations | Tied to activity drivers |
| Top-Down | Corporate targets | Allocate from total |
| Bottom-Up | Department input | Aggregate from detail |

### Blocker Check

**If ANY of these are unclear, STOP and ask:**
- Budget period
- Methodology choice
- Approval requirements
- Timeline constraints

---

## Phase 2: Assumption Development

**MANDATORY: Document ALL assumptions before building**

### Required Assumptions

| Category | Examples |
|----------|----------|
| Revenue | Growth rate, pricing, volume |
| Headcount | Hiring plan, attrition, merit |
| Inflation | General inflation, specific items |
| Timing | Seasonality, project timing |
| Strategic | Initiatives, investments |

### Assumption Documentation Standard

| Element | Requirement |
|---------|-------------|
| Assumption statement | Clear, specific description |
| Value | Quantified assumption |
| Rationale | Why this assumption |
| Owner | Who owns this assumption |
| Sensitivity | Impact if wrong |

### Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Same as last year" | Each budget is independent | **RE-EVALUATE assumption** |
| "Industry standard" | Industry varies | **CITE specific basis** |
| "Conservative estimate" | Conservative needs quantification | **DEFINE conservatism** |

---

## Phase 3: Line Item Build

**Dispatch to specialist with full context**

### Agent Dispatch

```
Task tool:
  subagent_type: "budget-planner"
  model: "opus"
  prompt: |
    Build budget per these specifications:

    **Period**: [budget period]
    **Type**: [annual/departmental/project]
    **Methodology**: [from Phase 1]

    **Assumptions**:
    [From Phase 2]

    **Constraints**:
    [Any targets or limitations]

    **Prior Period Reference**:
    [Attach prior budget/actuals]

    **Required Output**:
    - Line item detail with owners
    - Assumption linkage for each item
    - Variance to prior period
    - Monthly/quarterly phasing
```

### Required Output Elements

| Element | Requirement |
|---------|-------------|
| Budget Summary | High-level totals |
| Line Item Detail | Every line with owner |
| Assumptions | Linked to line items |
| Phasing | Monthly or quarterly |
| Variance | To prior period/target |
| Version | Version number and date |

---

## Phase 4: Consolidation

**MANDATORY: Review consolidated budget for reasonableness**

### Consolidation Checks

| Check | Validation |
|-------|------------|
| Math accuracy | All totals foot and cross-foot |
| Assumption consistency | No conflicting assumptions |
| Intercompany | Eliminations if applicable |
| Completeness | All departments included |

### Reasonableness Tests

| Test | Validation |
|------|------------|
| YoY change | Explainable variance |
| Margin trends | Consistent with strategy |
| Headcount | Reconciles to HR plan |
| CapEx | Within investment guidelines |

---

## Phase 5: Approval

**MANDATORY: Document all approvals**

### Approval Workflow

| Level | Approver | Documentation |
|-------|----------|---------------|
| Department | Department head | Written approval |
| Finance | Controller/CFO | Written approval |
| Executive | CEO | Written approval |
| Board | Board/Committee | Meeting minutes |

### Approval Documentation

| Element | Requirement |
|---------|-------------|
| Approver name | Full name and title |
| Approval date | Specific date |
| Version approved | Version number |
| Conditions | Any conditions or caveats |

---

## Phase 6: Documentation

**MANDATORY: Finalize with full audit trail**

### Documentation Checklist

| Element | Status |
|---------|--------|
| All assumptions documented | Required |
| All line items with owners | Required |
| All approvals documented | Required |
| Version control in place | Required |
| Change log complete | Required |

### Output Format

See [shared-patterns/execution-report.md](../shared-patterns/execution-report.md) for base metrics.

**Budget-Specific Metrics:**
- line_items: N
- departments: N
- assumptions_documented: N
- variance_to_prior: X.X%
- approval_status: DRAFT/SUBMITTED/APPROVED

---

## Pressure Resistance

See [shared-patterns/pressure-resistance.md](../shared-patterns/pressure-resistance.md) for universal pressures.

### Budget-Specific Pressures

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| "Make the numbers work" | "Budgets must reflect realistic projections. I'll document achievable targets." |
| "Skip departmental review" | "All budgets require owner sign-off. I'll coordinate with departments." |
| "Use last year's assumptions" | "Each budget needs fresh assumption validation. I'll re-evaluate all assumptions." |
| "We need it by EOD" | "Quality cannot be compromised by timeline. I'll document what's achievable." |

---

## Anti-Rationalization Table

See [shared-patterns/anti-rationalization.md](../shared-patterns/anti-rationalization.md) for universal anti-rationalizations.

### Budget-Specific Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Just add X% to last year" | Every item needs justification | **JUSTIFY each item** |
| "Department requested it" | Requests need validation | **VALIDATE request basis** |
| "We always spend this much" | Historical ≠ justified | **JUSTIFY current need** |
| "Round number is close enough" | Precision matters | **USE calculated amounts** |

---

## Execution Report

Upon completion, report:

| Metric | Value |
|--------|-------|
| Duration | Xm Ys |
| Line Items | N |
| Departments | N |
| Assumptions | N documented |
| Approval Status | DRAFT/APPROVED |
| Result | COMPLETE/PARTIAL |

### Quality Indicators

| Indicator | Status |
|-----------|--------|
| All assumptions documented | YES/NO |
| All items have owners | YES/NO |
| All approvals obtained | YES/NO |
| Version control in place | YES/NO |
