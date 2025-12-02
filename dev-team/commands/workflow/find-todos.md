---
allowed-tools: Grep(*), TodoWrite(*), Bash(*)
description: Find and organize TODO comments and unfinished work markers in the codebase
argument-hint: [--pattern=<pattern>] [--git-scope=<scope>]
---

# /shared:find-todos

## Context

I'll locate all TODO comments and unfinished work markers in your codebase.

## Instructions

### Usage Patterns

```bash
# Git-focused TODO discovery (recommended for active development)
/shared:find-todos --git-scope=all-changes               # Find TODOs in changed files
/shared:find-todos --git-scope=staged                   # Find TODOs in staged files
/shared:find-todos --git-scope=branch                   # Find TODOs in branch changes
/shared:find-todos --git-scope=last-commit              # Find TODOs in last commit

# Traditional pattern-based search
/shared:find-todos --pattern="TODO|FIXME"               # Find specific patterns
/shared:find-todos                                      # Find all TODO markers
```

**Arguments:**

- `--pattern`: Custom search pattern for TODO markers (default: "TODO|FIXME|HACK|XXX|NOTE")
- `--git-scope`: Git scope for focusing on specific changes - staged|unstaged|all-changes|branch|last-commit|commit-range=<range>

## Process

### Initial Setup

#### Git Scope Analysis (when --git-scope used)

If `--git-scope` is specified:

```bash
# Source git utilities
if ! source .claude/utils/git-utilities.sh; then
    echo "Error: Could not load git utilities. Please ensure git-utilities.sh exists." >&2
    exit 1
fi

# Process git scope (this function handles validation, stats, and file listing)
target_files=$(process_git_scope "$git_scope")
```

**Git-Scope TODO Benefits:**

- **Contextual Discovery**: Find TODOs in areas you're actively working on
- **Task Management**: Focus on TODOs related to current development work
- **Workflow Integration**: Discover TODOs as part of feature development or code review
- **Productivity**: Avoid information overload from project-wide TODO searches

## Formatting

### TODO Analysis Process

I'll use the Grep tool to efficiently search for task markers with context:

- Pattern: "TODO|FIXME|HACK|XXX|NOTE" (or custom pattern via --pattern)
- Case insensitive search across target files (scoped or full codebase)
- Show surrounding lines for better understanding

For each marker found, I'll show:

1. **File location** with line number
2. **The full comment** with context
3. **Surrounding code** to understand what needs to be done
4. **Priority assessment** based on the marker type

When I find multiple items, I'll create a todo list to organize them by priority:

- **Critical** (FIXME, HACK, XXX): Issues that could cause problems
- **Important** (TODO): Features or improvements needed
- **Informational** (NOTE): Context that might need attention

I'll also identify:

- TODOs that reference missing implementations
- Placeholder code that needs replacement
- Incomplete error handling
- Stubbed functions awaiting implementation

After scanning, I'll ask: "How would you like to track these?"

- Todos only: I'll maintain the local todo list
- Summary: I'll provide organized report

## Requirements

**Important**: I will NEVER:

- Modify existing working code without permission
- Delete TODO comments that serve as documentation
- Change the meaning or context of existing TODOs

This helps track and prioritize unfinished work systematically.
