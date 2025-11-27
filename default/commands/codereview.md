---
name: codereview
description: Run comprehensive parallel code review with all 3 specialized reviewers
argument-hint: "[files-or-paths]"
---

Dispatch all 3 specialized code reviewers in parallel, collect their reports, and provide a consolidated analysis.

## Review Process

### Step 1: Dispatch All Three Reviewers in Parallel

**CRITICAL: Use a single message with 3 Task tool calls to launch all reviewers simultaneously.**

Gather the required context first:
- WHAT_WAS_IMPLEMENTED: Summary of changes made
- PLAN_OR_REQUIREMENTS: Original plan or requirements (if available)
- BASE_SHA: Base commit for comparison (if applicable)
- HEAD_SHA: Head commit for comparison (if applicable)
- DESCRIPTION: Additional context about the changes

Then dispatch all 3 reviewers:

```
Task tool #1 (ring:code-reviewer):
  model: "opus"
  description: "Review code quality and architecture"
  prompt: |
    WHAT_WAS_IMPLEMENTED: [summary of changes]
    PLAN_OR_REQUIREMENTS: [original plan/requirements]
    BASE_SHA: [base commit if applicable]
    HEAD_SHA: [head commit if applicable]
    DESCRIPTION: [additional context]

Task tool #2 (ring:business-logic-reviewer):
  model: "opus"
  description: "Review business logic correctness"
  prompt: |
    [Same parameters as above]

Task tool #3 (ring:security-reviewer):
  model: "opus"
  description: "Review security vulnerabilities"
  prompt: |
    [Same parameters as above]
```

**Wait for all three reviewers to complete their work.**

### Step 2: Collect and Aggregate Reports

Each reviewer returns:
- **Verdict:** PASS/FAIL/NEEDS_DISCUSSION
- **Strengths:** What was done well
- **Issues:** Categorized by severity (Critical/High/Medium/Low/Cosmetic)
- **Recommendations:** Specific actionable feedback

Consolidate all issues by severity across all three reviewers.

### Step 3: Provide Consolidated Report

Return a consolidated report in this format:

```markdown
# Full Review Report

## VERDICT: [PASS | FAIL | NEEDS_DISCUSSION]

## Executive Summary

[2-3 sentences about overall review across all gates]

**Total Issues:**
- Critical: [N across all gates]
- High: [N across all gates]
- Medium: [N across all gates]
- Low: [N across all gates]

---

## Code Quality Review (Foundation)

**Verdict:** [PASS | FAIL]
**Issues:** Critical [N], High [N], Medium [N], Low [N]

### Critical Issues
[List all critical code quality issues]

### High Issues
[List all high code quality issues]

[Medium/Low issues summary]

---

## Business Logic Review (Correctness)

**Verdict:** [PASS | FAIL]
**Issues:** Critical [N], High [N], Medium [N], Low [N]

### Critical Issues
[List all critical business logic issues]

### High Issues
[List all high business logic issues]

[Medium/Low issues summary]

---

## Security Review (Safety)

**Verdict:** [PASS | FAIL]
**Issues:** Critical [N], High [N], Medium [N], Low [N]

### Critical Vulnerabilities
[List all critical security vulnerabilities]

### High Vulnerabilities
[List all high security vulnerabilities]

[Medium/Low vulnerabilities summary]

---

## Consolidated Action Items

**MUST FIX (Critical):**
1. [Issue from any gate] - `file:line`
2. [Issue from any gate] - `file:line`

**SHOULD FIX (High):**
1. [Issue from any gate] - `file:line`
2. [Issue from any gate] - `file:line`

**CONSIDER (Medium/Low):**
[Brief list]

---

## Next Steps

**If PASS:**
- ✅ All 3 reviewers passed
- ✅ Ready for next step (merge/production)

**If FAIL:**
- ❌ Fix all Critical/High/Medium issues immediately
- ❌ Add TODO(review) comments for Low issues in code
- ❌ Add FIXME(nitpick) comments for Cosmetic/Nitpick issues in code
- ❌ Re-run all 3 reviewers in parallel after fixes

**If NEEDS_DISCUSSION:**
- 💬 [Specific discussion points across gates]
```

## Severity-Based Action Guide

After producing the consolidated report, provide clear guidance:

**Critical/High/Medium Issues:**
```
These issues MUST be fixed immediately:
1. [Issue description] - file.ext:line - [Reviewer]
2. [Issue description] - file.ext:line - [Reviewer]

Recommended approach:
- Dispatch fix subagent to address all Critical/High/Medium issues
- After fixes complete, re-run all 3 reviewers in parallel to verify
```

**Low Issues:**
```
Add TODO comments in the code for these issues:

// TODO(review): [Issue description]
// Reported by: [reviewer-name] on [date]
// Severity: Low
// Location: file.ext:line
```

**Cosmetic/Nitpick Issues:**
```
Add FIXME comments in the code for these issues:

// FIXME(nitpick): [Issue description]
// Reported by: [reviewer-name] on [date]
// Severity: Cosmetic
// Location: file.ext:line
```

## Remember

1. **All reviewers are independent** - They run in parallel, not sequentially
2. **Dispatch all 3 reviewers in parallel** - Single message, 3 Task calls
3. **Specify model: "opus"** - All reviewers need opus for comprehensive analysis
4. **Wait for all to complete** - Don't aggregate until all reports received
5. **Consolidate findings by severity** - Group all issues across reviewers
6. **Provide clear action guidance** - Tell user exactly what to fix vs. document
7. **Overall FAIL if any reviewer fails** - One failure means work needs fixes
