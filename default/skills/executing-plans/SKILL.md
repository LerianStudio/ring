---
name: executing-plans
description: |
  Controlled plan execution with human review checkpoints - loads plan, executes
  in batches, pauses for feedback. Supports one-go (autonomous) or batch modes.
metadata:
  related:
    similar:
    - ring:subagent-driven-development
  sequence:
    after:
    - ring:writing-plans
    - ring:pre-dev-task-breakdown
  skip_when: |
    - Same session with independent tasks → use ring:subagent-driven-development
    - No plan exists → use ring:writing-plans first
    - Plan needs revision → use ring:brainstorming first
  trigger: |
    - Have a plan file ready to execute
    - Want human review between task batches
    - Need structured checkpoints during implementation
---

# Executing Plans

## Overview

Load plan, review critically, choose execution mode, execute tasks with code review.

**Core principle:** User chooses between autonomous execution or batch execution with human review checkpoints.

**Two execution modes:**
- **One-go (autonomous):** Execute all batches continuously with code review, report only at completion
- **Batch (with review):** Execute one batch, code review, pause for human feedback, repeat

**Announce at start:** "I'm using the ring:executing-plans skill to implement this plan."

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

### Step 2.5: Context Switching for Multi-Module Plans

**If plan has tasks with `target:` and `working_directory:` fields:**

1. **Track current module:**
   ```
   current_module = None
   current_directory = "."
   ```

2. **Before each task, check for context switch:**
   ```
   IF task.target != current_module AND current_module != None:
     # Prompt user for confirmation
     AskUserQuestion:
       question: "Switching to {task.target} module at {task.working_directory}. Continue?"
       header: "Context"
       options:
         - label: "Continue"
           description: "Switch to {task.target} and execute task"
         - label: "Skip task"
           description: "Skip this task and continue with next"
         - label: "Stop"
           description: "Stop execution for manual review"

     IF answer == "Continue":
       current_module = task.target
       current_directory = task.working_directory
     ELIF answer == "Skip":
       Mark task as skipped → proceed to next
     ELSE:
       Stop execution → report progress
   ```

3. **Load module-specific PROJECT_RULES.md:**
   ```
   IF {task.working_directory}/PROJECT_RULES.md exists:
     Instruct agent to read module-specific rules
     Module rules override root rules
   ```

4. **Pass working directory to agent:**
   ```
   Task(
     subagent_type=task.agent,
     prompt="Working directory: {task.working_directory}

     Before executing, cd to the working directory:
     cd {task.working_directory}

     If PROJECT_RULES.md exists in this directory, read and follow it.

     {task.prompt}"
   )
   ```

**Optimization:** To minimize context switches, batch tasks by module when possible:
- Original: [backend, frontend, backend, frontend]
- Optimized: [backend, backend, frontend, frontend]
- **Only reorder if no dependencies between modules**

---

### Step 3: Execute Batch
**Default: First 3 tasks**

**Agent Selection:** Backend Go → `ring:backend-engineer-golang` | Backend TS → `ring:backend-engineer-typescript` | Frontend → `ring:frontend-bff-engineer-typescript` | Infra → `ring:devops-engineer` | Testing → `ring:qa-analyst` | Reliability → `ring:sre`

For each task: Check context switch (Step 2.5) → Mark in_progress → Dispatch to agent with working_directory → Follow plan steps exactly → Run verifications → Mark completed

### Step 4: Run Code Review
**After each batch, REQUIRED:** Use ring:requesting-code-review (all 7 reviewers in parallel)

**Handle by severity:**
- **Critical/High/Medium:** Fix immediately (no TODO) → re-run all 7 reviewers → repeat until resolved
- **Low:** Add `TODO(review): [Issue] ([reviewer], [date], Low)`
- **Cosmetic:** Add `FIXME(nitpick): [Issue] ([reviewer], [date], Cosmetic)`

**Proceed when:** Zero Critical/High/Medium remain + all Low/Cosmetic have comments

### Step 5: Report and Continue

**One-go mode:** Log internally → proceed to next batch → report only at completion
**Batch mode:** Show implementation + verification + review results → "Ready for feedback." → wait → apply changes → proceed

### Step 6: Complete Development

Use finishing-a-development-branch to verify tests, present options, execute choice.

## When to Stop

**STOP immediately:** Blocker mid-batch | Critical gaps | Unclear instruction | Verification fails repeatedly. **Ask rather than guess.**

## Remember

- **MANDATORY:** `AskUserQuestion` for execution mode - NO exceptions
- Use `*` agents over `general-purpose` when available
- Run code review after each batch (all 7 parallel)
- Fix Critical/High/Medium immediately (no TODO)
- Low → TODO, Cosmetic → FIXME
- Stop when blocked, don't guess
- **If rationalizing why to skip AskUserQuestion → You're wrong → Ask anyway**

## Blocker Criteria

STOP and report if:

| Decision Type | Blocker Condition | Required Action |
|---|---|---|
| Execution mode | AskUserQuestion not used for mode selection | STOP and ask for execution mode - NO exceptions |
| Plan loading | Plan file not found or unreadable | STOP and report missing plan |
| Code review | Critical/High/Medium issues found in review | STOP and fix before proceeding |
| Task blocker | Task blocked mid-batch | STOP and report blocker details |
| Verification | Task verification fails repeatedly | STOP and escalate |

### Cannot Be Overridden

The following requirements CANNOT be waived:
- AskUserQuestion for execution mode is MANDATORY - user intent does NOT skip this step
- Code review after each batch is REQUIRED - all 7 reviewers in parallel
- Critical/High/Medium issues MUST be fixed immediately - TODO comments are FORBIDDEN for these severities
- Context switch confirmation is REQUIRED when switching between modules
- Full test suite MUST pass before completing development

## Severity Calibration

| Severity | Condition | Required Action |
|---|---|---|
| CRITICAL | Skipped AskUserQuestion for execution mode | MUST stop and ask for mode selection |
| CRITICAL | Proceeding with unfixed Critical/High review findings | MUST fix issues before continuing |
| HIGH | Skipped code review after batch | MUST run all 7 reviewers |
| HIGH | Used TODO for Critical/High/Medium issues | MUST fix immediately, remove TODO |
| MEDIUM | Missing context switch confirmation for multi-module | Should add module switch prompt |
| LOW | Low-severity issues without TODO comment | Fix by adding proper TODO format |

## Pressure Resistance

| User Says | Your Response |
|---|---|
| "Just execute, don't ask about mode" | "MUST use AskUserQuestion for execution mode. This is a structural checkpoint, not optional. Takes 3 seconds." |
| "Skip the code review, we're in a hurry" | "Code review is REQUIRED after each batch. CANNOT proceed without running all 7 reviewers." |
| "Add a TODO for that critical issue, fix later" | "Critical/High/Medium issues MUST be fixed immediately. TODO comments FORBIDDEN for these severities." |
| "User intent is clear, skip the question" | "Intent is not explicit selection. MUST use AskUserQuestion - it's a structural gate, not conversation." |

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|---|---|---|
| "User said 'just execute' so mode is clear" | Verbal shorthand ≠ structured mode selection | **MUST use AskUserQuestion anyway** |
| "This is contextual guidance, not absolute law" | It says MANDATORY - that means mandatory | **MUST follow the mandatory step** |
| "Asking would violate their 'don't ask' instruction" | AskUserQuestion is a 3-second structural gate, not a conversation | **MUST ask for execution mode** |
| "Skills are tools, not bureaucratic checklists" | This skill IS the checklist; that's its purpose | **MUST follow the checklist** |
| "Review is overkill for small changes" | Small changes can have critical bugs; review catches them | **MUST run code review after each batch** |
