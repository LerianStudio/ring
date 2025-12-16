---
name: financial-modeling
description: |
  Financial modeling workflow for DCF, LBO, merger, and operating models.
  Delivers validated, documented models with sensitivity and scenario analysis.

trigger: |
  - Building valuation model (DCF, comps)
  - Creating transaction model (LBO, M&A)
  - Developing operating/projection model
  - Scenario or sensitivity analysis

skip_when: |
  - Analyzing historical financials → use financial-analysis
  - Creating budgets → use budget-creation
  - Cash flow forecasting → use cash-flow-analysis

related:
  similar: [financial-analysis, budget-creation]
  uses: [financial-modeler]
---

# Financial Modeling Workflow

This skill provides a structured workflow for building financial models using the `financial-modeler` agent.

## Workflow Overview

The financial modeling workflow follows 6 phases:

| Phase | Name | Description |
|-------|------|-------------|
| 1 | Scoping | Define model purpose and requirements |
| 2 | Architecture | Design model structure |
| 3 | Assumptions | Document all model inputs |
| 4 | Build | Construct model with formulas |
| 5 | Validation | Test and verify model |
| 6 | Documentation | Prepare user guide and audit trail |

---

## Phase 1: Scoping

**MANDATORY: Define model purpose before building**

### Questions to Answer

| Question | Purpose |
|----------|---------|
| What decision does this model support? | Ensures relevance |
| What type of model is needed? | Sets approach |
| What level of detail is required? | Scopes complexity |
| Who will use the model? | Tailors design |
| What scenarios are needed? | Plans flexibility |

### Model Type Selection

| Type | Use Case | Key Outputs |
|------|----------|-------------|
| DCF | Intrinsic valuation | Enterprise Value, Equity Value |
| Trading Comps | Relative valuation | Implied multiples |
| LBO | PE acquisition | IRR, MOIC, sources/uses |
| M&A | Strategic acquisition | Accretion/dilution, synergies |
| Three-Statement | Operating projections | IS, BS, CF integrated |

### Blocker Check

**If ANY of these are unclear, STOP and ask:**
- Model purpose
- Model type
- Key assumptions (WACC, growth, multiples)
- Scenario requirements

---

## Phase 2: Architecture

**MANDATORY: Design structure before building**

### Architecture Principles

| Principle | Description |
|-----------|-------------|
| Input separation | All inputs in dedicated section |
| No hardcoding | No numbers in formulas |
| Consistent formulas | Same formula across row |
| Error checks | Validation on each sheet |
| Clear flow | Logical left-to-right, top-to-bottom |

### Standard Model Structure

| Section | Contents |
|---------|----------|
| Cover | Model name, version, date, author |
| Inputs | All assumptions in one place |
| Historical | Historical financial data |
| Projections | Projected financials |
| Valuation | DCF, comps, or transaction calcs |
| Sensitivity | Sensitivity tables |
| Output | Summary and key metrics |
| Checks | Error checking |

---

## Phase 3: Assumptions

**MANDATORY: Document ALL assumptions with sources**

### Required Assumption Categories

| Category | Examples |
|----------|----------|
| Operating | Revenue growth, margins, CapEx |
| Valuation | WACC, terminal growth, multiples |
| Transaction | Entry price, financing, fees |
| Timing | Projection period, exit year |

### Assumption Documentation Standard

| Element | Requirement |
|---------|-------------|
| Assumption name | Clear description |
| Value | Base case value |
| Source | Where value came from |
| Sensitivity | Range for testing |

### Blocker: WACC Components

**MUST get user input on:**
- Risk-free rate source
- Equity risk premium source
- Beta source and adjustment
- Capital structure assumption

---

## Phase 4: Build

**Dispatch to specialist with full context**

### Agent Dispatch

```
Task tool:
  subagent_type: "financial-modeler"
  model: "opus"
  prompt: |
    Build financial model per these specifications:

    **Purpose**: [decision supported]
    **Model Type**: [DCF/LBO/M&A/Operating]

    **Architecture**:
    [From Phase 2]

    **Assumptions**:
    [From Phase 3]

    **Historical Data**:
    [Attach historical financials]

    **Required Output**:
    - Model structure per architecture
    - All assumptions in input section
    - Sensitivity analysis
    - Scenario analysis (base/upside/downside)
    - Error checks
```

### Required Output Elements

| Element | Requirement |
|---------|-------------|
| Model Summary | Key outputs and conclusions |
| Assumptions | Complete input section |
| Model Structure | Per architecture design |
| Key Outputs | Valuation, metrics, returns |
| Sensitivity | 2x2 tables for key drivers |
| Validation | Error checks passing |

---

## Phase 5: Validation

**MANDATORY: Test model before delivery**

### Validation Tests

| Test | Description |
|------|-------------|
| Balance Sheet | Assets = Liabilities + Equity |
| Cash Flow | CF reconciles to B/S cash |
| Circular Control | Circulars iterate and converge |
| Formula Audit | No hardcoded values in calcs |
| Reasonableness | Results within expected range |

### Sensitivity Testing

| Test | Purpose |
|------|---------|
| WACC sensitivity | Valuation impact of discount rate |
| Growth sensitivity | Valuation impact of growth |
| Margin sensitivity | Valuation impact of profitability |
| Exit multiple sensitivity | LBO return sensitivity |

### Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Model foots, it's correct" | Footing ≠ correct logic | **VALIDATE methodology** |
| "Sensitivity shows expected range" | Range needs to be appropriate | **VERIFY ranges sensible** |
| "Used industry WACC" | WACC must be calculated | **CALCULATE and document** |

---

## Phase 6: Documentation

**MANDATORY: Document for future users**

### Documentation Checklist

| Element | Status |
|---------|--------|
| Model summary | Required |
| Assumption register | Required |
| Methodology description | Required |
| User instructions | Required |
| Error check explanations | Required |
| Version history | Required |

### Output Format

See [shared-patterns/execution-report.md](../shared-patterns/execution-report.md) for base metrics.

**Modeling-Specific Metrics:**
- model_tabs: N
- assumptions_documented: N
- scenarios: N
- sensitivity_tests: N
- validation_tests: N passed

---

## Pressure Resistance

See [shared-patterns/pressure-resistance.md](../shared-patterns/pressure-resistance.md) for universal pressures.

### Modeling-Specific Pressures

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| "Just give me a valuation" | "Valuations require documented methodology. I'll build proper model." |
| "Use 10% WACC" | "WACC must be calculated from components. I'll show the build-up." |
| "Skip sensitivity" | "Sensitivity is required for decision support. I'll include key drivers." |
| "Copy last model" | "Each model needs fresh design. Prior models are reference, not template." |

---

## Anti-Rationalization Table

See [shared-patterns/anti-rationalization.md](../shared-patterns/anti-rationalization.md) for universal anti-rationalizations.

### Modeling-Specific Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Quick model doesn't need structure" | ALL models need structure | **DESIGN architecture** |
| "Terminal value is just a plug" | TV often 60%+ of value | **CALCULATE properly** |
| "Industry multiple is obvious" | Multiples need source | **CITE and date source** |
| "Circular doesn't matter" | Circulars affect results | **HANDLE explicitly** |

---

## Execution Report

Upon completion, report:

| Metric | Value |
|--------|-------|
| Duration | Xm Ys |
| Model Tabs | N |
| Assumptions | N documented |
| Scenarios | N |
| Sensitivity Tests | N |
| Validation Tests | N/N passed |
| Result | COMPLETE/PARTIAL |

### Quality Indicators

| Indicator | Status |
|-----------|--------|
| All inputs in input section | YES/NO |
| No hardcoded values | YES/NO |
| Error checks pass | YES/NO |
| Sensitivity included | YES/NO |
| Methodology documented | YES/NO |
