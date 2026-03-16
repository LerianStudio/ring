---
name: session-handoff
description: Create handoff documents capturing session state for seamless context-clear and resume
allowed-tools: EnterPlanMode, ExitPlanMode, Write, Bash, Read, Glob
metadata:
  user_invocable: false
---

# Session Handoff Skill

Creates a comprehensive handoff document that captures the current session's context, progress, decisions, and next steps. Uses Claude Code's **Plan Mode** to deliver the handoff as a native plan, giving the user a seamless "clear context and continue implementing" option without any manual steps.

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `session-name` | No | Short identifier for the session (defaults to feature/task name) |
| `description` | No | Brief description of current state |

## What Gets Captured

The handoff document includes:

1. **Session Summary** - What was being worked on in this entire session (organized per sub-topics)
2. **Current State** - Where things stand right now
3. **Completed Work** - What was accomplished
4. **In-Progress Work** - What's partially done
5. **Key Decisions** - Important choices made and why
6. **What Worked** - Successful approaches
7. **What Didn't Work** - Failed approaches to avoid
8. **Open Questions** - Unresolved items needing attention
9. **Next Steps** - Clear actions for resumption
10. **Relevant Files** - Key files touched or to be modified
11. **Context for Resumption** - Gotchas, environment setup, anything the next session needs

## Execution Protocol

MUST follow these steps in exact order. No step can be skipped or reordered.

### Step 1: Gather Context

Before entering plan mode, collect all session information needed for the handoff:

- Review the conversation history to identify completed work, decisions, and open items
- Use `Glob` and `Read` as needed to verify file states and paths
- Use `Bash` with `date` commands to generate timestamps
- Determine the session name (from argument or infer from the work done)
- Determine the description (from argument or infer from current state)

### Step 2: Enter Plan Mode

MUST call `EnterPlanMode` tool. This switches the session to plan mode where the handoff will be presented as a native plan.

### Step 3: Write the Handoff as the Plan

MUST write the handoff content to the plan file. When plan mode is active, the system message specifies the plan file path. Write the full handoff document (using the template below) to that path using the `Write` tool.

The handoff IS the plan. The user will see it displayed inline and can review every detail before deciding to continue.

### Step 4: Exit Plan Mode

MUST call `ExitPlanMode` tool. This presents the user with native options including "clear context and continue implementing" - which is the seamless handoff resume.

### Step 5: Confirm to User

After exiting plan mode, inform the user:

```
Handoff created and loaded as plan.

You can now choose "clear context and continue implementing" to seamlessly
resume in a fresh context with the handoff loaded as your plan.
```

## Handoff Template

When creating the handoff document (the plan file), use this structure:

````markdown
# Handoff: {Session Name}

**Created:** {timestamp}
**Session:** {session-name}
**Status:** {In Progress | Blocked | Ready for Review | Complete}

## Summary

{1-2 sentence overview of what this session was about}

## Current State

{Where things stand right now - be specific about what's done vs pending}

## Completed Work

- {List of completed items with file references where relevant}

## In-Progress Work

- {Partially completed items - describe exactly where you stopped}
- {Include enough detail that the next session can pick up without re-reading code}

## Key Decisions

| Decision | Rationale | Alternatives Considered |
|----------|-----------|------------------------|
| {decision} | {why} | {what else was considered} |

## What Worked

- {Successful approaches, patterns, or solutions worth reusing}

## What Didn't Work

- {Failed approaches - document to avoid repeating}

## Open Questions

- [ ] {Unresolved questions that need answers}
- [ ] {Blockers or dependencies}

## Next Steps

1. {First thing to do when resuming - be specific and actionable}
2. {Second priority}
3. {Third priority}

## Relevant Files

| File | Purpose | Status |
|------|---------|--------|
| `path/to/file` | {what it does} | {modified/created/to-modify} |

## Context for Resumption

{Any additional context the next session needs - gotchas, environment setup, branch state, test commands, etc.}
````

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|----------------|----------------|-----------------|
| "I'll enter plan mode first, then gather context" | Plan mode restricts tool usage. Context gathering requires Read, Glob, and Bash. | **MUST gather all context before calling EnterPlanMode** |
| "The handoff doesn't need all template sections" | Incomplete handoffs cause information loss. Every section exists for a reason. | **MUST fill every section of the template** |
| "I'll just summarize briefly" | Brief summaries lose critical context. The whole point is comprehensive capture. | **MUST provide detailed content in each section** |
| "ExitPlanMode isn't needed, the plan is written" | Without ExitPlanMode, the user never sees the native resume options. | **MUST call ExitPlanMode after writing the plan** |
| "I'll write the plan file to a custom path" | Plan mode specifies its own file path. Writing elsewhere breaks the integration. | **MUST write to the path specified by plan mode system message** |

## Examples

### Basic Usage

```
User: /ring:create-handoff
Assistant: I will create a handoff document for the current session.
[Step 1: Gathers context from conversation history]
[Step 2: Calls EnterPlanMode]
[Step 3: Writes handoff to plan file path]
[Step 4: Calls ExitPlanMode]
[Step 5: User sees handoff and native options]
```

### With Session Name and Description

```
User: /ring:create-handoff auth-refactor "OAuth provider integration"
Assistant: I will create a handoff document for the auth-refactor session.
[Gathers all context, enters plan mode, writes plan, exits plan mode]

Handoff created and loaded as plan.

You can now choose "clear context and continue implementing" to seamlessly
resume in a fresh context with the handoff loaded as your plan.
```

### What the User Sees After Completion

After the command completes, the user sees the full handoff document displayed as a plan in their Claude Code session. The system presents native options:

1. **"Clear context and continue implementing"** - Clears the conversation context and loads the handoff as the active plan. This is the seamless resume path.
2. **"Continue without clearing"** - Keeps the current context and the plan. Useful if the user wants to keep working in the same session.
3. **Edit the plan** - The user can modify the handoff before proceeding.

The plan persists across context clears, so the user can always review it regardless of which option they choose.
