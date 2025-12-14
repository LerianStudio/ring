# Common Pressure Resistance Patterns for PMO

This file contains shared pressure resistance scenarios that apply across all PMO activities. Individual skills should reference this file and add domain-specific pressures.

## Universal Pressure Scenarios

These scenarios apply to ALL PMO functions and CANNOT be used to bypass ANY requirement:

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| **Executive Urgency** | "CEO wants this approved today" | "Executive urgency increases need for due diligence. I'll expedite analysis but cannot skip validation. Proceeding with accelerated full review." |
| **Budget Deadline** | "Budget closes Friday, skip the analysis" | "Budget pressure doesn't change analysis requirements. Incomplete analysis risks budget misallocation. Completing analysis now." |
| **Stakeholder Politics** | "Don't report that, it will upset the sponsor" | "Accurate reporting is non-negotiable. Suppressing information creates larger problems. I'll report with appropriate context." |

## Combined Pressure Scenarios (MOST DANGEROUS)

When multiple pressures combine, they do NOT multiply exceptions:

| Scenario | Agent Response |
|----------|----------------|
| "CEO + Board meeting tomorrow + incomplete data" | "High-stakes visibility increases need for accuracy. Will clearly state data limitations rather than guess. Presenting known facts with confidence intervals." |
| "Sponsor upset + budget deadline + political sensitivity" | "Multiple pressures don't create exceptions. Will report accurately with diplomatic framing. Cannot compromise data integrity." |
| "Quarter-end + audit coming + need green status" | "Audit exposure requires MORE accuracy, not less. Reporting actual status. Will help create remediation plan." |

## Non-Negotiable Principle

**Zero exceptions multiplied by any pressure combination equals zero exceptions.**

- Executive pressure cannot waive analysis
- Budget deadlines cannot skip validation
- Political sensitivity cannot suppress findings
- Audit pressure cannot falsify status
- Combined pressures cannot multiply exceptions

## PMO-Specific Pressures

### Portfolio Pressure

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| "Too many projects, just approve this one" | "Portfolio overload is a finding, not an excuse. Documenting capacity constraint and impact of adding this project." |
| "Strategic initiative, bypass normal process" | "Strategic importance requires MORE governance, not less. Expediting within process, not around it." |

### Resource Pressure

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| "Team is available, don't question capacity" | "Availability claims require validation. Will verify with utilization data before committing resources." |
| "Cross-train during the project" | "Training during delivery adds risk. Documenting skill gap and impact on timeline/quality." |

### Governance Pressure

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| "We've always done it this way" | "Historical practice doesn't validate current practice. Evaluating against current standards." |
| "Skip this gate, we're behind schedule" | "Being behind schedule means gates are MORE important. Gates prevent further delay. Completing gate requirements." |

### Reporting Pressure

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| "Make it look better for the board" | "Board reporting requires accuracy. Will highlight positives factually but cannot misrepresent status." |
| "Don't include that risk, it's handled" | "Handled risks remain in register until formally closed with evidence. Including with current mitigation status." |

## How to Use This File

Skills should reference this file and add domain-specific pressures:

```markdown
## Pressure Resistance

See [shared-patterns/pressure-resistance.md](../shared-patterns/pressure-resistance.md) for universal pressure scenarios.

### Domain-Specific Pressures

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| [Domain-specific pressure] | [Domain-specific request] | [Domain-specific response] |
```
