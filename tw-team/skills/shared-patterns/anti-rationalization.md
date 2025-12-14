# Anti-Rationalization Patterns

Canonical source for anti-rationalization patterns used by all tw-team agents and skills.

AI models naturally attempt to be "helpful" by making autonomous decisions. This is DANGEROUS in structured workflows. These tables use aggressive language intentionally to override the AI's instinct to be accommodating.

## Universal Anti-Rationalizations

These rationalizations are ALWAYS wrong, regardless of context:

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "This is prototype/throwaway code" | Prototypes become production 60% of time. Standards apply to ALL documentation. | **Apply full standards. No prototype exemption.** |
| "Too exhausted to do this properly" | Exhaustion doesn't waive requirements. It increases error risk. | **STOP work. Resume when able to comply fully.** |
| "Time pressure + authority says skip" | Combined pressures don't multiply exceptions. Zero exceptions × any pressure = zero exceptions. | **Follow all requirements regardless of pressure combination.** |
| "Similar task worked without this step" | Past non-compliance doesn't justify future non-compliance. | **Follow complete process every time.** |
| "User explicitly authorized skip" | User authorization doesn't override HARD GATES. | **Cannot comply. Explain non-negotiable requirement.** |

---

## Documentation-Specific Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Users will figure it out" | Documentation must be explicit | **Document ALL steps** |
| "Code is self-documenting" | Not all users read code | **Provide clear explanations** |
| "This is obvious" | Obvious to you ≠ obvious to users | **Explain thoroughly** |
| "API is simple, minimal docs needed" | Simple APIs still need complete documentation | **Document ALL parameters and responses** |

---

## API Documentation Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Schema is in OpenAPI spec" | Not all users read specs | **Document in human-readable form** |
| "Error codes are standard HTTP" | Context-specific meanings need documentation | **Document ALL error scenarios** |
| "Optional parameters are obvious" | Optional ≠ undocumented | **Document ALL parameters** |

---

## Review-Specific Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Author is experienced" | Experience doesn't prevent mistakes | **Review ALL documentation** |
| "Small change, skip review" | Small changes can have big impact | **Review ALL changes** |
| "Already reviewed similar doc" | Each document is unique | **Review THIS document** |

---

## How to Reference This File

**For Agents:**
```markdown
## Anti-Rationalization

See [shared-patterns/anti-rationalization.md](../skills/shared-patterns/anti-rationalization.md) for universal and documentation-specific anti-rationalizations.

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
