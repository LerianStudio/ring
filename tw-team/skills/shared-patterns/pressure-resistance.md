# Common Pressure Resistance Patterns

This file contains shared pressure resistance scenarios that apply across all technical writing gates. Individual skills should reference this file and add gate-specific pressures.

## Universal Pressure Scenarios

These scenarios apply to ALL gates and CANNOT be used to bypass ANY gate requirement:

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| **Exhaustion + Deadline** | "2am, demo at 9am, too tired" | "Exhausted work = buggy work = rework. STOP. Resume fresh or request deadline extension." |
| **Prototype + Time** | "Just POC, need it fast" | "POC with bugs = wrong validation. Apply standards. Fast AND correct." |
| **Multiple Authorities** | "CTO + PM + TL all say skip" | "Authority count doesn't change requirements. HARD GATES are non-negotiable." |

## Documentation-Specific Pressures

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| **Skip Review** | "Doc looks fine, ship it" | "Unreviewed documentation = potential user confusion. Review is MANDATORY." |
| **Incomplete API Docs** | "Users will figure it out" | "Documentation MUST be explicit. Users shouldn't guess." |
| **Rush Tutorial** | "Just outline the steps" | "Incomplete tutorials = frustrated users. Complete documentation REQUIRED." |

## Combined Pressure Scenarios (MOST DANGEROUS)

When multiple pressures combine, they do NOT multiply exceptions:

| Scenario | Agent Response |
|----------|----------------|
| "Release tomorrow + PM approved + small API change" | "Gates are NON-NEGOTIABLE. Combined pressures don't create exceptions. Proceeding with full documentation requirements." |
| "VP approved + hotfix + obvious change + senior approved" | "I cannot override HARD GATES regardless of authority or urgency. Executing full documentation requirements." |

## Non-Negotiable Principle

**Zero exceptions multiplied by any pressure combination equals zero exceptions.**

- Authority cannot waive documentation quality
- Time pressure cannot waive accuracy
- Combined pressures cannot waive completeness
- Past compliance does not grant future exceptions
- User authorization does not override HARD GATES

## How to Use This File

Skills should reference this file and add gate-specific pressures:

```markdown
## Pressure Resistance

See [shared-patterns/pressure-resistance.md](../shared-patterns/pressure-resistance.md) for universal pressure scenarios.

### Gate-Specific Pressures

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| [Gate-specific pressure] | [Gate-specific request] | [Gate-specific response] |
```
