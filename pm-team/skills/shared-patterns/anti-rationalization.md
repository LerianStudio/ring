# Anti-Rationalization Patterns

Canonical source for anti-rationalization patterns used by all pm-team agents and skills.

AI models naturally attempt to be "helpful" by making autonomous decisions. This is DANGEROUS in structured workflows. These tables use aggressive language intentionally to override the AI's instinct to be accommodating.

## Universal Anti-Rationalizations

These rationalizations are ALWAYS wrong, regardless of context:

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "This is prototype/throwaway code" | Prototypes become production 60% of time. Standards apply to ALL code. | **Apply full standards. No prototype exemption.** |
| "Too exhausted to do this properly" | Exhaustion doesn't waive requirements. It increases error risk. | **STOP work. Resume when able to comply fully.** |
| "Time pressure + authority says skip" | Combined pressures don't multiply exceptions. Zero exceptions × any pressure = zero exceptions. | **Follow all requirements regardless of pressure combination.** |
| "Similar task worked without this step" | Past non-compliance doesn't justify future non-compliance. | **Follow complete process every time.** |
| "User explicitly authorized skip" | User authorization doesn't override HARD GATES. | **Cannot comply. Explain non-negotiable requirement.** |

---

## Research-Specific Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "First result looks correct" | Single source is insufficient verification | **Cross-reference with multiple sources** |
| "This is common knowledge" | Assumptions need verification | **Cite authoritative sources** |
| "Research is taking too long" | Thoroughness > speed | **Complete full research scope** |
| "Team already knows this" | Your job is to document, not assume | **Document ALL findings** |

---

## Planning-Specific Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Simple feature, minimal plan needed" | Complexity often hidden | **Create comprehensive plan** |
| "We can figure out details later" | Vague plans cause issues | **Define ALL tasks upfront** |
| "Team knows the codebase" | Assumptions are dangerous | **Document file paths explicitly** |
| "Previous project used this approach" | Each project is unique | **Analyze THIS project's needs** |

---

## How to Reference This File

**For Agents:**
```markdown
## Anti-Rationalization

See [shared-patterns/anti-rationalization.md](../skills/shared-patterns/anti-rationalization.md) for universal and research-specific anti-rationalizations.

### Domain-Specific Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| [Domain-specific rationalization] | [Domain-specific reason] | **[Domain-specific action]** |
```

**For Skills:**
```markdown
## Anti-Rationalization Table

See [shared-patterns/anti-rationalization.md](../shared-patterns/anti-rationalization.md) for universal anti-rationalizations.

### Gate-Specific Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| [Gate-specific rationalization] | [Gate-specific reason] | **[Gate-specific action]** |
```
