# Execution Report Format

This file defines the standard execution report format for all financial workflows.

## Standard Report Structure

Every financial workflow skill MUST produce an execution report with these base metrics:

| Metric | Value | Description |
|--------|-------|-------------|
| Duration | Xm Ys | Time spent executing the workflow |
| Data Sources | N | Number of data sources consulted |
| Calculations | N | Number of calculations performed |
| Verifications | N | Number of independent verifications |
| Result | PASS/FAIL/PARTIAL | Workflow outcome |

## Accuracy Metrics (MANDATORY)

All financial workflows MUST report accuracy metrics:

| Metric | Value | Description |
|--------|-------|-------------|
| Variance Threshold | X.X% | Maximum acceptable variance |
| Actual Variance | X.X% | Variance found in analysis |
| Reconciled | YES/NO | All figures reconciled to source |
| Exceptions | N | Number of unresolved exceptions |

## How to Use This File

Skills should reference this format and add workflow-specific metrics:

```markdown
## Execution Report

Base metrics per [shared-patterns/execution-report.md](../shared-patterns/execution-report.md):

| Metric | Value |
|--------|-------|
| Duration | Xm Ys |
| Data Sources | N |
| Calculations | N |
| Verifications | N |
| Result | PASS/FAIL/PARTIAL |

### Accuracy Metrics

| Metric | Value |
|--------|-------|
| Variance Threshold | X.X% |
| Actual Variance | X.X% |
| Reconciled | YES/NO |
| Exceptions | N |

### Workflow-Specific Details
[Add workflow-specific metrics here]
```

## Workflow-Specific Metric Examples

### Financial Analysis
- ratios_calculated: N
- benchmarks_compared: N
- trends_identified: N
- recommendations: N
- confidence_level: HIGH/MEDIUM/LOW

### Budget Creation
- line_items: N
- departments: N
- assumptions_documented: N
- variance_to_prior: X.X%
- approval_status: DRAFT/SUBMITTED/APPROVED

### Financial Modeling
- scenarios: N
- sensitivity_tests: N
- NPV_calculated: YES/NO
- IRR_calculated: YES/NO
- model_validated: YES/NO

### Cash Flow Analysis
- periods_analyzed: N
- inflows_categorized: N
- outflows_categorized: N
- liquidity_assessed: YES/NO
- forecast_horizon: N months

### Financial Reporting
- statements_prepared: N
- disclosures_included: N
- footnotes_added: N
- management_review: YES/NO
- regulatory_compliance: YES/NO

### Metrics Dashboard
- KPIs_defined: N
- data_sources_connected: N
- visualizations_created: N
- refresh_frequency: DAILY/WEEKLY/MONTHLY
- anomaly_detection: YES/NO

### Financial Close
- close_tasks: N/N completed
- reconciliations: N/N completed
- adjustments: N posted
- review_checkpoints: N/N passed
- close_date_met: YES/NO

## Quality Indicators

All reports SHOULD include quality indicators:

| Indicator | Status | Description |
|-----------|--------|-------------|
| Source Verified | YES/NO | Data traced to authoritative source |
| Calculation Checked | YES/NO | Independent calculation verification |
| Assumption Documented | YES/NO | All assumptions explicitly stated |
| Variance Explained | YES/NO | All variances have explanations |
| Audit Ready | YES/NO | Documentation supports audit review |
