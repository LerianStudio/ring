---
name: shared-pattern:gate-cadence-classification
description: Classification of dev-cycle gates by execution cadence (subtask/task/cycle).
---

# Gate Cadence Classification

## Three Cadences

### Subtask Cadence
Runs for every subtask (or task itself if no subtasks). Input scoped to a single unit.
- Backend: Gate 0 (Implementation + TDD + coverage + docker-compose/local runtime + delivery verify)
- Frontend: Gate 0 (Implementation-owned quality), Gate 8 (Validation)

### Task Cadence
Runs once per task, after all subtasks complete their subtask-level gates. Input is
UNION of all subtasks' changes.
- Backend: Gate 8 (Review — 9 default reviewers plus triggered specialists), Gate 9 (Validation — aggregates every subtask's acceptance criteria + one human approval, after Gate 8)
- Frontend: Gate 7 (Review)

### Cycle Cadence
Runs once per cycle at cycle end.
- Backend: Multi-Tenant Verify, dev-report, Final Commit
- Frontend: Final Commit (minimal cycle-level processing)

## Why Cadence Matters

Running task-cadence gates at subtask cadence causes redundant work: cumulative diff
review has output that stabilizes at the task boundary, not the subtask boundary.
The task-level cumulative diff is strictly more informative for review than N
per-subtask fragments because interaction bugs between subtasks are visible only in
the cumulative view.

## Implementation Requirement

Sub-skills that run at task cadence MUST accept aggregated input:
- `implementation_files`: array (union across all subtasks of the task)
- `gate0_handoffs`: array (one entry per subtask)

Sub-skills that run at subtask cadence MUST continue to accept scoped input:
- `implementation_files`: array (this subtask's changes only)
- `gate0_handoff`: object (this subtask's handoff)

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Running a task-cadence gate per subtask is safer — more runs catch more bugs" | Task-cadence review operates on the UNION of subtask outputs. Per-subtask firing wastes cycle time on in-flight code and misses cross-subtask interaction bugs. | **MUST dispatch Gate 8 once per task, after ALL subtasks have passed Gate 0; Gate 9 validation then runs once per task after Gate 8.** |
| "A cycle-cadence gate can run at task end — close enough" | Cycle-cadence checks like multi-tenant verification, migration-safety, and dev-report are aggregate checks. Firing them per task inflates cycle duration and weakens signal. | **MUST defer cycle checks to Step 12.x of dev-cycle.** |
| "This task has only one subtask, so cadence doesn't matter" | Cadence is a schema-level invariant enforced by `validate-gate-progression.sh` and the state-write paths documented in `dev-cycle/SKILL.md`. Bypassing it writes state to the wrong path and breaks the hook's progression check for the next task that has multiple subtasks. | **MUST follow the documented cadence regardless of subtask count. Treat single-subtask tasks as "subtasks: [task-itself]" for state purposes.** |
| "I'll run all gates per subtask because the cycle is short anyway" | Cycle brevity does not license cadence violation. The cadence model is also how reviewers consume aggregate context; per-subtask firing produces incomplete review inputs. | **MUST classify each gate against this table before dispatch. When unclear, STOP and ask the orchestrator.** |
