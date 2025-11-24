---
name: writing-plans
description: Use when design is complete and you need detailed implementation tasks for engineers with zero codebase context - creates comprehensive implementation plans with exact file paths, complete code examples, and verification steps assuming engineer has minimal domain knowledge
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

**Step 2: Report to human**

After the agent completes, it will save the plan and offer execution options to the human partner.

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
9. Offer execution options (subagent-driven or parallel session)

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

## After Plan Creation

The agent will report back and offer two execution options:

**1. Subagent-Driven (current session)**
- Agent dispatches fresh subagent per task
- Code review between tasks
- Fast iteration with quality gates
- Use ring:subagent-driven-development

**2. Parallel Session (separate session)**
- Open new agent session in worktree
- Batch execution with checkpoints
- Use ring:executing-plans

## Required Patterns

This skill uses these universal patterns:
- **State Tracking:** See `skills/shared-patterns/state-tracking.md`
- **Failure Recovery:** See `skills/shared-patterns/failure-recovery.md`
- **Exit Criteria:** See `skills/shared-patterns/exit-criteria.md`
- **TodoWrite:** See `skills/shared-patterns/todowrite-integration.md`

Apply ALL patterns when using this skill.
