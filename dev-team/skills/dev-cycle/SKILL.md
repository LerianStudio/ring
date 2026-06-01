---
name: ring:dev-cycle
description: |
  Lean backend development cycle orchestrator with implementation-owned quality.
  Backend engineers own TDD, coverage, docker-compose/local runtime, and delivery verification.
  Task-level review stays separate; user validation closes each subtask.
---

# Development Cycle Orchestrator

## When to use
- Starting a new development cycle with a task file
- Resuming an interrupted development cycle
- Need structured, gate-based task execution with quality checkpoints

## Skip when
- No tasks file exists
- Task is documentation-only or planning-only
- Frontend project (use ring:dev-cycle-frontend instead)


You orchestrate. Agents execute. You NEVER read, write, or edit source code directly.

## How This Works

Load tasks from PM output and execute the lean backend cycle. Backend implementation owns local runtime and quality so the flow does not dispatch separate QA, SRE, or DevOps gates.

**Announce at start:** "Using ring:dev-cycle lean backend flow."

## Gate Map

| Gate | Skill to Load | Agent to Dispatch | Cadence | Mode |
|------|---------------|-------------------|---------|------|
| 0 | ring:dev-implementation | ring:backend-engineer-* | Per subtask | Write + Run |
| 8 | ring:codereview | 9 default reviewers + triggered specialists in parallel | Per task | Run |
| 9 | ring:dev-validation | N/A (verification) | Per subtask | Run |

Gate 0 includes TDD RED/GREEN, coverage threshold enforcement, docker-compose/local runtime updates, basic health/observability verification, and delivery verification. Do not dispatch separate QA, SRE, or DevOps gates as part of this cycle.

## Execution Order

```yaml
for each task:

  # SUBTASK-LEVEL implementation (per subtask, or task-itself if no subtasks)
  for each subtask:
    Gate 0
    [checkpoint if manual_per_subtask mode]

  # TASK-LEVEL review (once per task, after all subtasks are ready for review)
  Gate 8

  # SUBTASK-LEVEL validation (after task review passes)
  for each subtask:
    Gate 9

# CYCLE-END (once, after all tasks done) — see "Cycle Completion" section; read gates/cycle-completion.md
Final Test Confirmation → Multi-Tenant Verify → Migration Safety (Gate 0.5D, conditional) → dev-report → Final Commit
```

## Gate Execution Workflow

For EVERY gate, follow this exact sequence:

```
1. Read gate-specific instructions  → Gate 0: Read("gates/gate-0-implementation.md"); Gate 8: Read("gates/gate-8-review.md"); Gate 9: Read("gates/gate-9-validation.md")
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

State lives in `docs/ring:dev-cycle/current-cycle.json` (or `docs/ring:dev-refactor/current-cycle.json`).

For state schema, persistence rules, and initialization logic, read `gates/state-schema.md` from this skill directory.

**Critical rule:** Write state after EVERY gate completion. If state write fails → STOP. Never proceed without persisted state.

## PROJECT_RULES.md Check

Before starting any gate execution, verify `docs/PROJECT_RULES.md` exists.

For the full verification process and template creation flow, read `gates/project-rules-check.md` from this skill directory.

If PROJECT_RULES.md doesn't exist → create it using the Ring template before proceeding.

## Cycle Completion

When the task loop in Execution Order finishes (last task passed all its gates), the cycle is NOT done — a completion phase runs once.

Read `gates/cycle-completion.md` from this skill directory and execute Steps 12.0–12.1 in order:

1. **Step 12.0** — Final Test Confirmation (HARD GATE: every Gate 0 handoff has passing tests, coverage ≥ threshold, local runtime verified)
2. **Step 12.0.5** — Multi-tenant dual-mode verification (post-cycle sanity check)
3. **Step 12.0.5b** — Gate 0.5D Migration Safety (conditional: runs only when SQL migration files appear in the cycle diff vs `origin/main`)
4. **Step 12.1** — Final Commit + the one-and-only `ring:dev-report` dispatch

⛔ The cycle is incomplete until Step 12.1 finishes. Do NOT declare the cycle done from the Execution Order summary alone — the detailed, mandatory steps live in `gates/cycle-completion.md`.

## Execution Modes

Ask user at cycle start:

| Mode | Behavior |
|------|----------|
| `automatic` | All gates execute, pause only on failure |
| `manual_per_task` | Checkpoint after each task completes all gates |
| `manual_per_subtask` | Checkpoint after each subtask completes subtask-level gates |

Mode affects CHECKPOINTS (user approval pauses), not GATES. All listed gates execute regardless of mode.

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

- Gate 0 (implementation): Commit after GREEN phase, coverage, docker-compose/local runtime, and delivery verification pass
- Gate 8 (review): Commit fixes after all reviewers pass
- Gate 9 (validation): No commit (verification only)
- Cycle-end: Final commit with cycle metadata

Convention: `feat|fix|test|chore(scope): description` — keep commits atomic per gate.

## Blocker Handling

| Blocker | Action |
|---------|--------|
| Gate failure (tests not passing, review failed) | STOP. Cannot proceed to next gate. |
| Missing PROJECT_RULES.md | STOP. Create using template. |
| Agent error | STOP. Diagnose and report. |
| Architectural decision needed | STOP. Present options to user. |

## Gate Completion Rules

A gate is complete ONLY when ALL components succeed:
- Gate 0: TDD RED + GREEN + coverage ≥ 85% + all acceptance criteria tested + docker-compose/local runtime verified + delivery verification (all requirements delivered, 0 dead code)
- Gate 8: all 9 default reviewers pass, and any triggered conditional specialist also passes.
- Gate 9: Explicit "APPROVED" from user

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
| Context limit reached | Use `/ring:create-handoff` → resume in new session |

## Input Sources

| Source | Path |
|--------|------|
| Tasks (PM output) | `docs/pre-dev/{feature}/tasks.md` |
| Subtasks | `docs/pre-dev/{feature}/subtasks/{task-id}/ST-XXX-01.md` |
| Refactor tasks | `docs/ring:dev-refactor/*/tasks.md` |

## Frontend Handoff

If frontend tasks are detected in a backend cycle → create a handoff file listing frontend requirements, API contracts, and test expectations. Frontend uses `ring:dev-cycle-frontend` separately.
