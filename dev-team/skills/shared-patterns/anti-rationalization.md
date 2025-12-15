# Anti-Rationalization Patterns

Canonical source for anti-rationalization patterns used by all dev-team agents and skills.

AI models naturally attempt to be "helpful" by making autonomous decisions. This is DANGEROUS in structured workflows. These tables use aggressive language intentionally to override the AI's instinct to be accommodating.

---

## Universal Anti-Rationalizations

These rationalizations are ALWAYS wrong, regardless of context:

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "This is prototype/throwaway code" | Prototypes become production 60% of time. Standards apply to ALL code. | **Apply full standards. No prototype exemption.** |
| "Too exhausted to do this properly" | Exhaustion doesn't waive requirements. It increases error risk. | **STOP work. Resume when able to comply fully.** |
| "Time pressure + authority says skip" | Combined pressures don't multiply exceptions. Zero exceptions × any pressure = zero exceptions. | **Follow all requirements regardless of pressure combination.** |
| "Similar task worked without this step" | Past non-compliance doesn't justify future non-compliance. | **Follow complete process every time.** |
| "User explicitly authorized skip" | User authorization doesn't override HARD GATES. | **Cannot comply. Explain non-negotiable requirement.** |
| "Task is simple, doesn't need full process" | Simple tasks have complex impacts. Gates catch what you don't see. | **Follow complete process** |
| "Already passed N steps/gates" | Each step catches different issues. Sunk cost is irrelevant. | **Complete ALL remaining steps** |
| "Manager/authority approved skipping" | Authority cannot override quality gates. Document the pressure. | **Cannot comply. Proceed with gate.** |
| "We'll fix issues later/post-merge" | Later = never. Post-merge fixes are 10x more expensive. | **Fix NOW before proceeding** |
| "Just this once won't hurt" | "Just this once" becomes precedent. Each exception erodes gates. | **No incremental compromise** |
| "90% done, skip remaining" | 90% done with 0% gates = 0% verified. Gates verify the 90%. | **Complete ALL gates** |
| "Close enough to threshold" | Close enough ≠ passing. Thresholds are exact minimums. | **Meet exact threshold** |

---

## TDD Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Code already works, add tests after" | Tests-after is not TDD. You're testing assumptions, not requirements. | **DELETE code. Write test FIRST.** |
| "I'll keep code as reference" | Reference = adapting = testing-after. Delete means DELETE. | **Delete from everywhere. No backup.** |
| "Too simple for TDD" | Simple code still needs tests. TDD is mandatory for ALL changes. | **TDD for ALL code** |
| "I've TDDed 9/10 functions, skip last one" | TDD is ALL-or-nothing. 9/10 = 0/10. | **TDD for EVERY function** |
| "Refactoring tests doesn't need TDD" | Test code refactoring is exempt. Production code is NOT. | **Clarify what you're changing** |

---

## Review Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Trivial change, skip review" | Security vulnerabilities fit in 1 line. ALL changes require review. | **Review ALL changes** |
| "Only N lines changed" | Line count is irrelevant. SQL injection is 1 line. | **Review ALL changes** |
| "One reviewer is enough" | 3 reviewers catch different issues. All required. | **Dispatch ALL 3 reviewers** |
| "Run reviewers sequentially" | Sequential = 3x slower. Parallel is REQUIRED. | **Single message, 3 Task calls** |
| "Only MEDIUM issues, can proceed" | MEDIUM = Fix NOW. No deferral, no FIXME. | **Fix MEDIUM issues** |
| "Small fix, no re-review needed" | Small fixes can have big impacts. | **Re-run ALL 3 reviewers after ANY fix** |

---

## Validation Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "User is busy, assume approval" | CANNOT assume approval. Wait for explicit response. | **Wait for explicit APPROVED/REJECTED** |
| "Tests pass, validation redundant" | Tests verify code works. Validation verifies it meets REQUIREMENTS. | **Validation REQUIRED** |
| "'Looks good' means approved" | "Looks good" is ambiguous. Require explicit APPROVED. | **Ask for explicit APPROVED** |
| "No objections = approved" | Silence ≠ approval. Require explicit response. | **Wait for explicit response** |

---

## Agent-Specific Anti-Rationalizations

### Standards Compliance Mode Detection

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Prompt didn't have exact marker" | Multiple patterns trigger mode. Check all. | **Check ALL detection patterns** |
| "User seems to want direct implementation" | Seeming ≠ knowing. If ANY pattern matches, include. | **Include if uncertain** |
| "Standards section too long for this task" | Length doesn't determine requirement. Pattern match does. | **Include full section if triggered** |

### Standards Section Comparison

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "I'll check the main sections only" | ALL sections must be checked. You don't decide relevance. | **Check EVERY section from WebFetch result** |
| "This section doesn't apply" | Report it as N/A with reason, don't skip silently. | **Report ALL sections with status** |
| "Codebase doesn't have this pattern" | That's a finding! Report as Non-Compliant or N/A. | **Report missing patterns** |

### WebFetch Standards Quoting

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Brief description is enough" | Developers need exact code to understand the fix. | **Quote from WebFetch result** |
| "Standards are in my knowledge" | You must use the FETCHED standards, not assumptions. | **Quote from WebFetch result** |
| "WebFetch result was too large" | Extract the specific pattern for this finding. | **Quote only relevant section** |

---

## Specialist Dispatch Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "This is a small task, no specialist needed" | Size doesn't determine complexity. Standards always apply. | **DISPATCH specialist** |
| "I already know how to do this" | Your knowledge ≠ Ring standards loaded by specialist. | **DISPATCH specialist** |
| "Dispatching takes too long" | Quality > speed. Specialist follows full standards. | **DISPATCH specialist** |
| "I'll just fix this one thing quickly" | Quick fixes bypass TDD, testing, review. | **DISPATCH specialist** |
| "I've already implemented 80% myself" | Past mistakes don't justify continuing wrong approach. | **DISPATCH specialist. Accept sunk cost.** |

---

## Skill-Specific Anti-Rationalizations

### Gate Execution

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Previous gate passed, this one will too" | Each gate is independent. No assumptions. | **Execute full gate requirements** |
| "Small change, skip full process" | Size doesn't determine requirements. | **Follow complete process** |
| "Already tested manually" | Manual testing ≠ gate compliance. | **Execute automated verification** |

---

## How to Reference This File

**For Agents:**
```markdown
## Anti-Rationalization

See [shared-patterns/anti-rationalization.md](../skills/shared-patterns/anti-rationalization.md) for universal anti-rationalizations.

[OPTIONAL: Add domain-specific rationalizations ONLY if not covered above]
```

**For Skills:**
```markdown
## Common Rationalizations - REJECTED

See [shared-patterns/anti-rationalization.md](../shared-patterns/anti-rationalization.md) for universal anti-rationalizations.

[OPTIONAL: Add gate-specific rationalizations ONLY if not covered above]
```
