---
name: ring:dev-cycle-frontend
description: |
  Frontend development cycle orchestrator with lean gates. Loads tasks from PM team output
  or backend handoff and executes through Gate 0 implementation-owned checks,
  Gate 7 review, and Gate 8 validation.
---

# Frontend Development Cycle Orchestrator

## When to use
- Starting a new frontend development cycle with a task file
- Resuming an interrupted frontend development cycle (--resume flag)
- After backend dev cycle completes (consuming handoff)

## Skip when
- No tasks file exists
- Task is documentation-only or planning-only
- Backend project — use ring:dev-cycle instead

## Sequence
**Runs before:** ring:dev-report


You orchestrate. Agents execute. NEVER read/write/edit source files (*.ts, *.tsx, *.jsx, *.css) directly.
All code changes go through `Task(subagent_type=...)`. Announce at start: "Using ring:dev-cycle-frontend with lean gate flow (Gate 0, 7, 8)."

## Step 0: Pre-Execution Setup (MANDATORY)

```
1. Detect UI library: Read package.json
   - "@lerianstudio/sindarian-ui" present → ui_library_mode = "sindarian-ui"
   - Otherwise → ui_library_mode = "fallback-only"
   Store in state.

2. Pre-cache standards (once):
   WebFetch → https://raw.githubusercontent.com/LerianStudio/ring/main/CLAUDE.md
   WebFetch → https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/frontend.md
   WebFetch → testing-accessibility.md, testing-visual.md, testing-e2e.md, testing-performance.md, devops.md, sre.md
   Store in state.cached_standards.

3. Load backend handoff if available: docs/ring:dev-cycle/handoff-frontend.json

4. Verify PROJECT_RULES.md exists → STOP if missing.

5. Ask execution mode: automatic | manual_per_epic | manual_per_task
```

## Gate Map

| Gate | Cadence | Skill | Agent | Purpose |
|------|---------|-------|-------|---------|
| 0 | task | ring:dev-implementation | ring:frontend-engineer / ring:ui-engineer / ring:frontend-bff-engineer-typescript | TDD, coverage, accessibility, visual/E2E/perf checks, local runtime |
| 7 | epic | ring:codereview | 9 defaults + triggered specialists via ring:codereview | Code review |
| 8 | task | ring:dev-validation | User | Acceptance sign-off |

All listed gates are MANDATORY. No exceptions.

## Gate Agent Selection (Gate 0)

| Condition | Agent |
|-----------|-------|
| React/Next.js component | ring:frontend-engineer |
| Design system / Sindarian UI | ring:ui-engineer |
| BFF / API aggregation | ring:frontend-bff-engineer-typescript |
| Mixed | frontend-engineer first, then frontend-bff-engineer-typescript |

Pass `ui_library_mode` to every Gate 0 agent.

## Frontend TDD Policy

| Component Layer | TDD Required? | When |
|-----------------|---------------|------|
| Custom hooks | YES — RED→GREEN | Gate 0 |
| Form validation | YES — RED→GREEN | Gate 0 |
| State management | YES — RED→GREEN | Gate 0 |
| Conditional rendering | YES — RED→GREEN | Gate 0 |
| API integration | YES — RED→GREEN | Gate 0 |
| Layout / styling | NO — test-after | Gate 0 visual checks |
| Animations | NO — test-after | Gate 0 visual checks |
| Static presentational | NO — test-after | Gate 0 visual checks |

## Execution Order

```yaml
for each epic:
  for each task:
    Gate 0
    [checkpoint if manual_per_task]

  # epic-level (after all tasks)
  Gate 7

  # task-level validation after review passes
  for each task:
    Gate 8

  [checkpoint if manual_per_epic]

  # phase boundary — fires once, after the last epic of the current phase
  [if epic is last in its phase: Phase Cadence (see below)]
```

## Phase Boundary (Rolling Wave)

Phases group epics and are elaborated one at a time. After the last epic of the current
phase completes its Gate 0/7/8 flow, fire the phase boundary exactly once:

```
1. Checkpoint with the user: summarize the completed phase (epics done, review/validation
   outcomes) and confirm intent to continue.
2. Elaborate the next phase's tasks inline under each epic, following the
   ring:pre-dev-task-creation format (Context, Implementation vision, Files, Verification,
   Done when). Detail exactly one phase ahead — never further.
3. Set state.current_phase to the next phase and resume execution from its first epic.
```

Do not elaborate more than one phase ahead — detail decays before execution reaches it.

## Gate Execution Workflow (MANDATORY for every gate)

```
1. Skill("[sub-skill-name]")
2. Follow sub-skill dispatch rules
3. Task(subagent_type=...)
4. Validate output
5. Write state
6. Next gate
```

Sub-skill MUST be loaded before dispatching the agent.

## Gate 7: Reviewers

Invoke `Skill("ring:codereview")`. The codereview skill dispatches its 9 default reviewers plus triggered conditional specialists in parallel and applies its own pass/fail rules.

## Gate Completion Criteria

| Gate | Required for COMPLETE |
|------|-----------------------|
| 0 | TDD RED captured (behavioral) + GREEN passes; visual: implementation complete |
| 7 | ring:codereview PASS (all 9 defaults and triggered specialists) |
| 8 | Explicit "APPROVED" from user |

Former Gates 1-6 checks are owned by Gate 0 implementation and local verification.

## State Management

State: `docs/ring:dev-cycle-frontend/current-cycle.json` (state schema v2.0.0).

Write after EVERY gate. If write fails → STOP.

```json
{
  "schema_version": "2.0.0",
  "ui_library_mode": "",
  "tasks_file": "",
  "execution_mode": "",
  "current_gate": 0,
  "phases": [],
  "current_phase": "",
  "phase_checkpoint": {},
  "epics": [],
  "current_epic_index": 0,
  "current_task_index": 0,
  "gates_completed": {},
  "cached_standards": {}
}
```

Each entry in `epics[]` (E-X.Y) carries its own `tasks[]` array (T-X.Y.Z). Gate 0/8
run at task cadence over `epics[current_epic_index].tasks[current_task_index]`; Gate 7
runs at epic cadence over the union of that epic's tasks.

## Blocker Handling

| Blocker | Action |
|---------|--------|
| Gate failure | STOP. Fix before proceeding. |
| Missing PROJECT_RULES.md | STOP. Create using template. |
| Standards WebFetch fails | STOP. Report. |
| Architectural decision needed | STOP. Present options to user. |
