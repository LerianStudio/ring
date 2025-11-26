---
name: writing-plans
description: Use when design is complete and you need detailed implementation tasks for engineers with zero codebase context - creates comprehensive implementation plans with exact file paths, complete code examples, and verification steps assuming engineer has minimal domain knowledge
when_to_use: Use when design is complete and you need detailed implementation tasks for engineers with zero codebase context - creates comprehensive implementation plans with exact file paths, complete code examples, and verification steps assuming engineer has minimal domain knowledge
---

# Writing Plans

## Overview

This skill dispatches a specialized agent to write comprehensive implementation plans for engineers with zero codebase context.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** This should be run in a dedicated worktree (created by brainstorming skill).

## The Process

**Step 1: Dispatch the write-plan agent**

Use the Task tool to launch the specialized planning agent:

```
Task(
  subagent_type: "general-purpose",
  description: "Write implementation plan",
  prompt: "Use the write-plan agent to create a comprehensive implementation plan.

  Load agents/write-plan.md and follow all instructions to:
  - Understand the feature scope
  - Read relevant codebase files
  - Create bite-sized tasks (2-5 min each)
  - Include exact file paths, complete code, and verification steps
  - Add code review checkpoints
  - Pass the Zero-Context Test

  Save the plan to docs/plans/YYYY-MM-DD-<feature-name>.md and report back with execution options.",
  model: "opus"
)
```

**Step 2: Ask user about execution**

After the agent completes and saves the plan, use `AskUserQuestion` to determine next steps:

```
AskUserQuestion(
  questions: [{
    header: "Execution",
    question: "The plan is ready. Would you like to execute it now or save it for later?",
    options: [
      { label: "Execute now", description: "Start implementation in current session using subagent-driven development" },
      { label: "Execute in parallel session", description: "Open a new agent session in the worktree for batch execution" },
      { label: "Save for later", description: "Keep the plan for manual review before execution" }
    ],
    multiSelect: false
  }]
)
```

**Based on response:**
- **Execute now** → Use `ring:subagent-driven-development` skill
- **Execute in parallel session** → Instruct user to open new session and use `ring:executing-plans`
- **Save for later** → Report plan location and end workflow

## Why Use an Agent?

**Context preservation:** Plan writing requires reading many files and analyzing architecture. Using a dedicated agent keeps the main supervisor's context clean.

**Model power:** The agent runs on Opus for comprehensive planning and attention to detail.

**Separation of concerns:** The supervisor orchestrates workflows, the agent focuses on deep planning work.

## What the Agent Does

The write-plan agent will:
1. Explore the codebase to understand architecture
2. Identify all files that need modification
3. Break the feature into bite-sized tasks (2-5 minutes each)
4. Write complete, copy-paste ready code for each task
5. Include exact commands with expected output
6. Add code review checkpoints after task batches
7. Verify the plan passes the Zero-Context Test
8. Save to `docs/plans/YYYY-MM-DD-<feature-name>.md`
9. Report back (supervisor then uses `AskUserQuestion` for execution choice)

## Requirements for Plans

The agent ensures every plan includes:
- ✅ Header with goal, architecture, tech stack, prerequisites
- ✅ Verification commands with expected output
- ✅ Exact file paths (never "somewhere in src")
- ✅ Complete code (never "add validation here")
- ✅ Bite-sized steps separated by verification
- ✅ Failure recovery steps
- ✅ Code review checkpoints with severity-based handling
- ✅ Passes Zero-Context Test (executable with only the document)
- ✅ **Recommended agents per task** (see Agent Selection below)

## Agent Selection for Execution

Plans should specify which specialized agents to use for each task type. During execution, prefer specialized agents over general-purpose when available.

**Pattern matching for agent selection:**

| Task Type | Agent Pattern | Examples |
|-----------|---------------|----------|
| Backend API/services | `ring-developers:backend-engineer-*` | `backend-engineer-golang`, `backend-engineer-python` |
| Frontend UI/components | `ring-developers:frontend-engineer-*` | `frontend-engineer-react`, `frontend-engineer-vue` |
| Infrastructure/CI/CD | `ring-developers:devops-engineer` | Single agent |
| Testing strategy | `ring-developers:qa-analyst` | Single agent |
| Monitoring/reliability | `ring-developers:sre` | Single agent |

**Plan header should include:**
```markdown
## Recommended Agents
- Backend tasks: `ring-developers:backend-engineer-golang` (or language variant)
- Frontend tasks: `ring-developers:frontend-engineer-react` (or framework variant)
- Fallback: `general-purpose` if specialized agent unavailable
```

**Agent availability check:** If `ring-developers` plugin is not installed, execution falls back to `general-purpose` Task agents automatically.

## Execution Options Reference

When user selects an execution mode via `AskUserQuestion`:

**1. Execute now (Subagent-Driven)**
- Dispatches fresh subagent per task in current session
- Code review between tasks
- Fast iteration with quality gates
- Uses `ring:subagent-driven-development`

**2. Execute in parallel session**
- User opens new agent session in the worktree
- Batch execution with human review checkpoints
- Uses `ring:executing-plans`

**3. Save for later**
- Plan saved to `docs/plans/YYYY-MM-DD-<feature-name>.md`
- User reviews plan manually before deciding on execution
- Can invoke `ring:executing-plans` later with the plan file

## Required Patterns

This skill uses these universal patterns:
- **State Tracking:** See `skills/shared-patterns/state-tracking.md`
- **Failure Recovery:** See `skills/shared-patterns/failure-recovery.md`
- **Exit Criteria:** See `skills/shared-patterns/exit-criteria.md`
- **TodoWrite:** See `skills/shared-patterns/todowrite-integration.md`

Apply ALL patterns when using this skill.
