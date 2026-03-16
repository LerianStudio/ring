---
name: writing-plans
description: |
  Creates comprehensive implementation plans with exact file paths, complete code
  examples, and verification steps for engineers with zero codebase context.
metadata:
  related:
    similar:
    - brainstorming
  sequence:
    after:
    - brainstorming
    - ring:pre-dev-trd-creation
    before:
    - ring:executing-plans
    - ring:subagent-driven-development
  skip_when: |
    - Design not validated → use brainstorming first
    - Requirements still unclear → use ring:pre-dev-prd-creation first
    - Already have a plan → use ring:executing-plans
  trigger: |
    - Design phase complete (brainstorming/PRD/TRD validated)
    - Need to create executable task breakdown
    - Creating work for other engineers or AI agents
---

# Writing Plans

## Overview

This skill dispatches a specialized agent to write comprehensive implementation plans for engineers with zero codebase context.

**Announce at start:** "I'm using the ring:writing-plans skill to create the implementation plan."

**Context:** This should be run in a dedicated worktree (created by ring:brainstorming skill).

## The Process

**Step 1: Dispatch Write-Plan Agent**

Dispatch via `Task(subagent_type: "ring:write-plan")` with:
- Instructions to create bite-sized tasks (2-5 min each)
- Include exact file paths, complete code, verification steps
- Save to `docs/plans/YYYY-MM-DD-<feature-name>.md`

**Step 2: Validate Plan**

After the plan is saved, validate it:

```bash
python3 default/lib/validate-plan-precedent.py docs/plans/YYYY-MM-DD-<feature>.md
```

**Interpretation:**
- `PASS` → Plan is safe to execute
- `WARNING` → Plan has issues to address
  - Review the warnings in the output
  - Update plan to address the issues
  - Re-run validation until PASS

**Step 3: Ask User About Execution**

Ask via `AskUserQuestion`: "Execute now?" Options:
1. Execute now → `ring:subagent-driven-development`
2. Parallel session → user opens new session with `ring:executing-plans`
3. Save for later → report location and end

## Why Use an Agent?

**Context preservation** (reading many files keeps supervisor clean) | **Model power** (comprehensive planning) | **Separation of concerns** (supervisor orchestrates, agent plans)

## What the Agent Does

Explore codebase → identify files → break into bite-sized tasks (2-5 min) → write complete code → include exact commands → add review checkpoints → verify Zero-Context Test → save to `docs/plans/YYYY-MM-DD-<feature>.md` → report back

## Requirements for Plans

Every plan: Header (goal, architecture, tech stack) | Verification commands with expected output | Exact file paths (never "somewhere in src") | Complete code (never "add validation here") | Bite-sized steps with verification | Failure recovery | Review checkpoints | Zero-Context Test | **Recommended agents per task**

### Multi-Module Task Requirements

**If TopologyConfig exists** (from pre-dev research.md frontmatter or user input):

Each task MUST include:
- **Target:** `backend` | `frontend` | `shared`
- **Working Directory:** Resolved path from topology configuration
- **Agent:** Recommended agent matching the target

**Task Format with Target:**

```markdown
## Task 3: Create User Login API

**Target:** backend
**Working Directory:** packages/api
**Agent:** ring:backend-engineer-golang

**Files to Create/Modify:**
- `packages/api/internal/handlers/auth.go`
- `packages/api/internal/services/auth_service.go`

...rest of task...
```

**Target Assignment Rules:**

| Target | When | Agent |
|--------|------|-------|
| `backend` | API endpoints, services, data layer, CLI | `ring:backend-engineer-{golang,typescript}` |
| `frontend` | UI components, pages, BFF routes | See [Frontend Tasks (api_pattern aware)](#frontend-tasks-api_pattern-aware) |
| `shared` | CI/CD, configs, docs, cross-module | `ring:devops-engineer` or `ring:general-purpose` |

**Working Directory Resolution:**

| Topology Structure | Backend Path | Frontend Path |
|-------------------|--------------|---------------|
| `single-repo` | `.` | `.` |
| `monorepo` | `topology.modules.backend.path` | `topology.modules.frontend.path` |
| `multi-repo` | `topology.modules.backend.path` (absolute) | `topology.modules.frontend.path` (absolute) |

## Agent Selection

### Backend Tasks

| Task Type | Agent |
|-----------|-------|
| Go backend API/services | `ring:backend-engineer-golang` |
| TypeScript backend API/services | `ring:backend-engineer-typescript` |

### Frontend Tasks (api_pattern aware)

**Read `api_pattern` from topology configuration to determine correct agent:**

| API Pattern | Task Type | Agent |
|-------------|-----------|-------|
| `direct` | UI components, pages, forms | `ring:frontend-engineer` |
| `direct` | Server Actions, data fetching | `ring:frontend-engineer` |
| `direct` | Server Components with data loading | `ring:frontend-engineer` |
| `bff` | API routes (`/api/*`) | `ring:frontend-bff-engineer-typescript` |
| `bff` | Data aggregation, transformation | `ring:frontend-bff-engineer-typescript` |
| `bff` | External service integration | `ring:frontend-bff-engineer-typescript` |
| `bff` | UI components, pages, forms | `ring:frontend-engineer` |
| `other` | Depends on pattern | Ask user or use `ring:frontend-engineer` default |

### Decision Logic for Frontend Tasks

```
def get_frontend_agent(task, topology):
    api_pattern = topology.get('api_pattern', 'direct')

    if api_pattern == 'direct':
        return 'ring:frontend-engineer'

    if api_pattern == 'bff':
        if is_bff_task(task):  # API routes, aggregation, transformation
            return 'ring:frontend-bff-engineer-typescript'
        else:  # UI components, pages
            return 'ring:frontend-engineer'

    return 'ring:frontend-engineer'  # Default for 'other'

def is_bff_task(task):
    bff_indicators = [
        'API route', 'api route', '/api/',
        'aggregat', 'transform', 'BFF',
        'external service', 'backend service',
        'data layer', 'HTTP client'
    ]
    return any(ind in task.description for ind in bff_indicators)
```

### Infrastructure and Other Tasks

| Task Type | Agent |
|-----------|-------|
| Infra/CI/CD | `ring:devops-engineer` |
| Testing | `ring:qa-analyst` |
| Reliability | `ring:sre` |
| Fallback | `ring:general-purpose` |

### Task Format with api_pattern

When TopologyConfig includes `api_pattern`, include it in task metadata:

```markdown
## Task 3: Aggregate Dashboard Data

**Target:** frontend
**Working Directory:** packages/web
**API Pattern:** bff
**Agent:** ring:frontend-bff-engineer-typescript

**Files to Create/Modify:**
- `packages/web/app/api/dashboard/route.ts`
- `packages/web/lib/services/dashboard-aggregator.ts`

...rest of task...
```

## Execution Options Reference

| Option | Description |
|--------|-------------|
| **Execute now** | Fresh subagent per task, code review between tasks → `ring:subagent-driven-development` |
| **Parallel session** | User opens new session, batch execution with human review → `ring:executing-plans` |
| **Save for later** | Plan at `docs/plans/YYYY-MM-DD-<feature>.md`, manual review before execution |

## Required Patterns

This skill uses these universal patterns:
- **State Tracking:** See `skills/shared-patterns/state-tracking.md`
- **Failure Recovery:** See `skills/shared-patterns/failure-recovery.md`
- **Exit Criteria:** See `skills/shared-patterns/exit-criteria.md`
- **TodoWrite:** See `skills/shared-patterns/todowrite-integration.md`

Apply ALL patterns when using this skill.

## Blocker Criteria

STOP and report if:

| Decision Type | Blocker Condition | Required Action |
|---|---|---|
| Design Validation | Design phase not complete (brainstorming/PRD/TRD not validated) | STOP and report |
| Plan Validation | Plan fails `validate-plan-precedent.py` check | STOP and report |
| Zero-Context Test | Plan contains vague instructions ("add validation here") | STOP and report |
| Agent Assignment | Tasks missing recommended agent specification | STOP and report |

### Cannot Be Overridden

The following requirements CANNOT be waived:
- Design phase MUST be complete before creating implementation plan
- Plan validation script MUST pass before execution
- All tasks MUST include exact file paths, never "somewhere in src"
- All tasks MUST include complete code examples, never placeholders
- Each task MUST specify recommended agent

## Severity Calibration

| Severity | Condition | Required Action |
|---|---|---|
| CRITICAL | Plan created without validated design | MUST complete design phase first |
| CRITICAL | Tasks contain placeholder code ("add logic here") | MUST write complete code examples |
| HIGH | Plan fails validation script | MUST address warnings and re-validate |
| HIGH | Missing exact file paths in tasks | MUST specify complete paths |
| MEDIUM | Missing verification commands in tasks | Should add expected output verification |
| LOW | Missing review checkpoints between tasks | Fix in next iteration |

## Pressure Resistance

| User Says | Your Response |
|---|---|
| "Skip design validation, we know what to build" | "CANNOT skip design validation. Plans without validated design lead to rework. Design phase MUST be complete first." |
| "Add the code later, just outline the tasks" | "CANNOT use placeholder code. Zero-Context Test requires complete code so engineers can execute without codebase knowledge." |
| "Approximate file paths are fine" | "CANNOT use vague paths. Tasks MUST include exact file paths - never 'somewhere in src'." |
| "Skip plan validation, we're in a hurry" | "CANNOT skip validation. Plan validation catches issues before they become implementation blockers." |

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|---|---|---|
| "Design is obvious, skip to planning" | Obvious ≠ validated. Unvalidated designs cause plan rework. | **MUST complete design phase first** |
| "Engineer will figure out the details" | Zero-Context Test: engineer has NO codebase context. Plan must be complete. | **MUST include complete code and paths** |
| "Validation warnings are minor" | Warnings indicate issues that become blockers during execution. | **MUST address all warnings** |
| "Agent assignment is flexible" | Wrong agent = wrong standards applied. Each task needs correct specialist. | **MUST specify recommended agent** |
| "Plan is good enough, validation is overkill" | "Good enough" plans fail Zero-Context Test. Validation ensures completeness. | **MUST run and pass validation** |
