---
name: shared-pattern:gate-cadence-classification
description: Classification of dev-cycle gates by execution cadence (task/epic/phase/cycle).
---

# Gate Cadence Classification

## Four Cadences

### Task Cadence
Runs for every task (Task N.M.T), the dispatch-ready unit under its epic. Input scoped to a single unit.
- Backend: Gate 0 (Implementation + TDD + coverage + docker-compose/local runtime + delivery verify)
- Frontend: Gate 0 (Implementation-owned quality), Gate 8 (Validation)

### Epic Cadence
Runs once per epic (Epic N.M), after all of its tasks complete their task-level gates. Input is
UNION of all the epic's tasks' changes.
- Backend: Gate 8 (Review — 9 default reviewers plus triggered specialists), Gate 9 (Validation — aggregates every task's acceptance criteria + one human approval, after Gate 8)
- Frontend: Gate 7 (Review)

### Phase Cadence
Runs once per phase transition, at the phase boundary (Step 11.5, "phase cadence"). A phase
groups epics and is elaborated one at a time (rolling wave). After the last epic of a phase
completes, the boundary fires exactly once: checkpoint with the user, then elaborate the next
phase's tasks before execution continues.
- Backend / Frontend: phase-boundary checkpoint + next-phase elaboration

### Cycle Cadence
Runs once per cycle at cycle end.
- Backend: Multi-Tenant Verify, dev-report, Final Commit
- Frontend: Final Commit (minimal cycle-level processing)

## Why Cadence Matters

Running epic-cadence gates at task cadence causes redundant work: cumulative diff
review has output that stabilizes at the epic boundary, not the task boundary.
The epic-level cumulative diff is strictly more informative for review than N
per-task fragments because interaction bugs between tasks are visible only in
the cumulative view.

Rolling-wave elaboration is the dual constraint: phases are detailed one at a time so
plan accuracy tracks current knowledge. Elaborating more than one phase ahead wastes the
detail because requirements shift before execution reaches it.

## Implementation Requirement

Sub-skills that run at epic cadence MUST accept aggregated input:
- `implementation_files`: array (union across all the epic's tasks)
- `gate0_handoffs`: array (one entry per task)

Sub-skills that run at task cadence MUST continue to accept scoped input:
- `implementation_files`: array (this task's changes only)
- `gate0_handoff`: object (this task's handoff)

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Running an epic-cadence gate per task is safer — more runs catch more bugs" | Epic-cadence review operates on the UNION of the epic's task outputs. Per-task firing wastes cycle time on in-flight code and loses cross-task visibility — interaction bugs between tasks are invisible until the cumulative view. | **MUST dispatch Gate 8 once per epic, after ALL its tasks have passed Gate 0; Gate 9 validation then runs once per epic after Gate 8.** |
| "I'll elaborate the next two or three phases now while I have context" | Elaborating more than one phase ahead defeats rolling wave — detail decays. Requirements and discovered constraints shift before execution reaches a far-out phase, so the early detail is rework. | **MUST elaborate exactly one phase ahead, at the phase boundary (Step 11.5). Detail the next phase only after the current phase's last epic completes.** |
| "A cycle-cadence gate can run at epic end — close enough" | Cycle-cadence checks like multi-tenant verification, migration-safety, and dev-report are aggregate checks. Firing them per epic inflates cycle duration and weakens signal. | **MUST defer cycle checks to Step 12.x of dev-cycle.** |
| "This epic has only one task, so cadence doesn't matter" | Cadence is a schema-level invariant enforced by `validate-gate-progression.sh` and the state-write paths documented in `running-dev-cycle/SKILL.md`. Bypassing it writes state to the wrong path and breaks the hook's progression check for the next epic that has multiple tasks. | **MUST follow the documented cadence regardless of task count. Treat single-task epics as "tasks: [epic-itself]" for state purposes.** |
| "I'll run all gates per task because the cycle is short anyway" | Cycle brevity does not license cadence violation. The cadence model is also how reviewers consume aggregate context; per-task firing produces incomplete review inputs. | **MUST classify each gate against this table before dispatch. When unclear, STOP and ask the orchestrator.** |
