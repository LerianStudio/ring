---
name: ring:detailing-tasks
description: "Detailing the first phase's epics into dispatch-ready tasks written inline into tasks.md — Context with file:line refs, implementation vision, exact Files, Verification, Done-when — prose over code, no vague tasks, no deferrals. Gate 8 of ring:using-pm-team Full Track; runs after ring:decomposing-phases-and-epics. Use when a phased plan passed Gate 7 and Phase 1 must become executable. Skip on Small Track or for later phases."
---

# Task Creation — Detailing the First Wave

## When to use

- Phased plan passed Gate 7 validation (phases + epics)
- Full Track workflow (2+ day features)
- Ready to make Phase 1 executable

## Skip when

- Small Track workflow → Phase 1 detailing happens inside ring:decomposing-phases-and-epics
- Phased plan not validated → complete Gate 7 first

## Sequence

**Runs before:** ring:planning-delivery
**Runs after:** ring:decomposing-phases-and-epics

## Related

**Canonical format:** the Task Format mirrors ring:writing-plans — that skill is the canonical source for task-authoring semantics (code snippet policy, vagueness rules). The skeleton below is self-contained for this gate.

---

Break each Phase 1 epic into dispatch-ready tasks. A task is close to a ready-to-use prompt: an implementer (agent or human) with zero codebase context should be able to start within a minute of reading it. The deliverable is **decisions**, not code.

**Detail ONLY Phase 1.** Later phases stay epic-level — they are elaborated during execution (ring:executing-plans or ring:running-dev-cycle), against the codebase as it exists after earlier phases land. Pre-written detail for Phase 3 is stale the moment Phase 1 ships.

## Task Format

```markdown
#### Task T-[epic].[seq]: [Action-oriented name]

- [ ] Done

**Context:** [why this task exists; what already exists in the codebase, with
`file.go:42`-style references]

**Implementation vision:** [the approach; key decisions already made; patterns
to follow or avoid; named edge cases and how each is handled]

**Files:**
- Create: `exact/path/to/file.go`
- Modify: `exact/path/to/existing.go:123-145`
- Test: `path/to/file_test.go`

**Verification:** [command to run + expected outcome]

**Done when:** [acceptance criteria]
```

- IDs: `T-1.1.1` = first task of epic E-1.1
- Use `file:line` references when pointing into existing code; exact paths for every file touched
- Multi-module topology: tasks inherit `Target:`, `Working Directory:`, and `Agent:` from their epic; add them per-task only when overriding

## Code Snippet Policy

Default is **prose, not code**. Include a snippet ONLY when prose cannot pin down the decision:

| Justified | Example |
|-----------|---------|
| Public contract other epics depend on | API signature, event schema, migration DDL |
| Non-obvious algorithm where the approach IS the decision | Custom balancing logic, conflict-resolution rule |
| Exact artifact where approximation breaks behavior | Config block, regex, SQL query |

If the snippet exists to "save the implementer time", delete it. If it exists because two epics would otherwise disagree about a contract, keep it.

## ⛔ No Vague Tasks

| Pattern | Why it fails |
|---------|--------------|
| "Add appropriate error handling" | WHICH errors, handled HOW? Decide here. |
| "Handle edge cases" | Name them, one by one. |
| "TBD" / "TODO" / "figure out during implementation" | The detailed wave admits no deferrals — that's what makes it dispatch-ready |
| Implementation vision that restates the task name | Vision = approach + decisions, not a paraphrase |
| Task referencing a contract no epic defines | Plan is internally inconsistent |

Deferrals ARE allowed in later-phase epics — that is the point of rolling wave. They are NOT allowed inside the detailed wave.

## Output — Living Document

Tasks are written **into `tasks.md`**, directly under their Phase 1 epic blocks. No separate subtasks directory.

After writing all tasks:
1. Flip Phase 1 `Status` to `Detailed` in the Phase Overview table
2. Leave the epic-level `## Summary` table untouched — it remains the ring:running-dev-cycle Status contract

During execution, the same elaboration is repeated for each subsequent phase by the executing workflow — this gate establishes the format and quality bar the elaboration follows.

## TDD Note

Tasks carry no test code. The implementer derives the failing test from the task's **Verification** intent at execution time (ring:test-driven-development governs RED→GREEN→REFACTOR). The task's job is to make the expected behavior unambiguous enough that the test writes itself.

## Gate 8 Validation Checklist

| Category | Requirements |
|----------|--------------|
| **Coverage** | Every Phase 1 epic fully broken into tasks; every Scope item of each epic maps to a task |
| **Dispatch-Readiness** | Every task has Context (with file:line refs into existing code), Implementation vision with decisions made, exact Files, Verification, Done-when |
| **Zero Context** | An implementer could start each task within a minute of reading it — no unstated assumptions |
| **Snippet Discipline** | Code only where the Code Snippet Policy justifies it |
| **Wave Discipline** | Later phases untouched (epic-level); Phase Overview shows Phase 1 as `Detailed` |
| **Consistency** | Contracts referenced across tasks agree; no task references an undefined contract |

**Gate Result:** ✅ PASS → Delivery Planning | ⚠️ CONDITIONAL (vague or incomplete tasks) | ❌ FAIL (deferrals in the detailed wave, or premature detail in later phases)
