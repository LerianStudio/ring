---
name: cash-flow-analysis
description: |
  Cash flow analysis and treasury management workflow covering liquidity assessment,
  cash forecasting, working capital optimization, and treasury operations.

trigger: |
  - Cash flow forecasting (13-week, monthly)
  - Liquidity assessment
  - Working capital analysis
  - Treasury operations review

skip_when: |
  - Financial statement analysis → use financial-analysis
  - Creating budgets → use budget-creation
  - Building valuation models → use financial-modeling

related:
  similar: [financial-analysis, budget-creation]
  uses: [treasury-specialist]
---

# Cash Flow Analysis Workflow

This skill provides a structured workflow for cash flow analysis and treasury management using the `treasury-specialist` agent.

## Workflow Overview

The cash flow analysis workflow follows 5 phases:

| Phase | Name | Description |
|-------|------|-------------|
| 1 | Position Assessment | Establish current cash position |
| 2 | Forecasting | Build cash flow forecast |
| 3 | Liquidity Analysis | Assess liquidity and runway |
| 4 | Risk Identification | Identify cash flow risks |
| 5 | Recommendations | Provide actionable guidance |

---

## Phase 1: Position Assessment

**MANDATORY: Establish current position before forecasting**

### Position Requirements

| Item | Description |
|------|-------------|
| Bank balances | All accounts, same day |
| Credit availability | Undrawn facilities |
| Restricted cash | Identify any restrictions |
| Intercompany | IC positions and netting |

### Verification Checklist

| Check | Validation |
|-------|------------|
| All accounts included | Complete bank list |
| Same-day balance | No stale data |
| Reconciled | Ties to bank statement |
| FX converted | Consistent currency |

### Blocker Check

**If ANY of these are unclear, STOP and ask:**
- Current cash position
- Credit facility terms
- FX rate source for conversion
- Restricted cash items

---

## Phase 2: Forecasting

**MANDATORY: Build forecast with documented methodology**

### Forecast Types

| Type | Horizon | Granularity | Use Case |
|------|---------|-------------|----------|
| 13-Week | 13 weeks | Weekly | Short-term liquidity |
| Monthly | 12 months | Monthly | Operating planning |
| Annual | 1-5 years | Annual | Strategic planning |

### Forecast Components

| Component | Description |
|-----------|-------------|
| Opening balance | Current position |
| Operating receipts | Customer collections, other |
| Operating disbursements | Payroll, vendors, other |
| Investing | CapEx, acquisitions |
| Financing | Debt, equity, dividends |
| Closing balance | Calculated position |

### Methodology Options

| Method | Description |
|--------|-------------|
| Receipts/Disbursements | Bottom-up from transactions |
| Adjusted Net Income | Top-down from P&L |
| Balance Sheet Method | From B/S changes |

---

## Phase 3: Agent Dispatch

**Dispatch to specialist with full context**

### Agent Dispatch

```
Task tool:
  subagent_type: "treasury-specialist"
  model: "opus"
  prompt: |
    Perform cash flow analysis per these specifications:

    **Current Position**: [from Phase 1]
    **Forecast Type**: [13-week/monthly/annual]
    **Methodology**: [receipts-disbursements/adjusted NI]

    **Data Provided**:
    - Bank balances as of [date]
    - Credit facility details
    - AR aging
    - AP aging
    - Payroll schedule
    - Known commitments

    **Required Output**:
    - Current position summary
    - Cash flow forecast
    - Liquidity analysis
    - Risk assessment
    - Recommendations
```

### Required Output Elements

| Element | Requirement |
|---------|-------------|
| Treasury Summary | Current position and highlights |
| Cash Position | All accounts with reconciliation |
| Forecast | Period-by-period projection |
| Liquidity Analysis | Runway and ratios |
| Risk Assessment | Identified risks and mitigations |
| Recommendations | Actionable next steps |

---

## Phase 4: Liquidity Analysis

**MANDATORY: Assess liquidity comprehensively**

### Liquidity Metrics

| Metric | Formula | Threshold |
|--------|---------|-----------|
| Cash Runway | Cash / Monthly Burn | >6 months |
| Current Ratio | Current Assets / Current Liabilities | >1.5x |
| Quick Ratio | (CA - Inventory) / CL | >1.0x |
| Cash Ratio | Cash / Current Liabilities | >0.5x |

### Stress Testing

| Scenario | Description |
|----------|-------------|
| Base Case | Expected forecast |
| Delayed Receipts | AR delayed 30 days |
| Accelerated Payments | AP paid early |
| Revenue Shortfall | 10-20% revenue decline |
| Combined Stress | Multiple adverse factors |

---

## Phase 5: Risk Identification

**MANDATORY: Document all cash flow risks**

### Risk Categories

| Category | Examples |
|----------|----------|
| Collection Risk | Customer concentration, aging |
| Payment Risk | Vendor demands, timing |
| Operational Risk | Seasonality, cyclicality |
| Financing Risk | Covenant compliance, renewal |
| FX Risk | Currency exposure |

### Risk Assessment Framework

| Element | Documentation |
|---------|---------------|
| Risk description | Clear statement |
| Probability | High/Medium/Low |
| Impact | Quantified if possible |
| Mitigation | Specific action |

---

## Pressure Resistance

See [shared-patterns/pressure-resistance.md](../shared-patterns/pressure-resistance.md) for universal pressures.

### Cash Flow-Specific Pressures

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| "Use yesterday's balance" | "Treasury needs current data. I'll get today's position." |
| "Skip the forecast, just need position" | "Position without forecast lacks context. I'll include projections." |
| "Estimate the AR collections" | "Collections forecast needs AR aging basis. I'll use actual data." |
| "We never have liquidity issues" | "Past performance ≠ future results. I'll assess current risk." |

---

## Anti-Rationalization Table

See [shared-patterns/anti-rationalization.md](../shared-patterns/anti-rationalization.md) for universal anti-rationalizations.

### Cash Flow-Specific Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Cash is cash, simple analysis" | Cash has many components | **ANALYZE by category** |
| "Forecast is same as last month" | Each forecast is independent | **BUILD fresh forecast** |
| "We always collect in 45 days" | Actual may differ | **USE actual aging** |
| "Covenant is not close" | Still needs monitoring | **CALCULATE covenant** |

---

## Execution Report

Upon completion, report:

| Metric | Value |
|--------|-------|
| Duration | Xm Ys |
| Accounts Reconciled | N |
| Forecast Periods | N |
| Risks Identified | N |
| Recommendations | N |
| Result | COMPLETE/PARTIAL |

### Quality Indicators

| Indicator | Status |
|-----------|--------|
| Position same-day | YES/NO |
| All accounts included | YES/NO |
| Forecast documented | YES/NO |
| Risks assessed | YES/NO |
| Covenants calculated | YES/NO |
