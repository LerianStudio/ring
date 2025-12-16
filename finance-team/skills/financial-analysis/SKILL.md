---
name: financial-analysis
description: |
  Comprehensive financial analysis workflow covering ratio analysis, trend analysis,
  benchmarking, and variance analysis. Delivers documented, audit-ready insights.

trigger: |
  - Need to analyze financial statements
  - Evaluating financial health or performance
  - Comparing against benchmarks or prior periods
  - Investment or credit evaluation

skip_when: |
  - Building budgets or forecasts → use budget-creation
  - Building valuation models → use financial-modeling
  - Cash flow specific analysis → use cash-flow-analysis

related:
  similar: [budget-creation, financial-reporting]
  uses: [financial-analyst]
---

# Financial Analysis Workflow

This skill provides a structured workflow for comprehensive financial analysis using the `financial-analyst` agent.

## Workflow Overview

The financial analysis workflow follows 5 phases:

| Phase | Name | Description |
|-------|------|-------------|
| 1 | Objective Definition | Clarify analysis scope and questions |
| 2 | Data Collection | Gather and verify source documents |
| 3 | Analysis Execution | Calculate ratios, identify trends |
| 4 | Interpretation | Draw conclusions, identify insights |
| 5 | Documentation | Prepare audit-ready deliverable |

---

## Phase 1: Objective Definition

**MANDATORY: Define analysis scope before proceeding**

### Questions to Answer

| Question | Purpose |
|----------|---------|
| What decision does this analysis support? | Ensures relevance |
| What time periods are being analyzed? | Sets scope |
| What comparisons are needed? | Determines benchmarks |
| Who is the audience? | Tailors presentation |
| What is the materiality threshold? | Focuses effort |

### Blocker Check

**If ANY of these are unclear, STOP and ask:**
- Analysis objective
- Time period scope
- Comparison basis (peer, prior period, budget)
- Materiality threshold

---

## Phase 2: Data Collection

**MANDATORY: Verify all data sources before analysis**

### Data Requirements

| Analysis Type | Required Data |
|--------------|---------------|
| Trend Analysis | 3-5 periods of financial statements |
| Peer Comparison | Peer company financials (same period) |
| Variance Analysis | Budget/forecast and actual results |
| Credit Analysis | Balance sheet, cash flow, debt schedules |

### Data Verification Checklist

| Check | Verification |
|-------|--------------|
| Source documented | Each data point cites source |
| Period matched | All data from same period |
| Currency consistent | Single currency or conversion noted |
| Audit status | Audited vs unaudited noted |

### Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Data looks right" | Looks right ≠ is right | **VERIFY against source** |
| "Same source as always" | Sources can change | **CONFIRM source current** |
| "Minor discrepancy" | All discrepancies matter | **INVESTIGATE and document** |

---

## Phase 3: Analysis Execution

**Dispatch to specialist with full context**

### Agent Dispatch

```
Task tool:
  subagent_type: "financial-analyst"
  model: "opus"
  prompt: |
    Perform financial analysis per these specifications:

    **Objective**: [from Phase 1]
    **Period**: [time periods]
    **Comparison**: [benchmarks/peers]
    **Materiality**: [threshold]

    **Data Provided**:
    [Attach verified data from Phase 2]

    **Required Analysis**:
    - [ ] Ratio analysis (liquidity, profitability, leverage, efficiency)
    - [ ] Trend analysis (period over period)
    - [ ] Benchmark comparison (if applicable)
    - [ ] Variance analysis (if applicable)

    **Output Requirements**:
    - All calculations shown
    - All sources cited
    - All assumptions documented
```

### Required Output Elements

| Element | Requirement |
|---------|-------------|
| Executive Summary | Key findings in 3-5 bullets |
| Analysis Methodology | Methods used and why |
| Key Findings | With supporting calculations |
| Data Sources | Complete citation |
| Assumptions | All assumptions documented |
| Recommendations | Actionable next steps |

---

## Phase 4: Interpretation

**MANDATORY: Provide context for all findings**

### Interpretation Framework

| Finding Type | Required Context |
|--------------|------------------|
| Ratio result | Industry comparison, trend direction |
| Variance | Root cause, materiality assessment |
| Trend | Sustainability, drivers, implications |
| Anomaly | Investigation result, explanation |

### Quality Checks

| Check | Validation |
|-------|------------|
| Findings supported | Each finding traces to data |
| Conclusions logical | Interpretation follows from facts |
| Recommendations actionable | Clear next steps provided |
| Limitations disclosed | Analysis boundaries stated |

---

## Phase 5: Documentation

**MANDATORY: Ensure audit-ready deliverable**

### Documentation Checklist

| Element | Status |
|---------|--------|
| All data sources cited | Required |
| All calculations shown | Required |
| All assumptions documented | Required |
| Methodology explained | Required |
| Limitations disclosed | Required |
| Version control | Required |

### Output Format

See [shared-patterns/execution-report.md](../shared-patterns/execution-report.md) for base metrics.

**Analysis-Specific Metrics:**
- ratios_calculated: N
- periods_analyzed: N
- benchmarks_compared: N
- variances_explained: N
- recommendations_made: N

---

## Pressure Resistance

See [shared-patterns/pressure-resistance.md](../shared-patterns/pressure-resistance.md) for universal pressures.

### Analysis-Specific Pressures

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| "Just give me the conclusion" | "I'll provide conclusions with supporting analysis. Undocumented conclusions cannot be defended." |
| "Skip the ratios we don't need" | "Comprehensive analysis requires complete ratio set. I'll calculate all standard ratios." |
| "Use approximate numbers" | "Analysis requires precise figures. I'll use exact amounts from source documents." |

---

## Anti-Rationalization Table

See [shared-patterns/anti-rationalization.md](../shared-patterns/anti-rationalization.md) for universal anti-rationalizations.

### Analysis-Specific Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Standard analysis doesn't need documentation" | ALL analysis needs documentation | **DOCUMENT methodology** |
| "Ratios speak for themselves" | Ratios need interpretation | **PROVIDE context** |
| "Industry benchmark is well-known" | Benchmarks need citation | **CITE source** |
| "Similar to prior analysis" | Each analysis is independent | **PERFORM fresh analysis** |

---

## Execution Report

Upon completion, report:

| Metric | Value |
|--------|-------|
| Duration | Xm Ys |
| Data Sources | N verified |
| Ratios Calculated | N |
| Trends Identified | N |
| Recommendations | N |
| Result | COMPLETE/PARTIAL |

### Quality Indicators

| Indicator | Status |
|-----------|--------|
| All sources verified | YES/NO |
| All calculations shown | YES/NO |
| All assumptions documented | YES/NO |
| Audit ready | YES/NO |
