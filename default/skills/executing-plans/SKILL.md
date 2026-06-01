---
name: ring:executing-plans
description: |
  Inline execution of an implementation plan task-by-task with review checkpoints.
  Loads a written plan, reviews it critically, executes tasks in order with
  verification, and hands off to finishing skills when done.
---

# Executing Plans

## When to use
- A written plan exists (typically produced by ring:writing-plans)
- Inline execution in this session is preferred over full subagent orchestration
- Plan is small-to-medium and benefits from fast iteration with checkpoints

## Skip when
- Plan doesn't exist yet — use ring:writing-plans first
- Production-grade work requiring the full review pool — use ring:dev-cycle instead (lean backend cycle, Gate 0/8/9, dispatches specialists in parallel)
- Plan covers multiple independent subsystems — split into separate plans before executing

## Sequence
**Runs after:** ring:writing-plans (consumes its plan document)
**Alternative:** ring:dev-cycle (subagent-orchestrated, gated workflow with parallel specialist dispatch)

## Related
**Companion skills:** ring:test-driven-development (enforces RED→GREEN→REFACTOR per task), ring:commit (closes each task with a signed atomic commit)

---

Load the plan. Review it critically. Execute every task in order. Stop and ask when blocked.

**Announce at start:** "Using ring:executing-plans to implement this plan."

## The Process

### Step 1: Load and Review Plan

1. Read the plan file end-to-end
2. Review critically — identify questions or concerns
3. Verify the plan header (Goal, Architecture, Tech Stack) is present
4. If concerns: raise them with the user **before starting**
5. If no concerns: create the task tracker and proceed

| Concern type | Action |
|--------------|--------|
| Placeholder content ("TBD", "appropriate error handling") | Block; ask user to refine plan or fill in |
| Missing/contradictory test commands | Block; ask user to clarify |
| Type/method name inconsistency across tasks | Block; ask user to reconcile |
| Stylistic / "nice to have" | Note but proceed |

### Step 2: Execute Tasks

For each task in the plan:

1. Mark as in-progress in the task tracker
2. Follow each step exactly — the plan has bite-sized steps for a reason
3. Run verifications as specified (test commands, expected output)
4. Use ring:test-driven-development when a step writes new production code
5. Use ring:commit at the step that says "Commit"
6. Mark as completed only after verification passes

**Do not skip the RED phase.** If the plan says "Run test to verify it fails," run it and paste the failure output. Skipping verification means the plan didn't actually execute.

### Step 3: Complete Development

After all tasks complete and verified:

- Announce: "All tasks complete and verified. Closing with ring:commit."
- Use ring:commit for the final commit if uncommitted work remains
- Offer to push: `git push` (or `git push -u origin <branch>` if no upstream)

For production work, hand off to ring:codereview to run the review pool against the cumulative diff.

## ⛔ When to Stop and Ask

**Stop executing immediately when:**

| Trigger | Why it blocks |
|---------|---------------|
| Missing dependency | Can't proceed reliably without it |
| Test fails unexpectedly (not RED phase) | Either plan is wrong or implementation diverged |
| Instruction unclear or ambiguous | Guessing wastes more time than asking |
| Verification fails repeatedly | Underlying issue, not a flakiness retry |
| Plan has critical gaps preventing start | Should have been caught in Step 1; refine before continuing |

**Ask for clarification rather than guessing.** Plan execution is not the place for taste calls.

## When to Revisit Earlier Steps

**Return to Step 1 (Review) when:**
- User updates the plan based on your feedback
- Fundamental approach needs rethinking mid-execution

**Don't force through blockers** — stop and ask. A correctly-executed wrong plan still produces wrong code.

## ⛔ Branch Safety

**MUST NOT** start implementation on `main`/`master` without explicit user consent. If currently on a protected branch:

1. Stop
2. Ask the user to create or switch to a feature branch (or invoke ring:worktree for an isolated workspace)
3. Resume only after branch confirmation

## Remember

- Review plan critically first — fix gaps before executing
- Follow plan steps exactly — they are bite-sized for a reason
- Don't skip verifications (RED phase included)
- Reference required skills when the plan says to (ring:test-driven-development, ring:commit)
- Stop when blocked — don't guess
- Never implement on main/master without consent

## Verification Checklist

Before marking the plan complete:
- [ ] Every task in the plan executed and verified
- [ ] Every RED phase produced a real failure (output captured)
- [ ] Every GREEN phase passes with minimal code
- [ ] Every "Commit" step produced an atomic, signed commit via ring:commit
- [ ] Working tree clean (or remaining changes documented)
- [ ] Final commit / push offered to user
