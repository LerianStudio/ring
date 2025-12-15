---
name: ring-default:requesting-code-review
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

**1. code-reviewer** (Foundation)
- **Focus:** Architecture, design patterns, code quality, maintainability
- **Model:** Opus (required for comprehensive analysis)
- **Reports:** Code quality issues, architectural concerns

**2. business-logic-reviewer** (Correctness)
- **Focus:** Domain correctness, business rules, edge cases, requirements
- **Model:** Opus (required for deep domain understanding)
- **Reports:** Business logic issues, requirement gaps

**3. security-reviewer** (Safety)
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
2. **/codereview command:** Command that provides workflow instructions for parallel review (convenience)

## How to Request

**1. Get SHAs:** `BASE_SHA=$(git rev-parse HEAD~1)` and `HEAD_SHA=$(git rev-parse HEAD)`

**2. Dispatch all three in parallel (CRITICAL: single message, 3 Task calls):**

Each reviewer needs: `WHAT_WAS_IMPLEMENTED`, `PLAN_OR_REQUIREMENTS`, `BASE_SHA`, `HEAD_SHA`, `DESCRIPTION` - all with `model: "opus"`

**3. Aggregate by severity:** Critical | High | Medium | Low | Cosmetic/Nitpick (from all 3 reviewers)

**4. Handle by severity:**
- **Critical/High/Medium:** Fix immediately → re-run all 3 reviewers → repeat until resolved
- **Low:** Add `// TODO(review): [Issue] - [reviewer] on [date]`
- **Cosmetic:** Add `// FIXME(nitpick): [Issue] - [reviewer] on [date]`
- **Push back:** If wrong, provide reasoning/evidence. Security requires extra scrutiny.

## Integration with Workflows

| Workflow | When to Review | Notes |
|----------|----------------|-------|
| **Subagent-Driven Development** | After EACH task (all 3 parallel) | Fix Critical/High/Medium before next task |
| **Executing Plans** | After each batch (3 tasks) | Handle severity fixes before next batch |
| **Ad-Hoc Development** | Before merge (all 3 parallel) | Single reviewer OK if domain-specific |

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

**After fixing Critical/High/Medium:** Re-run all 3 in parallel (~3-5 min total). Don't cherry-pick reviewers.
**After adding TODO/FIXME:** Commit noting review completion. No re-run needed.
