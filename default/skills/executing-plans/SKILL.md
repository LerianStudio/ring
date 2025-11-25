---
name: executing-plans
description: Use when partner provides a complete implementation plan to execute in controlled batches with review checkpoints - loads plan, reviews critically, executes tasks in batches, reports for review between batches
when_to_use: Use when partner provides a complete implementation plan to execute in controlled batches with review checkpoints - loads plan, reviews critically, executes tasks in batches, reports for review between batches
---

# Executing Plans

## Overview

Load plan, review critically, execute tasks in batches, report for review between batches.

**Core principle:** Batch execution with checkpoints for architect review.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

## The Process

### Step 1: Load and Review Plan
1. Read plan file
2. Review critically - identify any questions or concerns about the plan
3. If concerns: Raise them with your human partner before starting
4. If no concerns: Create TodoWrite and proceed

### Step 2: Execute Batch
**Default: First 3 tasks**

For each task:
1. Mark as in_progress
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. Mark as completed

### Step 3: Run Code Review
**After each batch execution, REQUIRED:**

1. **Dispatch all 3 reviewers in parallel:**
   - REQUIRED SUB-SKILL: Use ring:requesting-code-review
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

3. **Only proceed to reporting when:**
   - Zero Critical/High/Medium issues remain
   - All Low/Cosmetic issues have TODO/FIXME comments

### Step 4: Report
When batch complete AND code review passed:
- Show what was implemented
- Show verification output
- Show code review results (severity breakdown)
- Say: "Ready for feedback."

### Step 5: Continue
Based on feedback:
- Apply changes if needed
- Execute next batch
- Repeat until complete

### Step 6: Complete Development

After all tasks complete and verified:
- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED SUB-SKILL:** Use ring:finishing-a-development-branch
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
- Follow plan steps exactly
- Don't skip verifications
- Run code review after each batch (all 3 reviewers in parallel)
- Fix Critical/High/Medium immediately - no TODO comments for these
- Only Low issues get TODO comments, Cosmetic get FIXME
- Reference skills when plan says to
- Between batches: just report and wait
- Stop when blocked, don't guess
