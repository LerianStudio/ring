# Common Pressure Resistance Patterns

This file contains shared pressure resistance scenarios that apply across all pre-development planning gates. Individual skills should reference this file and add gate-specific pressures.

## Universal Pressure Scenarios

These scenarios apply to ALL gates and CANNOT be used to bypass ANY gate requirement:

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| **Exhaustion + Deadline** | "2am, demo at 9am, too tired" | "Exhausted work = buggy work = rework. STOP. Resume fresh or request deadline extension." |
| **Prototype + Time** | "Just POC, need it fast" | "POC with bugs = wrong validation. Apply standards. Fast AND correct." |
| **Multiple Authorities** | "CTO + PM + TL all say skip" | "Authority count doesn't change requirements. HARD GATES are non-negotiable." |

## Pre-Dev Specific Pressures

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| **Skip Research** | "We already know the approach" | "Assumptions without research = missed requirements. Research is MANDATORY." |
| **Skip PRD** | "Requirements are obvious" | "Obvious to you ≠ obvious to team. PRD ensures shared understanding." |
| **Rush Task Breakdown** | "Just give rough estimates" | "Rough estimates = scope creep. Detailed breakdown is REQUIRED." |

## Combined Pressure Scenarios (MOST DANGEROUS)

When multiple pressures combine, they do NOT multiply exceptions:

| Scenario | Agent Response |
|----------|----------------|
| "CEO watching + 11 PM + simple feature + already know approach" | "Gates are NON-NEGOTIABLE. Combined pressures don't create exceptions. Proceeding with full gate requirements." |
| "VP approved + emergency + small scope + sprint ends today" | "I cannot override HARD GATES regardless of authority or urgency. Executing full gate requirements." |

## Non-Negotiable Principle

**Zero exceptions multiplied by any pressure combination equals zero exceptions.**

- Authority cannot waive gates
- Time pressure cannot waive gates
- Combined pressures cannot waive gates
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
