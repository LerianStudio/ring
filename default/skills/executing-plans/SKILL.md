---
name: ring:executing-plans
description: "Executing a phased plan from ring:writing-plans in rolling waves: implements the detailed phase task-by-task with TDD and signed commits via ring:committing-changes, checkpoints at each phase boundary, then elaborates the next phase. Use when a phased plan exists and inline execution is preferred over subagent orchestration. Skip when no plan exists (use ring:writing-plans) or a plan-driven subagent dev cycle is wanted (use ring:running-dev-cycle)."
---

# Executing Plans

## When to use
- A phased plan exists (typically produced by ring:writing-plans)
- Inline execution in this session is preferred over full subagent orchestration
- Work benefits from phase checkpoints and course-correction between phases

## Skip when
- Plan doesn't exist yet — use ring:writing-plans first
- Production-grade work requiring the full review pool — use ring:running-dev-cycle instead (lean backend cycle, Gate 0/8/9, dispatches specialists in parallel)
- Plan covers multiple independent subsystems — split into separate plans before executing

## Sequence
**Runs after:** ring:writing-plans (consumes and updates its plan document)
**Alternative:** ring:running-dev-cycle (subagent-orchestrated, gated workflow with parallel specialist dispatch)

## Related
**Companion skills:** ring:writing-plans (defines the Epic and Task formats used during elaboration), ring:test-driven-development (enforces RED→GREEN→REFACTOR per task), ring:committing-changes (closes each task with a signed atomic commit)

---

The loop: **implement the detailed phase → phase checkpoint → elaborate the next phase → repeat.** The plan document is the living source of truth — elaboration writes tasks back into it.

**Announce at start:** "Using ring:executing-plans to implement this plan."

## The Process

### Step 1: Load and Review Plan

1. Read the plan file end-to-end
2. Verify the header (Goal, Architecture, Tech Stack, Phase Overview) is present
3. Verify exactly one phase is task-detailed (the current wave); later phases sit at epic level
4. Review critically — raise concerns with the user **before starting**

| Concern type | Action |
|--------------|--------|
| Vague detailed-wave task ("appropriate error handling", "TBD") | Block; ask user to refine or fill in |
| Phase that doesn't end in working, verifiable software | Block; ask user to redraw the boundary |
| Contract inconsistency between epics | Block; ask user to reconcile |
| Later phases already task-detailed | Warn — those tasks are stale risk; treat as drafts to re-validate at elaboration time |
| Stylistic / "nice to have" | Note but proceed |

### Step 2: Implement the Current Phase

For each task in the detailed phase, in order:

1. Mark as in-progress in the task tracker
2. Implement per the task's **Implementation vision** — its decisions are binding; raise a blocker rather than silently diverging
3. Use ring:test-driven-development for new production code: write the failing test first from the task's **Verification** intent, capture the RED output, then implement
4. Run the task's verification; paste the output
5. Close the task with ring:committing-changes (atomic, signed)
6. Mark as completed only after verification passes — tick the task's `- [ ] Done` checkbox in the plan document

**Do not skip the RED phase.** The plan carries no test code — writing the failing test from the verification intent IS the task's first step.

### Step 3: Phase Checkpoint (user gate)

When every task in the phase is complete and verified:

1. Update the plan document: flip the phase's Status to `Complete` in the Phase Overview; record any deviations from the plan that affect later phases
2. Present to the user: what was built, test results, deviations and why
3. **STOP and wait for the user's check** before elaborating the next phase — unless the user pre-authorized continuous execution, in which case state that and proceed

### Step 4: Elaborate the Next Phase (rolling wave)

After the checkpoint, detail the next phase before implementing it:

1. Re-read the phase's epics against the codebase **as it now exists** — not as the plan assumed it would
2. Fold in learnings and deviations from completed phases; if reality diverged enough to change an epic's scope or approach, surface that to the user before proceeding
3. Break each epic into dispatch-ready tasks using the **Task Format from ring:writing-plans** (load that skill if the format is not in context) — same bar: context with file:line references, implementation vision with decisions made, exact files, verification, done-when
4. Write the tasks into the plan document under their epics; flip the phase's Status to `Detailed`
5. Return to Step 2 with the newly detailed phase

Repeat Steps 2–4 until every phase is complete.

### Step 5: Complete Development

After all phases complete and verified:

- Announce: "All phases complete and verified. Closing with ring:committing-changes."
- Use ring:committing-changes for the final commit if uncommitted work remains
- Offer to push: `git push` (or `git push -u origin <branch>` if no upstream)

For production work, hand off to ring:reviewing-code to run the review pool against the cumulative diff.

## ⛔ When to Stop and Ask

**Stop executing immediately when:**

| Trigger | Why it blocks |
|---------|---------------|
| Missing dependency | Can't proceed reliably without it |
| Test fails unexpectedly (not RED phase) | Either plan is wrong or implementation diverged |
| Task's implementation vision conflicts with the actual codebase | The wave is stale; re-elaborate, don't improvise |
| Instruction unclear or ambiguous | Guessing wastes more time than asking |
| Verification fails repeatedly | Underlying issue, not a flakiness retry |
| Epic scope no longer matches reality at elaboration time | User decides whether scope shifts or plan changes |

**Ask for clarification rather than guessing.** Plan execution is not the place for taste calls.

## ⛔ Branch Safety

**MUST NOT** start implementation on `main`/`master` without explicit user consent. If currently on a protected branch:

1. Stop
2. Ask the user to create or switch to a feature branch (or invoke ring:creating-worktrees for an isolated workspace)
3. Resume only after branch confirmation

## Remember

- Review the plan critically first — fix gaps before executing
- One detailed wave at a time — never elaborate two phases ahead
- The plan document is living: tick tasks, flip statuses, record deviations
- Don't skip verifications (RED phase included)
- Phase checkpoint is a user gate, not a formality
- Elaborate against the codebase as it exists, not as the plan assumed
- Stop when blocked — don't guess
- Never implement on main/master without consent

## Verification Checklist

Before marking the plan complete:
- [ ] Every phase implemented and verified, in order
- [ ] Every phase boundary checkpointed with the user (or continuous mode explicitly pre-authorized)
- [ ] Every later phase elaborated into tasks before implementation, against the real codebase
- [ ] Every RED phase produced a real failure (output captured)
- [ ] Every task closed with an atomic, signed commit via ring:committing-changes
- [ ] Plan document reflects final state (statuses, ticked tasks, recorded deviations)
- [ ] Working tree clean (or remaining changes documented)
- [ ] Final commit / push offered to user
