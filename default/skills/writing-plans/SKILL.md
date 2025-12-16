---
name: writing-plans
description: |
  Creates comprehensive implementation plans with exact file paths, complete code
  examples, and verification steps for engineers with zero codebase context.

trigger: |
  - Design phase complete (brainstorming/PRD/TRD validated)
  - Need to create executable task breakdown
  - Creating work for other engineers or AI agents

skip_when: |
  - Design not validated → use brainstorming first
  - Requirements still unclear → use pre-dev-prd-creation first
  - Already have a plan → use executing-plans

sequence:
  after: [brainstorming, pre-dev-trd-creation]
  before: [executing-plans, subagent-driven-development]

related:
  similar: [brainstorming]
---

# Writing Plans

## Overview

This skill dispatches a specialized agent to write comprehensive implementation plans for engineers with zero codebase context.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** This should be run in a dedicated worktree (created by brainstorming skill).

## The Process

**Step 1:** Dispatch write-plan agent via `Task(subagent_type: "write-plan", model: "opus")` with instructions to create bite-sized tasks (2-5 min each), include exact file paths/complete code/verification steps, and save to `docs/plans/YYYY-MM-DD-<feature-name>.md`.

**Step 2:** Ask user via `AskUserQuestion`: "Execute now?" Options: (1) Execute now → `subagent-driven-development` (2) Parallel session → user opens new session with `executing-plans` (3) Save for later → report location and end

## Why Use an Agent?

**Context preservation** (reading many files keeps supervisor clean) | **Model power** (Opus for comprehensive planning) | **Separation of concerns** (supervisor orchestrates, agent plans)

## What the Agent Does

Explore codebase → identify files → break into bite-sized tasks (2-5 min) → write complete code → include exact commands → add review checkpoints → verify Zero-Context Test → save to `docs/plans/YYYY-MM-DD-<feature>.md` → report back

## Requirements for Plans

Every plan: Header (goal, architecture, tech stack) | Verification commands with expected output | Exact file paths (never "somewhere in src") | Complete code (never "add validation here") | Bite-sized steps with verification | Failure recovery | Review checkpoints | Zero-Context Test | **Recommended agents per task**

## Agent Selection

| Task Type | Agent |
|-----------|-------|
| Backend API/services | `backend-engineer-{golang,typescript}` |
| Frontend/BFF | `frontend-bff-engineer-typescript` |
| Infra/CI/CD | `devops-engineer` |
| Testing | `qa-analyst` |
| Reliability | `sre` |
| Fallback | `general-purpose` (built-in, no prefix) |

## Execution Options Reference

| Option | Description |
|--------|-------------|
| **Execute now** | Fresh subagent per task, code review between tasks → `subagent-driven-development` |
| **Parallel session** | User opens new session, batch execution with human review → `executing-plans` |
| **Save for later** | Plan at `docs/plans/YYYY-MM-DD-<feature>.md`, manual review before execution |

## Required Patterns

This skill uses these universal patterns:
- **State Tracking:** See `skills/shared-patterns/state-tracking.md`
- **Failure Recovery:** See `skills/shared-patterns/failure-recovery.md`
- **Exit Criteria:** See `skills/shared-patterns/exit-criteria.md`
- **TodoWrite:** See `skills/shared-patterns/todowrite-integration.md`

Apply ALL patterns when using this skill.
