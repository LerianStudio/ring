---
name: executing-plans
description: |
  Controlled plan execution with human review checkpoints - loads plan, executes
  in batches, pauses for feedback. Supports one-go (autonomous) or batch modes.

trigger: |
  - Have a plan file ready to execute
  - Want human review between task batches
  - Need structured checkpoints during implementation

skip_when: |
  - Same session with independent tasks → use subagent-driven-development
  - No plan exists → use writing-plans first
  - Plan needs revision → use brainstorming first

sequence:
  after: [writing-plans, pre-dev-task-breakdown]

related:
  similar: [subagent-driven-development]
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

Use `AskUserQuestion` to determine execution mode:

```
AskUserQuestion(
  questions: [{
    header: "Mode",
    question: "How would you like to execute this plan?",
    options: [
      { label: "One-go (autonomous)", description: "Execute all batches automatically with code review between each, no human review until completion" },
      { label: "Batch (with review)", description: "Execute in batches, pause for human review after each batch's code review" }
    ],
    multiSelect: false
  }]
)
```

**Based on response:**
- **One-go** → Execute all batches continuously (Steps 3-4 loop until done, skip Step 5)
- **Batch** → Execute one batch, report, wait for feedback (Steps 3-5 loop)

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

**Agent Selection:** For each task, dispatch to the appropriate specialized agent based on task type:

| Task Type | Preferred Agent | Fallback |
|-----------|-----------------|----------|
| Backend (Go) | `ring-dev-team:backend-engineer-golang` | `general-purpose` |
| Backend (TypeScript) | `ring-dev-team:backend-engineer-typescript` | `general-purpose` |
| Frontend (TypeScript/React) | `ring-dev-team:frontend-engineer-typescript` | `general-purpose` |
| Infrastructure | `ring-dev-team:devops-engineer` | `general-purpose` |
| Testing | `ring-dev-team:qa-analyst` | `general-purpose` |
| Reliability | `ring-dev-team:sre` | `general-purpose` |

> **Note:** `general-purpose` is Claude's built-in agent for general tasks. It does NOT require the `ring-` prefix as it's not a Ring plugin agent.

**Note:** If plan specifies a recommended agent in its header, use that. If `ring-dev-team` plugin is unavailable, fall back to `general-purpose`.

For each task:
1. Mark as in_progress
2. Dispatch to appropriate specialized agent (or fallback)
3. Agent follows each step exactly (plan has bite-sized steps)
4. Run verifications as specified
5. Mark as completed

### Step 4: Run Code Review
**After each batch execution, REQUIRED:**

1. **Dispatch all 3 reviewers in parallel:**
   - REQUIRED SUB-SKILL: Use ring-default:requesting-code-review
   - All reviewers run simultaneously (not sequentially)
   - Wait for all to complete

2. **Handle findings by severity:**

**Critical/High/Medium Issues:**
- Fix immediately (do NOT add TODO comments)
- Re-run all 3 reviewers in parallel after fixes
- Repeat until no Critical/High/Medium issues remain

**Low Issues:**
- Add `TODO(review):` comments in code
- Format: `TODO(review): [Issue description] (reported by [reviewer] on [date], severity: Low)`
- Track tech debt at code location for visibility

**Cosmetic/Nitpick Issues:**
- Add `FIXME(nitpick):` comments in code
- Format: `FIXME(nitpick): [Issue description] (reported by [reviewer] on [date], severity: Cosmetic)`
- Low-priority improvements tracked inline

3. **Only proceed when:**
   - Zero Critical/High/Medium issues remain
   - All Low/Cosmetic issues have TODO/FIXME comments

### Step 5: Report and Continue

**Behavior depends on execution mode chosen in Step 2:**

**One-go mode:**
- Log batch completion internally
- Immediately proceed to next batch (Step 3)
- Continue until all tasks complete
- Only report to human at final completion

**Batch mode:**
- Show what was implemented
- Show verification output
- Show code review results (severity breakdown)
- Say: "Ready for feedback."
- Wait for human response
- Apply changes if requested
- Then proceed to next batch (Step 3)

### Step 6: Complete Development

After all tasks complete and verified:
- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED SUB-SKILL:** Use ring-default:finishing-a-development-branch
- Follow that skill to verify tests, present options, execute choice

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Hit a blocker mid-batch (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly

**Ask for clarification rather than guessing.**

## When to Revisit Earlier Steps

**Return to Review (Step 1) when:**
- Partner updates the plan based on your feedback
- Fundamental approach needs rethinking

**Don't force through blockers** - stop and ask.

## Remember
- Review plan critically first
- **MANDATORY: Use `AskUserQuestion` for execution mode** - NO exceptions, even if user says "don't ask"
- **Use specialized agents:** Prefer `ring-dev-team:*` agents over `general-purpose` when available
- Follow plan steps exactly
- Don't skip verifications
- Run code review after each batch (all 3 reviewers in parallel)
- Fix Critical/High/Medium immediately - no TODO comments for these
- Only Low issues get TODO comments, Cosmetic get FIXME
- Reference skills when plan says to
- **One-go mode:** Continue autonomously until completion
- **Batch mode:** Report and wait for feedback between batches
- Stop when blocked, don't guess
- **If rationalizing why to skip AskUserQuestion → You're wrong → Ask anyway**
