---
name: dev-cycle-frontend
description: |
  Frontend development cycle orchestrator with 9 gates. Loads tasks from PM team output
  or backend handoff and executes through implementation → devops → accessibility →
  unit testing → visual testing → E2E testing → performance testing → review → validation.
metadata:
  examples:
  - name: New frontend from backend handoff
    invocation: /ring:dev-cycle-frontend docs/pre-dev/auth/tasks-frontend.md
    expected_flow: |
      1. Load tasks with subtasks
      2. Detect UI library mode (sindarian-ui or fallback)
      3. Load backend handoff if available
      4. Ask user for execution mode
      5. Execute Gate 0→1→2→3→4→5→6→7→8 for each task
      6. Generate feedback report
  - name: Resume interrupted frontend cycle
    invocation: /ring:dev-cycle-frontend --resume
  - name: Direct prompt mode
    invocation: /ring:dev-cycle-frontend Implement dashboard with transaction list and charts
  prerequisite: |
    - Tasks file exists with structured subtasks
    - Not already in a specific gate skill execution
  related:
    complementary:
    - ring:dev-frontend-accessibility
    - ring:dev-unit-testing
    - ring:dev-frontend-visual
    - ring:dev-frontend-e2e
    - ring:dev-frontend-performance
    - ring:requesting-code-review
    - ring:dev-validation
    - ring:dev-feedback-loop
  sequence:
    before:
    - ring:dev-feedback-loop
  skip_when: |
    - "Task is simple" → Simple ≠ risk-free. Execute gates.
    - "Tests already pass" → Tests ≠ review. Different concerns.
    - "Backend already tested this" → Frontend has different quality concerns.
  trigger: |
    - Starting a new frontend development cycle with a task file
    - Resuming an interrupted frontend development cycle (--resume flag)
    - After backend dev cycle completes (consuming handoff)
  verification:
    automated:
    - command: test -f docs/ring:dev-cycle-frontend/current-cycle.json
      description: State file exists
      success_pattern: exit 0
    manual:
    - All gates for current task show PASS in state file
---

# Frontend Development Cycle Orchestrator

## Standards Loading (MANDATORY)

**Before any gate execution, you MUST load Ring standards:**

<fetch_required>
https://raw.githubusercontent.com/LerianStudio/ring/main/CLAUDE.md
https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/frontend.md
</fetch_required>

Fetch URLs above and extract: Agent Modification Verification requirements, Anti-Rationalization Tables requirements, Critical Rules, and Frontend Standards.

<block_condition>
- WebFetch fails or returns empty
- CLAUDE.md not accessible
- frontend.md not accessible
</block_condition>

If any condition is true, STOP and report blocker. Cannot proceed without Ring standards.

## Overview

The frontend development cycle orchestrator loads tasks/subtasks from PM team output (or manual task files) and executes through 9 gates (Gate 0-8) with **all gates executing per unit** (no deferred execution):

- **Gates 0-8 (per unit):** Write code + run tests/checks per task/subtask
- **All 9 gates are sequential and mandatory**

Unlike the backend `ring:dev-cycle` (which defers integration/chaos test execution), the frontend cycle executes all gates fully per unit. Frontend testing tools (Playwright, Storybook, Lighthouse) do not require heavy container infrastructure.

**MUST announce at start:** "I'm using the ring:dev-cycle-frontend skill to orchestrate frontend task execution through 9 gates (Gate 0-8). All gates execute per unit."

## CRITICAL: Specialized Agents Perform All Tasks

See [shared-patterns/shared-orchestrator-principle.md](../shared-patterns/shared-orchestrator-principle.md) for full ORCHESTRATOR principle, role separation, forbidden/required actions, gate-to-agent mapping, and anti-rationalization table.

**Summary:** You orchestrate. Agents execute. If using Read/Write/Edit/Bash on source code, STOP. Dispatch agent.

---

## ORCHESTRATOR BOUNDARIES (HARD GATE)

**This section defines exactly what the orchestrator CAN and CANNOT do.**

### What Orchestrator CAN Do (PERMITTED)

| Action | Tool | Purpose |
|--------|------|---------|
| Read task files | `Read` | Load task definitions from `docs/pre-dev/*/tasks-frontend.md` or `docs/pre-dev/*/tasks.md` |
| Read state files | `Read` | Load/verify `docs/ring:dev-cycle-frontend/current-cycle.json` |
| Read PROJECT_RULES.md | `Read` | Load project-specific rules |
| Read backend handoff | `Read` | Load `docs/ring:dev-cycle/handoff-frontend.json` if available |
| Write state files | `Write` | Persist cycle state to JSON |
| Track progress | `TodoWrite` | Maintain task list |
| Dispatch agents | `Task` | Send work to specialist agents |
| Ask user questions | `AskUserQuestion` | Get execution mode, approvals |
| WebFetch standards | `WebFetch` | Load Ring standards |

### What Orchestrator CANNOT Do (FORBIDDEN)

<forbidden>
- Read source code (`Read` on `*.ts`, `*.tsx`, `*.jsx`, `*.css`, `*.scss`) - Agent reads code, not orchestrator
- Write source code (`Write`/`Create` on `*.ts`, `*.tsx`, `*.jsx`) - Agent writes code, not orchestrator
- Edit source code (`Edit` on `*.ts`, `*.tsx`, `*.jsx`, `*.css`) - Agent edits code, not orchestrator
- Run tests (`Execute` with `npm test`, `npx playwright`, `npx vitest`) - Agent runs tests in TDD cycle
- Analyze code (Direct pattern analysis) - `ring:codebase-explorer` analyzes
- Make architectural decisions (Choosing patterns/libraries) - User decides, agent implements
</forbidden>

Any of these actions by orchestrator = IMMEDIATE VIOLATION. Dispatch agent instead.

---

### The 3-FILE RULE

**If a task requires editing MORE than 3 files, MUST dispatch specialist agent.**

This is not negotiable:
- 1-3 files of non-source content (markdown, json, yaml) - Orchestrator MAY edit directly
- 1+ source code files (`*.ts`, `*.tsx`, `*.jsx`, `*.css`) - MUST dispatch agent
- 4+ files of any type - MUST dispatch agent

### Orchestrator Workflow Order (MANDATORY)

```text
+------------------------------------------------------------------+
|  CORRECT WORKFLOW ORDER                                           |
+------------------------------------------------------------------+
|                                                                   |
|  1. Load task file (Read docs/pre-dev/*/tasks-frontend.md)        |
|  2. Detect UI library mode (Step 0)                               |
|  3. Load backend handoff if available                             |
|  4. Ask execution mode (AskUserQuestion)                          |
|  5. Determine state path + Check/Load state                       |
|  6. WebFetch Ring Standards (CLAUDE.md + frontend.md)             |
|  7. LOAD SUB-SKILL for current gate (Skill tool)                  |
|  8. Execute sub-skill instructions (dispatch agent via Task)      |
|  9. Wait for agent completion                                     |
|  10. Verify agent output (Standards Coverage Table)               |
|  11. Update state (Write to JSON)                                 |
|  12. Proceed to next gate                                         |
|                                                                   |
|  ================================================================ |
|  WRONG: Load -> Mode -> Standards -> Task(agent) directly         |
|  RIGHT: Load -> Mode -> Standards -> Skill(sub) -> Task(agent)    |
|  ================================================================ |
+------------------------------------------------------------------+
```

---

## UI Library Mode Detection (MANDATORY - Step 0)

Before any gate execution, detect the project's UI library configuration:

```text
Read tool: package.json

Parse the JSON content:
  - If "dependencies" or "devDependencies" contains "@lerianstudio/sindarian-ui"
    → ui_library_mode = "sindarian-ui"
  - Otherwise
    → ui_library_mode = "fallback-only"
```

Store result in state file under `ui_library_mode`.

**`@lerianstudio/sindarian-ui`** is PRIMARY. shadcn/ui + Radix is FALLBACK for missing components.

| Mode | Meaning | Agent Behavior |
|------|---------|----------------|
| `sindarian-ui` | Sindarian UI detected in package.json | Use Sindarian components first, shadcn/ui only for gaps |
| `fallback-only` | No Sindarian UI detected | Use shadcn/ui + Radix as primary component library |

**Anti-Rationalization for UI Library Mode:**

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Skip detection, just use shadcn" | Project may have Sindarian UI. Skipping = wrong components. | **MUST detect before Gate 0** |
| "Mode doesn't matter for this task" | Mode affects every component decision in Gate 0. | **MUST detect and store in state** |

---

## Backend Handoff Loading (Optional)

If the frontend cycle follows a backend `ring:dev-cycle`, load the handoff file:

```text
Check: Does docs/ring:dev-cycle/handoff-frontend.json exist?

  YES -> Load and parse:
    - endpoints: API endpoints implemented by backend
    - types: TypeScript types/interfaces exported by backend
    - contracts: Request/response schemas
    - auth_pattern: Authentication approach (JWT, session, etc.)
    Store in state.backend_handoff

  NO -> Proceed without handoff (standalone frontend development)
```

**Handoff contents are CONTEXT for agents, not requirements.** Agents MUST still follow all gate requirements regardless of handoff content.

---

## SUB-SKILL LOADING IS MANDATORY (HARD GATE)

**Before dispatching any agent, you MUST load the corresponding sub-skill first.**

<cannot_skip>
- Gate 0: `Skill("ring:dev-implementation")` → then `Task(subagent_type="ring:frontend-engineer" or "ring:ui-engineer" or "ring:frontend-bff-engineer-typescript")`
- Gate 1: `Skill("ring:dev-devops")` → then `Task(subagent_type="ring:devops-engineer")`
- Gate 2: `Skill("ring:dev-frontend-accessibility")` → then `Task(subagent_type="ring:qa-analyst-frontend", test_mode="accessibility")`
- Gate 3: `Skill("ring:dev-unit-testing")` → then `Task(subagent_type="ring:qa-analyst-frontend", test_mode="unit")`
- Gate 4: `Skill("ring:dev-frontend-visual")` → then `Task(subagent_type="ring:qa-analyst-frontend", test_mode="visual")`
- Gate 5: `Skill("ring:dev-frontend-e2e")` → then `Task(subagent_type="ring:qa-analyst-frontend", test_mode="e2e")`
- Gate 6: `Skill("ring:dev-frontend-performance")` → then `Task(subagent_type="ring:qa-analyst-frontend", test_mode="performance")`
- Gate 7: `Skill("ring:requesting-code-review")` → then 5x `Task(...)` in parallel
- Gate 8: `Skill("ring:dev-validation")` → N/A (verification only)
</cannot_skip>

Between "WebFetch standards" and "Task(agent)" there MUST be "Skill(sub-skill)".

**The workflow for each gate is:**
```text
1. Skill("[sub-skill-name]")     <- Load sub-skill instructions
2. Follow sub-skill instructions  <- Sub-skill tells you HOW to dispatch
3. Task(subagent_type=...)       <- Dispatch agent as sub-skill instructs
4. Validate agent output          <- Per sub-skill validation rules
5. Update state                   <- Record results
```

### Custom Instructions (Optional Second Argument)

**Validation:** See [shared-patterns/custom-prompt-validation.md](../shared-patterns/custom-prompt-validation.md) for max length (500 chars), sanitization rules, gate protection, and conflict handling.

**If `custom_prompt` is set in state, inject it into all agent dispatches:**

```yaml
Task tool:
  subagent_type: "ring:frontend-engineer"
  prompt: |
    **CUSTOM CONTEXT (from user):**
    {state.custom_prompt}

    ---

    **Standard Instructions:**
    [... rest of agent prompt ...]
```

**Rules for custom prompt:**
1. **Inject at TOP of prompt** - User context takes precedence
2. **Preserve in state** - custom_prompt persists for resume
3. **Include in execution report** - Document what context was used
4. **Forward via state** - Sub-skills read `custom_prompt` from state file and inject into their agent dispatches (no explicit parameter passing needed)

**Example custom prompts and their effect:**

| Custom Prompt | Effect on Agents |
|---------------|------------------|
| "Use dark mode as default theme" | Agents implement dark mode first, light as secondary |
| "Focus on mobile-first responsive design" | Gate 4 visual tests prioritize mobile breakpoints |
| "Integrate with existing auth context from backend" | Gate 0 uses backend handoff auth pattern |
| "Prioritize accessibility over animations" | Gate 2 gets more attention, animations simplified |

### Anti-Rationalization for Skipping Sub-Skills

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "I know what the sub-skill does" | Knowledge ≠ execution. Sub-skill has iteration logic. | **Load Skill() first** |
| "Task() directly is faster" | Faster ≠ correct. Sub-skill has validation rules. | **Load Skill() first** |
| "Sub-skill just wraps Task()" | Sub-skills have retry logic, fix dispatch, validation. | **Load Skill() first** |
| "I'll follow the pattern manually" | Manual = error-prone. Sub-skill is the pattern. | **Load Skill() first** |

**Between "WebFetch standards" and "Task(agent)" there MUST be "Skill(sub-skill)".**

---

### Anti-Rationalization for Direct Coding

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "It's just one small component" | File count doesn't determine agent need. Standards do. | **DISPATCH specialist agent** |
| "I already loaded the standards" | Loading standards ≠ permission to implement. Standards are for AGENTS. | **DISPATCH specialist agent** |
| "Agent dispatch adds overhead" | Overhead ensures compliance. Skip = skip verification. | **DISPATCH specialist agent** |
| "I can write React/TypeScript" | Knowing framework ≠ having Ring standards loaded. Agent has them. | **DISPATCH specialist agent** |
| "Just a quick CSS fix" | "Quick" is irrelevant. All source changes require specialist. | **DISPATCH specialist agent** |
| "I'll read the component first to understand" | Reading source = temptation to edit. Agent reads for you. | **DISPATCH specialist agent** |
| "Let me check if tests pass first" | Agent runs tests in TDD cycle. You don't run tests. | **DISPATCH specialist agent** |

### Red Flags - Orchestrator Violation in Progress

**If you catch yourself doing any of these, STOP IMMEDIATELY:**

```text
RED FLAG: About to Read *.tsx or *.ts file
   -> STOP. Dispatch agent instead.

RED FLAG: About to Write/Create source code
   -> STOP. Dispatch agent instead.

RED FLAG: About to Edit source code or CSS
   -> STOP. Dispatch agent instead.

RED FLAG: About to run "npm test" or "npx playwright test"
   -> STOP. Agent runs tests, not you.

RED FLAG: Thinking "I'll just..."
   -> STOP. "Just" is the warning word. Dispatch agent.

RED FLAG: Thinking "This is simple enough..."
   -> STOP. Simplicity is irrelevant. Dispatch agent.

RED FLAG: Standards loaded, but next action is not Task tool
   -> STOP. After standards, IMMEDIATELY dispatch agent.
```

### Recovery from Orchestrator Violation

If you violated orchestrator boundaries:

1. **STOP** current execution immediately
2. **DISCARD** any direct changes (`git checkout -- .`)
3. **DISPATCH** the correct specialist agent
4. **Agent implements** from scratch following TDD
5. **Document** the violation for feedback loop

**Sunk cost of direct work is IRRELEVANT. Agent dispatch is MANDATORY.**

---

## Blocker Criteria - STOP and Report

<block_condition>
- Gate Failure: Tests not passing, review failed -> STOP, cannot proceed to next gate
- Missing Standards: No PROJECT_RULES.md -> STOP, report blocker and wait
- Agent Failure: Specialist agent returned errors -> STOP, diagnose and report
- User Decision Required: Component library choice, design system variance -> STOP, present options
- Accessibility Blocker: WCAG AA violations found -> STOP, fix before proceeding
</block_condition>

You CANNOT proceed when blocked. Report and wait for resolution.

### Cannot Be Overridden

<cannot_skip>
- All 9 gates must execute (0->1->2->3->4->5->6->7->8) - Each gate catches different issues
- All testing gates (2-6) are MANDATORY - Comprehensive test coverage ensures quality
- Gates execute in order (0->1->2->3->4->5->6->7->8) - Dependencies exist between gates
- Gate 7 requires all 5 reviewers - Different review perspectives are complementary
- Unit test coverage threshold >= 85% - Industry standard for quality code
- WCAG 2.1 AA compliance is non-negotiable - Accessibility is a legal requirement
- Core Web Vitals thresholds are non-negotiable - Performance affects user experience
- PROJECT_RULES.md must exist - Cannot verify standards without target
</cannot_skip>

No exceptions. User cannot override. Time pressure cannot override.

---

## Severity Calibration

| Severity | Criteria | Examples |
|----------|----------|----------|
| **CRITICAL** | Blocks deployment, accessibility violation, security risk | Gate violation, WCAG AA failure, XSS vulnerability |
| **HIGH** | Major functionality broken, standards violation | Missing tests, wrong agent dispatched, performance regression |
| **MEDIUM** | Code quality, maintainability issues | Incomplete documentation, minor gaps, non-ideal patterns |
| **LOW** | Best practices, optimization | Style improvements, minor refactoring, cosmetic issues |

Report all severities. Let user prioritize.

### Reviewer Verdicts Are Final

**MEDIUM issues found in Gate 7 MUST be fixed. No exceptions.**

| Request | Why It's WRONG | Required Action |
|---------|----------------|-----------------|
| "Can reviewer clarify if MEDIUM can defer?" | Reviewer already decided. MEDIUM means FIX. | **Fix the issue, re-run reviewers** |
| "Ask if this specific case is different" | Reviewer verdict accounts for context already. | **Fix the issue, re-run reviewers** |
| "Request exception for business reasons" | Reviewers know business context. Verdict is final. | **Fix the issue, re-run reviewers** |

**Severity mapping is absolute:**
- CRITICAL/HIGH/MEDIUM -> Fix NOW, re-run all 5 reviewers
- LOW -> Add TODO(review): comment
- Cosmetic -> Add FIXME(nitpick): comment

No negotiation. No exceptions. No "special cases".

---

## The 9 Gates

| Gate | Skill | Purpose | Agent | Standards Module |
|------|-------|---------|-------|------------------|
| 0 | ring:dev-implementation | Write code following TDD | ring:frontend-engineer / ring:ui-engineer / ring:frontend-bff-engineer-typescript | frontend.md |
| 1 | ring:dev-devops | Docker/compose/Nginx setup | ring:devops-engineer | devops.md |
| 2 | ring:dev-frontend-accessibility | WCAG 2.1 AA compliance | ring:qa-analyst-frontend (test_mode: accessibility) | testing-accessibility.md |
| 3 | ring:dev-unit-testing | Unit tests 85%+ coverage | ring:qa-analyst-frontend (test_mode: unit) | frontend.md |
| 4 | ring:dev-frontend-visual | Snapshot/visual regression tests | ring:qa-analyst-frontend (test_mode: visual) | testing-visual.md |
| 5 | ring:dev-frontend-e2e | E2E tests with Playwright | ring:qa-analyst-frontend (test_mode: e2e) | testing-e2e.md |
| 6 | ring:dev-frontend-performance | Core Web Vitals + Lighthouse | ring:qa-analyst-frontend (test_mode: performance) | testing-performance.md |
| 7 | ring:requesting-code-review | Parallel code review (5 reviewers) | ring:code-reviewer, ring:business-logic-reviewer, ring:security-reviewer, ring:test-reviewer, ring:frontend-engineer (review mode) | N/A |
| 8 | ring:dev-validation | Final acceptance validation | N/A (verification) | N/A |

**All gates are MANDATORY. No exceptions. No skip reasons.**

### Gate 0: Agent Selection Logic

| Condition | Agent to Dispatch |
|-----------|-------------------|
| React/Next.js component implementation | `ring:frontend-engineer` |
| Design system / Sindarian UI component | `ring:ui-engineer` |
| BFF / API aggregation layer | `ring:frontend-bff-engineer-typescript` |
| Mixed (component + BFF) | Dispatch `ring:frontend-engineer` first, then `ring:frontend-bff-engineer-typescript` |

**UI library mode (detected in Step 0) MUST be passed to the agent as context.**

### Gate 0: Frontend TDD Policy

**TDD (RED→GREEN) applies to behavioral logic. Visual/presentational components use test-after.**

| Component Layer | TDD Required? | Where Tests Are Created | Rationale |
|-----------------|---------------|-------------------------|-----------|
| Custom hooks | YES - TDD RED→GREEN | Gate 0 (implementation) | Test defines the hook contract before code |
| Form validation | YES - TDD RED→GREEN | Gate 0 (implementation) | Test defines validation rules before code |
| State management | YES - TDD RED→GREEN | Gate 0 (implementation) | Test defines state transitions before code |
| Conditional rendering | YES - TDD RED→GREEN | Gate 0 (implementation) | Test defines when elements show/hide |
| API integration / data fetching | YES - TDD RED→GREEN | Gate 0 (implementation) | Test defines expected request/response |
| Layout / styling | NO - test-after | Gate 4 (visual testing) | Visual output is exploratory; snapshot locks it |
| Animations / transitions | NO - test-after | Gate 4 (visual testing) | Motion is iterative; test captures final state |
| Static presentational components | NO - test-after | Gate 4 (visual testing) | No logic to drive with RED phase |

**Rules:**
1. **Behavioral components** in Gate 0 MUST produce TDD RED failure output before implementation
2. **Visual/presentational components** in Gate 0 are implemented without RED phase; Gate 4 creates their snapshot tests
3. **Mixed components** (behavior + visual): TDD for the behavioral part, test-after for the visual part
4. Gate 3 (Unit Testing) coverage threshold (85%) still applies to ALL component types - the distinction is only about WHEN tests are written, not WHETHER

**Anti-Rationalization:**

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "This hook is simple, skip TDD" | Simple hooks still need contract verification. | **TDD RED→GREEN for all hooks** |
| "Form validation is visual" | Validation rules are logic, not presentation. | **TDD RED→GREEN for validation** |
| "This component has onClick, skip TDD" | Event handlers contain logic. TDD for the handler behavior. | **TDD RED→GREEN for behavioral logic** |
| "Layout needs TDD too" | Snapshot test written before layout exists is meaningless. | **Test-after in Gate 4** |
| "Skip all tests, Gate 4 handles it" | Gate 4 covers visual snapshots only. Behavioral tests are Gate 0+3. | **TDD for behavior in Gate 0** |

### Gate 7: Code Review Adaptation (5 Reviewers)

For the frontend cycle, the 5 parallel reviewers are:

| # | Reviewer | Focus Area |
|---|----------|------------|
| 1 | `ring:code-reviewer` | Code quality, patterns, maintainability, React best practices |
| 2 | `ring:business-logic-reviewer` | Business logic correctness, domain rules, acceptance criteria |
| 3 | `ring:security-reviewer` | XSS, CSRF, auth handling, sensitive data exposure, CSP |
| 4 | `ring:test-reviewer` | Test quality, coverage gaps, test patterns, assertion quality |
| 5 | `ring:frontend-engineer` (review mode) | Accessibility compliance, frontend standards, component architecture |

**NOTE:** The 5th reviewer slot uses `ring:frontend-engineer` in review mode instead of `ring:nil-safety-reviewer` (which is Go-specific). The frontend engineer reviews accessibility compliance and frontend standards adherence.

**All 5 reviewers MUST be dispatched in a single message with 5 parallel Task calls.**

```yaml
# Gate 7: Dispatch all 5 reviewers in parallel (SINGLE message)
Task 1: { subagent_type: "ring:code-reviewer", ... }
Task 2: { subagent_type: "ring:business-logic-reviewer", ... }
Task 3: { subagent_type: "ring:security-reviewer", ... }
Task 4: { subagent_type: "ring:test-reviewer", ... }
Task 5: { subagent_type: "ring:frontend-engineer", prompt: "REVIEW MODE: Review accessibility compliance and frontend standards adherence...", ... }
```

---

## Gate Completion Definition (HARD GATE)

**A gate is COMPLETE only when all components finish successfully:**

| Gate | Components Required | Partial = FAIL |
|------|---------------------|----------------|
| 0.1 | TDD-RED: Failing test written + failure output captured (behavioral components only - see [Frontend TDD Policy](#gate-0-frontend-tdd-policy)) | Test exists but no failure output = FAIL. Visual-only components skip to 0.2 |
| 0.2 | TDD-GREEN: Implementation passes test (behavioral) OR implementation complete (visual) | Code exists but test fails = FAIL |
| 0 | Both 0.1 and 0.2 complete (behavioral) OR 0.2 complete (visual - snapshots deferred to Gate 4) | 0.1 done without 0.2 = FAIL |
| 1 | Dockerfile + docker-compose/nginx + .env.example | Missing any = FAIL |
| 2 | 0 WCAG AA violations + keyboard navigation tested + screen reader tested | Any violation = FAIL |
| 3 | Unit test coverage >= 85% + all AC tested | 84% = FAIL |
| 4 | All state snapshots pass + responsive breakpoints covered | Missing snapshots = FAIL |
| 5 | All user flows tested + cross-browser (Chromium, Firefox, WebKit) + 3x stable pass | Flaky = FAIL |
| 6 | LCP < 2.5s + CLS < 0.1 + INP < 200ms + Lighthouse >= 90 | Any threshold missed = FAIL |
| 7 | All 5 reviewers PASS | 4/5 reviewers = FAIL |
| 8 | Explicit "APPROVED" from user | "Looks good" = not approved |

**CRITICAL for Gate 7:** Running 4 of 5 reviewers is not a partial pass - it's a FAIL. Re-run all 5 reviewers.

**Anti-Rationalization for Partial Gates:**

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "4 of 5 reviewers passed" | Gate 7 requires all 5. 4/5 = 0/5. | **Re-run all 5 reviewers** |
| "Gate mostly complete" | Mostly ≠ complete. Binary: done or not done. | **Complete all components** |
| "Can finish remaining in next cycle" | Gates don't carry over. Complete NOW. | **Finish current gate** |
| "No component is optional within a gate" | Every component is required. | **Complete all components** |
| "Accessibility can be fixed later" | WCAG compliance is mandatory NOW. Later = never. | **Fix accessibility in Gate 2** |
| "Visual tests are flaky, skip them" | Fix flakiness, don't skip verification. | **Stabilize and pass Gate 4** |
| "Lighthouse score is 88, close enough" | Close enough ≠ passing. Threshold is >= 90. | **Optimize until threshold met** |

---

## Gate Order Enforcement (HARD GATE)

**Gates MUST execute in order: 0 -> 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8. All 9 gates are MANDATORY.**

| Violation | Why It's WRONG | Consequence |
|-----------|----------------|-------------|
| Skip Gate 1 (DevOps) | "No infra changes" | App without container = works on my machine only |
| Skip Gate 2 (Accessibility) | "It's internal tool" | Internal tools MUST be accessible. Legal requirement. |
| Skip Gate 3 (Unit Testing) | "E2E covers it" | E2E is slow, unit tests catch logic bugs faster |
| Skip Gate 4 (Visual) | "Snapshots are brittle" | Fix brittleness, don't skip regression detection |
| Skip Gate 5 (E2E) | "Manual testing done" | Manual testing is not reproducible or automated |
| Skip Gate 6 (Performance) | "Optimize later" | Later = never. Performance budgets apply NOW |
| Reorder Gates | "Review before test" | Reviewing untested code wastes reviewer time |
| Parallel Gates | "Run 2 and 3 together" | Dependencies exist. Order is intentional. |

**All testing gates (2-6) are MANDATORY. No exceptions. No skip reasons.**

**Gates are not parallelizable across different gates. Sequential execution is MANDATORY.**

---

## Execution Order

**Core Principle:** Each execution unit passes through all 9 gates. All gates execute and complete per unit.

**Per-Unit Flow:** Unit -> Gate 0->1->2->3->4->5->6->7->8 -> Unit Checkpoint -> Task Checkpoint -> Next Unit

| Scenario | Execution Unit | Gates Per Unit |
|----------|----------------|----------------|
| Task without subtasks | Task itself | 9 gates |
| Task with subtasks | Each subtask | 9 gates per subtask |

## Commit Timing

**User selects when commits happen (during initialization).**

| Option | When Commit Happens | Use Case |
|--------|---------------------|----------|
| **(a) Per subtask** | After each subtask passes Gate 8 | Fine-grained history, easy rollback per subtask |
| **(b) Per task** | After all subtasks of a task complete | Logical grouping, one commit per feature chunk |
| **(c) At the end** | After entire cycle completes | Single commit with all changes, clean history |

### Commit Message Format

| Timing | Message Format | Example |
|--------|----------------|---------|
| Per subtask | `feat({subtask_id}): {subtask_title}` | `feat(ST-001-02): implement transaction list component` |
| Per task | `feat({task_id}): {task_title}` | `feat(T-001): implement dashboard page` |
| At the end | `feat({cycle_id}): complete frontend dev cycle for {feature}` | `feat(cycle-abc123): complete frontend dev cycle for dashboard` |

### Commit Timing vs Execution Mode

| Execution Mode | Commit Timing | Behavior |
|----------------|---------------|----------|
| Manual per subtask | Per subtask | Commit + checkpoint after each subtask |
| Manual per subtask | Per task | Checkpoint after subtask, commit after task |
| Manual per subtask | At end | Checkpoint after subtask, commit at cycle end |
| Manual per task | Per subtask | Commit after subtask, checkpoint after task |
| Manual per task | Per task | Commit + checkpoint after task |
| Manual per task | At end | Checkpoint after task, commit at cycle end |
| Automatic | Per subtask | Commit after each subtask, no checkpoints |
| Automatic | Per task | Commit after task, no checkpoints |
| Automatic | At end | Single commit at cycle end, no checkpoints |

**Note:** Checkpoints (user approval pauses) are controlled by `execution_mode`. Commits are controlled by `commit_timing`. They are independent settings.

---

## State Management

### State Path

| Task Source | State Path |
|-------------|------------|
| Any source | `docs/ring:dev-cycle-frontend/current-cycle.json` |

### State File Structure

State is persisted to `docs/ring:dev-cycle-frontend/current-cycle.json`:

```json
{
  "version": "1.0.0",
  "cycle_id": "uuid",
  "started_at": "ISO timestamp",
  "updated_at": "ISO timestamp",
  "source_file": "path/to/tasks-frontend.md",
  "state_path": "docs/ring:dev-cycle-frontend/current-cycle.json",
  "cycle_type": "frontend",
  "ui_library_mode": "sindarian-ui | fallback-only",
  "backend_handoff": {
    "loaded": true,
    "source": "docs/ring:dev-cycle/handoff-frontend.json",
    "endpoints": [],
    "types": [],
    "contracts": []
  },
  "execution_mode": "manual_per_subtask|manual_per_task|automatic",
  "commit_timing": "per_subtask|per_task|at_end",
  "custom_prompt": {
    "type": "string",
    "optional": true,
    "max_length": 500,
    "description": "User-provided context for agents (from second positional argument). Max 500 characters.",
    "validation": "Max 500 chars (truncated with warning if exceeded); whitespace trimmed; control chars stripped (except newlines)."
  },
  "status": "in_progress|completed|failed|paused|paused_for_approval|paused_for_task_approval",
  "feedback_loop_completed": false,
  "current_task_index": 0,
  "current_gate": 0,
  "current_subtask_index": 0,
  "tasks": [
    {
      "id": "T-001",
      "title": "Task title",
      "status": "pending|in_progress|completed|failed|blocked",
      "feedback_loop_completed": false,
      "subtasks": [
        {
          "id": "ST-001-01",
          "file": "subtasks/T-001/ST-001-01.md",
          "status": "pending|completed"
        }
      ],
      "gate_progress": {
        "implementation": {
          "status": "pending|in_progress|completed",
          "started_at": "...",
          "tdd_red": {
            "status": "pending|in_progress|completed",
            "test_file": "path/to/test_file.spec.tsx",
            "failure_output": "FAIL: expected element not found",
            "completed_at": "ISO timestamp"
          },
          "tdd_green": {
            "status": "pending|in_progress|completed",
            "implementation_file": "path/to/Component.tsx",
            "test_pass_output": "PASS: 12 tests passed",
            "completed_at": "ISO timestamp"
          }
        },
        "devops": {"status": "pending"},
        "accessibility": {
          "status": "pending|in_progress|completed",
          "wcag_violations": 0,
          "keyboard_nav_tested": false,
          "screen_reader_tested": false
        },
        "unit_testing": {
          "status": "pending|in_progress|completed",
          "coverage_actual": 0,
          "coverage_threshold": 85
        },
        "visual_testing": {
          "status": "pending|in_progress|completed",
          "snapshots_total": 0,
          "snapshots_passed": 0,
          "responsive_breakpoints_covered": []
        },
        "e2e_testing": {
          "status": "pending|in_progress|completed",
          "flows_tested": 0,
          "browsers_tested": [],
          "stability_runs": 0
        },
        "performance_testing": {
          "status": "pending|in_progress|completed",
          "lcp_ms": 0,
          "cls": 0,
          "inp_ms": 0,
          "lighthouse_score": 0
        },
        "review": {"status": "pending"},
        "validation": {"status": "pending"}
      },
      "agent_outputs": {
        "implementation": {
          "agent": "ring:frontend-engineer",
          "output": "## Summary\n...",
          "timestamp": "ISO timestamp",
          "duration_ms": 0,
          "iterations": 1,
          "standards_compliance": {
            "total_sections": 12,
            "compliant": 12,
            "not_applicable": 0,
            "non_compliant": 0,
            "gaps": []
          }
        },
        "devops": {
          "agent": "ring:devops-engineer",
          "output": "## Summary\n...",
          "timestamp": "ISO timestamp",
          "duration_ms": 0,
          "iterations": 1,
          "artifacts_created": ["Dockerfile", "nginx.conf", ".env.example"],
          "verification_errors": [],
          "standards_compliance": {}
        },
        "accessibility": {
          "agent": "ring:qa-analyst-frontend",
          "test_mode": "accessibility",
          "output": "## Summary\n...",
          "verdict": "PASS",
          "wcag_violations": 0,
          "keyboard_nav_issues": 0,
          "screen_reader_issues": 0,
          "iterations": 1,
          "timestamp": "ISO timestamp"
        },
        "unit_testing": {
          "agent": "ring:qa-analyst-frontend",
          "test_mode": "unit",
          "output": "## Summary\n...",
          "verdict": "PASS",
          "coverage_actual": 87.5,
          "coverage_threshold": 85,
          "iterations": 1,
          "timestamp": "ISO timestamp"
        },
        "visual_testing": {
          "agent": "ring:qa-analyst-frontend",
          "test_mode": "visual",
          "output": "## Summary\n...",
          "verdict": "PASS",
          "snapshots_total": 15,
          "snapshots_passed": 15,
          "iterations": 1,
          "timestamp": "ISO timestamp"
        },
        "e2e_testing": {
          "agent": "ring:qa-analyst-frontend",
          "test_mode": "e2e",
          "output": "## Summary\n...",
          "verdict": "PASS",
          "flows_tested": 5,
          "browsers_tested": ["chromium", "firefox", "webkit"],
          "stability_runs": 3,
          "iterations": 1,
          "timestamp": "ISO timestamp"
        },
        "performance_testing": {
          "agent": "ring:qa-analyst-frontend",
          "test_mode": "performance",
          "output": "## Summary\n...",
          "verdict": "PASS",
          "lcp_ms": 2100,
          "cls": 0.05,
          "inp_ms": 150,
          "lighthouse_score": 93,
          "iterations": 1,
          "timestamp": "ISO timestamp"
        },
        "review": {
          "iterations": 1,
          "timestamp": "ISO timestamp",
          "duration_ms": 0,
          "code_reviewer": {
            "agent": "ring:code-reviewer",
            "output": "...",
            "verdict": "PASS",
            "issues": []
          },
          "business_logic_reviewer": {
            "agent": "ring:business-logic-reviewer",
            "output": "...",
            "verdict": "PASS",
            "issues": []
          },
          "security_reviewer": {
            "agent": "ring:security-reviewer",
            "output": "...",
            "verdict": "PASS",
            "issues": []
          },
          "test_reviewer": {
            "agent": "ring:test-reviewer",
            "output": "...",
            "verdict": "PASS",
            "issues": []
          },
          "frontend_engineer_reviewer": {
            "agent": "ring:frontend-engineer",
            "mode": "review",
            "output": "...",
            "verdict": "PASS",
            "issues": []
          }
        },
        "validation": {
          "result": "approved|rejected",
          "timestamp": "ISO timestamp"
        }
      }
    }
  ],
  "metrics": {
    "total_duration_ms": 0,
    "gate_durations": {},
    "review_iterations": 0,
    "testing_iterations": 0
  }
}
```

### Populating Structured Data

**Each gate MUST populate its structured fields when saving to state:**

| Gate | Fields to Populate |
|------|-------------------|
| Gate 0 (Implementation) | `standards_compliance` (total, compliant, gaps[]) |
| Gate 1 (DevOps) | `standards_compliance` + `verification_errors[]` |
| Gate 2 (Accessibility) | `wcag_violations` + `keyboard_nav_issues` + `screen_reader_issues` |
| Gate 3 (Unit Testing) | `standards_compliance` + `coverage_actual` + `failures[]` |
| Gate 4 (Visual Testing) | `snapshots_total` + `snapshots_passed` + `responsive_breakpoints_covered[]` |
| Gate 5 (E2E Testing) | `flows_tested` + `browsers_tested[]` + `stability_runs` |
| Gate 6 (Performance) | `lcp_ms` + `cls` + `inp_ms` + `lighthouse_score` |
| Gate 7 (Review) | `issues[]` per reviewer + `verdict` per reviewer |

**Empty arrays `[]` indicate no issues found - this is valid data for feedback-loop.**

---

## State Persistence Rule (MANDATORY)

**"Update state" means BOTH update the object and write to file. Not just in-memory.**

### After every Gate Transition

You MUST execute these steps after completing any gate:

```yaml
# Step 1: Update state object with gate results
state.tasks[current_task_index].gate_progress.[gate_name].status = "completed"
state.tasks[current_task_index].gate_progress.[gate_name].completed_at = "[ISO timestamp]"
state.current_gate = [next_gate_number]
state.updated_at = "[ISO timestamp]"

# Step 2: Write to file (MANDATORY - use Write tool)
Write tool:
  file_path: "docs/ring:dev-cycle-frontend/current-cycle.json"
  content: [full JSON state]

# Step 3: Verify persistence (MANDATORY - use Read tool)
Read tool:
  file_path: "docs/ring:dev-cycle-frontend/current-cycle.json"
# Confirm current_gate and gate_progress match expected values
```

### State Persistence Checkpoints

| After | MUST Update | MUST Write File |
|-------|-------------|-----------------|
| Gate 0.1 (TDD-RED) | `tdd_red.status`, `tdd_red.failure_output` | YES |
| Gate 0.2 (TDD-GREEN) | `tdd_green.status`, `implementation.status` | YES |
| Gate 1 (DevOps) | `devops.status`, `agent_outputs.devops` | YES |
| Gate 2 (Accessibility) | `accessibility.status`, `agent_outputs.accessibility` | YES |
| Gate 3 (Unit Testing) | `unit_testing.status`, `agent_outputs.unit_testing` | YES |
| Gate 4 (Visual Testing) | `visual_testing.status`, `agent_outputs.visual_testing` | YES |
| Gate 5 (E2E Testing) | `e2e_testing.status`, `agent_outputs.e2e_testing` | YES |
| Gate 6 (Performance) | `performance_testing.status`, `agent_outputs.performance_testing` | YES |
| Gate 7 (Review) | `review.status`, `agent_outputs.review` | YES |
| Gate 8 (Validation) | `validation.status`, task `status` | YES |
| Unit Approval | `status = "paused_for_approval"` | YES |
| Task Approval | `status = "paused_for_task_approval"` | YES |

### Anti-Rationalization for State Persistence

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "I'll save state at the end" | Crash/timeout loses all progress | **Save after each gate** |
| "State is in memory, that's updated" | Memory is volatile. File is persistent. | **Write to JSON file** |
| "Only save on checkpoints" | Gates without saves = unrecoverable on resume | **Save after every gate** |
| "Write tool is slow" | Write takes <100ms. Lost progress takes hours. | **Write after every gate** |
| "I updated the state variable" | Variable ≠ file. Without Write tool, nothing persists. | **Use Write tool explicitly** |

---

## Checkpoint Modes

**User selects checkpoint mode during initialization.**

| Mode | Checkpoint Behavior | Gate Behavior |
|------|---------------------|---------------|
| **Manual per subtask** | Pause after each subtask completes all 9 gates | All 9 gates execute without pause |
| **Manual per task** | Pause after all subtasks of a task complete | All 9 gates execute without pause |
| **Automatic** | No pauses | All 9 gates execute without pause |

**CRITICAL:** Execution mode affects CHECKPOINTS (user approval pauses), not GATES (quality checks). All gates execute regardless of mode.

### Checkpoint Questions

**Unit Checkpoint (after subtask completes Gate 8):**

**VISUAL CHANGE REPORT (MANDATORY - before checkpoint question):**
- MANDATORY: Invoke `Skill("ring:visual-explainer")` to generate a code-diff HTML report for this execution unit
- Read `default/skills/visual-explainer/templates/code-diff.html` to absorb the patterns before generating
- Content sourced from state JSON `agent_outputs` for the current unit:
  * **TDD Output:** `tdd_red` (failing test) + `tdd_green` (implementation)
  * **Files Changed:** Per-file before/after diff panels using `git diff` data from the implementation (do not read source files directly — use diff output provided by the implementation agent)
  * **Frontend-Specific Metrics:** WCAG violations resolved (Gate 2), visual snapshot pass rate (Gate 4), LCP/CLS/INP values (Gate 6), Lighthouse score (Gate 6)
  * **Review Verdicts:** Summary of all 5 reviewer verdicts from Gate 7
- Save to: `docs/ring:dev-cycle-frontend/reports/unit-{unit_id}-report.html`
- Open in browser:
  ```text
  macOS: open docs/ring:dev-cycle-frontend/reports/unit-{unit_id}-report.html
  Linux: xdg-open docs/ring:dev-cycle-frontend/reports/unit-{unit_id}-report.html
  ```
- Tell the user the file path
- See [shared-patterns/anti-rationalization-visual-report.md](../shared-patterns/anti-rationalization-visual-report.md) for anti-rationalization table

```text
Subtask {id} complete. All 9 gates passed.
(a) Continue to next subtask
(b) Pause cycle (save state for --resume)
(c) Abort cycle
```

**Task Checkpoint (after all subtasks of a task complete):**

**VISUAL CHANGE REPORT (MANDATORY - before task checkpoint question):**
- MANDATORY: Invoke `Skill("ring:visual-explainer")` to generate an aggregate code-diff HTML report for all subtasks
- Read `default/skills/visual-explainer/templates/code-diff.html` to absorb the patterns before generating
- Content aggregated from all subtask executions:
  * **Task Overview:** Task ID, title, all subtask IDs and their gate statuses
  * **Combined File Changes:** All files modified across all subtasks with before/after diff panels
  * **Aggregate Metrics:** Total tests added, total review iterations, total lines changed, accessibility score, performance score
- Save to: `docs/ring:dev-cycle-frontend/reports/task-{task_id}-report.html`
- Open in browser:
  ```text
  macOS: open docs/ring:dev-cycle-frontend/reports/task-{task_id}-report.html
  Linux: xdg-open docs/ring:dev-cycle-frontend/reports/task-{task_id}-report.html
  ```
- Tell the user the file path
- See [shared-patterns/anti-rationalization-visual-report.md](../shared-patterns/anti-rationalization-visual-report.md) for anti-rationalization table

```text
Task {id} complete. All subtasks passed all gates.
(a) Continue to next task
(b) Pause cycle
(c) Abort cycle
```

---

## Step 0: Verify PROJECT_RULES.md Exists (HARD GATE)

**NON-NEGOTIABLE. Cycle CANNOT proceed without project standards.**

Same flow as backend `ring:dev-cycle`:

```text
Check: Does docs/PROJECT_RULES.md exist?

  YES -> Proceed to Step 1 (Initialize or Resume)

  NO -> ASK: "Is this a LEGACY project?"
    YES (legacy) -> Dispatch ring:codebase-explorer + ask 3 questions + generate PROJECT_RULES.md
    NO (new) -> Check for PM documents (PRD/TRD/Feature Map)
      HAS PM docs -> Generate PROJECT_RULES.md from PM docs
      NO PM docs -> HARD BLOCK: "Run /ring:pre-dev-full or /ring:pre-dev-feature first"
```

---

## Step 1: Initialize or Resume

### Prompt-Only Mode (no task file)

**Input:** Direct prompt without a task file path (e.g., `/ring:dev-cycle-frontend Implement dashboard with transaction list`)

1. **Detect prompt-only mode:** No task file argument provided
2. **Analyze prompt:** Extract intent, scope, and frontend requirements
3. **Explore codebase:** Dispatch `ring:codebase-explorer` to understand project structure
4. **Generate tasks:** Create task structure internally based on prompt + codebase analysis
5. **Present generated tasks:** Show user the auto-generated task breakdown
6. **Confirm with user:** "I generated X tasks from your prompt. Proceed?"
7. **Continue to execution mode selection**

### New Cycle (with task file path)

**Input:** `path/to/tasks-frontend.md` or `path/to/pre-dev/{feature}/` with optional second argument for custom instructions

**Examples:**
- `/ring:dev-cycle-frontend tasks.md`
- `/ring:dev-cycle-frontend tasks.md "Use shadcn/ui components"`

1. **Detect input:** File -> Load directly | Directory -> Load tasks-frontend.md + discover subtasks/
2. **Build order:** Read tasks, check for subtasks (ST-XXX-01, 02...)
3. **Detect UI library mode** (Step 0 above)
4. **Load backend handoff** if `docs/ring:dev-cycle/handoff-frontend.json` exists
5. **Capture and validate custom instructions:** If second argument provided
6. **Initialize state:** Generate cycle_id, create state file, set indices to 0
7. **Display plan:** "Loaded X tasks with Y subtasks. UI mode: {mode}. Backend handoff: {loaded/not found}."
8. **ASK EXECUTION MODE (MANDATORY - AskUserQuestion):**
   - Options: (a) Manual per subtask (b) Manual per task (c) Automatic
   - **Do not skip:** User hints ≠ mode selection. Only explicit a/b/c is valid.
9. **ASK COMMIT TIMING (MANDATORY - AskUserQuestion):**
   - Options: (a) Per subtask (b) Per task (c) At the end
   - Store in `commit_timing` field in state
10. **Start:** Display mode + commit timing, proceed to Gate 0

### Resume Cycle (--resume flag)

1. **Find existing state file:** Check `docs/ring:dev-cycle-frontend/current-cycle.json`
   - If not found -> Error: "No frontend cycle to resume"
2. Load state file, validate
3. Display: cycle started, tasks completed/total, current task/subtask/gate, paused reason
4. **Handle paused states:**

| Status | Action |
|--------|--------|
| `paused_for_approval` | Re-present unit checkpoint |
| `paused_for_task_approval` | Re-present task checkpoint |
| `paused` (generic) | Ask user to confirm resume |
| `in_progress` | Resume from current gate |

---

## Step 2-10: Gate Execution (Per Unit)

### Step 2: Gate 0 - Implementation

**REQUIRED SUB-SKILL:** `Skill("ring:dev-implementation")`

Dispatch appropriate frontend agent based on task type. Agent follows TDD (RED then GREEN) with frontend.md standards.

### Step 3: Gate 1 - DevOps

**REQUIRED SUB-SKILL:** `Skill("ring:dev-devops")`

Dispatch `ring:devops-engineer` for Dockerfile, docker-compose, Nginx configuration, and .env.example.

### Step 4: Gate 2 - Accessibility

**REQUIRED SUB-SKILL:** `Skill("ring:dev-frontend-accessibility")`

Dispatch `ring:qa-analyst-frontend` with `test_mode="accessibility"`. MUST verify:
- 0 WCAG 2.1 AA violations (axe-core scan)
- Keyboard navigation works for all interactive elements
- Screen reader announcements are correct
- Focus management is proper
- Color contrast ratios meet AA thresholds

### Step 5: Gate 3 - Unit Testing

**REQUIRED SUB-SKILL:** `Skill("ring:dev-unit-testing")`

Dispatch `ring:qa-analyst-frontend` with `test_mode="unit"`. MUST verify:
- Coverage >= 85%
- All acceptance criteria have corresponding tests
- Component rendering, state management, and event handlers tested
- Edge cases covered (empty states, error states, loading states)

### Step 6: Gate 4 - Visual Testing

**REQUIRED SUB-SKILL:** `Skill("ring:dev-frontend-visual")`

Dispatch `ring:qa-analyst-frontend` with `test_mode="visual"`. MUST verify:
- All component states have snapshots (default, hover, active, disabled, error, loading)
- Responsive breakpoints covered (mobile, tablet, desktop)
- Design system compliance verified
- Visual regression baseline established

### Step 7: Gate 5 - E2E Testing

**REQUIRED SUB-SKILL:** `Skill("ring:dev-frontend-e2e")`

Dispatch `ring:qa-analyst-frontend` with `test_mode="e2e"`. MUST verify:
- All user flows tested end-to-end
- Cross-browser: Chromium, Firefox, WebKit
- 3x consecutive stable pass (no flakiness)
- Page object pattern used for maintainability

### Step 8: Gate 6 - Performance Testing

**REQUIRED SUB-SKILL:** `Skill("ring:dev-frontend-performance")`

Dispatch `ring:qa-analyst-frontend` with `test_mode="performance"`. MUST verify:
- LCP (Largest Contentful Paint) < 2.5s
- CLS (Cumulative Layout Shift) < 0.1
- INP (Interaction to Next Paint) < 200ms
- Lighthouse Performance score >= 90
- Bundle size within budget (if defined in PROJECT_RULES.md)

### Step 9: Gate 7 - Code Review

**REQUIRED SUB-SKILL:** `Skill("ring:requesting-code-review")`

Dispatch all 5 reviewers in parallel (see Gate 7: Code Review Adaptation above).

### Step 10: Gate 8 - Validation

**REQUIRED SUB-SKILL:** `Skill("ring:dev-validation")`

Present implementation summary to user. Require explicit "APPROVED" response. "Looks good" or silence ≠ approved.

---

## Execution Report

Base metrics per [shared-patterns/output-execution-report.md](../shared-patterns/output-execution-report.md):

| Metric | Value |
|--------|-------|
| Duration | Xm Ys |
| Iterations | N |
| Result | PASS/FAIL/PARTIAL |

### Frontend-Specific Metrics

| Metric | Value |
|--------|-------|
| UI Library Mode | sindarian-ui / fallback-only |
| Backend Handoff | loaded / not found |
| WCAG Violations | 0 |
| Unit Coverage | XX.X% |
| Visual Snapshots | X/Y passed |
| E2E Stability | 3/3 runs |
| LCP | Xms |
| CLS | X.XX |
| INP | Xms |
| Lighthouse | XX |
| Reviewers | 5/5 PASS |

---

## Pressure Resistance

See [shared-patterns/shared-pressure-resistance.md](../shared-patterns/shared-pressure-resistance.md) for universal pressure scenarios.

**Frontend-specific pressure scenarios:**

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| **Accessibility** | "Skip accessibility, it's an internal tool" | "FORBIDDEN. Internal tools MUST be accessible. WCAG AA is a legal requirement in many jurisdictions. Gate 2 executes fully." |
| **Browser Coverage** | "Only test Chromium, it's the main browser" | "All 3 browsers (Chromium, Firefox, WebKit) are REQUIRED. Cross-browser issues are the most common production bugs." |
| **Performance** | "Performance will be optimized later" | "Performance thresholds apply NOW. LCP < 2.5s, CLS < 0.1, INP < 200ms, Lighthouse >= 90. Later = never." |
| **Visual Tests** | "Snapshots are too brittle to maintain" | "Fix the brittleness (use threshold tolerances), don't skip regression detection. Gate 4 is MANDATORY." |
| **Design System** | "We'll align with design system later" | "Design system compliance is part of Gate 0. Components MUST use Sindarian UI (or shadcn fallback) from the start." |

**Gate-specific note:** Execution mode selection affects CHECKPOINTS (user approval pauses), not GATES (quality checks). All gates execute regardless of mode.

---

## Common Rationalizations - REJECTED

See [shared-patterns/shared-anti-rationalization.md](../shared-patterns/shared-anti-rationalization.md) for universal anti-rationalizations.

**Frontend-specific rationalizations:**

| Excuse | Reality |
|--------|---------|
| "Backend already tested this endpoint" | Backend tests verify API logic. Frontend tests verify UI rendering, state management, user interaction, and accessibility. Different concerns entirely. |
| "Accessibility is optional for MVP" | Accessibility is NEVER optional. WCAG AA compliance is mandatory. Building without it means expensive retrofitting later. |
| "Snapshots are brittle and slow down development" | Snapshots catch visual regressions that no other test type detects. Fix brittleness with tolerances, don't skip the gate. |
| "E2E tests are slow, unit tests are enough" | Unit tests verify components in isolation. E2E tests verify user flows end-to-end. Both are MANDATORY because they catch different issues. |
| "Lighthouse score is close enough at 88" | Close enough ≠ passing. Threshold is >= 90. Optimize bundle size, lazy load, compress images until threshold is met. |
| "Automatic mode means faster" | Automatic mode skips CHECKPOINTS, not GATES. Same quality, less interruption. |
| "Only desktop matters, skip mobile testing" | Responsive design is mandatory. Visual tests MUST cover mobile, tablet, and desktop breakpoints. |
| "This component is reused from design system" | Reused components still need tests in context. Integration point testing is required. |

---

## Red Flags - STOP

See [shared-patterns/shared-red-flags.md](../shared-patterns/shared-red-flags.md) for universal red flags.

**Frontend-specific red flags:**

- "Skip accessibility, we'll add ARIA labels later"
- "Only test happy path in E2E"
- "Performance optimization is a separate ticket"
- "Visual tests will be added when design stabilizes"
- "The designer didn't provide mobile mockups, skip responsive"
- "This browser doesn't matter for our users"
- "It works in Chromium, ship it"

If you catch yourself thinking any of those patterns, STOP immediately and return to gate execution.

---

## Incremental Compromise Prevention

**The "just this once" pattern leads to complete gate erosion:**

```text
Day 1: "Skip accessibility just this once" -> Approved (precedent set)
Day 2: "Skip visual tests, we did it last time" -> Approved (precedent extended)
Day 3: "Skip performance, pattern established" -> Approved (gates meaningless)
Day 4: Production incident: inaccessible UI + layout regression + 5s load time
```

**Prevention rules:**
1. **No incremental exceptions** - Each exception becomes the new baseline
2. **Document every pressure** - Log who requested, why, outcome
3. **Escalate patterns** - If same pressure repeats, escalate to team lead
4. **Gates are binary** - Complete or incomplete. No "mostly done".

---

## Input Validation

Task files are generated by `/ring:pre-dev-*` or backend handoff. The ring:dev-cycle-frontend performs basic format checks:

### Format Checks

| Check | Validation | Action |
|-------|------------|--------|
| File exists | Task file path is readable | Error: abort |
| Task headers | At least one `## Task:` found | Error: abort |
| Task ID format | `## Task: {ID} - {Title}` | Warning: use line number as ID |
| Acceptance criteria | At least one `- [ ]` per task | Warning: task may fail validation gate |
