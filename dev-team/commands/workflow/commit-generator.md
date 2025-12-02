---
allowed-tools: Bash(*), Read(*), Grep(*), Write(*)
description: Generate conventional commit messages based on git changes and save as commit-message.txt
argument-hint: [--git-scope=<scope>] (which git changes to analyze)
---

# /ring-dev-team:workflow:commit-generator

Analyzes current git changes and generates conventional commit messages following the Conventional Commits 1.0.0 specification, then saves them to `commit-message.txt` in the project root.

## Usage

This command examines your git staging area and working directory to suggest properly formatted conventional commit messages based on the changes detected.

```bash
# Analyze different sets of changes
/ring-dev-team:workflow:commit-generator --git-scope=staged              # Generate message for staged changes only (default)
/ring-dev-team:workflow:commit-generator --git-scope=all-changes         # Generate message for all changes (staged + unstaged)
/ring-dev-team:workflow:commit-generator --git-scope=unstaged            # Generate message for unstaged changes only
/ring-dev-team:workflow:commit-generator --git-scope=branch              # Generate message for branch changes
/ring-dev-team:workflow:commit-generator --git-scope=last-commit         # Generate message based on last commit

# Basic usage (defaults to staged changes)
/ring-dev-team:workflow:commit-generator
```

**Arguments:**

- `--git-scope`: Which git changes to analyze - staged|unstaged|all-changes|branch|last-commit|commit-range=<range> (defaults to 'staged')

## Initial Setup

### Git Scope Configuration

```bash
# Source git utilities
if ! source .claude/utils/git-utilities.sh; then
    echo "Error: Could not load git utilities. Please ensure git-utilities.sh exists." >&2
    exit 1
fi

# Set default git scope if not provided
git_scope="${git_scope:-staged}"

# Process git scope (this function handles validation, stats, and file listing)
target_files=$(process_git_scope "$git_scope")
```

**Git-Scope Commit Benefits:**

- **Precise Control**: Generate messages for specific change sets (staged, branch, etc.)
- **Flexible Workflow**: Support different commit strategies and workflows
- **Better Messages**: More accurate commit messages based on targeted change analysis
- **Staging Integration**: Generate messages for exactly what will be committed

## Process

1. **Git Scope Analysis** (Enhanced)
    - Uses `get_git_files()` to analyze files in specified scope
    - Analyzes targeted changes based on git-scope parameter
    - Provides context about the scope of changes being committed

2. **Change Classification**
    - Analyzes file patterns and change types
    - Determines appropriate commit type (feat, fix, docs, style, etc.)
    - Automatically detects scope from file paths (api, ui, docs, etc.)

3. **Message Generation**
    - Creates conventional commit message following the format:

        ```
        <type>[optional scope]: <description>

        [optional body]

        [optional footer(s)]
        ```

    - Saves the generated message to `commit-message.txt` in the project root
    - Provides multiple suggestions when appropriate

## Supported Commit Types

Based on the Conventional Commits specification and Angular convention:

- **feat:** A new feature
- **fix:** A bug fix
- **docs:** Documentation only changes
- **style:** Changes that do not affect the meaning of the code
- **refactor:** A code change that neither fixes a bug nor adds a feature
- **perf:** A code change that improves performance
- **test:** Adding missing tests or correcting existing tests
- **build:** Changes that affect the build system or external dependencies
- **ci:** Changes to CI configuration files and scripts
- **chore:** Other changes that don't modify src or test files
- **revert:** Reverts a previous commit

## Examples

### Basic Feature Addition

```bash
/ring-dev-team:workflow:commit-generator
```

**Output:**

```
feat: add user authentication system

- Implement JWT token validation
- Add login/logout endpoints
- Create user authentication system
```

### Analyzing Branch Changes

```bash
/ring-dev-team:workflow:commit-generator --git-scope=branch
```

**Output:**

```
feat(api): add user authentication endpoints

- Implement /auth/login endpoint
- Add /auth/logout endpoint
- Include JWT token validation middleware
```

### Bug Fix with Scope

```
fix(api): correct user validation logic

- Fix email validation regex pattern
- Update password requirements check
```

## Notes

- If no changes are detected, the command will prompt you to stage changes first
- Multiple commit suggestions may be provided for complex changesets
- The command respects conventional commit standards for consistent git history
- Generated commit messages are saved to `commit-message.txt` for easy copying or use with `git commit -F commit-message.txt`

## Critical Requirements

**CRITICAL REQUIREMENT**: This commit generator must NEVER add "BREAKING CHANGE" in commit messages under any circumstances.

- Do NOT include "BREAKING CHANGE:" footer text in any generated commit messages
- Do NOT add breaking change notifications or warnings to commit body
- Do NOT use the "!" suffix to indicate breaking changes in commit type
- Do NOT generate breaking change examples or templates

**CRITICAL REQUIREMENT**: Generated commit messages must NOT include any AI attribution, credits, or "generated by" messages.

- Do NOT include "Generated by Claude" or similar AI attribution text
- Do NOT add "Co-Authored-By: Claude <noreply@anthropic.com>" or any AI co-author credits
- Do NOT use emojis like 🤖 or any other AI-related symbols
- Do NOT include references to AI assistance in any form
- Do NOT add "Generated with [Claude Code]" links or similar attribution
- Commit messages must appear as normal human-written commits without any indication of AI involvement
