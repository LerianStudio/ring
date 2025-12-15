---
name: ring-default:subagent-driven-development
description: |
  Autonomous plan execution - fresh subagent per task with automated code review
  between tasks. No human-in-loop, high throughput with quality gates.

trigger: |
  - Staying in current session (no worktree switch)
  - Tasks are independent (can be executed in isolation)
  - Want continuous progress without human pause points

skip_when: |
  - Need human review between tasks → use executing-plans
  - Tasks are tightly coupled → execute manually
  - Plan needs revision → use brainstorming first

sequence:
  after: [writing-plans, pre-dev-task-breakdown]

related:
  similar: [executing-plans]
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

**Dispatch:** `Task tool (general-purpose)` with: Task N from [plan-file], instructions (implement, test with TDD, verify, commit, report back), working directory. Subagent reports summary.

### 3. Review Subagent's Work (Parallel Execution)

**CRITICAL: Single message with 3 Task tool calls** - all reviewers execute simultaneously.

| Reviewer | Model | Context |
|----------|-------|---------|
| `code-reviewer` | opus | WHAT_WAS_IMPLEMENTED, PLAN, BASE_SHA, HEAD_SHA |
| `business-logic-reviewer` | opus | Same context |
| `security-reviewer` | opus | Same context |

**Each returns:** Strengths, Issues (Critical/High/Medium/Low/Cosmetic), Assessment (PASS/FAIL)

### 4. Aggregate and Handle Review Feedback

**Aggregate** all issues by severity across all 3 reviewers.

| Severity | Action |
|----------|--------|
| **Critical/High/Medium** | Dispatch fix subagent → Re-run all 3 reviewers → Repeat until clear |
| **Low** | Add `# TODO(review): [issue] - reviewer, date, Severity: Low` |
| **Cosmetic** | Add `# FIXME(nitpick): [issue] - reviewer, date, Severity: Cosmetic` |

Commit TODO/FIXME comments with fixes.

### 5. Mark Complete, Next Task

After all Critical/High/Medium issues resolved for current task:
- Mark task as completed in TodoWrite
- Commit all changes (including TODO/FIXME comments)
- Move to next task
- Repeat steps 2-5

### 6. Final Review (After All Tasks)

**Same pattern as Step 3** but reviewing entire implementation (all tasks, full BASE_SHA→HEAD_SHA range). Aggregate, fix, re-run until all 3 PASS.

### 7. Complete Development

After final review passes:
- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED SUB-SKILL:** Use finishing-a-development-branch
- Follow that skill to verify tests, present options, execute choice

## Example Workflow

**Task 1:** Implement → All 3 reviewers PASS → Mark complete.

**Task 2:** Implement → Review finds: Critical (hardcoded secret), High (missing password reset, no rate limiting), Low (extract token logic) → Dispatch fix subagent → Re-run reviewers → All PASS → Add TODO for Low → Mark complete.

**Final:** All 3 reviewers PASS entire implementation → Done.

**Why parallel:** 3x faster, all feedback at once, TODO/FIXME tracks tech debt.

## Advantages

| vs. | Benefits |
|-----|----------|
| **Manual execution** | Fresh context per task, TDD enforced, parallel-safe |
| **Executing Plans** | Same session (no handoff), continuous progress, automatic review |

**Cost:** More invocations, but catches issues early (cheaper than debugging later).

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

See reviewer agent definitions: code-reviewer (agents/code-reviewer.md), security-reviewer (agents/security-reviewer.md), business-logic-reviewer (agents/business-logic-reviewer.md)
