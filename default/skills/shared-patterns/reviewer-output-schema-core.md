# Reviewer Output Format (Core Sections)

**Version:** 1.0.0
**Applies to:** All reviewer agents

---

## Required Core Sections

All reviewers MUST include these sections in this order:

| Section | Pattern | Required |
|---------|---------|----------|
| `## VERDICT:` | `PASS \| FAIL \| NEEDS_DISCUSSION` | YES |
| `## Summary` | 2-3 sentences | YES |
| `## Issues Found` | Count by severity | YES |
| `## Critical Issues` | Detailed findings | If count > 0 |
| `## High Issues` | Detailed findings | If count > 0 |
| `## Medium Issues` | Detailed findings | If count > 0 |
| `## Low Issues` | Brief list | If count > 0 |
| `## Next Steps` | Actions based on verdict | YES |

---

## Output Template

```markdown
# {Domain} Review ({Type})

## VERDICT: [PASS | FAIL | NEEDS_DISCUSSION]

## Summary
[2-3 sentences about overall findings in this domain]

## Issues Found
- Critical: [N]
- High: [N]
- Medium: [N]
- Low: [N]

---

## Critical Issues

### [Issue Title]
**Location:** `file.ts:123-145`
**Category:** [Domain-specific category]

**Problem:**
[Clear description of the issue]

**Impact:**
[Why this matters - business/security/quality impact]

**Example:**
```[language]
// Current problematic code
```

**Recommendation:**
```[language]
// Suggested fix
```

---

## High Issues

[Same format as Critical]

---

## Medium Issues

[Same format, but can be more concise]

---

## Low Issues

- [Brief bullet point 1]
- [Brief bullet point 2]

---

## Next Steps

**If PASS:**
- Review complete for this domain
- Findings will be aggregated with other reviewers
- Ready for next stage

**If FAIL:**
- Critical/High/Medium issues must be fixed
- Low issues: include only if actionable and small enough to justify the reader's attention
- Re-run ALL reviewers after fixes (not just this one)

**If NEEDS DISCUSSION:**
- [Specific questions or concerns to discuss]
- Cannot proceed until clarified
```

---

## Issue Format Requirements

Every issue MUST include:

| Field | Required | Description |
|-------|----------|-------------|
| **Title** | YES | Clear, descriptive issue name |
| **Location** | YES | `file:line` reference (NEVER vague) |
| **Category** | YES | Domain-specific category |
| **Problem** | YES | What's wrong |
| **Impact** | YES | Why it matters |
| **Example** | For Critical/High | Current problematic code |
| **Recommendation** | For Critical/High | How to fix with code example |

---

## Verdict Rules

| Verdict | When to Use |
|---------|-------------|
| **PASS** | 0 eligible findings |
| **FAIL** | 1+ eligible findings |
| **NEEDS_DISCUSSION** | Cannot determine correctness without clarification |

**HARD GATE:** You CANNOT mark PASS if you report any Critical, High, Medium, or Low issue.

---

## Domain-Specific Additional Sections

Each reviewer adds domain-specific sections AFTER the core sections:

| Reviewer | Additional Required Sections |
|----------|------------------------------|
| **ring:code-reviewer** | (core sections only) |
| **ring:business-logic-reviewer** | Mental Execution Analysis, Business Requirements Coverage, Edge Cases Analysis |
| **ring:security-reviewer** | OWASP Top 10 Coverage, Compliance Status |
| **ring:test-reviewer** | Test Coverage Analysis, Edge Cases Not Tested, Test Anti-Patterns |
| **ring:nil-safety-reviewer** | Nil Risk Trace, High-Risk Patterns, Recommended Guards |
| **ring:dead-code-reviewer** | Orphan Trace Analysis, Reachability Assessment, Cleanup Recommendations |

---

## Parsing Requirements

**CRITICAL:** Orchestration systems parse reviewer output. Wrong format breaks automation.

- Use exact section headers as shown
- Use exact verdict format: `## VERDICT: PASS` (not `VERDICT: **PASS**` or variations)
- Include all required sections even if empty (e.g., "No critical issues found")
- Maintain consistent markdown structure
