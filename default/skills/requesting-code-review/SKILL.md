---
name: requesting-code-review
description: |
  Gate 4 of development cycle - dispatches 3 specialized reviewers (code, business-logic,
  security) in parallel for comprehensive code review feedback.

trigger: |
  - Gate 4 of development cycle
  - After completing major feature implementation
  - Before merge to main branch
  - After fixing complex bug

NOT_skip_when: |
  - "Code is simple" → Simple code can have security issues. Review required.
  - "Just refactoring" → Refactoring may expose vulnerabilities. Review required.
  - "Already reviewed similar code" → Each change needs fresh review.

sequence:
  after: [dev-testing]
  before: [dev-validation]

related:
  complementary: [dev-cycle, dev-implementation, dev-testing]

input_schema:
  required:
    - name: unit_id
      type: string
      description: "Task or subtask identifier"
    - name: base_sha
      type: string
      description: "Git SHA before implementation (for diff)"
    - name: head_sha
      type: string
      description: "Git SHA after implementation (current)"
    - name: implementation_summary
      type: string
      description: "Summary of what was implemented"
    - name: requirements
      type: string
      description: "Requirements or acceptance criteria"
  optional:
    - name: implementation_files
      type: array
      items: string
      description: "List of files changed"
    - name: gate0_handoff
      type: object
      description: "Full handoff from Gate 0"
    - name: skip_reviewers
      type: array
      items: string
      enum: [code-reviewer, business-logic-reviewer, security-reviewer]
      description: "Reviewers to skip (use sparingly)"

output_schema:
  format: markdown
  required_sections:
    - name: "Review Summary"
      pattern: "^## Review Summary"
      required: true
    - name: "Issues by Severity"
      pattern: "^## Issues by Severity"
      required: true
    - name: "Reviewer Verdicts"
      pattern: "^## Reviewer Verdicts"
      required: true
    - name: "Handoff to Next Gate"
      pattern: "^## Handoff to Next Gate"
      required: true
  metrics:
    - name: result
      type: enum
      values: [PASS, FAIL, NEEDS_FIXES]
    - name: reviewers_passed
      type: string
      description: "X/3 format"
    - name: issues_critical
      type: integer
    - name: issues_high
      type: integer
    - name: issues_medium
      type: integer
    - name: issues_low
      type: integer
    - name: iterations
      type: integer

examples:
  - name: "Feature review"
    input:
      unit_id: "task-001"
      base_sha: "abc123"
      head_sha: "def456"
      implementation_summary: "Added user authentication with JWT"
      requirements: "AC-1: User can login, AC-2: Invalid password returns error"
    expected_output: |
      ## Review Summary
      **Status:** PASS
      **Reviewers:** 3/3 PASS
      
      ## Issues by Severity
      | Severity | Count |
      |----------|-------|
      | Critical | 0 |
      | High | 0 |
      | Medium | 0 |
      | Low | 2 |
      
      ## Reviewer Verdicts
      | Reviewer | Verdict |
      |----------|---------|
      | code-reviewer | ✅ PASS |
      | business-logic-reviewer | ✅ PASS |
      | security-reviewer | ✅ PASS |
      
      ## Handoff to Next Gate
      - Ready for Gate 5: YES
---

# Code Review (Gate 4)

## Overview

Dispatch all three reviewer subagents in **parallel** for fast, comprehensive feedback:

1. **code-reviewer** - Architecture, design patterns, code quality
2. **business-logic-reviewer** - Domain correctness, business rules, edge cases
3. **security-reviewer** - Vulnerabilities, authentication, OWASP risks

**Core principle:** All 3 reviewers run simultaneously in a single message with 3 Task tool calls.

## CRITICAL: Role Clarification

**This skill ORCHESTRATES. Reviewer Agents REVIEW.**

| Who | Responsibility |
|-----|----------------|
| **This Skill** | Dispatch reviewers, aggregate findings, track iterations |
| **Reviewer Agents** | Analyze code, report issues with severity |
| **Implementation Agent** | Fix issues found by reviewers |

---

## Step 1: Validate Input

```text
REQUIRED INPUT (from dev-cycle orchestrator):
- unit_id: [task/subtask being reviewed]
- base_sha: [git SHA before implementation]
- head_sha: [git SHA after implementation]
- implementation_summary: [what was implemented]
- requirements: [acceptance criteria]

OPTIONAL INPUT:
- implementation_files: [list of changed files]
- gate0_handoff: [full Gate 0 output]
- skip_reviewers: [reviewers to skip - use sparingly]

IF any REQUIRED input is missing:
  → STOP and report: "Missing required input: [field]"
  → Return to orchestrator with error
```

## Step 2: Initialize Review State

```text
review_state = {
  unit_id: [from input],
  base_sha: [from input],
  head_sha: [from input],
  reviewers: {
    code_reviewer: {verdict: null, issues: []},
    business_logic_reviewer: {verdict: null, issues: []},
    security_reviewer: {verdict: null, issues: []}
  },
  aggregated_issues: {
    critical: [],
    high: [],
    medium: [],
    low: [],
    cosmetic: []
  },
  iterations: 0,
  max_iterations: 3
}
```

## Step 3: Dispatch All 3 Reviewers in Parallel

**⛔ CRITICAL: All 3 reviewers MUST be dispatched in a SINGLE message with 3 Task calls.**

```yaml
# Task 1: Code Reviewer
Task:
  subagent_type: "code-reviewer"
  model: "opus"
  description: "Code review for [unit_id]"
  prompt: |
    ## Code Review Request
    
    **Unit ID:** [unit_id]
    **Base SHA:** [base_sha]
    **Head SHA:** [head_sha]
    
    ## What Was Implemented
    [implementation_summary]
    
    ## Requirements
    [requirements]
    
    ## Files Changed
    [implementation_files or "Use git diff"]
    
    ## Your Focus
    - Architecture and design patterns
    - Code quality and maintainability
    - Naming conventions
    - Error handling patterns
    - Performance concerns
    
    ## Required Output
    ### VERDICT: PASS / FAIL
    
    ### Issues Found
    | Severity | Description | File:Line | Recommendation |
    |----------|-------------|-----------|----------------|
    | [CRITICAL/HIGH/MEDIUM/LOW/COSMETIC] | [issue] | [location] | [fix] |
    
    ### What Was Done Well
    [positive observations]

# Task 2: Business Logic Reviewer
Task:
  subagent_type: "business-logic-reviewer"
  model: "opus"
  description: "Business logic review for [unit_id]"
  prompt: |
    ## Business Logic Review Request
    
    **Unit ID:** [unit_id]
    **Base SHA:** [base_sha]
    **Head SHA:** [head_sha]
    
    ## What Was Implemented
    [implementation_summary]
    
    ## Requirements
    [requirements]
    
    ## Your Focus
    - Domain correctness
    - Business rules implementation
    - Edge cases handling
    - Requirements coverage
    - Data validation
    
    ## Required Output
    ### VERDICT: PASS / FAIL
    
    ### Issues Found
    | Severity | Description | File:Line | Recommendation |
    |----------|-------------|-----------|----------------|
    | [CRITICAL/HIGH/MEDIUM/LOW/COSMETIC] | [issue] | [location] | [fix] |
    
    ### Requirements Traceability
    | Requirement | Status | Evidence |
    |-------------|--------|----------|
    | [req] | ✅/❌ | [file:line] |

# Task 3: Security Reviewer
Task:
  subagent_type: "security-reviewer"
  model: "opus"
  description: "Security review for [unit_id]"
  prompt: |
    ## Security Review Request
    
    **Unit ID:** [unit_id]
    **Base SHA:** [base_sha]
    **Head SHA:** [head_sha]
    
    ## What Was Implemented
    [implementation_summary]
    
    ## Requirements
    [requirements]
    
    ## Your Focus
    - Authentication and authorization
    - Input validation
    - SQL injection, XSS, CSRF
    - Sensitive data handling
    - OWASP Top 10 risks
    
    ## Required Output
    ### VERDICT: PASS / FAIL
    
    ### Issues Found
    | Severity | Description | File:Line | OWASP Category | Recommendation |
    |----------|-------------|-----------|----------------|----------------|
    | [CRITICAL/HIGH/MEDIUM/LOW] | [issue] | [location] | [A01-A10] | [fix] |
    
    ### Security Checklist
    | Check | Status |
    |-------|--------|
    | Input validation | ✅/❌ |
    | Auth checks | ✅/❌ |
    | No hardcoded secrets | ✅/❌ |
```

## Step 4: Wait for All Reviewers and Parse Output

```text
Wait for all 3 Task calls to complete.

For each reviewer:
1. Extract VERDICT (PASS/FAIL)
2. Extract Issues Found table
3. Categorize issues by severity

review_state.reviewers.code_reviewer = {
  verdict: [PASS/FAIL],
  issues: [parsed issues]
}
// ... same for other reviewers

Aggregate all issues by severity:
review_state.aggregated_issues.critical = [all critical from all reviewers]
review_state.aggregated_issues.high = [all high from all reviewers]
// ... etc
```

## Step 5: Handle Results by Severity

```text
Count blocking issues:
blocking_count = critical.length + high.length + medium.length

IF blocking_count == 0:
  → All reviewers PASS
  → Proceed to Step 8 (Success)

IF blocking_count > 0:
  → review_state.iterations += 1
  → IF iterations >= max_iterations: Go to Step 9 (Escalate)
  → Go to Step 6 (Dispatch Fixes)
```

## Step 6: Dispatch Fixes to Implementation Agent

```yaml
Task:
  subagent_type: "[implementation_agent from Gate 0]"
  model: "opus"
  description: "Fix review issues for [unit_id]"
  prompt: |
    ⛔ FIX REQUIRED - Code Review Issues Found

    ## Context
    - **Unit ID:** [unit_id]
    - **Iteration:** [iterations] of [max_iterations]

    ## Critical Issues (MUST FIX)
    [list critical issues with file:line and recommendation]

    ## High Issues (MUST FIX)
    [list high issues]

    ## Medium Issues (MUST FIX)
    [list medium issues]

    ## Requirements
    1. Fix ALL Critical, High, and Medium issues
    2. Commit fixes
    3. Return list of fixed issues with evidence

    ## For Low/Cosmetic Issues
    Add TODO/FIXME comments:
    - Low: `// TODO(review): [Issue] - [reviewer] on [date]`
    - Cosmetic: `// FIXME(nitpick): [Issue] - [reviewer] on [date]`
```

## Step 7: Re-Run All Reviewers After Fixes

```text
After fixes committed:
1. Get new HEAD_SHA
2. Go back to Step 3 (dispatch all 3 reviewers again)

⛔ CRITICAL: Always re-run ALL 3 reviewers after fixes.
Do NOT cherry-pick reviewers.
```

## Step 8: Prepare Success Output

```text
Generate skill output:

## Review Summary
**Status:** PASS
**Unit ID:** [unit_id]
**Iterations:** [review_state.iterations]

## Issues by Severity
| Severity | Count |
|----------|-------|
| Critical | 0 |
| High | 0 |
| Medium | 0 |
| Low | [count] |
| Cosmetic | [count] |

## Reviewer Verdicts
| Reviewer | Verdict | Issues |
|----------|---------|--------|
| code-reviewer | ✅ PASS | [count] |
| business-logic-reviewer | ✅ PASS | [count] |
| security-reviewer | ✅ PASS | [count] |

## Low/Cosmetic Issues (TODO/FIXME added)
[list with file locations]

## Handoff to Next Gate
- Review status: COMPLETE
- All blocking issues: RESOLVED
- Reviewers passed: 3/3
- Ready for Gate 5 (Validation): YES
```

## Step 9: Escalate - Max Iterations Reached

```text
Generate skill output:

## Review Summary
**Status:** FAIL
**Unit ID:** [unit_id]
**Iterations:** [max_iterations] (MAX REACHED)

## Issues by Severity
| Severity | Count |
|----------|-------|
| Critical | [count] |
| High | [count] |
| Medium | [count] |

## Unresolved Issues
[list all Critical/High/Medium still open]

## Reviewer Verdicts
| Reviewer | Verdict |
|----------|---------|
| code-reviewer | [PASS/FAIL] |
| business-logic-reviewer | [PASS/FAIL] |
| security-reviewer | [PASS/FAIL] |

## Handoff to Next Gate
- Review status: FAILED
- Unresolved blocking issues: [count]
- Ready for Gate 5: NO
- **Action Required:** User must manually resolve issues

⛔ ESCALATION: Max iterations (3) reached. Blocking issues remain.
```

---

## Pressure Resistance

See [dev-team/skills/shared-patterns/shared-pressure-resistance.md](../../dev-team/skills/shared-patterns/shared-pressure-resistance.md) for universal pressure scenarios.

| User Says | Your Response |
|-----------|---------------|
| "Skip review, code is simple" | "Simple code can have security issues. Dispatching all 3 reviewers." |
| "Just run code-reviewer" | "All 3 reviewers run in parallel. No time saved by skipping." |
| "Fix later, merge now" | "Blocking issues (Critical/High/Medium) MUST be fixed before Gate 5." |

## Anti-Rationalization Table

See [dev-team/skills/shared-patterns/shared-anti-rationalization.md](../../dev-team/skills/shared-patterns/shared-anti-rationalization.md) for universal anti-rationalizations.

### Gate 4-Specific Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Run reviewers one at a time" | Sequential = slow. Parallel = 3x faster. | **Dispatch all 3 in single message** |
| "Skip security for internal code" | Internal code can have vulnerabilities. | **Include security-reviewer** |
| "Critical issue is false positive" | Prove it with evidence, don't assume. | **Fix or provide evidence** |
| "Low issues don't need TODO" | TODOs ensure issues aren't forgotten. | **Add TODO comments** |
| "2 of 3 reviewers passed" | Gate 4 requires ALL 3. 2/3 = 0/3. | **Re-run ALL 3 reviewers** |
| "MEDIUM is not blocking" | MEDIUM = MUST FIX. Same as CRITICAL/HIGH. | **Fix MEDIUM issues NOW** |

---

## Execution Report Format

```markdown
## Review Summary
**Status:** [PASS|FAIL|NEEDS_FIXES]
**Unit ID:** [unit_id]
**Duration:** [Xm Ys]
**Iterations:** [N]

## Issues by Severity
| Severity | Count |
|----------|-------|
| Critical | [N] |
| High | [N] |
| Medium | [N] |
| Low | [N] |

## Reviewer Verdicts
| Reviewer | Verdict |
|----------|---------|
| code-reviewer | ✅/❌ |
| business-logic-reviewer | ✅/❌ |
| security-reviewer | ✅/❌ |

## Handoff to Next Gate
- Review status: [COMPLETE|FAILED]
- Blocking issues: [resolved|N remaining]
- Ready for Gate 5: [YES|NO]
```
