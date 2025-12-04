---
allowed-tools: Bash(*), Read(*), Edit(*), Grep(*), Task(*), TodoWrite(*)
description: Unified problem resolution with multiple sources for error messages, issue files, or descriptions
argument-hint: [--input=<file-path-or-text>] [--git-scope=<scope>]
---

# /ring-dev-team:debugging:fix-problem

Unified problem resolution command supporting multiple input sources for comprehensive debugging and issue resolution.

## Background Information

Problem resolution involves systematic investigation across different input types: runtime errors, documented issues, or problem descriptions. This unified command provides source-based routing to appropriate debugging methodologies while maintaining comprehensive root cause analysis and prevention strategies.

## Usage Patterns

```bash
# Git-focused problem resolution (recommended for active development)
/ring-dev-team:debugging:fix-problem --input="TypeError: Cannot read property 'id' of undefined" --git-scope=all-changes
/ring-dev-team:debugging:fix-problem --input="API returns 500 on user login" --git-scope=branch
/ring-dev-team:debugging:fix-problem --input=issues/bug-report.md --git-scope=staged

# Traditional problem resolution
/ring-dev-team:debugging:fix-problem --input="TypeError: Cannot read property 'id' of undefined"
/ring-dev-team:debugging:fix-problem --input=issues/bug-report.md
/ring-dev-team:debugging:fix-problem --input="API returns 500 on user login"
/ring-dev-team:debugging:fix-problem --input="Memory leak in production after 24 hours"
```

**Arguments:**

- `--input`: Error message, issue file path, or problem description (required)
- `--git-scope`: Git scope for focusing problem analysis on specific changes - staged|unstaged|all-changes|branch|last-commit|commit-range=<range> (optional)

## Initial Setup

### Git Scope Analysis (when --git-scope used)

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

**Git-Scope Problem Resolution Benefits:**

- **Contextual Investigation**: Focus problem analysis on recently changed code where issues are likely introduced
- **Efficient Debugging**: Narrow investigation scope to relevant files and areas
- **Change Attribution**: Connect problems to specific changes, commits, or features
- **Root Cause Analysis**: Analyze how recent changes might have introduced or exposed the problem

## Source-Based Processing

### Error Source Mode

**Purpose**: Systematically debug and fix runtime errors with comprehensive root cause analysis

**Focus**: Error messages, stack traces, runtime issues, exceptions

**Process**:

1. **Error Information Gathering**: Collect complete error details, timing, environment, logs
2. **Reproduce the Error**: Create minimal test case, document reproduction steps
3. **Stack Trace Analysis**: Trace execution path, identify origin point
4. **Code Context Investigation**: Examine surrounding code, recent changes, variable states
5. **Hypothesis Formation**: Form evidence-based theories about root cause
6. **Systematic Testing**: Test hypotheses with targeted experiments
7. **Fix Implementation**: Implement solution, verify resolution
8. **Prevention Strategy**: Add safeguards, tests, monitoring to prevent recurrence

### Issue Source Mode

**Purpose**: Resolve issues described in markdown files with structured analysis

**Focus**: Bug reports, feature requests, documented problems

**Process**:

1. **Issue Analysis**: Read issue file, parse details, identify type and severity
2. **Environment Setup**: Ensure correct branch, pull latest changes, create feature branch
3. **Reproduce the Issue**: Follow reproduction steps, confirm issue exists
4. **Root Cause Analysis**: Search codebase, locate problematic code, identify root cause
5. **Solution Design**: Design comprehensive fix addressing root cause with edge cases
6. **Implementation**: Implement clean, focused code following project standards
7. **Testing Strategy**: Write/update tests, verify existing tests pass, check for regressions
8. **Code Quality Checks**: Run linting, formatting, static analysis, security checks
9. **Documentation Updates**: Update docs, comments, changelog as needed

### Description Source Mode

**Purpose**: Resolve problems from natural language descriptions

**Focus**: User-reported issues, observed behaviors, system problems

**Process**:

1. **Problem Clarification**: Parse description, identify key symptoms and context
2. **Information Gathering**: Collect additional context through codebase analysis
3. **Symptom Analysis**: Map described symptoms to potential code areas
4. **Investigation Strategy**: Develop targeted search and analysis approach
5. **Root Cause Investigation**: Use systematic debugging to identify source
6. **Solution Implementation**: Apply appropriate fix based on problem type
7. **Verification**: Confirm resolution addresses original description
8. **Documentation**: Document findings and prevention strategies

## Source Examples

### Error Source Example

```bash
/ring-dev-team:debugging:fix-problem --source=error --input="TypeError: Cannot read property 'id' of undefined"
```

**Process Flow**:

1. **Analyze Error**: Parse error type, identify null/undefined access pattern
2. **Search Codebase**: Find all locations accessing `.id` property
3. **Reproduce**: Create test case that triggers the error
4. **Identify Root Cause**: Determine why object is undefined at access time
5. **Implement Fix**: Add null checks, default values, or proper initialization
6. **Add Prevention**: Include TypeScript types, validation, tests

**Common Error Types**:

- **JavaScript/TypeScript Errors**: Undefined/null references, type errors, async issues
- **API/Network Errors**: 500 server errors, 404 not found, CORS issues, timeouts
- **Performance Issues**: Memory leaks, CPU spikes, slow rendering, bundle size
- **Build/Runtime Errors**: Module resolution, dependency conflicts, environment issues

### Issue Source Example

```bash
/ring-dev-team:debugging:fix-problem --source=issue --input=issues/login-bug-report.md
```

**Expected Issue File Format**:

```markdown
# Login Button Not Working

## Type

Bug

## Priority

High

## Description

Users cannot log in when clicking the login button. The button appears to work but no authentication occurs.

## Steps to Reproduce

1. Navigate to /login page
2. Enter valid credentials
3. Click "Login" button
4. Notice no redirect occurs

## Expected Behavior

User should be redirected to dashboard after successful login

## Actual Behavior

Button click has no effect, user remains on login page

## Environment

- Browser: Chrome 120.0
- OS: macOS 14.1
- App Version: 1.2.3
```

**Process Flow**:

1. **Parse Issue**: Extract bug type, reproduction steps, expected vs actual behavior
2. **Environment Setup**: Create feature branch, ensure reproducible environment
3. **Reproduce Bug**: Follow exact steps to confirm issue exists
4. **Investigate Code**: Search for login button handlers, authentication logic
5. **Identify Root Cause**: Find specific code causing the malfunction
6. **Implement Fix**: Apply targeted solution preserving functionality
7. **Test Thoroughly**: Verify fix works, no regressions introduced
8. **Document Solution**: Update issue with resolution details

### Description Source Example

```bash

/ring-dev-team:debugging:fix-problem --source=description --input="Users report slow page loading after recent deployment"
```

**Process Flow**:

1. **Parse Description**: Extract key symptoms (slow loading, recent deployment timing)
2. **Investigation Strategy**: Check recent commits, performance metrics, network requests
3. **Performance Analysis**: Profile application, identify bottlenecks
4. **Root Cause Analysis**: Correlate performance issues with recent changes
5. **Solution Implementation**: Apply performance optimizations or revert problematic changes
6. **Monitoring**: Add performance tracking to prevent future issues

## Quality Standards

### Universal Requirements

- Create comprehensive problem analysis before implementing solutions
- Maintain detailed documentation of investigation process and findings
- Ensure all solutions preserve existing functionality while fixing problems
- Implement appropriate testing to verify fixes and prevent regressions
- Follow project coding standards and conventions in all implementations

### Source-Specific Requirements

**Error Source Requirements**:

- Capture complete error context including stack traces and environment details
- Create reproducible test cases for systematic verification
- Implement appropriate error handling and logging improvements
- Add monitoring and alerting for similar future errors

**Issue Source Requirements**:

- Parse and validate issue file format for completeness
- Create feature branch following project naming conventions
- Implement comprehensive testing covering reported scenarios
- Update issue documentation with resolution details and closing information
- Generate pull request if significant changes are made

**Description Source Requirements**:

- Clarify ambiguous descriptions through systematic investigation
- Document assumptions made during problem interpretation
- Provide multiple solution options when problem scope is unclear
- Create detailed problem analysis report for future reference

### Safety Requirements

- Always create git checkpoints before making significant changes
- Verify fixes don't introduce new problems through comprehensive testing
- Maintain backward compatibility unless explicitly breaking change is required
- Document all changes with clear commit messages and pull request descriptions

## Execution Flow

1. **Source Detection**: Parse --source flag and route to appropriate debugging methodology
2. **Problem Analysis**: Apply source-specific analysis to understand the problem completely
3. **Investigation**: Use systematic approach to identify root cause through codebase examination
4. **Solution Design**: Develop comprehensive fix addressing root cause and edge cases
5. **Implementation**: Apply solution following project standards with appropriate testing
6. **Verification**: Confirm resolution works and doesn't introduce regressions
7. **Documentation**: Record findings, solution details, and prevention strategies

## Output Format

````markdown
# Problem Resolution Report: [Source] Source

## Problem Summary

- **Source Type**: [Error/Issue/Description]
- **Problem**: [Concise problem statement]
- **Priority**: [Critical/High/Medium/Low]
- **Environment**: [Relevant environment details]

## Investigation Results

### Root Cause Analysis

[Detailed explanation of underlying cause]

### Contributing Factors

- [Factor 1: explanation]
- [Factor 2: explanation]

### Impact Assessment

- [User impact description]
- [System impact description]

## Solution Implemented

### Approach

[Description of fix strategy and reasoning]

### Changes Made

1. **File:Line** - [Change description with rationale]
2. **File:Line** - [Change description with rationale]

### Code Changes

```diff
- [old problematic code]
+ [new fixed code]
```
````

## Verification

### Testing Results

- ✅ Original problem reproduction fails (fixed)
- ✅ Fix resolves the reported issue
- ✅ No regression in existing functionality
- ✅ Edge cases properly handled

### Quality Checks

- ✅ All tests pass
- ✅ Code quality standards maintained
- ✅ Performance impact assessed
- ✅ Security implications reviewed

## Prevention Measures

- [Safeguards added to prevent recurrence]
- [Monitoring/alerting improvements implemented]
- [Documentation updates made]
- [Process improvements identified]

## Next Steps

- [ ] [Any follow-up actions required]
- [ ] [Related issues to investigate]
- [ ] [Process improvements to implement]

```

**Migration Note**: This command consolidates functionality from the former `/debug-error` and `/fix-issue` commands into a unified interface with source-based routing.
```
