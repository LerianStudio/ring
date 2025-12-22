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
│       │   Step 1: Dispatch agents IN PARALLEL:                              │
│       │     • codebase-explorer (technical: stack, patterns, features)      │
│       │     • business-logic-reviewer (domain: entities, rules, workflows)  │
│       │   Step 2: Ask 4 questions (what agents can't determine):            │
│       │     1. What do you need help with?                                  │
│       │     2. Why was this project created?                                │
│       │     3. Any business rules NOT visible in code?                      │
│       │     4. Any specific technology not in dev-team standards?           │
│       │   Step 3: Combine outputs → Generate PROJECT_RULES.md               │
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

### Step 0.2.1: Legacy Project Analysis (Agents + Questions)

#### Overview

For legacy projects, combine automated analysis with targeted questions:

```text
┌─────────────────────────────────────────────────────────────────┐
│ 📋 LEGACY PROJECT ANALYSIS                                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ Since this is a legacy project, I'll analyze the codebase       │
│ first, then ask a few questions about business context.         │
│                                                                 │
│ Step 1: Automated analysis (codebase-explorer + business-logic) │
│ Step 2: Ask what only you know (business context, goals)        │
│ Step 3: Generate PROJECT_RULES.md                               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### Step 0.2.1a: Automated Codebase Analysis (MANDATORY)

**⛔ You MUST use the Task tool to dispatch BOTH agents. This is NOT implicit.**

#### Dispatch Agents

Dispatch TWO agents in PARALLEL to analyze the legacy project:

```text
Action: Use Task tool with EXACTLY these parameters for EACH agent:

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

# Agent 2: Business Logic Reviewer - Domain Analysis
Task tool:
  subagent_type: "business-logic-reviewer"
  model: "opus"
  description: "Analyze legacy project domain for PROJECT_RULES.md"
  prompt: |
    Analyze this LEGACY codebase to extract business domain information for PROJECT_RULES.md.
    
    This is an existing project created without PM documentation.
    Your job is to understand the business logic from the code.
    
    **IMPORTANT:** This is NOT a code review. Do NOT provide VERDICT or issues.
    Focus on understanding what the business logic does.
    
    **Extract:**
    1. **Business Domain:** What business problem does this appear to solve?
    2. **Domain Terminology:** Key terms, entities, concepts used
    3. **Business Rules:** Validation rules, calculations, constraints in code
    4. **Domain Entities:** Main entities/models and relationships
    5. **Business Workflows:** Key processes/flows implemented
    6. **Constraints:** Business invariants, validation rules
    
    **Output format:**
    ## Business Domain Analysis (Legacy Project)
    
    ### Inferred Business Domain
    [What business this project serves based on code]
    
    ### Domain Terminology
    | Term | Definition (inferred from code) |
    |------|--------------------------------|
    | [term] | [definition] |
    
    ### Business Rules Found
    [List of explicit rules in code]
    
    ### Domain Entities
    [Main entities and relationships]
    
    ### Business Workflows
    [Key processes found in code]
    
    ### Business Constraints
    [Validations, invariants found]
```

#### Verification (MANDATORY)

After BOTH agents complete, confirm:
- [ ] `codebase-explorer` returned "## Technical Analysis (Legacy Project)" section
- [ ] `business-logic-reviewer` returned "## Business Domain Analysis (Legacy Project)" section
- [ ] Both outputs contain non-empty content

**If either agent failed or returned empty output → Re-dispatch that agent. Cannot proceed without both analyses.**

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
| 2 | **Why was this project created?** (Business context, original problem) | Historical context, not in code |
| 3 | **Any business rules NOT visible in code?** (Implicit rules, external constraints) | Undocumented requirements |
| 4 | **Any specific technology not in dev-team standards?** (Custom libs, internal tools, proprietary tech) | Project-specific tech not in Ring standards |

#### Step 0.2.1c: Generate PROJECT_RULES.md

#### Combine Agent Outputs and User Answers

```yaml
Create tool:
  file_path: "docs/PROJECT_RULES.md"
  content: |
    # Project Rules
    
    > Generated from legacy project analysis.
    > Technical details extracted by codebase-explorer and business-logic-reviewer.
    > Business context provided by developer.
    > Update this file as the project evolves.
    
    ## Project Overview
    
    [From codebase-explorer: Project Overview]
    
    ## Business Domain
    
    [From business-logic-reviewer: Inferred Business Domain]
    [From User Question 2: Why was this project created?]
    
    ## Current Development Goal
    
    [From User Question 1: What do you need help with?]
    
    ## Technical Stack
    
    [From codebase-explorer: Technical Stack - full details]
    
    ## Architecture Patterns
    
    [From codebase-explorer: Architecture Patterns]
    
    ## Existing Features
    
    [From codebase-explorer: Existing Features]
    
    ## Project Structure
    
    [From codebase-explorer: Project Structure]
    
    ## Domain Terminology
    
    [From business-logic-reviewer: Domain Terminology table]
    
    ## Business Rules
    
    ### From Code Analysis
    [From business-logic-reviewer: Business Rules Found]
    
    ### Additional Rules (from developer)
    [From User Question 3: Any business rules NOT visible in code?]
    
    ## Project-Specific Technology
    
    [From User Question 4: Any specific technology not in dev-team standards?]
    
    ## Domain Entities
    
    [From business-logic-reviewer: Domain Entities]
    
    ## Business Workflows
    
    [From business-logic-reviewer: Business Workflows]
    
    ## External Integrations
    
    [From codebase-explorer: External Integrations]
    
    ## Configuration
    
    [From codebase-explorer: Configuration]
    
    ---
    
    *Generated: [ISO timestamp]*
    *Source: Legacy project analysis (codebase-explorer + business-logic-reviewer + developer input)*
    *Last Updated: [ISO timestamp]*
```

#### Present to User

```text
┌─────────────────────────────────────────────────────────────────┐
│ ✓ PROJECT_RULES.md Generated for Legacy Project                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ I analyzed your codebase using:                                 │
│   • codebase-explorer (technical patterns, stack, structure)    │
│   • business-logic-reviewer (domain, entities, rules)           │
│                                                                 │
│ Combined with your input on:                                    │
│   • Current development goal                                    │
│   • Business context                                            │
│   • Additional business rules                                   │
│                                                                 │
│ Generated: docs/PROJECT_RULES.md                                │
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

| From PRD | Extract For PROJECT_RULES.md |
|----------|------------------------------|
| Problem statement | Project Overview |
| User stories / Features | Business Domain context |
| Domain terms, entities | Domain Terminology (Glossary) |
| Business rules, constraints | Business Rules |
| Acceptance criteria patterns | Validation rules |

| From TRD | Extract For PROJECT_RULES.md |
|----------|------------------------------|
| Architecture decisions | Architecture Patterns |
| Tech stack | Technical Stack |
| Database design | Database Patterns |
| API contracts | External Integrations |
| Component structure | Project Structure |

| From Feature Map | Extract For PROJECT_RULES.md |
|------------------|------------------------------|
| Technology choices | Technical Stack (primary source) |
| Feature groupings | Project Structure / Module organization |
| Feature relationships | Domain Entities relationships |
| Dependencies between features | Integration patterns |
| Complexity indicators | Architecture decisions |

#### Generate PROJECT_RULES.md

```yaml
Create tool:
  file_path: "docs/PROJECT_RULES.md"
  content: |
    # Project Rules
    
    > Auto-generated from PM documents (PRD/TRD/Feature Map).
    > Review and update as needed.
    
    ## Project Overview
    
    [From PRD: Problem statement, product vision]
    
    ## Domain Terminology
    
    | Term | Definition |
    |------|------------|
    [From PRD: Domain entities, concepts mentioned]
    [From Feature Map: Feature names and their relationships]
    
    ## Business Rules
    
    [From PRD: Explicit business rules, constraints, validations]
    
    ## Technical Stack
    
    [From Feature Map: Technology choices - PRIMARY SOURCE]
    [From TRD: Languages, frameworks, databases - supplementary]
    
    ## Architecture Patterns
    
    [From TRD: Architecture decisions, patterns chosen]
    [From Feature Map: Complexity indicators, feature dependencies]
    
    ## Project Structure
    
    [From Feature Map: Feature groupings - PRIMARY SOURCE]
    [From TRD: Component/module organization]
    
    ## Database Patterns
    
    [From TRD: Database design, schema patterns]
    
    ## External Integrations
    
    [From TRD: APIs, external services, message queues]
    [From Feature Map: Feature dependencies on external systems]
    
    ---
    
    *Generated from: [PRD path], [TRD path], [Feature Map path]*
    *Generated: [ISO timestamp]*
```

#### Check for Missing Information

If any section is empty or incomplete, ask supplementary questions:

| Missing Section | Supplementary Question |
|-----------------|------------------------|
| Domain Terminology | "What are the main entities/concepts in your domain?" |
| Business Rules | "What are the key business rules or constraints?" |
| Architecture Patterns | "What architecture pattern will you follow?" |
| External Integrations | "Are there any external systems to integrate with?" |

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
| "Just skip this, I'll create PM docs later" | "PM documents are REQUIRED for new projects. Without them, agents cannot understand your project's domain, business rules, or technical requirements. Run `/pre-dev-full` or `/pre-dev-feature` first." |
| "I don't need formal documents" | "PM documents are the source of truth for PROJECT_RULES.md. Development cannot start without documented requirements." |
| "This is just a quick prototype" | "Even prototypes need clear requirements. `/pre-dev-feature` takes ~30 minutes and prevents hours of rework." |
| "I already explained what I want verbally" | "Verbal explanations cannot be used by agents. Requirements MUST be documented in PRD/TRD/Feature Map files." |
| "It's a legacy project but skip the questions" | "The legacy analysis (agents + 4 questions) is the only way I can understand your project. It takes ~5 minutes and enables me to help you effectively." |
| "I'll fill in PROJECT_RULES.md myself" | "That works! Create `docs/PROJECT_RULES.md` with at least: Project Overview, Technical Stack, and Business Domain. Then run `/dev-cycle` again." |

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

7. **⛔ SAVE STATE TO FILE (MANDATORY):**
   ```yaml
   Write tool:
     file_path: "docs/refactor/current-cycle.json"
     content: [full updated state JSON]
   ```
   See "State Persistence Rule" section. State MUST be written to file after Gate 0.

8. Proceed to Gate 1

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

```text
For current execution unit:

1. Record gate start timestamp
2. Check if unit requires DevOps work:
   - Infrastructure changes?
   - New service deployment?

3. If DevOps needed:
   Task tool:
     subagent_type: "devops-engineer"
     prompt: |
       Review and update infrastructure for: [unit_id]

       Implementation changes:
       [implementation_artifacts]

       Check:
       - Dockerfile updates needed?
       - docker-compose updates needed?
       - Helm chart updates needed?
       - Environment variables?

       Report: changes made, deployment notes.

4. If DevOps not needed:
   - Mark as "skipped" with reason
   - agent_outputs.devops = null

5. If DevOps executed:
   - agent_outputs.devops = {
       agent: "devops-engineer",
       output: "[full agent output for feedback analysis]",
       timestamp: "[ISO timestamp]",
       duration_ms: [execution time]
     }

6. Update state
7. **⛔ SAVE STATE TO FILE (MANDATORY):**
   Write tool → "docs/refactor/current-cycle.json"
   See "State Persistence Rule" section.

8. Proceed to Gate 2
```

## Step 4: Gate 2 - SRE (Per Execution Unit)

**REQUIRED SUB-SKILL:** Use dev-sre

```text
For current execution unit:

1. Record gate start timestamp
2. Check if unit requires SRE observability:
   - New service or API?
   - External dependencies added?
   - Performance-critical changes?

3. If SRE needed:
   Task tool:
     subagent_type: "sre"
     prompt: |
       Validate observability for: [unit_id]

       Service Information:
       - Language: [Go/TypeScript/Python]
       - Service type: [API/Worker/Batch]
       - External dependencies: [list]
       - Implementation from Gate 0: [summary of what was implemented]

       Validation Requirements:
       - Verify structured JSON logging with trace correlation
       - Verify OpenTelemetry tracing (if external calls)

       Report: validation results with PASS/FAIL for each component (logging, tracing), issues found by severity, verification commands executed.

4. If SRE not needed:
   - Mark as "skipped" with reason
   - agent_outputs.sre = null

5. If SRE executed:
   - agent_outputs.sre = {
       agent: "sre",
       output: "[full agent output for feedback analysis]",
       timestamp: "[ISO timestamp]",
       duration_ms: [execution time]
     }

6. Update state
7. **⛔ SAVE STATE TO FILE (MANDATORY):**
   Write tool → "docs/refactor/current-cycle.json"
   See "State Persistence Rule" section.

8. Proceed to Gate 3
```

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
         timestamp: "[ISO timestamp]"
       },
       business_logic_reviewer: {
         agent: "business-logic-reviewer",
         output: "[full output for feedback analysis]",
         timestamp: "[ISO timestamp]"
       },
       security_reviewer: {
         agent: "security-reviewer",
         output: "[full output for feedback analysis]",
         timestamp: "[ISO timestamp]"
       }
     }
5. Aggregate findings by severity:
   - Critical/High/Medium: Must fix
   - Low: Add TODO(review): comment
   - Cosmetic: Add FIXME(nitpick): comment

6. If Critical/High/Medium issues found:
   - Dispatch fix to implementation agent
   - Re-run all 3 reviewers in parallel
   - Increment metrics.review_iterations
   - Repeat until clean (max 3 iterations)

7. When all issues resolved:
   - Update state
   - Proceed to Gate 5
```

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
