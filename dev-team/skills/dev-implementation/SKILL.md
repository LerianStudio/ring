---
name: ring-dev-team:dev-implementation
description: |
  Gate 0 of the development cycle. Executes code implementation using the appropriate
  specialized agent based on task content and project language. Handles both tasks
  with subtasks (step-by-step) and tasks without (TDD autonomous). Follows project
  standards defined in docs/PROJECT_RULES.md.

trigger: |
  - Gate 0 of development cycle
  - Tasks loaded at initialization
  - Ready to write code

skip_when: |
  - Tasks not loaded (initialization incomplete)
  - Implementation already complete for this task

  NOT_skip_when: |
    - "Code already exists" → DELETE it. TDD is test-first.
    - "Simple feature" → Simple ≠ exempt. TDD for all.
    - "Time pressure" → TDD saves time. No shortcuts.
    - "PROJECT_RULES.md doesn't require" → Ring ALWAYS requires TDD.

sequence:
  before: [dev-devops]

related:
  complementary: [dev-cycle, test-driven-development, requesting-code-review]
  similar: [subagent-driven-development, executing-plans]

agent_selection:
  criteria:
    - pattern: "*.go"
      keywords: ["go.mod", "golang", "Go"]
      agent: "backend-engineer-golang"
    - pattern: "*.ts"
      keywords: ["express", "fastify", "nestjs", "backend", "api", "server"]
      agent: "backend-engineer-typescript"
    - pattern: "*.tsx"
      keywords: ["react", "next", "frontend", "component", "page"]
      agent: "frontend-bff-engineer-typescript"
    - pattern: "*.css|*.scss"
      keywords: ["design", "visual", "aesthetic", "styling", "ui"]
      agent: "frontend-designer"
  fallback: "ASK_USER"  # Do NOT assume language - ask user
  detection_order:
    - "Check task.type field in tasks.md"
    - "Look for file patterns in task description"
    - "Detect project language from go.mod/package.json"
    - "Match keywords in task title/description"
    - "If no match → ASK USER (do not assume)"
  on_detection_failure: |
    If language cannot be detected, use AskUserQuestion:
    Question: "Could not detect project language. Which agent should implement this task?"
    Options:
      - "Go Backend" → backend-engineer-golang
      - "TypeScript Backend" → backend-engineer-typescript
      - "TypeScript Frontend" → frontend-bff-engineer-typescript
      - "Frontend Design" → frontend-designer
    NEVER assume Go. Wrong agent = wrong patterns = rework.

verification:
  automated:
    - command: "go build ./... 2>&1 | grep -c 'error'"
      description: "Go code compiles"
      success_pattern: "^0$"
    - command: "npm run build 2>&1 | grep -c 'error'"
      description: "TypeScript compiles"
      success_pattern: "^0$"
  manual:
    - "TDD RED phase failure output captured before implementation"
    - "Implementation follows project standards from PROJECT_RULES.md"
    - "No TODO comments without issue references"

examples:
  - name: "Go backend implementation"
    context: "Task: Add user authentication endpoint"
    expected_flow: |
      1. Detect go.mod -> Select backend-engineer-golang
      2. Load PROJECT_RULES.md for Go standards
      3. Write failing test (RED)
      4. Implement auth handler (GREEN)
      5. Refactor if needed
      6. Prepare handoff to Gate 1
  - name: "TypeScript frontend component"
    context: "Task: Create dashboard widget"
    expected_flow: |
      1. Detect package.json with react -> Select frontend-bff-engineer-typescript
      2. Load frontend.md standards
      3. Write component test (RED)
      4. Implement Dashboard component (GREEN)
      5. Verify strict TypeScript compliance
---

# Code Implementation (Gate 0)

See [CLAUDE.md](https://raw.githubusercontent.com/LerianStudio/ring/main/CLAUDE.md) for canonical gate requirements.

## Overview

This skill executes the implementation phase of the development cycle. It:
- Selects the appropriate specialized agent based on task content
- Applies project standards from docs/PROJECT_RULES.md
- Follows TDD methodology
- Documents implementation decisions

## Pressure Resistance

See [shared-patterns/shared-pressure-resistance.md](../shared-patterns/shared-pressure-resistance.md) for universal pressure scenarios.

**TDD-specific note:** If code exists before test, DELETE IT. No exceptions. No "adapting". No "reference". ALL code gets TDD, not just most of it.

## Exploratory Spikes (Time-Boxed Learning Only)

**Definition:** Time-boxed throwaway experiment to learn unfamiliar APIs/libraries. NOT for production code.

**When Spike Is Legitimate:**
- First time using new library (e.g., learning gRPC streaming API)
- API documentation unclear - need hands-on experiment
- Testing approach unknown - verify framework supports TDD pattern

**Rules (NON-NEGOTIABLE):**
- **Maximum Duration:** 1 hour (can extend once for 30 min if genuinely stuck)
- **Purpose:** Learning ONLY - understanding how API works
- **DELETE AFTER:** ALL spike code MUST be deleted before TDD implementation begins
- **No Keeping:** Cannot "adapt" spike code - must start completely fresh with RED phase
- **Document Learning:** Write down what you learned, then delete the code

**When Spike Is NOT Acceptable:**
- ❌ "Spike to implement feature, then add tests" (that's testing-after, not spike)
- ❌ "Spike for 3 hours to build whole component" (no time limit = bypass)
- ❌ "Keep spike code as reference while TDDing" (adapting spike = testing-after)
- ❌ "Spike covered 80%, TDD the remaining 20%" (partial TDD = not TDD)

**After Spike Completes:**
1. **DELETE** all spike code (no git stash, no branch, no "just in case")
2. **Document** what you learned (patterns, gotchas, constraints)
3. **Start Fresh** with TDD - write failing test based on spike learnings
4. **If spike showed TDD is impossible** → STOP, report blocker (wrong library/framework choice)

**Spike vs Implementation:**

| Spike (Learning) | TDD Implementation |
|------------------|-------------------|
| Max 90 minutes total | No time limit |
| DELETE after | COMMIT to repo |
| No tests required | Test-first MANDATORY |
| Throwaway exploration | Production code |
| "How does X work?" | "Implement feature Y" |

**Red Flag:** If you want to keep spike code, you're not spiking - you're bypassing TDD. DELETE IT.

## Test Refactoring and TDD

**Question:** When refactoring existing tests, does TDD apply?

**Answer:** Depends on what "refactoring" means:

**Scenario A: Changing Test Implementation (TDD Does NOT Apply)**
- **What:** Refactoring test code itself (extract helper, improve assertions, fix flaky test)
- **Test-First Required:** NO - tests can't test themselves
- **Approach:** Edit test directly, verify it still fails correctly, then passes correctly

**Example:**
```typescript
// Before: Flaky test with timing issues
it('should process async task', async () => {
  await processTask();
  await new Promise(resolve => setTimeout(resolve, 100)); // Bad: arbitrary wait
  expect(result).toBe('done');
});

// Refactor: Fix flakiness (no TDD needed for test code itself)
it('should process async task', async () => {
  const result = await processTask();
  expect(result).toBe('done'); // Better: no timing dependency
});
```

**Scenario B: Changing Implementation Code Covered By Tests (TDD APPLIES)**
- **What:** Refactoring production code that has tests
- **Test-First Required:** YES - update tests first if behavior changes
- **Approach:**
  1. If changing behavior → Update test FIRST (RED if needed)
  2. Refactor implementation (GREEN)
  3. Verify tests still pass

**Example:**
```typescript
// Refactoring: Extract method from large function
// 1. Tests already exist and pass ✓
// 2. Extract method (refactor implementation)
// 3. Run tests - verify still pass ✓
// No new test needed if behavior unchanged
```

**Scenario C: Adding Test Coverage for Untested Code (TDD APPLIES)**
- **What:** Writing tests for code that lacks coverage
- **Test-First Required:** YES - this is standard TDD
- **Approach:** Write failing test (RED), verify it fails, implementation already exists (GREEN), refactor

**Summary:**
- **Test code refactoring:** TDD does NOT apply (can't test the test)
- **Production code refactoring:** TDD applies IF behavior changes
- **Adding coverage:** TDD applies (write failing test first)

## Common Rationalizations - REJECTED

See [shared-patterns/shared-anti-rationalization.md](../shared-patterns/shared-anti-rationalization.md) for universal anti-rationalizations (including TDD section).

**Implementation-specific rationalizations:**

| Excuse | Reality |
|--------|---------|
| "Keep code as reference" | Reference = adapting = testing-after. Delete means DELETE. No "reference", no "backup", no "just in case". |
| "Save to branch, delete locally" | Saving anywhere = keeping. Delete from everywhere. |
| "Look at old code for guidance" | Looking leads to adapting. Delete means don't look either. |

## Red Flags - STOP

See [shared-patterns/shared-red-flags.md](../shared-patterns/shared-red-flags.md) for universal red flags (including TDD section).

If you catch yourself thinking ANY of those patterns, STOP immediately. DELETE any existing code. Start with failing test.

## What "DELETE" Means - No Ambiguity

**DELETE means:**
- `git checkout -- file.go` (discard changes)
- `rm file.go` (remove file)
- NOT `git stash` (that's keeping)
- NOT `mv file.go file.go.bak` (that's keeping)
- NOT "move to another branch" (that's keeping)
- NOT "I'll just remember" (you'll reference)

**DELETE verification:**
```bash
# After deletion, this should show nothing:
git diff HEAD -- <file>
ls <file>  # Should return "No such file"
```

**If you can retrieve the code, you didn't delete it.**

## Mental Reference Prevention (HARD GATE)

**Mental reference is a subtle form of "keeping" that violates TDD:**

| Type | Example | Why It's Wrong | Required Action |
|------|---------|----------------|-----------------|
| **Memory** | "I remember the approach I used" | You'll unconsciously reproduce patterns | **Start fresh with new design** |
| **Similar code** | "Let me check how auth works elsewhere" | Looking at YOUR prior work = adapting | **Read external examples only** |
| **Mental model** | "I know the structure already" | Structure should emerge from tests | **Let tests drive the design** |
| **Clipboard** | "I copied the method signature" | Clipboard content = keeping | **Type from scratch** |

**Anti-Rationalization for Mental Reference:**

See [shared-patterns/shared-anti-rationalization.md](../shared-patterns/shared-anti-rationalization.md) for universal anti-rationalizations.

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "I deleted the code but remember it" | Memory = reference. You'll reproduce flaws. | **Design fresh from requirements** |
| "Looking at similar code for patterns" | If it's YOUR code, that's adapting. | **Only external examples allowed** |
| "I already know the approach" | Knowing = bias. Let tests discover approach. | **Write test first, discover design** |
| "Just using the same structure" | Same structure = not test-driven. | **Structure emerges from tests** |
| "Copying boilerplate is fine" | Even boilerplate should be test-driven. | **Generate boilerplate via tests** |

**Valid external references:**
- ✅ Official documentation (Go docs, TypeScript handbook)
- ✅ Open source libraries you're using
- ✅ Team patterns documented in PROJECT_RULES.md
- ❌ Your own prior implementation of THIS feature
- ❌ Similar code YOU wrote in another service

## Generated Code Handling

**Generated code (protobuf, OpenAPI, ORM) has special rules:**

| Type | TDD Required? | Rationale |
|------|---------------|-----------|
| **protobuf .pb.go** | NO | Generated from .proto - test the .proto |
| **swagger/openapi client** | NO | Generated from spec - test the spec |
| **ORM models** | NO | Generated from schema - test business logic using them |
| **Your code using generated code** | YES | Your logic needs TDD |

**Rule:** Test what you write. Don't test what's generated. But test your usage of generated code.

## ⛔ MANDATORY: Agent Dispatch Required (HARD GATE)

See [shared-patterns/shared-orchestrator-principle.md](../shared-patterns/shared-orchestrator-principle.md) for full ORCHESTRATOR principle, role separation, forbidden/required actions, agent responsibilities (observability), library requirements, and anti-rationalization table.

**Summary:** You orchestrate. Agents execute. Agents implement observability (logs, traces). If using Read/Write/Edit/Bash on source code → STOP. Dispatch agent.

See [shared-patterns/template-tdd-prompts.md](../shared-patterns/template-tdd-prompts.md) for observability requirements to include in dispatch prompts.

## Prerequisites

**HARD GATE:** `docs/PROJECT_RULES.md` must exist (Read tool, NOT WebFetch). Not found → STOP with blocker.

**Required:** Tasks imported from dev-cycle, Agent selected (backend-engineer-golang/-typescript, frontend-bff-engineer-typescript, frontend-designer)

**Note:** PROJECT_RULES.md validated by dev-cycle Step 0, but Gate 0 re-checks (defense-in-depth).

## TDD Sub-Phases (Gate 0.1 and 0.2)

**Gate 0 is split into two explicit sub-phases with a HARD GATE between them:**

```
┌─────────────────────────────────────────────────────────────────┐
│  GATE 0.1: TDD-RED                                              │
│  Write failing test → Run test → Capture FAILURE output         │
│                                                                 │
│  ═══════════════════ HARD GATE ═══════════════════════════════  │
│  CANNOT proceed to 0.2 until failure_output is captured         │
│  ════════════════════════════════════════════════════════════   │
│                                                                 │
│  GATE 0.2: TDD-GREEN                                            │
│  Implement minimal code → Run test → Verify PASS                │
└─────────────────────────────────────────────────────────────────┘
```

**State tracking:**
```json
{
  "tdd_red": {
    "status": "completed",
    "test_file": "path/to/test.go",
    "failure_output": "FAIL: TestFoo - expected X got nil"
  },
  "tdd_green": {
    "status": "pending"
  }
}
```

## Step 1: Prepare Implementation Context

**Required:** Technical design (`docs/plans/YYYY-MM-DD-{feature}.md`), selected agent, PROJECT_RULES.md | **Optional:** PRD/TRD, existing patterns

**Verify:** Plan complete ✓ | Agent matches stack ✓ | Environment ready ✓ | Git branch clean ✓

## Step 2: Gate 0.1 - TDD-RED (Write Failing Test)

**Purpose:** Write a test that captures expected behavior and FAILS.

**Dispatch:** `Task(subagent_type: "{agent}", model: "opus")`

See [shared-patterns/template-tdd-prompts.md](../shared-patterns/template-tdd-prompts.md) for the TDD-RED prompt template.

**Agent returns:** Test file + Failure output

**On success:** Store `tdd_red.failure_output` → Proceed to Gate 0.2

## Step 3: Gate 0.2 - TDD-GREEN (Implementation)

**PREREQUISITE:** `tdd_red.status == "completed"` with valid `failure_output`

**Purpose:** Write minimal code to make the failing test pass.

**Dispatch:** `Task(subagent_type: "{agent}", model: "opus")`

See [shared-patterns/template-tdd-prompts.md](../shared-patterns/template-tdd-prompts.md) for the TDD-GREEN prompt template (includes observability requirements).

**Agent returns:** Implementation + Pass output + Commit SHA

**On success:** Store `tdd_green.test_pass_output` → Gate 0 complete

## Step 4: Choose Execution Approach

| Approach | When to Use | Process |
|----------|-------------|---------|
| **Subagent-Driven** (recommended) | Real-time feedback needed, human intervention | Dispatch agent → Review → Code review at checkpoints → Repeat |
| **Parallel Session** | Well-defined plans, batch execution | New terminal in worktree → `executing-plans` with plan path |

## Step 5: Code Review Checkpoints

**Every 3-5 tasks:** Use `requesting-code-review` → dispatch 3 reviewers in parallel (code, business-logic, security)

**Severity handling:** Critical/High/Medium → Fix immediately, re-run all | Low → `TODO(review):` | Cosmetic → `FIXME(nitpick):`

**Proceed only when:** Zero Critical/High/Medium + all Low/Cosmetic have comments

## Step 6: Track Implementation Progress

Track: Tasks (completed/in-progress), Files (created/modified), Code Review Status (checkpoint N: PASS/PENDING), Decisions, Issues+Resolutions.

## Step 7: Document Implementation Decisions

Record for each significant decision: Task, Context (why it came up), Chosen Approach, Alternatives, Rationale, Impact. Focus on: deviations from design, performance optimizations, error handling, API changes, test coverage.

## Agent Selection Guide

Use the agent selected in Gate 1 based on technology:

| Stack | Agent |
|-------|-------|
| Go backend | `backend-engineer-golang` |
| TypeScript backend | `backend-engineer-typescript` |
| React/Next.js frontend | `frontend-bff-engineer-typescript` |
| BFF layer (Next.js API Routes) | `frontend-bff-engineer-typescript` |

## TDD Compliance

**Cycle:** RED (failing test) → GREEN (minimal code to pass) → REFACTOR (clean up) → COMMIT (atomic per task)

**TDD details:** PROJECT_RULES.md (project-specific config) + agent knowledge. Agent enforces when configured.

## Handling Implementation Issues

| Issue | Resolution Steps |
|-------|-----------------|
| **Test Won't Pass** | Verify test logic → Check implementation matches expectations → Check imports/deps → Check environment → If stuck: document + escalate |
| **Design Change Needed** | Document issue → Propose alternative → Update plan if approved → Implement new approach → Note in decisions |
| **Performance Concerns** | Document concern → Add benchmark test → Implement correctness first → Optimize with benchmarks → Document optimization |

## Integration with Standards

**Follow PROJECT_RULES.md for:** Naming (vars, functions, files), Code structure (dirs, modules), Error handling (types, logging), Testing (location, naming, coverage), Documentation (comments, API docs), Git (commits, branches)

**No PROJECT_RULES.md?** STOP with blocker: "Cannot implement without project standards. REQUIRED: docs/PROJECT_RULES.md"

## Prepare Handoff to Gate 1

**Gate 0 Handoff contents:**

| Section | Content |
|---------|---------|
| **Status** | COMPLETE/PARTIAL |
| **Files** | Created: {list}, Modified: {list} |
| **Environment Needs** | Dependencies, env vars, services |
| **Ready for DevOps** | Code compiles ✓, Tests pass ✓, Review passed ✓, No Critical/High/Medium ✓ |
| **DevOps Tasks** | Dockerfile update (Y/N), docker-compose update (Y/N), new env vars, new services |

## Execution Report

Base metrics per [shared-patterns/output-execution-report.md](../shared-patterns/output-execution-report.md).

| Metric | Value |
|--------|-------|
| Duration | Xm Ys |
| Iterations | N |
| Result | PASS/FAIL/PARTIAL |

### Details
- tasks_completed: N/N
- files_created: N
- files_modified: N
- tests_added: N
- tests_passing: N/N
- review_checkpoints_passed: N/N
- agent_used: {agent}

### Issues Encountered
- List any issues or "None"

### Handoff to Next Gate
- Implementation status (complete/partial)
- Files created and modified
- Environment requirements for DevOps
- Outstanding items (if partial)
