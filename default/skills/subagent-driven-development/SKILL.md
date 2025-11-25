---
name: subagent-driven-development
description: Use when executing implementation plans with independent tasks in the current session - dispatches fresh subagent for each task with comprehensive code review (code-reviewer, security-reviewer, business-logic-reviewer) between tasks, enabling fast iteration with quality gates
when_to_use: Use when executing implementation plans with independent tasks in the current session - dispatches fresh subagent for each task with comprehensive code review (code-reviewer, security-reviewer, business-logic-reviewer) between tasks, enabling fast iteration with quality gates
---

# Subagent-Driven Development

Execute plan by dispatching fresh subagent per task, with code review after each.

**Core principle:** Fresh subagent per task + review between tasks = high quality, fast iteration

## Overview

**vs. Executing Plans (parallel session):**
- Same session (no context switch)
- Fresh subagent per task (no context pollution)
- Code review after each task (catch issues early)
- Faster iteration (no human-in-loop between tasks)

**When to use:**
- Staying in this session
- Tasks are mostly independent
- Want continuous progress with quality gates

**When NOT to use:**
- Need to review plan first (use executing-plans)
- Tasks are tightly coupled (manual execution better)
- Plan needs revision (brainstorm first)

## The Process

### 1. Load Plan

Read plan file, create TodoWrite with all tasks.

### 2. Execute Task with Subagent

For each task:

**Dispatch fresh subagent:**
```
Task tool (general-purpose):
  description: "Implement Task N: [task name]"
  prompt: |
    You are implementing Task N from [plan-file].

    Read that task carefully. Your job is to:
    1. Implement exactly what the task specifies
    2. Write tests (following TDD if task says to)
    3. Verify implementation works
    4. Commit your work
    5. Report back

    Work from: [directory]

    Report: What you implemented, what you tested, test results, files changed, any issues
```

**Subagent reports back** with summary of work.

### 3. Review Subagent's Work (Parallel Execution)

**Dispatch all three reviewer subagents in parallel using a single message:**

**CRITICAL: Use one message with 3 Task tool calls to launch all reviewers simultaneously.**

```
# Single message with 3 parallel Task calls:

Task tool #1 (ring:code-reviewer):
  model: "opus"
  description: "Review code quality for Task N"
  prompt: |
    WHAT_WAS_IMPLEMENTED: [from subagent's report]
    PLAN_OR_REQUIREMENTS: Task N from [plan-file]
    BASE_SHA: [commit before task]
    HEAD_SHA: [current commit]
    DESCRIPTION: [task summary]

Task tool #2 (ring:business-logic-reviewer):
  model: "opus"
  description: "Review business logic for Task N"
  prompt: |
    [Same parameters as above]

Task tool #3 (ring:security-reviewer):
  model: "opus"
  description: "Review security for Task N"
  prompt: |
    [Same parameters as above]
```

**All three reviewers execute simultaneously. Wait for all to complete.**

**Each reviewer returns:** Strengths, Issues (Critical/High/Medium/Low/Cosmetic), Assessment (PASS/FAIL)

### 4. Aggregate and Handle Review Feedback

**After all three reviewers complete:**

**Step 1: Aggregate all issues by severity across all reviewers:**
- **Critical issues:** [List from code/business/security reviewers]
- **High issues:** [List from code/business/security reviewers]
- **Medium issues:** [List from code/business/security reviewers]
- **Low issues:** [List from code/business/security reviewers]
- **Cosmetic/Nitpick issues:** [List from code/business/security reviewers]

**Step 2: Handle by severity:**

**Critical/High/Medium → Fix immediately:**
```
Dispatch fix subagent:
"Fix the following issues from parallel code review:

Critical Issues:
- [Issue 1 from reviewer X] - file:line
- [Issue 2 from reviewer Y] - file:line

High Issues:
- [Issue 3 from reviewer Z] - file:line

Medium Issues:
- [Issue 4 from reviewer X] - file:line"
```

After fixes complete, **re-run all 3 reviewers in parallel** to verify fixes.
Repeat until no Critical/High/Medium issues remain.

**Low issues → Add TODO comments in code:**
```python
# TODO(review): Extract this validation logic into separate function
# Reported by: code-reviewer on 2025-11-06
# Severity: Low
def process_data(data):
    ...
```

**Cosmetic/Nitpick → Add FIXME comments in code:**
```python
# FIXME(nitpick): Consider more descriptive variable name than 'x'
# Reported by: code-reviewer on 2025-11-06
# Severity: Cosmetic
x = calculate_total()
```

Commit TODO/FIXME comments with fixes.

### 5. Mark Complete, Next Task

After all Critical/High/Medium issues resolved for current task:
- Mark task as completed in TodoWrite
- Commit all changes (including TODO/FIXME comments)
- Move to next task
- Repeat steps 2-5

### 6. Final Review (After All Tasks)

After all tasks complete, run parallel final validation across entire implementation:

**Dispatch all three reviewers in parallel for full implementation review:**

```
# Single message with 3 parallel Task calls:

Task tool #1 (ring:code-reviewer):
  model: "opus"
  description: "Final code review for complete implementation"
  prompt: |
    WHAT_WAS_IMPLEMENTED: All tasks from [plan]
    PLAN_OR_REQUIREMENTS: Complete plan from [plan-file]
    BASE_SHA: [start of development]
    HEAD_SHA: [current commit]
    DESCRIPTION: Full implementation review

Task tool #2 (ring:business-logic-reviewer):
  model: "opus"
  description: "Final business logic review"
  prompt: |
    [Same parameters as above]

Task tool #3 (ring:security-reviewer):
  model: "opus"
  description: "Final security review"
  prompt: |
    [Same parameters as above]
```

**Wait for all three final reviews to complete, then:**
- Aggregate findings by severity
- Fix any remaining Critical/High/Medium issues
- Add TODO/FIXME for Low/Cosmetic issues
- Re-run parallel review if fixes were needed

### 7. Complete Development

After final review passes:
- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED SUB-SKILL:** Use ring:finishing-a-development-branch
- Follow that skill to verify tests, present options, execute choice

## Example Workflow

```
You: I'm using Subagent-Driven Development to execute this plan.

[Load plan, create TodoWrite]

Task 1: Hook installation script

[Dispatch implementation subagent]
Subagent: Implemented install-hook with tests, 5/5 passing

[Parallel review - dispatch all 3 reviewers in single message]
Code reviewer: PASS. Strengths: Good test coverage. Issues: None.
Business reviewer: PASS. Strengths: Meets requirements. Issues: None.
Security reviewer: PASS. Strengths: No security concerns. Issues: None.

[All pass - mark Task 1 complete]

Task 2: User authentication endpoint

[Dispatch implementation subagent]
Subagent: Added auth endpoint with JWT, 8/8 tests passing

[Parallel review - all 3 reviewers run simultaneously]
Code reviewer:
  Strengths: Clean architecture
  Issues (Low): Consider extracting token logic
  Assessment: PASS

Business reviewer:
  Strengths: Workflow correct
  Issues (High): Missing password reset flow (required per PRD)
  Assessment: FAIL

Security reviewer:
  Strengths: Good validation
  Issues (Critical): JWT secret hardcoded, (High): No rate limiting
  Assessment: FAIL

[Aggregate issues by severity]
Critical: JWT secret hardcoded
High: Missing password reset, No rate limiting
Low: Extract token logic

[Dispatch fix subagent for Critical/High issues]
Fix subagent: Added password reset, moved secret to env var, added rate limiting

[Re-run all 3 reviewers in parallel after fixes]
Code reviewer: PASS
Business reviewer: PASS. All requirements met.
Security reviewer: PASS. Issues resolved.

[Add TODO comment for Low issue]
# TODO(review): Extract token generation logic into TokenService
# Reported by: code-reviewer on 2025-11-06
# Severity: Low

[Commit and mark Task 2 complete]

...

[After all tasks]
[Parallel final review - all 3 reviewers simultaneously]

Code reviewer:
  All implementation solid, architecture consistent
  Assessment: PASS

Business reviewer:
  All requirements met, workflows complete
  Assessment: PASS

Security reviewer:
  No remaining security concerns, ready for production
  Assessment: PASS

Done!
```

**Why parallel works well:**
- 3x faster than sequential (reviewers run simultaneously)
- Get all feedback at once (easier to prioritize fixes)
- Re-review after fixes is fast (parallel execution)
- TODO/FIXME comments track tech debt in code

## Advantages

**vs. Manual execution:**
- Subagents follow TDD naturally
- Fresh context per task (no confusion)
- Parallel-safe (subagents don't interfere)

**vs. Executing Plans:**
- Same session (no handoff)
- Continuous progress (no waiting)
- Review checkpoints automatic

**Cost:**
- More subagent invocations
- But catches issues early (cheaper than debugging later)

## Red Flags

**Never:**
- Skip code review between tasks
- Proceed with unfixed Critical/High/Medium issues
- Dispatch reviewers sequentially (use parallel - 3x faster!)
- Dispatch multiple implementation subagents in parallel (conflicts)
- Implement without reading plan task
- Forget to add TODO/FIXME comments for Low/Cosmetic issues

**Always:**
- Launch all 3 reviewers in single message with 3 Task calls
- Specify `model: "opus"` for each reviewer
- Wait for all reviewers before aggregating findings
- Fix Critical/High/Medium immediately
- Add TODO for Low, FIXME for Cosmetic
- Re-run all 3 reviewers after fixes

**If subagent fails task:**
- Dispatch fix subagent with specific instructions
- Don't try to fix manually (context pollution)

## Integration

**Required workflow skills:**
- **writing-plans** - REQUIRED: Creates the plan that this skill executes
- **requesting-code-review** - REQUIRED: Review after each task (see Step 3)
- **finishing-a-development-branch** - REQUIRED: Complete development after all tasks (see Step 7)

**Subagents must use:**
- **test-driven-development** - Subagents follow TDD for each task

**Alternative workflow:**
- **executing-plans** - Use for parallel session instead of same-session execution

See reviewer agent definitions: agents/code-reviewer.md, agents/security-reviewer.md, agents/business-logic-reviewer.md
