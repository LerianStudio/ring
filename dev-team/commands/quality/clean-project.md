---
allowed-tools: Bash(*), Read(*), Edit(*), Glob(*), Grep(*), LS(*), TodoWrite(*)
description: Clean up development artifacts while preserving working code with safety checkpoints
argument-hint: [--dry-run] [--verbose] [--git-scope=<scope>]
---

# /ring-dev-team:quality:clean-project

## Instructions

Clean up development artifacts while preserving working code with safety checkpoints. Focus cleanup on git-changed directories only for faster, targeted cleaning.

## Context

This command helps maintain clean project directories by removing development artifacts, temporary files, and debug content while preserving essential working code and configurations.

## Strategic Thinking
Before cleaning, I need to carefully consider:

1. **Artifact Identification**
   - What patterns indicate temporary/debug files?
   - Which files might look temporary but are actually important?
   - Are there project-specific conventions for temp files?
   - What about generated files that should be kept?
   - **Git-focused**: Should cleanup target only directories with recent changes?

2. **Safety Analysis**
   - Which deletions are definitely safe?
   - Which require more careful inspection?
   - Are there active processes using these files?
   - Could removing these break the development environment?

3. **Common Pitfalls**
   - .env files might look like artifacts but contain config
   - .cache directories might be needed for performance
   - Some .tmp files might be active process data
   - Debug logs might contain important error information

4. **Cleanup Strategy**
   - Start with obvious artifacts (_.log, _.tmp, \*~)
   - Check file age - older files are usually safer to remove
   - Verify with git status what's tracked vs untracked
   - Group similar files for batch decision making
   - **Git-aware**: Focus on artifact cleanup in directories with active development

## Safety Guidelines
**Important**: I will NEVER:

- Add "Co-authored-by" or any Claude signatures
- Include "Generated with Claude Code" or similar messages
- Modify git config or user credentials
- Add any AI/assistant attribution to the commit
- Use emojis in commits, PRs, or git-related content

I'll identify cleanup targets using native tools:

- **Glob tool** to find temporary and debug files
- **Grep tool** to detect debug statements in code
- **Read tool** to verify file contents before removal

Critical directories are automatically protected:

- .claude directory (commands and configurations)
- .git directory (version control)
- node_modules, vendor (dependency directories)
- Essential configuration files

When I find multiple items to clean, I'll create a todo list to process them systematically.

I'll show you what will be removed and why before taking action:

- Debug/log files and temporary artifacts
- Failed implementation attempts
- Development-only files
- Debug statements in code

After cleanup, I'll verify project integrity and report what was cleaned.

If any issues occur, I can restore from the git checkpoint created at the start.

This keeps only clean, working code while maintaining complete safety.

## Git Options

### --git-scope

Focuses cleanup on directories with git changes, preserving build artifacts in unchanged areas:

```bash
# Clean artifacts in directories with any git changes
/ring-dev-team:quality:clean-project --git-scope=all

# Clean artifacts in staged file directories
/ring-dev-team:quality:clean-project --git-scope=staged

# Clean artifacts in feature branch directories
/ring-dev-team:quality:clean-project --git-scope=branch

# Clean artifacts in directories touched by last commit
/ring-dev-team:quality:clean-project --git-scope=last-commit

# Show what would be cleaned with dry-run
/ring-dev-team:quality:clean-project --git-scope=staged --dry-run

# Verbose output showing git context
/ring-dev-team:quality:clean-project --git-scope=all --verbose
```

**Benefits:**

- **Faster execution** - Only scans directories with git changes
- **Incremental builds preserved** - Keeps artifacts in unchanged areas
- **Targeted cleaning** - Focuses on active development directories
- **Build performance** - Maintains cache for unchanged components
- **Flexible scope** - Choose the appropriate git change set to target

## Process

When `--git-scope` is used:

```bash
# 1. Validate git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Error: Not a git repository. Git cleanup requires a git repository." >&2
    exit 1
fi

# 2. Identify directories with git changes
changed_dirs=$(git diff HEAD --name-only --diff-filter=ACMR | xargs dirname | sort -u)

# 3. Focus artifact cleanup on these directories only
for dir in $changed_dirs; do
    echo "Cleaning artifacts in active directory: $dir"
    # Clean temporary files in this directory
    find "$dir" -name "*.log" -o -name "*.tmp" -o -name "*~" | head -20
done

# 4. Preserve artifacts in unchanged directories
echo "Preserving build artifacts in unchanged directories for performance"
```

### Example Git-Focused Cleanup

**Before cleanup** (traditional approach):

- Scans entire 50GB repository
- Removes all build artifacts (forces full rebuild)
- Takes 5+ minutes to complete
- No context about active development

**After cleanup** (git-focused):

- Scans only 3 changed directories
- Preserves build cache for 95% of codebase
- Completes in 30 seconds
- Targets active development areas only

This approach is especially valuable for:

- **Large monorepos** with selective changes
- **Incremental build systems** (Bazel, Nx, Turborepo)
- **CI/CD optimization** where build cache matters
- **Active feature development** with focused changes
