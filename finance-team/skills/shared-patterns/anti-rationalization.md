# Anti-Rationalization Patterns

Canonical source for anti-rationalization patterns used by all finance-team agents and skills.

AI models naturally attempt to be "helpful" by making autonomous decisions. This is DANGEROUS in financial workflows where accuracy and compliance are non-negotiable. These tables use aggressive language intentionally to override the AI's instinct to be accommodating.

## Universal Anti-Rationalizations

These rationalizations are ALWAYS wrong, regardless of context:

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "This is prototype/throwaway analysis" | Financial prototypes become production decisions. Standards apply to ALL analyses. | **Apply full standards. No prototype exemption.** |
| "Too exhausted to verify all numbers" | Exhaustion in finance = errors = incorrect decisions. | **STOP work. Resume when able to verify fully.** |
| "Time pressure + CFO says skip validation" | Combined pressures don't multiply exceptions. Zero exceptions in finance. | **Follow all requirements regardless of pressure combination.** |
| "Similar calculation worked before" | Past calculations don't validate future ones. Each must be verified. | **Verify every calculation independently.** |
| "User explicitly authorized approximation" | User authorization doesn't override accuracy requirements. | **Cannot comply. Explain accuracy requirement.** |
| "Rounding error is immaterial" | Materiality is not your decision. Report exact figures, let user decide materiality. | **Report precise figures. Document rounding separately.** |

---

## Financial Anti-Rationalizations

### Data Accuracy

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Numbers look reasonable" | Looking reasonable ≠ being correct. Verify source. | **VERIFY against source documents** |
| "Previous period had similar figures" | Similarity ≠ accuracy. Each period is independent. | **VERIFY each period independently** |
| "Small variance, probably OK" | Small variances compound. Every variance needs explanation. | **INVESTIGATE and DOCUMENT all variances** |
| "Manual adjustment is faster" | Manual adjustments bypass audit trail. | **Document ALL adjustments with rationale** |

### Calculation Verification

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Formula worked in previous analysis" | Copy-paste errors are common. Verify inputs and logic. | **VERIFY formula inputs and logic** |
| "Excel calculated it automatically" | Automatic ≠ correct. Verify formula references. | **VERIFY cell references and ranges** |
| "Percentage change looks about right" | Approximate verification is not verification. | **CALCULATE independently and compare** |
| "Totals match, details are fine" | Matching totals can hide offsetting errors. | **VERIFY line item details** |

### Assumptions and Projections

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Industry standard assumption" | Industry standards may not apply to this specific situation. | **DOCUMENT assumption and its appropriateness** |
| "Conservative estimate is safe" | Conservative in one direction = aggressive in another. | **PROVIDE ranges with documented rationale** |
| "Growth rate seems reasonable" | Reasonable is subjective. Cite supporting evidence. | **CITE specific supporting data** |
| "Timing assumption won't matter much" | Timing significantly impacts NPV, IRR, cash flows. | **SENSITIVITY test timing assumptions** |

---

## Compliance Anti-Rationalizations

### Regulatory Reporting

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Similar to last quarter's filing" | Regulations change. Each filing is independent. | **VERIFY current requirements** |
| "Minor disclosure, not critical" | Regulators determine materiality, not analysts. | **INCLUDE all required disclosures** |
| "Deadline is soon, submit what we have" | Incomplete filings have penalties. | **ESCALATE deadline risk, do not submit incomplete** |

### Audit Trail

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "No one will check this detail" | Auditors check everything. Assume full scrutiny. | **DOCUMENT as if audit is tomorrow** |
| "Supporting document is hard to find" | Difficulty doesn't excuse non-compliance. | **LOCATE and ATTACH supporting documentation** |
| "Verbal approval is sufficient" | Verbal approvals have no audit trail. | **OBTAIN written approval** |

---

## How to Reference This File

**For Agents:**
```markdown
## Anti-Rationalization

See [shared-patterns/anti-rationalization.md](../skills/shared-patterns/anti-rationalization.md) for universal and financial anti-rationalizations.

### Domain-Specific Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| [Domain-specific rationalization] | [Domain-specific reason] | **[Domain-specific action]** |
```

**For Skills:**
```markdown
## Anti-Rationalization Table

See [shared-patterns/anti-rationalization.md](../shared-patterns/anti-rationalization.md) for universal anti-rationalizations.

### Workflow-Specific Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| [Workflow-specific rationalization] | [Workflow-specific reason] | **[Workflow-specific action]** |
```
