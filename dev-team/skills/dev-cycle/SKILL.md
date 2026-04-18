---
name: ring:dev-cycle
description: |
  10-gate development cycle orchestrator with subtask/task/cycle cadence classification.
  Subtask-level gates: implementation (includes delivery verification exit check), unit testing, validation.
  Task-level gates: devops, SRE, fuzz, property, integration (write), chaos (write), review (8 reviewers on cumulative task diff).
  Cycle-end: integration execute, chaos execute, multi-tenant verify, dev-report aggregate, final commit.
  State schema v1.1.0.

trigger: |
  - Starting a new development cycle with a task file
  - Resuming an interrupted development cycle (--resume flag)
  - Need structured, gate-based task execution with quality checkpoints

skip_when: |
  - No tasks file exists or no structured subtasks to execute
  - Task is documentation-only, research-only, or planning-only
  - User explicitly requested manual workflow without gates
  - Already inside a specific gate skill execution (avoid nesting)
  - Frontend project (use ring:dev-cycle-frontend instead)

prerequisites: |
  - Tasks file exists with structured subtasks
  - Not already in a specific gate skill execution
  - Human has not explicitly requested manual workflow

NOT_skip_when: |
  - "Task is simple" → Simple ≠ risk-free. Execute gates.
  - "Tests already pass" → Tests ≠ review. Different concerns.
  - "Time pressure" → Pressure ≠ permission. Document and proceed.
  - "Already did N gates" → Sunk cost is irrelevant. Complete all gates.

sequence:
  before: [ring:dev-report]

related:
  complementary: [ring:dev-implementation, ring:dev-devops, ring:dev-sre, ring:dev-unit-testing, ring:codereview, ring:dev-validation, ring:dev-report, ring:dev-delivery-verification]

verification:
  automated:
    - command: "test -f docs/ring:dev-cycle/current-cycle.json || test -f docs/ring:dev-refactor/current-cycle.json"
      description: "State file exists (ring:dev-cycle or ring:dev-refactor)"
      success_pattern: "exit 0"
    - command: "cat docs/ring:dev-cycle/current-cycle.json 2>/dev/null || cat docs/ring:dev-refactor/current-cycle.json | jq '.current_gate'"
      description: "Current gate is valid"
      success_pattern: '[0-5]|0\.5'
  manual:
    - "All gates for current task show PASS in state file"
    - "No tasks have status 'blocked' for more than 3 iterations"
---

# Development Cycle Orchestrator

## Standards Loading (MANDATORY)

**Before any gate execution, you MUST load Ring standards:**

<fetch_required>
https://raw.githubusercontent.com/LerianStudio/ring/main/CLAUDE.md
</fetch_required>

Fetch URL above and extract: Agent Modification Verification requirements, Anti-Rationalization Tables requirements, and Critical Rules.

<block_condition>
- WebFetch fails or returns empty
- CLAUDE.md not accessible
</block_condition>

If any condition is true, STOP and report blocker. Cannot proceed without Ring standards.

## Overview

The development cycle orchestrator loads tasks/subtasks from PM team output (or manual task files) and executes through 10 gates (Gate 0–9) at three cadences (subtask / task / cycle). Gate 0 includes delivery verification as an inline exit check. **Deferred execution** applies for infrastructure-dependent tests:

- **Gates 0-5, 8-9 (per unit):** Write code + run tests per task/subtask
- **Gates 6-7 (per unit):** Write/update integration and chaos test code, verify compilation, but do **not execute** tests (no containers)
- **Gates 6-7 (end of cycle):** Execute all integration and chaos tests once after all units complete

This keeps test code current with each feature while avoiding redundant container spin-ups during development.

**MUST announce at start:** "I'm using the ring:dev-cycle skill to orchestrate task execution through 10 gates (Gate 0–9). Subtask-level: 0 (implementation + delivery verification exit check), 3 (unit testing), 9 (validation). Task-level (after all subtasks): 1 (devops), 2 (SRE), 4 (fuzz), 5 (property), 6 write (integration), 7 write (chaos), 8 (review — 8 reviewers). Cycle-end: gates 6/7 execute mode, multi-tenant verify, dev-report, final commit."

## ⛔ CRITICAL: Specialized Agents Perform All Tasks

See [shared-patterns/shared-orchestrator-principle.md](../shared-patterns/shared-orchestrator-principle.md) for full ORCHESTRATOR principle, role separation, forbidden/required actions, gate-to-agent mapping, and anti-rationalization table.

**Summary:** You orchestrate. Agents execute. If using Read/Write/Edit/Bash on source code → STOP. Dispatch agent.

---

## ⛔ ORCHESTRATOR BOUNDARIES (HARD GATE)

**This section defines exactly what the orchestrator CAN and CANNOT do.**

### What Orchestrator CAN Do (PERMITTED)

| Action | Tool | Purpose |
|--------|------|---------|
| Read task files | `Read` | Load task definitions from `docs/pre-dev/*/tasks.md` or `docs/ring:dev-refactor/*/tasks.md` |
| Read state files | `Read` | Load/verify `docs/ring:dev-cycle/current-cycle.json` or `docs/ring:dev-refactor/current-cycle.json` |
| Read PROJECT_RULES.md | `Read` | Load project-specific rules |
| Write state files | `Write` | Persist cycle state to JSON |
| Track progress | `TodoWrite` | Maintain task list |
| Dispatch agents | `Task` | Send work to specialist agents |
| Ask user questions | `AskUserQuestion` | Get execution mode, approvals |
| WebFetch standards | `WebFetch` | Load Ring standards |

### What Orchestrator CANNOT Do (FORBIDDEN)

<forbidden>
- Read source code (`Read` on `*.go`, `*.ts`, `*.tsx`) - Agent reads code, not orchestrator
- Write source code (`Write`/`Create` on `*.go`, `*.ts`) - Agent writes code, not orchestrator
- Edit source code (`Edit` on `*.go`, `*.ts`, `*.tsx`) - Agent edits code, not orchestrator
- Run tests (`Execute` with `go test`, `npm test`) - Agent runs tests in TDD cycle
- Analyze code (Direct pattern analysis) - `ring:codebase-explorer` analyzes
- Make architectural decisions (Choosing patterns/libraries) - User decides, agent implements
</forbidden>

Any of these actions by orchestrator = IMMEDIATE VIOLATION. Dispatch agent instead.

---

### The 3-FILE RULE

**If a task requires editing MORE than 3 files → MUST dispatch specialist agent.**

This is not negotiable:
- 1-3 files of non-source content (markdown, json, yaml) → Orchestrator MAY edit directly
- 1+ source code files (`*.go`, `*.ts`, `*.tsx`) → MUST dispatch agent
- 4+ files of any type → MUST dispatch agent

### Orchestrator Workflow Order (MANDATORY)

```text
┌─────────────────────────────────────────────────────────────────┐
│  CORRECT WORKFLOW ORDER                                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. Load task file (Read docs/pre-dev/*/tasks.md or docs/ring:dev-refactor/*/tasks.md) │
│  2. Ask execution mode (AskUserQuestion)                        │
│  3. Determine state path + Check/Load state (see State Path Selection) │
│  4. WebFetch Ring Standards                                     │
│  5. ⛔ LOAD SUB-SKILL for current gate (Skill tool)            │
│  6. Execute sub-skill instructions (dispatch agent via Task)    │
│  7. Wait for agent completion                                   │
│  8. Verify agent output (Standards Coverage Table)              │
│  9. Update state (Write to JSON)                               │
│  10. Proceed to next gate                                       │
│                                                                 │
│  ════════════════════════════════════════════════════════════   │
│  ❌ WRONG: Load → Mode → Standards → Task(agent) directly       │
│  ✅ RIGHT: Load → Mode → Standards → Skill(sub) → Task(agent)   │
│  ════════════════════════════════════════════════════════════   │
└─────────────────────────────────────────────────────────────────┘
```

### ⛔ SUB-SKILL LOADING IS MANDATORY (HARD GATE)

**Before dispatching any agent, you MUST load the corresponding sub-skill first.**

<cannot_skip>
- Gate 0: `Skill("ring:dev-implementation")` → then `Task(subagent_type="ring:backend-engineer-*", ...)`. **Gate 0 includes delivery verification exit check inline** (a sub-check of ring:dev-implementation Step 7): verifies all requirements are DELIVERED (not just created), catches dead code, unwired structs, unregistered middleware, and runs 7 automated checks: (A) file size ≤300 lines, (B) license headers, (C) linting, (D) migration safety, (E) vulnerability scanning, (F) API backward compatibility, (G) multi-tenant dual-mode. FAIL → ring:dev-implementation re-iterates with fix instructions.
- Gate 1: `Skill("ring:dev-devops")` → then `Task(subagent_type="ring:devops-engineer", ...)`
- Gate 2: `Skill("ring:dev-sre")` → then `Task(subagent_type="ring:sre", ...)`
- Gate 3: `Skill("ring:dev-unit-testing")` → then `Task(subagent_type="ring:qa-analyst", test_mode="unit", ...)`
- Gate 4: `Skill("ring:dev-fuzz-testing")` → then `Task(subagent_type="ring:qa-analyst", test_mode="fuzz", ...)`
- Gate 5: `Skill("ring:dev-property-testing")` → then `Task(subagent_type="ring:qa-analyst", test_mode="property", ...)`
- Gate 6: `Skill("ring:dev-integration-testing")` → per unit: write/update tests + compile check (no execution); end of cycle: execute
- Gate 7: `Skill("ring:dev-chaos-testing")` → per unit: write/update tests + compile check (no execution); end of cycle: execute
- Gate 8: `Skill("ring:codereview")` → then 5x `Task(...)` in parallel
- Gate 9: `Skill("ring:dev-validation")` → N/A (verification only)
</cannot_skip>

Between "WebFetch standards" and "Task(agent)" there MUST be "Skill(sub-skill)".

**The workflow for each gate is:**
```text
1. Skill("[sub-skill-name]")     ← Load sub-skill instructions
2. Follow sub-skill instructions  ← Sub-skill tells you HOW to dispatch
3. Task(subagent_type=...)       ← Dispatch agent as sub-skill instructs
4. Validate agent output          ← Per sub-skill validation rules
5. Update state                   ← Record results
```

### Custom Instructions (Optional Second Argument)

**Validation:** See [shared-patterns/custom-prompt-validation.md](../shared-patterns/custom-prompt-validation.md) for max length (500 chars), sanitization rules, gate protection, and conflict handling.

**If `custom_prompt` is set in state, inject it into ALL agent dispatches:**

```yaml
Task tool:
  subagent_type: "ring:backend-engineer-golang"
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
| "Focus on error handling first" | Agents prioritize error-related acceptance criteria |
| "Use existing UserRepository interface" | Agents integrate with specified interface instead of creating new |
| "Deprioritize UI polish" | Gate 3 still enforces 85% coverage, but agents deprioritize non-functional UI tweaks |
| "Prioritize observability gaps" | SRE gate gets more attention, implementation focuses on instrumentation |

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
| "It's just one small file" | File count doesn't determine agent need. Language does. | **DISPATCH specialist agent** |
| "I already loaded the standards" | Loading standards ≠ permission to implement. Standards are for AGENTS. | **DISPATCH specialist agent** |
| "Agent dispatch adds overhead" | Overhead ensures compliance. Skip = skip verification. | **DISPATCH specialist agent** |
| "I can write Go/TypeScript" | Knowing language ≠ having Ring standards loaded. Agent has them. | **DISPATCH specialist agent** |
| "Just a quick fix" | "Quick" is irrelevant. all source changes require specialist. | **DISPATCH specialist agent** |
| "I'll read the file first to understand" | Reading source → temptation to edit. Agent reads for you. | **DISPATCH specialist agent** |
| "Let me check if tests pass first" | Agent runs tests in TDD cycle. You don't run tests. | **DISPATCH specialist agent** |

### Red Flags - Orchestrator Violation in Progress

**If you catch yourself doing any of these, STOP IMMEDIATELY:**

```text
🚨 RED FLAG: About to Read *.go or *.ts file
   → STOP. Dispatch agent instead.

🚨 RED FLAG: About to Write/Create source code
   → STOP. Dispatch agent instead.

🚨 RED FLAG: About to Edit source code
   → STOP. Dispatch agent instead.

🚨 RED FLAG: About to run "go test" or "npm test"
   → STOP. Agent runs tests, not you.

🚨 RED FLAG: Thinking "I'll just..."
   → STOP. "Just" is the warning word. Dispatch agent.

🚨 RED FLAG: Thinking "This is simple enough..."
   → STOP. Simplicity is irrelevant. Dispatch agent.

🚨 RED FLAG: Standards loaded, but next action is not Task tool
   → STOP. After standards, IMMEDIATELY dispatch agent.
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
- Gate Failure: Tests not passing, review failed → STOP, cannot proceed to next gate
- Missing Standards: No PROJECT_RULES.md → STOP, report blocker and wait
- Agent Failure: Specialist agent returned errors → STOP, diagnose and report
- User Decision Required: Architecture choice, framework selection → STOP, present options
</block_condition>

You CANNOT proceed when blocked. Report and wait for resolution.

### Cannot Be Overridden

<cannot_skip>
- All 10 gates must execute across their respective cadences: Subtask loop (Gate 0 → 3 → 9), then Task-level (Gate 1 → 2 → 4 → 5 → 6 write → 7 write → 8), then Cycle-end (Gate 6 execute → 7 execute → multi-tenant verify → dev-report → final commit).
- Gate 0 includes delivery verification exit check inline (MUST NOT dispatch a separate gate for delivery verification).
- All testing gates (3-7) are MANDATORY - Comprehensive test coverage ensures quality
- Gate 8 requires all 8 reviewers - Different review perspectives are complementary
- Coverage threshold ≥ 85% - Industry standard for quality code
- PROJECT_RULES.md must exist - Cannot verify standards without target
</cannot_skip>

No exceptions. User cannot override. Time pressure cannot override.

---

## Severity Calibration

| Severity | Criteria | Examples |
|----------|----------|----------|
| **CRITICAL** | Blocks deployment, security risk, data loss | Gate violation, skipped mandatory step |
| **HIGH** | Major functionality broken, standards violation | Missing tests, wrong agent dispatched |
| **MEDIUM** | Code quality, maintainability issues | Incomplete documentation, minor gaps |
| **LOW** | Best practices, optimization | Style improvements, minor refactoring |

Report all severities. Let user prioritize.

### Reviewer Verdicts Are Final

**MEDIUM issues found in Gate 4 MUST be fixed. No exceptions.**

| Request | Why It's WRONG | Required Action |
|---------|----------------|-----------------|
| "Can reviewer clarify if MEDIUM can defer?" | Reviewer already decided. MEDIUM means FIX. | **Fix the issue, re-run reviewers** |
| "Ask if this specific case is different" | Reviewer verdict accounts for context already. | **Fix the issue, re-run reviewers** |
| "Request exception for business reasons" | Reviewers know business context. Verdict is final. | **Fix the issue, re-run reviewers** |

**Severity mapping is absolute:**
- CRITICAL/HIGH/MEDIUM → Fix NOW, re-run all 8 reviewers
- LOW → Add TODO(review): comment
- Cosmetic → Add FIXME(nitpick): comment

No negotiation. No exceptions. No "special cases".

---

## Pressure Resistance

See [shared-patterns/shared-pressure-resistance.md](../shared-patterns/shared-pressure-resistance.md) for universal pressure scenarios.

**Gate-specific note:** Execution mode selection affects CHECKPOINTS (user approval pauses), not GATES (quality checks). all gates execute regardless of mode.

---

## Common Rationalizations - REJECTED

See [shared-patterns/shared-anti-rationalization.md](../shared-patterns/shared-anti-rationalization.md) for universal anti-rationalizations.

**Gate-specific rationalizations:**

| Excuse | Reality |
|--------|---------|
| "Automatic mode means faster" | Automatic mode skips CHECKPOINTS, not GATES. Same quality, less interruption. |
| "Automatic mode will skip review" | Automatic mode affects user approval pauses, not quality gates. all gates execute regardless. |
| "Defense in depth exists (frontend validates)" | Frontend can be bypassed. Backend is the last line. Fix at source. |
| "Backlog the Medium issue, it's documented" | Documented risk ≠ mitigated risk. Medium in Gate 4 = fix NOW, not later. |
| "Risk-based prioritization allows deferral" | Gates ARE the risk-based system. Reviewers define severity, not you. |
| "I'll WebFetch standards again for this gate" | Standards are pre-cached at Step 1.5 in `state.cached_standards`. Read from state, do not re-fetch. |
| "Task-level Gate 8 misses bugs from subtask 2" | Cumulative task diff shows ALL subtasks' changes. Cross-subtask interactions are MORE visible, not less. |

---

## Red Flags - STOP

See [shared-patterns/shared-red-flags.md](../shared-patterns/shared-red-flags.md) for universal red flags.

If you catch yourself thinking any of those patterns, STOP immediately and return to gate execution.

---

## Incremental Compromise Prevention

**The "just this once" pattern leads to complete gate erosion:**

```text
Day 1: "Skip review just this once" → Approved (precedent set)
Day 2: "Skip testing, we did it last time" → Approved (precedent extended)
Day 3: "Skip implementation checks, pattern established" → Approved (gates meaningless)
Day 4: Production incident from Day 1 code
```

**Prevention rules:**
1. **No incremental exceptions** - Each exception becomes the new baseline
2. **Document every pressure** - Log who requested, why, outcome
3. **Escalate patterns** - If same pressure repeats, escalate to team lead
4. **Gates are binary** - Complete or incomplete. No "mostly done".

---

## Gate Completion Definition (HARD GATE)

**A gate is COMPLETE only when all components finish successfully:**

| Gate | Components Required | Partial = FAIL |
|------|---------------------|----------------|
| 0.1 | TDD-RED: Failing test written + failure output captured | Test exists but no failure output = FAIL |
| 0.2 | TDD-GREEN: Implementation passes test | Code exists but test fails = FAIL |
| 0 | Both 0.1 and 0.2 complete + Delivery verification: all requirements delivered, 0 dead code items | 0.1 done without 0.2 = FAIL; missing/dead code = FAIL |
| 1 | Dockerfile + docker-compose + .env.example | Missing any = FAIL |
| 2 | Structured JSON logs with trace correlation | Partial structured logs = FAIL |
| 3 | Unit test coverage ≥ 85% + all AC tested | 84% = FAIL |
| 4 | Fuzz tests with seed corpus ≥ 5 entries | Missing corpus = FAIL |
| 5 | Property-based tests for domain invariants | Missing property tests = FAIL |
| 6 | Integration tests with testcontainers | No testcontainers = FAIL |
| 7 | Chaos tests for failure scenarios | Missing chaos tests = FAIL |
| 8 | **All 8 reviewers PASS** | 7/8 reviewers = FAIL |
| 9 | Explicit "APPROVED" from user | "Looks good" = not approved |

**CRITICAL for Gate 8:** Running 7 of 8 reviewers is not a partial pass - it's a FAIL. Re-run all 8 reviewers.

**Anti-Rationalization for Partial Gates:**

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "7 of 8 reviewers passed" | Gate 8 requires all 8. 7/8 = 0/8. | **Re-run all 8 reviewers** |
| "Gate mostly complete" | Mostly ≠ complete. Binary: done or not done. | **Complete all components** |
| "Can finish remaining in next cycle" | Gates don't carry over. Complete NOW. | **Finish current gate** |
| "Core components done, optional can wait" | No component is optional within a gate. | **Complete all components** |
| "Unit tests are enough, skip fuzz/property" | Each test type catches different bugs. All are MANDATORY. | **Execute all testing gates (3-7)** |
| "No external dependencies, skip integration" | Integration testing is MANDATORY. Write tests per unit, execute at end of cycle. | **Write Gate 6 tests per unit, execute at end** |

---

## Gate Order Enforcement (HARD GATE)

**Gates MUST execute in this order within each task:**

1. **Subtask loop** (per subtask OR per task-itself if no subtasks):
   - Gate 0 (Implementation — INCLUDES delivery verification exit check inline)
   - Gate 3 (Unit Testing)
   - Gate 9 (Validation)

2. **After all subtasks complete their subtask-level gates — task-level gates** (once per task):
   - Gate 1 (DevOps)
   - Gate 2 (SRE)
   - Gate 4 (Fuzz)
   - Gate 5 (Property)
   - Gate 6 (Integration — write mode)
   - Gate 7 (Chaos — write mode)
   - Gate 8 (Review — 8 reviewers)

3. **End of cycle** (once per cycle):
   - Gate 6 (Integration — execute mode)
   - Gate 7 (Chaos — execute mode)
   - Multi-Tenant Verify
   - dev-report (aggregate)
   - Final Commit

**Deferred Execution Model for Gates 6-7:**
- **Write mode (task-level):** Write/update test code + verify compilation (no container execution)
- **Execute mode (end of cycle):** Execute all integration and chaos tests (containers spun up once), then verify multi-tenant dual-mode compliance (already implemented at Gate 0, verified at Gate 0.5G)

| Violation | Why It's WRONG | Consequence |
|-----------|----------------|-------------|
| Dispatching Gate 1 during subtask loop | Gate 1 is task-level; MUST wait until all subtasks done | DevOps validated N times instead of once |
| Dispatching Gate 2/4/5/6(write)/7(write)/8 during subtask loop | These are task-cadence; MUST wait until ALL subtasks of the current task complete Gate 0 + Gate 3 + Gate 9 | Redundant reviewer/QA runs; broken input aggregation (missing UNION of files) |
| Dispatching Gate 0.5 as separate gate | Gate 0.5 was REMOVED; delivery verification runs inline as Gate 0 exit criteria | Duplicate dispatch; broken gate accounting |
| Skip Gate 1 (DevOps) | "No infra changes" | Code without container = works on my machine only |
| Skip Gate 2 (SRE) | "Observability later" | Blind production = debugging nightmare |
| Skip Gate 4 (Fuzz) | "Unit tests are enough" | Edge cases and crashes not discovered |
| Skip Gate 5 (Property) | "Too complex" | Domain invariant violations not detected |
| Skip Gate 6 (Integration) | "No external dependencies" | Internal integration bugs surface in production |
| Skip Gate 7 (Chaos) | "Infra is reliable" | System fails under real-world conditions |
| Reorder Gates | "Review before test" | Reviewing untested code wastes reviewer time |
| Parallel Gates | "Run 3 and 4 together" | Dependencies exist. Order is intentional. |

**All testing gates (3-7) are MANDATORY. No exceptions. No skip reasons.**

**Gates are not parallelizable across different gates. Sequential execution is MANDATORY within each cadence layer.**

## The 10 Gates

| Gate | Skill | Purpose | Agent | Per Unit | Standards Module |
|------|-------|---------|-------|----------|------------------|
| 0 | ring:dev-implementation | Write code following TDD (single-tenant) | Based on task language/domain | Write + Run | core.md, domain.md |
| 1 | ring:dev-devops | Infrastructure and deployment | ring:devops-engineer | Write + Run | devops.md |
| 2 | ring:dev-sre | Observability (health, logging, tracing) | ring:sre | Write + Run | sre.md |
| 3 | ring:dev-unit-testing | Unit tests for acceptance criteria | ring:qa-analyst (test_mode: unit) | Write + Run | testing-unit.md |
| 4 | ring:dev-fuzz-testing | Fuzz tests for edge cases and crashes | ring:qa-analyst (test_mode: fuzz) | Write + Run | testing-fuzz.md |
| 5 | ring:dev-property-testing | Property-based tests for domain invariants | ring:qa-analyst (test_mode: property) | Write + Run | testing-property.md |
| 6 | ring:dev-integration-testing | Integration tests with testcontainers | ring:qa-analyst (test_mode: integration) | **Write only** | testing-integration.md |
| 7 | ring:dev-chaos-testing | Chaos tests for failure scenarios | ring:qa-analyst (test_mode: chaos) | **Write only** | testing-chaos.md |
| 8 | ring:codereview | Parallel code review (8 reviewers) | ring:code-reviewer, ring:business-logic-reviewer, ring:security-reviewer, ring:nil-safety-reviewer, ring:test-reviewer, ring:consequences-reviewer, ring:dead-code-reviewer, ring:performance-reviewer | Run | N/A |
| 9 | ring:dev-validation | Final acceptance validation | N/A (verification) | Run | N/A |

**All gates are MANDATORY. No exceptions. No skip reasons.**

**Note:** Gate 0 includes delivery verification exit criteria. See Step 2.3.1.

**Gates 6-7 Deferred Execution:** Test code is written/updated per unit to stay current. Actual test execution (with containers) happens once at end of cycle.

## Integrated PM → Dev Workflow

**PM Team Output** → **Dev Team Execution** (`/ring:dev-cycle`)

| Input Type | Path | Structure |
|------------|------|-----------|
| **Tasks only** | `docs/pre-dev/{feature}/tasks.md` | T-001, T-002, T-003 with requirements + acceptance criteria |
| **Tasks + Subtasks** | `docs/pre-dev/{feature}/` | tasks.md + `subtasks/{task-id}/ST-XXX-01.md, ST-XXX-02.md...` |

## Execution Order

**Core Principle (two-level cadence):**

- **Subtask-level gates** run per execution unit (subtask, or task-itself if no subtasks): Gate 0 (Implementation, incl. delivery verification exit check), Gate 3 (Unit Testing), Gate 9 (Validation).
- **Task-level gates** run ONCE per task, after all its subtasks finish their subtask-level gates: Gate 1 (DevOps), Gate 2 (SRE), Gate 4 (Fuzz), Gate 5 (Property), Gate 6 write (Integration), Gate 7 write (Chaos), Gate 8 (Review — 8 reviewers on cumulative task diff).
- **Cycle-level gates** run ONCE per cycle, after all tasks are done: Gate 6 execute, Gate 7 execute, Multi-Tenant Verify, ring:dev-report (aggregate), Final Commit.

**Per-Subtask Flow:** Subtask → Gate 0 (incl. delivery verification exit check) → Gate 3 → Gate 9 → [opt-in subtask visual report] → [subtask checkpoint if `execution_mode = manual_per_subtask`]
**Per-Task Flow (after all subtasks done):** Gate 1 → Gate 2 → Gate 4 → Gate 5 → Gate 6 (write) → Gate 7 (write) → Gate 8 (Review) → Task-level visual report → Accumulate metrics → [task checkpoint if `execution_mode in {manual_per_task, manual_per_subtask}`]
**End-of-Cycle Flow:** All tasks done → Gate 6 (execute) → Gate 7 (execute) → Multi-Tenant Verify → ring:dev-report (ONE dispatch, reads accumulated_metrics) → Final Commit

| Scenario | Execution Unit | Subtask-Level Gates (0, 3, 9) | Task-Level Gates (1, 2, 4, 5, 6w, 7w, 8) |
|----------|----------------|-------------------------------|-------------------------------------------|
| Task without subtasks | Task itself (single unit) | 3 gates per unit | 7 gates once (same scope as the unit) |
| Task with subtasks | Each subtask | 3 gates per subtask | 7 gates once per task (UNION of all subtasks' files) |

**Why deferred execution for Gates 6-7:**
- Integration tests require testcontainers (slow to spin up/tear down)
- Chaos tests require Toxiproxy infrastructure
- Running containers per subtask is wasteful when subsequent subtasks modify the same code
- Test code stays current (written per task), infrastructure cost is paid once

## Execution Loop Structure (cadence model)

```yaml
for each task in state.tasks:
  # ===== SUBTASK-LEVEL GATES =====
  for each subtask in task.subtasks (or task-itself if no subtasks):
    Execute Gate 0 (Implementation, includes delivery verification exit check)
    Execute Gate 3 (Unit Testing)
    Execute Gate 9 (Validation)
    [per-subtask visual report — OPT-IN only via state.visual_report_granularity == "subtask"]
    [subtask checkpoint if execution_mode == manual_per_subtask]
  end for

  # ===== TASK-LEVEL GATES =====
  # Input aggregation: implementation_files = UNION across all subtasks of this task.
  # gate0_handoffs = ARRAY of per-subtask implementation handoffs (one per subtask).
  Execute Gate 1 (DevOps)
  Execute Gate 2 (SRE)
  Execute Gate 4 (Fuzz)
  Execute Gate 5 (Property)
  Execute Gate 6 (Integration — write mode)
  Execute Gate 7 (Chaos — write mode)
  Execute Gate 8 (Review — 8 parallel reviewers on cumulative task diff)

  Generate task-level visual report
  Accumulate metrics into state.tasks[i].accumulated_metrics  (no dev-report dispatch here)
  [task checkpoint if execution_mode in {manual_per_task, manual_per_subtask}]
end for

# ===== CYCLE-LEVEL GATES =====
Execute Gate 6 (Integration — execute mode)
Execute Gate 7 (Chaos — execute mode)
Execute Multi-Tenant Verify
Dispatch ring:dev-report (ONE AND ONLY dispatch per cycle — reads accumulated_metrics)
Execute Final Commit
```

⛔ **CADENCE RULE:** Gates 1, 2, 4, 5, 6w, 7w, 8 MUST NOT be dispatched during the subtask loop. They are task-cadence — wait until ALL subtasks of the current task have completed Gates 0, 3, and 9 before dispatching them.

**Why task-level cadence for Gates 1, 2, 4, 5, 6w, 7w, 8:**
- **DevOps / SRE / Fuzz / Property:** Container configs, observability, edge-case coverage, and invariants are coherent at the task boundary, not at each subtask. Running them per subtask duplicates work against an in-flight feature.
- **Integration / Chaos (write):** Test scenarios span multiple subtasks; writing them once per task avoids churn as later subtasks land.
- **Review (Gate 8):** Cumulative task diff shows ALL subtasks' changes at once. Cross-subtask interactions (contract drift, hidden coupling) are MORE visible at this cadence, not less.

## Commit Timing

**User selects when commits happen (Step 7 of initialization).**

| Option | When Commit Happens | Use Case |
|--------|---------------------|----------|
| **(a) Per subtask** | After each subtask passes Gate 9 | Fine-grained history, easy rollback per subtask |
| **(b) Per task** | After all subtasks of a task complete | Logical grouping, one commit per feature chunk |
| **(c) At the end** | After entire cycle completes | Single commit with all changes, clean history |

### Commit Message Format

| Timing | Message Format | Example |
|--------|----------------|---------|
| Per subtask | `feat({subtask_id}): {subtask_title}` | `feat(ST-001-02): implement user authentication handler` |
| Per task | `feat({task_id}): {task_title}` | `feat(T-001): implement user authentication` |
| At the end | `feat({cycle_id}): complete dev cycle for {feature}` | `feat(cycle-abc123): complete dev cycle for auth-system` |

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

## State Management

### State Path Selection (MANDATORY)

The state file path depends on the **source of tasks**:

| Task Source | State Path | Use Case |
|-------------|------------|----------|
| `docs/ring:dev-refactor/*/tasks.md` | `docs/ring:dev-refactor/current-cycle.json` | Refactoring existing code |
| `docs/pre-dev/*/tasks.md` | `docs/ring:dev-cycle/current-cycle.json` | New feature development |
| Any other path | `docs/ring:dev-cycle/current-cycle.json` | Default for manual tasks |

**Detection Logic:**
```text
if source_file contains "docs/ring:dev-refactor/" THEN
  state_path = "docs/ring:dev-refactor/current-cycle.json"
else
  state_path = "docs/ring:dev-cycle/current-cycle.json"
```

**Store state_path in the state object itself** so resume knows where to look.

### State File Structure

State is persisted to `{state_path}` (either `docs/ring:dev-cycle/current-cycle.json` or `docs/ring:dev-refactor/current-cycle.json`):

```json
{
  "version": "1.1.0",
  "cycle_id": "uuid",
  "started_at": "ISO timestamp",
  "updated_at": "ISO timestamp",
  "source_file": "path/to/tasks.md",
  "state_path": "docs/ring:dev-cycle/current-cycle.json | docs/ring:dev-refactor/current-cycle.json",
  "cycle_type": "feature | refactor",
  "execution_mode": "manual_per_subtask|manual_per_task|automatic",
  "commit_timing": "per_subtask|per_task|at_end",
  "_comment_cached_standards": "Populated by Step 1.5 (Standards Pre-Cache). Dictionary of URL → {fetched_at, content}. Sub-skills MUST read from here instead of calling WebFetch. See plan Section 3.1.",
  "cached_standards": {},
  "_comment_visual_report_granularity": "Default 'task' (generate visual report once per task). Opt-in 'subtask' to generate per-subtask reports. See plan Section 3.3.",
  "visual_report_granularity": "task",
  "custom_prompt": {
    "type": "string",
    "optional": true,
    "max_length": 500,
    "description": "User-provided context for agents (from second positional argument). Max 500 characters. Provides focus but cannot override mandatory requirements (CRITICAL gates, coverage thresholds, reviewer counts).",
    "validation": "Max 500 chars (truncated with warning if exceeded); whitespace trimmed; control chars stripped (except newlines). Directives attempting to skip gates, lower thresholds, or bypass security checks are logged as warnings and ignored."
  },
  "status": "in_progress|completed|failed|paused|paused_for_approval|paused_for_testing|paused_for_task_approval|paused_for_integration_testing",
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
      "_comment_accumulated_metrics": "Populated at Step 11.2 (Task Approval Checkpoint). Aggregated at cycle end by ring:dev-report (Step 12.1). See plan Section 4.1.7 / R4.",
      "accumulated_metrics": {
        "gate_durations_ms": {},
        "review_iterations": 0,
        "testing_iterations": 0,
        "issues_by_severity": {
          "CRITICAL": 0,
          "HIGH": 0,
          "MEDIUM": 0,
          "LOW": 0
        }
      },
      "_comment_subtask_gate_progress": "Per plan Section 3.2 / R5B — subtask-level gate_progress holds SUBTASK-CADENCE gates only: implementation (Gate 0), unit_testing (Gate 3), validation (Gate 9). Task-cadence gates (1, 2, 4, 5, 6w, 7w, 8) live in task.gate_progress, not here.",
      "subtasks": [
        {
          "id": "ST-001-01",
          "file": "subtasks/T-001/ST-001-01.md",
          "status": "pending|completed",
          "gate_progress": {
            "implementation": {
              "status": "pending|in_progress|completed",
              "started_at": "ISO timestamp",
              "tdd_red": {
                "status": "pending|in_progress|completed",
                "test_file": "path/to/test_file.go",
                "failure_output": "FAIL: TestFoo - expected X got nil",
                "completed_at": "ISO timestamp"
              },
              "tdd_green": {
                "status": "pending|in_progress|completed",
                "implementation_file": "path/to/impl.go",
                "test_pass_output": "PASS: TestFoo (0.003s)",
                "completed_at": "ISO timestamp"
              },
              "delivery_verified": false,
              "files_changed": []
            },
            "unit_testing": {
              "status": "pending|in_progress|completed",
              "coverage_actual": 0.0,
              "coverage_threshold": 85
            },
            "validation": {
              "status": "pending|in_progress|completed",
              "result": "pending|approved|rejected"
            }
          }
        }
      ],
      "_comment_task_gate_progress": "Per plan Section 3.2 / R5B — task-level gate_progress holds TASK-CADENCE gates only: devops (1), sre (2), fuzz_testing (4), property_testing (5), integration_testing (6w), chaos_testing (7w), review (8). Subtask-cadence gates (0, 3, 9) live in each subtask's gate_progress, not here. Gates 6/7 keep write_mode and execute_mode phases; execute_mode transitions at cycle end (Step 12.1).",
      "gate_progress": {
        "devops": {"status": "pending"},
        "sre": {"status": "pending"},
        "fuzz_testing": {"status": "pending"},
        "property_testing": {"status": "pending"},
        "integration_testing": {
          "write_mode": {
            "status": "pending|in_progress|completed",
            "test_files": [],
            "compilation_passed": false
          },
          "execute_mode": "pending|completed",
          "scenarios_tested": 0,
          "tests_passed": 0,
          "tests_failed": 0,
          "flaky_tests_detected": 0
        },
        "chaos_testing": {
          "write_mode": {
            "status": "pending|in_progress|completed",
            "test_files": [],
            "compilation_passed": false
          },
          "execute_mode": "pending|completed"
        },
        "review": {"status": "pending"}
      },
      "artifacts": {},
      "agent_outputs": {
        "implementation": {
          "agent": "ring:backend-engineer-golang",
          "output": "## Summary\n...",
          "timestamp": "ISO timestamp",
          "duration_ms": 0,
          "iterations": 1,
          "standards_compliance": {
            "total_sections": 15,
            "compliant": 14,
            "not_applicable": 1,
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
          "artifacts_created": ["Dockerfile", "docker-compose.yml", ".env.example"],
          "verification_errors": [],
          "standards_compliance": {
            "total_sections": 8,
            "compliant": 8,
            "not_applicable": 0,
            "non_compliant": 0,
            "gaps": []
          }
        },
        "sre": {
          "agent": "ring:sre",
          "output": "## Summary\n...",
          "timestamp": "ISO timestamp",
          "duration_ms": 0,
          "iterations": 1,
          "instrumentation_coverage": "92%",
          "validation_errors": [],
          "standards_compliance": {
            "total_sections": 10,
            "compliant": 10,
            "not_applicable": 0,
            "non_compliant": 0,
            "gaps": []
          }
        },
        "unit_testing": {
          "agent": "ring:qa-analyst",
          "test_mode": "unit",
          "output": "## Summary\n...",
          "verdict": "PASS",
          "coverage_actual": 87.5,
          "coverage_threshold": 85,
          "iterations": 1,
          "timestamp": "ISO timestamp",
          "duration_ms": 0,
          "failures": [],
          "uncovered_criteria": [],
          "standards_compliance": {
            "total_sections": 6,
            "compliant": 6,
            "not_applicable": 0,
            "non_compliant": 0,
            "gaps": []
          }
        },
        "fuzz_testing": {
          "agent": "ring:qa-analyst",
          "test_mode": "fuzz",
          "output": "## Summary\n...",
          "verdict": "PASS",
          "corpus_entries": 5,
          "iterations": 1,
          "timestamp": "ISO timestamp",
          "duration_ms": 0,
          "standards_compliance": {
            "total_sections": 5,
            "compliant": 5,
            "not_applicable": 0,
            "non_compliant": 0,
            "gaps": []
          }
        },
        "property_testing": {
          "agent": "ring:qa-analyst",
          "test_mode": "property",
          "output": "## Summary\n...",
          "verdict": "PASS",
          "properties_tested": 3,
          "iterations": 1,
          "timestamp": "ISO timestamp",
          "duration_ms": 0,
          "standards_compliance": {
            "total_sections": 5,
            "compliant": 5,
            "not_applicable": 0,
            "non_compliant": 0,
            "gaps": []
          }
        },
        "integration_testing": {
          "agent": "ring:qa-analyst",
          "test_mode": "integration",
          "output": "## Summary\n...",
          "verdict": "PASS",
          "scenarios_tested": 5,
          "tests_passed": 5,
          "tests_failed": 0,
          "flaky_tests_detected": 0,
          "iterations": 1,
          "timestamp": "ISO timestamp",
          "duration_ms": 0,
          "standards_compliance": {
            "total_sections": 10,
            "compliant": 10,
            "not_applicable": 0,
            "non_compliant": 0,
            "gaps": []
          }
        },
        "chaos_testing": {
          "agent": "ring:qa-analyst",
          "test_mode": "chaos",
          "output": "## Summary\n...",
          "verdict": "PASS",
          "failure_scenarios_tested": 4,
          "recovery_verified": true,
          "iterations": 1,
          "timestamp": "ISO timestamp",
          "duration_ms": 0,
          "standards_compliance": {
            "total_sections": 5,
            "compliant": 5,
            "not_applicable": 0,
            "non_compliant": 0,
            "gaps": []
          }
        },
        "review": {
          "iterations": 1,
          "timestamp": "ISO timestamp",
          "duration_ms": 0,
          "code_reviewer": {
            "agent": "ring:code-reviewer",
            "output": "...",
            "verdict": "PASS",
            "timestamp": "...",
            "issues": [],
            "standards_compliance": {
              "total_sections": 12,
              "compliant": 12,
              "not_applicable": 0,
              "non_compliant": 0,
              "gaps": []
            }
          },
          "business_logic_reviewer": {
            "agent": "ring:business-logic-reviewer",
            "output": "...",
            "verdict": "PASS",
            "timestamp": "...",
            "issues": [],
            "standards_compliance": {
              "total_sections": 8,
              "compliant": 8,
              "not_applicable": 0,
              "non_compliant": 0,
              "gaps": []
            }
          },
          "security_reviewer": {
            "agent": "ring:security-reviewer",
            "output": "...",
            "verdict": "PASS",
            "timestamp": "...",
            "issues": [],
            "standards_compliance": {
              "total_sections": 10,
              "compliant": 10,
              "not_applicable": 0,
              "non_compliant": 0,
              "gaps": []
            }
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

### Structured Error/Issue Schemas

**These schemas enable `ring:dev-report` to analyze issues without parsing raw output.**

#### Standards Compliance Gap Schema

```json
{
  "section": "Error Handling (MANDATORY)",
  "status": "❌",
  "reason": "Missing error wrapping with context",
  "file": "internal/handler/user.go",
  "line": 45,
  "evidence": "return err // should wrap with additional context"
}
```

#### Test Failure Schema

```json
{
  "test_name": "TestUserCreate_InvalidEmail",
  "test_file": "internal/handler/user_test.go",
  "error_type": "assertion",
  "expected": "ErrInvalidEmail",
  "actual": "nil",
  "message": "Expected validation error for invalid email format",
  "stack_trace": "user_test.go:42 → user.go:28"
}
```

#### Review Issue Schema

```json
{
  "severity": "MEDIUM",
  "category": "error-handling",
  "description": "Error not wrapped with context before returning",
  "file": "internal/handler/user.go",
  "line": 45,
  "suggestion": "Use fmt.Errorf(\"failed to create user: %w\", err)",
  "fixed": false,
  "fixed_in_iteration": null
}
```

#### DevOps Verification Error Schema

```json
{
  "check": "docker_build",
  "status": "FAIL",
  "error": "COPY failed: file not found in build context: go.sum",
  "suggestion": "Ensure go.sum exists and is not in .dockerignore"
}
```

#### SRE Validation Error Schema

```json
{
  "check": "structured_logging",
  "status": "FAIL",
  "file": "internal/handler/user.go",
  "line": 32,
  "error": "Using fmt.Printf instead of structured logger",
  "suggestion": "Use logger.Info().Str(\"user_id\", id).Msg(\"user created\")"
}
```

### Populating Structured Data

**Each gate MUST populate its structured fields when saving to state:**

| Gate | Fields to Populate |
|------|-------------------|
| Gate 0 (Implementation) | `standards_compliance` (total, compliant, gaps[]) |
| Gate 1 (DevOps) | `standards_compliance` + `verification_errors[]` |
| Gate 2 (SRE) | `standards_compliance` + `validation_errors[]` |
| Gate 3 (Unit Testing) | `standards_compliance` + `failures[]` + `uncovered_criteria[]` |
| Gate 4 (Fuzz Testing) | `standards_compliance` + `corpus_entries` |
| Gate 5 (Property Testing) | `standards_compliance` + `properties_tested` |
| Gate 6 (Integration Testing) | `standards_compliance` + `scenarios_tested` + `tests_passed` + `tests_failed` + `flaky_tests_detected` |
| Gate 7 (Chaos Testing) | `standards_compliance` + `failure_scenarios_tested` + `recovery_verified` |
| Gate 8 (Review) | `standards_compliance` per reviewer + `issues[]` per reviewer |

**All gates track `standards_compliance`:**
- `total_sections`: Count from agent's standards file (via standards-coverage-table.md)
- `compliant`: Sections marked ✅ in Standards Coverage Table
- `not_applicable`: Sections marked N/A
- `non_compliant`: Sections marked ❌ (MUST be 0 to pass gate)
- `gaps[]`: Detailed info for each ❌ section (even if later fixed)

**Empty arrays `[]` indicate no issues found - this is valid data for feedback-loop.**

## ⛔ State Persistence Rule (MANDATORY)

**"Update state" means BOTH update the object and write to file. Not just in-memory.**

### After every Gate Transition

You MUST execute these steps after completing any gate (0, 1, 2, 3, 4, or 5):

```yaml
# Step 1: Update state object with gate results
state.tasks[current_task_index].gate_progress.[gate_name].status = "completed"
state.tasks[current_task_index].gate_progress.[gate_name].completed_at = "[ISO timestamp]"
state.current_gate = [next_gate_number]
state.updated_at = "[ISO timestamp]"

# Step 2: Write to file (MANDATORY - use Write tool)
Write tool:
  file_path: [state.state_path]  # Use state_path from state object
  content: [full JSON state]
```

### State Persistence Checkpoints

⛔ **Cadence-aware write paths.** Subtask-level gates (0, 3, 9) write to `state.tasks[i].subtasks[j].gate_progress.<gate_name>`. Task-level gates (1, 2, 4, 5, 6w, 7w, 8) write to `state.tasks[i].gate_progress.<gate_name>`. Never write task-level gate status under a subtask and never write subtask-level gate status under the task.

| Checkpoint | Cadence | MUST Update | MUST Write File |
|------------|---------|-------------|-----------------|
| **Before Gate 0 (task start)** | Task | `task.status = "in_progress"` in JSON **+ tasks.md Status → `🔄 Doing`** | ✅ YES |
| Gate 0.1 (TDD-RED) | Subtask | `state.tasks[i].subtasks[j].gate_progress.implementation.tdd_red.status` + `.failure_output` | ✅ YES |
| Gate 0.2 (TDD-GREEN) | Subtask | `state.tasks[i].subtasks[j].gate_progress.implementation.tdd_green.status` + `.implementation.status` | ✅ YES |
| Gate 0 exit (Delivery Verification) | Subtask | `state.tasks[i].subtasks[j].gate_progress.implementation.delivery_verified = true` | ✅ YES |
| Gate 3 (Unit Testing) | Subtask | `state.tasks[i].subtasks[j].gate_progress.unit_testing.status` + `.coverage_actual` + `agent_outputs.unit_testing` | ✅ YES |
| Gate 9 (Validation) | Subtask | `state.tasks[i].subtasks[j].gate_progress.validation.status` + `.result` (do NOT touch task-level status here) | ✅ YES |
| Gate 1 (DevOps) | Task | `state.tasks[i].gate_progress.devops.status` + `agent_outputs.devops` | ✅ YES |
| Gate 2 (SRE) | Task | `state.tasks[i].gate_progress.sre.status` + `agent_outputs.sre` | ✅ YES |
| Gate 4 (Fuzz Testing) | Task | `state.tasks[i].gate_progress.fuzz_testing.status` + `agent_outputs.fuzz_testing` | ✅ YES |
| Gate 5 (Property Testing) | Task | `state.tasks[i].gate_progress.property_testing.status` + `agent_outputs.property_testing` | ✅ YES |
| Gate 6 (Integration — write) | Task | `state.tasks[i].gate_progress.integration_testing.write_mode.status` + `.test_files` + `.compilation_passed` | ✅ YES |
| Gate 7 (Chaos — write) | Task | `state.tasks[i].gate_progress.chaos_testing.write_mode.status` + `.test_files` + `.compilation_passed` | ✅ YES |
| Gate 8 (Review) | Task | `state.tasks[i].gate_progress.review.status` + `agent_outputs.review` (reviewers see cumulative task diff) | ✅ YES |
| Step 11.1 (Subtask Approval) | Subtask | `status = "paused_for_approval"` (subtask-level checkpoint; set only when `execution_mode = manual_per_subtask`) | ✅ YES |
| Step 11.2 (Task Approval) | Task | `task.status = "completed"` in JSON **+ tasks.md Status → `✅ Done`** + `task.accumulated_metrics` populated (gate_durations_ms, review_iterations, testing_iterations, issues_by_severity); NO dev-report dispatch here (runs ONCE at Step 12.1) | ✅ YES |
| Step 12.1 (Cycle end — Gate 6/7 execute + dev-report) | Cycle | `state.tasks[i].gate_progress.integration_testing.execute_mode = "completed"` + `.chaos_testing.execute_mode = "completed"`; `state.feedback_loop_completed = true` after the ONE AND ONLY `ring:dev-report` dispatch | ✅ YES |
| HARD BLOCK (any gate) | Task | `task.status = "failed"` in JSON **+ tasks.md Status → `❌ Failed`** | ✅ YES |

**tasks.md Status update rules (apply at the three checkpoints above):**

```text
If state.source_file is absent or file does not exist → log warning "tasks.md Status updates skipped: source_file missing" and skip all status updates for this cycle.

task_id = state.tasks[state.current_task_index].id
# Always the parent TASK ID — do NOT use current_subtask_index
# Rows where column 1 is "TOTAL" or empty → skip, not a task row

Use Edit tool on state.source_file (tasks.md):
- Find the row starting with `| {task_id} |` in the `## Summary` table
- Before Gate 0: replace `⏸️ Pending` with `🔄 Doing`
  - If already `🔄 Doing` (resumed cycle) → skip, no change needed
- Step 11.2 (all subtasks done, user approved): replace `🔄 Doing` with `✅ Done`
- HARD BLOCK (any gate, task abandoned): replace `🔄 Doing` with `❌ Failed`
  - If row shows `⏸️ Pending` (unexpected) → replace with target value anyway
- If row not found or no Status column → log warning "Status update skipped: task {task_id} row not found in {source_file}" and continue, do not abort
```

### Anti-Rationalization for State Persistence

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "I'll save state at the end" | Crash/timeout loses all progress | **Save after each gate** |
| "State is in memory, that's updated" | Memory is volatile. File is persistent. | **Write to JSON file** |
| "Only save on checkpoints" | Gates without saves = unrecoverable on resume | **Save after every gate** |
| "Write tool is slow" | Write takes <100ms. Lost progress takes hours. | **Write after every gate** |
| "I updated the state variable" | Variable ≠ file. Without Write tool, nothing persists. | **Use Write tool explicitly** |

---

## Step 0: Verify PROJECT_RULES.md Exists (HARD GATE)

**NON-NEGOTIABLE. Cycle CANNOT proceed without project standards.**

### Step 0 Flow

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│  Check: Does docs/PROJECT_RULES.md exist?                                   │
│                                                                             │
│  ├── YES → Proceed to Step 1 (Initialize or Resume)                        │
│  │                                                                          │
│  └── no → ASK: "Is this a LEGACY project (created without PM workflow)?"   │
│       │                                                                     │
│       ├── YES (legacy project) → LEGACY PROJECT ANALYSIS:                   │
│       │   Step 1: Dispatch ring:codebase-explorer (technical info only)          │
│       │   Step 2: Ask 3 questions (what agent can't determine):             │
│       │     1. What do you need help with?                                  │
│       │     2. Any external APIs not visible in code?                       │
│       │     3. Any specific technology not in Ring Standards?               │
│       │   Step 3: Generate PROJECT_RULES.md (deduplicated from Ring)        │
│       │   Note: Business rules belong in PRD, not in PROJECT_RULES          │
│       │   → Proceed to Step 1                                               │
│       │                                                                     │
│       └── no (new project) → ASK: "Do you have PRD, TRD, or Feature Map?"  │
│           │                                                                 │
│           ├── YES (has PM docs) → "Please provide the file path(s)"        │
│           │   → Read PRD/TRD/Feature Map → Extract info                    │
│           │   → Generate PROJECT_RULES.md                                  │
│           │   → Ask supplementary questions if info is incomplete          │
│           │   → Save and proceed to Step 1                                 │
│           │                                                                 │
│           └── no (no PM docs) → ⛔ HARD BLOCK:                              │
│               "PM documents are REQUIRED for new projects.                  │
│                Run /ring:pre-dev-full or /ring:pre-dev-feature first."               │
│               → STOP (cycle cannot proceed)                                 │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Step 0.1: Check for PROJECT_RULES.md

```yaml
# Check if file exists
Read tool:
  file_path: "docs/PROJECT_RULES.md"

# If file exists and has content → Proceed to Step 1
# If file does not exist or is empty → Continue to Step 0.2
```

### Step 0.2: Check if Legacy Project

#### Ask the User

Use AskUserQuestion:

```text
┌─────────────────────────────────────────────────────────────────┐
│ 📋 PROJECT_RULES.md not FOUND                                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ I need to create docs/PROJECT_RULES.md to understand your       │
│ project's specific conventions and domain.                      │
│                                                                 │
│ First, I need to know: Is this a LEGACY project?                │
│                                                                 │
│ A legacy project is one that was created WITHOUT using the      │
│ PM team workflow (no PRD, TRD, or Feature Map documents).       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### Question

"Is this a legacy project (created without PM team workflow)?"

#### Options

(a) Yes, this is a legacy project (b) No, this is a new project following Ring workflow

#### If YES (legacy)

Go to Step 0.2.1 (Legacy Project Analysis)

#### If no (new project)

Go to Step 0.3 (Check for PM Documents)

### Step 0.2.1: Legacy Project Analysis (Technical Only)

#### Overview

For legacy projects, analyze codebase for TECHNICAL information only:

```text
┌─────────────────────────────────────────────────────────────────┐
│ 📋 LEGACY PROJECT ANALYSIS                                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ Since this is a legacy project, I'll analyze the codebase       │
│ for TECHNICAL information (not business rules).                 │
│                                                                 │
│ Step 1: Automated analysis (ring:codebase-explorer)                  │
│ Step 2: Ask for project-specific tech not in Ring Standards     │
│ Step 3: Generate PROJECT_RULES.md (deduplicated)                │
│                                                                 │
│ Note: Business rules belong in PRD/product docs, not here.      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### Step 0.2.1a: Automated Codebase Analysis (MANDATORY)

**⛔ You MUST use the Task tool to dispatch ring:codebase-explorer. This is not implicit.**

#### Dispatch Agent

Dispatch ring:codebase-explorer to analyze the legacy project for TECHNICAL information:

```text
Action: Use Task tool with EXACTLY these parameters:

┌─────────────────────────────────────────────────────────────────────────────────┐
│  ⛔ If Task tool not used → Analysis does not happen → PROJECT_RULES.md INVALID │
└─────────────────────────────────────────────────────────────────────────────────┘
```

```yaml
# Agent 1: Codebase Explorer - Technical Analysis
Task tool:
  subagent_type: "ring:codebase-explorer"
  description: "Analyze legacy project for PROJECT_RULES.md"
  prompt: |
    Analyze this LEGACY codebase to extract technical information for PROJECT_RULES.md.
    
    This is an existing project created without PM documentation.
    Your job is to understand what exists in the code.
    
    **Extract:**
    1. **Project Structure:** Directory layout, module organization
    2. **Technical Stack:** Languages, frameworks, databases, external services
    3. **Architecture Patterns:** Clean Architecture, MVC, microservices, etc.
    4. **Existing Features:** Main modules, endpoints, capabilities
    5. **Internal Libraries:** Shared packages, utilities
    6. **Configuration:** Environment variables, config patterns
    7. **Database:** Schema patterns, migrations, ORM usage
    8. **External Integrations:** APIs consumed, message queues
    
    **Output format:**
    ## Technical Analysis (Legacy Project)
    
    ### Project Overview
    [What this project appears to do based on code analysis]
    
    ### Technical Stack
    - Language: [detected]
    - Framework: [detected]
    - Database: [detected]
    - External Services: [detected]
    
    ### Architecture Patterns
    [Detected patterns]
    
    ### Existing Features
    [List of features/modules found]
    
    ### Project Structure
    [Directory layout explanation]
    
    ### Configuration
    [Env vars, config files found]
    
    ### External Integrations
    [APIs, services detected]

```

**Note:** Business logic analysis is not needed for PROJECT_RULES.md. Business rules belong in PRD/product docs, not technical project rules.

#### Verification (MANDATORY)

After agent completes, confirm:
- [ ] `ring:codebase-explorer` returned "## Technical Analysis (Legacy Project)" section
- [ ] Output contains non-empty content for: Tech Stack, External Integrations, Configuration

**If agent failed or returned empty output → Re-dispatch. Cannot proceed without technical analysis.**

#### Step 0.2.1b: Supplementary Questions (Only What Agents Can't Determine)

#### Post-Analysis Questions

After agents complete, ask only what they couldn't determine from code:

```text
┌─────────────────────────────────────────────────────────────────┐
│ ✓ Codebase Analysis Complete                                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ I've analyzed your codebase. Now I need a few details that      │
│ only you can provide (not visible in the code).                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### Questions to Ask

Use AskUserQuestion for each:

| # | Question | Why Agents Can't Determine This |
|---|----------|--------------------------------|
| 1 | **What do you need help with?** (Current task/feature/fix) | Future intent, not in code |
| 2 | **Any external APIs or services not visible in code?** (Third-party integrations planned) | Planned integrations, not yet in code |
| 3 | **Any specific technology not in Ring Standards?** (Message broker, cache, etc.) | Project-specific tech not in Ring |

**Note:** Business rules belong in PRD/product docs, not in PROJECT_RULES.md.

#### Step 0.2.1c: Generate PROJECT_RULES.md

#### Combine Agent Outputs and User Answers

```yaml
Create tool:
  file_path: "docs/PROJECT_RULES.md"
  content: |
    # Project Rules
    
    > Ring Standards apply automatically. This file documents only what Ring does not cover.
    > For error handling, logging, testing, architecture, lib-commons → See Ring Standards (auto-loaded by agents)
    > Generated from legacy project analysis.
    
    ## What Ring Standards Already Cover (DO not ADD HERE)
    
    The following are defined in Ring Standards and MUST not be duplicated:
    - Error handling patterns (no panic, wrap errors)
    - Logging standards (structured JSON, zerolog/zap)
    - Testing patterns (table-driven tests, mocks)
    - Architecture patterns (Hexagonal, Clean Architecture)
    - Observability (OpenTelemetry, trace correlation)
    - lib-commons usage and patterns
    - API directory structure
    
    ---
    
    ## Tech Stack (Not in Ring Standards)
    
    [From ring:codebase-explorer: Technologies not covered by Ring Standards]
    [e.g., specific message broker, specific cache, DB if not PostgreSQL]
    
    | Technology | Purpose | Notes |
    |------------|---------|-------|
    | [detected] | [purpose] | [notes] |
    
    ## Non-Standard Directory Structure
    
    [From ring:codebase-explorer: Directories that deviate from Ring's standard API structure]
    [e.g., workers/, consumers/, polling/]
    
    | Directory | Purpose | Pattern |
    |-----------|---------|---------|
    | [detected] | [purpose] | [pattern] |
    
    ## External Integrations
    
    [From ring:codebase-explorer: Third-party services specific to this project]
    
    | Service | Purpose | Docs |
    |---------|---------|------|
    | [detected] | [purpose] | [link] |
    
    ## Environment Configuration
    
    [From ring:codebase-explorer: Project-specific env vars not covered by Ring]
    
    | Variable | Purpose | Example |
    |----------|---------|---------|
    | [detected] | [purpose] | [example] |
    
    ## Domain Terminology
    
    [From codebase analysis: Technical names used in this codebase]
    
    | Term | Definition | Used In |
    |------|------------|---------|
    | [detected] | [definition] | [location] |
    
    ---
    
    *Generated: [ISO timestamp]*
    *Source: Legacy project analysis (ring:codebase-explorer)*
    *Ring Standards Version: [version from WebFetch]*
```

#### Present to User

```text
┌─────────────────────────────────────────────────────────────────┐
│ ✓ PROJECT_RULES.md Generated for Legacy Project                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ I analyzed your codebase using:                                 │
│   • ring:codebase-explorer (technical patterns, stack, structure)    │
│                                                                 │
│ Combined with your input on:                                    │
│   • Current development goal                                    │
│   • External integrations                                       │
│   • Project-specific technology                                 │
│                                                                 │
│ Generated: docs/PROJECT_RULES.md                                │
│                                                                 │
│ Note: Ring Standards (error handling, logging, testing, etc.)   │
│ are not duplicated - agents load them automatically via WebFetch│
│                                                                 │
│ Please review the file and make any corrections needed.         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### Ask for Approval

Use AskUserQuestion:
- Question: "PROJECT_RULES.md has been generated. Would you like to review it before proceeding?"
- Options: (a) Proceed (b) Open for editing first

#### After Approval

Proceed to Step 1

### Step 0.3: Check for PM Documents (PRD/TRD/Feature Map)

#### Check for PM Documents

For NEW projects (not legacy), ask about PM documents:

```text
┌─────────────────────────────────────────────────────────────────┐
│ 📋 NEW PROJECT - PM DOCUMENTS CHECK                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ Since this is a new project following Ring workflow, you        │
│ should have PM documents from the pre-dev workflow.             │
│                                                                 │
│ Do you have any of these PM documents?                          │
│   • PRD (Product Requirements Document)                         │
│   • TRD (Technical Requirements Document)                       │
│   • Feature Map (from ring:pre-dev-feature-map skill)                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### Question

"Do you have PRD, TRD, or Feature Map documents for this project?"

#### Options

(a) Yes, I have PM documents (b) No, I don't have these documents

#### If YES - Ask for File Paths

```text
"Please provide the file path(s) to your PM documents:
 - PRD path (or 'skip' if none): 
 - TRD path (or 'skip' if none): 
 - Feature Map path (or 'skip' if none): "
```

#### Example Paths

Typical PM team output structure:

```text
docs/pre-dev/{feature-name}/
├── prd.md              → PRD path: docs/pre-dev/auth-system/prd.md
├── trd.md              → TRD path: docs/pre-dev/auth-system/trd.md
├── feature-map.md      → Feature Map path: docs/pre-dev/auth-system/feature-map.md
├── api-design.md
├── data-model.md
└── tasks.md
```

#### Common Patterns

- `/ring:pre-dev-full` output: `docs/pre-dev/{feature}/prd.md`, `trd.md`, `feature-map.md`
- `/ring:pre-dev-feature` output: `docs/pre-dev/{feature}/prd.md`, `feature-map.md`
- Custom locations: User may have docs in different paths (e.g., `requirements/`, `specs/`)

#### Then

Go to Step 0.3.1 (Generate from PM Documents)

#### If no

HARD BLOCK (Step 0.3.2)

### Step 0.3.1: Generate from PM Documents (PRD/TRD/Feature Map)

#### Read the Provided Documents

```yaml
# Read PRD if provided
Read tool:
  file_path: "[user-provided PRD path]"

# Read TRD if provided  
Read tool:
  file_path: "[user-provided TRD path]"

# Read Feature Map if provided
Read tool:
  file_path: "[user-provided Feature Map path]"
```

#### Extract PROJECT_RULES.md Content from PM Documents

**⛔ DEDUPLICATION RULE:** Extract only what Ring Standards DO NOT cover.

| From PRD | Extract For PROJECT_RULES.md | Note |
|----------|------------------------------|------|
| Domain terms, entities | Domain Terminology | Technical names only |
| External service mentions | External Integrations | Third-party APIs |
| ~~Business rules~~ | ~~N/A~~ | ❌ Stays in PRD, not PROJECT_RULES |
| ~~Architecture~~ | ~~N/A~~ | ❌ Ring Standards covers this |

| From TRD | Extract For PROJECT_RULES.md | Note |
|----------|------------------------------|------|
| Tech stack not in Ring | Tech Stack (Not in Ring) | Only non-standard tech |
| External APIs | External Integrations | Third-party services |
| Non-standard directories | Non-Standard Directory Structure | Workers, consumers, etc. |
| ~~Architecture decisions~~ | ~~N/A~~ | ❌ Ring Standards covers this |
| ~~Database patterns~~ | ~~N/A~~ | ❌ Ring Standards covers this |

| From Feature Map | Extract For PROJECT_RULES.md | Note |
|------------------|------------------------------|------|
| Technology choices not in Ring | Tech Stack (Not in Ring) | Only if not in Ring |
| External dependencies | External Integrations | Third-party services |
| ~~Architecture~~ | ~~N/A~~ | ❌ Ring Standards covers this |

#### Generate PROJECT_RULES.md

```yaml
Create tool:
  file_path: "docs/PROJECT_RULES.md"
  content: |
    # Project Rules
    
    > ⛔ IMPORTANT: Ring Standards are not automatic. Agents MUST WebFetch them before implementation.
    > This file documents only project-specific information not covered by Ring Standards.
    > Generated from PM documents (PRD/TRD/Feature Map).
    >
    > Ring Standards URLs:
    > - Go: https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang.md
    > - TypeScript: https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/typescript.md
    
    ## What Ring Standards Cover (DO not DUPLICATE HERE)
    
    The following are defined in Ring Standards and MUST not be duplicated in this file:
    - Error handling patterns (no panic, wrap errors)
    - Logging standards (structured JSON via lib-commons)
    - Testing patterns (table-driven tests, mocks)
    - Architecture patterns (Hexagonal, Clean Architecture)
    - Observability (OpenTelemetry via lib-commons)
    - lib-commons / lib-common-js usage and patterns
    - API directory structure (Lerian pattern)
    - Database connections (PostgreSQL, MongoDB, Redis via lib-commons)
    - Bootstrap pattern (config.go, service.go, server.go)
    
    **Agents MUST WebFetch Ring Standards and output Standards Coverage Table.**
    
    ---
    
    ## Tech Stack (Not in Ring Standards)
    
    [From TRD/Feature Map: only technologies not covered by Ring Standards]
    
    | Technology | Purpose | Notes |
    |------------|---------|-------|
    | [detected] | [purpose] | [notes] |
    
    ## Non-Standard Directory Structure
    
    [From TRD: Directories that deviate from Ring's standard API structure]
    
    | Directory | Purpose | Pattern |
    |-----------|---------|---------|
    | [detected] | [purpose] | [pattern] |
    
    ## External Integrations
    
    [From TRD/PRD: Third-party services specific to this project]
    
    | Service | Purpose | Docs |
    |---------|---------|------|
    | [detected] | [purpose] | [link] |
    
    ## Environment Configuration
    
    [From TRD: Project-specific env vars not covered by Ring]
    
    | Variable | Purpose | Example |
    |----------|---------|---------|
    | [detected] | [purpose] | [example] |
    
    ## Domain Terminology
    
    [From PRD: Technical names used in this codebase]
    
    | Term | Definition | Used In |
    |------|------------|---------|
    | [detected] | [definition] | [location] |
    
    ---
    
    *Generated from: [PRD path], [TRD path], [Feature Map path]*
    *Ring Standards Version: [version from WebFetch]*
    *Generated: [ISO timestamp]*
```

#### Check for Missing Information

If any section is empty or incomplete, ask supplementary questions:

| Missing Section | Supplementary Question |
|-----------------|------------------------|
| Tech Stack (Not in Ring) | "Any technology not covered by Ring Standards (message broker, cache, etc.)?" |
| External Integrations | "Any third-party APIs or external services?" |
| Domain Terminology | "What are the main entities/classes in this codebase?" |
| Non-Standard Directories | "Any directories that don't follow standard API structure (workers, consumers)?" |

**Note:** Do not ask about architecture, error handling, logging, testing - Ring Standards covers these.

#### After Generation

Present to user for review, then proceed to Step 1.

### Step 0.3.2: HARD BLOCK - No PM Documents (New Projects Only)

#### When User Has No PM Documents

```text
┌─────────────────────────────────────────────────────────────────┐
│ ⛔ CANNOT PROCEED - PM DOCUMENTS REQUIRED                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ Development cannot start without PM documents.                  │
│                                                                 │
│ You MUST create PRD, TRD, and/or Feature Map documents first    │
│ using PM team skills:                                           │
│                                                                 │
│   /ring:pre-dev-full     → For features ≥2 days (9 gates)           │
│   /ring:pre-dev-feature  → For features <2 days (4 gates)           │
│                                                                 │
│ These commands will guide you through creating:                 │
│   • PRD (Product Requirements Document)                         │
│   • TRD (Technical Requirements Document)                       │
│   • Feature Map (technology choices, feature relationships)     │
│                                                                 │
│ After completing pre-dev workflow, run /ring:dev-cycle again.        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### Action

STOP EXECUTION. Do not proceed to Step 1.

### Step 0 Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Skip PM docs, I'll add them later" | Later = never. No PM docs = no project context = agents guessing. | **Run /ring:pre-dev-full or /ring:pre-dev-feature NOW** |
| "Project is simple, doesn't need PM docs" | Simple projects still need domain context defined upfront. | **Create PM documents first** |
| "I know what I want to build" | Your knowledge ≠ documented knowledge agents can use. | **Document in PRD/TRD/Feature Map** |
| "PM workflow takes too long" | PM workflow takes 30-60 min. Rework from unclear requirements takes days. | **Invest time upfront** |
| "Just let me start coding" | Coding without requirements = building the wrong thing. | **Requirements first, code second** |
| "It's legacy but I don't want to answer questions" | Legacy analysis takes ~5 min. Without it, agents have zero context. | **Answer the 4 questions** |
| "Legacy project is too complex to explain" | Start with high-level answers. PROJECT_RULES.md can be refined later. | **Provide what you know NOW** |

### Pressure Resistance

| User Says | Your Response |
|-----------|---------------|
| "Just skip this, I'll create PM docs later" | "PM documents are REQUIRED for new projects. Without them, agents cannot understand your project's domain context or technical requirements. Run `/ring:pre-dev-full` or `/ring:pre-dev-feature` first." |
| "I don't need formal documents" | "PM documents are the source of truth for PROJECT_RULES.md. Development cannot start without documented requirements." |
| "This is just a quick prototype" | "Even prototypes need clear requirements. `/ring:pre-dev-feature` takes ~30 minutes and prevents hours of rework." |
| "I already explained what I want verbally" | "Verbal explanations cannot be used by agents. Requirements MUST be documented in PRD/TRD/Feature Map files." |
| "It's a legacy project but skip the questions" | "The legacy analysis (ring:codebase-explorer + 3 questions) is the only way I can understand your project. It takes ~5 minutes and enables me to help you effectively." |
| "I'll fill in PROJECT_RULES.md myself" | "That works! Create `docs/PROJECT_RULES.md` with: Tech Stack (not in Ring), External Integrations, Domain Terminology. Do not duplicate Ring Standards content. Then run `/ring:dev-cycle` again." |

---

## Step 1: Initialize or Resume

### Instructions-Only Mode (no task file)

**Input:** Custom instructions string without a task file path

**Example:** `/ring:dev-cycle "Add webhook notification support for account status changes"`

When custom instructions are provided without a tasks file, ring:dev-cycle generates tasks internally:

1. **Detect instructions-only mode:** No task file argument AND instructions string provided
2. **Analyze prompt:** Extract intent, scope, and requirements from the prompt
3. **Explore codebase:** Dispatch `ring:codebase-explorer` to understand project structure
4. **Generate tasks:** Create task structure internally based on prompt + codebase analysis

```yaml
Task tool:
  subagent_type: "ring:codebase-explorer"
  prompt: |
    Analyze this codebase to support the following implementation request:
    
    **User Request:** {prompt}
    
    Provide:
    1. Relevant files and patterns for this request
    2. Suggested task breakdown (T-001, T-002, etc.)
    3. Acceptance criteria for each task
    4. Files that will need modification
    
    Output as structured task list compatible with ring:dev-cycle.
```

5. **Present generated tasks:** Show user the auto-generated task breakdown
6. **Confirm with user:** "I generated X tasks from your prompt. Proceed?"
7. **Set state:**
   - `state_path = "docs/ring:dev-cycle/current-cycle.json"`
   - `cycle_type = "prompt"`
   - `source_prompt = "[user's prompt]"`
   - Generate `tasks` array from ring:codebase-explorer output
8. **Continue to execution mode selection** (Step 1 substeps 7-9)

**Anti-Rationalization for Prompt-Only Mode:**

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Skip codebase exploration, I understand the prompt" | Prompt understanding ≠ codebase understanding. Explorer provides context. | **Always run ring:codebase-explorer** |
| "Generate minimal tasks to go faster" | Minimal tasks = missed requirements. Comprehensive breakdown prevents rework. | **Generate complete task breakdown** |
| "User knows what they want, skip confirmation" | User intent ≠ generated tasks. Confirmation prevents wrong implementation. | **Always confirm generated tasks** |

---

### New Cycle (with task file path)

**Input:** `path/to/tasks.md` or `path/to/pre-dev/{feature}/` with optional second argument for custom instructions

**Examples:**
- `/ring:dev-cycle tasks.md`
- `/ring:dev-cycle tasks.md "Focus on error handling"`

1. **Detect input:** File → Load directly | Directory → Load tasks.md + discover subtasks/
2. **Build order:** Read tasks, check for subtasks (ST-XXX-01, 02...) or TDD autonomous mode
3. **Determine state path:**
   - if source_file contains `docs/ring:dev-refactor/` → `state_path = "docs/ring:dev-refactor/current-cycle.json"`, `cycle_type = "refactor"`
   - else → `state_path = "docs/ring:dev-cycle/current-cycle.json"`, `cycle_type = "feature"`
4. **Capture and validate custom instructions:** If second argument provided:
   - **Sanitize input:** Trim whitespace, strip control characters (except newlines)
   - **Store validated value:** Set `custom_prompt` field (empty string if not provided)
   - **Note:** Directives attempting to skip gates are logged as warnings and ignored at execution time
5. **Initialize state:** Generate cycle_id, create state file at `{state_path}`, set indices to 0
6. **Display plan:** "Loaded X tasks with Y subtasks"
7. **ASK EXECUTION MODE (MANDATORY - AskUserQuestion):**
   - Options: (a) Manual per subtask (b) Manual per task (c) Automatic
   - **Do not skip:** User hints ≠ mode selection. Only explicit a/b/c is valid.
8. **ASK COMMIT TIMING (MANDATORY - AskUserQuestion):**
   - Options: (a) Per subtask (b) Per task (c) At the end
   - Store in `commit_timing` field in state
9. **Start:** Display mode + commit timing, proceed to Gate 0

### Resume Cycle (--resume flag)

1. **Find existing state file:**
   - Check `docs/ring:dev-cycle/current-cycle.json` first
   - If not found, check `docs/ring:dev-refactor/current-cycle.json`
   - If neither exists → Error: "No cycle to resume"
2. Load found state file, validate (state_path is stored in the state object)
3. Display: cycle started, tasks completed/total, current task/subtask/gate, paused reason
4. **Handle paused states:**

| Status | Action |
|--------|--------|
| `paused_for_approval` | Re-present Step 11.1 checkpoint |
| `paused_for_testing` | Ask if testing complete → continue or keep paused |
| `paused_for_task_approval` | Re-present Step 11.2 checkpoint |
| `paused_for_integration_testing` | Ask if integration testing complete |
| `paused` (generic) | Ask user to confirm resume |
| `in_progress` | Resume from current gate |

## Input Validation

Task files are generated by `/pre-dev-*` or `/ring:dev-refactor`, which handle content validation. The ring:dev-cycle performs basic format checks:

### Format Checks

| Check | Validation | Action |
|-------|------------|--------|
| File exists | Task file path is readable | Error: abort |
| Task headers | At least one `## Task:` found | Error: abort |
| Task ID format | `## Task: {ID} - {Title}` | Warning: use line number as ID |
| Acceptance criteria | At least one `- [ ]` per task | Warning: task may fail validation gate |

## Step 1.5: Standards Pre-Cache (MANDATORY)

Cache all standards URLs the cycle will need, ONCE, into `state.cached_standards`.
Sub-skills read from this cache instead of calling WebFetch themselves.

**Required URLs to pre-fetch (MUST succeed all):**

1. `https://raw.githubusercontent.com/LerianStudio/ring/main/CLAUDE.md`
2. Language-specific (based on detected project stack):
   - **If Go project:**
     - `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang.md`
     - `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/core.md`
     - `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/bootstrap.md`
     - `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/domain.md`
     - `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/domain-modeling.md`
     - `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/api-patterns.md`
     - `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/architecture.md`
     - `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/security.md`
     - `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/quality.md`
     - `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/multi-tenant.md`
     - `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/testing-fuzz.md`
     - `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/testing-property.md`
     - `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/testing-integration.md`
     - `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/testing-chaos.md`
   - **If TypeScript backend:**
     - `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/typescript.md`
     - `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/typescript/multi-tenant.md`
3. `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/devops.md`
4. `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/sre.md`
5. `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/migration-safety.md` (if SQL migrations detected in project)

**Protocol:**

```text
For each URL in the required list:
  WebFetch: [URL]
  Write to state.cached_standards[URL] = {
    "fetched_at": current_iso_timestamp,
    "content": <fetched content>
  }
```

**MANDATORY:** Save state to file after cache populated — Write tool → [state.state_path]

**Blocker:** If ANY URL fails to fetch, STOP cycle and report. Cache MUST be complete. Sub-skills downstream rely on `state.cached_standards` being populated; a partial cache causes WebFetch fallback warnings and defeats the purpose of pre-caching.

**Rationale:** Before this step existed, every sub-skill dispatch triggered its own WebFetch of the same standards. The 5-minute prompt cache TTL is regularly exceeded, producing 15–25+ redundant network fetches per cycle. A single pre-cache at cycle start reduces that to one fetch per unique URL.

---

## Step 1.6: Detect External Dependencies (Cycle-Level Auto-Detection)

**MANDATORY:** Scan the codebase once at cycle start to detect external dependencies. Store in `state.detected_dependencies` for use by Gates 2, 6, and 7.

```text
detected_dependencies = []

1. Scan docker-compose.yml / docker-compose.yaml for service images:
   - Grep tool: pattern "postgres" in docker-compose* files → add "postgres"
   - Grep tool: pattern "mongo" in docker-compose* files → add "mongodb"
   - Grep tool: pattern "valkey" in docker-compose* files → add "valkey"
   - Grep tool: pattern "redis" in docker-compose* files → add "redis"
   - Grep tool: pattern "rabbitmq" in docker-compose* files → add "rabbitmq"

2. Scan dependency manifests:
   if language == "go":
     - Grep tool: pattern "github.com/lib/pq" in go.mod → add "postgres"
     - Grep tool: pattern "github.com/jackc/pgx" in go.mod → add "postgres"
     - Grep tool: pattern "go.mongodb.org/mongo-driver" in go.mod → add "mongodb"
     - Grep tool: pattern "github.com/redis/go-redis" in go.mod → add "redis"
     - Grep tool: pattern "github.com/valkey-io/valkey-go" in go.mod → add "valkey"
     - Grep tool: pattern "github.com/rabbitmq/amqp091-go" in go.mod → add "rabbitmq"

   if language == "typescript":
     - Grep tool: pattern "\"pg\"" in package.json → add "postgres"
     - Grep tool: pattern "@prisma/client" in package.json → add "postgres"
     - Grep tool: pattern "\"mongodb\"" in package.json → add "mongodb"
     - Grep tool: pattern "\"mongoose\"" in package.json → add "mongodb"
     - Grep tool: pattern "\"redis\"" in package.json → add "redis"
     - Grep tool: pattern "\"ioredis\"" in package.json → add "redis"
     - Grep tool: pattern "@valkey" in package.json → add "valkey"
     - Grep tool: pattern "\"amqplib\"" in package.json → add "rabbitmq"
     - Grep tool: pattern "amqp-connection-manager" in package.json → add "rabbitmq"

3. Deduplicate detected_dependencies
4. Store: state.detected_dependencies = detected_dependencies
5. Log: "Auto-detected external dependencies: [detected_dependencies]"

### ⛔ MANDATORY: Multi-Tenant Detection & Compliance Audit

<cannot_skip>
MANDATORY: Multi-tenant dual-mode applies to all Go services (no exceptions). Gate 0 implements dual-mode from the start using lib-commons v4 resolvers. Gate 0.5G verifies compliance. This detection captures the CURRENT state of the codebase for context.

See [multi-tenant.md](../../docs/standards/golang/multi-tenant.md) for the canonical model and [dev-delivery-verification](../dev-delivery-verification/SKILL.md) Step 3.5G for the verification checks.
</cannot_skip>

```text
6. Detect existing multi-tenant code and audit compliance:
   multi_tenant_exists = false
   multi_tenant_compliant = false

   if language == "go":
     // Phase 1: Detection
     - Grep tool: pattern "MULTI_TENANT_ENABLED" in internal/ --include="*.go" → multi_tenant_exists = true
     - Grep tool: pattern "tenant-manager" in go.mod → multi_tenant_exists = true
     - Grep tool: pattern "TenantMiddleware\|WithPG\|WithMB" in internal/ --include="*.go" → multi_tenant_exists = true

     // Phase 2: Compliance audit (only if multi_tenant_exists = true)
     if multi_tenant_exists:
       compliance_checks = {}
       - Grep: "TENANT_MANAGER_ADDRESS\|TENANT_URL\|TENANT_MANAGER_URL" in internal/ → if match: compliance_checks.config = "NON-COMPLIANT"
       - Grep: "tmmiddleware.NewTenantMiddleware" in internal/ → if no match: compliance_checks.middleware = "NON-COMPLIANT"
       - Grep: "tmcore.GetPGContext\|tmcore.GetMBContext" in internal/ → if no match: compliance_checks.repositories = "NON-COMPLIANT"
       - Grep: "WithCircuitBreaker" in internal/ → if no match: compliance_checks.circuit_breaker = "NON-COMPLIANT"
       - Grep: "TestMultiTenant_BackwardCompatibility" in internal/ → if no match: compliance_checks.backward_compat = "NON-COMPLIANT"

       if all checks pass: multi_tenant_compliant = true
       else: multi_tenant_compliant = false

   if language == "typescript":
     - Grep tool: pattern "MULTI_TENANT_ENABLED" in src/ --include="*.ts" → multi_tenant_exists = true
     - Grep tool: pattern "tenant-manager" in package.json → multi_tenant_exists = true
     // TypeScript compliance audit follows same pattern

   state.multi_tenant_exists = multi_tenant_exists
   state.multi_tenant_compliant = multi_tenant_compliant

   if multi_tenant_exists && multi_tenant_compliant:
     Log: "Multi-tenant COMPLIANT — Gate 0 agent uses dual-mode resolvers, Gate 0.5G will verify"
   elif multi_tenant_exists && !multi_tenant_compliant:
     Log: "Multi-tenant DETECTED but NON-COMPLIANT — Gate 0 agent must fix, Gate 0.5G will verify"
   else:
     Log: "Multi-tenant NOT detected — Gate 0 agent will implement dual-mode, Gate 0.5G will verify"
```

**MANDATORY: ⛔ Save state to file — Write tool → [state.state_path]**

<auto_detect_reason>
PM team task files often omit external_dependencies. If the codebase uses postgres, mongodb, valkey, or rabbitmq, these MUST be detected and passed to Gates 6 (integration) and 7 (chaos). Auto-detection at cycle level avoids redundant scans per gate.

Multi-tenant state is detected here and passed to Gate 0 (implementation) and Gate 0.5G (verification). See [multi-tenant.md](../../docs/standards/golang/multi-tenant.md) for the canonical model and compliance criteria.
</auto_detect_reason>

### License Detection (Advisory)

Detect the repository license at cycle start. This check is advisory — it does not block Gate 0. If no license is found, prompt the user; if the user declines, log a warning and proceed.

```text
7. Detect repository license:
   license_type = "unknown"

   - ls LICENSE LICENSE.md LICENSE.txt 2>/dev/null
   - If found:
     - grep -l "Apache License" LICENSE* → license_type = "apache"
     - grep -l "Elastic License" LICENSE* → license_type = "elv2"
     - grep -l "All rights reserved.*Lerian" LICENSE* → license_type = "proprietary"
   - If not found (no LICENSE file):
     → Ask user: "No LICENSE file detected. Which license should this repository use? [apache|elv2|proprietary|skip]"
     → If user selects a license: set license_type = <chosen value>, invoke Skill("ring:dev-licensing") with chosen type
     → If user selects "skip": set license_type = "skip", log "⚠️ WARNING: No LICENSE file. License headers may be inconsistent."

   Store: state.license_type = license_type
   Log: "License detected: {license_type}"
```

---

## Step 2: Gate 0 - Implementation (Per Execution Unit)

ℹ️ **CADENCE:** Subtask-level. Execution unit is always a subtask (or the task-itself when the task has no subtasks). Writes to `state.tasks[i].subtasks[j].gate_progress.implementation`. Task-level gates (1, 2, 4, 5, 6w, 7w, 8) MUST NOT be dispatched from inside this step — they run after the subtask loop.

**REQUIRED SUB-SKILL:** Use ring:dev-implementation

**Execution Unit:** Task-itself (if no subtasks) or a Subtask (if task has subtasks). Either way, the unit is a SUBTASK-LEVEL scope.

### Pre-Dispatch: Before Gate 0 Checkpoint (MANDATORY)

MUST execute the **Before Gate 0 (task start)** row from the State Persistence Checkpoints table before sub-steps 2.1–2.3:
- Set `task.status = "in_progress"` in state JSON
- Update tasks.md Status → `🔄 Doing` (per tasks.md Status update rules in that table)
- Write state to file

CANNOT proceed to sub-steps 2.1–2.3 without completing this checkpoint.

### ⛔ MANDATORY: Invoke ring:dev-implementation Skill (not inline execution)

See [shared-patterns/shared-orchestrator-principle.md](../shared-patterns/shared-orchestrator-principle.md) for full details.

**⛔ FORBIDDEN: Executing TDD-RED/GREEN logic directly from this step.**
MUST invoke the ring:dev-implementation skill via the Skill tool; it handles all TDD phases, agent selection, agent dispatch, standards verification, and fix iteration.

### ⛔ Post-Generation Panic Check (MANDATORY)

After ring:dev-implementation completes, verify generated code:

| Check | Command | Expected | If Found |
|-------|---------|----------|----------|
| No panic() | `grep -rn "panic(" --include="*.go" --exclude="*_test.go"` | 0 results | Return to Gate 0 with fix instructions |
| No log.Fatal() | `grep -rn "log.Fatal" --include="*.go"` | 0 results | Return to Gate 0 with fix instructions |
| No Must* helpers | `grep -rn "Must[A-Z]" --include="*.go" \| grep -v "regexp\.MustCompile"` | 0 results | Return to Gate 0 with fix instructions |
| No os.Exit() | `grep -rn "os.Exit" --include="*.go" --exclude="main.go"` | 0 results | Return to Gate 0 with fix instructions |

**If any check fails: DO NOT proceed to Gate 1. Return to Gate 0 with specific fix instructions.**

### ⛔ File Size Enforcement (MANDATORY — All Gates)

See [shared-patterns/file-size-enforcement.md](../shared-patterns/file-size-enforcement.md) for thresholds, verification commands, split strategies, and agent instructions.

**Summary:** No source file may exceed 300 lines (>300 = loop back to agent; >500 = hard block). Implementation agents MUST split proactively. Enforcement points:

- **Gate 0:** Implementation agent receives file-size instructions; orchestrator runs verification command after agent completes and loops back if any file > 300 lines.
- **Gate 0 exit check (inline in ring:dev-implementation Step 7):** Delivery verification runs 7 checks as exit criteria: (A) file-size, (B) license headers, (C) linting, (D) migration safety, (E) vulnerability scanning, (F) API backward compatibility, (G) multi-tenant dual-mode. Any FAIL → ring:dev-implementation re-iterates with specific fix instructions.
- **Gate 8:** Code reviewers MUST flag any file > 300 lines as a MEDIUM+ issue (blocking).

### Step 2.1: Prepare Input for ring:dev-implementation Skill

```text
Gather from current execution unit:

implementation_input = {
  // REQUIRED - from current execution unit
  unit_id: state.current_unit.id,
  requirements: state.current_unit.acceptance_criteria,

  // REQUIRED - detected from project
  language: state.current_unit.language,  // "go" | "typescript" | "python"
  service_type: state.current_unit.service_type,  // "api" | "worker" | "batch" | "cli" | "frontend" | "bff"

  // OPTIONAL - additional context
  technical_design: state.current_unit.technical_design || null,
  existing_patterns: state.current_unit.existing_patterns || [],
  project_rules_path: "docs/PROJECT_RULES.md"
}
```

### Step 2.2: Invoke ring:dev-implementation Skill

```text
1. Record gate start timestamp

2. REQUIRED: Invoke ring:dev-implementation skill with structured input:

   Skill("ring:dev-implementation") with input:
     unit_id: implementation_input.unit_id
     requirements: implementation_input.requirements
     language: implementation_input.language
     service_type: implementation_input.service_type
     technical_design: implementation_input.technical_design
     existing_patterns: implementation_input.existing_patterns
     project_rules_path: implementation_input.project_rules_path

   The skill handles:
   - Selecting appropriate agent (Go/TS/Frontend based on language)
   - TDD-RED phase (writing failing test, capturing failure output)
   - TDD-GREEN phase (implementing code to pass test)
   - Standards compliance verification (iteration loop, max 3 attempts)
   - Re-dispatching agent for compliance fixes
   - Outputting Standards Coverage Table with evidence

3. REQUIRED: Parse skill output for results:

   Expected output sections:
   - "## Implementation Summary" → status (PASS/FAIL), agent used
   - "## TDD Results" → RED/GREEN phase status
   - "## Files Changed" → created/modified files list
   - "## Handoff to Next Gate" → ready_for_gate_1: YES/NO

   if skill output contains "Status: PASS" and "Ready for Gate 1: YES":
     → Gate 0 PASSED. Proceed to Step 2.3.

   if skill output contains "Status: FAIL" or "Ready for Gate 1: NO":
     → Gate 0 BLOCKED.
     → Skill already dispatched fixes to implementation agent
     → Skill already re-ran TDD and standards verification
     → If "ESCALATION" in output: STOP and report to user

4. **MANDATORY: ⛔ Save state to file — Write tool → [state.state_path]**
```

### Step 2.3: Gate 0 Complete

```text
5. When ring:dev-implementation skill returns PASS:

   REQUIRED: Parse from skill output:
   - agent_used: extract from "## Implementation Summary"
   - tdd_red_status: extract from "## TDD Results" table
   - tdd_green_status: extract from "## TDD Results" table
   - files_changed: extract from "## Files Changed" table
   - standards_compliance: extract from Standards Coverage Table

   - agent_outputs.implementation = {
       skill: "ring:dev-implementation",
       agent: "[agent used by skill]",
       output: "[full skill output]",
       timestamp: "[ISO timestamp]",
       duration_ms: [execution time],
       tdd_red: {
         status: "completed",
         test_file: "[from skill output]",
         failure_output: "[from skill output]"
       },
       tdd_green: {
         status: "completed",
         implementation_files: "[from skill output]",
         pass_output: "[from skill output]"
       },
       standards_compliance: {
         total_sections: [N from skill output],
         compliant: [N sections with ✅],
         not_applicable: [N sections with N/A],
         non_compliant: 0
       }
     }

6. Display to user:
   ┌─────────────────────────────────────────────────┐
   │ ✓ GATE 0 COMPLETE                              │
   ├─────────────────────────────────────────────────┤
   │ Skill: ring:dev-implementation                  │
   │ Agent: [agent_used]                             │
   │ TDD-RED:   FAIL captured ✓                     │
   │ TDD-GREEN: PASS verified ✓                     │
   │ STANDARDS: [N]/[N] sections compliant ✓        │
   │                                                 │
   │ Proceeding to Gate 1 (DevOps)...               │
   └─────────────────────────────────────────────────┘

7. MANDATORY: ⛔ Save state to file — Write tool → [state.state_path]
   See "State Persistence Rule" section.

8. Proceed to Step 2.3.1 (Delivery Verification Exit Check)
```

### Step 2.3.1: Delivery Verification Exit Check (MANDATORY before Gate 1)

After Gate 0 PASS, delivery verification runs AS EXIT CRITERIA (not as a separate gate).
This check is performed inside `ring:dev-implementation` as its Step 7 (Delivery
Verification Exit Check). The orchestrator DOES NOT dispatch a separate skill.

Verify that the dev-implementation handoff includes `delivery_verification` field:

  required_handoff_fields:
    - implementation_summary
    - files_changed
    - tests_written
    - tdd_red_evidence
    - tdd_green_evidence
    - delivery_verification:        # NEW — added in R3
        result: "PASS|PARTIAL|FAIL"
        requirements_total: int
        requirements_delivered: int
        requirements_missing: int
        dead_code_items: int

IF delivery_verification.result == "PASS":
  → Update state.tasks[current].subtasks[current].gate_progress.implementation.delivery_verified = true
  → Proceed to Gate 1 (DevOps)

IF delivery_verification.result == "PARTIAL" or "FAIL":
  → Return control to dev-implementation with remediation instructions (max 2 retries)
  → After 2 retries → escalate to user

Anti-Rationalization:
| Rationalization | Why It's WRONG | Required Action |
|---|---|---|
| "Gate 0.5 still exists, just renamed" | Gate 0.5 was DELETED as a separate dispatch. Checks now run inline in Gate 0. | **Read `delivery_verification` from Gate 0 handoff; do NOT dispatch a separate skill.** |
| "I'll just skip this check if Gate 0 passed" | Gate 0 passing without `delivery_verification` means Gate 0 is incomplete. | **Verify `delivery_verification` exists in handoff. If absent → Gate 0 failed.** |

No separate `state.gate_progress.delivery_verification` field — delivery verification is a sub-check of implementation, tracked inline.

### Anti-Rationalization: Gate 0 Skill Invocation

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "I can run TDD-RED/GREEN directly from here" | Inline TDD = skipping the skill. Skill has iteration logic and validation. | **Invoke Skill("ring:dev-implementation")** |
| "I already know which agent to dispatch" | Agent selection is the SKILL's job, not the orchestrator's. | **Invoke Skill("ring:dev-implementation")** |
| "The TDD steps are documented here, I'll follow them" | These steps are REFERENCE, not EXECUTABLE. The skill is executable. | **Invoke Skill("ring:dev-implementation")** |
| "Skill adds overhead for simple tasks" | Overhead = compliance checks. Simple ≠ exempt. | **Invoke Skill("ring:dev-implementation")** |
| "I'll dispatch the agent and verify output myself" | Self-verification skips the skill's re-dispatch loop. | **Invoke Skill("ring:dev-implementation")** |
| "Agent already did TDD internally" | Internal ≠ verified by skill. Skill validates output structure. | **Invoke Skill("ring:dev-implementation")** |

---

## Step 3: Gate 1 - DevOps (Per Task — after all subtasks complete Gate 0 + Gate 3 + Gate 9)

⛔ **CADENCE:** This gate runs ONCE per task, NOT per subtask. Do NOT dispatch during the subtask loop. Input `implementation_files` is the UNION of all subtasks' changed files; `gate0_handoffs` is an ARRAY of per-subtask implementation handoffs.

**REQUIRED SUB-SKILLS:** Use ring:dev-devops, then ring:dev-docker-security (audit)

### ⛔ HARD GATE: Required Artifacts MUST Be Created

**Gate 1 is a BLOCKING gate.** DevOps agent MUST create all required artifacts. If any artifact is missing:
- You CANNOT proceed to Gate 2
- You MUST re-dispatch to ring:devops-engineer to create missing artifacts
- You MUST verify all artifacts exist before proceeding

### Required Artifacts

**See [shared-patterns/standards-coverage-table.md](../skills/shared-patterns/standards-coverage-table.md) → "ring:devops-engineer → devops.md" for all required sections.**

**Key artifacts from devops.md:**
- Containers (Dockerfile + Docker Compose)
- Makefile Standards (all required commands)
- Infrastructure as Code (if applicable)
- Helm charts (if K8s deployment)

### Step 3.1: Prepare Input for ring:dev-devops Skill

⛔ **Input scope:** TASK-level. `implementation_files` is the UNION of `files_changed` across all subtasks of the current task; `gate0_handoffs` is an ARRAY (one per subtask).

```text
Gather from completed subtask-level gates of the current task:

task = state.tasks[state.current_task_index]

devops_input = {
  // REQUIRED - TASK-level identifiers (NOT subtask)
  unit_id: task.id,  // TASK id (e.g., "T-001"), not subtask id
  language: task.language,  // "go" | "typescript" | "python"
  service_type: task.service_type,  // "api" | "worker" | "batch" | "cli"

  // REQUIRED - UNION of files changed across all subtasks of this task
  implementation_files: flatten(task.subtasks.map(st =>
    st.gate_progress.implementation.files_changed || []
  )),

  // REQUIRED - ARRAY of per-subtask Gate 0 handoffs (one per subtask)
  gate0_handoffs: task.subtasks.map(st => st.gate_progress.implementation),

  // OPTIONAL - additional context (union across subtasks where applicable)
  new_dependencies: union(task.subtasks.map(st => st.new_deps || [])),
  new_env_vars: union(task.subtasks.map(st => st.env_vars || [])),
  new_services: union(task.subtasks.map(st => st.services || [])),
  existing_dockerfile: [check if Dockerfile exists],
  existing_compose: [check if docker-compose.yml exists]
}
```

### Step 3.2: Invoke ring:dev-devops Skill

```text
1. Record gate start timestamp

2. Invoke ring:dev-devops skill with structured input:

   Skill("ring:dev-devops") with input:
     unit_id: devops_input.unit_id                    # TASK id
     language: devops_input.language
     service_type: devops_input.service_type
     implementation_files: devops_input.implementation_files  # UNION across subtasks
     gate0_handoffs: devops_input.gate0_handoffs      # ARRAY of subtask handoffs
     new_dependencies: devops_input.new_dependencies
     new_env_vars: devops_input.new_env_vars
     new_services: devops_input.new_services
     existing_dockerfile: devops_input.existing_dockerfile
     existing_compose: devops_input.existing_compose

   The skill handles:
   - Dispatching ring:devops-engineer agent
   - Dockerfile creation/update
   - docker-compose.yml configuration
   - .env.example documentation
   - Verification commands execution
   - Fix iteration loop (max 3 attempts)

3. Parse skill output for results:
   
   Expected output sections:
   - "## DevOps Summary" → status, iterations
   - "## Files Changed" → Dockerfile, docker-compose, .env.example actions
   - "## Verification Results" → build, startup, health checks
   - "## Handoff to Next Gate" → ready_for_sre: YES/no
   
   if skill output contains "Status: PASS" and "Ready for Gate 2: YES":
     → Gate 1 PASSED. Proceed to Step 3.3.
   
   if skill output contains "Status: FAIL" or "Ready for Gate 2: no":
     → Gate 1 BLOCKED.
     → Skill already dispatched fixes to ring:devops-engineer
     → Skill already re-ran verification
     → If "ESCALATION" in output: STOP and report to user

4. **MANDATORY: ⛔ Save state to file — Write tool → [state.state_path]**
```

### Step 3.2.1: Docker Security Audit

```text
After ring:dev-devops PASSES, run Docker Hub Health Score compliance audit
on the created/updated Dockerfile:

   Skill("ring:dev-docker-security") with input:
     dockerfile_path: [extract from devops "## Files Changed" table, or default to "Dockerfile"]
     language: devops_input.language
     service_type: devops_input.service_type
     mode: "audit"

   The skill validates:
   - Non-root USER directive
   - Minimal base image (distroless/alpine)
   - No AGPL v3 license risk
   - Supply chain attestations in pipeline
   - Audit checklist compliance

   if skill output contains "Result: PASS":
     → Proceed to Step 3.3.

   if skill output contains "Result: FAIL":
     → Re-dispatch ring:devops-engineer with the failing policies
     → Re-run ring:dev-docker-security audit
     → Max 3 total attempts (2 retries). If still FAIL: STOP and report to user
```

### Step 3.3: Gate 1 Complete

```text
5. When ring:dev-devops skill returns PASS:
   
   Parse from skill output:
   - status: extract from "## DevOps Summary"
   - dockerfile_action: extract from "## Files Changed" table
   - compose_action: extract from "## Files Changed" table
   - verification_passed: extract from "## Verification Results"
   
   - agent_outputs.devops = {
       skill: "ring:dev-devops",
       output: "[full skill output]",
       artifacts_created: ["Dockerfile", "docker-compose.yml", ".env.example"],
       verification_passed: true,
       timestamp: "[ISO timestamp]",
       duration_ms: [execution time]
     }

6. Update state:
   - gate_progress.devops.status = "completed"
   - gate_progress.devops.artifacts = [list from skill output]

7. Proceed to Gate 2
```

### Gate 1 Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Dockerfile exists, skip other artifacts" | all artifacts required. 1/4 ≠ complete. | **Create all artifacts** |
| "docker-compose not needed locally" | docker-compose is MANDATORY for local dev. | **Create docker-compose.yml** |
| "Makefile is optional" | Makefile is MANDATORY for standardized commands. | **Create Makefile** |
| ".env.example can be added later" | .env.example documents required config NOW. | **Create .env.example** |
| "Small service doesn't need all this" | Size is irrelevant. Standards apply uniformly. | **Create all artifacts** |

## Step 4: Gate 2 - SRE (Per Task — after all subtasks complete Gate 0 + Gate 3 + Gate 9)

⛔ **CADENCE:** This gate runs ONCE per task, NOT per subtask. Input `implementation_files` is the UNION of all subtasks' changed files; `gate0_handoffs` is an ARRAY.

**REQUIRED SUB-SKILL:** Use `ring:dev-sre`

### Step 4.1: Prepare Input for ring:dev-sre Skill

⛔ **Input scope:** TASK-level. Aggregate from all subtasks of the current task.

```text
Gather from completed subtask-level gates:

task = state.tasks[state.current_task_index]

sre_input = {
  // REQUIRED - TASK-level identifiers
  unit_id: task.id,  // TASK id
  language: task.language,
  service_type: task.service_type,

  // REQUIRED - UNION across subtasks
  implementation_files: flatten(task.subtasks.map(st =>
    st.gate_progress.implementation.files_changed || []
  )),

  // REQUIRED - ARRAY of per-subtask Gate 0 handoffs
  gate0_handoffs: task.subtasks.map(st => st.gate_progress.implementation),

  // REQUIRED - implementation_agent (consistent across subtasks of the same task)
  implementation_agent: task.subtasks[0].gate_progress.implementation.agent,

  // OPTIONAL - additional context
  external_dependencies: task.external_deps || state.detected_dependencies || [],
  gate1_handoff: task.gate_progress.devops  // task-level Gate 1 output (just completed)
}
```

### Step 4.2: Invoke ring:dev-sre Skill

```text
1. Record gate start timestamp

2. Invoke ring:dev-sre skill with structured input:

   Skill("ring:dev-sre") with input:
     unit_id: sre_input.unit_id                       # TASK id
     language: sre_input.language
     service_type: sre_input.service_type
     implementation_agent: sre_input.implementation_agent
     implementation_files: sre_input.implementation_files  # UNION across subtasks
     external_dependencies: sre_input.external_dependencies
     gate0_handoffs: sre_input.gate0_handoffs          # ARRAY of subtask handoffs
     gate1_handoff: sre_input.gate1_handoff

   The skill handles:
   - Dispatching SRE agent for validation
   - Structured logging validation
   - Distributed tracing validation
   - Code instrumentation coverage (90%+ required)
   - Context propagation validation (InjectHTTPContext/InjectGRPCContext)
   - Dispatching fixes to implementation agent if needed
   - Re-validation loop (max 3 iterations)

3. Parse skill output for validation results:
   
   Expected output sections:
   - "## Validation Result" → status, iterations, coverage
   - "## Instrumentation Coverage" → table with per-layer coverage
   - "## Issues Found" → list or "None"
   - "## Handoff to Next Gate" → ready_for_testing: YES/no
   
   if skill output contains "Status: PASS" and "Ready for Gate 3: YES":
     → Gate 2 PASSED. Proceed to Step 4.3.
   
   if skill output contains "Status: FAIL" or "Ready for Gate 3: no":
     → Gate 2 BLOCKED. 
     → Skill already dispatched fixes to implementation agent
     → Skill already re-ran validation
     → If "ESCALATION" in output: STOP and report to user

4. **MANDATORY: ⛔ Save state to file — Write tool → [state.state_path]**
```

### Step 4.3: Gate 2 Complete

```text
5. When ring:dev-sre skill returns PASS:
   
   Parse from skill output:
   - status: extract from "## Validation Result"
   - instrumentation_coverage: extract percentage from coverage table
   - iterations: extract from "Iterations:" line
   
   - agent_outputs.sre = {
       skill: "ring:dev-sre",
       output: "[full skill output]",
       validation_result: "PASS",
       instrumentation_coverage: "[X%]",
       iterations: [count],
       timestamp: "[ISO timestamp]",
       duration_ms: [execution time]
     }

6. Update state:
   - gate_progress.sre.status = "completed"
   - gate_progress.sre.observability_validated = true
   - gate_progress.sre.instrumentation_coverage = "[X%]"

7. Proceed to Gate 3
```

### Gate 2 Anti-Rationalization Table

See [ring:dev-sre/SKILL.md](../dev-sre/SKILL.md) for complete anti-rationalization tables covering:
- Observability deferral rationalizations
- Instrumentation coverage rationalizations
- Context propagation rationalizations

### Gate 2 Pressure Resistance

| User Says | Your Response |
|-----------|---------------|
| "Skip SRE validation, we'll add observability later" | "Observability is MANDATORY for Gate 2. Invoking ring:dev-sre skill now." |
| "SRE found issues but let's continue" | "Gate 2 is a HARD GATE. ring:dev-sre skill handles fix dispatch and re-validation." |
| "Instrumentation coverage is low but code works" | "90%+ instrumentation coverage is REQUIRED. ring:dev-sre skill will not pass until met." |

## Step 5: Gate 3 - Unit Testing (Per Execution Unit)

ℹ️ **CADENCE:** Subtask-level. Execution unit = a subtask (or the task itself when no subtasks). Writes to `state.tasks[i].subtasks[j].gate_progress.unit_testing`.

**REQUIRED SUB-SKILL:** Use `ring:dev-unit-testing`

### Step 5.1: Prepare Input for ring:dev-unit-testing Skill

```text
Gather from previous gates:

testing_input = {
  // REQUIRED - from current execution unit
  unit_id: state.current_unit.id,
  acceptance_criteria: state.current_unit.acceptance_criteria,  // list of ACs to test
  implementation_files: agent_outputs.implementation.files_changed,
  language: state.current_unit.language,  // "go" | "typescript" | "python"
  
  // OPTIONAL - additional context
  coverage_threshold: 85,  // Ring minimum, PROJECT_RULES.md can raise
  gate0_handoff: agent_outputs.implementation,  // full Gate 0 output
  existing_tests: [check for existing test files]
}
```

### Step 5.2: Invoke ring:dev-unit-testing Skill

```text
1. Record gate start timestamp

2. Invoke ring:dev-unit-testing skill with structured input:

   Skill("ring:dev-unit-testing") with input:
     unit_id: testing_input.unit_id
     acceptance_criteria: testing_input.acceptance_criteria
     implementation_files: testing_input.implementation_files
     language: testing_input.language
     coverage_threshold: testing_input.coverage_threshold
     gate0_handoff: testing_input.gate0_handoff
     existing_tests: testing_input.existing_tests

   The skill handles:
   - Dispatching ring:qa-analyst agent
   - Test creation following TDD methodology
   - Coverage measurement and validation (85%+ required)
   - Traceability matrix (AC → Test mapping)
   - Dispatching fixes to implementation agent if coverage < threshold
   - Re-validation loop (max 3 iterations)

3. Parse skill output for results:
   
   Expected output sections:
   - "## Testing Summary" → status, iterations
   - "## Coverage Report" → threshold vs actual
   - "## Traceability Matrix" → AC-to-test mapping
   - "## Handoff to Next Gate" → ready_for_review: YES/no
   
   if skill output contains "Status: PASS" and "Ready for Next Gate: YES":
     → Gate 3 PASSED. Proceed to Step 5.3.

   if skill output contains "Status: FAIL" or "Ready for Next Gate: NO":
     → Gate 3 BLOCKED.
     → Skill already dispatched fixes to implementation agent
     → Skill already re-ran coverage check
     → If "ESCALATION" in output: STOP and report to user

4. **MANDATORY: ⛔ Save state to file — Write tool → [state.state_path]**
```

### Step 5.3: Gate 3 Complete

```text
5. When ring:dev-unit-testing skill returns PASS:
   
   Parse from skill output:
   - coverage_actual: extract percentage from "## Coverage Report"
   - coverage_threshold: extract from "## Coverage Report"
   - criteria_covered: extract from "## Traceability Matrix"
   - iterations: extract from "Iterations:" line
   
   - agent_outputs.testing = {
       skill: "ring:dev-unit-testing",
       output: "[full skill output]",
       verdict: "PASS",
       coverage_actual: [X%],
       coverage_threshold: [85%],
       criteria_covered: "[X/Y]",
       iterations: [count],
       timestamp: "[ISO timestamp]",
       duration_ms: [execution time],
       failures: [],  // Empty when PASS; see schema below for FAIL
       uncovered_criteria: []  // Empty when all ACs covered
     }
   
   **If iterations > 1 (tests failed before passing), populate `failures[]`:**
   ```json
   failures: [
     {
       "test_name": "TestUserCreate_InvalidEmail",
       "test_file": "internal/handler/user_test.go",
       "error_type": "assertion|panic|timeout|compilation",
       "expected": "[expected value]",
       "actual": "[actual value]",
       "message": "[error message from test output]",
       "stack_trace": "[relevant stack trace]",
       "fixed_in_iteration": [iteration number when fixed]
     }
   ]
   ```
   
   **If coverage < 100% of acceptance criteria, populate `uncovered_criteria[]`:**
   ```json
   uncovered_criteria: [
     {
       "criterion_id": "AC-001",
       "description": "User should receive email confirmation",
       "reason": "No test found for email sending functionality"
     }
   ]
   ```

6. Update state:
   - gate_progress.testing.status = "completed"
   - gate_progress.testing.coverage = [coverage_actual]

7. Proceed to Gate 4 (Fuzz Testing)
```

### Gate 3 Thresholds

- **Minimum:** 85% (Ring standard - CANNOT be lowered)
- **Project-specific:** Can be higher if defined in `docs/PROJECT_RULES.md`
- **Validation:** Threshold < 85% → Use 85%

### Gate 3 Pressure Resistance

| User Says | Your Response |
|-----------|---------------|
| "84% is close enough" | "85% is Ring minimum. ring:dev-unit-testing skill enforces this." |
| "Skip testing, deadline" | "Testing is MANDATORY. ring:dev-unit-testing skill handles iterations." |
| "Manual testing covers it" | "Gate 3 requires executable unit tests. Invoking ring:dev-unit-testing now." |

## Step 6: Gate 4 - Fuzz Testing (Per Task — after all subtasks complete Gate 0 + Gate 3 + Gate 9)

⛔ **CADENCE:** This gate runs ONCE per task, NOT per subtask. Input `implementation_files` is the UNION of all subtasks' changed files.

**REQUIRED SUB-SKILL:** Use `ring:dev-fuzz-testing`

**MANDATORY GATE:** All code paths MUST have fuzz tests to discover edge cases and crashes.

### Step 6.1: Prepare Input for ring:dev-fuzz-testing Skill

⛔ **Input scope:** TASK-level. Aggregate from all subtasks of the current task.

```text
task = state.tasks[state.current_task_index]

fuzz_testing_input = {
  // REQUIRED - TASK-level
  unit_id: task.id,  // TASK id
  language: task.language,  // "go" | "typescript"

  // REQUIRED - UNION across subtasks
  implementation_files: flatten(task.subtasks.map(st =>
    st.gate_progress.implementation.files_changed || []
  )),

  // REQUIRED - ARRAY of per-subtask unit-testing handoffs (Gate 3 is per subtask)
  gate3_handoffs: task.subtasks.map(st => st.gate_progress.unit_testing)
}
```

### Step 6.2: Invoke ring:dev-fuzz-testing Skill

```text
1. Record gate start timestamp

2. Invoke ring:dev-fuzz-testing skill with structured input:

   Skill("ring:dev-fuzz-testing") with input:
     unit_id: fuzz_testing_input.unit_id               # TASK id
     implementation_files: fuzz_testing_input.implementation_files  # UNION across subtasks
     language: fuzz_testing_input.language
     gate3_handoffs: fuzz_testing_input.gate3_handoffs # ARRAY of per-subtask handoffs

   The skill handles:
   - Dispatching ring:qa-analyst agent (test_mode: fuzz)
   - Fuzz function creation (FuzzXxx naming)
   - Seed corpus generation (minimum 5 entries)
   - f.Add() pattern validation
   - Dispatching fixes if crashes found
   - Re-validation loop (max 3 iterations)

3. Parse skill output for results:

   if skill output contains "Status: PASS":
     → Gate 4 PASSED. Proceed to Gate 5.

   if skill output contains "Status: FAIL":
     → Gate 4 BLOCKED.

4. **MANDATORY: ⛔ Save state to file — Write tool → [state.state_path]**
```

### Step 6.3: Gate 4 Complete

```text
5. Update state:
   - gate_progress.fuzz_testing.status = "completed"
   - gate_progress.fuzz_testing.corpus_entries = [count]

6. Proceed to Gate 5 (Property Testing)
```

---

## Step 7: Gate 5 - Property-Based Testing (Per Task — after all subtasks complete Gate 0 + Gate 3 + Gate 9)

⛔ **CADENCE:** This gate runs ONCE per task, NOT per subtask. Input `implementation_files` is the UNION of all subtasks' changed files; `domain_invariants` is the UNION across subtasks.

**REQUIRED SUB-SKILL:** Use `ring:dev-property-testing`

**MANDATORY GATE:** Domain invariants MUST be verified with property-based tests.

### Step 7.1: Prepare Input for ring:dev-property-testing Skill

⛔ **Input scope:** TASK-level.

```text
task = state.tasks[state.current_task_index]

property_testing_input = {
  // REQUIRED - TASK-level
  unit_id: task.id,  // TASK id
  language: task.language,

  // REQUIRED - UNION across subtasks
  implementation_files: flatten(task.subtasks.map(st =>
    st.gate_progress.implementation.files_changed || []
  )),

  // Domain invariants — UNION across subtasks of the task
  domain_invariants: union(task.subtasks.map(st => st.domain_invariants || []))
}
```

### Step 7.2: Invoke ring:dev-property-testing Skill

```text
1. Record gate start timestamp

2. Invoke ring:dev-property-testing skill with structured input:

   Skill("ring:dev-property-testing") with input:
     unit_id: property_testing_input.unit_id
     implementation_files: property_testing_input.implementation_files
     language: property_testing_input.language
     domain_invariants: property_testing_input.domain_invariants

   The skill handles:
   - Dispatching ring:qa-analyst agent (test_mode: property)
   - Property function creation (TestProperty_* naming)
   - quick.Check pattern validation
   - Invariant verification
   - Dispatching fixes if properties fail
   - Re-validation loop (max 3 iterations)

3. Parse skill output for results:

   if skill output contains "Status: PASS":
     → Gate 5 PASSED. Proceed to Gate 6.

   if skill output contains "Status: FAIL":
     → Gate 5 BLOCKED.

4. **MANDATORY: ⛔ Save state to file — Write tool → [state.state_path]**
```

### Step 7.3: Gate 5 Complete

```text
5. Update state:
   - gate_progress.property_testing.status = "completed"
   - gate_progress.property_testing.properties_tested = [count]

6. Proceed to Gate 6 (Integration Testing)
```

---

## Step 8: Gate 6 - Integration Testing (Per Task — WRITE ONLY)

⛔ **CADENCE:** Write mode runs ONCE per task, NOT per subtask. Execute mode runs ONCE at cycle end (Step 12.1). Input `implementation_files` is the UNION of all subtasks' changed files.

**REQUIRED SUB-SKILL:** Use `ring:dev-integration-testing`

**MANDATORY GATE:** All code MUST have integration tests using testcontainers.

**⛔ DEFERRED EXECUTION:** Per task, this gate writes/updates integration test code and verifies compilation. Tests are NOT executed here (no containers). Actual execution happens at end of cycle (Step 12.1).

### Step 8.1: Prepare Input for ring:dev-integration-testing Skill

⛔ **Input scope:** TASK-level.

```text
task = state.tasks[state.current_task_index]

integration_testing_input = {
  // REQUIRED - TASK-level
  unit_id: task.id,  // TASK id
  language: task.language,
  mode: "write_only",  // CRITICAL: write tests, verify compilation, do NOT execute

  // REQUIRED - UNION across subtasks of the task
  integration_scenarios: union(task.subtasks.map(st => st.integration_scenarios || [])),
  external_dependencies: union(task.subtasks.map(st => st.external_dependencies || []))
    || state.detected_dependencies
    || [],
  implementation_files: flatten(task.subtasks.map(st =>
    st.gate_progress.implementation.files_changed || []
  )),

  // OPTIONAL - additional context
  gate5_handoff: task.gate_progress.property_testing  // task-level Gate 5 output
}

// NOTE: external_dependencies falls back to state.detected_dependencies
// from Step 1.6 (cycle-level auto-detection) when no subtask defines them.
```

### Step 8.2: Invoke ring:dev-integration-testing Skill (Write Mode)

```text
1. Record gate start timestamp

2. REQUIRED: Invoke ring:dev-integration-testing skill with structured input:

   Skill("ring:dev-integration-testing") with input:
     unit_id: integration_testing_input.unit_id
     integration_scenarios: integration_testing_input.integration_scenarios
     external_dependencies: integration_testing_input.external_dependencies
     language: integration_testing_input.language
     mode: "write_only"
     gate5_handoff: integration_testing_input.gate5_handoff
     implementation_files: integration_testing_input.implementation_files

   In write_only mode, the skill handles:
   - Dispatching ring:qa-analyst agent (test_mode: integration)
   - Writing/updating integration test code for current unit's changes
   - Verifying test compilation (go build ./... or tsc --noEmit)
   - Verifying build tags (//go:build integration) present
   - Verifying testcontainers imports present
   - NOT spinning up containers or executing tests

3. REQUIRED: Parse skill output for results:

   Expected output:
   - "## Integration Test Code" → files written/updated
   - "## Compilation Check" → PASS/FAIL
   - "## Standards Compliance" → build tags, naming, testcontainers

   if compilation PASS and standards met:
     → Gate 6 (write) PASSED. Proceed to Step 8.3.

   if compilation FAIL:
     → Gate 6 BLOCKED. Fix compilation errors before proceeding.

4. **MANDATORY: ⛔ Save state to file — Write tool → [state.state_path]**
```

### Step 8.3: Gate 6 (Write) Complete

```text
5. Update state:
   - gate_progress.integration_testing.write_status = "completed"
   - gate_progress.integration_testing.execution_status = "deferred"  // Executed at end of cycle
   - gate_progress.integration_testing.test_files = [list of test files written/updated]
   - gate_progress.integration_testing.compilation_passed = true

6. Proceed to Gate 7 (Chaos Testing — Write Only)
```

### Gate 6 Pressure Resistance

| User Says | Your Response |
|-----------|---------------|
| "Unit tests cover integration" | "Unit tests mock dependencies. Integration tests verify real behavior. Write the tests now, execute at end of cycle." |
| "Skip writing, we'll add tests later" | "Test code MUST be written per unit to stay current. Only execution is deferred." |
| "No external dependencies to test" | "Verify internal integration too. Write the tests, they'll execute at end of cycle." |
| "Just run the tests now" | "Deferred execution avoids redundant container spin-ups. Tests execute once at end of cycle." |

---

## Step 9: Gate 7 - Chaos Testing (Per Task — WRITE ONLY)

⛔ **CADENCE:** Write mode runs ONCE per task, NOT per subtask. Execute mode runs ONCE at cycle end (Step 12.1). `external_dependencies` is the UNION across all subtasks of the task.

**REQUIRED SUB-SKILL:** Use `ring:dev-chaos-testing`

**MANDATORY GATE:** All external dependencies MUST have chaos tests for failure scenarios.

**⛔ DEFERRED EXECUTION:** Per task, this gate writes/updates chaos test code and verifies compilation. Tests are NOT executed here (no Toxiproxy). Actual execution happens at end of cycle (Step 12.1).

### Step 9.1: Prepare Input for ring:dev-chaos-testing Skill

⛔ **Input scope:** TASK-level.

```text
task = state.tasks[state.current_task_index]

chaos_testing_input = {
  // REQUIRED - TASK-level
  unit_id: task.id,  // TASK id
  language: task.language,
  mode: "write_only",  // CRITICAL: write tests, verify compilation, do NOT execute

  // REQUIRED - UNION across subtasks of the task
  external_dependencies: union(task.subtasks.map(st => st.external_dependencies || []))
    || state.detected_dependencies
    || [],
  implementation_files: flatten(task.subtasks.map(st =>
    st.gate_progress.implementation.files_changed || []
  )),

  // OPTIONAL - additional context
  gate6_handoff: task.gate_progress.integration_testing  // task-level Gate 6 (write) output
}

// NOTE: external_dependencies falls back to state.detected_dependencies
// from Step 1.6 (cycle-level auto-detection) when no subtask defines them.
```

### Step 9.2: Invoke ring:dev-chaos-testing Skill (Write Mode)

```text
1. Record gate start timestamp

2. REQUIRED: Invoke ring:dev-chaos-testing skill with structured input:

   Skill("ring:dev-chaos-testing") with input:
     unit_id: chaos_testing_input.unit_id
     external_dependencies: chaos_testing_input.external_dependencies
     language: chaos_testing_input.language
     mode: "write_only"
     gate6_handoff: chaos_testing_input.gate6_handoff

   In write_only mode, the skill handles:
   - Dispatching ring:qa-analyst agent (test_mode: chaos)
   - Writing/updating chaos test code for current unit's dependencies
   - Verifying test compilation
   - Verifying dual-gate pattern (CHAOS=1 + testing.Short())
   - Verifying Toxiproxy imports present
   - NOT starting Toxiproxy or executing failure scenarios

3. Parse skill output for results:

   if compilation PASS and standards met:
     → Gate 7 (write) PASSED. Proceed to Gate 8.

   if compilation FAIL:
     → Gate 7 BLOCKED. Fix compilation errors before proceeding.

4. **MANDATORY: ⛔ Save state to file — Write tool → [state.state_path]**
```

### Step 9.3: Gate 7 (Write) Complete

```text
5. Update state:
   - gate_progress.chaos_testing.write_status = "completed"
   - gate_progress.chaos_testing.execution_status = "deferred"  // Executed at end of cycle
   - gate_progress.chaos_testing.test_files = [list of test files written/updated]
   - gate_progress.chaos_testing.compilation_passed = true

6. Proceed to Gate 8 (Review)
```

### Gate 7 Pressure Resistance

| User Says | Your Response |
|-----------|---------------|
| "Chaos testing is overkill" | "Chaos tests verify graceful degradation. Write them now, execute at end of cycle." |
| "Skip writing, add later" | "Test code MUST be written per unit. Only execution is deferred to end of cycle." |
| "Just run the chaos tests now" | "Deferred execution avoids redundant Toxiproxy spin-ups. Tests execute once at end of cycle." |
| "No time for chaos testing" | "Writing chaos tests per unit takes minutes. Execution cost is paid once at end." |

---

## Step 10: Gate 8 - Review (Per Task — after all subtasks complete Gate 0 + Gate 3 + Gate 9)

⛔ **CADENCE:** This gate runs ONCE per task, NOT per subtask. Reviewers see the CUMULATIVE diff of all subtasks in the task — cross-subtask interaction bugs (contract drift, hidden coupling, duplicated logic) are MORE visible at this cadence, not less.

**REQUIRED SUB-SKILL:** Use `ring:codereview`

### Step 10.1: Prepare Input for ring:codereview Skill

⛔ **Input scope:** TASK-level. `base_sha` is the SHA before the FIRST subtask's Gate 0 (i.e., the task's starting commit); `head_sha` is the current HEAD after all subtasks and task-level gates up to this point. The resulting diff covers ALL subtasks of the task.

```text
task = state.tasks[state.current_task_index]

review_input = {
  // REQUIRED - TASK-level
  unit_id: task.id,  // TASK id
  base_sha: task.base_sha,            // SHA before the FIRST subtask started
  head_sha: [current HEAD],           // SHA after all subtasks + task-level gates so far

  // REQUIRED - summary and requirements aggregated from task + subtasks
  implementation_summary: task.title + "\n" +
    task.subtasks.map(st => "- " + st.title + ": " + (st.summary || "")).join("\n"),
  requirements: task.acceptance_criteria
    || flatten(task.subtasks.map(st => st.acceptance_criteria || [])),

  // OPTIONAL - additional context
  implementation_files: flatten(task.subtasks.map(st =>
    st.gate_progress.implementation.files_changed || []
  )),  // UNION across subtasks
  gate0_handoffs: task.subtasks.map(st => st.gate_progress.implementation)  // ARRAY
}
```

### Step 10.2: Invoke ring:codereview Skill

```text
1. Record gate start timestamp

2. Invoke ring:codereview skill with structured input:

   Skill("ring:codereview") with input:
     unit_id: review_input.unit_id                    # TASK id
     base_sha: review_input.base_sha                  # SHA before first subtask
     head_sha: review_input.head_sha                  # Current HEAD (cumulative diff)
     implementation_summary: review_input.implementation_summary
     requirements: review_input.requirements
     implementation_files: review_input.implementation_files  # UNION across subtasks
     gate0_handoffs: review_input.gate0_handoffs      # ARRAY of subtask handoffs

   The skill handles:
   - Dispatching all 8 reviewers in PARALLEL (single message with 8 Task calls)
   - ring:code-reviewer, ring:business-logic-reviewer, ring:security-reviewer, ring:nil-safety-reviewer, ring:test-reviewer, ring:consequences-reviewer, ring:dead-code-reviewer
   - Aggregating issues by severity (CRITICAL/HIGH/MEDIUM/LOW/COSMETIC)
   - Dispatching fixes to implementation agent for blocking issues
   - Re-running all 8 reviewers after fixes
   - Iteration tracking (max 3 attempts)
   - Adding TODO/FIXME comments for non-blocking issues

3. Parse skill output for results:
   
   Expected output sections:
   - "## Review Summary" → status, iterations
   - "## Issues by Severity" → counts per severity level
   - "## Reviewer Verdicts" → all 8 reviewers
   - "## Handoff to Next Gate" → ready_for_validation: YES/NO

   if skill output contains "Status: PASS" and "Ready for Gate 9: YES":
     → Gate 8 PASSED. Proceed to Step 10.3.

   if skill output contains "Status: FAIL" or "Ready for Gate 9: NO":
     → Gate 8 BLOCKED.
     → Skill already dispatched fixes to implementation agent
      → Skill already re-ran all 8 reviewers
     → If "ESCALATION" in output: STOP and report to user

4. **MANDATORY: ⛔ Save state to file — Write tool → [state.state_path]**
```

### Step 10.3: Gate 8 Complete

```text
5. When ring:codereview skill returns PASS:

   Parse from skill output:
   - reviewers_passed: extract from "## Reviewer Verdicts" (should be "5/5")
   - issues_critical: extract count from "## Issues by Severity"
   - issues_high: extract count from "## Issues by Severity"
   - issues_medium: extract count from "## Issues by Severity"
   - iterations: extract from "Iterations:" line

   - agent_outputs.review = {
       skill: "ring:codereview",
       output: "[full skill output]",
       iterations: [count],
       timestamp: "[ISO timestamp]",
       duration_ms: [execution time],
       reviewers_passed: "5/5",
       code_reviewer: {
         verdict: "PASS",
         issues_count: N,
         issues: []  // Structured issues - see schema below
       },
       business_logic_reviewer: {
         verdict: "PASS",
         issues_count: N,
         issues: []
       },
       security_reviewer: {
         verdict: "PASS",
         issues_count: N,
         issues: []
       },
       nil_safety_reviewer: {
         verdict: "PASS",
         issues_count: N,
         issues: []
       },
       test_reviewer: {
         verdict: "PASS",
         issues_count: N,
         issues: []
       }
     }
   
   **Populate `issues[]` for each reviewer with all issues found (even if fixed):**
   ```json
   issues: [
     {
       "severity": "CRITICAL|HIGH|MEDIUM|LOW|COSMETIC",
       "category": "error-handling|security|performance|maintainability|business-logic|...",
       "description": "[detailed description of the issue]",
       "file": "internal/handler/user.go",
       "line": 45,
       "code_snippet": "return err",
       "suggestion": "Use fmt.Errorf(\"failed to create user: %w\", err)",
       "fixed": true|false,
       "fixed_in_iteration": [iteration number when fixed, null if not fixed]
     }
   ]
   ```
   
   **Issue tracking rules:**
   - all issues found across all iterations MUST be recorded
   - `fixed: true` + `fixed_in_iteration: N` for issues resolved during review
   - `fixed: false` + `fixed_in_iteration: null` for LOW/COSMETIC (TODO/FIXME added)
   - This enables feedback-loop to analyze recurring issue patterns

6. Update state:
   - gate_progress.review.status = "completed"
   - gate_progress.review.reviewers_passed = "5/5"

7. Proceed to Gate 9
```

### Gate 8 Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Only 1 MEDIUM issue, can proceed" | MEDIUM = MUST FIX. Quantity is irrelevant. | **Fix the issue, re-run all 8 reviewers** |
| "Issue is cosmetic, not really MEDIUM" | Reviewer decided severity. Accept their judgment. | **Fix the issue, re-run all 8 reviewers** |
| "Will fix in next sprint" | Deferred fixes = technical debt = production bugs. | **Fix NOW before Gate 9** |
| "User approved, can skip fix" | User approval ≠ reviewer override. Fixes are mandatory. | **Fix the issue, re-run all 8 reviewers** |
| "Same issue keeps appearing, skip it" | Recurring issue = fix is wrong. Debug properly. | **Root cause analysis, then fix** |
| "Only one reviewer found it" | One reviewer = valid finding. All findings matter. | **Fix the issue, re-run all 8 reviewers** |
| "Iteration limit reached, just proceed" | Limit = escalate, not bypass. Quality is non-negotiable. | **Escalate to user, DO NOT proceed** |
| "Tests pass, review issues don't matter" | Tests ≠ review. Different quality dimensions. | **Fix the issue, re-run all 8 reviewers** |

### Gate 8 Pressure Resistance

| User Says | Your Response |
|-----------|---------------|
| "Just skip this MEDIUM issue" | "MEDIUM severity issues are blocking by definition. I MUST dispatch a fix to the appropriate agent before proceeding. This protects code quality." |
| "I'll fix it later, let's continue" | "Gate 8 is a HARD GATE. All CRITICAL/HIGH/MEDIUM issues must be resolved NOW. I'm dispatching the fix to [agent] and will re-run all 8 reviewers after." |
| "We're running out of time" | "Proceeding with known issues creates larger problems later. The fix dispatch is automated and typically takes 2-5 minutes. Quality gates exist to save time overall." |
| "Override the gate, I approve" | "User approval cannot override reviewer findings. The gate ensures code quality. I'll dispatch the fix now." |
| "It's just a style issue" | "If it's truly cosmetic, reviewers would mark it COSMETIC (non-blocking). MEDIUM means it affects maintainability or correctness. Fixing now." |

---

## Step 11: Gate 9 - Validation (Per Execution Unit)

ℹ️ **CADENCE:** Subtask-level. Runs after Gate 3 for the current subtask (or task-itself when no subtasks). Writes to `state.tasks[i].subtasks[j].gate_progress.validation`. Task-level gates (1, 2, 4, 5, 6w, 7w, 8) only run AFTER every subtask of the task has passed Gates 0, 3, and 9.

```text
For current execution unit:

1. Record gate start timestamp
2. Verify acceptance criteria:
   For each criterion in acceptance_criteria:
     - Check if implemented
     - Check if tested
     - Mark as PASS/FAIL

3. Run final verification:
   - All tests pass?
   - No Critical/High/Medium review issues?
   - All acceptance criteria met?

4. If validation fails:
   - Log failure reasons
   - Determine which gate to revisit
   - Loop back to appropriate gate

5. If validation passes:
   - Set unit status = "completed"
   - Record gate end timestamp
   - agent_outputs.validation = {
       result: "approved",
       timestamp: "[ISO timestamp]",
       criteria_results: [{criterion, status}]
     }
   - Proceed to Step 11.1 (Execution Unit Approval)
```

## Step 11.1: Execution Unit Approval (Conditional)

**Checkpoint depends on `execution_mode`:** `manual_per_subtask` → Execute | `manual_per_task` / `automatic` → Skip

0. **COMMIT CHECK (before checkpoint):**
   - if `commit_timing == "per_subtask"`:
     - Execute `/ring:commit` command with message: `feat({unit_id}): {unit_title}`
     - Include all changed files from this subtask
   - else: Skip commit (will happen at task or cycle end)

0b. **VISUAL CHANGE REPORT (subtask-level — OPT-IN ONLY):**
   - Default: SKIP per-subtask visual report. Task-level aggregate report is generated in Step 11.2.
   - Opt-in: If `state.visual_report_granularity == "subtask"`, generate per-subtask report
     as previously documented. Default value is "task".
   - Rationale: Task-level aggregate covers all subtasks' diffs; per-subtask reports are
     rarely consumed and cost one visualize dispatch each.

1. Set `status = "paused_for_approval"`, save state
2. Present summary: Unit ID, Parent Task, Gates 0-9 status, Criteria X/X, Duration, Files Changed, Commit Status
3. **AskUserQuestion:** "Ready to proceed?" Options: (a) Continue (b) Test First (c) Stop Here
4. **Handle response:**

| Response | Action |
|----------|--------|
| Continue | Set in_progress, move to next unit (or Step 11.2 if last) |
| Test First | Set `paused_for_testing`, STOP, output resume command |
| Stop Here | Set `paused`, STOP, output resume command |

## Step 11.2: Task Approval Checkpoint (Conditional)

**Checkpoint depends on `execution_mode`:** `manual_per_subtask` / `manual_per_task` → Execute | `automatic` → Skip

0. **COMMIT CHECK (before task checkpoint):**
   - if `commit_timing == "per_task"`:
     - Execute `/ring:commit` command with message: `feat({task_id}): {task_title}`
     - Include all changed files from this task (all subtasks combined)
   - else if `commit_timing == "per_subtask"`: Already committed per subtask
   - else: Skip commit (will happen at cycle end)

0b. **VISUAL CHANGE REPORT (MANDATORY - before task checkpoint):**
   - MANDATORY: Invoke `Skill("ring:visualize")` to generate an aggregate code-diff HTML report for all subtasks in this task
   - Read `default/skills/visualize/templates/code-diff.html` to absorb the patterns before generating
   - Content aggregated from all subtask executions:
     * **Task Overview:** Task ID, title, all subtask IDs and their gate statuses
     * **Combined File Changes:** All files modified across all subtasks with before/after diff panels
     * **Aggregate Metrics:** Total tests added, total review iterations, total lines changed
   - Save to: `docs/ring:dev-cycle/reports/task-{task_id}-report.html`
   - Open in browser:
     ```text
     macOS: open docs/ring:dev-cycle/reports/task-{task_id}-report.html
     Linux: xdg-open docs/ring:dev-cycle/reports/task-{task_id}-report.html
     ```
   - Tell the user the file path
   - See [shared-patterns/anti-rationalization-visual-report.md](../shared-patterns/anti-rationalization-visual-report.md) for anti-rationalization table

1. Set task `status = "completed"`, cycle `status = "paused_for_task_approval"`, save state, and update tasks.md Status → `✅ Done` (per Step 11.2 row in State Persistence Checkpoints table)

2. Present summary: Task ID, Subtasks X/X, Total Duration, Review Iterations, Files Changed, Commit Status
3. **AskUserQuestion:** "Task complete. Ready for next?" Options: (a) Continue (b) Integration Test (c) Stop Here
4. **Handle response:**

```text
After completing all subtasks of a task:

0. Check execution_mode from state:
   - If "automatic": Still run feedback, then skip to next task
   - If "manual_per_subtask" or "manual_per_task": Continue with checkpoint below

1. Set task status = "completed"

2. **Accumulate task metrics into state (NO dev-report dispatch here):**

   Write into `state.tasks[current_task_index].accumulated_metrics`:
   - `gate_durations_ms`: {gate_name: duration_ms for each completed gate}
   - `review_iterations`: `state.tasks[current].gate_progress.review.iterations`
   - `testing_iterations`: sum across all testing gates (unit, fuzz, property, integration, chaos)
   - `issues_by_severity`: {CRITICAL, HIGH, MEDIUM, LOW counts from Gate 8 output}

   Set `state.tasks[current].feedback_loop_completed = true`
   (Actual dev-report dispatch happens ONCE at cycle end in Step 12.1.)

   MANDATORY: Save state to file.

   Rationale: Feedback analysis is stronger on aggregate data. A single cycle-end
   dev-report run produces the same or better insights than N per-task runs.

   | Rationalization | Why It's WRONG | Required Action |
   |-----------------|----------------|-----------------|
   | "Should dispatch dev-report now" | dev-report runs ONCE at cycle end (Step 12.1). Per-task metrics are accumulated into state, not analyzed here. | **Accumulate metrics into state, proceed to next task** |

3. Set cycle status = "paused_for_task_approval"
4. Save state

5. Present task completion summary (with feedback metrics):
   ┌─────────────────────────────────────────────────┐
   │ ✓ TASK COMPLETED                                │
   ├─────────────────────────────────────────────────┤
   │ Task: [task_id] - [task_title]                  │
   │                                                  │
   │ Subtasks Completed: X/X                         │
   │   ✓ ST-001-01: [title]                          │
   │   ✓ ST-001-02: [title]                          │
   │   ✓ ST-001-03: [title]                          │
   │                                                  │
   │ Total Duration: Xh Xm                           │
   │ Total Review Iterations: N                      │
   │                                                  │
   │ ═══════════════════════════════════════════════ │
   │ FEEDBACK METRICS                                │
   │ ═══════════════════════════════════════════════ │
   │                                                  │
   │ Assertiveness Score: XX% (Rating)               │
   │                                                  │
   │ Prompt Quality by Agent:                        │
   │   ring:backend-engineer-golang: 90% (Excellent)     │
   │   ring:qa-analyst: 75% (Acceptable)                 │
   │   ring:code-reviewer: 88% (Good)               │
   │                                                  │
   │ Improvements Suggested: N                       │
   │ Feedback Location:                              │
   │   docs/feedbacks/cycle-YYYY-MM-DD/             │
   │                                                  │
   │ ═══════════════════════════════════════════════ │
   │                                                  │
   │ All Files Changed This Task:                    │
   │   - file1.go                                    │
   │   - file2.go                                    │
   │   - ...                                         │
   │                                                  │
   │ Next Task: [next_task_id] - [next_task_title]   │
   │            Subtasks: N (or "TDD autonomous")    │
   │            or "No more tasks - cycle complete"  │
   └─────────────────────────────────────────────────┘

6. **ASK FOR EXPLICIT APPROVAL using AskUserQuestion tool:**

   Question: "Task [task_id] complete. Ready to start the next task?"
   Options:
     a) "Continue" - Proceed to next task
     b) "Integration Test" - User wants to test the full task integration
     c) "Stop Here" - Pause cycle

7. Handle user response:

   If "Continue":
     - Set status = "in_progress"
     - Move to next task
     - Set current_task_index += 1
     - Set current_subtask_index = 0
     - Reset to Gate 0
     - Continue execution

   If "Integration Test":
     - Set status = "paused_for_integration_testing"
     - Save state
     - Output: "Cycle paused for integration testing.
                Test task [task_id] integration and run:
                /ring:dev-cycle --resume
                when ready to continue."
     - STOP execution

   If "Stop Here":
     - Set status = "paused"
     - Save state
     - Output: "Cycle paused after task [task_id]. Resume with:
                /ring:dev-cycle --resume"
     - STOP execution
```

**Note:** Tasks without subtasks execute both 7.1 and 7.2 in sequence.

## Step 12: Cycle Completion

### Step 12.0: Deferred Test Execution (Gates 6-7)

**⛔ MANDATORY: Execute integration and chaos tests before final commit.**

All units have written/updated test code during their Gate 6-7 passes. Now execute all tests once.

```text
1. Record deferred execution start timestamp

2. REQUIRED: Invoke ring:dev-integration-testing skill in EXECUTE mode:

   Skill("ring:dev-integration-testing") with input:
     mode: "execute"
     all_test_files: [aggregate gate_progress.integration_testing.test_files from all units]
     language: state.language

   The skill handles:
   - Spinning up testcontainers for all external dependencies
   - Running ALL integration tests across all units
   - Reporting pass/fail per test file
   - If failures: dispatching fixes and re-running (max 3 iterations)

3. REQUIRED: Invoke ring:dev-chaos-testing skill in EXECUTE mode:

   Skill("ring:dev-chaos-testing") with input:
     mode: "execute"
     all_test_files: [aggregate gate_progress.chaos_testing.test_files from all units]
     language: state.language

   The skill handles:
   - Starting Toxiproxy
   - Running ALL chaos tests across all units
   - Verifying recovery for all failure scenarios
   - If failures: dispatching fixes and re-running (max 3 iterations)

4. Update state:
   - gate_progress.integration_testing.execution_status = "completed" (or "failed")
   - gate_progress.chaos_testing.execution_status = "completed" (or "failed")

5. if any test FAILS after 3 iterations:
   → HARD BLOCK. Cannot complete cycle.
   → Report failures to user.

6. **MANDATORY: ⛔ Save state to file — Write tool → [state.state_path]**
```

### Step 12.0 Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "All unit/fuzz/property tests passed, skip integration" | Different test types catch different bugs. All are MANDATORY. | **Execute deferred tests** |
| "Tests were written, that's enough" | Written ≠ passing. Execution verifies real behavior. | **Execute deferred tests** |
| "Containers are slow, let CI handle it" | CI is backup, not replacement. Verify locally first. | **Execute deferred tests** |
| "One test failed but it's flaky" | Flaky = unreliable = fix it. No exceptions. | **Fix and re-run** |

### Step 12.0.5: Multi-Tenant Verification (Post-Cycle — Verification Only)

**Multi-tenant dual-mode is now implemented during Gate 0 and verified at Gate 0.5G.** This post-cycle step is a final sanity check only — it does NOT implement or adapt any code.

```text
1. Verify Gate 0.5G passed for ALL units:
   for each task in state.tasks:
     for each unit in task.units:
       if unit.gate_progress.delivery_verification.mt_dualmode != "PASS":
         → HARD BLOCK: "Unit [unit_id] failed MT dual-mode verification at Gate 0.5G"
         → This should never happen (Gate 0.5G blocks progression)

2. Display to user:
   ┌─────────────────────────────────────────────────┐
   │ ✓ MULTI-TENANT DUAL-MODE VERIFIED              │
   ├─────────────────────────────────────────────────┤
   │ Mode: Dual-mode (implemented at Gate 0)         │
   │ Verification: Gate 0.5G PASS for all units      │
   │ Resources Covered: [PG/Mongo/Redis/RMQ/S3]      │
   │ Backward Compat: Resolvers handle single-tenant │
   └─────────────────────────────────────────────────┘

3. MANDATORY: ⛔ Save state to file — Write tool → [state.state_path]
```

**Note:** The full ring:dev-multi-tenant skill (12 gates) is now used ONLY for migrating legacy codebases that were written before dual-mode was standard. For new development via dev-cycle, all multi-tenant compliance is handled by Gate 0 (implementation) + Gate 0.5G (verification).

---

### Step 12.1: Final Commit

0. **FINAL COMMIT CHECK (before completion):**
   - if `commit_timing == "at_end"`:
     - Execute `/ring:commit` command with message: `feat({cycle_id}): complete dev cycle for {feature_name}`
     - Include all changed files from the entire cycle
   - else: Already committed per subtask or per task

1. **Calculate metrics:** total_duration_ms, average gate durations, review iterations, pass/fail ratio
2. **Update state:** `status = "completed"`, `completed_at = timestamp`
3. **Generate report:** Task | Subtasks | Duration | Review Iterations | Status | Commit Status

4. **⛔ MANDATORY: Run ring:dev-report skill for cycle metrics**

   **IMPORTANT:** This is the ONE AND ONLY ring:dev-report dispatch in the cycle. ring:dev-report reads `accumulated_metrics` from ALL tasks in state and generates aggregate analysis.

   ```yaml
   Skill tool:
     skill: "ring:dev-report"
   ```

   **Note:** ring:dev-report manages its own TodoWrite tracking internally.

   **After feedback-loop completes, update state:**
   - Set `feedback_loop_completed = true` at cycle level in state file

   **⛔ HARD GATE: Cycle incomplete until feedback-loop executes.**

   | Rationalization | Why It's WRONG | Required Action |
   |-----------------|----------------|-----------------|
   | "Cycle done, feedback is extra" | Feedback IS part of cycle completion | **Execute Skill tool** |
   | "Will run feedback next session" | Next session = never. Run NOW. | **Execute Skill tool** |
   | "All tasks passed, no insights" | Pass patterns need documentation too | **Execute Skill tool** |

5. **Report:** "Cycle completed. Tasks X/X, Subtasks Y, Time Xh Xm, Review iterations X"

## Quick Commands

```bash
# Full PM workflow then dev execution
/ring:pre-dev-full my-feature
/ring:dev-cycle docs/pre-dev/my-feature/

# Simple PM workflow then dev execution
/ring:pre-dev-feature my-feature
/ring:dev-cycle docs/pre-dev/my-feature/tasks.md

# Manual task file
/ring:dev-cycle docs/tasks/sprint-001.md

# Resume interrupted cycle
/ring:dev-cycle --resume
```

## Error Recovery

| Type | Condition | Action |
|------|-----------|--------|
| **Recoverable** | Network timeout | Retry with exponential backoff |
| **Recoverable** | Agent failure | Retry once, then pause for user |
| **Recoverable** | Test flakiness | Re-run tests up to 2 times |
| **Non-Recoverable** | Missing required files | Stop and report |
| **Non-Recoverable** | Invalid state file | Must restart (cannot resume) |
| **Non-Recoverable** | Max review iterations | Pause for user |

**On any error:** Update state → Set status (failed/paused) → Save immediately → Report (what failed, why, how to recover, resume command)

## Execution Report

Base metrics per [shared-patterns/output-execution-report.md](../shared-patterns/output-execution-report.md).

| Metric | Value |
|--------|-------|
| Duration | Xh Xm Ys |
| Tasks Processed | N/M |
| Current Gate | Gate X - [name] |
| Review Iterations | N |
| Result | PASS/FAIL/IN_PROGRESS |

### Gate Timings
| Gate | Duration | Status |
|------|----------|--------|
| Implementation | Xm Ys | in_progress |
| DevOps | - | pending |
| SRE | - | pending |
| Testing | - | pending |
| Review | - | pending |
| Validation | - | pending |

### State File Location
`docs/ring:dev-cycle/current-cycle.json` (feature) or `docs/ring:dev-refactor/current-cycle.json` (refactor)

---

## Frontend Handoff

When the backend dev cycle completes, it produces a handoff file for the frontend dev cycle (`ring:dev-cycle-frontend`). This enables the frontend cycle to verify E2E tests exercise the correct API endpoints and use the right type contracts.

### Handoff File

**Path:** `docs/ring:dev-cycle/handoff-frontend.json`

**Generated:** Automatically after Gate 9 (Validation) passes for all tasks.

### Handoff Schema

```json
{
  "cycle_id": "string",
  "generated_at": "ISO-8601",
  "endpoints": [
    {
      "method": "GET|POST|PUT|PATCH|DELETE",
      "path": "/api/v1/resource",
      "request_schema": "object or null",
      "response_schema": "object",
      "status_codes": [200, 400, 404, 500],
      "auth_required": true
    }
  ],
  "types_exported": [
    {
      "name": "ResourceDTO",
      "file": "src/types/resource.ts",
      "fields": ["id", "name", "createdAt"]
    }
  ],
  "contracts": [
    {
      "consumer": "frontend",
      "provider": "backend",
      "endpoint": "/api/v1/resource",
      "format": "JSON"
    }
  ]
}
```

### How Frontend Cycle Uses the Handoff

| Frontend Gate | Handoff Usage |
|---------------|---------------|
| Gate 0 (Implementation) | Import types from `types_exported`, call `endpoints` |
| Gate 5 (E2E Testing) | Verify all `endpoints` are exercised in E2E tests |
| Gate 6 (Performance) | Measure response times against `endpoints` |

### When No Handoff Exists

If `docs/ring:dev-cycle/handoff-frontend.json` does not exist, the frontend cycle proceeds without it. The frontend engineer defines API contracts inline based on `PROJECT_RULES.md` or user input. This is common for greenfield frontend-only projects.
