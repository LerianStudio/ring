---
name: ring:generating-pr-descriptions
description: "Generating pull request descriptions from git branch changes with automatic title generation, change-type detection, and smart analysis. Uses branch-only scope to avoid full history analysis. Use when preparing a PR for review. Skip when the PR is a single trivial commit or description already exists."
user-invocable: true
argument-hint: "[base-branch]"
---

# Generating PR Descriptions

## When to use
- Preparing a pull request for review and need a comprehensive description
- Generating a PR title automatically from commit message analysis
- Classifying the type of change (bug fix, feature, breaking change)
- Saving a reusable PR description to `docs/pr-descriptions/<branch-name-with-hyphens>.md`

## Skip when
- The PR is a single trivial commit with an obvious description
- A PR description already exists and does not need regeneration
- The branch has no commits beyond the base branch

## Process

### 1. Git Branch Analysis - CRITICAL: Branch-Only Scope

- **MANDATORY**: Identify actual branch point to avoid analyzing entire development history
- Detect the base branch (develop, main, master) that the current branch was created from
- **CORRECT APPROACH**: Use `git merge-base HEAD <base-branch>` to find the true divergence point
- **CORRECT APPROACH**: Use `git log --oneline $(git merge-base HEAD <base-branch>)..HEAD` for branch-specific commits
- **CORRECT APPROACH**: Use `git diff $(git merge-base HEAD <base-branch>)..HEAD` for branch-specific changes
- **NEVER** rely on manual `HEAD~n` counting — it breaks on merges, rebases, and long-lived branches
- Run `git status --porcelain` to identify uncommitted files (excluded from PR)
- **Enforce that PR analyzes ONLY commits made on the current feature branch, not development history**
- Determine if this is a bug fix, feature, or breaking change based on actual branch commits

### 2. Change Classification

- Analyze file patterns and change types
- Identify the type of change (bug fix, new feature, breaking change, etc.)
- Detect if documentation updates are needed
- Determine testing requirements

### 3. PR Description Generation

- Create comprehensive description following the template format
- Include summary of changes and motivation based on ONLY branch-specific commits
- Pre-fill appropriate checkboxes based on change analysis
- Suggest testing strategies
- Derive the output filename from the full branch name with slashes replaced by hyphens (e.g., `feature/FE-157` -> `feature-FE-157.md`)
- Save to `docs/pr-descriptions/<derived-filename>` (create directory if needed)

## CRITICAL Implementation Steps

### Step 1: Branch Analysis (MANDATORY)

```bash
# 1. Get branch structure to identify commits
git log --oneline --decorate --graph -10

# 2. Count commits unique to current branch
# Look for where branch diverged from main/develop
# Example output shows 2 commits on feature/PLU-393:
# * 06603bf (HEAD -> feature/PLU-393) fix(i18n): add missing translations
# * d40c631 feat(ui): enhance templates system with calendar filter
# * 30664b1 (develop) Merge branch 'develop' into feature/libs
```

### Step 2: Extract Branch-Only Changes (MANDATORY)

```bash
# Use HEAD~n where n = number of branch commits
git log --oneline HEAD~2..HEAD           # Get branch commits
git diff HEAD~2..HEAD --name-status      # Get changed files
git diff HEAD~2..HEAD --stat            # Get change statistics
```

### Step 3: Validation (MANDATORY)

- Verify commit count matches actual branch commits
- Ensure no base branch commits are included in analysis
- Confirm file changes align with branch purpose

**WRONG APPROACH - DO NOT USE:**

```bash
git log main..HEAD      # Includes entire development history
git diff main...HEAD    # Includes all changes since branch creation
```

## Generated Template Structure

The skill generates pull requests following this exact structure:

```markdown
# [Auto-generated PR title: short, under 70 chars, using conventional commit prefix]

# Description

[Auto-generated summary of changes and motivation based on commits]

## Type of change

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] This change requires a documentation update
```

### PR Title Generation

- **Auto-generated** from commit message analysis
- Uses conventional commit prefix (`feat:`, `fix:`, `chore:`, `refactor:`, etc.) based on the dominant change type
- Kept under 70 characters, concise and descriptive
- Placed as the first `#` heading in the output file

### Change Type Detection

- **Bug fix**: Detects fixes, corrections, and patches in commit messages
- **New feature**: Identifies new functionality, components, or capabilities
- **Breaking change**: Flags API changes, removed functionality, or incompatible changes
- **Documentation update**: Detects changes to .md files, comments, or docs folders

## Implementation Requirements - CRITICAL

**MANDATORY Git Command Usage:**

1. **Branch Point Detection:**

   ```bash
   git log --oneline --decorate --graph -10
   # Identify where current branch diverged from base
   # Count commits unique to current branch
   ```

2. **Branch-Only Analysis Commands:**

   ```bash
   # For 2 commits on current branch:
   git log --oneline HEAD~2..HEAD
   git diff HEAD~2..HEAD --name-status
   git diff HEAD~2..HEAD --stat

   # NEVER use these (includes all development history):
   git log main..HEAD  # WRONG
   git diff main...HEAD  # WRONG
   ```

3. **Branch Point Validation:**
   - If branch has 3 commits: use `HEAD~3..HEAD`
   - If branch has 5 commits: use `HEAD~5..HEAD`
   - **Always verify** commit count matches actual branch commits

## Smart Analysis Features

- **File Pattern Recognition**: Detects frontend/backend changes, test files, config changes
- **Commit Message Analysis**: Uses conventional commits to determine change types
- **Dependency Detection**: Identifies if package.json or similar files changed
- **Test Coverage**: Suggests appropriate testing based on changed components

## Notes

- **Critical**: Uses `HEAD~n..HEAD` approach to analyze ONLY current branch commits
- **Branch Validation**: Verifies number of commits on branch before analysis
- **Feature Branch Scope**: Analyzes only commits made specifically on the current feature branch
- **Committed Changes Only**: Analyzes committed changes in the branch only, ignores uncommitted files
- **Precise Scope**: Prevents inclusion of entire development history in PR description
- Generated PRs reflect actual feature branch changes, not cumulative project history
- Breaking changes are flagged based on actual branch commits only
- Generated PR descriptions are saved to `docs/pr-descriptions/<branch-name-with-hyphens>.md` for easy copying to GitHub/GitLab
