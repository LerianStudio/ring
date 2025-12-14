Perform comprehensive financial analysis on provided financial data.

## Usage

```
/ring-finance-team:analyze-financials [data-source] [options]
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `data-source` | Yes | Path to financial data (statements, reports, or data file) |

## Options

| Option | Description | Example |
|--------|-------------|---------|
| `--period` | Analysis period | `--period "FY2024"` |
| `--comparison` | Comparison basis | `--comparison "prior-year"` |
| `--type` | Analysis type | `--type "ratio,trend"` |
| `--benchmark` | Benchmark source | `--benchmark "industry"` |
| `--output` | Output format | `--output "report"` |

## Examples

```bash
# Analyze financial statements
/ring-finance-team:analyze-financials docs/financials/statements-2024.xlsx

# Year-over-year analysis
/ring-finance-team:analyze-financials docs/financials/Q4-2024.xlsx --comparison prior-year

# Specific analysis types
/ring-finance-team:analyze-financials docs/financials/annual-report.pdf --type "ratio,trend,benchmark"

# With industry comparison
/ring-finance-team:analyze-financials docs/financials/income-statement.csv --benchmark industry
```

## Prerequisites

1. **Financial data**: Statements or data in readable format (Excel, CSV, PDF)
2. **Period specification**: Clear time period for analysis
3. **Comparison data** (optional): Prior period or benchmark data

## Analysis Types

| Type | Description |
|------|-------------|
| `ratio` | Liquidity, profitability, leverage, efficiency ratios |
| `trend` | Period-over-period trend analysis |
| `benchmark` | Comparison to industry/peers |
| `variance` | Budget-to-actual or forecast variance |
| `common-size` | Common-size statement analysis |

## Output

The command produces a comprehensive analysis report including:

- Executive Summary with key findings
- Analysis Methodology documentation
- Key Findings with supporting calculations
- Data Sources with citations
- Assumptions documented
- Recommendations for action
- Limitations disclosure

## Related Commands

| Command | Description |
|---------|-------------|
| `/ring-finance-team:create-budget` | Create budget or forecast |
| `/ring-finance-team:build-model` | Build financial model |

---

## MANDATORY: Load Full Skill

**This command MUST load the skill for complete workflow execution.**

```
Use Skill tool: ring-finance-team:financial-analysis
```

The skill contains the complete 5-phase workflow with:
- Objective definition requirements
- Data verification checklist
- Anti-rationalization tables
- Pressure resistance scenarios
- Documentation standards

## Execution Context

Pass the following context to the skill:

| Parameter | Value |
|-----------|-------|
| `data-source` | `$1` (first argument) |
| `--period` | If provided, analysis period |
| `--comparison` | If provided, comparison basis |
| `--type` | If provided, analysis types |
| `--benchmark` | If provided, benchmark source |

## Step 1: ASK ANALYSIS SCOPE (MANDATORY)

**After loading skill and before executing analysis, you MUST ask:**

```yaml
AskUserQuestion:
  questions:
    - question: "What decision does this analysis support?"
      header: "Analysis Objective"
      freeform: true
    - question: "What comparisons are needed?"
      header: "Comparison Basis"
      options:
        - label: "Prior Year"
          description: "Compare to same period last year"
        - label: "Prior Quarter"
          description: "Compare to previous quarter"
        - label: "Budget"
          description: "Compare to budget"
        - label: "Industry Benchmark"
          description: "Compare to industry peers"
        - label: "Multiple"
          description: "Multiple comparisons needed"
```

**Do NOT skip this.** File path alone does not define scope.

## Quick Reference

See skill `ring-finance-team:financial-analysis` for full details. Key rules:

- **All data sources cited** - No uncited figures
- **All calculations shown** - Audit-ready documentation
- **All assumptions documented** - Full transparency
- **All variances explained** - Material and immaterial
- **Recommendations actionable** - Clear next steps
