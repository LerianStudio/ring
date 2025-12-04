---
allowed-tools: Read(*), Write(*), Edit(*), Glob(*), Grep(*), Task(*)
description: Clean comments following clean code principles - remove redundant, obvious, and bad comments while preserving meaningful ones
argument-hint: [--file-pattern=<pattern>] [--git-scope=<scope>] [--dry-run]
---

# /ring-dev-team:quality:clean-comments

## Context

This command analyzes comments in your codebase and removes those that violate clean code principles while preserving valuable ones. You can focus on git changes for faster, more relevant cleaning, or analyze the entire codebase.

**Recommended workflow integration with analyze-codebase:**

```bash
# First understand the codebase architecture and patterns
/ring-dev-team:analysis:analyze-codebase

# Then clean comments with architectural context
/ring-dev-team:quality:clean-comments

# Or combine both commands for precision cleanup
/ring-dev-team:analysis:analyze-codebase && /ring-dev-team:quality:clean-comments
```

### Integration Benefits

When used with `/ring-dev-team:analysis:analyze-codebase`, this command:

- **Preserves architectural documentation** - Keeps comments explaining system design and patterns
- **Context-aware cleaning** - Understands which comments are critical for complex modules
- **Pattern-aware decisions** - Maintains comments that explain established coding patterns
- **Smart prioritization** - Focuses cleanup efforts on files with the most comment issues
- **Respects conventions** - Preserves project-specific documentation standards

## Instructions

Clean comments in code following clean code principles. Remove redundant, obvious noise, and bad comments while preserving meaningful documentation, warnings, and legal comments.

### Clean Code Comment Rules

1. **Always try to explain yourself in code** - Remove comments that can be replaced with better function/variable names
2. **Don't be redundant** - Remove comments that just repeat what the code obviously does
3. **Don't add obvious noise** - Remove comments like `i++; // increment i`
4. **Don't use closing brace comments** - Remove `} // end of if block` style comments
5. **Don't comment out code** - Remove commented-out code blocks
6. **Keep explanation of intent** - Preserve comments explaining WHY, not WHAT
7. **Keep warnings of consequences** - Preserve comments about important side effects
8. **Keep legal and informative comments** - Preserve copyright, licenses, TODOs

## Examples

### Standalone Usage

```bash
# Clean comments in git changes only (recommended for active development)
/ring-dev-team:quality:clean-comments --git-scope=all-changes

# Clean comments in staged files only
/ring-dev-team:quality:clean-comments --git-scope=staged

# Clean comments in files changed from main branch
/ring-dev-team:quality:clean-comments --git-scope=branch

# Clean comments in entire codebase (traditional approach)
/ring-dev-team:quality:clean-comments

# Clean git changes in JavaScript files only
/ring-dev-team:quality:clean-comments --git-scope=all-changes --file-pattern="**/*.js"

# Dry run to see what would be cleaned in git changes
/ring-dev-team:quality:clean-comments --git-scope=all-changes --dry-run

# Clean specific commit range
/ring-dev-team:quality:clean-comments --git-scope=commit-range=HEAD~3..HEAD
```

### Integrated Usage (Recommended)

```bash
# Comprehensive analysis followed by precision cleanup
/ring-dev-team:analysis:analyze-codebase && /ring-dev-team:quality:clean-comments

# Architecture-aware cleanup with dry run
/ring-dev-team:analysis:analyze-codebase && /ring-dev-team:quality:clean-comments --dry-run

# Focus on specific component with full context
/ring-dev-team:analysis:analyze-codebase lib/components && /ring-dev-team:quality:clean-comments --file-pattern="lib/components/**/*"
```

### Git-Focused Workflow (Fastest)

```bash
# Clean comments in current changes before commit
/ring-dev-team:quality:clean-comments --git-scope=all-changes

# Clean comments in staged files only
/ring-dev-team:quality:clean-comments --git-scope=staged --dry-run
/ring-dev-team:quality:clean-comments --git-scope=staged

# Review and clean feature branch changes
/ring-dev-team:quality:clean-comments --git-scope=branch

# Clean comments in last commit (useful for interactive rebase)
/ring-dev-team:quality:clean-comments --git-scope=last-commit
```

**Before:**

```javascript
// Check if user is eligible for discount
if (user.age >= 65 && user.membershipYears >= 5) {
  // Apply senior discount
  total = total * 0.9 // multiply by 0.9 to get 10% discount
} // end if block
```

**After:**

```javascript
if (user.isEligibleForSeniorDiscount()) {
  total = total * SENIOR_DISCOUNT_RATE
}
```

## Process

### Phase 0: Git Scope Filtering (when git options used)

If `--git-scope` is specified:

```bash
# Validate git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Error: Not a git repository. Git-focused options require a git repository." >&2
    exit 1
fi

# Get files in git scope
case "$git_scope" in
    "staged")
        target_files=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null)
        ;;
    "unstaged")
        target_files=$(git diff --name-only --diff-filter=ACMR 2>/dev/null)
        ;;
    "all-changes"|"")
        target_files=$(git diff HEAD --name-only --diff-filter=ACMR 2>/dev/null)
        ;;
    "last-commit")
        target_files=$(git diff HEAD~1..HEAD --name-only --diff-filter=ACMR 2>/dev/null)
        ;;
    "branch")
        base_branch=$(git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null)
        target_files=$(git diff "$base_branch..HEAD" --name-only --diff-filter=ACMR 2>/dev/null)
        ;;
    commit-range=*)
        range="${git_scope#commit-range=}"
        target_files=$(git diff "$range" --name-only --diff-filter=ACMR 2>/dev/null)
        ;;
esac

# Filter by file pattern if specified
if [[ -n "$file_pattern" ]]; then
    target_files=$(echo "$target_files" | grep -E "$file_pattern" 2>/dev/null)
fi

# Show git statistics
echo "## Git Scope: $git_scope"
echo "Files in scope: $(echo "$target_files" | grep -c . 2>/dev/null || echo "0")"
if [[ -n "$target_files" ]]; then
    echo ""
    echo "### Files to process:"
    echo "$target_files" | head -10
    if [[ $(echo "$target_files" | wc -l) -gt 10 ]]; then
        echo "... and $(($(echo "$target_files" | wc -l) - 10)) more files"
    fi
    echo ""
fi
```

### Phase 1: Architecture-Aware Analysis (when integrated with analyze-codebase)

1. **Understand Codebase Context**
   - Identify key architectural patterns and conventions
   - Map critical system components and their responsibilities
   - Understand established documentation patterns
   - Identify complex modules requiring careful comment preservation

### Phase 2: Targeted Comment Analysis

2. **Scan Files**
   - Find all files matching the pattern (or entire codebase if no pattern specified)
   - Prioritize files with most comment issues (using codebase analysis)
   - Identify different types of comments in context of project patterns
   - Categorize by clean code rules while respecting architecture

### Phase 3: Context-Aware Cleaning

3. **Clean Bad Comments**
   - Remove redundant comments that repeat code
   - Remove obvious noise comments
   - Remove closing brace comments
   - Remove commented-out code blocks
   - **Preserve architectural explanations** identified in Phase 1

4. **Preserve Good Comments**
   - Keep intent explanations and clarifications
   - Keep consequence warnings
   - Keep legal/copyright notices
   - Keep TODO comments
   - **Keep system design documentation** critical to understanding
   - **Keep pattern explanations** that help maintain conventions

5. **Suggest Code Improvements**
   - Identify where comments can be replaced with better naming
   - Suggest function extractions for complex logic
   - **Recommend architectural improvements** based on codebase analysis
