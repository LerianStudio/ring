Build financial model (DCF, LBO, M&A, or operating model) with validated methodology.

## Usage

```
/ring-finance-team:build-model [type] [options]
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `type` | Yes | Model type: `dcf`, `lbo`, `merger`, `operating`, `comps` |

## Options

| Option | Description | Example |
|--------|-------------|---------|
| `--purpose` | Model purpose/decision | `--purpose "acquisition evaluation"` |
| `--data` | Historical data file | `--data docs/financials/historical.xlsx` |
| `--scenarios` | Number of scenarios | `--scenarios 3` |
| `--output` | Output format | `--output "excel"` |
| `--sensitivity` | Key sensitivity drivers | `--sensitivity "wacc,growth"` |

## Examples

```bash
# DCF valuation model
/ring-finance-team:build-model dcf --purpose "standalone valuation" --data docs/financials.xlsx

# LBO model
/ring-finance-team:build-model lbo --purpose "PE acquisition" --data docs/target-financials.xlsx

# M&A accretion/dilution
/ring-finance-team:build-model merger --purpose "strategic acquisition" --scenarios 3

# Three-statement operating model
/ring-finance-team:build-model operating --purpose "5-year projection" --data docs/historical.xlsx

# With specific sensitivity analysis
/ring-finance-team:build-model dcf --sensitivity "wacc,terminal-growth,revenue-growth"
```

## Prerequisites

1. **Historical financials**: 3-5 years of financial data (recommended)
2. **Model purpose**: Clear decision the model supports
3. **Key assumptions**: WACC components, growth rates, multiples
4. **Transaction terms** (for LBO/M&A): Deal structure, financing

## Model Types

| Type | Description | Key Outputs |
|------|-------------|-------------|
| `dcf` | Discounted Cash Flow | Enterprise Value, Equity Value, implied multiple |
| `lbo` | Leveraged Buyout | IRR, MOIC, sources/uses, returns waterfall |
| `merger` | M&A / Merger Model | Accretion/dilution, synergies, pro forma |
| `operating` | Three-Statement Model | IS, BS, CF integrated projections |
| `comps` | Comparable Analysis | Trading multiples, implied valuation |

## Output

The command produces a complete financial model including:

- Model Summary with key outputs
- Assumptions Register with sources
- Model Structure documentation
- Key Outputs and metrics
- Sensitivity Analysis tables
- Scenario Analysis (if applicable)
- Validation Tests results

## Related Commands

| Command | Description |
|---------|-------------|
| `/ring-finance-team:analyze-financials` | Financial analysis |
| `/ring-finance-team:create-budget` | Create budget |

---

## MANDATORY: Load Full Skill

**This command MUST load the skill for complete workflow execution.**

```
Use Skill tool: ring-finance-team:financial-modeling
```

The skill contains the complete 6-phase workflow with:
- Scoping requirements
- Architecture design principles
- Assumption documentation
- Build standards
- Validation tests
- Documentation requirements

## Execution Context

Pass the following context to the skill:

| Parameter | Value |
|-----------|-------|
| `type` | `$1` (first argument: dcf, lbo, merger, operating, comps) |
| `--purpose` | If provided, model purpose |
| `--data` | If provided, historical data file |
| `--scenarios` | If provided, number of scenarios |
| `--sensitivity` | If provided, sensitivity drivers |

## Step 1: ASK MODEL PARAMETERS (MANDATORY)

**After loading skill and before building model, you MUST ask:**

```yaml
AskUserQuestion:
  questions:
    - question: "What decision does this model support?"
      header: "Model Purpose"
      freeform: true
    - question: "What WACC approach should be used?"
      header: "WACC"
      options:
        - label: "Calculate from components"
          description: "Build up WACC from risk-free, beta, ERP"
        - label: "Industry benchmark"
          description: "Use industry average (cite source)"
        - label: "Company-provided"
          description: "Use company's stated WACC"
    - question: "What terminal value methodology?"
      header: "Terminal Value"
      options:
        - label: "Gordon Growth"
          description: "Perpetuity growth model"
        - label: "Exit Multiple"
          description: "Apply multiple to terminal year"
        - label: "Both"
          description: "Calculate both for comparison"
```

**Do NOT skip this.** Model type alone does not define methodology.

## Quick Reference

See skill `ring-finance-team:financial-modeling` for full details. Key rules:

- **All inputs in input section** - No hardcoded values
- **WACC calculated from components** - Not assumed
- **Sensitivity analysis required** - Key drivers tested
- **Error checks implemented** - Validation on all sections
- **Model validated** - All tests passing before delivery
