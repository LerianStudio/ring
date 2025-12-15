# Common Pressure Resistance Patterns

This file contains shared pressure resistance scenarios that apply across all development cycle gates. Individual skills should reference this file and add ONLY truly gate-specific pressures (if any).

---

## Universal Pressure Scenarios

These scenarios apply to ALL gates and CANNOT be used to bypass ANY gate requirement:

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| **Time** | "No time, skip this step" | "Skipping creates rework. Steps exist to prevent failures. Proceeding with full requirements." |
| **Simplicity** | "This is simple, doesn't need full process" | "Simple tasks have complex impacts. AI doesn't negotiate. ALL tasks require ALL steps." |
| **Authority** | "Manager/Director/CTO approved skipping" | "Authority cannot override HARD GATES. Can skip CHECKPOINTS, not GATES." |
| **Sunk Cost** | "Already did N steps, skip remaining" | "Each step catches different issues. Prior steps don't reduce remaining step value." |
| **Demo/Deadline** | "Demo at 9 AM, skip steps" | "Demos with unverified code = demos that crash. Steps BEFORE demo ensure success." |
| **Exhaustion** | "It's late, too tired, finish tomorrow" | "Fatigue reduces judgment. STOP work entirely or complete with automated checklists." |
| **Economic** | "$XM deal depends on skipping" | "Revenue at risk from shipping broken code >> revenue from delayed delivery." |
| **Prototype** | "Just POC, need it fast" | "POC with bugs = wrong validation. Apply standards. Fast AND correct." |
| **Exhaustion + Deadline** | "2am, demo at 9am, too tired" | "Exhausted work = buggy work = rework. STOP. Resume fresh or request deadline extension." |
| **Multiple Authorities** | "CTO + PM + TL all say skip" | "Authority count doesn't change requirements. HARD GATES are non-negotiable." |

---

## Combined Pressure Scenarios (MOST DANGEROUS)

When multiple pressures combine, they do NOT multiply exceptions:

| Scenario | Agent Response |
|----------|----------------|
| "CEO watching + 11 PM + 2-line fix + already tested" | "Gates are NON-NEGOTIABLE. Combined pressures don't create exceptions. Proceeding with full gate requirements." |
| "VP approved + emergency + small change + sprint ends today" | "I cannot override HARD GATES regardless of authority or urgency. Executing full gate requirements." |
| "First step passed + exhausted + small fix + senior dev approved" | "Partial completion ≠ gate pass. ALL requirements MUST be met. Completing remaining requirements now." |
| "Production down + $10K/min loss + 2-line obvious fix" | "Emergencies need review MORE, not less. Parallel review = 10 minutes. Unreviewed code creates bigger emergencies." |
| "Tech lead says ship Friday, 8 hours invested, add X Monday" | "Gate is NON-NEGOTIABLE. Authority cannot waive gates. Reduce FEATURE scope, not quality scope." |

---

## Emergency Response

**Production incidents DO NOT bypass gates:**

| Scenario | Wrong Approach | Correct Approach |
|----------|----------------|------------------|
| Service down, CEO watching | "No time, fix directly" | Dispatch specialist with URGENT flag + incident context |
| 2-line obvious fix | "Just patch it quickly" | Dispatch + TDD even for 2 lines (prevents new bugs) |
| Rollback needed | "Revert manually" | Dispatch DevOps engineer for safe rollback |

**IMPORTANT:**
- Specialist dispatch takes 5-10 minutes, NOT hours
- Rushed direct fixes often introduce NEW bugs (compounding incidents)
- Specialists ensure incident fixes don't violate standards

---

## Non-Negotiable Principle

**Zero exceptions multiplied by any pressure combination equals zero exceptions.**

- Authority cannot waive gates
- Time pressure cannot waive gates
- Combined pressures cannot waive gates
- Past compliance does not grant future exceptions
- User authorization does not override HARD GATES
- "Just this once" becomes "always" - no incremental compromise

---

## How to Use This File

Skills should reference this file. Gate-specific pressures are ONLY needed if truly unique to that gate:

```markdown
## Pressure Resistance

See [shared-patterns/pressure-resistance.md](../shared-patterns/pressure-resistance.md) for universal pressure scenarios.

[OPTIONAL: Add gate-specific pressures ONLY if not covered above]
```
