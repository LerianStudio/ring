# Anti-Rationalization Patterns

Canonical source for anti-rationalization patterns used by all dev-team agents and skills.

AI models naturally attempt to be "helpful" by making autonomous decisions. This is DANGEROUS in structured workflows. These tables use aggressive language intentionally to override the AI's instinct to be accommodating.

---

## ⛔ Standards Deferral Anti-Rationalizations (CRITICAL)

**Ring Standards apply from Task 1. DEFERRED = FAILED. No exceptions.**

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "PM plan says X is for later tasks" | PM defines WHAT to build, not HOW. Ring Standards define HOW. | **Implement all standards NOW** |
| "Task 1 is just initial setup" | Setup WITH standards = correct setup. Without = wrong from Day 1. | **Implement all standards NOW** |
| "Basic implementation is sufficient initially" | "Basic" is not compliant. Full standards or fail. | **Implement all standards NOW** |
| "DEFERRED to later tasks as per plan" | DEFERRED = FAILED. Standards are not deferrable. | **Implement all standards NOW** |
| "Task dependency graph shows standards later" | Dependency graph is for features, not for standards. Standards are prerequisites. | **Implement all standards NOW** |
| "This standard doesn't apply to Task 1 scope" | all standards apply to all tasks. Scope is irrelevant. | **Implement all standards NOW** |
| "Will add observability/testing/error-handling later" | Later = never. Retrofitting is 10x harder. | **Implement all standards NOW** |
| "MVP doesn't need full standards" | MVP with standards = correct MVP. Without = technical debt from Day 1. | **Implement all standards NOW** |

**⛔ HARD GATE:** If your output contains "DEFERRED" regarding any Ring Standard → Implementation is INCOMPLETE. Fix before proceeding.

**⛔ SEVERITY:** Any agent outputting "DEFERRED" for a Ring Standard = CRITICAL FAILURE = Return to previous gate.

---

## Universal Anti-Rationalizations

These rationalizations are always wrong, regardless of context:

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "This is prototype/throwaway code" | Prototypes become production 60% of time. Standards apply to all code. | **Apply full standards. No prototype exemption.** |
| "Too exhausted to do this properly" | Exhaustion doesn't waive requirements. It increases error risk. | **STOP work. Resume when able to comply fully.** |
| "Time pressure + authority says skip" | Combined pressures don't multiply exceptions. Zero exceptions × any pressure = zero exceptions. | **Follow all requirements regardless of pressure combination.** |
| "Similar task worked without this step" | Past non-compliance doesn't justify future non-compliance. | **Follow complete process every time.** |
| "User explicitly authorized skip" | User authorization doesn't override HARD GATES. | **Cannot comply. Explain non-negotiable requirement.** |
| "Task is simple, doesn't need full process" | Simple tasks have complex impacts. Gates catch what you don't see. | **Follow complete process** |
| "Already passed N steps/gates" | Each step catches different issues. Sunk cost is irrelevant. | **Complete all remaining steps** |
| "Manager/authority approved skipping" | Authority cannot override quality gates. Document the pressure. | **Cannot comply. Proceed with gate.** |
| "We'll fix issues later/post-merge" | Later = never. Post-merge fixes are 10x more expensive. | **Fix NOW before proceeding** |
| "Just this once won't hurt" | "Just this once" becomes precedent. Each exception erodes gates. | **No incremental compromise** |
| "90% done, skip remaining" | 90% done with 0% gates = 0% verified. Gates verify the 90%. | **Complete all gates** |
| "Close enough to threshold" | Close enough ≠ passing. Thresholds are exact minimums. | **Meet exact threshold** |

---

## TDD Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Code already works, add tests after" | Tests-after is not TDD. You're testing assumptions, not requirements. | **DELETE code. Write test FIRST.** |
| "I'll keep code as reference" | Reference = adapting = testing-after. Delete means DELETE. | **Delete from everywhere. No backup.** |
| "Too simple for TDD" | Simple code still needs tests. TDD is mandatory for all changes. | **TDD for all code** |
| "I've TDDed 9/10 functions, skip last one" | TDD is all-or-nothing. 9/10 = 0/10. | **TDD for every function** |
| "Refactoring tests doesn't need TDD" | Test code refactoring is exempt. Production code is not. | **Clarify what you're changing** |

---

## Review Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Trivial change, skip review" | Security vulnerabilities fit in 1 line. all changes require review. | **Review all changes** |
| "Only N lines changed" | Line count is irrelevant. SQL injection is 1 line. | **Review all changes** |
| "One reviewer is enough" | 10 reviewers catch different issues. All required. | **Dispatch all 10 reviewers** |
| "Run reviewers sequentially" | Sequential = 10x slower. Parallel is REQUIRED. | **Single message, 10 Task calls** |
| "Only MEDIUM issues, can proceed" | MEDIUM = Fix NOW. No deferral, no FIXME. | **Fix MEDIUM issues** |
| "Small fix, no re-review needed" | Small fixes can have big impacts. | **Re-run all 10 reviewers after any fix** |

---

## Validation Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "User is busy, assume approval" | CANNOT assume approval. Wait for explicit response. | **Wait for explicit APPROVED/REJECTED** |
| "Tests pass, validation redundant" | Tests verify code works. Validation verifies it meets REQUIREMENTS. | **Validation REQUIRED** |
| "'Looks good' means approved" | "Looks good" is ambiguous. Require explicit APPROVED. | **Ask for explicit APPROVED** |
| "No objections = approved" | Silence ≠ approval. Require explicit response. | **Wait for explicit response** |

---

## ⛔ Standards Boundary Anti-Rationalizations (CRITICAL)

**Agents MUST check only what standards explicitly define. Inventing requirements = FAILURE.**

See [shared-patterns/standards-boundary-enforcement.md](standards-boundary-enforcement.md) for complete boundaries.

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Industry standard to have make proto" | Industry ≠ Ring standards. Ring defines requirements. | **Do not flag** |
| "Most Go projects need gRPC" | Most ≠ this project. Standards define this project. | **Do not flag** |
| "It's a best practice to have X" | Best practices are IN the standards. If not there, not required. | **Do not flag** |
| "This would improve the codebase" | Improvement suggestions ≠ compliance findings. | **Do not flag as non-compliant** |
| "I've seen this in similar projects" | Similar ≠ this. Standards are project-specific. | **Do not flag** |
| "Common sense says this is needed" | Common sense ≠ explicit requirement. Standards are explicit. | **Do not flag** |
| "The team probably wants this" | Speculation about preferences is not compliance. Standards state requirements explicitly. | **Do not flag** |
| "It's implied by the architecture" | Implied ≠ explicit. Only explicit requirements count. | **Do not flag** |

**⛔ HARD GATE:** If you cannot quote the EXACT requirement from WebFetch result → Do not flag it.

---

## Agent-Specific Anti-Rationalizations

### Standards Compliance Mode Detection

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Prompt didn't have exact marker" | Multiple patterns trigger mode. Check all. | **Check all detection patterns** |
| "User seems to want direct implementation" | Seeming ≠ knowing. If any pattern matches, include. | **Include if uncertain** |
| "Standards section too long for this task" | Length doesn't determine requirement. Pattern match does. | **Include full section if triggered** |

### Standards Section Comparison

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "I'll check the main sections only" | all sections must be checked. You don't decide relevance. | **Check every section from WebFetch result** |
| "This section doesn't apply" | Report it as N/A with reason, don't skip silently. | **Report all sections with status** |
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
| "It's faster to do it directly" | Speed ≠ correct process. The ring:dev-cycle exists for a reason. | **Follow ring:dev-cycle gates. No shortcuts.** |
| "These are simple changes" | Simplicity doesn't justify skipping gates. Simple bugs cause complex incidents. | **all gates mandatory regardless of perceived simplicity.** |
| "I know this code well, skip validation" | Familiarity breeds blind spots. Gates catch what you miss. | **Execute all gates. No expertise exemption.** |
| "Deadline is tight, skip non-critical gates" | No gate is "non-critical". Each catches different issues. | **all gates are mandatory. Negotiate deadline, not quality.** |
| "This is just a hotfix" | Hotfixes are highest-risk changes. They need MORE scrutiny, not less. | **Full ring:dev-cycle for all changes including hotfixes.** |

### Refactor Gap Tracking

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "This divergence is too minor to track" | You don't decide what's minor. Standards do. | **Create FINDING-XXX** |
| "Codebase pattern is acceptable alternative" | Alternative ≠ compliant. Ring standards are the baseline. | **Create FINDING-XXX** |
| "Low severity means optional" | Low severity = low priority, not optional. | **Create FINDING-XXX** |
| "Cosmetic differences don't count" | Cosmetic = standards compliance. They count. | **Create FINDING-XXX** |
| "This would create too many findings" | Quantity is not your concern. Completeness is. | **Create all FINDING-XXX entries** |
| "Team prefers current approach" | Preference ≠ compliance. Document the gap. | **Create FINDING-XXX** |
| "Fixing this adds no value" | You don't assess value. Standards define value. | **Create FINDING-XXX** |

---

## How to Reference This File

**For Agents:**
```markdown
## Anti-Rationalization

See [shared-patterns/shared-anti-rationalization.md](../skills/shared-patterns/shared-anti-rationalization.md) for universal anti-rationalizations.

[OPTIONAL: Add domain-specific rationalizations only if not covered above]
```

**For Skills:**
```markdown
## Common Rationalizations - REJECTED

See [shared-patterns/shared-anti-rationalization.md](../shared-patterns/shared-anti-rationalization.md) for universal anti-rationalizations.

[OPTIONAL: Add gate-specific rationalizations only if not covered above]
```
