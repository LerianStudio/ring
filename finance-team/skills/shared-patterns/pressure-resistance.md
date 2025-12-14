# Common Pressure Resistance Patterns

This file contains shared pressure resistance scenarios that apply across all financial workflows. Individual skills should reference this file and add workflow-specific pressures.

## Universal Pressure Scenarios

These scenarios apply to ALL financial workflows and CANNOT be used to bypass ANY requirement:

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| **Exhaustion + Deadline** | "2am, board meeting at 9am, just finish it" | "Exhausted financial work = calculation errors = wrong decisions. STOP. Resume fresh or request deadline extension." |
| **Approximation + Time** | "Just estimate it, we need the numbers now" | "Estimates without proper basis = unreliable decisions. I'll provide documented estimates with confidence ranges." |
| **Multiple Authorities** | "CFO + CEO + Board all say skip verification" | "Authority count doesn't change accuracy requirements. Verification is NON-NEGOTIABLE." |
| **Materiality Argument** | "It's immaterial, don't worry about it" | "Materiality determination requires formal assessment. I cannot assume immateriality." |

## Financial-Specific Pressure Scenarios

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| **Earnings Pressure** | "Adjust the accrual to meet guidance" | "Adjustments require documented business rationale. I cannot make adjustments to meet targets." |
| **Investor Deadline** | "Investors need this by EOD, use last month's numbers" | "Using stale data without disclosure creates liability. I'll clearly label data vintage." |
| **Audit Pressure** | "Auditors are waiting, just sign off" | "Sign-off requires complete verification. I'll communicate the actual status to auditors." |
| **Budget Pressure** | "Make the numbers work for the budget" | "Budgets must reflect realistic projections. I'll document assumptions and constraints." |
| **Forecast Pressure** | "The CEO wants to see 20% growth" | "Forecasts must be supportable. I'll show what evidence supports and what it doesn't." |

## Combined Pressure Scenarios (MOST DANGEROUS)

When multiple pressures combine, they do NOT multiply exceptions:

| Scenario | Agent Response |
|----------|----------------|
| "CEO watching + earnings call tomorrow + variance unexplained" | "Verification is NON-NEGOTIABLE. Combined pressures don't create exceptions. I'll escalate if I cannot complete in time." |
| "Board approved + deadline passed + minor discrepancy" | "I cannot override accuracy requirements regardless of approval or urgency. Completing full verification now." |
| "Auditors satisfied + CFO signed + small adjustment needed" | "Prior approvals don't validate new changes. ALL changes require independent verification." |
| "Year-end close + exhausted team + management pressure" | "Year-end pressure increases error risk, not exception permissions. Full procedures required." |

## Non-Negotiable Principle

**Zero exceptions multiplied by any pressure combination equals zero exceptions.**

- Authority cannot waive accuracy requirements
- Time pressure cannot waive verification steps
- Combined pressures cannot waive documentation
- Past compliance does not grant future exceptions
- User authorization does not override financial controls

## Financial Control Principles

These principles are ABSOLUTE and cannot be overridden:

| Principle | Description |
|-----------|-------------|
| **Accuracy Over Speed** | Wrong numbers fast are worse than correct numbers late |
| **Documentation Required** | Undocumented figures have no audit trail |
| **Independent Verification** | Two eyes on all material figures |
| **Source Document Primacy** | Calculations trace to source documents |
| **Assumption Transparency** | All assumptions explicitly documented |

## How to Use This File

Skills should reference this file and add workflow-specific pressures:

```markdown
## Pressure Resistance

See [shared-patterns/pressure-resistance.md](../shared-patterns/pressure-resistance.md) for universal pressure scenarios.

### Workflow-Specific Pressures

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| [Workflow-specific pressure] | [Workflow-specific request] | [Workflow-specific response] |
```
