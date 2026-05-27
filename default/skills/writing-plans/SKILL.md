---
name: ring:writing-plans
description: |
  Authoring comprehensive implementation plans from a spec or requirements before
  touching code. Produces bite-sized, TDD-shaped tasks with exact file paths,
  complete code, and verifiable commands — executable by an engineer with zero
  context for the codebase.
---

# Writing Plans

## When to use
- Spec or requirements exist for a multi-step task and no implementation has started
- Feature spans multiple files/layers and needs decomposition before coding
- Handing off implementation to a separate session, agent, or human

## Skip when
- Single-file change with obvious shape (just do it)
- Exploratory spike — TDD-shaped plans assume known requirements
- Spec is still in brainstorming; the plan would lock premature decisions

## Sequence
**Runs after:** ring:explore-codebase, ring:pre-dev-* skills (Gates 0-9 outputs feed the spec)
**Runs before:** ring:executing-plans (inline execution) or ring:dev-cycle (gated subagent workflow)

## Related
**Companion:** [plan-document-reviewer-prompt.md](plan-document-reviewer-prompt.md) — subagent dispatch template for thorough plan review

---

Write the plan assuming the engineer is skilled but has zero context for this codebase, toolset, or problem domain. Document every file to touch, every test to write, every command to run. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

**Announce at start:** "Using ring:writing-plans to author the implementation plan."

**Default save path:** `docs/plans/YYYY-MM-DD-<feature-name>.md`
(User preferences override.)

## Scope Check

If the spec covers multiple independent subsystems, suggest breaking it into separate plans — one per subsystem. Each plan must produce working, testable software on its own.

If brainstorming already split the spec into sub-project specs, write one plan per sub-spec.

## File Structure

Before defining tasks, map which files will be created or modified and what each is responsible for. This is where decomposition decisions lock in.

| Principle | What it means |
|-----------|---------------|
| Clear boundaries | Each file has one responsibility |
| Small and focused | Easier to hold in context; edits more reliable |
| Co-locate change | Files that change together live together |
| Split by responsibility | Not by technical layer alone |
| Follow existing patterns | Don't unilaterally restructure; mention restructure only if a file you're modifying is already unwieldy |

This structure informs task decomposition. Each task produces self-contained changes that make sense independently.

## Bite-Sized Task Granularity

**Each step is one action (2–5 minutes):**
- "Write the failing test" — step
- "Run it to make sure it fails" — step
- "Implement the minimal code to make the test pass" — step
- "Run the tests and make sure they pass" — step
- "Commit" — step

Larger units → smaller. If a step takes longer than 5 minutes, it's two steps.

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For implementers:** Use ring:executing-plans to implement this plan task-by-task (inline execution with checkpoints), or ring:dev-cycle for full subagent-orchestrated workflow. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

---
```

## Task Structure

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.go`
- Modify: `exact/path/to/existing.go:123-145`
- Test: `path/to/file_test.go`

- [ ] **Step 1: Write the failing test**

```go
func TestSpecificBehavior(t *testing.T) {
    result := Function(input)
    require.Equal(t, expected, result)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `go test ./path/... -run TestSpecificBehavior -v`
Expected: FAIL with "Function not defined"

- [ ] **Step 3: Write minimal implementation**

```go
func Function(input string) string {
    return expected
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `go test ./path/... -run TestSpecificBehavior -v`
Expected: PASS

- [ ] **Step 5: Commit**

Use ring:commit skill with:
- Type: `feat`
- Scope: relevant module
- Files: `path/to/file_test.go`, `path/to/file.go`
````

## ⛔ No Placeholders

Every step must contain the actual content the engineer needs. These are **plan failures** — never write them:

| Pattern | Why it fails |
|---------|--------------|
| "TBD", "TODO", "implement later", "fill in details" | Forces the engineer to guess scope |
| "Add appropriate error handling" / "add validation" / "handle edge cases" | Decision deferred — plan didn't do its job |
| "Write tests for the above" (without actual test code) | Test design is the plan's job, not the implementer's |
| "Similar to Task N" (without repeating the code) | Engineer may read tasks out of order |
| Steps that describe what without showing how | Code steps require code blocks |
| References to types/functions/methods not defined in any task | Plan is internally inconsistent |

## Remember

- Exact file paths always
- Complete code in every step — if a step changes code, show the code
- Exact commands with expected output
- DRY, YAGNI, TDD, frequent commits

## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch.

| Check | What to verify |
|-------|----------------|
| **Spec coverage** | Skim each requirement in the spec. Point to a task that implements it. List gaps. |
| **Placeholder scan** | Search for the red flags in the "No Placeholders" table. Fix any matches. |
| **Type consistency** | Method signatures, property names, and types used in later tasks match what earlier tasks defined. A function `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug. |
| **Command accuracy** | Test commands target the right paths; expected output matches the test name. |

If you find issues, fix them inline. No need to re-review — just fix and move on. If you find a spec requirement with no task, add the task.

**For high-stakes plans** (large surface, multiple authors, critical path): also dispatch a plan-document reviewer subagent using the template in `plan-document-reviewer-prompt.md`.

## Execution Handoff

After saving the plan, offer execution choice:

> Plan complete and saved to `docs/plans/<filename>.md`. Two execution options:
>
> **1. Inline Execution (this session)** — Use ring:executing-plans for task-by-task execution with verification checkpoints. Best for fast iteration, small-to-medium plans.
>
> **2. Subagent-Orchestrated (ring:dev-cycle)** — 10-gate backend cycle with parallel specialist dispatch (backend-engineer-golang/typescript, qa-analyst, code-reviewer, etc.). Best for production work that must pass through the full review pool.
>
> Which approach?

**If Inline Execution chosen:** Continue with ring:executing-plans in this session.

**If Subagent-Orchestrated chosen:** Hand off to ring:dev-cycle, which owns implementation across Gates 0–10.

## Verification Checklist

Before marking the plan complete:
- [ ] Plan header present (Goal, Architecture, Tech Stack)
- [ ] File structure mapped before tasks
- [ ] Every task has exact file paths and complete code
- [ ] Every code step has a code block; every command step has a command
- [ ] No placeholders ("TBD", "TODO", "appropriate error handling")
- [ ] Type and naming consistency across tasks
- [ ] Self-review checklist applied
- [ ] Plan saved to `docs/plans/YYYY-MM-DD-<feature-name>.md`
- [ ] Execution handoff offered
