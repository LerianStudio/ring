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

**Non-negotiable principle:** If code exists before test, DELETE IT. No exceptions. No "adapting". No "reference".

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
