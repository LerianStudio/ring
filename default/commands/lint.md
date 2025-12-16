---
name: lint
description: Run lint checks and dispatch parallel agents to fix all issues
argument-hint: "[path]"
---

Run linting tools, analyze results, and dispatch parallel AI agents to fix all issues until the codebase is clean.

## Usage

```
/lint [path]
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `path` | No | Specific path to lint (defaults to entire codebase) |

## What This Command Does

1. **Runs lint checks** - Executes `make lint` or appropriate linting tools
2. **Analyzes results** - Groups issues into independent fix streams
3. **Dispatches agents** - Launches parallel agents (one per stream)
4. **Iterates until clean** - Continues until all lint issues are resolved

## Process

This command invokes the `linting-codebase` skill which handles:

### Phase 1: Lint Execution
- Runs `make lint` (or detects appropriate lint command)
- Captures all output and exit codes
- Parses errors, warnings, and their locations

### Phase 2: Stream Analysis
- Groups issues by file or logical component
- Identifies independent streams that can be fixed in parallel
- Creates fix assignments for each stream

### Phase 3: Parallel Agent Dispatch
- Launches N agents simultaneously (one per stream)
- Each agent fixes issues in their assigned scope
- Agents work independently without conflicts

### Phase 4: Verification Loop
- Re-runs lint after all agents complete
- If issues remain, analyzes and dispatches new agents
- Continues until lint passes completely

## Important Constraints

⚠️ **NO AUTOMATED SCRIPTS** - Agents fix code directly, never create automation scripts
⚠️ **NO DOCUMENTATION** - Agents fix lint issues only, don't add docs/comments
⚠️ **DIRECT FIXES ONLY** - Each issue is fixed manually by editing the source

## Examples

### Lint Entire Codebase
```
/lint
```
Runs full lint, dispatches agents to fix everything.

### Lint Specific Path
```
/lint src/services/
```
Lints only the services directory.

## Related

| Command/Skill | Relationship |
|---------------|--------------|
| `linting-codebase` | Underlying skill with full logic |
| `dispatching-parallel-agents` | Pattern used for parallel fixes |
| `/codereview` | Use after lint passes for deeper review |
