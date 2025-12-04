---
name: dev-feedback-loop
description: |
  Development cycle feedback system - calculates assertiveness scores, aggregates cycle
  metrics, performs root cause analysis on failures, and generates improvement reports.

trigger: |
  - After task completion (any gate outcome)
  - After validation approval or rejection
  - At end of development cycle
  - When assertiveness drops below threshold

skip_when: |
  - Task still in progress -> wait for completion
  - Feedback already recorded for this task -> proceed
  - Exploratory/spike work (no metrics tracked)

sequence:
  after: [ring-dev-team:dev-validation]

related:
  complementary: [ring-default:root-cause-tracing, ring-default:codify-solution]
---

# Dev Feedback Loop

## Overview

Continuous improvement system that tracks development cycle effectiveness through assertiveness scores, identifies recurring failure patterns, and generates actionable improvement suggestions.

**Core principle:** What gets measured gets improved. Track every gate transition to identify systemic issues.

## Assertiveness Score Calculation

Base score of 100 points, with deductions for inefficiencies:

### Penalty Matrix

| Event | Penalty | Max Penalty | Rationale |
|-------|---------|-------------|-----------|
| Extra iteration (beyond 1) | -10 per iteration | -30 | Each iteration = rework |
| Review FAIL verdict | -20 | -20 | Critical/High issues found |
| Review NEEDS_DISCUSSION | -10 | -10 | Uncertainty in implementation |
| Unmet criterion at validation | -10 per criterion | -40 | Requirements gap |
| User REJECTED validation | -100 (score = 0) | -100 | Complete failure |

### Score Calculation Formula

```
assertiveness_score = 100
                    - min(30, (extra_iterations * 10))
                    - (review_fail * 20)
                    - (needs_discussion * 10)
                    - min(40, (unmet_criteria * 10))

if user_rejected:
    assertiveness_score = 0
```

### Score Interpretation

| Score Range | Rating | Action Required |
|-------------|--------|-----------------|
| 90-100 | Excellent | No action needed |
| 80-89 | Good | Minor improvements possible |
| 70-79 | Acceptable | Review patterns, optimize |
| 60-69 | Needs Improvement | Root cause analysis required |
| < 60 | Poor | Mandatory deep analysis |
| 0 | Failed | Full post-mortem required |

## Step 1: Collect Cycle Metrics

After task completion, gather all gate data:

```markdown
## Cycle Metrics - [TASK-ID]

### Gate Transitions
| Gate | Iterations | Duration | Outcome |
|------|------------|----------|---------|
| Gate 0: Implementation | 1 | 2h 30m | PASS |
| Gate 1: DevOps | 1 | 30m | PASS |
| Gate 2: SRE | 1 | 25m | PASS |
| Gate 3: Testing | 2 | 1h 15m | PASS (coverage gap) |
| Gate 4: Review | 1 | 20m | PASS |
| Gate 5: Validation | 1 | 10m | APPROVED |

### Review Findings
- Code reviewer: PASS (2 Low issues)
- Business logic reviewer: PASS (1 Medium issue)
- Security reviewer: PASS (0 issues)
- Aggregate VERDICT: PASS

### Validation Outcome
- Criteria: 4/4 verified
- Decision: APPROVED
- Notes: None
```

## Step 2: Calculate Assertiveness Score

Apply formula with collected metrics:

```markdown
## Assertiveness Calculation - [TASK-ID]

Base Score: 100

Deductions:
- Extra iterations: 2 (Gate 1 + Gate 2) = -20
- Review FAIL: 0 = -0
- NEEDS_DISCUSSION: 0 = -0
- Unmet criteria: 0 = -0
- User REJECTED: No = -0

**Final Score: 80 / 100**

Rating: Good
```

## Step 3: Threshold Alerts

### Task Score < 70

**Trigger:** Individual task assertiveness below 70

**Action:** Mandatory root cause analysis

```markdown
## Root Cause Analysis - [TASK-ID]

**Score:** 65/100 (Needs Improvement)

### Failure Events
1. Gate 3 required 3 iterations (extra_iterations = 2)
2. Review returned FAIL on first pass
3. 1 criterion unmet at validation

### Root Cause Investigation

#### Why did Gate 3 require 3 iterations?
- Iteration 1: Initial implementation incomplete
- Iteration 2: Edge case handling missing
- Iteration 3: Performance optimization needed
- **Root cause:** Requirements unclear on edge cases

#### Why did review FAIL?
- Critical finding: SQL injection vulnerability
- **Root cause:** Security patterns not applied

#### Why was criterion unmet?
- AC-3: "Response under 200ms" not achieved (actual: 350ms)
- **Root cause:** N+1 query not detected during implementation

### Corrective Actions
1. Add edge case checklist to Gate 0 (implementation)
2. Add security checklist to Gate 0 (implementation)
3. Add performance test to Gate 2 before validation

### Prevention Measures
1. Update implementation skill with security reminders
2. Add performance gate before review
3. Clarify requirements process
```

### Gate Iterations > 3

**Trigger:** Any gate exceeds 3 iterations

**Action:** Stop execution, request human intervention

```markdown
## GATE BLOCKED - Human Intervention Required

**Task:** [TASK-ID]
**Gate:** Gate 4 (Review)
**Iterations:** 4 (exceeds limit of 3)

### Iteration History
1. Initial review: FAIL (2 Critical, 3 High)
2. After fixes: FAIL (1 Critical, 2 High)
3. After fixes: FAIL (1 Critical, 1 High)
4. After fixes: FAIL (1 Critical)

### Recurring Issue
- Same Critical finding persists: "Authentication bypass possible"
- Fix attempts not addressing root cause

### Recommended Actions
1. Pair programming session on auth implementation
2. Architecture review of authentication flow
3. Consider alternative approach

### BLOCKED UNTIL
Human decision on how to proceed:
[ ] Continue with guidance
[ ] Reassign to different approach
[ ] Descope feature
[ ] Cancel task
```

### Cycle Average < 80

**Trigger:** Average assertiveness across recent tasks below 80

**Action:** Generate deep analysis report

```markdown
## Deep Analysis Report - Development Cycle Health

**Period:** [Date range]
**Tasks Analyzed:** 15
**Average Assertiveness:** 73.2

### Score Distribution
- Excellent (90-100): 2 tasks (13%)
- Good (80-89): 4 tasks (27%)
- Acceptable (70-79): 5 tasks (33%)
- Needs Improvement (60-69): 3 tasks (20%)
- Poor (<60): 1 task (7%)

### Common Failure Patterns

#### Pattern 1: Review Failures (40% of low scores)
- Frequency: 6/15 tasks had review FAIL
- Common finding: Security issues
- Root cause: Security checklist not followed
- Recommendation: Add mandatory security gate

#### Pattern 2: Extra Iterations in Testing (33% of low scores)
- Frequency: 5/15 tasks needed 2+ test iterations
- Common finding: Coverage gaps
- Root cause: TDD not strictly followed
- Recommendation: Enforce RED phase verification

#### Pattern 3: Validation Rejections (13% of low scores)
- Frequency: 2/15 tasks rejected at validation
- Common finding: Misunderstood requirements
- Root cause: Ambiguous acceptance criteria
- Recommendation: Require criterion clarification in Gate 1

### Improvement Plan

| Priority | Action | Owner | Target |
|----------|--------|-------|--------|
| High | Add security gate between impl and test | Team | Week 1 |
| High | Enforce TDD RED phase logging | Process | Week 1 |
| Medium | Criterion clarification template | PM | Week 2 |
| Low | Pair programming for security tasks | Team | Ongoing |

### Success Metrics
- Target average assertiveness: 85+
- Target review FAIL rate: <20%
- Target validation rejection: <10%
```

## Step 4: Write Feedback Report

Save report to standardized location:

```bash
# Create feedback directory if needed
mkdir -p .ring/dev-team/feedback

# Write report
cat > .ring/dev-team/feedback/cycle-YYYY-MM-DD.md << 'EOF'
[Report content]
EOF
```

Report format:

```markdown
# Development Cycle Feedback Report

**Date:** YYYY-MM-DD
**Tasks Completed:** X
**Average Assertiveness:** XX.X%

## Task Summary

| Task ID | Score | Rating | Key Issue |
|---------|-------|--------|-----------|
| TASK-001 | 95 | Excellent | - |
| TASK-002 | 80 | Good | Extra iteration in testing |
| TASK-003 | 65 | Needs Improvement | Review FAIL + 2 unmet criteria |

## Aggregate Metrics

### By Gate
| Gate | Avg Iterations | Avg Duration | Pass Rate |
|------|----------------|--------------|-----------|
| Gate 0: Implementation | 1.2 | 2h | 100% |
| Gate 1: DevOps | 1.1 | 30m | 100% |
| Gate 2: SRE | 1.1 | 25m | 100% |
| Gate 3: Testing | 1.5 | 1h | 95% |
| Gate 4: Review | 1.4 | 25m | 85% |
| Gate 5: Validation | 1.1 | 15m | 90% |

### By Penalty Type
| Penalty | Occurrences | Total Points Lost |
|---------|-------------|-------------------|
| Extra iterations | 8 | 80 |
| Review FAIL | 3 | 60 |
| NEEDS_DISCUSSION | 2 | 20 |
| Unmet criteria | 4 | 40 |
| User REJECTED | 0 | 0 |

## Patterns Identified

### Positive Patterns
1. DevOps gate (Gate 1) consistently single-iteration
2. Implementation quality improving (fewer review issues)

### Negative Patterns
1. Testing gate averaging 1.5 iterations (target: 1.0)
2. Review FAIL rate at 15% (target: <10%)

## Recommendations

### Immediate (This Sprint)
1. Add TDD compliance check before testing gate
2. Review security checklist with team

### Short-term (This Month)
1. Implement performance pre-check
2. Clarify acceptance criteria template

### Long-term (This Quarter)
1. Automate assertiveness tracking dashboard
2. Integrate feedback into retrospectives

## Next Review
- Date: YYYY-MM-DD (next cycle end)
- Target assertiveness: 85%
- Focus areas: Testing iterations, Review pass rate
```

## Step 5: Generate Improvement Suggestions

Based on patterns, generate specific improvements:

### For Agents

```markdown
## Agent Improvement Suggestions

### ring-dev-team:backend-engineer-*
- Issue: Security findings in 40% of reviews
- Suggestion: Add security checklist section to agent prompt
- Specific addition: OWASP Top 10 verification before completion

### ring-dev-team:qa-analyst
- Issue: Coverage gaps causing test iterations
- Suggestion: Add coverage threshold check to test completion
- Specific addition: Fail if coverage < 80% before gate exit
```

### For Skills

```markdown
## Skill Improvement Suggestions

### ring-dev-team:dev-testing
- Issue: TDD RED phase often skipped
- Suggestion: Add mandatory failure output capture
- Specific change: Require paste of test failure before GREEN phase

### ring-dev-team:dev-review
- Issue: Same security issues recurring
- Suggestion: Add pre-review security checklist
- Specific change: Gate entry requires security self-check
```

### For Process

```markdown
## Process Improvement Suggestions

### Planning Gate
- Issue: Ambiguous acceptance criteria causing validation rejections
- Suggestion: Require testable criterion format
- Template: "Given [context], when [action], then [outcome]"

### Review Gate
- Issue: Multiple iterations for same issue type
- Suggestion: Add issue-type-specific checklists
- Implementation: Security, performance, logic checklists
```

## Execution Report

| Metric | Value |
|--------|-------|
| Tasks Analyzed | N |
| Average Assertiveness | XX.X% |
| Threshold Alerts | X |
| Root Cause Analyses | Y |
| Improvement Suggestions | Z |
| Report Location | .ring/dev-team/feedback/cycle-YYYY-MM-DD.md |

## Anti-Patterns

**Never:**
- Skip feedback collection for "simple" tasks
- Ignore threshold alerts
- Accept low scores without analysis
- Generate suggestions without data
- Blame individuals instead of process

**Always:**
- Track every gate transition
- Calculate score for every task
- Investigate scores < 70
- Document root causes
- Generate actionable improvements
- Review trends over time

## Feedback Loop Integration

### With Retrospectives

Include feedback report in sprint retrospectives:
- Share aggregate metrics
- Discuss pattern trends
- Prioritize improvements
- Assign action items

### With Skill Updates

When patterns indicate skill gaps:
1. Document specific improvement
2. Update skill with new guidance
3. Track if pattern improves
4. Iterate on skill content

### With Agent Updates

When patterns indicate agent gaps:
1. Identify specific agent behavior
2. Update agent prompt/instructions
3. Track performance change
4. Validate improvement
