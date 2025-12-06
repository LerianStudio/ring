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
      agent: "ring-dev-team:frontend-engineer-typescript"
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
      - "TypeScript Frontend" → ring-dev-team:frontend-engineer-typescript
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
      1. Detect package.json with react -> Select frontend-engineer-typescript
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
| "Keep code as reference" | Reference = adapting = testing-after. Delete means DELETE. |
| "TDD not configured in PROJECT_RULES.md" | TDD is ALWAYS required in Ring. PROJECT_RULES.md adds constraints, not permissions. |
| "Simple CRUD doesn't need TDD" | CRUD still has edge cases. TDD catches them before production. |
| "Manual testing proves it works" | Manual tests are not repeatable. Write automated tests. |
| "I'm following the spirit of TDD" | Spirit without letter is rationalization. Follow the process exactly. |

## Red Flags - STOP

If you catch yourself thinking ANY of these, STOP immediately:

- "I'll write tests after the code works"
- "Let me keep this code as reference"
- "This is too simple for full TDD"
- "Manual testing already validated this"
- "I'm being pragmatic, not dogmatic"
- "TDD isn't explicitly required here"
- "I can adapt the existing code"

**All of these indicate TDD violation. DELETE any existing code. Start with failing test.**

## Prerequisites

Before starting Gate 0:

1. **PROJECT_RULES.md EXISTS** (MANDATORY - HARD GATE):
   ```text
   Check sequence:
   1. Check: docs/PROJECT_RULES.md
   2. Check: docs/STANDARDS.md (legacy name)

   If NOT found → STOP with blocker:
   "Cannot implement without project standards.
   REQUIRED: docs/PROJECT_RULES.md"
   ```
2. **Tasks imported and validated**: From dev-cycle initialization
3. **Agent Selection**: Automatically determined based on task content:
   - `ring-dev-team:backend-engineer-golang`
   - `ring-dev-team:backend-engineer-typescript`
   - `ring-dev-team:frontend-engineer`
   - `ring-dev-team:frontend-bff-engineer-typescript`
   - `ring-dev-team:frontend-designer`

**Note:** PROJECT_RULES.md should already be validated by dev-cycle (Step 0), but Gate 0 double-checks as defense-in-depth.

## Step 1: Prepare Implementation Context

Gather all necessary context:

```
Required:
- Technical design: docs/plans/YYYY-MM-DD-{feature}.md
- Selected agent: ring-dev-team:{agent}
- Project standards: docs/PROJECT_RULES.md

Optional:
- PRD/TRD: docs/pre-dev/{feature}/
- Existing code patterns from Gate 1 analysis
```

**Verify readiness:**
- [ ] Plan document is complete (passes zero-context test)
- [ ] Agent type matches technology stack
- [ ] Development environment is ready
- [ ] Git branch is clean

## Step 2: Choose Execution Approach

Two approaches for executing the implementation plan:

### Option A: Subagent-Driven (Recommended)

Execute in current session with fresh subagent per task:

```
Advantages:
- Real-time feedback and course correction
- Code review between tasks
- Human can intervene at any checkpoint

Process:
1. Dispatch agent for Task 1
2. Review output
3. Run code review if checkpoint
4. Repeat for remaining tasks
```

### Option B: Parallel Session

Execute in separate session with `ring-default:executing-plans`:

```
Advantages:
- Batch execution with checkpoints
- Good for well-defined, tested plans
- Non-blocking main session

Process:
1. Open new terminal in worktree
2. Start Claude session
3. Use executing-plans skill with plan path
```

## Step 3: Execute Implementation Tasks

For each task in the plan, dispatch the selected agent:

```
Task tool:
  subagent_type: "ring-dev-team:{selected-agent}"
  model: "opus"
  prompt: |
    Execute the following implementation task.

    ## Task
    {paste task from plan}

    ## Project Standards
    {paste docs/PROJECT_RULES.md content}

    ## Context from Plan
    **Goal:** {goal from plan}
    **Architecture:** {architecture from plan}

    ## Requirements

    1. **Follow TDD:**
       - Write failing test first
       - Implement minimal code to pass
       - Refactor if needed

    **MANDATORY RED PHASE EVIDENCE:**
    - You MUST show the failing test output in your response
    - Do NOT proceed to GREEN until failure is captured
    - Format: "RED PHASE: [paste test failure output here]"

    2. **Follow Standards:**
       - Match existing code patterns
       - Use project conventions
       - Handle errors consistently

    3. **Document Decisions:**
       - Comment non-obvious choices
       - Update docs if API changes

    4. **Output Format:**
       Provide your implementation following the output schema:
       - Summary of what was done
       - Files created/modified with key code snippets
       - Test results
       - Next steps

    ## Files Context
    {relevant existing file contents if needed}
```

## Step 4: Code Review Checkpoints

At review checkpoints (after every 3-5 tasks), run parallel code review:

```
REQUIRED SUB-SKILL: Use ring-default:requesting-code-review

Dispatch all 3 reviewers in parallel:
- ring-default:code-reviewer (architecture, patterns)
- ring-default:business-logic-reviewer (correctness, edge cases)
- ring-default:security-reviewer (OWASP, auth, validation)
```

**Handle findings by severity:**

| Severity | Action |
|----------|--------|
| Critical | Fix immediately, re-run all reviewers |
| High | Fix immediately, re-run all reviewers |
| Medium | Fix immediately, re-run all reviewers |
| Low | Add `TODO(review):` comment |
| Cosmetic | Add `FIXME(nitpick):` comment |

**Proceed only when:**
- Zero Critical/High/Medium issues remain
- All Low issues have TODO comments
- All Cosmetic issues have FIXME comments

## Step 5: Track Implementation Progress

Maintain progress tracking:

```markdown
## Implementation Progress

### Completed Tasks
- [x] Task 1: {description} - {files}
- [x] Task 2: {description} - {files}
- [ ] Task 3: {description} - IN PROGRESS

### Files Created
- `path/to/new/file1.ext`
- `path/to/new/file2.ext`

### Files Modified
- `path/to/existing/file1.ext` (lines X-Y)
- `path/to/existing/file2.ext` (lines A-B)

### Code Review Status
- Checkpoint 1: PASS (after Task 5)
- Checkpoint 2: PENDING

### Decisions Made
- Decision 1: {description}
- Decision 2: {description}

### Issues Encountered
- Issue 1: {description} - Resolution: {how fixed}
```

## Step 6: Document Implementation Decisions

Record decisions made during implementation:

```markdown
## Implementation Decisions

### Decision: {Title}
**Task:** Task N
**Context:** Why this came up during implementation
**Chosen Approach:** What was implemented
**Alternatives Considered:** Other options
**Rationale:** Why this approach was selected
**Impact:** Effects on other parts of the system
```

Document decisions about:
- Deviations from original design
- Performance optimizations
- Error handling strategies
- API changes
- Test coverage choices

## Agent Selection Guide

Use the agent selected in Gate 1 based on technology:

| Stack | Agent |
|-------|-------|
| Go backend | `ring-dev-team:backend-engineer-golang` |
| TypeScript backend | `ring-dev-team:backend-engineer-typescript` |
| React/Next.js frontend | `ring-dev-team:frontend-engineer` |
| BFF layer (Next.js API Routes) | `ring-dev-team:frontend-bff-engineer-typescript` |
| Visual design focus | `ring-dev-team:frontend-designer` |

## TDD Compliance

If TDD is enabled in `docs/PROJECT_RULES.md`, every implementation task follows:

```
1. RED: Write failing test first
2. GREEN: Write minimal code to pass
3. REFACTOR: Clean up while tests pass
4. COMMIT: Atomic commits per task
```

**Note:** TDD methodology details (examples, patterns, anti-patterns) are documented in:
- `docs/PROJECT_RULES.md` → Project-specific TDD configuration
- Agent knowledge → Implementation agents know TDD when configured

The implementation agent will enforce TDD if configured in PROJECT_RULES.md.

## Handling Implementation Issues

### Test Won't Pass

```
1. Verify test is correct (check assertion logic)
2. Check implementation matches test expectations
3. Look for missing dependencies or imports
4. Check for environment issues
5. If stuck: Document and escalate
```

### Design Change Needed

```
1. Document the issue with current design
2. Propose alternative approach
3. Update plan document if approved
4. Continue implementation with new approach
5. Note design change in implementation decisions
```

### Performance Concerns

```
1. Document the concern
2. Add benchmark test if possible
3. Implement correctness first
4. Optimize with benchmarks after
5. Document optimization decisions
```

## Integration with Standards

Follow `docs/PROJECT_RULES.md` for:

- **Naming conventions**: Variables, functions, files
- **Code structure**: Directory layout, module organization
- **Error handling**: Error types, logging format
- **Testing**: Test file location, naming, coverage
- **Documentation**: Comments, API docs, README
- **Git**: Commit message format, branch naming

If no PROJECT_RULES.md exists, derive conventions from Gate 1 analysis.

## Prepare Handoff to Gate 1

After implementation is complete:

```markdown
## Gate 0 Handoff

**Implementation Status:** COMPLETE/PARTIAL

**Files Created:**
- {list all new files}

**Files Modified:**
- {list all modified files}

**Environment Requirements:**
- New dependencies: {list}
- New environment variables: {list}
- New services needed: {list}

**Ready for DevOps:**
- [ ] Code compiles/builds successfully
- [ ] All tests pass
- [ ] Code review passed
- [ ] No Critical/High/Medium issues

**DevOps Tasks Needed:**
- [ ] Dockerfile update needed: YES/NO
- [ ] docker-compose.yml update needed: YES/NO
- [ ] New environment variables: {list}
- [ ] New services to containerize: {list}
```

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
