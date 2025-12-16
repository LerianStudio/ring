---
name: pre-dev-task-breakdown
description: |
  Gate 7: Implementation tasks - value-driven decomposition into working increments
  that deliver measurable user value.

trigger: |
  - PRD passed Gate 1 (required)
  - TRD passed Gate 3 (required)
  - All Large Track gates passed (if applicable)
  - Ready to create sprint/iteration tasks

skip_when: |
  - PRD or TRD not validated → complete earlier gates
  - Tasks already exist → proceed to Subtask Creation
  - Trivial change → direct implementation

sequence:
  after: [pre-dev-trd-creation, pre-dev-dependency-map]
  before: [pre-dev-subtask-creation, executing-plans]
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
| **2. Decomposition** | Per component/feature: define deliverable, set success criteria, map dependencies, estimate effort (S/M/L/XL max=2 weeks), plan testing, identify risks |
| **3. Gate 7 Validation** | All TRD components covered; every task delivers working software; measurable success criteria; correct dependencies; no task >2 weeks; testing strategy defined; risks with mitigations; delivery sequence optimizes value |

## Explicit Rules

### ✅ DO Include in Tasks
Task ID, title, type (Foundation/Feature/Integration/Polish), deliverable (what ships), user value (what users can do), technical value (what it enables), success criteria (testable/measurable), dependencies (blocks/requires/optional), effort estimate (S/M/L/XL with points), testing strategy, risk identification with mitigations, Definition of Done checklist

### ❌ NEVER Include in Tasks
Implementation details (file paths, code examples), step-by-step instructions (those go in subtasks), technical-only tasks with no user value, tasks exceeding 2 weeks (break them down), vague success criteria ("improve performance"), missing dependency information, undefined testing approach

### Task Sizing Rules

| Size | Points | Duration | Scope |
|------|--------|----------|-------|
| Small (S) | 1-3 | 1-3 days | Single component |
| Medium (M) | 5-8 | 3-5 days | Few dependencies |
| Large (L) | 13 | 1-2 weeks | Multiple components |
| XL (>2 weeks) | BREAK IT DOWN | Too large | Not atomic |

### Value Delivery Rules
- **Foundation**: Enables other work (database setup, core services)
- **Feature**: Delivers user-facing capabilities
- **Integration**: Connects to external systems
- **Polish**: Optimizes or enhances (nice-to-have)

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

**Gate Result:** ✅ PASS → Subtasks | ⚠️ CONDITIONAL (refine oversized/vague) | ❌ FAIL (re-decompose)

## Task Template Structure

Output to `docs/pre-dev/{feature-name}/tasks.md`. Each task includes:

| Section | Content |
|---------|---------|
| **Header** | T-[XXX]: [Task Title - What It Delivers] |
| **Deliverable** | One sentence: what working software ships |
| **Scope** | Includes (specific capabilities), Excludes (future tasks with IDs) |
| **Success Criteria** | Testable items: Functional, Technical, Operational, Quality |
| **User/Technical Value** | What users can do; what this enables |
| **Technical Components** | From TRD, From Dependencies |
| **Dependencies** | Blocks (T-AAA), Requires (T-BBB), Optional (T-CCC) |
| **Effort Estimate** | Size (S/M/L/XL), Points, Duration, Team type |
| **Risks** | Per risk: Impact, Probability, Mitigation, Fallback |
| **Testing Strategy** | Unit, Integration, E2E, Performance, Security |
| **Definition of Done** | Code reviewed, tests passing, docs updated, security clean, performance met, deployed to staging, PO acceptance, monitoring configured |

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

**Output to:** `docs/pre-dev/{feature-name}/tasks.md`

1. ✅ Tasks become sprint backlog
2. 🎯 Use as input for subtasks (`pre-dev-subtask-creation`)
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
