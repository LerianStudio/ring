---
name: dev-cycle
description: |
  Main orchestrator for the 6-gate development cycle system. Loads tasks/subtasks
  from PM team output and executes through implementation, devops, SRE, testing, review,
  and validation gates with state persistence and metrics collection.

trigger: |
  - Starting a new development cycle with a task file
  - Resuming an interrupted development cycle (--resume flag)
  - Need structured, gate-based task execution with quality checkpoints

skip_when: |
  - Already in a specific gate skill -> let that gate complete
  - Need to plan tasks first -> use writing-plans or pre-dev-full
  - Human explicitly requests manual implementation (non-AI workflow)

NOT_skip_when: |
  - "Task is simple" → Simple ≠ risk-free. Execute gates.
  - "Tests already pass" → Tests ≠ review. Different concerns.
  - "Time pressure" → Pressure ≠ permission. Document and proceed.
  - "Already did N gates" → Sunk cost is irrelevant. Complete all gates.

sequence:
  before: [dev-feedback-loop]

related:
  complementary: [dev-implementation, dev-devops, dev-sre, dev-testing, dev-review, dev-validation, dev-feedback-loop]

verification:
  automated:
    - command: "test -f docs/refactor/current-cycle.json"
      description: "State file exists"
      success_pattern: "exit 0"
    - command: "cat docs/refactor/current-cycle.json | jq '.current_gate'"
      description: "Current gate is valid"
      success_pattern: "[0-5]"
  manual:
    - "All gates for current task show PASS in state file"
    - "No tasks have status 'blocked' for more than 3 iterations"

examples:
  - name: "New feature from PM workflow"
    invocation: "/dev-cycle docs/pre-dev/auth/tasks.md"
    expected_flow: |
      1. Load tasks with subtasks from tasks.md
      2. Ask user for checkpoint mode (per-task/per-gate/continuous)
      3. Execute Gate 0-5 for each task sequentially
      4. Generate feedback report after completion
  - name: "Resume interrupted cycle"
    invocation: "/dev-cycle --resume"
    expected_state: "Continues from last saved gate in current-cycle.json"
  - name: "Execute with per-gate checkpoints"
    invocation: "/dev-cycle tasks.md --checkpoint per-gate"
    expected_flow: |
      1. Execute Gate 0, pause for approval
      2. User approves, execute Gate 1, pause
      3. Continue until all gates complete
---

# Development Cycle Orchestrator

## Standards Loading (MANDATORY)

**Before ANY gate execution, you MUST load Ring standards:**

See [CLAUDE.md](https://raw.githubusercontent.com/LerianStudio/ring/main/CLAUDE.md) as the canonical source. This table summarizes the loading process.

| Parameter | Value |
|-----------|-------|
| url | \`https://raw.githubusercontent.com/LerianStudio/ring/main/CLAUDE.md\` |
| prompt | "Extract Agent Modification Verification requirements, Anti-Rationalization Tables requirements, and Critical Rules" |

**Execute WebFetch before proceeding.** Do NOT continue until standards are loaded.

If WebFetch fails → STOP and report blocker. Cannot proceed without Ring standards.

## Overview

The development cycle orchestrator loads tasks/subtasks from PM team output (or manual task files) and executes through 6 quality gates. Tasks are loaded at initialization - no separate import gate.

**Announce at start:** "I'm using the dev-cycle skill to orchestrate task execution through 6 gates."

## ⛔ CRITICAL: Specialized Agents Perform All Tasks

See [shared-patterns/shared-orchestrator-principle.md](../shared-patterns/shared-orchestrator-principle.md) for full ORCHESTRATOR principle, role separation, forbidden/required actions, gate-to-agent mapping, and anti-rationalization table.

**Summary:** You orchestrate. Agents execute. If using Read/Write/Edit/Bash on source code → STOP. Dispatch agent.

## Blocker Criteria - STOP and Report

| Decision Type | Examples | Action |
|---------------|----------|--------|
| **Gate Failure** | Tests not passing, review failed | STOP. Cannot proceed to next gate. |
| **Missing Standards** | No PROJECT_RULES.md | STOP. Report blocker and wait. |
| **Agent Failure** | Specialist agent returned errors | STOP. Diagnose and report. |
| **User Decision Required** | Architecture choice, framework selection | STOP. Present options with trade-offs. |

You CANNOT proceed when blocked. Report and wait for resolution.

### Cannot Be Overridden

| Requirement | Rationale | Consequence If Skipped |
|-------------|-----------|------------------------|
| **All 6 gates must execute** | Each gate catches different issues | Missing critical defects, security vulnerabilities |
| **Gates execute in order (0→5)** | Dependencies exist between gates | Testing untested code, reviewing unobservable systems |
| **Gate 4 requires ALL 3 reviewers** | Different review perspectives are complementary | Missing security issues, business logic flaws |
| **Coverage threshold ≥ 85%** | Industry standard for quality code | Untested edge cases, regression risks |
| **PROJECT_RULES.md must exist** | Cannot verify standards without target | Arbitrary decisions, inconsistent implementations |

## Severity Calibration

| Severity | Criteria | Examples |
|----------|----------|----------|
| **CRITICAL** | Blocks deployment, security risk, data loss | Gate violation, skipped mandatory step |
| **HIGH** | Major functionality broken, standards violation | Missing tests, wrong agent dispatched |
| **MEDIUM** | Code quality, maintainability issues | Incomplete documentation, minor gaps |
| **LOW** | Best practices, optimization | Style improvements, minor refactoring |

Report ALL severities. Let user prioritize.

### Reviewer Verdicts Are Final

**MEDIUM issues found in Gate 4 MUST be fixed. No exceptions.**

| Request | Why It's WRONG | Required Action |
|---------|----------------|-----------------|
| "Can reviewer clarify if MEDIUM can defer?" | Reviewer already decided. MEDIUM means FIX. | **Fix the issue, re-run reviewers** |
| "Ask if this specific case is different" | Reviewer verdict accounts for context already. | **Fix the issue, re-run reviewers** |
| "Request exception for business reasons" | Reviewers know business context. Verdict is final. | **Fix the issue, re-run reviewers** |

**Severity mapping is absolute:**
- CRITICAL/HIGH/MEDIUM → Fix NOW, re-run all 3 reviewers
- LOW → Add TODO(review): comment
- Cosmetic → Add FIXME(nitpick): comment

No negotiation. No exceptions. No "special cases".

## Pressure Resistance

See [shared-patterns/shared-pressure-resistance.md](../shared-patterns/shared-pressure-resistance.md) for universal pressure scenarios.

**Gate-specific note:** Execution mode selection affects CHECKPOINTS (user approval pauses), not GATES (quality checks). ALL gates execute regardless of mode.

## Common Rationalizations - REJECTED

See [shared-patterns/shared-anti-rationalization.md](../shared-patterns/shared-anti-rationalization.md) for universal anti-rationalizations.

**Gate-specific rationalizations:**

| Excuse | Reality |
|--------|---------|
| "Automatic mode means faster" | Automatic mode skips CHECKPOINTS, not GATES. Same quality, less interruption. |
| "Automatic mode will skip review" | Automatic mode affects user approval pauses, NOT quality gates. ALL gates execute regardless. |
| "Defense in depth exists (frontend validates)" | Frontend can be bypassed. Backend is the last line. Fix at source. |
| "Backlog the Medium issue, it's documented" | Documented risk ≠ mitigated risk. Medium in Gate 4 = fix NOW, not later. |
| "Risk-based prioritization allows deferral" | Gates ARE the risk-based system. Reviewers define severity, not you. |

## Red Flags - STOP

See [shared-patterns/shared-red-flags.md](../shared-patterns/shared-red-flags.md) for universal red flags.

If you catch yourself thinking ANY of those patterns, STOP immediately and return to gate execution.

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

## Gate Completion Definition (HARD GATE)

**A gate is COMPLETE only when ALL components finish successfully:**

| Gate | Components Required | Partial = FAIL |
|------|---------------------|----------------|
| 0.1 | TDD-RED: Failing test written + failure output captured | Test exists but no failure output = FAIL |
| 0.2 | TDD-GREEN: Implementation passes test | Code exists but test fails = FAIL |
| 0 | Both 0.1 and 0.2 complete | 0.1 done without 0.2 = FAIL |
| 1 | Dockerfile + docker-compose + .env.example | Missing any = FAIL |
| 2 | Structured JSON logs with trace correlation | Partial structured logs = FAIL |
| 3 | Coverage ≥ 85% + all AC tested | 84% = FAIL |
| 4 | **ALL 3 reviewers PASS** | 2/3 reviewers = FAIL |
| 5 | Explicit "APPROVED" from user | "Looks good" = NOT approved |

**CRITICAL for Gate 4:** Running 2 of 3 reviewers is NOT a partial pass - it's a FAIL. Re-run ALL 3 reviewers.

**Anti-Rationalization for Partial Gates:**

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "2 of 3 reviewers passed" | Gate 4 requires ALL 3. 2/3 = 0/3. | **Re-run ALL 3 reviewers** |
| "Gate mostly complete" | Mostly ≠ complete. Binary: done or not done. | **Complete ALL components** |
| "Can finish remaining in next cycle" | Gates don't carry over. Complete NOW. | **Finish current gate** |
| "Core components done, optional can wait" | No component is optional within a gate. | **Complete ALL components** |

## Gate Order Enforcement (HARD GATE)

**Gates MUST execute in order: 0 → 1 → 2 → 3 → 4 → 5. No exceptions.**

| Violation | Why It's WRONG | Consequence |
|-----------|----------------|-------------|
| Skip Gate 1 (DevOps) | "No infra changes" | Code without container = works on my machine only |
| Skip Gate 2 (SRE) | "Observability later" | Blind production = debugging nightmare |
| Reorder Gates | "Review before test" | Reviewing untested code wastes reviewer time |
| Parallel Gates | "Run 2 and 3 together" | Dependencies exist. Order is intentional. |

**Gates are NOT parallelizable across different gates. Sequential execution is MANDATORY.**

## The 6 Gates

| Gate | Skill | Purpose | Agent |
|------|-------|---------|-------|
| 0 | dev-implementation | Write code following TDD | Based on task language/domain |
| 1 | dev-devops | Infrastructure and deployment | devops-engineer |
| 2 | dev-sre | Observability (health, logging, tracing) | sre |
| 3 | dev-testing | Unit tests for acceptance criteria | qa-analyst |
| 4 | dev-review | Parallel code review | code-reviewer, business-logic-reviewer, security-reviewer (3x parallel) |
| 5 | dev-validation | Final acceptance validation | N/A (verification) |

## Integrated PM → Dev Workflow

**PM Team Output** → **Dev Team Execution** (`/dev-cycle`)

| Input Type | Path | Structure |
|------------|------|-----------|
| **Tasks only** | `docs/pre-dev/{feature}/tasks.md` | T-001, T-002, T-003 with requirements + acceptance criteria |
| **Tasks + Subtasks** | `docs/pre-dev/{feature}/` | tasks.md + `subtasks/{task-id}/ST-XXX-01.md, ST-XXX-02.md...` |

## Execution Order

**Core Principle:** Each execution unit (task OR subtask) passes through **all 6 gates** before the next unit.

**Flow:** Unit → Gate 0-5 → 🔒 Unit Checkpoint (Step 7.1) → 🔒 Task Checkpoint (Step 7.2) → Next Unit

| Scenario | Execution Unit | Gates Per Unit |
|----------|----------------|----------------|
| Task without subtasks | Task itself | 6 gates |
| Task with subtasks | Each subtask | 6 gates per subtask |

## State Management

State is persisted to `docs/refactor/current-cycle.json`:

```json
{
  "version": "1.0.0",
  "cycle_id": "uuid",
  "started_at": "ISO timestamp",
  "updated_at": "ISO timestamp",
  "source_file": "path/to/tasks.md",
  "execution_mode": "manual_per_subtask|manual_per_task|automatic",
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
      "subtasks": [
        {
          "id": "ST-001-01",
          "file": "subtasks/T-001/ST-001-01.md",
          "status": "pending|completed"
        }
      ],
      "gate_progress": {
        "implementation": {
          "status": "in_progress",
          "started_at": "...",
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
          }
        },
        "devops": {"status": "pending"},
        "sre": {"status": "pending"},
        "testing": {"status": "pending"},
        "review": {"status": "pending"},
        "validation": {"status": "pending"}
      },
      "artifacts": {},
      "agent_outputs": {
        "implementation": {
          "agent": "backend-engineer-golang",
          "output": "## Summary\n...",
          "timestamp": "ISO timestamp",
          "duration_ms": 0
        },
        "devops": null,
        "sre": {
          "agent": "sre",
          "output": "## Summary\n...",
          "timestamp": "ISO timestamp",
          "duration_ms": 0
        },
        "testing": {
          "agent": "qa-analyst",
          "output": "## Summary\n...",
          "verdict": "PASS",
          "coverage_actual": 87.5,
          "coverage_threshold": 85,
          "iteration": 1,
          "timestamp": "ISO timestamp",
          "duration_ms": 0
        },
        "review": {
          "code_reviewer": {"agent": "code-reviewer", "output": "...", "timestamp": "..."},
          "business_logic_reviewer": {"agent": "business-logic-reviewer", "output": "...", "timestamp": "..."},
          "security_reviewer": {"agent": "security-reviewer", "output": "...", "timestamp": "..."}
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

## ⛔ State Persistence Rule (MANDATORY)

**"Update state" means BOTH update the object AND write to file. Not just in-memory.**

### After EVERY Gate Transition

You MUST execute these steps after completing ANY gate (0, 1, 2, 3, 4, or 5):

```yaml
# Step 1: Update state object with gate results
state.tasks[current_task_index].gate_progress.[gate_name].status = "completed"
state.tasks[current_task_index].gate_progress.[gate_name].completed_at = "[ISO timestamp]"
state.current_gate = [next_gate_number]
state.updated_at = "[ISO timestamp]"

# Step 2: Write to file (MANDATORY - use Write tool)
Write tool:
  file_path: "docs/refactor/current-cycle.json"
  content: [full JSON state]

# Step 3: Verify persistence (MANDATORY - use Read tool)
Read tool:
  file_path: "docs/refactor/current-cycle.json"
# Confirm current_gate and gate_progress match expected values
```

### State Persistence Checkpoints

| After | MUST Update | MUST Write File |
|-------|-------------|-----------------|
| Gate 0.1 (TDD-RED) | `tdd_red.status`, `tdd_red.failure_output` | ✅ YES |
| Gate 0.2 (TDD-GREEN) | `tdd_green.status`, `implementation.status` | ✅ YES |
| Gate 1 (DevOps) | `devops.status`, `agent_outputs.devops` | ✅ YES |
| Gate 2 (SRE) | `sre.status`, `agent_outputs.sre` | ✅ YES |
| Gate 3 (Testing) | `testing.status`, `agent_outputs.testing` | ✅ YES |
| Gate 4 (Review) | `review.status`, `agent_outputs.review` | ✅ YES |
| Gate 5 (Validation) | `validation.status`, task `status` | ✅ YES |
| Step 7.1 (Unit Approval) | `status = "paused_for_approval"` | ✅ YES |
| Step 7.2 (Task Approval) | `status = "paused_for_task_approval"` | ✅ YES |

### Anti-Rationalization for State Persistence

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "I'll save state at the end" | Crash/timeout loses ALL progress | **Save after EACH gate** |
| "State is in memory, that's updated" | Memory is volatile. File is persistent. | **Write to JSON file** |
| "Only save on checkpoints" | Gates without saves = unrecoverable on resume | **Save after EVERY gate** |
| "Write tool is slow" | Write takes <100ms. Lost progress takes hours. | **Write after EVERY gate** |
| "I updated the state variable" | Variable ≠ file. Without Write tool, nothing persists. | **Use Write tool explicitly** |

### Verification Command

After each gate, the state file MUST reflect:
- `current_gate` = next gate number
- `updated_at` = recent timestamp
- Previous gate `status` = "completed"

**If verification fails → State was not persisted. Re-execute Write tool.**

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
│  └── NO → ASK: "Is this a LEGACY project (created without PM workflow)?"   │
│       │                                                                     │
│       ├── YES (legacy project) → LEGACY PROJECT ANALYSIS:                   │
│       │   Step 1: Dispatch codebase-explorer (technical info only)          │
│       │   Step 2: Ask 3 questions (what agent can't determine):             │
│       │     1. What do you need help with?                                  │
│       │     2. Any external APIs not visible in code?                       │
│       │     3. Any specific technology not in Ring Standards?               │
│       │   Step 3: Generate PROJECT_RULES.md (deduplicated from Ring)        │
│       │   Note: Business rules belong in PRD, NOT in PROJECT_RULES          │
│       │   → Proceed to Step 1                                               │
│       │                                                                     │
│       └── NO (new project) → ASK: "Do you have PRD, TRD, or Feature Map?"  │
│           │                                                                 │
│           ├── YES (has PM docs) → "Please provide the file path(s)"        │
│           │   → Read PRD/TRD/Feature Map → Extract info                    │
│           │   → Generate PROJECT_RULES.md                                  │
│           │   → Ask supplementary questions if info is incomplete          │
│           │   → Save and proceed to Step 1                                 │
│           │                                                                 │
│           └── NO (no PM docs) → ⛔ HARD BLOCK:                              │
│               "PM documents are REQUIRED for new projects.                  │
│                Run /pre-dev-full or /pre-dev-feature first."               │
│               → STOP (cycle cannot proceed)                                 │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Step 0.1: Check for PROJECT_RULES.md

```yaml
# Check if file exists
Read tool:
  file_path: "docs/PROJECT_RULES.md"

# If file exists and has content → Proceed to Step 1
# If file does not exist OR is empty → Continue to Step 0.2
```

### Step 0.2: Check if Legacy Project

#### Ask the User

Use AskUserQuestion:

```text
┌─────────────────────────────────────────────────────────────────┐
│ 📋 PROJECT_RULES.md NOT FOUND                                   │
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

#### If NO (new project)

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
│ Step 1: Automated analysis (codebase-explorer)                  │
│ Step 2: Ask for project-specific tech not in Ring Standards     │
│ Step 3: Generate PROJECT_RULES.md (deduplicated)                │
│                                                                 │
│ Note: Business rules belong in PRD/product docs, NOT here.      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### Step 0.2.1a: Automated Codebase Analysis (MANDATORY)

**⛔ You MUST use the Task tool to dispatch codebase-explorer. This is NOT implicit.**

#### Dispatch Agent

Dispatch codebase-explorer to analyze the legacy project for TECHNICAL information:

```text
Action: Use Task tool with EXACTLY these parameters:

┌─────────────────────────────────────────────────────────────────────────────────┐
│  ⛔ If Task tool NOT used → Analysis does NOT happen → PROJECT_RULES.md INVALID │
└─────────────────────────────────────────────────────────────────────────────────┘
```

```yaml
# Agent 1: Codebase Explorer - Technical Analysis
Task tool:
  subagent_type: "codebase-explorer"
  model: "opus"
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

**Note:** Business logic analysis is NOT needed for PROJECT_RULES.md. Business rules belong in PRD/product docs, not technical project rules.

#### Verification (MANDATORY)

After agent completes, confirm:
- [ ] `codebase-explorer` returned "## Technical Analysis (Legacy Project)" section
- [ ] Output contains non-empty content for: Tech Stack, External Integrations, Configuration

**If agent failed or returned empty output → Re-dispatch. Cannot proceed without technical analysis.**

#### Step 0.2.1b: Supplementary Questions (Only What Agents Can't Determine)

#### Post-Analysis Questions

After agents complete, ask ONLY what they couldn't determine from code:

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

**Note:** Business rules belong in PRD/product docs, NOT in PROJECT_RULES.md.

#### Step 0.2.1c: Generate PROJECT_RULES.md

#### Combine Agent Outputs and User Answers

```yaml
Create tool:
  file_path: "docs/PROJECT_RULES.md"
  content: |
    # Project Rules
    
    > Ring Standards apply automatically. This file documents ONLY what Ring does NOT cover.
    > For error handling, logging, testing, architecture, lib-commons → See Ring Standards (auto-loaded by agents)
    > Generated from legacy project analysis.
    
    ## What Ring Standards Already Cover (DO NOT ADD HERE)
    
    The following are defined in Ring Standards and MUST NOT be duplicated:
    - Error handling patterns (no panic, wrap errors)
    - Logging standards (structured JSON, zerolog/zap)
    - Testing patterns (table-driven tests, mocks)
    - Architecture patterns (Hexagonal, Clean Architecture)
    - Observability (OpenTelemetry, trace correlation)
    - lib-commons usage and patterns
    - API directory structure
    
    ---
    
    ## Tech Stack (Not in Ring Standards)
    
    [From codebase-explorer: Technologies NOT covered by Ring Standards]
    [e.g., specific message broker, specific cache, DB if not PostgreSQL]
    
    | Technology | Purpose | Notes |
    |------------|---------|-------|
    | [detected] | [purpose] | [notes] |
    
    ## Non-Standard Directory Structure
    
    [From codebase-explorer: Directories that deviate from Ring's standard API structure]
    [e.g., workers/, consumers/, polling/]
    
    | Directory | Purpose | Pattern |
    |-----------|---------|---------|
    | [detected] | [purpose] | [pattern] |
    
    ## External Integrations
    
    [From codebase-explorer: Third-party services specific to this project]
    
    | Service | Purpose | Docs |
    |---------|---------|------|
    | [detected] | [purpose] | [link] |
    
    ## Environment Configuration
    
    [From codebase-explorer: Project-specific env vars NOT covered by Ring]
    
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
    *Source: Legacy project analysis (codebase-explorer)*
    *Ring Standards Version: [version from WebFetch]*
```

#### Present to User

```text
┌─────────────────────────────────────────────────────────────────┐
│ ✓ PROJECT_RULES.md Generated for Legacy Project                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ I analyzed your codebase using:                                 │
│   • codebase-explorer (technical patterns, stack, structure)    │
│                                                                 │
│ Combined with your input on:                                    │
│   • Current development goal                                    │
│   • External integrations                                       │
│   • Project-specific technology                                 │
│                                                                 │
│ Generated: docs/PROJECT_RULES.md                                │
│                                                                 │
│ Note: Ring Standards (error handling, logging, testing, etc.)   │
│ are NOT duplicated - agents load them automatically via WebFetch│
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
│   • Feature Map (from pre-dev-feature-map skill)                │
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

- `/pre-dev-full` output: `docs/pre-dev/{feature}/prd.md`, `trd.md`, `feature-map.md`
- `/pre-dev-feature` output: `docs/pre-dev/{feature}/prd.md`, `feature-map.md`
- Custom locations: User may have docs in different paths (e.g., `requirements/`, `specs/`)

#### Then

Go to Step 0.3.1 (Generate from PM Documents)

#### If NO

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

**⛔ DEDUPLICATION RULE:** Extract ONLY what Ring Standards do NOT cover.

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
    
    > ⛔ IMPORTANT: Ring Standards are NOT automatic. Agents MUST WebFetch them before implementation.
    > This file documents ONLY project-specific information not covered by Ring Standards.
    > Generated from PM documents (PRD/TRD/Feature Map).
    >
    > Ring Standards URLs:
    > - Go: https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang.md
    > - TypeScript: https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/typescript.md
    
    ## What Ring Standards Cover (DO NOT DUPLICATE HERE)
    
    The following are defined in Ring Standards and MUST NOT be duplicated in this file:
    - Error handling patterns (no panic, wrap errors)
    - Logging standards (structured JSON via lib-commons)
    - Testing patterns (table-driven tests, mocks)
    - Architecture patterns (Hexagonal, Clean Architecture)
    - Observability (OpenTelemetry via lib-commons)
    - lib-commons / lib-common-js usage and patterns
    - API directory structure (Midaz pattern)
    - Database connections (PostgreSQL, MongoDB, Redis via lib-commons)
    - Bootstrap pattern (config.go, service.go, server.go)
    
    **Agents MUST WebFetch Ring Standards and output Standards Coverage Table.**
    
    ---
    
    ## Tech Stack (Not in Ring Standards)
    
    [From TRD/Feature Map: ONLY technologies NOT covered by Ring Standards]
    
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
    
    [From TRD: Project-specific env vars NOT covered by Ring]
    
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

**Note:** Do NOT ask about architecture, error handling, logging, testing - Ring Standards covers these.

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
│   /pre-dev-full     → For features ≥2 days (9 gates)           │
│   /pre-dev-feature  → For features <2 days (4 gates)           │
│                                                                 │
│ These commands will guide you through creating:                 │
│   • PRD (Product Requirements Document)                         │
│   • TRD (Technical Requirements Document)                       │
│   • Feature Map (technology choices, feature relationships)     │
│                                                                 │
│ After completing pre-dev workflow, run /dev-cycle again.        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### Action

STOP EXECUTION. Do NOT proceed to Step 1.

### Step 0 Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Skip PM docs, I'll add them later" | Later = never. No PM docs = no project context = agents guessing. | **Run /pre-dev-full or /pre-dev-feature NOW** |
| "Project is simple, doesn't need PM docs" | Simple projects still need domain context defined upfront. | **Create PM documents first** |
| "I know what I want to build" | Your knowledge ≠ documented knowledge agents can use. | **Document in PRD/TRD/Feature Map** |
| "PM workflow takes too long" | PM workflow takes 30-60 min. Rework from unclear requirements takes days. | **Invest time upfront** |
| "Just let me start coding" | Coding without requirements = building the wrong thing. | **Requirements first, code second** |
| "It's legacy but I don't want to answer questions" | Legacy analysis takes ~5 min. Without it, agents have zero context. | **Answer the 4 questions** |
| "Legacy project is too complex to explain" | Start with high-level answers. PROJECT_RULES.md can be refined later. | **Provide what you know NOW** |

### Pressure Resistance

| User Says | Your Response |
|-----------|---------------|
| "Just skip this, I'll create PM docs later" | "PM documents are REQUIRED for new projects. Without them, agents cannot understand your project's domain context or technical requirements. Run `/pre-dev-full` or `/pre-dev-feature` first." |
| "I don't need formal documents" | "PM documents are the source of truth for PROJECT_RULES.md. Development cannot start without documented requirements." |
| "This is just a quick prototype" | "Even prototypes need clear requirements. `/pre-dev-feature` takes ~30 minutes and prevents hours of rework." |
| "I already explained what I want verbally" | "Verbal explanations cannot be used by agents. Requirements MUST be documented in PRD/TRD/Feature Map files." |
| "It's a legacy project but skip the questions" | "The legacy analysis (codebase-explorer + 3 questions) is the only way I can understand your project. It takes ~5 minutes and enables me to help you effectively." |
| "I'll fill in PROJECT_RULES.md myself" | "That works! Create `docs/PROJECT_RULES.md` with: Tech Stack (not in Ring), External Integrations, Domain Terminology. Do NOT duplicate Ring Standards content. Then run `/dev-cycle` again." |

---

## Step 1: Initialize or Resume

### New Cycle (with task file path)

**Input:** `path/to/tasks.md` OR `path/to/pre-dev/{feature}/`

1. **Detect input:** File → Load directly | Directory → Load tasks.md + discover subtasks/
2. **Build order:** Read tasks, check for subtasks (ST-XXX-01, 02...) or TDD autonomous mode
3. **Initialize state:** Generate cycle_id, create `docs/refactor/current-cycle.json`, set indices to 0
4. **Display plan:** "Loaded X tasks with Y subtasks"
5. **ASK EXECUTION MODE (MANDATORY - AskUserQuestion):**
   - Options: (a) Manual per subtask (b) Manual per task (c) Automatic
   - **Do NOT skip:** User hints ≠ mode selection. Only explicit a/b/c is valid.
6. **Start:** Display mode, proceed to Gate 0

### Resume Cycle (--resume flag)

1. Load `docs/refactor/current-cycle.json`, validate
2. Display: cycle started, tasks completed/total, current task/subtask/gate, paused reason
3. **Handle paused states:**

| Status | Action |
|--------|--------|
| `paused_for_approval` | Re-present Step 7.1 checkpoint |
| `paused_for_testing` | Ask if testing complete → continue or keep paused |
| `paused_for_task_approval` | Re-present Step 7.2 checkpoint |
| `paused_for_integration_testing` | Ask if integration testing complete |
| `paused` (generic) | Ask user to confirm resume |
| `in_progress` | Resume from current gate |

## Input Validation

Task files are generated by `/pre-dev-*` or `/dev-refactor`, which handle content validation. The dev-cycle performs basic format checks:

### Format Checks

| Check | Validation | Action |
|-------|------------|--------|
| File exists | Task file path is readable | Error: abort |
| Task headers | At least one `## Task:` found | Error: abort |
| Task ID format | `## Task: {ID} - {Title}` | Warning: use line number as ID |
| Acceptance criteria | At least one `- [ ]` per task | Warning: task may fail validation gate |

## Step 2: Gate 0 - Implementation (Per Execution Unit)

**REQUIRED SUB-SKILL:** Use dev-implementation

**Execution Unit:** Task (if no subtasks) OR Subtask (if task has subtasks)

### ⛔ MANDATORY: Agent Dispatch Required

See [shared-patterns/shared-orchestrator-principle.md](../shared-patterns/shared-orchestrator-principle.md) for full details.

**Gate 0 has TWO explicit sub-phases with a HARD GATE between them:**

```
┌─────────────────────────────────────────────────────────────────┐
│  GATE 0.1: TDD-RED                                              │
│  ─────────────────                                              │
│  Write failing test → Run test → Capture FAILURE output         │
│                                                                 │
│  ═══════════════════ HARD GATE ═══════════════════════════════  │
│  CANNOT proceed to 0.2 until failure output is captured         │
│  ════════════════════════════════════════════════════════════   │
│                                                                 │
│  GATE 0.2: TDD-GREEN                                            │
│  ──────────────────                                             │
│  Implement minimal code → Run test → Verify PASS                │
└─────────────────────────────────────────────────────────────────┘
```

### Step 2.1: Gate 0.1 - TDD-RED (Write Failing Test)

1. Record gate start timestamp
2. Set `gate_progress.implementation.tdd_red.status = "in_progress"`

3. Determine appropriate agent based on content:
   - Go files/go.mod → backend-engineer-golang
   - TypeScript backend → backend-engineer-typescript
   - React/Frontend → frontend-engineer-typescript
   - Infrastructure → devops-engineer

4. Dispatch to selected agent for TDD-RED ONLY:

   See [shared-patterns/template-tdd-prompts.md](../shared-patterns/template-tdd-prompts.md) for the TDD-RED prompt template.

   Include: unit_id, title, requirements, acceptance_criteria in the prompt.

5. Receive TDD-RED report from agent
6. **VERIFY FAILURE OUTPUT EXISTS (HARD GATE):** See shared-patterns/template-tdd-prompts.md for verification rules.

7. Update state:
   ```json
   gate_progress.implementation.tdd_red = {
     "status": "completed",
     "test_file": "[path from agent]",
     "failure_output": "[actual failure output from agent]",
     "completed_at": "[ISO timestamp]"
   }
   ```

8. **Display to user:**
   ```
   ┌─────────────────────────────────────────────────┐
   │ ✓ TDD-RED COMPLETE                              │
   ├─────────────────────────────────────────────────┤
   │ Test: [test_file]:[test_function]               │
   │ Failure: [first line of failure output]         │
   │                                                 │
   │ Proceeding to TDD-GREEN...                      │
   └─────────────────────────────────────────────────┘
   ```

9. Proceed to Gate 0.2

### Step 2.2: Gate 0.2 - TDD-GREEN (Implementation)

**PREREQUISITE:** `gate_progress.implementation.tdd_red.status == "completed"`

1. Set `gate_progress.implementation.tdd_green.status = "in_progress"`

2. Dispatch to same agent for TDD-GREEN:

   See [shared-patterns/template-tdd-prompts.md](../shared-patterns/template-tdd-prompts.md) for the TDD-GREEN prompt template (includes observability requirements).

   Include: unit_id, title, tdd_red.test_file, tdd_red.failure_output in the prompt.

3. Receive TDD-GREEN report from agent
4. **VERIFY PASS OUTPUT EXISTS (HARD GATE):** See shared-patterns/template-tdd-prompts.md for verification rules.

5. Update state:
   ```json
   gate_progress.implementation.tdd_green = {
     "status": "completed",
     "implementation_file": "[path from agent]",
     "test_pass_output": "[actual pass output from agent]",
     "completed_at": "[ISO timestamp]"
   }
   gate_progress.implementation.status = "completed"
   artifacts.implementation = {files_changed, commit_sha}
   agent_outputs.implementation = {
     agent: "[selected_agent]",
     output: "[full agent output for feedback analysis]",
     timestamp: "[ISO timestamp]",
     duration_ms: [execution time]
   }
   ```

6. **Display to user:**
   ```
   ┌─────────────────────────────────────────────────┐
   │ ✓ GATE 0 COMPLETE (TDD-RED → TDD-GREEN)        │
   ├─────────────────────────────────────────────────┤
   │ RED:   [test_file] - FAIL captured ✓           │
   │ GREEN: [impl_file] - PASS verified ✓           │
   │                                                 │
   │ Proceeding to Gate 1 (DevOps)...               │
   └─────────────────────────────────────────────────┘
   ```

7. **Proceed to Step 2.3 (Standards Compliance Verification)**

### Step 2.3: Standards Compliance Verification (HARD GATE)

**PREREQUISITE:** `gate_progress.implementation.tdd_green.status == "completed"`

**Purpose:** Verify implementation follows ALL standards defined in agent's standards file.

See [shared-patterns/template-tdd-prompts.md](../shared-patterns/template-tdd-prompts.md) → "Orchestrator Enforcement" section for full verification process.

**Process:**

1. **Parse TDD-GREEN agent output for "## Standards Coverage Table"**
   ```
   IF "## Standards Coverage Table" NOT FOUND in agent output:
     → Output INCOMPLETE
     → Re-dispatch to SAME agent with prompt:
       "Your output is missing Standards Coverage Table. 
        WebFetch your standards and output table per standards-coverage-table.md"
   ```

2. **Parse "ALL STANDARDS MET:" value from "## Compliance Summary"**
   ```
   IF "ALL STANDARDS MET:" NOT FOUND:
     → Output INCOMPLETE
     → Re-dispatch agent (same as above)
   ```

3. **Verify compliance:**
   ```
   IF "ALL STANDARDS MET: ✅ YES" AND all sections ✅ or N/A:
     → Gate 0 PASSED
     → Continue to step 4
   
   IF "ALL STANDARDS MET: ❌ NO" OR ANY section has ❌:
     → Gate 0 BLOCKED
     → Extract ❌ sections from Standards Coverage Table
     → Re-dispatch to SAME agent:
     
     Task tool:
       subagent_type: "[same agent from TDD-GREEN]"
       model: "opus"
       description: "Fix missing Ring Standards for [unit_id]"
       prompt: |
         ⛔ STANDARDS NOT MET - Fix Required
         
         Your Standards Coverage Table shows these sections as ❌:
         [list ❌ sections extracted from table]
         
         WebFetch your standards file:
         [URL for agent's standards - golang.md, typescript.md, etc.]
         
         Implement ALL missing sections.
         Return updated Standards Coverage Table with ALL ✅ or N/A.
     
     → After fix: Re-verify (go back to step 1)
     → Max 3 iterations, then STOP and escalate to user
   ```

4. **Update state:**
   ```json
   gate_progress.implementation = {
     "status": "completed",
     "tdd_red": {...},
     "tdd_green": {...},
     "standards_verified": true,
     "standards_compliance_iterations": [count],
     "standards_coverage": {
       "total_sections": [N],
       "compliant": [N],
       "not_applicable": [N],
       "non_compliant": 0
     }
   }
   ```

5. **Display to user:**
   ```
   ┌─────────────────────────────────────────────────┐
   │ ✓ GATE 0 COMPLETE                              │
   ├─────────────────────────────────────────────────┤
   │ TDD-RED:   [test_file] - FAIL captured ✓       │
   │ TDD-GREEN: [impl_file] - PASS verified ✓       │
   │ STANDARDS: [N]/[N] sections compliant ✓        │
   │                                                 │
   │ Proceeding to Gate 1 (DevOps)...               │
   └─────────────────────────────────────────────────┘
   ```

6. **⛔ SAVE STATE TO FILE (MANDATORY):**
   ```yaml
   Write tool:
     file_path: "docs/refactor/current-cycle.json"
     content: [full updated state JSON]
   ```
   See "State Persistence Rule" section. State MUST be written to file after Gate 0.

7. **Proceed to Gate 1**

### Standards Compliance Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Agent said implementation is complete" | Agent completion ≠ Standards compliance. Verify table. | **Parse and verify Standards Coverage Table** |
| "Table wasn't in agent output" | Missing table = Incomplete output = Re-dispatch | **Re-dispatch agent to output table** |
| "Only 1-2 sections are ❌" | ANY ❌ = BLOCKED. Count is irrelevant. | **Re-dispatch to fix ALL ❌ sections** |
| "lib-commons is the main thing" | ALL sections are equally required. No prioritization. | **Verify ALL sections from standards-coverage-table.md** |
| "Agent knows the standards" | Knowledge ≠ implementation. Evidence required. | **Check file:line evidence in table** |
| "Standards verification is slow" | Verification prevents rework. 30 seconds vs hours. | **Always verify before proceeding** |

### TDD Sub-Phase Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Test passes on first run, skip RED" | Passing test ≠ TDD. Test MUST fail first. | **Delete test, rewrite to fail first** |
| "I'll capture failure output later" | Later = never. Failure output is the gate. | **Capture NOW or cannot proceed** |
| "Failure output is in the logs somewhere" | "Somewhere" ≠ captured. Must be in state. | **Extract and store in tdd_red.failure_output** |
| "GREEN passed, RED doesn't matter now" | RED proves test validity. Skip = invalid test. | **Re-run RED phase, capture failure** |
| "Agent already did TDD internally" | Internal ≠ verified. State must show evidence. | **Agent must output failure explicitly** |

## Step 3: Gate 1 - DevOps (Per Execution Unit)

**REQUIRED SUB-SKILL:** Use dev-devops

### ⛔ HARD GATE: Required Artifacts MUST Be Created

**Gate 1 is a BLOCKING gate.** DevOps agent MUST create ALL required artifacts. If ANY artifact is missing:
- You CANNOT proceed to Gate 2
- You MUST re-dispatch to devops-engineer to create missing artifacts
- You MUST verify ALL artifacts exist before proceeding

### Required Artifacts

**See [shared-patterns/standards-coverage-table.md](../skills/shared-patterns/standards-coverage-table.md) → "devops-engineer → devops.md" for ALL required sections.**

**Key artifacts from devops.md:**
- Containers (Dockerfile + Docker Compose)
- Makefile Standards (ALL required commands)
- Infrastructure as Code (if applicable)
- Helm charts (if K8s deployment)

### Step 3.1: Dispatch DevOps Agent

```text
For current execution unit:

1. Record gate start timestamp
2. Dispatch DevOps agent (ALWAYS - not optional):

   Task tool:
     subagent_type: "devops-engineer"
     model: "opus"
     description: "Create/update DevOps artifacts for [unit_id]"
     prompt: |
       ⛔ MANDATORY: Create ALL DevOps Artifacts for: [unit_id]

       ## Implementation Summary from Gate 0:
       [implementation_artifacts]

       ## Standards Reference:
       WebFetch: https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/devops.md
       
       You MUST implement ALL sections from devops.md. See standards-coverage-table.md
       for the complete list: devops-engineer → devops.md

       ## Required Output:

       ### Standards Coverage Table
       | # | Section (from devops.md) | Status | Evidence |
       |---|--------------------------|--------|----------|
       | 1 | Containers | ✅/❌ | Dockerfile:[line], docker-compose.yml:[line] |
       | 2 | Makefile Standards | ✅/❌ | Makefile:[line] |
       | ... | ... | ... | ... |

       ### Compliance Summary
       - **ALL STANDARDS MET:** ✅ YES / ❌ NO
       - **If NO, what's missing:** [list sections]

       ### Verification Commands Executed:
       - `docker build -t [service] .` → [result]
       - `docker-compose config` → [result]
       - `make` → [result]

3. Parse agent output and verify Standards Coverage Table
```

### Step 3.2: Verify Standards Coverage Table (HARD GATE)

```text
4. Parse agent output for Standards Coverage Table:

   IF "ALL STANDARDS MET: ✅ YES" AND all sections have ✅ or N/A:
     → Verify files actually exist (Read tool for each artifact)
     → If all files exist → Gate 1 PASSED. Proceed to Step 3.3.

   IF ANY section has ❌:
     → Gate 1 BLOCKED. Standards not met.
     → Extract ❌ sections from Standards Coverage Table
     → Re-dispatch to devops-engineer:

     Task tool:
       subagent_type: "devops-engineer"
       model: "opus"
       description: "Fix missing DevOps standards for [unit_id]"
       prompt: |
         ⛔ FIX REQUIRED - DevOps Standards Not Met

         Your Standards Coverage Table shows these sections as ❌:
         [list ❌ sections from table]

         WebFetch the standards again:
         https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/devops.md

         Implement ALL missing sections.
         Return updated Standards Coverage Table with ALL ✅ or N/A.

     → After fix: Re-verify Standards Coverage Table
     → Max 3 iterations, then STOP and escalate to user
```

### Step 3.3: Gate 1 Complete

```text
5. When all artifacts verified:
   - agent_outputs.devops = {
       agent: "devops-engineer",
       output: "[full agent output]",
       artifacts_created: ["Dockerfile", "docker-compose.yml", ".env.example", "Makefile"],
       timestamp: "[ISO timestamp]",
       duration_ms: [execution time]
     }

6. Update state:
   - gate_progress.devops.status = "completed"
   - gate_progress.devops.artifacts = [list of created files]

7. **⛔ SAVE STATE TO FILE (MANDATORY):**
   Write tool → "docs/refactor/current-cycle.json"

8. Proceed to Gate 2
```

### Gate 1 Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Dockerfile exists, skip other artifacts" | ALL artifacts required. 1/4 ≠ complete. | **Create ALL artifacts** |
| "docker-compose not needed locally" | docker-compose is MANDATORY for local dev. | **Create docker-compose.yml** |
| "Makefile is optional" | Makefile is MANDATORY for standardized commands. | **Create Makefile** |
| ".env.example can be added later" | .env.example documents required config NOW. | **Create .env.example** |
| "Small service doesn't need all this" | Size is irrelevant. Standards apply uniformly. | **Create ALL artifacts** |

## Step 4: Gate 2 - SRE (Per Execution Unit)

**REQUIRED SUB-SKILL:** Use dev-sre

### ⛔ HARD GATE: Observability MUST Be Validated

**Gate 2 is a BLOCKING gate.** SRE agent VALIDATES that observability was correctly implemented in Gate 0. If ANY observability requirement is missing:
- You CANNOT proceed to Gate 3
- You MUST dispatch fix to the IMPLEMENTATION agent (backend-engineer-golang, etc.) - NOT SRE
- You MUST re-run SRE validation after fixes
- You MUST repeat until ALL observability requirements pass

**SRE validates. Implementation agents fix. SRE does NOT implement.**

### Required Observability (from sre.md)

**See [shared-patterns/standards-coverage-table.md](../skills/shared-patterns/standards-coverage-table.md) → "sre → sre.md" for ALL required sections.**

### Step 4.1: Dispatch SRE Agent for Validation

```text
For current execution unit:

1. Record gate start timestamp
2. Dispatch SRE agent (ALWAYS - validation is not optional):

   Task tool:
     subagent_type: "sre"
     model: "opus"
     description: "Validate observability for [unit_id]"
     prompt: |
       ⛔ VALIDATE Observability Implementation for: [unit_id]

       ## Service Information:
       - Language: [Go/TypeScript]
       - Service type: [API/Worker/Batch]
       - Implementation agent: [agent that did Gate 0]
       - Files from Gate 0: [list of implementation files]

       ## Standards Reference:
       WebFetch: https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/sre.md
       
       You MUST validate ALL sections from sre.md. See standards-coverage-table.md
       for the complete list: sre → sre.md

       ## Your Role:
       - VALIDATE that observability is implemented correctly
       - Do NOT implement - only verify and report
       - If issues found → Report them with severity and file:line

       ## Required Output:

       ### Standards Coverage Table (Validation Results)
       | # | Section (from sre.md) | Status | Evidence |
       |---|----------------------|--------|----------|
       | 1 | Logging Standards | ✅/❌ | [file:line or "NOT FOUND"] |
       | 2 | Tracing Standards | ✅/❌ | [file:line or "NOT FOUND"] |
       | 3 | OpenTelemetry with lib-commons | ✅/❌ | [file:line or "NOT FOUND"] |
       | 4 | Health Checks | ✅/❌ | [file:line or "NOT FOUND"] |
       | ... | ... | ... | ... |

       ### Issues Found (if any ❌)
       For each ❌ section:
       - **Section:** [name]
       - **Severity:** CRITICAL/HIGH/MEDIUM
       - **What's Missing:** [specific requirement not met]
       - **Expected:** [what should exist per sre.md]
       - **Fix Required By:** [implementation agent name]

       ### Compliance Summary
       - **ALL OBSERVABILITY VALIDATED:** ✅ YES / ❌ NO
       - **If NO, sections failing:** [list]

3. Parse agent output and check validation results
```

### Step 4.2: Handle Validation Results (HARD GATE)

```text
4. Parse SRE agent output for Standards Coverage Table:

   IF "ALL OBSERVABILITY VALIDATED: ✅ YES" AND all sections have ✅ or N/A:
     → Gate 2 PASSED. Proceed to Step 4.4.

   IF ANY section has ❌:
     → Gate 2 BLOCKED. Observability not implemented correctly.
     → Extract ❌ sections and issues from SRE report
     → Dispatch fix to IMPLEMENTATION agent (NOT SRE):
```

### Step 4.3: Dispatch Fix to Implementation Agent

```text
   ⛔ IMPORTANT: SRE validates. Implementation agents fix.
   
   Determine which agent implemented Gate 0:
   - Go code → backend-engineer-golang
   - TypeScript backend → backend-engineer-typescript
   - React/Frontend → frontend-engineer

   Task tool:
     subagent_type: "[implementation agent from Gate 0]"
     model: "opus"
     description: "Fix observability issues for [unit_id]"
     prompt: |
       ⛔ FIX REQUIRED - Observability Not Implemented

       SRE validation found these observability issues:

       ## Issues to Fix (from SRE report):
       [paste ❌ sections and issues from SRE output]

       ## Standards Reference:
       For Go: https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang.md
       For TS: https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/typescript.md
       
       Focus on:
       - Telemetry & Observability section
       - Logging Standards section
       - Bootstrap Pattern (telemetry initialization)

       ## Requirements:
       1. Implement ALL missing observability per standards
       2. For Go: lib-commons v2 telemetry, NewTrackingFromContext, spans
       3. For TS: lib-common-js logging, structured JSON
       4. Return Standards Coverage Table showing ALL observability ✅

   → After fix: Re-dispatch SRE agent to validate again
   → Increment metrics.sre_iterations
   → Max 3 iterations, then STOP and escalate to user
```

### Step 4.4: Gate 2 Complete

```text
5. When all observability validated:
   - agent_outputs.sre = {
       agent: "sre",
       output: "[full agent output]",
       validation_result: "PASS",
       iterations: [count],
       timestamp: "[ISO timestamp]",
       duration_ms: [execution time]
     }

6. Update state:
   - gate_progress.sre.status = "completed"
   - gate_progress.sre.observability_validated = true

7. **⛔ SAVE STATE TO FILE (MANDATORY):**
   Write tool → "docs/refactor/current-cycle.json"

8. Proceed to Gate 3
```

### Gate 2 Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Observability can be added later" | Observability is v1 requirement. Debugging blind code is impossible. | **Fix NOW before Gate 3** |
| "SRE should implement the fix" | SRE validates. Implementation agents implement. Role separation. | **Dispatch to implementation agent** |
| "Only logging is missing, tracing optional" | ALL observability sections are MANDATORY per sre.md. | **Implement ALL sections** |
| "Simple service doesn't need full observability" | Complexity is irrelevant. Standards apply uniformly. | **Implement ALL sections** |
| "Tests pass, skip observability" | Tests ≠ observability. Different concerns. | **Validate observability separately** |
| "lib-commons already handles it" | lib-commons provides tools. You must USE them correctly. | **Verify correct usage** |

### Gate 2 Pressure Resistance

| User Says | Your Response |
|-----------|---------------|
| "Skip SRE validation, we'll add observability later" | "Observability is MANDATORY for Gate 2. Without it, you cannot debug production issues. I'm dispatching SRE to validate now." |
| "SRE found issues but let's continue" | "Gate 2 is a HARD GATE. I MUST dispatch fixes to [implementation agent] before proceeding. SRE validates, implementation fixes." |
| "Just mark observability as N/A" | "Observability is ALWAYS applicable for services. N/A requires explicit technical reason. I'm dispatching validation now." |

## Step 5: Gate 3 - Testing (Per Execution Unit)

**REQUIRED SUB-SKILL:** Use dev-testing

### Simple Flow

```
┌─────────────────────────────────────────────────────────┐
│  QA runs tests → checks coverage against threshold      │
│                                                         │
│  PASS (coverage ≥ threshold) → Proceed to Gate 4       │
│  FAIL (coverage < threshold) → Return to Gate 0        │
│                                                         │
│  Max 3 attempts, then escalate to user                 │
└─────────────────────────────────────────────────────────┘
```

### Threshold

- Default: **85%** (Ring minimum)
- Can be higher if defined in `docs/PROJECT_RULES.md`
- Cannot be lower than 85%

### Execution

```text
1. Dispatch QA analyst with acceptance criteria and threshold
2. QA writes tests, runs them, checks coverage
3. QA returns VERDICT: PASS or FAIL

   PASS → Proceed to Gate 4 (Review)

   FAIL → Return to Gate 0 (Implementation) to add tests
          QA provides: what lines/branches need coverage

4. Track iteration count (state.testing.iteration)
   - Max 3 iterations allowed
   - After 3rd failure: STOP and escalate to user
   - Do NOT attempt 4th iteration automatically

5. **⛔ SAVE STATE TO FILE (MANDATORY):**
   Write tool → "docs/refactor/current-cycle.json"
   See "State Persistence Rule" section.
```

### State Tracking

```json
{
  "testing": {
    "verdict": "PASS|FAIL",
    "coverage_actual": 87.5,
    "coverage_threshold": 85,
    "iteration": 1
  }
}
```

## Step 6: Gate 4 - Review (Per Execution Unit)

**REQUIRED SUB-SKILL:** Use requesting-code-review

### ⛔ HARD GATE: Issues MUST Be Fixed Before Proceeding

**Gate 4 is a BLOCKING gate.** If reviewers find CRITICAL, HIGH, or MEDIUM severity issues:
- You CANNOT proceed to Gate 5
- You MUST dispatch fixes to the appropriate agent
- You MUST re-run ALL 3 reviewers after fixes
- You MUST repeat until ALL issues are resolved or max iterations reached

### Step 6.1: Initial Review Dispatch

```text
For current execution unit:

1. Record gate start timestamp
2. Dispatch all 3 reviewers in parallel (single message, 3 Task calls):

   Task tool #1:
     subagent_type: "code-reviewer"
     model: "opus"
     prompt: |
       Review implementation for: [unit_id]
       BASE_SHA: [pre-implementation commit]
       HEAD_SHA: [current commit]
       REQUIREMENTS: [unit requirements]

   Task tool #2:
     subagent_type: "business-logic-reviewer"
     model: "opus"
     prompt: [same structure]

   Task tool #3:
     subagent_type: "security-reviewer"
     model: "opus"
     prompt: [same structure]

3. Wait for all reviewers to complete
4. Store all reviewer outputs:
   - agent_outputs.review = {
       code_reviewer: {
         agent: "code-reviewer",
         output: "[full output for feedback analysis]",
         verdict: "PASS|FAIL",
         issues: [{severity, description, file, line}],
         timestamp: "[ISO timestamp]"
       },
       business_logic_reviewer: {
         agent: "business-logic-reviewer",
         output: "[full output for feedback analysis]",
         verdict: "PASS|FAIL",
         issues: [{severity, description, file, line}],
         timestamp: "[ISO timestamp]"
       },
       security_reviewer: {
         agent: "security-reviewer",
         output: "[full output for feedback analysis]",
         verdict: "PASS|FAIL",
         issues: [{severity, description, file, line}],
         timestamp: "[ISO timestamp]"
       }
     }
```

### Step 6.2: Aggregate and Classify Issues

```text
5. Parse all reviewer outputs and aggregate issues by severity:

   ┌─────────────────────────────────────────────────────────────────┐
   │ SEVERITY CLASSIFICATION                                         │
   ├─────────────────────────────────────────────────────────────────┤
   │ CRITICAL: Security vulnerabilities, data loss, crashes          │
   │           → MUST FIX. Cannot proceed. Auto-dispatch to agent.   │
   │                                                                 │
   │ HIGH:     Major bugs, incorrect business logic, performance     │
   │           → MUST FIX. Cannot proceed. Auto-dispatch to agent.   │
   │                                                                 │
   │ MEDIUM:   Code quality, standards violations, edge cases        │
   │           → MUST FIX. Cannot proceed. Auto-dispatch to agent.   │
   │                                                                 │
   │ LOW:      Best practices, minor improvements                    │
   │           → Add TODO(review): comment. Can proceed.             │
   │                                                                 │
   │ COSMETIC: Style, formatting, naming nitpicks                    │
   │           → Add FIXME(nitpick): comment. Can proceed.           │
   └─────────────────────────────────────────────────────────────────┘

6. Create aggregated issue list:
   aggregated_issues = {
     blocking: [  // CRITICAL + HIGH + MEDIUM
       {severity, reviewer, description, file, line, suggested_fix}
     ],
     non_blocking: [  // LOW + COSMETIC
       {severity, reviewer, description, file, line}
     ]
   }
```

### Step 6.3: Handle Non-Blocking Issues (LOW/COSMETIC)

```text
7. For each non-blocking issue, add inline comments:

   LOW severity → Add TODO comment:
   // TODO(review): [description] - [reviewer] on [date]

   COSMETIC severity → Add FIXME comment:
   // FIXME(nitpick): [description] - [reviewer] on [date]

   These comments are added but DO NOT block progression.
```

### Step 6.4: Handle Blocking Issues (CRITICAL/HIGH/MEDIUM) - HARD GATE

```text
8. IF aggregated_issues.blocking is NOT empty:

   ┌─────────────────────────────────────────────────────────────────┐
   │ ⛔ GATE 4 BLOCKED - ISSUES MUST BE FIXED                        │
   ├─────────────────────────────────────────────────────────────────┤
   │                                                                 │
   │ Found N blocking issues:                                        │
   │   • CRITICAL: X issues                                          │
   │   • HIGH: Y issues                                               │
   │   • MEDIUM: Z issues                                            │
   │                                                                 │
   │ Dispatching fixes to appropriate agents...                      │
   │                                                                 │
   └─────────────────────────────────────────────────────────────────┘

   a) Group issues by responsible agent (based on issue type):

   ┌─────────────────────────────────────────────────────────────────┐
   │ ISSUE-TO-AGENT ROUTING                                         │
   ├─────────────────────────────────────────────────────────────────┤
   │ Issue Type                    │ Agent                          │
   │───────────────────────────────┼────────────────────────────────│
   │ Go code issues                │ backend-engineer-golang        │
   │ TypeScript backend issues     │ backend-engineer-typescript    │
   │ React/Frontend issues         │ frontend-engineer              │
   │ BFF issues                    │ frontend-bff-engineer-typescript│
   │ Security vulnerabilities      │ Same as code type + sre        │
   │ Business logic errors         │ Same as code type              │
   │ Architecture issues           │ Same as code type              │
   │ DevOps/Infra issues           │ devops-engineer                │
   │ Observability issues          │ sre                            │
   │ Test coverage issues          │ qa-analyst                     │
   └─────────────────────────────────────────────────────────────────┘

   b) Dispatch fix request to each responsible agent:

   Task tool:
     subagent_type: "[agent from routing table]"
     model: "opus"
     description: "Fix review issues for [unit_id]"
     prompt: |
       ⛔ FIX REQUIRED - Review Issues Found

       You MUST fix the following issues identified by code reviewers.
       Do NOT skip any issue. Do NOT defer any issue.

       ## Context
       - Unit ID: [unit_id]
       - Unit Title: [title]
       - Files Changed: [list of files from implementation]

       ## Issues to Fix (BLOCKING - ALL MUST BE RESOLVED)

       [For each issue assigned to this agent:]
       ### Issue N: [severity] - [reviewer]
       - **Description:** [description]
       - **File:** [file]:[line]
       - **Suggested Fix:** [suggested_fix if provided]

       ## Requirements
       1. Fix ALL issues listed above
       2. Run tests after fixes to ensure no regressions
       3. Report what was fixed and how

       ## Output Format
       For each issue:
       - Issue: [description]
       - Fix Applied: [what you did]
       - File Changed: [file]:[lines]
       - Test Verification: [test results]

   c) Wait for all fix agents to complete

   d) Store fix results in state:
      agent_outputs.review.fix_iteration_N = {
        issues_fixed: N,
        agents_dispatched: [list],
        timestamp: "[ISO timestamp]"
      }
```

### Step 6.5: Re-Run ALL Reviewers After Fixes

```text
9. After ALL fixes are applied:

   ⛔ MANDATORY: Re-run ALL 3 reviewers in parallel
   (You CANNOT cherry-pick reviewers. ALL 3 must re-run.)

   Increment: metrics.review_iterations += 1

   Dispatch all 3 reviewers again (same as Step 6.1)
   with updated HEAD_SHA reflecting the fixes.

10. Parse results and check for remaining blocking issues:

    IF aggregated_issues.blocking is empty:
      → Gate 4 PASSED. Proceed to Step 6.6.

    IF aggregated_issues.blocking is NOT empty:
      → Check iteration count

11. Iteration limit check:

    IF metrics.review_iterations >= 3:
      ┌─────────────────────────────────────────────────────────────────┐
      │ ⛔ MAXIMUM REVIEW ITERATIONS REACHED                            │
      ├─────────────────────────────────────────────────────────────────┤
      │                                                                 │
      │ After 3 fix attempts, blocking issues remain:                   │
      │                                                                 │
      │ [List remaining issues]                                         │
      │                                                                 │
      │ ACTION REQUIRED: Human intervention needed.                     │
      │                                                                 │
      │ Options:                                                        │
      │   a) Review issues manually and provide guidance                │
      │   b) Escalate to senior engineer                                │
      │   c) Abort this unit and mark as blocked                        │
      │                                                                 │
      └─────────────────────────────────────────────────────────────────┘

      Set status = "blocked"
      Set gate_progress.review.status = "failed"
      Set gate_progress.review.blocked_reason = "max_iterations"
      Save state
      STOP execution - require user decision

    IF metrics.review_iterations < 3:
      → Loop back to Step 6.4 (dispatch fixes again)
```

### Step 6.6: Gate 4 Complete

```text
12. When all blocking issues are resolved (aggregated_issues.blocking is empty):

    Update state:
    - gate_progress.review.status = "completed"
    - gate_progress.review.completed_at = "[ISO timestamp]"
    - gate_progress.review.total_iterations = metrics.review_iterations
    - gate_progress.review.issues_fixed = [count]

    Display:
    ┌─────────────────────────────────────────────────────────────────┐
    │ ✓ GATE 4 COMPLETE (Review)                                      │
    ├─────────────────────────────────────────────────────────────────┤
    │                                                                 │
    │ All 3 reviewers: PASS                                           │
    │ Review iterations: N                                            │
    │ Issues fixed: X                                                 │
    │ TODO comments added: Y (LOW severity)                           │
    │ FIXME comments added: Z (COSMETIC)                              │
    │                                                                 │
    │ Proceeding to Gate 5 (Validation)...                            │
    └─────────────────────────────────────────────────────────────────┘

13. **⛔ SAVE STATE TO FILE (MANDATORY):**
    Write tool → "docs/refactor/current-cycle.json"
    See "State Persistence Rule" section.

14. Proceed to Gate 5
```

### Gate 4 Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Only 1 MEDIUM issue, can proceed" | MEDIUM = MUST FIX. Quantity is irrelevant. | **Fix the issue, re-run all reviewers** |
| "Issue is cosmetic, not really MEDIUM" | Reviewer decided severity. Accept their judgment. | **Fix the issue, re-run all reviewers** |
| "Will fix in next sprint" | Deferred fixes = technical debt = production bugs. | **Fix NOW before Gate 5** |
| "User approved, can skip fix" | User approval ≠ reviewer override. Fixes are mandatory. | **Fix the issue, re-run all reviewers** |
| "Same issue keeps appearing, skip it" | Recurring issue = fix is wrong. Debug properly. | **Root cause analysis, then fix** |
| "Only security reviewer found it" | One reviewer = valid finding. All findings matter. | **Fix the issue, re-run all reviewers** |
| "Iteration limit reached, just proceed" | Limit = escalate, not bypass. Quality is non-negotiable. | **Escalate to user, do NOT proceed** |
| "Tests pass, review issues don't matter" | Tests ≠ review. Different quality dimensions. | **Fix the issue, re-run all reviewers** |

### Gate 4 Pressure Resistance

| User Says | Your Response |
|-----------|---------------|
| "Just skip this MEDIUM issue" | "MEDIUM severity issues are blocking by definition. I MUST dispatch a fix to the appropriate agent before proceeding. This protects code quality." |
| "I'll fix it later, let's continue" | "Gate 4 is a HARD GATE. All CRITICAL/HIGH/MEDIUM issues must be resolved NOW. I'm dispatching the fix to [agent] and will re-run reviewers after." |
| "We're running out of time" | "Proceeding with known issues creates larger problems later. The fix dispatch is automated and typically takes 2-5 minutes. Quality gates exist to save time overall." |
| "Override the gate, I approve" | "User approval cannot override reviewer findings. The gate ensures code quality. I'll dispatch the fix now." |
| "It's just a style issue" | "If it's truly cosmetic, reviewers would mark it COSMETIC (non-blocking). MEDIUM means it affects maintainability or correctness. Fixing now." |

## Step 7: Gate 5 - Validation (Per Execution Unit)

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
   - Proceed to Step 7.1 (Execution Unit Approval)
```

## Step 7.1: Execution Unit Approval (Conditional)

**Checkpoint depends on `execution_mode`:** `manual_per_subtask` → Execute | `manual_per_task` / `automatic` → Skip

1. Set `status = "paused_for_approval"`, save state
2. Present summary: Unit ID, Parent Task, Gates 0-5 status, Criteria X/X, Duration, Files Changed
3. **AskUserQuestion:** "Ready to proceed?" Options: (a) Continue (b) Test First (c) Stop Here
4. **Handle response:**

| Response | Action |
|----------|--------|
| Continue | Set in_progress, move to next unit (or Step 7.2 if last) |
| Test First | Set `paused_for_testing`, STOP, output resume command |
| Stop Here | Set `paused`, STOP, output resume command |

## Step 7.2: Task Approval Checkpoint (Conditional)

**Checkpoint depends on `execution_mode`:** `manual_per_subtask` / `manual_per_task` → Execute | `automatic` → Skip

1. Set task `status = "completed"`, cycle `status = "paused_for_task_approval"`, save state
2. Present summary: Task ID, Subtasks X/X, Total Duration, Review Iterations, Files Changed
3. **AskUserQuestion:** "Task complete. Ready for next?" Options: (a) Continue (b) Integration Test (c) Stop Here
4. **Handle response:**

```text
After completing all subtasks of a task:

0. Check execution_mode from state:
   - If "automatic": Still run feedback, then skip to next task
   - If "manual_per_subtask" OR "manual_per_task": Continue with checkpoint below

1. Set task status = "completed"

2. **⛔ MANDATORY: Run dev-feedback-loop skill**

   ```yaml
   Skill tool:
     skill: "dev-feedback-loop"
   ```

   **Note:** dev-feedback-loop manages its own TodoWrite tracking internally.
   
   The skill will:
   - Add its own todo item for tracking
   - Calculate assertiveness score for the task
   - Dispatch prompt-quality-reviewer agent with agent_outputs from state
   - Generate improvement suggestions
   - Write feedback to docs/feedbacks/cycle-{date}/{agent}.md
   - Mark its todo as completed

   **After feedback-loop completes, update state:**
   - Set `tasks[current].feedback_loop_completed = true` in state file

   **Anti-Rationalization for Feedback Loop:**

   | Rationalization | Why It's WRONG | Required Action |
   |-----------------|----------------|-----------------|
   | "Task was simple, skip feedback" | Simple tasks still contribute to patterns | **Execute Skill tool** |
   | "Already at 100% score" | High scores need tracking for replication | **Execute Skill tool** |
   | "User approved, feedback unnecessary" | Approval ≠ process quality metrics | **Execute Skill tool** |
   | "No issues found, nothing to report" | Absence of issues IS data | **Execute Skill tool** |
   | "Time pressure, skip metrics" | Metrics take <2 min, prevent future issues | **Execute Skill tool** |

   **⛔ HARD GATE: You CANNOT proceed to step 3 without executing the Skill tool above.**
   
   **Hook Enforcement:** A UserPromptSubmit hook (`feedback-loop-enforcer.sh`) monitors state and will inject reminders if feedback-loop is not executed.

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
   │   backend-engineer-golang: 90% (Excellent)     │
   │   qa-analyst: 75% (Acceptable)                 │
   │   code-reviewer: 88% (Good)                    │
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
   │            OR "No more tasks - cycle complete"  │
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
                /dev-cycle --resume
                when ready to continue."
     - STOP execution

   If "Stop Here":
     - Set status = "paused"
     - Save state
     - Output: "Cycle paused after task [task_id]. Resume with:
                /dev-cycle --resume"
     - STOP execution
```

**Note:** Tasks without subtasks execute both 7.1 and 7.2 in sequence.

## Step 8: Cycle Completion

1. **Calculate metrics:** total_duration_ms, average gate durations, review iterations, pass/fail ratio
2. **Update state:** `status = "completed"`, `completed_at = timestamp`
3. **Generate report:** Task | Subtasks | Duration | Review Iterations | Status

4. **⛔ MANDATORY: Run dev-feedback-loop skill for cycle metrics**

   ```yaml
   Skill tool:
     skill: "dev-feedback-loop"
   ```

   **Note:** dev-feedback-loop manages its own TodoWrite tracking internally.

   **After feedback-loop completes, update state:**
   - Set `feedback_loop_completed = true` at cycle level in state file

   **⛔ HARD GATE: Cycle is NOT complete until feedback-loop executes.**
   
   **Hook Enforcement:** A UserPromptSubmit hook (`feedback-loop-enforcer.sh`) monitors state and will inject reminders if feedback-loop is not executed.

   | Rationalization | Why It's WRONG | Required Action |
   |-----------------|----------------|-----------------|
   | "Cycle done, feedback is extra" | Feedback IS part of cycle completion | **Execute Skill tool** |
   | "Will run feedback next session" | Next session = never. Run NOW. | **Execute Skill tool** |
   | "All tasks passed, no insights" | Pass patterns need documentation too | **Execute Skill tool** |

5. **Report:** "Cycle completed. Tasks X/X, Subtasks Y, Time Xh Xm, Review iterations X"

## Quick Commands

```bash
# Full PM workflow then dev execution
/pre-dev-full my-feature
/dev-cycle docs/pre-dev/my-feature/

# Simple PM workflow then dev execution
/pre-dev-feature my-feature
/dev-cycle docs/pre-dev/my-feature/tasks.md

# Manual task file
/dev-cycle docs/tasks/sprint-001.md

# Resume interrupted cycle
/dev-cycle --resume
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
`docs/refactor/current-cycle.json`
