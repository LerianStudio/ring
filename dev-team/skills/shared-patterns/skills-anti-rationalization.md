# Common Anti-Rationalization Patterns

This file contains shared anti-rationalization entries that apply across all development cycle gates. Individual skills should reference this file and add gate-specific anti-rationalizations.

## Universal Anti-Rationalizations

These rationalizations are ALWAYS wrong, regardless of which gate you're executing:

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "This is prototype/throwaway code" | Prototypes become production 60% of time. Standards apply to ALL code. | **Apply full standards. No prototype exemption.** |
| "Too exhausted to do this properly" | Exhaustion doesn't waive requirements. It increases error risk. | **STOP work. Resume when able to comply fully.** |
| "Time pressure + authority says skip" | Combined pressures don't multiply exceptions. Zero exceptions × any pressure = zero exceptions. | **Follow all requirements regardless of pressure combination.** |
| "Similar task worked without this step" | Past non-compliance doesn't justify future non-compliance. | **Follow complete process every time.** |
| "User explicitly authorized skip" | User authorization doesn't override HARD GATES. | **Cannot comply. Explain non-negotiable requirement.** |

## Universal Common Rationalizations - REJECTED

These excuses apply across ALL gates:

| Excuse | Reality |
|--------|---------|
| "This is prototype/throwaway code" | Prototypes become production 60% of time. Standards apply to ALL code. |
| "Too exhausted to do this properly" | Exhaustion doesn't waive requirements. It increases error risk. |
| "Time pressure + authority says skip" | Combined pressures don't multiply exceptions. Zero exceptions × any pressure = zero exceptions. |
| "Similar task worked without this step" | Past non-compliance doesn't justify future non-compliance. |
| "User explicitly authorized skip" | User authorization doesn't override HARD GATES. |

## Why Anti-Rationalization Tables Are Required

AI models naturally attempt to be "helpful" by making autonomous decisions. This is DANGEROUS in structured workflows. These tables use aggressive language intentionally to override the AI's instinct to be accommodating.

## How to Use This File

Skills should reference this file and add gate-specific anti-rationalizations:

```markdown
## Anti-Rationalization Table

See [shared-patterns/skills-anti-rationalization.md](../shared-patterns/skills-anti-rationalization.md) for universal anti-rationalizations.

### Gate-Specific Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| [Gate-specific rationalization] | [Gate-specific reason] | **[Gate-specific action]** |
```
