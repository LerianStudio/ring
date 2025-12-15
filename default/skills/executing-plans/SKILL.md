---
name: ring-default:executing-plans
description: |
  Controlled plan execution with human review checkpoints - loads plan, executes
  in batches, pauses for feedback. Supports one-go (autonomous) or batch modes.

trigger: |
  - Have a plan file ready to execute
  - Want human review between task batches
  - Need structured checkpoints during implementation

skip_when: |
  - Same session with independent tasks → use ring-default:subagent-driven-development
  - No plan exists → use ring-default:writing-plans first
  - Plan needs revision → use ring-default:brainstorming first

sequence:
  after: [ring-default:writing-plans, ring-pm-team:pre-dev-task-breakdown]

related:
  similar: [ring-default:subagent-driven-development]
---

# Executing Plans

## Overview

Load plan, review critically, choose execution mode, execute tasks with code review.

**Core principle:** User chooses between autonomous execution or batch execution with human review checkpoints.

**Two execution modes:**
- **One-go (autonomous):** Execute all batches continuously with code review, report only at completion
- **Batch (with review):** Execute one batch, code review, pause for human feedback, repeat

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

## The Process

### Step 1: Load and Review Plan
1. Read plan file
2. Review critically - identify any questions or concerns about the plan
3. If concerns: Raise them with your human partner before starting
4. If no concerns: Create TodoWrite and proceed to Step 2

### Step 2: Choose Execution Mode (MANDATORY)

**⚠️ THIS STEP IS NON-NEGOTIABLE. You MUST use `AskUserQuestion` before executing ANY tasks.**

Ask: "How would you like to execute this plan?" Options: (1) **One-go (autonomous)** - all batches with code review, no human review until completion (2) **Batch (with review)** - pause for human review after each batch

**Based on response:** One-go → Steps 3-4 loop until done | Batch → Steps 3-5 loop

### Why AskUserQuestion is Mandatory (Not "Contextual Guidance")

**This is a structural checkpoint, not optional UX polish.**

User saying "don't wait", "don't ask questions", or "just execute" does NOT skip this step because:

1. **Execution mode affects architecture** - One-go vs batch determines review checkpoints, error recovery paths, and rollback points
2. **Implicit intent ≠ explicit choice** - "Don't wait" might mean "use one-go" OR "ask quickly and proceed"
3. **AskUserQuestion takes 3 seconds** - It's not an interruption, it's a confirmation
4. **Emergency pressure is exactly when mistakes happen** - Structural gates exist FOR high-pressure moments

**Common Rationalizations That Mean You're About to Violate This Rule:**

| Rationalization | Reality |
|-----------------|---------|
| "User intent is crystal clear" | Intent is not the same as explicit selection. Ask anyway. |
| "This is contextual guidance, not absolute law" | Wrong. It says MANDATORY. That means mandatory. |
| "Asking would violate their 'don't ask' instruction" | AskUserQuestion is a 3-second structural gate, not a conversation. |
| "Skills are tools, not bureaucratic checklists" | This skill IS the checklist. Follow it. |
| "Interpreting spirit over letter" | The spirit IS the letter. Use AskUserQuestion. |
| "User already chose by saying 'just execute'" | Verbal shorthand ≠ structured mode selection. Ask. |

**If you catch yourself thinking any of these → STOP → Use AskUserQuestion anyway.**

### Step 3: Execute Batch
**Default: First 3 tasks**

**Agent Selection:** Backend Go → `ring-dev-team:backend-engineer-golang` | Backend TS → `ring-dev-team:backend-engineer-typescript` | Frontend → `ring-dev-team:frontend-bff-engineer-typescript` | Infra → `ring-dev-team:devops-engineer` | Testing → `ring-dev-team:qa-analyst` | Reliability → `ring-dev-team:sre` | Fallback → `general-purpose`

For each task: Mark in_progress → Dispatch to agent → Follow plan steps exactly → Run verifications → Mark completed

### Step 4: Run Code Review
**After each batch, REQUIRED:** Use ring-default:requesting-code-review (all 3 reviewers in parallel)

**Handle by severity:**
- **Critical/High/Medium:** Fix immediately (no TODO) → re-run all 3 reviewers → repeat until resolved
- **Low:** Add `TODO(review): [Issue] ([reviewer], [date], Low)`
- **Cosmetic:** Add `FIXME(nitpick): [Issue] ([reviewer], [date], Cosmetic)`

**Proceed when:** Zero Critical/High/Medium remain + all Low/Cosmetic have comments

### Step 5: Report and Continue

**One-go mode:** Log internally → proceed to next batch → report only at completion
**Batch mode:** Show implementation + verification + review results → "Ready for feedback." → wait → apply changes → proceed

### Step 6: Complete Development

Use ring-default:finishing-a-development-branch to verify tests, present options, execute choice.

## When to Stop

**STOP immediately:** Blocker mid-batch | Critical gaps | Unclear instruction | Verification fails repeatedly. **Ask rather than guess.**

## Remember

- **MANDATORY:** `AskUserQuestion` for execution mode - NO exceptions
- Use `*` agents over `general-purpose` when available
- Run code review after each batch (all 3 parallel)
- Fix Critical/High/Medium immediately (no TODO)
- Low → TODO, Cosmetic → FIXME
- Stop when blocked, don't guess
- **If rationalizing why to skip AskUserQuestion → You're wrong → Ask anyway**
