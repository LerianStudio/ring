---
allowed-tools: Read(*), Glob(*), Grep(*), Bash(*), Task(*)
description: Comprehensive code quality review with actionable recommendations and git diff analysis
argument-hint: [--target=<path>] [--git-scope=<scope>] [--diff-context]
---

# /ring-dev-team:quality:code-review

## Overview

Performs comprehensive code quality review with security, performance, and maintainability analysis. Supports focused git-scope analysis for active development workflows and traditional path-based analysis.

### Purpose

- Comprehensive code quality review with security, performance, and maintainability analysis
- Git-focused analysis for faster, more relevant results during development
- Structured reporting with actionable recommendations
- Integration with development workflows through git scope targeting

### Scope

Covers complete code quality assessment including security vulnerabilities, performance bottlenecks, maintainability issues, and technical debt analysis with detailed reporting.

## Context

This command provides systematic code quality assessment focused on identifying issues, vulnerabilities, and improvement opportunities without making changes to the codebase.

## Usage Examples

```bash
# Git-focused review (recommended for active development)
/ring-dev-team:quality:code-review --git-scope=all-changes                   # Review all git changes
/ring-dev-team:quality:code-review --git-scope=staged                        # Review staged files only
/ring-dev-team:quality:code-review --git-scope=branch                        # Review feature branch changes
/ring-dev-team:quality:code-review --git-scope=all-changes --diff-context    # Review with git diff context

# Traditional scope-based review
/ring-dev-team:quality:code-review                                            # Review entire repository
/ring-dev-team:quality:code-review --target=src/                             # Focus on specific directory
/ring-dev-team:quality:code-review --target=src/api/users.ts                 # Review specific file
/ring-dev-team:quality:code-review --target=src/components/                  # Review component directory

# Combined approaches
/ring-dev-team:quality:code-review --git-scope=branch --target=src/          # Review branch changes in src/ only
```

## Review Process

### 1. Initial Analysis

**Git-Focused Analysis** (when `--git-scope` used):

```bash
# Validate git repository and get target files
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Error: Not a git repository. Git-focused options require a git repository." >&2
    exit 1
fi

# Show git scope statistics
echo "## Git Changes Analysis"
case "$git_scope" in
    "staged")
        echo "Reviewing staged files only"
        git diff --cached --stat
        ;;
    "branch")
        echo "Reviewing feature branch changes vs main/master"
        base_branch=$(git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null)
        git diff --stat "$base_branch..HEAD"
        ;;
    "all-changes")
        echo "Reviewing all uncommitted changes"
        git diff --stat HEAD
        ;;
esac

# Show diff context if requested
if [[ "$diff_context" == "true" ]]; then
    echo ""
    echo "### Code Changes Context:"
    git diff --unified=3 ${git_range} | head -50
    if [[ $(git diff --unified=3 ${git_range} | wc -l) -gt 50 ]]; then
        echo "... (truncated, use git diff for full context)"
    fi
    echo ""
fi
```

**Traditional Analysis**:

- Examine repository structure and identify framework/language
- Check for configuration files (package.json, tsconfig.json, .eslintrc, etc.)
- Review README and documentation for context

### 2. Code Quality Assessment

- Scan for code smells, anti-patterns, and potential bugs
- Check for consistent coding style and naming conventions
- Identify unused imports, variables, or dead code
- Review error handling and logging practices
- Evaluate code complexity and maintainability

### 3. Security Review

- Look for common vulnerabilities (injection, XSS, etc.)
- Check for hardcoded secrets, API keys, or passwords
- Review authentication and authorization implementation
- Examine input validation and sanitization
- Check for secure headers and CORS configuration
- Review dependencies for known vulnerabilities
- OWASP Top 10 compliance check

### 4. Performance Analysis

- Identify inefficient algorithms and data structures
- Check for memory leaks (event listeners, timers)
- Review database query optimization
- Analyze bundle size and import strategies
- Check for unnecessary dependencies
- Review async/await and Promise handling
- Identify opportunities for caching and lazy loading

### 5. Testing & Documentation

- Check existing test coverage and quality
- Identify areas lacking proper testing
- Evaluate code comments and inline documentation
- Review API documentation completeness
- Assess README and setup instructions

### 6. Recommendation Generation

**Analysis Output**:

- Prioritized list of issues found
- Specific file and line number references
- Detailed explanations of problems
- Suggested solutions with code examples

**Report Categories**:

- Critical security vulnerabilities
- Performance optimization opportunities
- Maintainability improvements needed
- Technical debt assessment
- Testing gap analysis

## Output Format

**IMPORTANT: All findings must be presented in structured tables for better visual clarity and organization.**

```markdown
# Code Review Report

## Executive Summary

| Metric          | Value      | Status   |
| --------------- | ---------- | -------- |
| Files Reviewed  | [X] files  | ℹ️       |
| Critical Issues | [Y] issues | 🔴       |
| Warnings        | [Z] issues | 🟡       |
| Suggestions     | [A] items  | 🟢       |
| Overall Score   | [B]/10     | ✅/⚠️/❌ |

## Git Analysis (when using git-scope)

| Property             | Value                     |
| -------------------- | ------------------------- |
| **Scope**            | [git-scope value]         |
| **Files in Scope**   | [number of files]         |
| **Lines Changed**    | +[additions] -[deletions] |
| **Commits Reviewed** | [commit range]            |
| **Branch**           | [current branch]          |

## 🔴 Critical Issues (Must Fix Immediately)

| #   | File               | Line | Issue               | Severity    | Impact           |
| --- | ------------------ | ---- | ------------------- | ----------- | ---------------- |
| 1   | `path/to/file.js`  | 45   | [Brief description] | 🔴 Critical | [Impact summary] |
| 2   | `path/to/other.ts` | 128  | [Brief description] | 🔴 Critical | [Impact summary] |

### Detailed Critical Issues

**For each critical issue, provide:**

| Issue               | Details                                  |
| ------------------- | ---------------------------------------- |
| **File**            | `path/to/file.js:45`                     |
| **Category**        | Security/Performance/Logic               |
| **Description**     | [Detailed explanation]                   |
| **Current Code**    | `javascript<br/>[problematic code]<br/>` |
| **Recommended Fix** | `javascript<br/>[corrected code]<br/>`   |
| **Risk Level**      | High/Medium/Low                          |
| **Effort Required** | 1-5 story points                         |

## 🟡 Warnings (Should Address Soon)

| #   | File             | Line | Issue         | Category        | Priority |
| --- | ---------------- | ---- | ------------- | --------------- | -------- |
| 1   | `src/utils.js`   | 23   | [Description] | Code Quality    | High     |
| 2   | `src/api.ts`     | 67   | [Description] | Performance     | Medium   |
| 3   | `src/helpers.js` | 145  | [Description] | Maintainability | Medium   |

## 🟢 Suggestions (Nice to Have)

| #   | File              | Area         | Suggestion               | Benefit         | Effort |
| --- | ----------------- | ------------ | ------------------------ | --------------- | ------ |
| 1   | `src/components/` | React        | Implement useCallback    | Performance     | Low    |
| 2   | `src/types/`      | TypeScript   | Add stricter types       | Type Safety     | Medium |
| 3   | `src/utils/`      | Architecture | Extract common utilities | Maintainability | Low    |

## Code Quality Metrics

| Metric                    | Current | Target | Status   | Trend   |
| ------------------------- | ------- | ------ | -------- | ------- |
| **Cyclomatic Complexity** | X.X     | <10    | ✅/⚠️/❌ | ↗️/→/↘️ |
| **Code Duplication**      | X.X%    | <5%    | ✅/⚠️/❌ | ↗️/→/↘️ |
| **Test Coverage**         | XX%     | >80%   | ✅/⚠️/❌ | ↗️/→/↘️ |
| **Type Coverage**         | XX%     | >95%   | ✅/⚠️/❌ | ↗️/→/↘️ |
| **Bundle Size**           | XXkB    | <500kB | ✅/⚠️/❌ | ↗️/→/↘️ |
| **Performance Score**     | XX/100  | >90    | ✅/⚠️/❌ | ↗️/→/↘️ |

## Security Analysis

| Check                          | Result   | Details               |
| ------------------------------ | -------- | --------------------- |
| **Input Validation**           | ✅/⚠️/❌ | [Summary of findings] |
| **Authentication**             | ✅/⚠️/❌ | [Summary of findings] |
| **Authorization**              | ✅/⚠️/❌ | [Summary of findings] |
| **Data Sanitization**          | ✅/⚠️/❌ | [Summary of findings] |
| **Dependency Vulnerabilities** | ✅/⚠️/❌ | [Summary of findings] |
| **Secrets Exposure**           | ✅/⚠️/❌ | [Summary of findings] |
| **OWASP Compliance**           | ✅/⚠️/❌ | [Summary of findings] |

## Performance Analysis

| Area                     | Score | Issues Found   | Recommendations       |
| ------------------------ | ----- | -------------- | --------------------- |
| **Algorithm Efficiency** | X/10  | [count] issues | [Key recommendations] |
| **Memory Usage**         | X/10  | [count] issues | [Key recommendations] |
| **Database Queries**     | X/10  | [count] issues | [Key recommendations] |
| **Bundle Optimization**  | X/10  | [count] issues | [Key recommendations] |
| **Async Operations**     | X/10  | [count] issues | [Key recommendations] |

## File-by-File Analysis

| File                        | Issues | Warnings | Suggestions | Score  | Priority |
| --------------------------- | ------ | -------- | ----------- | ------ | -------- |
| `src/app.js`                | 0      | 2        | 1           | 8.5/10 | Medium   |
| `src/api/users.js`          | 1      | 1        | 3           | 6.2/10 | High     |
| `src/components/Header.tsx` | 0      | 0        | 2           | 9.1/10 | Low      |

## Testing Analysis

| Test Category         | Coverage | Quality        | Missing Areas             |
| --------------------- | -------- | -------------- | ------------------------- |
| **Unit Tests**        | XX%      | Good/Fair/Poor | [List of uncovered areas] |
| **Integration Tests** | XX%      | Good/Fair/Poor | [List of uncovered areas] |
| **E2E Tests**         | XX%      | Good/Fair/Poor | [List of uncovered areas] |
| **Security Tests**    | XX%      | Good/Fair/Poor | [List of uncovered areas] |

## ✨ Positive Findings

| Category         | Finding                   | Impact                |
| ---------------- | ------------------------- | --------------------- |
| **Architecture** | [Strong point observed]   | [Benefit description] |
| **Code Quality** | [Good pattern identified] | [Benefit description] |
| **Security**     | [Commendable practice]    | [Benefit description] |
| **Performance**  | [Optimization found]      | [Benefit description] |

## Action Plan

| Priority           | Task                           | Files Affected           | Estimated Effort | Owner        |
| ------------------ | ------------------------------ | ------------------------ | ---------------- | ------------ |
| **🔴 Immediate**   | Fix SQL injection in users API | `src/api/users.js`       | 2 hours          | Backend Dev  |
| **🔴 Immediate**   | Add authentication middleware  | `src/routes/admin.js`    | 1 hour           | Backend Dev  |
| **🟡 This Sprint** | Improve test coverage          | `src/utils/`, `src/api/` | 1 day            | QA Team      |
| **🟡 This Sprint** | Refactor duplicate code        | `src/components/`        | 4 hours          | Frontend Dev |
| **🟢 Next Sprint** | Add TypeScript strict mode     | All `.js` files          | 2 days           | Full Team    |

## Recommended Next Steps

1. **Immediate Actions** (< 1 day)
   - Address all critical security issues
   - Fix blocking bugs

2. **Short Term** (This Sprint)
   - Resolve high-priority warnings
   - Improve test coverage to >80%

3. **Long Term** (Next Sprint+)
   - Technical debt reduction
   - Performance optimizations
   - Documentation improvements
```

## Review Categories

### Security


- Input validation and sanitization
- Authentication and authorization
- Secure data storage and transmission
- Dependency vulnerabilities
- OWASP Top 10 compliance

### Performance

- Algorithm efficiency (O(n) complexity)
- Database query optimization
- Caching strategies
- Bundle size impact
- Memory usage patterns

### Code Quality

- SOLID principles adherence
- DRY (Don't Repeat Yourself)
- Clear naming conventions
- Proper error handling
- Test coverage

### Maintainability

- Code readability
- Documentation completeness
- Modular architecture
- Dependency management
- Technical debt assessment

## Frontend-Specific Reviews

### React/TypeScript

- Component re-render optimization (useMemo, useCallback)
- Memory leaks in useEffect hooks
- Bundle size and tree shaking effectiveness
- TypeScript strict mode compliance
- Accessibility (a11y) compliance
- State management patterns (Context vs external stores)

### Performance & UX

- Core Web Vitals optimization
- Image optimization and lazy loading
- Route-based code splitting
- CSS-in-JS performance impact
- Mobile responsiveness
- Progressive Web App features

### Security & Best Practices

- XSS prevention in dynamic content
- Content Security Policy implementation
- Authentication token handling
- API key security (environment variables)
- Third-party library vulnerability scan

Remember to be constructive and provide specific examples with file paths and line numbers where applicable.
