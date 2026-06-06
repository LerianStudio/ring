---
name: ring:running-dev-cycle
description: "Running the backend dev cycle: implements every task in a rolling-wave tasks.md plan for a Go/TS service, driving specialist agents through Gate 0 implementation/TDD, Gate 8 parallel review, and Gate 9 validation per epic, elaborating later phases at each phase boundary. Use when starting or resuming a gated backend dev cycle with a tasks.md plan. Skip for frontend (use ring:running-dev-cycle-frontend) or docs-only work."
---

# Development Cycle Orchestrator

## When to use
- Starting a new development cycle with a phased plan (tasks.md from pre-dev)
- Resuming an interrupted development cycle
- Need structured, gate-based epic execution with quality checkpoints and phase cadence

## Skip when
- No tasks file exists
- Task is documentation-only or planning-only
- Frontend project (use ring:running-dev-cycle-frontend instead)


You orchestrate. Agents execute. You NEVER read, write, or edit source code directly.

## How This Works

Load the phased plan (tasks.md) from PM output and execute the lean backend cycle. tasks.md is a rolling-wave phased plan: a `## Phase Overview` table (phases + milestone + status), a `## Summary` table whose rows are epics (E-X.Y), and inline dispatch-ready tasks (T-X.Y.Z) written under each epic of the currently-detailed wave. Only the active wave is task-detailed; later phases are epic-level and get elaborated at each phase boundary. Backend implementation owns local runtime and quality so the flow does not dispatch separate QA, SRE, or DevOps gates.

**Vocabulary:** Phase = independently verifiable milestone. Epic (E-X.Y) = value-driven increment, the UNIT this cycle iterates. Task (T-X.Y.Z) = dispatch-ready unit, the Gate 0 execution unit.

**Announce at start:** "Using ring:running-dev-cycle lean backend flow (rolling-wave phased plan)."

## Gate Map

| Gate | Skill to Load | Agent to Dispatch | Cadence | Mode |
|------|---------------|-------------------|---------|------|
| 0 | ring:implementing-tasks | ring:backend-go / ring:backend-ts | Per task (T-X.Y.Z) | Write + Run |
| 8 | ring:reviewing-code | 9 default reviewers + triggered specialists in parallel | Per epic (E-X.Y) | Run |
| 9 | ring:validating-acceptance-criteria | N/A (verification) | Per epic | Run |
| 11.5 | (orchestrator + 1 planning agent) | ring:backend-go / ring:backend-ts / ring:frontend / ring:codebase-explorer (ANALYSIS mode) | Per phase boundary | Plan only |

Gate 0 includes TDD RED/GREEN, coverage threshold enforcement, docker-compose/local runtime updates, basic health/observability verification, and delivery verification. Do not dispatch separate QA, SRE, or DevOps gates as part of this cycle. Step 11.5 (phase cadence) closes the just-finished phase and rolling-wave elaborates the next phase's epics into dispatch-ready tasks — read `gates/phase-boundary.md`.

## Execution Order

```yaml
for each phase (current wave; starts at Phase 1, the only detailed phase at init):

  for each epic in this phase (Summary order):

    # 1. TASK-LEVEL build (per task T-X.Y.Z, or epic-itself if no task breakdown)
    for each task:
      Gate 0  # build task
      [checkpoint if manual_per_task mode]

    # 2. EPIC-LEVEL review (once per epic, after all tasks are built)
    Gate 8  # review whole epic — 9 parallel reviewers see cumulative diff

    # 3-4. Fix CRITICAL/HIGH/MEDIUM, then re-review until clean (inside Gate 8)

    # 5. EPIC-LEVEL validation (once per epic, after review passes)
    Gate 9  # validate whole epic — aggregate EVERY task's acceptance criteria + ONE human approval
            # criterion FAIL → back to Gate 0 for that task, then re-review (step 2) → re-validate

    # 6. "Proceed to next epic?" checkpoint (Step 11.1) → next epic in this phase

  # 7. PHASE BOUNDARY (Step 11.5, after the LAST epic of the phase is approved) — read gates/phase-boundary.md
  #    close phase (Phase Overview → Complete, record deviations) →
  #    phase checkpoint (manual: ask Continue/Pause/Adjust | auto: log + continue) →
  #    elaborate next phase's epics into dispatch-ready tasks (1 planning agent, ANALYSIS mode) →
  #    validate elaboration → resume epic loop at Gate 0 for the new phase
  #    (no next phase → fall through to cycle-end)

# 8. CYCLE-END (once, after the LAST phase completes its boundary) — see "Cycle Completion"; read gates/cycle-completion.md
Final Test Confirmation → Multi-Tenant Verify → Migration Safety (Gate 0.5D, conditional) → dev-report → Final Commit
```

## Gate Execution Workflow

For EVERY gate, follow this exact sequence:

```
1. Read gate-specific instructions  → Gate 0: Read("gates/gate-0-implementation.md"); Gate 8: Read("gates/gate-8-review.md"); Gate 9: Read("gates/gate-9-validation.md"); Phase boundary (Step 11.5): Read("gates/phase-boundary.md")
2. Load sub-skill                   → Skill("ring:{sub-skill-name}")
3. Follow sub-skill dispatch rules  → Sub-skill tells you HOW to dispatch
4. Dispatch agent                   → Task(subagent_type="ring:{agent}", ...)
5. Validate agent output            → Per sub-skill validation rules
6. Update state                     → Write to current-cycle.json
7. Next gate or checkpoint
```

Never dispatch an agent without loading the sub-skill first.
Never skip from standards → agent directly. Always: standards → sub-skill → agent.

## Standards Loading

At cycle start (Step 1.5), pre-cache Ring standards:

1. WebFetch the standards index for the project language (e.g., `golang/index.md`)
2. Store cached standards in `state.cached_standards`
3. Pass relevant modules to agents at dispatch time — do NOT re-fetch per gate

## Orchestrator Boundaries

**You CAN:** Read task/state files, write state files, track progress, dispatch agents, ask user questions, WebFetch standards.

**You CANNOT:** Read/write/edit source code (*.go, *.ts, *.tsx), run tests, analyze code directly, make architectural decisions.

If a task involves source code → dispatch specialist agent. No exceptions regardless of file count or simplicity.

## State Management

State lives in `docs/ring:running-dev-cycle/current-cycle.json` (or `docs/ring:planning-backend-refactor/current-cycle.json`).

For state schema, persistence rules, and initialization logic, read `gates/state-schema.md` from this skill directory.

**Critical rule:** Write state after EVERY gate completion. If state write fails → STOP. Never proceed without persisted state.

## PROJECT_RULES.md Check

Before starting any gate execution, verify `docs/PROJECT_RULES.md` exists.

For the full verification process and template creation flow, read `gates/project-rules-check.md` from this skill directory.

If PROJECT_RULES.md doesn't exist → create it using the Ring template before proceeding.

## Cycle Completion

When the epic loop finishes the LAST phase (last epic of the last phase passed all its gates AND that phase's boundary at Step 11.5 found no next phase to elaborate), the cycle is NOT done — a completion phase runs once.

Read `gates/cycle-completion.md` from this skill directory and execute Steps 12.0–12.1 in order:

1. **Step 12.0** — Cycle Exit Verification (HARD GATE: every Gate 0 handoff has passing tests, coverage ≥ threshold, local runtime; plus multi-tenant dual-mode verified for all units)
2. **Step 12.0.5b** — Gate 0.5D Migration Safety (conditional: runs only when SQL migration files appear in the cycle diff vs `origin/main`)
3. **Step 12.1** — the one-and-only `ring:writing-dev-reports` dispatch, then Final Commit (which captures the feedback it generates)

⛔ The cycle is incomplete until Step 12.1 finishes. Do NOT declare the cycle done from the Execution Order summary alone — the detailed, mandatory steps live in `gates/cycle-completion.md`.

## Execution Modes

Ask user at cycle start (two independent questions):

**1. Execution mode** (epic/task checkpoint cadence):

| Mode | Behavior |
|------|----------|
| `automatic` | All gates execute, pause only on failure |
| `manual_per_epic` | Checkpoint after each epic completes all gates |
| `manual_per_task` | Checkpoint after each task completes task-level gates |

**2. Phase checkpoint** (`state.phase_checkpoint`):

| Value | Behavior |
|-------|----------|
| `manual` (default) | At each phase boundary (Step 11.5), AskUserQuestion: Continue / Pause / Adjust plan first |
| `auto` | At each phase boundary, log a phase summary and continue (still elaborates the next phase) |

Mode and phase_checkpoint affect CHECKPOINTS (user approval pauses), not GATES. All listed gates execute regardless of mode. The phase boundary's elaboration step runs in BOTH phase_checkpoint values — only the pause differs.

## Custom Instructions

If user provides custom context at cycle start, store in `state.custom_prompt` and inject at the top of every agent dispatch:

```
**CUSTOM CONTEXT (from user):**
{state.custom_prompt}

---

**Standard Instructions:**
[... agent prompt ...]
```

## Commit Timing

- Gate 0 (implementation): Commit after GREEN phase, coverage, docker-compose/local runtime, and delivery verification pass (`commit_timing == "per_task"`)
- Gate 8 (review): Commit fixes after all reviewers pass
- Gate 9 (validation): No commit (verification only); epic-level commit at Step 11.1 when `commit_timing == "per_epic"`
- Cycle-end: Final commit with cycle metadata

`commit_timing ∈ {per_task, per_epic, at_end}`. Convention: `feat|fix|test|chore(scope): description` — keep commits atomic per gate.

## Blocker Handling

| Blocker | Action |
|---------|--------|
| Gate failure (tests not passing, review failed) | STOP. Cannot proceed to next gate. |
| Missing PROJECT_RULES.md | STOP. Create using template. |
| Agent error | STOP. Diagnose and report. |
| Architectural decision needed | STOP. Present options to user. |

## Gate Completion Rules

A gate is complete ONLY when ALL components succeed:
- Gate 0 (per task): TDD RED + GREEN + coverage ≥ 85% + all acceptance criteria tested + docker-compose/local runtime verified + delivery verification (all requirements delivered, 0 dead code)
- Gate 8 (per epic): all 9 default reviewers pass, and any triggered conditional specialist also passes.
- Gate 9 (per epic): every task's acceptance criteria aggregated and marked PASS + explicit "APPROVED" from user
- Phase boundary (Step 11.5): phase closed (Phase Overview → Complete, deviations recorded) + next phase elaborated and validated (or no next phase) + checkpoint honored per `phase_checkpoint`

## Severity of Issues

- CRITICAL/HIGH/MEDIUM found in review → Fix NOW, re-run the selected review pool
- LOW → Keep in the review report if actionable; do not add source comments during review
- Cosmetic → Add `FIXME(nitpick):` comment

## Error Recovery

| Scenario | Recovery |
|----------|----------|
| Agent returns error | Retry with clearer instructions (max 3 attempts) |
| State file corrupted | Rebuild from git log + last known state |
| Gate stuck in loop | After 3 iterations, escalate to user |
| Context limit reached | Use `/ring:creating-handoffs` → resume in new session |

## Input Sources

| Source | Path |
|--------|------|
| Tasks (PM output) | `docs/pre-dev/{feature}/tasks.md` |
| Phase tasks | inside tasks.md, under each epic (phased plan) |
| Refactor tasks | `docs/ring:planning-backend-refactor/*/tasks.md` |

## Frontend Handoff

If frontend tasks are detected in a backend cycle → create a handoff file listing frontend requirements, API contracts, and test expectations. Frontend uses `ring:running-dev-cycle-frontend` separately.
