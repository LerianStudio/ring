---
name: pre-dev-task-breakdown
description: |
  Gate 7: Implementation tasks - value-driven decomposition into working increments
  that deliver measurable user value.
metadata:
  sequence:
    after:
    - ring:pre-dev-trd-creation
    - ring:pre-dev-dependency-map
    before:
    - ring:pre-dev-subtask-creation
    - ring:executing-plans
  skip_when: |
    - PRD or TRD not validated → complete earlier gates
    - Tasks already exist → proceed to Subtask Creation
    - Trivial change → direct implementation
  trigger: |
    - PRD passed Gate 1 (required)
    - TRD passed Gate 3 (required)
    - All Large Track gates passed (if applicable)
    - Ready to create sprint/iteration tasks
---

# Task Breakdown - Value-Driven Decomposition

## Foundational Principle

**Every task must deliver working software that provides measurable user value.**

Creating technical-only or oversized tasks creates:
- Work that doesn't ship until "everything is done"
- Teams working on pieces that don't integrate
- No early validation of value or technical approach
- Waterfall development disguised as iterative process

**Tasks answer**: What working increment will be delivered?
**Tasks never answer**: How to implement that increment (that's Subtasks).

## Mandatory Workflow

| Phase | Activities |
|-------|------------|
| **1. Task Identification** | Load PRD (Gate 1, required), TRD (Gate 3, required); optional: Feature Map, API Design, Data Model, Dependency Map; identify value streams |
| **2. Decomposition** | Per component/feature: define deliverable, set success criteria, map dependencies, estimate effort via AI analysis (max 16 AI-agent-hours), plan testing, identify risks |
| **3. Gate 7 Validation** | All TRD components covered; every task delivers working software; measurable success criteria; correct dependencies; no task >2 weeks; testing strategy defined; risks with mitigations; delivery sequence optimizes value |

## Explicit Rules

### ✅ DO Include in Tasks
Task ID, title, type (Foundation/Feature/Integration/Polish), deliverable (what ships), user value (what users can do), technical value (what it enables), success criteria (testable/measurable), dependencies (blocks/requires/optional), effort estimate (AI-agent-hours with confidence), testing strategy, risk identification with mitigations, Definition of Done checklist

### ❌ NEVER Include in Tasks
Implementation details (file paths, code examples), step-by-step instructions (those go in subtasks), technical-only tasks with no user value, tasks exceeding 2 weeks (break them down), vague success criteria ("improve performance"), missing dependency information, undefined testing approach

### Task Sizing Rules

| Size | AI-agent-hours | Calendar Duration* | Scope |
|------|----------------|-------------------|-------|
| Small (S) | 1-4h | 1-2 days | Single component |
| Medium (M) | 4-8h | 2-4 days | Few dependencies |
| Large (L) | 8-16h | 1-2 weeks | Multiple components |
| XL (>16h) | BREAK IT DOWN | Too large | Not atomic |

*Calendar duration assumes 1.5x multiplier (standard validation), 90% capacity, and 1 developer

### Value Delivery Rules
- **Foundation**: Enables other work (database setup, core services)
- **Feature**: Delivers user-facing capabilities
- **Integration**: Connects to external systems
- **Polish**: Optimizes or enhances (nice-to-have)

## AI-Assisted Time Estimation

**See [shared-patterns/ai-agent-baseline.md](../shared-patterns/ai-agent-baseline.md) for baseline definition.**

After defining task scope and success criteria, the system automatically estimates implementation time.

### Estimation Process

1. **Tech Stack Detection:** Identify project type from TRD
   - Go project → dispatch ring:backend-engineer-golang
   - TypeScript Backend → dispatch ring:backend-engineer-typescript
   - React/Next.js → dispatch ring:frontend-engineer
   - Mixed/Unknown → dispatch ring:codebase-explorer

2. **Scope Analysis:** Specialized agent analyzes:
   - Technical components (endpoints, schemas, services)
   - Complexity level (CRUD vs custom algorithms)
   - Available libraries (lib-commons, frameworks)
   - Test requirements (coverage %, test types)
   - Documentation requirements

3. **Time Calculation:** Agent estimates per scope item
   - Database schema + migrations
   - Repository/data layer
   - Business logic layer
   - API handlers/controllers
   - Validation logic
   - Error handling
   - Unit tests (TDD)
   - Integration tests
   - Documentation

4. **Output:** Total in AI-agent-hours

**For detailed baseline definition and capacity explanation, see [shared-patterns/ai-agent-baseline.md](../shared-patterns/ai-agent-baseline.md).**

### Confidence Levels

| Level | Criteria | Example |
|-------|----------|---------|
| **High** | Standard patterns, libs available, clear scope | CRUD API with lib-commons |
| **Medium** | Some custom logic, partial lib support | Payment integration |
| **Low** | Novel algorithms, no lib support, vague scope | ML feature, R&D work |

### Example Output

```markdown
**Effort Estimate:**
- **Baseline:** AI Agent via ring:dev-cycle
- **AI Estimate:** 4.5 AI-agent-hours
- **Estimation Method:** ring:backend-engineer-golang analysis
- **Confidence:** High (standard CRUD, lib-commons available)

**Breakdown:**
- Database schema + migrations: 0.5h
- Repository layer (CRUD): 0.5h
- Service layer (business logic): 0.5h
- HTTP handlers (4 endpoints): 1.0h
- Input validation: 0.3h
- Error handling: 0.2h
- Unit tests (TDD, 85% coverage): 0.8h
- Integration tests: 0.5h
- OpenAPI documentation: 0.2h
**Total: 4.5 AI-agent-hours**

**Assumptions:**
- lib-commons/http, lib-commons/postgres, lib-commons/validator available
- Standard CRUD patterns (no complex algorithms)
- PostgreSQL database configured
- ring:dev-cycle will execute implementation

**Team Type:** Backend Engineer (Go)
```

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "This 3-week task is fine" | Tasks >2 weeks hide complexity. Break it down. |
| "Setup tasks don't need value" | Setup enables value. Define what it enables. |
| "Success criteria are obvious" | Obvious to you ≠ testable. Document explicitly. |
| "Dependencies will be clear later" | Later is too late. Map them now. |
| "We don't need detailed estimates" | Without estimates, no planning possible. Size them. |
| "Technical tasks can skip user value" | Even infrastructure enables users. Define the connection. |
| "Testing strategy can be decided during" | Testing affects design. Plan it upfront. |
| "Risks aren't relevant at task level" | Risks compound across tasks. Identify them early. |
| "DoD is the same for all tasks" | Different tasks need different criteria. Specify. |
| "We can combine multiple features" | Combining hides value delivery. Keep tasks focused. |
| "Skip AI estimation, use story points" | Story points are abstract, AI hours are concrete | **MUST run AI estimation for all tasks** |
| "Manual estimate is faster" | Fast ≠ accurate. AI analyzes full scope consistently | **MUST use AI analysis, not guesses** |
| "AI estimate too low, inflate it" | Inflation happens in multiplier (Gate 9), not here | **MUST report AI estimate as-is** |
| "Confidence is always High" | Confidence reflects scope clarity and complexity | **MUST assess confidence honestly** |
| "Skip breakdown, just give total" | Breakdown enables validation and learning | **MUST provide detailed breakdown** |
| "AI can't estimate this, too complex" | Complex = lower confidence, not impossible | **MUST attempt estimate, flag low confidence** |

## Red Flags - STOP

If you catch yourself writing any of these in a task, **STOP**:

- Task estimates over 2 weeks
- Tasks named "Setup X" without defining what X enables
- Success criteria like "works" or "complete" (not measurable)
- No dependencies listed (every task depends on something)
- No testing strategy (how will you verify?)
- "Technical debt" as a task type (debt reduction must deliver value)
- Vague deliverables ("improve", "optimize", "refactor")
- Missing Definition of Done

**When you catch yourself**: Refine the task until it's concrete, valuable, and testable.

## Gate 7 Validation Checklist

| Category | Requirements |
|----------|--------------|
| **Task Completeness** | All TRD components have tasks; all PRD features have tasks; each task appropriately sized (no XL+); task boundaries clear |
| **Delivery Value** | Every task delivers working software; user value explicit; technical value clear; sequence optimizes value |
| **Technical Clarity** | Success criteria measurable/testable; dependencies correctly mapped; testing approach defined; DoD comprehensive |
| **Team Readiness** | Skills match capabilities; estimates realistic; capacity available; handoffs minimized |
| **Risk Management** | Risks identified per task; mitigations defined; high-risk tasks scheduled early; fallback plans exist |
| **Multi-Module** (if applicable) | All tasks have `target:` field; all tasks have `working_directory:`; per-module files generated (if doc_organization: per-module) |

**Gate Result:** ✅ PASS → Subtasks | ⚠️ CONDITIONAL (refine oversized/vague) | ❌ FAIL (re-decompose)

## Multi-Module Task Tagging

**If TopologyConfig exists in research.md frontmatter** (from Gate 0):

### Read Topology Configuration

```yaml
# From research.md frontmatter
topology:
  scope: fullstack
  structure: monorepo | multi-repo
  modules:
    backend:
      path: packages/api
      language: golang
    frontend:
      path: packages/web
      framework: nextjs
  doc_organization: unified | per-module
```

### Task Target Assignment

Each task MUST have `target:` and `working_directory:` fields when topology is multi-module.

**Agent assignment depends on both `target` and `api_pattern`:**

| Target | API Pattern | Task Type | Agent |
|--------|-------------|-----------|-------|
| `backend` | any | API endpoints, services, data layer, CLI | `ring:backend-engineer-golang` or `ring:backend-engineer-typescript` |
| `frontend` | `direct` | UI components, pages, forms, Server Components | `ring:frontend-engineer` |
| `frontend` | `direct` | Server Actions, data fetching hooks | `ring:frontend-engineer` |
| `frontend` | `bff` | API routes, data aggregation, transformation | `ring:frontend-bff-engineer-typescript` |
| `frontend` | `bff` | UI components, pages, forms | `ring:frontend-engineer` |
| `shared` | any | CI/CD, configs, docs, cross-module utilities | DevOps or general |

### How to Determine Agent for Frontend Tasks

**Read `api_pattern` from research.md frontmatter:**

```yaml
# From research.md
topology:
  scope: fullstack
  api_pattern: direct | bff | other
```

**Decision Flow:**

```
Is task target: frontend?
├─ NO → Use backend-engineer-* based on language
└─ YES → Check api_pattern
    ├─ direct → ALL frontend tasks use frontend-engineer
    └─ bff → Split tasks:
        ├─ API routes, aggregation, transformation → frontend-bff-engineer-typescript
        └─ UI components, pages, forms → frontend-engineer
```

### Task Format with Agent Assignment

```markdown
## T-003: User Login API Endpoint

**Target:** backend
**Working Directory:** packages/api
**Agent:** ring:backend-engineer-golang

**Deliverable:** Working login API that validates credentials and returns JWT token.

...rest of task...
```

```markdown
## T-004: User Dashboard Data Aggregation

**Target:** frontend
**Working Directory:** packages/web
**Agent:** ring:frontend-bff-engineer-typescript  # Because api_pattern: bff

**Deliverable:** BFF endpoint that aggregates user profile, recent activity, and notifications.

...rest of task...
```

```markdown
## T-005: User Dashboard UI

**Target:** frontend
**Working Directory:** packages/web
**Agent:** ring:frontend-engineer  # UI task, even with BFF pattern

**Deliverable:** Dashboard page component consuming aggregated data from BFF.

...rest of task...
```

### Validation for Agent Assignment

| Check | Requirement |
|-------|-------------|
| All tasks have `Agent:` field | MANDATORY |
| Agent matches api_pattern rules | If frontend + bff → check task type |
| BFF tasks clearly separated | Data aggregation vs UI clearly split |
| No mixed responsibilities | One task = one agent |

### Per-Module Output

**Document placement depends on topology.structure:**

#### Single-Repo

All tasks in one file:
```
docs/pre-dev/{feature}/
└── tasks.md           # All tasks with target tags
```

#### Monorepo (per-module placement)

Index at root, filtered tasks in module directories:
```
docs/pre-dev/{feature}/
└── tasks.md           # Index with ALL tasks (target tags included)

{backend.path}/docs/pre-dev/{feature}/
└── tasks.md           # Backend tasks only (target: backend)

{frontend.path}/docs/pre-dev/{feature}/
└── tasks.md           # Frontend tasks only (target: frontend)
```

#### Multi-Repo (distributed placement)

Tasks distributed to respective repositories:
```
{backend.path}/docs/pre-dev/{feature}/
└── tasks.md           # Backend tasks only

{frontend.path}/docs/pre-dev/{feature}/
└── tasks.md           # Frontend tasks only
```

**Note:** For multi-repo, there is no central index. Each repo contains only its relevant tasks.

### Task Splitting Logic

```python
def split_tasks_by_module(all_tasks: list, topology: dict) -> dict:
    """
    Split tasks into module-specific files.

    Returns dict with keys: 'index', 'backend', 'frontend'
    """
    structure = topology.get('structure', 'single-repo')
    modules = topology.get('modules', {})
    backend_path = modules.get('backend', {}).get('path', '.')
    frontend_path = modules.get('frontend', {}).get('path', '.')

    backend_tasks = [t for t in all_tasks if t.get('target') == 'backend']
    frontend_tasks = [t for t in all_tasks if t.get('target') == 'frontend']
    shared_tasks = [t for t in all_tasks if t.get('target') == 'shared']

    if structure == 'single-repo':
        return {
            'index': {
                'path': f"docs/pre-dev/{feature}/tasks.md",
                'tasks': all_tasks
            }
        }

    if structure == 'monorepo':
        return {
            'index': {
                'path': f"docs/pre-dev/{feature}/tasks.md",
                'tasks': all_tasks
            },
            'backend': {
                'path': f"{backend_path}/docs/pre-dev/{feature}/tasks.md",
                'tasks': backend_tasks + shared_tasks
            },
            'frontend': {
                'path': f"{frontend_path}/docs/pre-dev/{feature}/tasks.md",
                'tasks': frontend_tasks + shared_tasks
            }
        }

    if structure == 'multi-repo':
        return {
            'backend': {
                'path': f"{backend_path}/docs/pre-dev/{feature}/tasks.md",
                'tasks': backend_tasks + shared_tasks
            },
            'frontend': {
                'path': f"{frontend_path}/docs/pre-dev/{feature}/tasks.md",
                'tasks': frontend_tasks + shared_tasks
            }
        }
```

### Module-Specific Task File Header

Each module-specific tasks.md should include:

```markdown
---
feature: {feature-name}
module: backend | frontend
filtered_from: docs/pre-dev/{feature}/tasks.md  # (monorepo only)
total_tasks: N
---

# {Feature Name} - {Module} Tasks

This file contains tasks filtered for the **{module}** module.

**Full task list:** {link to index if monorepo, or note "distributed" if multi-repo}

---
```

### Validation for Multi-Module

| Check | Requirement |
|-------|-------------|
| All tasks have `target:` | If topology is monorepo or multi-repo |
| All tasks have `working_directory:` | If topology is monorepo or multi-repo |
| Target matches task content | Backend tasks have backend work, etc. |
| Working directory resolves correctly | Path exists or will be created |

---

## Task Template Structure

Output path depends on topology — see [Output & After Approval](#output--after-approval) for the full topology-dependent rules. The file starts with two summary sections followed by the full task details.

### File Summary Sections (top of tasks.md)

MUST open with two summary tables before the individual task details.

#### Summary Table 1 — Technical Overview

A quick-reference table for the engineering team. The `Status` column is initialized by `ring:pre-dev-task-breakdown` and updated by `ring:dev-cycle` during execution.

- CANNOT set any value other than `⏸️ Pending` at task creation time

```markdown
## Summary

| Task | Title | Type | Hours | Confidence | Blocks | Status |
|------|-------|------|-------|------------|--------|--------|
| T-001 | Project Foundation | Foundation | 3.0 | High | All | ⏸️ Pending |
| T-002 | ... | Feature | 6.5 | Medium | T-004, T-008 | ⏸️ Pending |
| | **TOTAL** | | **85.0h** | | | |
```

MUST leave the Status cell of the TOTAL row empty. CANNOT apply `⏸️ Pending` or any status value to the TOTAL row.

**Status lifecycle (managed by `ring:dev-cycle`):**

| Value | Meaning | Set by |
|-------|---------|--------|
| `⏸️ Pending` | Not started | `ring:pre-dev-task-breakdown` at task creation |
| `🔄 Doing` | Execution started (Gate 0 began) | `ring:dev-cycle` |
| `✅ Done` | Gate 9 approved | `ring:dev-cycle` |
| `❌ Failed` | Execution terminated with unresolved blocker | `ring:dev-cycle` |

#### Summary Table 2 — Business Deliverables View

MUST appear immediately after Summary Table 1. A plain-language view for product managers, stakeholders, and the team to understand **what value each task delivers**.

```markdown
## Business Deliverables

| Task | Deliverable (business view) |
|------|-----------------------------|
| T-001 | The team can develop and test locally from day one — **every contributor gets a working environment without manual setup**. |
| T-002 | **Transactions reach their destination** — messages conform to the agreed standard and counterparties accept every one sent. |
| ... | _(additional tasks omitted for brevity)_ |
```

**Writing rules for Business Deliverables View:**

| Rule | Correct | Wrong |
|------|---------|-------|
| **Language** | Plain business language | Technical jargon (endpoints, migrations, repositories) |
| **Perspective** | What the business/user gains | What the developer implements |
| **Voice** | Active — "The product can...", "Users gain..." | Passive — "It is implemented...", "It will be created..." |
| **Length** | 1-3 sentences max | Bullet lists, long paragraphs |
| **Emphasis** | Bold the core value proposition | No bold or no emphasis at all |
| **Source** | Derived from each task's **Deliverable** field | Invented separately |

**What to include:**
- The capability unlocked ("The product can...", "Users can now...")
- Why it matters to the business ("Without this, no transaction reaches its destination")
- Who benefits (developer, operator, end user, regulator)
- Business consequence if missing (when relevant)

**What to exclude:**
- File names, class names, function names
- Architecture terms (API, REST, handler, service layer)
- Infrastructure terms (Docker, Kubernetes, PostgreSQL)
- Implementation verbs (implement, create endpoint, configure database)

**Validation for Business Deliverables View:**

| Check | Requirement |
|-------|-------------|
| Language | No technical jargon (no API, REST, handler, migration, repository) |
| Length | 1-3 sentences per row; no bullet lists |
| Voice | Active and capability-focused; no passive constructions |
| Source | Each row derived from the task's Deliverable field, not invented |
| Formatting | Core value proposition bolded; no other inline formatting |
| Exclusions | No file/class names, architecture terms, infrastructure terms, or implementation verbs |

---

### Per-Task Template

Each task includes:

| Section | Content |
|---------|---------|
| **Header** | T-[XXX]: [Task Title - What It Delivers] |
| **Target** | backend \| frontend \| shared (if multi-module) |
| **Working Directory** | Path from topology config (if multi-module) |
| **Agent** | Recommended agent: ring:backend-engineer-*, ring:frontend-*-engineer-*, etc. |
| **Deliverable** | One sentence: what working software ships |
| **Scope** | Includes (specific capabilities), Excludes (future tasks with IDs) |
| **Success Criteria** | Testable items: Functional, Technical, Operational, Quality |
| **User/Technical Value** | What users can do; what this enables |
| **Technical Components** | From TRD, From Dependencies |
| **Dependencies** | Blocks (T-AAA), Requires (T-BBB), Optional (T-CCC) |
| **Effort Estimate** | AI Estimate: X AI-agent-hours, Confidence: [High/Medium/Low], Estimation Method: [Agent Name], Team type |
| **Risks** | Per risk: Impact, Probability, Mitigation, Fallback |
| **Testing Strategy** | Unit, Integration, E2E, Performance, Security |
| **Definition of Done** | Code reviewed, tests passing, docs updated, security clean, performance met, deployed to staging, PO acceptance, monitoring configured |

### AI Estimation Fallback Procedure

**When AI estimation fails or is unavailable:**

#### Failure Conditions

AI estimation is considered failed when:
- ❌ Agent unreachable (API timeout >30s)
- ❌ API errors (rate limit exceeded, 500 errors)
- ❌ Service outage (Claude API down)
- ❌ Invalid response (no estimate returned)
- ❌ Scope too ambiguous (agent returns Low confidence with no estimate)

#### Escalation Path

1. **Immediate (0-5 min):** Retry once with exponential backoff
2. **Short-term (5-15 min):** Switch to backup agent if available
3. **Medium-term (15-30 min):** Notify PM team lead via Slack
4. **Long-term (30+ min):** Use manual estimation override (see below)

#### Manual Estimation Override

**Who can approve:** PM Team Lead or designated backup

**Required evidence for override:**
- Similar historical task with actual time data
- Expert estimation from technical lead (with rationale)
- Decomposed scope with per-component estimates
- Documentation of estimation method used

**How to record:**
```markdown
**Effort Estimate:**
- AI Estimate: [FAILED - API unavailable]
- Manual Override: X hours (approved by: [Name], date: YYYY-MM-DD)
- Estimation Method: Historical comparison with Task T-XXX
- Confidence: Medium (manual estimation, subject to higher variance)
- Evidence: [Link to similar task or rationale document]
```

#### Temporary Capacity Adjustments

**When manual estimation is used:**
- Apply **1.3x multiplier** to manual estimates (30% buffer for estimation uncertainty)
- Mark task with **"Estimation Pending"** flag in roadmap
- Schedule **re-estimation** when AI service restored
- Track variance post-completion to calibrate manual estimates

**Example:**
```
Manual estimate: 6 hours
Adjusted estimate: 6h × 1.3 = 7.8 hours
Confidence: Medium → Low (due to estimation method)
Re-estimation scheduled: [Date when AI available]
```

#### Confidence Flag Requirements

**Align with rationalization table:**
- ✅ Manual estimates MUST be marked with confidence level
- ✅ Include rationale for estimation method
- ✅ Link to historical data or expert judgment
- ✅ Document who approved and when
- ❌ NEVER mark manual estimates as "High" confidence
- ❌ NEVER skip variance tracking for manual estimates

## Common Violations

| Violation | Wrong | Correct |
|-----------|-------|---------|
| **Technical-Only Tasks** | "Setup PostgreSQL Database" with install/configure steps | "User Data Persistence Foundation" with deliverable (working DB layer <100ms), user value (enables T-002/T-003), success criteria (users table, pooling, migrations) |
| **Oversized Tasks** | "Complete User Management System" (6 weeks) with all auth features combined | Split into: T-005 Basic Auth (L), T-006 Password Mgmt (M), T-007 2FA (M), T-008 Permissions (L) |
| **Vague Success Criteria** | "Feature works, Tests pass, Code reviewed" | Functional (upload 100MB, formats), Technical (<2s response), Operational (99.5% success rate), Quality (90% coverage) |

## Delivery Sequencing

Optimize task order by sprint/phase with goals, critical path identification, and parallel work opportunities.

## Confidence Scoring

| Factor | Points | Criteria |
|--------|--------|----------|
| Task Decomposition | 0-30 | All appropriately sized: 30, Most well-scoped: 20, Too large/vague: 10 |
| Value Clarity | 0-25 | Every task delivers working software: 25, Most clear: 15, Unclear: 5 |
| Dependency Mapping | 0-25 | All documented: 25, Most clear: 15, Ambiguous: 5 |
| Estimation Quality | 0-20 | Based on past work: 20, Educated guesses: 12, Speculation: 5 |

**Action:** 80+ autonomous | 50-79 present options | <50 ask about velocity

## Output & After Approval

**Output to (depends on topology.structure):**

| Structure | Files Generated |
|-----------|-----------------|
| single-repo | `docs/pre-dev/{feature}/tasks.md` |
| monorepo | Index + `{backend.path}/docs/pre-dev/{feature}/tasks.md` + `{frontend.path}/docs/pre-dev/{feature}/tasks.md` |
| multi-repo | `{backend.path}/docs/pre-dev/{feature}/tasks.md` + `{frontend.path}/docs/pre-dev/{feature}/tasks.md` |

1. ✅ Tasks become sprint backlog
2. 🎯 Use as input for subtasks (`ring:pre-dev-subtask-creation`)
3. 📊 Track progress per task (not per subtask)
4. 🚫 No implementation yet - that's in subtasks

## The Bottom Line

**If you created tasks that don't deliver working software, rewrite them.**

Tasks are not technical activities. Tasks are working increments.

"Setup database" is not a task. "User data persists correctly" is a task.
"Implement OAuth" is not a task. "Users can log in with Google" is a task.
"Write tests" is not a task. Tests are part of Definition of Done for other tasks.

Every task must answer: **"What working software can I demo to users?"**

If you can't demo it, it's not a task. It's subtask implementation detail.

**Deliver value. Ship working software. Make tasks demoable.**

---

## Standards Loading (MANDATORY)

This skill is a task decomposition skill and does NOT require WebFetch of language-specific standards.

**Purpose:** Task Breakdown defines WHAT value increments to deliver, not HOW to implement them. Language-specific standards apply during subtask creation and implementation.

**However**, MUST load PRD (Gate 1), TRD (Gate 3), and research.md to ensure tasks align with requirements and architecture.

---

## Blocker Criteria - STOP and Report

| Condition | Action | Severity |
|-----------|--------|----------|
| PRD (Gate 1) not validated | STOP and complete Gate 1 first | CRITICAL |
| TRD (Gate 3) not validated | STOP and complete Gate 3 first | CRITICAL |
| Task exceeds 2 weeks (XL size) | STOP and break down further | HIGH |
| Task has no measurable success criteria | STOP and define testable criteria | HIGH |
| Task has no user or technical value | STOP and redefine as value delivery | HIGH |
| AI estimation failed | Follow fallback procedure in skill | MEDIUM |
| Dependencies form circular loop | STOP and resolve dependency cycle | HIGH |

---

## Cannot Be Overridden

These requirements are NON-NEGOTIABLE:

- MUST NOT create tasks exceeding 2 weeks (break them down)
- MUST include measurable success criteria for every task
- MUST include user value OR technical value for every task
- MUST include task dependencies (blocks, requires, optional)
- MUST run AI estimation for all tasks (no manual guesses)
- MUST include Definition of Done checklist for every task
- MUST include Business Deliverables View in summary section
- MUST initialize Status column as `⏸️ Pending` for every task row
- CANNOT set Status to any value other than `⏸️ Pending` at task creation
- CANNOT use technical-only tasks without value connection

---

## Severity Calibration

| Severity | Definition | Example |
|----------|------------|---------|
| **CRITICAL** | Cannot create valid tasks | PRD/TRD not validated, no requirements to decompose |
| **HIGH** | Task violates sizing or value rules | XL task, no success criteria, no value defined |
| **MEDIUM** | Task incomplete but usable | Missing one dependency, unclear testing strategy |
| **LOW** | Minor documentation gaps | Definition of Done could be more detailed |

---

## Pressure Resistance

| User Says | Your Response |
|-----------|---------------|
| "This 3-week task is fine" | "Cannot accept 3-week tasks. Tasks >2 weeks hide complexity. I'll break it into smaller deliverables." |
| "Setup tasks don't need user value" | "Cannot create valueless tasks. Setup ENABLES value. I'll define what this setup enables." |
| "Success criteria are obvious" | "Cannot assume obvious criteria. Obvious to you ≠ testable. I'll document explicit, measurable criteria." |
| "Skip AI estimation, use story points" | "Cannot skip AI estimation. Story points are abstract; AI hours are concrete. I'll run AI analysis." |
| "We can figure out dependencies later" | "Cannot defer dependencies. Later is too late. I'll map dependencies now." |

---

## Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "This 3-week task is fine" | Tasks >2 weeks hide complexity | **Break down into ≤2 week tasks** |
| "Setup tasks don't need value" | Setup enables value. Define what it enables | **Connect to user/technical value** |
| "Success criteria are obvious" | Obvious to you ≠ testable. Document explicitly | **Define measurable criteria** |
| "Dependencies will be clear later" | Later is too late. Map them now | **Document all dependencies** |
| "Skip AI estimation, use story points" | Story points are abstract; AI hours are concrete | **Run AI estimation** |
| "Technical tasks can skip user value" | Even infrastructure enables users. Define connection | **Connect to user impact** |
| "Testing strategy can be decided during" | Testing affects design. Plan it upfront | **Define testing strategy now** |

---

## When This Skill Is Not Needed

- PRD or TRD not validated (complete earlier gates first)
- Tasks already exist and are validated
- Trivial change that can be implemented directly
- Bug fix with known solution (no decomposition needed)
- Documentation-only updates
- Configuration changes with no implementation work
