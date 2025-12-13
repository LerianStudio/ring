---
name: dev-implementation
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
  before: [ring-dev-team:dev-devops]

related:
  complementary: [ring-dev-team:dev-cycle, ring-default:test-driven-development, ring-default:requesting-code-review]
  similar: [ring-default:subagent-driven-development, ring-default:executing-plans]

agent_selection:
  criteria:
    - pattern: "*.go"
      keywords: ["go.mod", "golang", "Go"]
      agent: "ring-dev-team:backend-engineer-golang"
    - pattern: "*.ts"
      keywords: ["express", "fastify", "nestjs", "backend", "api", "server"]
      agent: "ring-dev-team:backend-engineer-typescript"
    - pattern: "*.tsx"
      keywords: ["react", "next", "frontend", "component", "page"]
      agent: "ring-dev-team:frontend-bff-engineer-typescript"
    - pattern: "*.css|*.scss"
      keywords: ["design", "visual", "aesthetic", "styling", "ui"]
      agent: "ring-dev-team:frontend-designer"
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
      - "Go Backend" → ring-dev-team:backend-engineer-golang
      - "TypeScript Backend" → ring-dev-team:backend-engineer-typescript
      - "TypeScript Frontend" → ring-dev-team:frontend-bff-engineer-typescript
      - "Frontend Design" → ring-dev-team:frontend-designer
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

**TDD is NON-NEGOTIABLE in Ring workflows. Pressure scenarios and required responses:**

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| **Code Exists** | "Code already written, just add tests" | "DELETE the code. TDD means test-first. Existing code = start over." |
| **Time** | "No time for TDD, just implement" | "TDD is faster long-term. RED-GREEN-REFACTOR prevents rework." |
| **Simplicity** | "Too simple for TDD" | "Simple code still needs tests. TDD is mandatory for ALL changes." |
| **Standards Missing** | "PROJECT_RULES.md doesn't require TDD" | "Ring workflows ALWAYS require TDD. PROJECT_RULES.md adds to, not replaces." |
| **Authority** | "CTO/Senior says skip TDD and ship" | "TDD is non-negotiable in Ring. Escalate to me if authority conflicts with process." |
| **Economic** | "$X/hour revenue loss, ship now" | "Technical debt costs more than revenue loss. Fix root cause with TDD." |
| **Social** | "Team waiting on you, don't block them" | "Blocking with quality is better than unblocking with bugs. They'll wait longer if it breaks." |
| **Exhaustion** | "Too tired, better tests tomorrow" | "Tired code creates more work. STOP now. Resume with TDD tomorrow." |
| **Partial Compliance** | "I've TDDed 9 functions, just this last one without tests" | "TDD is ALL-or-nothing. Every function gets TDD. No partial credit." |
| **Proven Track Record** | "I've proven I follow TDD, one exception is fine" | "Past compliance doesn't grant future exceptions. Every function requires TDD." |
| **Exhaustion + Deadline** | "2am, demo at 9am, too tired" | "Exhausted work = buggy work = rework. STOP. Resume fresh or request deadline extension." |
| **Prototype + Time** | "Just POC, need it fast" | "POC with bugs = wrong validation. Apply standards. Fast AND correct." |
| **Multiple Authorities** | "CTO + PM + TL all say skip" | "Authority count doesn't change requirements. HARD GATES are non-negotiable." |

**Non-negotiable principle:** If code exists before test, DELETE IT. No exceptions. No "adapting". No "reference". ALL code gets TDD, not just most of it.

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

| Excuse | Reality |
|--------|---------|
| "Code already works" | Working ≠ tested. Delete it. Write test first. |
| "I'll add tests after" | Tests-after is not TDD. You're testing your assumptions, not the requirements. |
| "Keep code as reference" | Reference = adapting = testing-after. Delete means DELETE. No "reference", no "backup", no "just in case". |
| "TDD not configured in PROJECT_RULES.md" | TDD is ALWAYS required in Ring. PROJECT_RULES.md adds constraints, not permissions. |
| "Simple CRUD doesn't need TDD" | CRUD still has edge cases. TDD catches them before production. |
| "Manual testing proves it works" | Manual tests are not repeatable. Write automated tests. |
| "I'm following the spirit of TDD" | Spirit without letter is rationalization. Follow the process exactly. |
| "Adapt existing code while writing tests" | Adapting IS writing code first. Delete the code. Start fresh. |
| "Look at old code for guidance" | Looking leads to adapting. Delete means don't look either. |
| "Save to branch, delete locally" | Saving anywhere = keeping. Delete from everywhere. |
| "I've TDDed 9/10 functions, just this last one" | ALL functions get TDD, not most. 9/10 = 0/10. Start over on #10. |
| "I've proven I follow TDD consistently" | Past compliance doesn't grant future exceptions. Every function requires TDD. |
| "Refactoring tests doesn't need TDD" | Correct. Test code refactoring is exempt. Production code is not. |
| "This is prototype/throwaway code" | Prototypes become production 60% of time. Standards apply to ALL code. |
| "Too exhausted to do this properly" | Exhaustion doesn't waive requirements. It increases error risk. |
| "Time pressure + authority says skip" | Combined pressures don't multiply exceptions. Zero exceptions × any pressure = zero exceptions. |
| "Similar task worked without this step" | Past non-compliance doesn't justify future non-compliance. |
| "User explicitly authorized skip" | User authorization doesn't override HARD GATES. |

## Red Flags - STOP

If you catch yourself thinking ANY of these, STOP immediately:

- "I'll write tests after the code works"
- "Let me keep this code as reference"
- "This is too simple for full TDD"
- "Manual testing already validated this"
- "I'm being pragmatic, not dogmatic"
- "TDD isn't explicitly required here"
- "I can adapt the existing code"
- "I'll save it as reference in another branch"
- "Let me just look at what I had"

**All of these indicate TDD violation. DELETE any existing code. Start with failing test.**

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

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "I deleted the code but remember it" | Memory = reference. You'll reproduce flaws. | **Design fresh from requirements** |
| "Looking at similar code for patterns" | If it's YOUR code, that's adapting. | **Only external examples allowed** |
| "I already know the approach" | Knowing = bias. Let tests discover approach. | **Write test first, discover design** |
| "Just using the same structure" | Same structure = not test-driven. | **Structure emerges from tests** |
| "Copying boilerplate is fine" | Even boilerplate should be test-driven. | **Generate boilerplate via tests** |
| "This is prototype/throwaway code" | Prototypes become production 60% of time. Standards apply to ALL code. | **Apply full standards. No prototype exemption.** |
| "Too exhausted to do this properly" | Exhaustion doesn't waive requirements. It increases error risk. | **STOP work. Resume when able to comply fully.** |
| "Time pressure + authority says skip" | Combined pressures don't multiply exceptions. Zero exceptions × any pressure = zero exceptions. | **Follow all requirements regardless of pressure combination.** |
| "Similar task worked without this step" | Past non-compliance doesn't justify future non-compliance. | **Follow complete process every time.** |
| "User explicitly authorized skip" | User authorization doesn't override HARD GATES. | **Cannot comply. Explain non-negotiable requirement.** |

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

## Prerequisites

**HARD GATE:** `docs/PROJECT_RULES.md` must exist (Read tool, NOT WebFetch). Not found → STOP with blocker.

**Required:** Tasks imported from dev-cycle, Agent selected (backend-engineer-golang/-typescript, frontend-bff-engineer-typescript, frontend-designer)

**Note:** PROJECT_RULES.md validated by dev-cycle Step 0, but Gate 0 re-checks (defense-in-depth).

## Step 1: Prepare Implementation Context

**Required:** Technical design (`docs/plans/YYYY-MM-DD-{feature}.md`), selected agent, PROJECT_RULES.md | **Optional:** PRD/TRD, existing patterns

**Verify:** Plan complete ✓ | Agent matches stack ✓ | Environment ready ✓ | Git branch clean ✓

## Step 2: Choose Execution Approach

| Approach | When to Use | Process |
|----------|-------------|---------|
| **Subagent-Driven** (recommended) | Real-time feedback needed, human intervention | Dispatch agent → Review → Code review at checkpoints → Repeat |
| **Parallel Session** | Well-defined plans, batch execution | New terminal in worktree → `ring-default:executing-plans` with plan path |

## Step 3: Execute Implementation Tasks

**Dispatch:** `Task(subagent_type: "ring-dev-team:{agent}", model: "opus")` with task, PROJECT_RULES.md, context

**MANDATORY in prompt:** "TDD RED PHASE EVIDENCE REQUIRED - show failing test output before GREEN"

**Agent returns:** Summary + Files + Tests + Next Steps

## Step 4: Code Review Checkpoints

**Every 3-5 tasks:** Use `ring-default:requesting-code-review` → dispatch 3 reviewers in parallel (code, business-logic, security)

**Severity handling:** Critical/High/Medium → Fix immediately, re-run all | Low → `TODO(review):` | Cosmetic → `FIXME(nitpick):`

**Proceed only when:** Zero Critical/High/Medium + all Low/Cosmetic have comments

## Step 5: Track Implementation Progress

Track: Tasks (completed/in-progress), Files (created/modified), Code Review Status (checkpoint N: PASS/PENDING), Decisions, Issues+Resolutions.

## Step 6: Document Implementation Decisions

Record for each significant decision: Task, Context (why it came up), Chosen Approach, Alternatives, Rationale, Impact. Focus on: deviations from design, performance optimizations, error handling, API changes, test coverage.

## Agent Selection Guide

Use the agent selected in Gate 1 based on technology:

| Stack | Agent |
|-------|-------|
| Go backend | `ring-dev-team:backend-engineer-golang` |
| TypeScript backend | `ring-dev-team:backend-engineer-typescript` |
| React/Next.js frontend | `ring-dev-team:frontend-bff-engineer-typescript` |
| BFF layer (Next.js API Routes) | `ring-dev-team:frontend-bff-engineer-typescript` |

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
- agent_used: ring-dev-team:{agent}

### Issues Encountered
- List any issues or "None"

### Handoff to Next Gate
- Implementation status (complete/partial)
- Files created and modified
- Environment requirements for DevOps
- Outstanding items (if partial)
