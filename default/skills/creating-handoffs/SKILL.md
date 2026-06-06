---
name: ring:create-handoff
description: Create handoff documents capturing session state for seamless context-clear and resume
---

# Session Handoff Skill

## When to use
- User is ending a session and wants to preserve context for later
- Context window is getting large and a fresh start would be beneficial
- Handing off work to another person or AI session
- User says "handoff", "save session", "wrap up", or "context transfer"

## Skip when
- Session has minimal context that does not warrant a handoff document
- User simply wants to end the conversation without resuming later
- Work is fully complete with nothing pending

Creates a handoff document capturing session context, delivered via Claude Code's Plan Mode so the user gets a native "clear context and continue implementing" option.

## Execution Protocol (exact order, no skipping)

### Step 1: Gather Context

Before entering plan mode, collect:
- Completed work, decisions, and open items from conversation history
- Use `Glob` and `Read` to verify file states and paths as needed
- Use `Bash` with `date` for timestamps
- Session name (from argument or infer from work done)

### Step 2: Enter Plan Mode

Call `EnterPlanMode` tool.

### Step 3: Write Handoff as the Plan

Write the full handoff document (template below) to the plan file path specified in the system message. The handoff IS the plan.

### Step 4: Exit Plan Mode

Call `ExitPlanMode` tool — this presents the native resume options.

### Step 5: Confirm to User

```
Handoff created and loaded as plan.

Choose "clear context and continue implementing" to resume in a fresh context.
```

## Handoff Template

````markdown
# Handoff: {Session Name}

**Created:** {timestamp}
**Session:** {session-name}
**Status:** {In Progress | Blocked | Ready for Review | Complete}

## Summary
{1-2 sentence overview}

## Current State
{Where things stand — specific about done vs pending}

## Completed Work
- {item with file references}

## In-Progress Work
- {partially done items — describe exactly where you stopped}

## Key Decisions
| Decision | Rationale | Alternatives Considered |
|----------|-----------|------------------------|

## What Worked
- {successful approaches worth reusing}

## What Didn't Work
- {failed approaches to avoid}

## Open Questions
- [ ] {unresolved questions or blockers}

## Next Steps
1. {First action when resuming — specific and actionable}

## Relevant Files
| File | Purpose | Status |
|------|---------|--------|

## Context for Resumption
{Gotchas, environment setup, branch state, test commands}
````

## Key Rules

- MUST gather all context BEFORE calling EnterPlanMode (plan mode restricts tool usage)
- MUST fill every section of the template
- MUST call ExitPlanMode after writing (otherwise user never sees native resume options)
- MUST write to the path specified by plan mode system message
