---
name: dev-design
description: |
  Gate 2 of the development cycle. Creates detailed technical design for implementation
  based on task definition and codebase analysis. Produces architecture decisions,
  interface definitions, and an ordered implementation checklist. Follows project
  methodology defined in docs/STANDARDS.md (DDD, Clean Architecture, etc.).

trigger: |
  - Gate 2 of development cycle
  - Task and analysis report available from Gates 0-1
  - Need technical design before implementation

skip_when: |
  - No task definition exists (need Gate 0 first)
  - No analysis report exists (need Gate 1 first)
  - Simple bug fix with obvious solution
  - Already have technical design document

sequence:
  after: [dev-analysis]
  before: [dev-implementation]

related:
  complementary: [writing-plans, dev-implementation]
  similar: [pre-dev-trd-creation]
---

# Technical Design (Gate 2)

## Overview

This skill creates a detailed technical design document for implementation. It synthesizes:
- Task definition from Gate 0
- Analysis report from Gate 1
- PRD/TRD from pre-dev (if available)
- **Project methodology from docs/STANDARDS.md** (DDD, Clean Architecture, etc.)

The output guides developers through implementation with clear architecture decisions and an ordered checklist.

**Note:** Design methodology (DDD, Clean Architecture, etc.) is defined in `docs/STANDARDS.md`. The planning agent (`ring-default:write-plan`) will apply the appropriate patterns based on project configuration.

---

## Prerequisites

Before starting Gate 2:

1. **Gate 0 Complete**: Task definition exists with clear scope
2. **Gate 1 Complete**: Analysis report with:
   - Selected agent type (backend-engineer-golang, frontend-engineer-typescript, etc.)
   - Identified patterns and conventions
   - Files to create/modify
3. **Optional**: PRD/TRD from `docs/pre-dev/{feature}/`

## Step 1: Gather Context

Collect all inputs for design:

```
Required inputs:
- Task definition (Gate 0 output)
- Analysis report (Gate 1 output)
- Selected agent: {agent from Gate 1}

Optional inputs:
- docs/pre-dev/{feature}/PRD.md
- docs/pre-dev/{feature}/TRD.md
- docs/STANDARDS.md (project standards)
```

**Verify prerequisites:**
- [ ] Task has clear acceptance criteria
- [ ] Analysis identifies technology stack
- [ ] Agent type is selected

## Step 2: Dispatch Planning Agent

Dispatch `ring-default:write-plan` with comprehensive context:

```
Task tool:
  subagent_type: "ring-default:write-plan"
  model: "opus"
  prompt: |
    Create a technical implementation plan for the following task.

    ## Task Definition
    {paste task from Gate 0}

    ## Analysis Report
    {paste analysis from Gate 1}

    ## PRD/TRD (if available)
    {paste PRD/TRD content or "Not available"}

    ## Project Standards
    {paste docs/STANDARDS.md content or summarize conventions from analysis}

    ## Requirements for the Plan

    1. **Architecture Section:**
       - Component diagram (text-based)
       - Data flow description
       - Integration points with existing code

    2. **Interface Definitions:**
       - Types/interfaces to create
       - API contracts (if applicable)
       - Database schema changes (if applicable)

    3. **Implementation Checklist:**
       - Ordered list of bite-sized tasks (2-5 min each)
       - Each task specifies:
         - Exact files to create/modify
         - Dependencies on previous tasks
         - Verification step

    4. **Acceptance Criteria Mapping:**
       - Map each acceptance criterion to implementation task
       - Ensure full coverage

    5. **Code Review Checkpoints:**
       - Insert after every 3-5 tasks
       - Use ring-default:requesting-code-review skill

    Save the plan to: docs/plans/YYYY-MM-DD-{feature-name}.md
```

## Step 3: Validate Design Document

After `ring-default:write-plan` completes, verify the plan:

**Completeness Check:**
- [ ] Goal statement is clear and measurable
- [ ] Architecture section explains component relationships
- [ ] Tech stack matches analysis report
- [ ] All interfaces/types are fully defined
- [ ] Implementation checklist is ordered correctly
- [ ] Each task has exact file paths
- [ ] Code review checkpoints are included
- [ ] All acceptance criteria are covered

**Zero-Context Test:**
- [ ] Can be executed by someone unfamiliar with codebase
- [ ] No references to "existing pattern" without explanation
- [ ] All commands include expected output
- [ ] Failure recovery steps are present

## Step 4: Document Design Decisions

Add design decisions rationale to the plan:

```markdown
## Design Decisions

### Decision 1: [Title]
**Context:** [Why this decision was needed]
**Options Considered:**
1. [Option A] - Pros/Cons
2. [Option B] - Pros/Cons
**Decision:** [Chosen option]
**Rationale:** [Why this option was selected]

### Decision 2: [Title]
...
```

Include decisions about:
- Architecture approach (layered, hexagonal, etc.)
- State management strategy
- Error handling patterns
- Testing approach
- API design choices

## Step 5: Prepare Handoff to Gate 3

Package the following for Gate 3 (Implementation):

```markdown
## Gate 2 Handoff

**Plan Location:** docs/plans/YYYY-MM-DD-{feature-name}.md

**Selected Implementation Agent:** ring-dev-team:{agent-from-gate-1}

**Implementation Approach:**
- [ ] Subagent-driven (current session, fresh agent per task)
- [ ] Parallel session (new session with executing-plans skill)

**First Implementation Task:**
{Summary of Task 1 from the plan}

**Key Files to Create:**
- {file 1}
- {file 2}

**Key Files to Modify:**
- {file 1:lines}
- {file 2:lines}
```

## Design Document Structure

The technical design document follows `ring-default:write-plan` output format:

```markdown
# [Feature Name] Implementation Plan

> **For Agents:** REQUIRED SUB-SKILL: Use ring-default:executing-plans to implement this plan task-by-task.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

**Global Prerequisites:**
- Environment: [OS, runtime versions]
- Tools: [Commands to verify]
- Access: [API keys, services]
- State: [Branch, setup requirements]

---

## Design Decisions
[From Step 4]

---

### Task 1: [Component Name]

**Files:**
- Create: `exact/path/to/file.ext`
- Modify: `exact/path/to/existing.ext:lines`
- Test: `tests/path/to/test.ext`

**Steps:**
1. Write failing test
2. Run test to verify failure
3. Implement minimal code
4. Run test to verify pass
5. Commit

**Failure Recovery:**
[Standard recovery steps]

---

### Task 2: ...

---

### Task N: Run Code Review
[Code review checkpoint using ring-default:requesting-code-review]

---
```

## Integration with Pre-Dev Documents

If PRD/TRD exist from pre-dev workflow:

```
PRD provides:
- User stories and acceptance criteria
- Business context and constraints
- Success metrics

TRD provides:
- Technical approach
- System components
- Integration requirements
- Performance requirements

Use these to:
1. Validate task scope against PRD requirements
2. Align architecture with TRD decisions
3. Ensure implementation covers all acceptance criteria
```

## Common Design Patterns

Reference patterns based on analysis (Gate 1) and project STANDARDS.md:

**Backend (Go):**
- Hexagonal architecture (ports/adapters)
- Repository pattern for data access
- Command/Query handlers for CQRS
- Middleware chain for HTTP

**Backend (TypeScript):**
- Layered architecture (controller/service/repository)
- Dependency injection (NestJS or manual)
- DTO validation with class-validator or Zod

**Backend (Python):**
- MVC/MVT pattern (FastAPI/Django)
- Pydantic models for validation
- SQLAlchemy for ORM

**Frontend (TypeScript):**
- Component composition
- Custom hooks for logic
- Type-safe API clients

**Note:** If project uses DDD, Clean Architecture, or other methodologies, these are defined in `docs/STANDARDS.md` and the implementation agent will apply them.

## Anti-Patterns to Avoid

1. **Vague architecture:** "Use standard patterns" - specify exact patterns
2. **Missing interfaces:** Always define types/interfaces before implementation
3. **Large tasks:** Break into 2-5 minute steps
4. **Skipping tests:** Every task should have test-first approach
5. **Missing dependencies:** Clearly state task order and prerequisites
6. **No review checkpoints:** Include code review after every 3-5 tasks

## Execution Report

| Metric | Value |
|--------|-------|
| Duration | Xm Ys |
| Iterations | N |
| Result | PASS/FAIL/PARTIAL |

### Details
- plan_location: docs/plans/YYYY-MM-DD-{feature}.md
- task_count: N
- review_checkpoints: N
- acceptance_criteria_coverage: N/N
- selected_agent: ring-dev-team:{agent}

### Issues Encountered
- List any issues or "None"

### Handoff to Next Gate
- Plan document location
- Selected implementation agent
- First task summary
- Recommended execution approach (subagent-driven or parallel session)
