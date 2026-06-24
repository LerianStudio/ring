---
name: ring:cleaning-comments
description: "Cleaning redundant and obvious comments following clean code principles while preserving meaningful documentation. Supports git scope filtering (staged, unstaged, branch, commit-range). Use when code has excessive comments, during code review, or post-refactor cleanup. Skip when reviewing documentation files or comments are already minimal."
user-invocable: true
argument-hint: "[file-pattern=<pattern>] [git-scope=<scope>] [dry-run]"
---

# Cleaning Comments

## When to use
- Code has excessive, redundant, or obvious comments
- During code review or post-refactor cleanup
- Before committing to clean up comment noise in changed files
- Codebase has accumulated commented-out code blocks

## Skip when
- Reviewing documentation files (README, docs/, etc.)
- Comments are already minimal and meaningful
- Working with generated code or third-party files

## Sequence
**Runs after:** ring:exploring-codebases (optional, for architecture context)

## Related
**Complementary:** ring:exploring-codebases — run first for architecture-aware cleaning that preserves critical documentation

---

Analyze comments in code and remove those that violate clean code principles while preserving valuable ones. You can focus on git changes for faster, more relevant cleaning, or analyze the entire codebase.

**Recommended workflow:** Run `ring:exploring-codebases` first to understand the architecture, then clean comments with that context. This preserves architectural documentation, understands which comments are critical for complex modules, and respects project-specific documentation standards.

## Clean Code Comment Rules

1. **Always try to explain yourself in code** — Remove comments that can be replaced with better function/variable names
2. **Don't be redundant** — Remove comments that just repeat what the code obviously does
3. **Don't add obvious noise** — Remove comments like `i++; // increment i`
4. **Don't use closing brace comments** — Remove `} // end of if block` style comments
5. **Don't comment out code** — Remove commented-out code blocks
6. **Keep explanation of intent** — Preserve comments explaining WHY, not WHAT
7. **Keep warnings of consequences** — Preserve comments about important side effects
8. **Keep legal and informative comments** — Preserve copyright, licenses, TODOs

## Examples

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

If `git-scope` is specified, determine files in scope:

| Scope | Git command |
|-------|------------|
| `staged` | `git diff --cached --name-only --diff-filter=ACMR` |
| `unstaged` | `git diff --name-only --diff-filter=ACMR` |
| `all-changes` | `git diff HEAD --name-only --diff-filter=ACMR` |
| `last-commit` | `git diff HEAD~1..HEAD --name-only --diff-filter=ACMR` |
| `branch` | `git diff $(git merge-base HEAD main)..HEAD --name-only --diff-filter=ACMR` |
| `commit-range=<range>` | `git diff <range> --name-only --diff-filter=ACMR` |

If `file-pattern` is also specified, filter the git results to match. Show git statistics: scope name, file count, and first 10 filenames.

### Phase 1: Architecture-Aware Analysis

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
