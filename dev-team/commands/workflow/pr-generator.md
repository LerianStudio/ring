---
allowed-tools: Bash(*), Read(*), Grep(*), Write(*)
description: Generate pull request descriptions based on git changes and save as pull-request.md
argument-hint: [--title=<title>] [--issue=<issue-number>] (optional PR title and issue number)
---

# PR Generator

## Overview

Analyzes current git branch changes and generates comprehensive pull request descriptions following the standard template structure, then saves them to `pull-request.md` in the project root.

## Usage

This command examines only the commits made on your current feature branch (compared to its base branch like develop/main) to generate a detailed pull request description that follows the standard template structure.

```bash
/shared:development:pr-generator
/shared:development:pr-generator --title="Add user authentication system"
/shared:development:pr-generator --issue=123
/shared:development:pr-generator --title="Fix login bug" --issue=456
```

## Process

### 1. Git Branch Analysis - CRITICAL: Branch-Only Scope

- **MANDATORY**: Identify actual branch point to avoid analyzing entire development history
- Detects the base branch (develop, main, master) that the current branch was created from
- **CRITICAL**: Uses `git log --oneline --decorate --graph -10` to identify the true branch start point
- **NEVER** use `git log main..HEAD` or `git diff main...HEAD` as this includes all history
- **CORRECT APPROACH**: Use `git diff HEAD~n..HEAD` where n = number of commits on the current branch
- **CORRECT APPROACH**: Use `git log --oneline HEAD~n..HEAD` to get only branch-specific commits
- Runs `git status --porcelain` to identify uncommitted files (excluded from PR)
- **Enforces that PR analyzes ONLY commits made on the current feature branch, not development history**
- Determines if this is a bug fix, feature, or breaking change based on actual branch commits

### 2. Change Classification

- Analyzes file patterns and change types
- Identifies the type of change (bug fix, new feature, breaking change, etc.)
- Detects if documentation updates are needed
- Determines testing requirements

### 3. PR Description Generation

- Creates comprehensive description following the template format
- Includes summary of changes and motivation based on ONLY branch-specific commits
- Pre-fills appropriate checkboxes based on change analysis
- Suggests testing strategies
- Saves the generated description to `pull-request.md` in the project root

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
git log main..HEAD      # ❌ Includes entire development history
git diff main...HEAD    # ❌ Includes all changes since branch creation
```

## Generated Template Structure

The command generates pull requests following this exact structure:

```markdown
# Description

[Auto-generated summary of changes and motivation based on commits]

Fixes # (issue)

## Type of change

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] This change requires a documentation update

# How Has This Been Tested?

[Auto-suggested tests based on changed files and patterns]

- [ ] Test A
- [ ] Test B

# Checklist:

- [ ] My code follows the style guidelines of this project
- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] Any dependent changes have been merged and published in downstream modules
```

### Change Type Detection

- **Bug fix**: Detects fixes, corrections, and patches in commit messages
- **New feature**: Identifies new functionality, components, or capabilities
- **Breaking change**: Flags API changes, removed functionality, or incompatible changes
- **Documentation update**: Detects changes to .md files, comments, or docs folders

## Examples

### Basic Feature Addition

```bash
/shared:development:pr-generator
```

**Output in pull-request.md:**

```markdown
# Description

This PR adds user authentication system including JWT token validation, login/logout endpoints, and user session management.

Fixes # (issue)

## Type of change

- [ ] Bug fix (non-breaking change which fixes an issue)
- [x] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] This change requires a documentation update

# How Has This Been Tested?

Manual testing of login/logout flow, unit tests for authentication endpoints, integration tests for JWT token validation.

- [x] Manual testing of login/logout flow
- [x] Unit tests for authentication endpoints

# Checklist:

- [x] My code follows the style guidelines of this project
- [x] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [x] I have added tests that prove my fix is effective or that my feature works
- [x] New and existing unit tests pass locally with my changes
- [ ] Any dependent changes have been merged and published in downstream modules
```

### With Custom Title and Issue

```bash
/shared:development:pr-generator --title="Fix authentication timeout issue" --issue=789
```

**Output:**

```markdown
# Description

Fix authentication timeout issue - extends session timeout from 1 hour to 24 hours and adds proper token refresh mechanism.

Fixes #789

## Type of change

- [x] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] This change requires a documentation update

# How Has This Been Tested?

Manual testing with extended session scenarios, unit tests for timeout logic.

- [x] Manual testing with extended sessions
- [x] Unit tests for timeout configuration

# Checklist:

- [x] My code follows the style guidelines of this project
- [x] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [x] I have added tests that prove my fix is effective or that my feature works
- [x] New and existing unit tests pass locally with my changes
- [ ] Any dependent changes have been merged and published in downstream modules
```

## Smart Analysis Features

- **File Pattern Recognition**: Detects frontend/backend changes, test files, config changes
- **Commit Message Analysis**: Uses conventional commits to determine change types
- **Dependency Detection**: Identifies if package.json or similar files changed
- **Test Coverage**: Suggests appropriate testing based on changed components

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
   git log main..HEAD  # ❌ WRONG
   git diff main...HEAD  # ❌ WRONG
   ```

3. **Branch Point Validation:**
   - If branch has 3 commits: use `HEAD~3..HEAD`
   - If branch has 5 commits: use `HEAD~5..HEAD`
   - **Always verify** commit count matches actual branch commits

## Notes

- **Critical**: Uses `HEAD~n..HEAD` approach to analyze ONLY current branch commits
- **Branch Validation**: Verifies number of commits on branch before analysis
- **Feature Branch Scope**: Analyzes only commits made specifically on the current feature branch
- **Committed Changes Only**: Analyzes committed changes in the branch only, ignores uncommitted files
- **Precise Scope**: Prevents inclusion of entire development history in PR description
- Generated PRs reflect actual feature branch changes, not cumulative project history
- Breaking changes are flagged based on actual branch commits only
- Generated PR descriptions are saved to `pull-request.md` for easy copying to GitHub/GitLab
