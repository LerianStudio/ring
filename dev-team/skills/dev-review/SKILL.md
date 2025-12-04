---
name: dev-review
description: |
  Development cycle review gate (Gate 3) - executes parallel code review with 3 specialized
  reviewers, aggregates findings, and determines VERDICT for gate passage.

trigger: |
  - After testing gate complete (Gate 2)
  - Implementation ready for review
  - Before validation gate

skip_when: |
  - Tests not passing -> complete Gate 2 first
  - Already reviewed with no changes since -> proceed to validation
  - Trivial change (<20 lines, no logic) -> document skip reason

sequence:
  after: [dev-testing]
  before: [dev-validation]

related:
  complementary: [ring-default:requesting-code-review, ring-default:receiving-code-review]
---

# Dev Review (Gate 3)

## Overview

Execute comprehensive code review using 3 specialized reviewers IN PARALLEL. Aggregate findings and determine VERDICT for gate passage.

**Core principle:** Three perspectives catch more bugs than one. Parallel execution = 3x faster feedback.

## Prerequisites

Before starting this gate:
- All tests pass (Gate 2 complete)
- Implementation is feature-complete
- Code is committed (or ready to diff)

## Reviewer Specializations

| Reviewer | Focus Area | Catches |
|----------|------------|---------|
| `ring-default:code-reviewer` | Architecture, patterns, maintainability | Design flaws, code smells, DRY violations |
| `ring-default:business-logic-reviewer` | Correctness, requirements, edge cases | Logic errors, missing cases, requirement gaps |
| `ring-default:security-reviewer` | OWASP, auth, input validation | Vulnerabilities, injection risks, auth bypasses |

## Step 1: Prepare Review Context

Gather information for reviewers:

```bash
# Get commit range
BASE_SHA=$(git merge-base HEAD main)  # or origin/main
HEAD_SHA=$(git rev-parse HEAD)

# Get changed files
git diff --name-only $BASE_SHA $HEAD_SHA

# Get diff statistics
git diff --stat $BASE_SHA $HEAD_SHA
```

Prepare review prompt context:

```markdown
WHAT_WAS_IMPLEMENTED: [Feature/fix description]
PLAN_OR_REQUIREMENTS: [Link to task/PRD/TRD]
ACCEPTANCE_CRITERIA:
- AC-1: [criterion]
- AC-2: [criterion]
BASE_SHA: [starting commit]
HEAD_SHA: [current commit]
FILES_CHANGED: [list of modified files]
```

## Step 2: Dispatch All 3 Reviewers IN PARALLEL

**CRITICAL: Launch all 3 reviewers in a SINGLE message with 3 Task tool calls.**

```
# Single message with 3 parallel Task calls:

Task tool #1:
  subagent_type: "ring-default:code-reviewer"
  model: "opus"
  description: "Review code quality and architecture"
  prompt: |
    WHAT_WAS_IMPLEMENTED: [description]
    PLAN_OR_REQUIREMENTS: [reference]
    ACCEPTANCE_CRITERIA:
    - AC-1: [criterion]
    BASE_SHA: [sha]
    HEAD_SHA: [sha]

Task tool #2:
  subagent_type: "ring-default:business-logic-reviewer"
  model: "opus"
  description: "Review business logic correctness"
  prompt: |
    [Same context as above]

Task tool #3:
  subagent_type: "ring-default:security-reviewer"
  model: "opus"
  description: "Review security vulnerabilities"
  prompt: |
    [Same context as above]
```

**Wait for ALL three reviewers to complete before proceeding.**

## Step 3: Collect Individual Findings

Each reviewer returns a report with sections:
- VERDICT (PASS/FAIL/NEEDS_DISCUSSION)
- Summary
- Issues Found (by severity)
- What Was Done Well
- Next Steps

Extract findings from each:

```markdown
## Code Reviewer Findings
- VERDICT: [PASS/FAIL/NEEDS_DISCUSSION]
- Critical: [list]
- High: [list]
- Medium: [list]
- Low: [list]

## Business Logic Reviewer Findings
- VERDICT: [PASS/FAIL/NEEDS_DISCUSSION]
- Critical: [list]
- High: [list]
- Medium: [list]
- Low: [list]

## Security Reviewer Findings
- VERDICT: [PASS/FAIL/NEEDS_DISCUSSION]
- Critical: [list]
- High: [list]
- Medium: [list]
- Low: [list]
```

## Step 4: Aggregate Findings

Combine all findings by severity:

```markdown
## Aggregated Review Findings

### Critical Issues (Block release)
1. [Issue from reviewer X] - Source: code-reviewer
2. [Issue from reviewer Y] - Source: security-reviewer

### High Issues (Must fix before merge)
1. [Issue] - Source: business-logic-reviewer
2. [Issue] - Source: code-reviewer

### Medium Issues (Should fix)
1. [Issue] - Source: security-reviewer

### Low Issues (Track as TODO)
1. [Issue] - Source: code-reviewer
```

## Step 5: Determine VERDICT

Apply VERDICT rules:

| Condition | VERDICT | Action |
|-----------|---------|--------|
| All 3 reviewers PASS, no Critical/High | **PASS** | Proceed to Gate 4 |
| Any Critical finding | **FAIL** | Return to Gate 0 |
| 2+ High findings | **FAIL** | Return to Gate 0 |
| 1 High finding | **NEEDS_DISCUSSION** | Evaluate with stakeholder |
| Only Medium/Low findings | **PASS** | Track issues, proceed |

**VERDICT Decision Tree:**

```
Any Critical issue?
├── Yes -> VERDICT: FAIL
└── No -> Count High issues
          ├── >= 2 -> VERDICT: FAIL
          ├── == 1 -> VERDICT: NEEDS_DISCUSSION
          └── == 0 -> VERDICT: PASS
```

## Step 6: Handle VERDICT

### VERDICT: PASS

1. Document review completion
2. Add TODO comments for Low issues:
   ```javascript
   // TODO(review): [Issue description]
   // Reported by: [reviewer] on [date]
   ```
3. Add FIXME comments for Medium issues:
   ```javascript
   // FIXME(review): [Issue description]
   // Reported by: [reviewer] on [date]
   ```
4. Proceed to Gate 4 (Validation)

### VERDICT: FAIL

1. Document all Critical and High findings
2. Create fix tasks:
   ```markdown
   ## Required Fixes Before Re-Review

   1. [Critical] [Description] - File: X, Line: Y
   2. [High] [Description] - File: X, Line: Y
   ```
3. Return to Gate 0 (Implementation) with findings
4. After fixes, re-run ALL 3 reviewers (full parallel review)
5. Do NOT cherry-pick which reviewers to re-run

### VERDICT: NEEDS_DISCUSSION

1. Document the High finding requiring discussion
2. Present options to stakeholder:
   ```markdown
   ## Review Finding Requires Decision

   **Finding:** [Description]
   **Reviewer:** [which reviewer]
   **Risk if not addressed:** [impact]
   **Effort to fix:** [estimate]

   Options:
   A. Fix now (delay: X hours)
   B. Accept risk, track as tech debt
   C. Partial fix with TODO
   ```
3. Wait for decision before proceeding

## Step 7: Document Review Outcome

Create review summary:

```markdown
## Code Review Summary - [Task ID]

**Date:** YYYY-MM-DD
**Reviewers:** code-reviewer, business-logic-reviewer, security-reviewer
**VERDICT:** [PASS/FAIL/NEEDS_DISCUSSION]

### Individual Verdicts
- Code Reviewer: [PASS/FAIL]
- Business Logic Reviewer: [PASS/FAIL]
- Security Reviewer: [PASS/FAIL]

### Findings Summary
- Critical: X issues
- High: Y issues
- Medium: Z issues
- Low: W issues

### Actions Taken
- [List of fixes applied]
- [TODOs added for tracking]

### Next Steps
- [Proceed to validation / Return to implementation / Await decision]
```

## Re-Review Protocol

After fixing Critical/High issues:

1. **Always re-run ALL 3 reviewers** (not just the one that found the issue)
2. Fixes may introduce new issues in other domains
3. Parallel execution makes full re-review fast (~3-5 minutes)
4. Update aggregated findings
5. Re-determine VERDICT

**Maximum iterations:** 3 review cycles

If still FAIL after 3 iterations:
- Stop automated process
- Request human intervention
- Document recurring issues
- Consider architectural changes

## Anti-Patterns

**Never:**
- Run reviewers sequentially (wastes time)
- Skip a reviewer because "domain doesn't apply"
- Proceed with Critical/High issues unfixed
- Cherry-pick which reviewers to re-run
- Argue with valid feedback without evidence
- Mark Low issues as "won't fix" without tracking

**Always:**
- Launch all 3 reviewers in single message
- Wait for all to complete before aggregating
- Fix Critical/High immediately
- Track Medium/Low with comments
- Re-run full review after fixes
- Document reviewer disagreements

## Execution Report

| Metric | Value |
|--------|-------|
| Duration | Xm Ys |
| Review Iterations | N |
| Reviewers | 3 (parallel) |
| Findings | X Critical, Y High, Z Medium, W Low |
| Fixes Applied | N |
| VERDICT | PASS/FAIL/NEEDS_DISCUSSION |
| Result | Gate passed / Returned to Gate 0 / Awaiting decision |

## Pushing Back on Reviewers

When reviewer feedback is incorrect:

1. Provide technical evidence (code, tests, docs)
2. Explain why current implementation is correct
3. Reference requirements or architectural decisions
4. Request clarification for ambiguous feedback
5. Security concerns require extra scrutiny before dismissing

**Example pushback:**
```markdown
**Reviewer:** "This allows SQL injection"
**Response:** "Using parameterized query on line 45:
`db.Query("SELECT * FROM users WHERE id = $1", userID)`
This is safe. See test in auth_test.go:78 verifying injection attempts fail."
```
