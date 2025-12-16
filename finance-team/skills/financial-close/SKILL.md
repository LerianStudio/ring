---
name: financial-close
description: |
  Month-end and year-end close workflow covering journal entries, reconciliations,
  close procedures, and audit preparation. Delivers accurate, timely close with full audit trail.

trigger: |
  - Month-end close procedures
  - Year-end close procedures
  - Account reconciliations
  - Preparing for audit

skip_when: |
  - Financial analysis → use financial-analysis
  - Budget work → use budget-creation
  - Cash flow forecasting → use cash-flow-analysis

related:
  similar: [financial-reporting, financial-analysis]
  uses: [accounting-specialist]
---

# Financial Close Workflow

This skill provides a structured workflow for month-end and year-end close using the `accounting-specialist` agent.

## Workflow Overview

The financial close workflow follows 6 phases:

| Phase | Name | Description |
|-------|------|-------------|
| 1 | Pre-Close | Prepare for close, gather data |
| 2 | Transaction Processing | Complete period transactions |
| 3 | Reconciliations | Reconcile all accounts |
| 4 | Adjustments | Post adjusting entries |
| 5 | Review | Quality review and sign-off |
| 6 | Finalization | Close period, prepare reports |

---

## Phase 1: Pre-Close

**MANDATORY: Complete pre-close checklist before proceeding**

### Pre-Close Tasks

| Task | Description |
|------|-------------|
| Calendar review | Confirm close dates |
| Cutoff communication | Notify stakeholders of deadlines |
| Open items review | Identify carryover items |
| System readiness | Verify system availability |

### Pre-Close Checklist

| Item | Status |
|------|--------|
| Prior period closed | Required |
| Subledgers ready | Required |
| Bank statements received | Required |
| Intercompany confirmed | Required |
| Cutoff communicated | Required |

### Blocker Check

**If ANY of these are missing, STOP and ask:**
- Prior period closed
- Bank statements available
- Key source data ready
- System access confirmed

---

## Phase 2: Transaction Processing

**MANDATORY: Complete all period transactions**

### Transaction Types

| Type | Description |
|------|-------------|
| Revenue | Sales, services, other income |
| Expenses | Operating, non-operating |
| Payroll | Salaries, benefits, taxes |
| Inventory | Receipts, shipments, adjustments |
| Fixed Assets | Additions, disposals, depreciation |

### Cutoff Procedures

| Area | Procedure |
|------|-----------|
| Revenue | Review shipments around period end |
| Expenses | Review invoices received post-close |
| Payroll | Confirm payroll period alignment |
| Inventory | Physical count if applicable |

---

## Phase 3: Reconciliations

**MANDATORY: Reconcile ALL balance sheet accounts**

### Agent Dispatch

```
Task tool:
  subagent_type: "accounting-specialist"
  model: "opus"
  prompt: |
    Perform period-end reconciliations:

    **Period**: [close period]
    **Entity**: [entity name]

    **Accounts to Reconcile**:
    - Cash and bank accounts
    - Accounts receivable
    - Inventory (if applicable)
    - Prepaid expenses
    - Fixed assets
    - Accounts payable
    - Accrued expenses
    - Intercompany (if applicable)
    - Debt

    **Prior Period Workpapers**: [attached]

    **Required Output**:
    - Reconciliation for each account
    - Reconciling items identified
    - Supporting documentation
    - Sign-off status
```

### Reconciliation Standard

| Element | Requirement |
|---------|-------------|
| GL balance | From trial balance |
| Subledger/Bank | From supporting system |
| Reconciling items | Each item explained |
| Support | Documentation attached |
| Sign-off | Preparer and reviewer |

### Required Reconciliations

| Category | Accounts |
|----------|----------|
| Assets | Cash, AR, Inventory, Prepaid, Fixed Assets |
| Liabilities | AP, Accruals, Debt, Intercompany |
| Equity | Retained Earnings, Other Comprehensive Income |

---

## Phase 4: Adjustments

**MANDATORY: Post all adjusting entries with documentation**

### Adjustment Types

| Type | Description |
|------|-------------|
| Accruals | Expenses incurred not yet recorded |
| Deferrals | Cash received/paid for future periods |
| Estimates | Reserves, allowances, impairments |
| Corrections | Error corrections |
| Reclassifications | Account reclasses |

### Journal Entry Standard

| Element | Requirement |
|---------|-------------|
| Entry number | Unique identifier |
| Date | Period end date |
| Description | Clear rationale |
| Accounts | Debits and credits |
| Support | Documentation attached |
| Approval | Required before posting |

---

## Phase 5: Review

**MANDATORY: Quality review before closing**

### Review Checklist

| Check | Validation |
|-------|------------|
| Trial balance foots | Total debits = credits |
| All recs complete | Every account reconciled |
| All entries posted | No pending entries |
| Variances explained | Material changes documented |
| Controls completed | SOX controls if applicable |

### Review Levels

| Level | Reviewer | Focus |
|-------|----------|-------|
| Self-review | Preparer | Accuracy, completeness |
| Peer review | Another accountant | Independent verification |
| Manager review | Controller | Reasonableness, policy |
| Final review | CFO | Overall quality |

---

## Phase 6: Finalization

**MANDATORY: Complete close procedures**

### Finalization Tasks

| Task | Description |
|------|-------------|
| Period lock | Prevent further posting |
| Reports generated | Trial balance, financials |
| Workpapers filed | Documentation archived |
| Close memo | Summary of significant items |

### Close Deliverables

| Deliverable | Description |
|-------------|-------------|
| Trial Balance | Final, adjusted |
| Financial Statements | IS, BS, CF |
| Reconciliation Package | All reconciliations |
| Close Memo | Summary and issues |

---

## Pressure Resistance

See [shared-patterns/pressure-resistance.md](../shared-patterns/pressure-resistance.md) for universal pressures.

### Close-Specific Pressures

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| "Skip that reconciliation" | "All accounts must be reconciled. I'll complete the reconciliation." |
| "Post without approval" | "Entries require approval before posting. I'll obtain approval." |
| "Close now, fix next month" | "Errors compound. I'll correct before close." |
| "Immaterial, don't worry" | "Materiality requires documentation. I'll document the item." |

---

## Anti-Rationalization Table

See [shared-patterns/anti-rationalization.md](../shared-patterns/anti-rationalization.md) for universal anti-rationalizations.

### Close-Specific Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Same entry as last month" | Each period independent | **VERIFY current validity** |
| "Reconciling item will clear" | Items need investigation | **INVESTIGATE now** |
| "Small balance, skip rec" | All accounts need rec | **RECONCILE all accounts** |
| "Prior period was fine" | Each close independent | **COMPLETE all steps** |

---

## Execution Report

Upon completion, report:

| Metric | Value |
|--------|-------|
| Duration | Xm Ys |
| Journal Entries | N posted |
| Reconciliations | N/N complete |
| Adjustments | N |
| Review Sign-offs | N/N |
| Result | CLOSED/PARTIAL |

### Quality Indicators

| Indicator | Status |
|-----------|--------|
| All accounts reconciled | YES/NO |
| All entries approved | YES/NO |
| All reviews complete | YES/NO |
| Period locked | YES/NO |
| Workpapers filed | YES/NO |
