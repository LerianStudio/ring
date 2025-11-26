---
name: requesting-code-review
description: |
  Parallel code review dispatch - sends to 3 specialized reviewers (code, business-logic,
  security) simultaneously for comprehensive feedback.

trigger: |
  - After completing major feature implementation
  - After completing task in subagent-driven-development
  - Before merge to main branch
  - After fixing complex bug

skip_when: |
  - Trivial change (<20 lines, no logic change) → verify manually
  - Still in development → finish implementation first
  - Already reviewed and no changes since → proceed

sequence:
  after: [verification-before-completion]
  before: [finishing-a-development-branch]
---

# Requesting Code Review

Dispatch all three reviewer subagents in parallel for fast, comprehensive feedback.

**Core principle:** Review early, review often. Parallel execution provides 3x faster feedback with comprehensive coverage.

## Review Order (Parallel Execution)

Three specialized reviewers run in **parallel** for maximum speed:

**1. ring:code-reviewer** (Foundation)
- **Focus:** Architecture, design patterns, code quality, maintainability
- **Model:** Opus (required for comprehensive analysis)
- **Reports:** Code quality issues, architectural concerns

**2. ring:business-logic-reviewer** (Correctness)
- **Focus:** Domain correctness, business rules, edge cases, requirements
- **Model:** Opus (required for deep domain understanding)
- **Reports:** Business logic issues, requirement gaps

**3. ring:security-reviewer** (Safety)
- **Focus:** Vulnerabilities, authentication, input validation, OWASP risks
- **Model:** Opus (required for thorough security analysis)
- **Reports:** Security vulnerabilities, OWASP risks

**Critical:** All three reviewers run simultaneously in a single message with 3 Task tool calls. Each reviewer works independently and returns its report. After all complete, aggregate findings and handle by severity.

## When to Request Review

**Mandatory:**
- After each task in subagent-driven development
- After completing major feature

**Optional but valuable:**
- When stuck (fresh perspective)
- Before refactoring (baseline check)
- After fixing complex bug

## Which Reviewers to Use

**Use all three reviewers (parallel) when:**
- Implementing new features (comprehensive check)
- Before merge to main (final validation)
- After completing major milestone

**Use subset when domain doesn't apply:**
- **Code-reviewer only:** Documentation changes, config updates
- **Code + Business (skip security):** Internal scripts with no external input
- **Code + Security (skip business):** Infrastructure/DevOps changes

**Default: Use all three in parallel.** Only skip reviewers when you're certain their domain doesn't apply.

**Two ways to run parallel reviews:**
1. **Direct parallel dispatch:** Launch 3 Task calls in single message (explicit control)
2. **/ring:review command:** Command that provides workflow instructions for parallel review (convenience)

## How to Request

**1. Get git SHAs:**
```bash
BASE_SHA=$(git rev-parse HEAD~1)  # or origin/main
HEAD_SHA=$(git rev-parse HEAD)
```

**2. Dispatch all three reviewers in parallel:**

**CRITICAL: Use a single message with 3 Task tool calls to launch all reviewers simultaneously.**

```
# Single message with 3 parallel Task calls:

Task tool #1 (ring:code-reviewer):
  model: "opus"
  description: "Review code quality and architecture"
  prompt: |
    WHAT_WAS_IMPLEMENTED: [What you built]
    PLAN_OR_REQUIREMENTS: [Requirements/plan reference]
    BASE_SHA: [starting commit]
    HEAD_SHA: [current commit]
    DESCRIPTION: [brief summary]

Task tool #2 (ring:business-logic-reviewer):
  model: "opus"
  description: "Review business logic correctness"
  prompt: |
    [Same parameters as above]

Task tool #3 (ring:security-reviewer):
  model: "opus"
  description: "Review security vulnerabilities"
  prompt: |
    [Same parameters as above]
```

**All three reviewers execute simultaneously. Wait for all to complete.**

**3. Aggregate findings from all three reviews:**

Collect all issues by severity across all three reviewers:
- **Critical issues:** [List from all 3 reviewers]
- **High issues:** [List from all 3 reviewers]
- **Medium issues:** [List from all 3 reviewers]
- **Low issues:** [List from all 3 reviewers]
- **Cosmetic/Nitpick issues:** [List from all 3 reviewers]

**4. Handle by severity:**

**Critical/High/Medium → Fix immediately:**
- Dispatch fix subagent to address all Critical/High/Medium issues
- After fixes complete, re-run all 3 reviewers in parallel
- Repeat until no Critical/High/Medium issues remain

**Low issues → Add TODO comments in code:**
```javascript
// TODO(review): [Issue description from reviewer]
// Reported by: [reviewer-name] on [date]
// Location: file:line
```

**Cosmetic/Nitpick → Add FIXME comments in code:**
```javascript
// FIXME(nitpick): [Issue description from reviewer]
// Reported by: [reviewer-name] on [date]
// Location: file:line
```

**Push back on incorrect feedback:**
- If reviewer is wrong, provide reasoning and evidence
- Request clarification for ambiguous feedback
- Security concerns require extra scrutiny before dismissing

## Integration with Workflows

**Subagent-Driven Development:**
- Review after EACH task using parallel dispatch (all 3 reviewers at once)
- Aggregate findings across all reviewers
- Fix Critical/High/Medium, add TODO/FIXME for Low/Cosmetic
- Move to next task only after all Critical/High/Medium resolved

**Executing Plans:**
- Review after each batch (3 tasks) using parallel dispatch
- Handle severity-based fixes before next batch
- Track Low/Cosmetic issues in code comments

**Ad-Hoc Development:**
- Review before merge using parallel dispatch (all three reviewers)
- Can use single reviewer if domain-specific (e.g., docs → code-reviewer only)

## Red Flags

**Never:**
- Dispatch reviewers sequentially (wastes time - use parallel!)
- Proceed to next task with unfixed Critical/High/Medium issues
- Skip security review for "just refactoring" (may expose vulnerabilities)
- Skip code review because "code is simple"
- Forget to add TODO/FIXME comments for Low/Cosmetic issues
- Argue with valid technical/security feedback without evidence

**Always:**
- Launch all 3 reviewers in a single message (3 Task calls)
- Specify `model: "opus"` for each reviewer
- Wait for all reviewers to complete before aggregating
- Fix Critical/High/Medium immediately
- Add TODO comments for Low issues
- Add FIXME comments for Cosmetic/Nitpick issues
- Re-run all 3 reviewers after fixing Critical/High/Medium issues

**If reviewer wrong:**
- Push back with technical reasoning
- Show code/tests that prove it works
- Request clarification
- Security concerns require extra scrutiny before dismissing

## Re-running Reviews After Fixes

**After fixing Critical/High/Medium issues:**
- Re-run all 3 reviewers in parallel (same as initial review)
- Don't cherry-pick which reviewers to re-run
- Parallel execution makes full re-review fast (~3-5 minutes total)

**After adding TODO/FIXME comments:**
- Commit with message noting review completion and tech debt tracking
- No need to re-run reviews for comment additions
