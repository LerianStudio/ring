# Anti-Rationalization Patterns

Canonical source for anti-rationalization patterns used by all finops-team agents and skills.

AI models naturally attempt to be "helpful" by making autonomous decisions. This is DANGEROUS in structured workflows. These tables use aggressive language intentionally to override the AI's instinct to be accommodating.

## Universal Anti-Rationalizations

These rationalizations are ALWAYS wrong, regardless of context:

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "This is prototype/throwaway code" | Prototypes become production 60% of time. Standards apply to ALL templates. | **Apply full standards. No prototype exemption.** |
| "Too exhausted to do this properly" | Exhaustion doesn't waive requirements. It increases error risk. | **STOP work. Resume when able to comply fully.** |
| "Time pressure + authority says skip" | Combined pressures don't multiply exceptions. Zero exceptions × any pressure = zero exceptions. | **Follow all requirements regardless of pressure combination.** |
| "Similar task worked without this step" | Past non-compliance doesn't justify future non-compliance. | **Follow complete process every time.** |
| "User explicitly authorized skip" | User authorization doesn't override HARD GATES. | **Cannot comply. Explain non-negotiable requirement.** |

---

## Regulatory Compliance Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Template worked before" | Regulatory requirements change | **Verify against CURRENT requirements** |
| "Field mapping is obvious" | Obvious ≠ correct | **Verify EVERY field mapping** |
| "Similar to previous submission" | Each submission is independent | **Full verification REQUIRED** |
| "Regulator hasn't complained" | Absence of complaint ≠ compliance | **Verify against specification** |

---

## Template Implementation Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Minor format difference" | Format compliance is strict | **Match EXACT format specification** |
| "Field is always the same value" | Static doesn't mean skip verification | **Verify ALL fields every time** |
| "Edge case won't happen" | Edge cases in regulatory = penalties | **Handle ALL edge cases** |

---

## Analysis-Specific Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Previous analysis covered this" | Each analysis is independent | **Verify ALL fields** |
| "Regulatory hasn't changed" | Assumption ≠ verification | **Check current requirements** |
| "Field mapping is standard" | Standards vary by regulation | **Verify against SPECIFIC regulation** |

---

## How to Reference This File

**For Agents:**
```markdown
## Anti-Rationalization

See [shared-patterns/anti-rationalization.md](../skills/shared-patterns/anti-rationalization.md) for universal and regulatory-specific anti-rationalizations.

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
