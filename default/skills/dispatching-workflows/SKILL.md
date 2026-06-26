---
name: ring:dispatching-workflows
description: "Executing a phased plan in rolling waves where each phase runs as one multi-agent workflow harness: the supervisor elaborates the phase into tasks against the real landed code, launches a workflow that implements with TDD and runs mandatory in-harness review plus an adversarial contrarian pass (and researchers when the phase hits an unknown) before returning verified work, then reviews it, checkpoints with the user, and rolls to the next phase. Use when each wave should be a reviewed multi-agent harness, not a lone subagent. Skip when one supervised subagent per wave suffices (ring:executing-plans) or the full gated cycle is wanted (ring:running-dev-cycle)."
---

# Dispatching Workflows

## When to use
- A phased plan exists (typically from ring:writing-plans) and you want each phase executed by a **multi-agent harness**, not a single subagent
- You want review and an adversarial contrarian pass baked **inside** every wave — verified work returns, unverified work does not
- Work benefits from phase checkpoints and supervisor course-correction between phases

## Skip when
- One supervised subagent per wave is enough → ring:executing-plans (lighter; the supervisor reviews after the wave returns)
- Production work needing the full gated specialist roster and Gate 0/8/9 → ring:running-dev-cycle
- No plan exists yet → ring:writing-plans first
- Plan covers multiple independent subsystems → split into separate plans before executing

## Sequence
**Runs after:** ring:writing-plans (consumes and updates its living plan document)
**Alternatives:** ring:executing-plans (one supervised subagent per wave — lighter), ring:running-dev-cycle (full gated specialist cycle — heavier)

## Related
**Companion skills:** ring:writing-plans (Task Format + phase-epic-task hierarchy used during elaboration), ring:test-driven-development (RED→GREEN per task, inside the harness), ring:committing-changes (closes each task with a signed atomic commit), ring:reviewing-code (the full 9+ reviewer pool — run it at plan close or for a high-stakes phase)

---

The loop: **elaborate the current phase into tasks against the real landed code → launch the phase as one workflow that implements, reviews, and contrarian-verifies internally → the workflow returns verified work → review it as supervisor → phase checkpoint → roll to the next phase → repeat.** The main agent stays the supervisor; the workflow is a multi-agent harness, not a lone implementer. The plan document is the living source of truth — elaboration writes tasks back into it.

**Announce at start:** "Using ring:dispatching-workflows to execute this plan phase-by-phase as reviewed multi-agent workflows."

## How this differs from the sibling skills

| Skill | Wave unit | What runs the wave | Where review happens |
|-------|-----------|--------------------|----------------------|
| ring:executing-plans | phase or epic | **one** supervised subagent | supervisor reviews **after** the wave returns |
| **ring:dispatching-workflows** | **phase** | a **multi-agent workflow harness** | **inside** the harness (mandatory) — verified work returns |
| ring:running-dev-cycle | task/epic/phase cadences | gated specialist orchestration | Gate 8 full reviewer pool, per epic |

If you do not need an in-harness multi-agent pass, use ring:executing-plans — it is cheaper and simpler.

## The Harness (what runs inside one phase workflow)

Author one workflow per phase. Its stages, in order:

1. **Research (conditional)** — only when the phase introduces an unknown (a new library, an unfamiliar pattern, an external contract). A researcher agent resolves it and feeds findings to the implementers. Skip when the phase is well-understood.
2. **Implement** — the phase's tasks, in dependency order. Each task uses ring:test-driven-development (failing test first, capture RED, then GREEN) and closes with a signed atomic commit via ring:committing-changes. Tasks in a phase usually depend on each other → run them sequentially; parallelize only truly independent tasks, and then with `isolation: 'worktree'` so they don't collide on files.
3. **Review (MANDATORY)** — the relevant Ring reviewer agents, in parallel, over the phase diff. **Compose the existing reviewers via `agentType`** (`agent(prompt, {agentType: 'ring:logic-reviewer', schema})`) — do not re-implement them, and do not re-list the roster here. Pick by what the phase touched (see ring:reviewing-code for the roster and the triggers for conditional specialists). Review is read-only.
4. **Contrarian (MANDATORY)** — adversarial verifiers whose job is to **refute** the wave's claims, not confirm them: that tests actually ran, that the implementation matches each task's vision, that no scope was smuggled in, that no simpler correct approach was ignored. Prompt them to default to *refuted* when uncertain. This is a **role**, not a Ring agent — it lives in the harness prompt.
5. **Synthesize** — PASS only if review surfaced no Critical/High **and** the contrarian refuted nothing. Otherwise the harness self-heals once (fix → re-review), and if still not clean **returns `ISSUES`** rather than looping unbounded. Return a structured report: `status`, `commits`, `findings`, `refutations`.

**Review depth scales with the phase** — pick the reviewers the diff warrants; do not run all 12 every phase. The full ring:reviewing-code pool is the supervisor's call at plan close or for a high-stakes phase, not a per-phase default.

### Workflow skeleton (Claude Code Workflow tool)

```js
export const meta = {
  name: 'phase-wave',
  description: 'Implement one plan phase, then review + contrarian-verify before returning',
  phases: [{ title: 'Implement' }, { title: 'Review' }, { title: 'Contrarian' }],
}

const TASKS     = args.tasks      // dispatch-ready tasks the supervisor elaborated this phase
const REVIEWERS = args.reviewers  // Ring reviewer agentTypes picked for this phase's diff

// 2. Implement — dependency order; TDD (RED→GREEN) + signed commit per task.
phase('Implement')
const built = []
for (const t of TASKS) {
  built.push(await agent(implementPrompt(t, built), {
    label: `impl:${t.id}`, phase: 'Implement', schema: TASK_RESULT,
  }))
}

// 3. Review (MANDATORY) — compose Ring reviewers over the phase diff, in parallel.
phase('Review')
const reviews = (await parallel(REVIEWERS.map(a => () =>
  agent(reviewPrompt(built), { label: a, phase: 'Review', agentType: a, schema: FINDINGS })
))).filter(Boolean)

// 4. Contrarian (MANDATORY) — try to REFUTE each claim, not confirm it.
phase('Contrarian')
const refutations = (await parallel(built.map(b => () =>
  agent(`Try to refute this claim about the just-built code: "${b.claim}". `
      + `Verify the tests actually ran, the implementation matches the task vision, `
      + `no scope was smuggled in, and no simpler correct approach was ignored. `
      + `Default to refuted=true if uncertain.`,
    { label: `refute:${b.id}`, phase: 'Contrarian', schema: VERDICT })
))).filter(Boolean)

// 5. Synthesize — PASS only if review is clean AND nothing was refuted.
const blocking = reviews.flatMap(r => r.findings).filter(f => f.severity === 'Critical' || f.severity === 'High')
const refuted  = refutations.filter(v => v.refuted)
return {
  status: blocking.length === 0 && refuted.length === 0 ? 'PASS' : 'ISSUES',
  commits: built.map(b => b.commit),
  findings: reviews.flatMap(r => r.findings),
  refutations: refuted,
}
// ponytail: happy path. Self-heal (fix → re-review once) and the conditional Research
// stage are described in prose above — add them only when a phase actually needs them.
```

## The Process

### Step 1: Load the plan and choose dispatch
1. Read the plan file end-to-end; verify the header (Goal, Architecture, Tech Stack, Phase Overview) and that exactly one phase is task-detailed (the current wave).
2. Review critically — raise gaps with the user **before launching** (vague tasks, a phase that doesn't end in working software, contract inconsistencies between epics).
3. Confirm branch safety (below).

### Step 2: Elaborate the current phase (rolling wave)
Detail the phase **against the codebase as it now exists** — not as the plan assumed — using the **Task Format from ring:writing-plans** (load it if not in context): context with file:line, implementation vision with decisions made, exact files, verification, done-when. Fold in deviations from completed phases; if reality diverged enough to change an epic's scope, surface it before proceeding. Write the tasks back into the plan and flip the phase Status to `Detailed`. If the phase introduces an unknown the supervisor itself can't pin down, research it (or mark it for the harness's Research stage) before launching.

### Step 3: Launch the phase workflow
Author the harness for this phase (skeleton above) and launch it with the elaborated tasks and the reviewer set you picked for the phase diff. The supervisor does **not** implement; the harness does. Then await its return.

### Step 4: Supervise the returned wave
When the workflow returns, the supervisor reviews it as a gate:
- The report MUST show a completed Review stage **and** a completed Contrarian stage. A wave that returns without both is **non-compliant** — bounce it, do not accept it.
- `status` must be `PASS`. On `ISSUES`, read the findings/refutations and dispatch a fix wave before advancing.
- Spot-check that each task's tests actually ran (RED captured), commits are atomic and signed, and the implementation matches the vision — the contrarian reduces this load but does not replace the supervisor's judgment.

### Step 5: Phase checkpoint (user gate)
When the phase is complete and verified:
1. Update the plan: flip the phase Status to `Complete`; record deviations that affect later phases.
2. Present to the user: what was built, test results, review/contrarian outcome, deviations and why.
3. **STOP and wait** for the user's check before elaborating the next phase — unless the user pre-authorized continuous execution, in which case say so and proceed.
4. After the user approves, call `Skill("ring:committing-changes")` to commit all phase work before rolling to the next phase.

### Step 6: Roll to the next phase, then complete
Return to Step 2 for the next phase. Repeat until every phase is `Complete`. At plan close:
- Announce completion; commit any remaining work via ring:committing-changes; offer to push.
- For production work, hand off to ring:reviewing-code to run the **full** reviewer pool against the cumulative diff — the per-phase in-harness review is targeted, not the final gate.

## Without a workflow harness (fallback)

Ring runs across harnesses; the Workflow tool is Claude Code only. Where it is absent, keep the same contract with a **single atomic parallel dispatch** per phase: dispatch the implementers, then dispatch the picked Ring reviewers **plus a contrarian agent** in one parallel batch (the discipline in ring:reviewing-code applies — all in one turn, no trickle-dispatch), and the supervisor aggregates. The stages and the mandatory review + contrarian rule are unchanged; only the orchestration primitive differs.

## ⛔ Mandatory review inside the harness

Review and the contrarian pass are **not optional and not deferrable to the supervisor**. A workflow script without both stages is non-compliant. A returned wave whose report does not show both stages ran MUST be rejected. The point of this skill over ring:executing-plans is exactly that verification happens *inside* the wave — remove it and you should be using the lighter skill.

## ⛔ When to Stop and Ask

| Trigger | Why it blocks |
|---------|---------------|
| Missing dependency | Can't proceed reliably |
| A task's vision conflicts with the actual codebase | The wave is stale — re-elaborate, don't improvise |
| Verification fails repeatedly (not the RED phase) | Underlying issue, not flakiness |
| Contrarian refutes a claim the harness can't resolve in one self-heal | Surface it; the supervisor decides |
| Epic scope no longer matches reality at elaboration time | The user decides whether scope shifts or the plan changes |

Ask rather than guess. Plan execution is not the place for taste calls.

## ⛔ Branch Safety

**MUST NOT** launch implementation on `main`/`master` without explicit user consent. If on a protected branch: stop, ask the user to switch to a feature branch (or invoke ring:creating-worktrees), and resume only after confirmation.

## Remember
- The supervisor elaborates and reviews; the workflow harness implements, reviews, and contrarian-verifies
- One detailed wave at a time — never elaborate two phases ahead
- Review depth scales with the phase diff; the full pool is for plan close, not every phase
- The contrarian is a role in the prompt, not a new Ring agent
- Compose existing Ring reviewers via `agentType` — never re-list or re-implement the roster
- A wave returns only when verified — reject any that skipped review or contrarian
- Phase checkpoint is a user gate, not a formality
- Never launch on main/master without consent

## Verification Checklist
Before marking the plan complete:
- [ ] Each phase elaborated into dispatch-ready tasks against the real codebase before launch
- [ ] Each phase launched as one workflow harness (or the documented fallback batch)
- [ ] Every wave ran both the Review and Contrarian stages — verified in the returned report
- [ ] Every returned wave reviewed by the supervisor; `ISSUES` waves bounced into a fix wave
- [ ] Every RED phase produced a real failure inside the harness (output captured)
- [ ] Every task closed with an atomic, signed commit via ring:committing-changes
- [ ] Every phase boundary checkpointed with the user (or continuous mode pre-authorized)
- [ ] Plan document reflects final state (statuses, ticked tasks, recorded deviations)
- [ ] Full ring:reviewing-code pool run at plan close for production work
- [ ] Final commit / push offered to the user
```