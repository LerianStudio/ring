---
name: ring:writing-plans
description: "Writing a rolling-wave phased implementation plan from a spec before coding: a phase-epic-task hierarchy where Phase 1 is detailed into dispatch-ready tasks and later phases stay epic-level for elaboration during execution. Use when a multi-file feature needs decomposition; runs after ring:exploring-codebases or pre-dev gates, hands off to ring:executing-plans or ring:running-dev-cycle. Skip for single-file changes or spikes."
---

# Writing Plans

## When to use
- Spec or requirements exist for a multi-step task and no implementation has started
- Feature spans multiple files/layers and needs decomposition before coding
- Handing off implementation to a separate session, agent, or human

## Skip when
- Single-file change with obvious shape (just do it)
- Exploratory spike — phased plans assume known requirements
- Spec is still in brainstorming; the plan would lock premature decisions

## Sequence
**Runs after:** ring:exploring-codebases, ring:planning-large-features (gates 0-6 artifacts) or ring:planning-small-features (gates 0-2 artifacts) — their outputs feed the spec
**Runs before:** ring:executing-plans (rolling-wave execution) or ring:running-dev-cycle (gated subagent workflow)

## Related
**Companion:** [plan-document-reviewer-prompt.md](plan-document-reviewer-prompt.md) — subagent dispatch template for thorough plan review

---

Write the plan assuming the implementer is skilled but has zero context for this codebase, toolset, or problem domain.

The plan is a **rolling-wave document**. Only the first phase is detailed to task level at plan time; later phases stay at epic level until execution reaches them. Detail decays: code written in Phase 1 invalidates assumptions baked into Phase 3 tasks, so do not write Phase 3 tasks yet. ring:executing-plans elaborates each subsequent phase against the codebase as it actually exists.

**Announce at start:** "Using ring:writing-plans to author the implementation plan."

**Default save path:** `docs/plans/YYYY-MM-DD-<feature-name>.md`
(User preferences override.)

**Invoked from pre-dev:** when dispatched as the final gate of ring:planning-large-features or ring:planning-small-features, the spec inputs are the pre-dev artifacts — trd.md (plus feature-map.md, openapi.yaml, the schema file, and dependencies.md on the Large track). On Large, plan phases MUST mirror feature-map.md phases one-to-one. Output path is `docs/pre-dev/{feature}/plan.md`, overriding the default above; standalone invocations keep the default. plan.md is always a SINGLE document per feature: on multi-module topologies (monorepo fullstack / multi-repo), each epic carries one line `**Target:** backend | frontend | infra` (placed right before `**Status:**`); for multi-repo features the orchestrator copies plan.md into each repo and the local dev-cycle executes only epics whose Target matches that repo. No per-module plan splits.

## Plan Language

Before authoring, ask which language the plan's **prose** should be written in — using the question/ask tool the harness provides (e.g. `AskUserQuestion` in Claude Code). Offer three options: **English** (default), **Brazilian Portuguese (pt-BR)**, **Spanish**. If the user skips or no question tool is available, default to English.

The choice covers narrative prose only — Goal, Architecture, Context, Implementation vision, and other descriptions. Everything a downstream skill or agent parses stays verbatim English regardless of choice: section headers and format keywords, `**Status:**` values (Pending/Doing/Done/Failed), Phase-Overview status cells (Detailed/Epic-level/Complete), `**Target:**` values, file paths, commands, code snippets, and identifiers. Translating those breaks ring:executing-plans and ring:running-dev-cycle status matching.

## Standards

Do NOT fetch standards documents while planning — standards compliance is enforced by the implementation agents and reviewers downstream. Plans reference DRY, YAGNI, and TDD generically.

## Blocker — STOP and Report

Do not write a plan on a shaky foundation. STOP and ask when:

| Situation | Action |
|-----------|--------|
| Vague requirements ("make it better", "add feature") | STOP. Ask: "What specific behavior should change?" |
| Missing success criteria | STOP. Ask: "How do we verify this works?" |
| Unknown codebase structure (can't locate files) | STOP. Run ring:exploring-codebases first, then plan |
| Conflicting constraints | STOP. Ask: "Which constraint takes priority?" |
| Multiple valid architectures without guidance | STOP. Ask: "Which pattern should we use?" |

## Scope Check

If the spec covers multiple independent subsystems, suggest breaking it into separate plans — one per subsystem. Each plan must produce working, testable software on its own.

If brainstorming already split the spec into sub-project specs, write one plan per sub-spec.

## Plan Hierarchy

| Level | Granularity | When detailed |
|-------|-------------|---------------|
| **Phase** | Independently verifiable milestone — software works at the end of every phase | At plan time |
| **Epic** | Cohesive unit of work inside a phase (one capability, one subsystem) | At plan time |
| **Task** | Dispatch-ready unit: context + implementation vision + verification | Phase 1 at plan time; later phases during execution (rolling wave) |

Rules:
- Every phase ends with working, testable software. No phase ends mid-refactor.
- 2–5 epics per phase. An epic that needs more than a paragraph to describe is two epics.
- Order phases by dependency first, then by risk — front-load whatever invalidates the design if it turns out wrong.

## Code Snippet Policy

Default is **prose, not code**. Describe intent, decisions, and shape; the implementer writes the code at execution time with the real codebase in front of them.

Include a snippet ONLY when prose cannot pin down the decision:

| Justified | Example |
|-----------|---------|
| Public contract other epics depend on | API signature, event schema, migration DDL |
| Non-obvious algorithm where the approach IS the decision | Custom balancing logic, conflict-resolution rule |
| Exact artifact where approximation breaks behavior | Config block, regex, SQL query |

If the snippet exists to "save the implementer time", delete it. If it exists because two epics would otherwise disagree about a contract, keep it.

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For implementers:** Use ring:executing-plans (rolling wave: dispatch each
> wave — a phase or one epic, your choice — as a workflow → review → user
> checkpoint → detail the next phase against the real code → repeat),
> ring:dispatching-workflows to run each phase as a reviewed multi-agent
> workflow (review + contrarian baked in), or ring:running-dev-cycle for the
> full subagent-orchestrated workflow.
> This document is the living source of truth — task elaboration for later
> phases is written back into it during execution.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

## Phase Overview

| Phase | Milestone | Epics | Status |
|-------|-----------|-------|--------|
| 1 | [what works at the end] | 1.1, 1.2 | Detailed |
| 2 | [what works at the end] | 2.1, 2.2 | Epic-level |
| 3 | [what works at the end] | 3.1 | Epic-level |

---
```

## Epic Format (all phases)

```markdown
### Epic N.M: [Name]

**Goal:** [what exists and works when this epic is done]
**Scope:** [subsystems/directories touched — coarse-grained for later phases]
**Dependencies:** [epics or phases that must land first, or "none"]
**Done when:** [observable acceptance criteria]
**Status:** Pending
```

`**Status:**` lifecycle: Pending → Doing → Done | Failed. It is the write target for ring:running-dev-cycle epic checkpoints; ring:executing-plans may ignore it.

For Phase 1 epics, tasks follow immediately below the epic block. For later phases, the epic block is the whole entry — tasks are added during execution.

## Task Format (detailed wave only)

Each task is close to a ready-to-dispatch prompt: an implementer with zero context should be able to start within a minute of reading it.

```markdown
#### Task N.M.T: [Action-oriented name]

- [ ] Done

**Context:** [why this task exists; what already exists, with `file.go:42`-style
references into the current codebase]

**Implementation vision:** [the approach; key decisions already made; patterns
to follow or avoid; named edge cases and how each is handled]

**Files:**
- Create: `exact/path/to/file.go`
- Modify: `exact/path/to/existing.go:123-145`
- Test: `path/to/file_test.go`

**Verification:** [command to run + expected outcome]

**Done when:** [acceptance criteria]
```

Use `file:line` references when pointing into existing code. Paths are always exact for every file touched.

## ⛔ No Vague Tasks

The plan's deliverable is **decisions**, not code. A task without decisions is a plan failure:

| Pattern | Why it fails |
|---------|--------------|
| "Add appropriate error handling" | WHICH errors, handled HOW? Decide in the plan. |
| "Handle edge cases" | Name them, one by one. |
| "TBD" / "TODO" / "figure out during implementation" in detailed-wave tasks | The detailed wave admits no deferrals — that's what makes it dispatch-ready |
| Implementation vision that restates the task name | Vision = approach + decisions, not a paraphrase |
| Task referencing a contract no epic defines | Plan is internally inconsistent |

Deferrals ARE allowed in later-phase epics — that is the point of rolling wave. They are NOT allowed inside the detailed wave.

## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch.

| Check | What to verify |
|-------|----------------|
| **Spec coverage** | Skim each requirement in the spec. Point to an epic that covers it. List gaps. |
| **Vagueness scan** | Search detailed-wave tasks for the red flags in "No Vague Tasks". Fix any matches. |
| **Contract consistency** | Names, signatures, and schemas referenced across epics agree. A contract defined nowhere but used somewhere is a bug. |
| **Phase boundaries** | Every phase ends with working, verifiable software. |
| **Verification plausibility** | Detailed-wave verification commands target real paths and plausible outcomes. |

If you find issues, fix them inline. No need to re-review — just fix and move on.

**For high-stakes plans** (large surface, multiple authors, critical path): also dispatch a plan-document reviewer subagent using the template in `plan-document-reviewer-prompt.md`.

## Execution Handoff

After saving the plan, announce the save, then collect the execution choice **using the question/ask tool the harness provides** (e.g. `AskUserQuestion` in Claude Code). If no question tool is available, present the options as a prose prompt and ask which to use. The three options:

> Plan complete and saved to `docs/plans/<filename>.md`. Pick how to execute it:
>
> **1. Rolling-Wave Execution (this session)** — Use ring:executing-plans: you supervise while one workflow per wave-unit (a whole phase, or one epic at a time — you choose at start) implements its tasks; you review what returns, checkpoint, then elaborate the next phase into tasks against the real landed code, and repeat. Lightest: one supervised subagent per wave, reviewed after it returns. Best for iterative delivery with course-correction between waves.
>
> **2. Reviewed Multi-Agent Workflows (this session)** — Use ring:dispatching-workflows: the same rolling wave, but each phase runs as a multi-agent workflow harness that implements, reviews, and runs an adversarial contrarian pass internally before returning verified work. Best when you want review and a contrarian baked into every wave, without the full gated cycle.
>
> **3. Subagent-Orchestrated (ring:running-dev-cycle)** — lean backend cycle (Gate 0/8/9) with parallel specialist dispatch. Heaviest: full review pool per epic. Best for production work that must pass through the full review pool.

**If Rolling-Wave chosen:** Continue with ring:executing-plans in this session.

**If Reviewed Multi-Agent Workflows chosen:** Continue with ring:dispatching-workflows in this session.

**If Subagent-Orchestrated chosen:** Hand off to ring:running-dev-cycle, which owns implementation across the lean cycle (Gate 0 per task, Gates 8/9 per epic, phase boundaries per phase).

## Verification Checklist

Before marking the plan complete:
- [ ] Plan language confirmed with user (prose only; structural tokens, paths, and code stay English)
- [ ] Plan header present (Goal, Architecture, Tech Stack, Phase Overview)
- [ ] Every phase ends in working, testable software
- [ ] Every epic has Goal, Scope, Dependencies, Done-when, Status
- [ ] Phase 1 epics fully broken into dispatch-ready tasks; later phases epic-level only
- [ ] No vague tasks in the detailed wave (no "appropriate", "TBD", unnamed edge cases)
- [ ] Code snippets only where the Code Snippet Policy justifies them
- [ ] Contract consistency across epics
- [ ] Self-review checklist applied
- [ ] Plan saved to `docs/plans/YYYY-MM-DD-<feature-name>.md` (or `docs/pre-dev/{feature}/plan.md` when invoked from pre-dev)
- [ ] Execution handoff offered

## Worked Example

<example title="Phase 1 epic with a dispatch-ready task, and a Phase 2 epic left at epic level">
### Epic 1.1: Transaction lookup service path

**Goal:** `GET /transactions/:id` returns a persisted transaction end-to-end
**Scope:** `internal/service/`, `internal/handler/`
**Dependencies:** none
**Done when:** integration test fetches a seeded transaction by ID; unknown ID returns 404
**Status:** Pending

#### Task 1.1.1: Implement GetTransactionByID service method

- [ ] Done

**Context:** `TransactionRepository` interface already exposes `GetByID` at `internal/domain/repository.go:15`. The service layer (`internal/service/transaction_service.go`) has no read path yet — only `Create`.

**Implementation vision:** Add `GetByID(ctx, id)` to `transactionService`, delegating to the repository. Follow the observability pattern used by `Create` (`transaction_service.go:31-38`): tracking from context, span around the call, `HandleSpanError` on failure. Propagate `domain.ErrNotFound` untouched — the handler layer maps it to 404; do not wrap it. No input validation here: ID format is validated at the handler.

**Files:**
- Modify: `internal/service/transaction_service.go`
- Test: `internal/service/transaction_service_test.go`

**Verification:** `go test ./internal/service/... -run TestTransactionService_GetByID -v` — found and not-found cases both pass; not-found asserts `errors.Is(err, domain.ErrNotFound)`.

**Done when:** service returns the transaction for a known ID and `domain.ErrNotFound` for an unknown one, with span + log coverage matching the `Create` pattern.

---

### Epic 2.1: Transaction list endpoint with cursor pagination

**Goal:** `GET /transactions` returns tenant-scoped pages of transactions
**Scope:** `internal/service/`, `internal/handler/`, repository query layer
**Dependencies:** Epic 1.1 (read path patterns established there)
**Done when:** paginated listing works against seeded data; cursor round-trips; page size capped at 100
**Status:** Pending

*(No tasks yet — elaborated by ring:executing-plans after Phase 1 lands, against the read-path patterns Phase 1 actually established.)*
</example>
