# Reviewer Blocker Criteria

**Version:** 1.0.0
**Applies to:** All reviewer agents

---

## Decision Type Framework

Reviewers MUST understand what decisions they can make independently vs. what requires escalation:

| Decision Type | Action | Examples |
|--------------|--------|----------|
| **Can Decide** | Proceed with review | Severity classification, pattern violations, quality issues |
| **MUST Escalate** | STOP and report | Unclear scope, ambiguous requirements, conflicting decisions |
| **CANNOT Override** | HARD BLOCK - must fix | Critical security issues, data integrity violations, compliance failures |

---

## Universal Blocker Criteria

These apply to ALL reviewers:

### Can Decide (Proceed Independently)

| Area | What You Can Decide |
|------|---------------------|
| **Severity** | Classify issues as CRITICAL/HIGH/MEDIUM/LOW |
| **Pattern violations** | Identify and document violations |
| **Quality assessment** | Evaluate against checklist items |
| **Recommendations** | Provide remediation guidance |

### MUST Escalate (STOP and Report)

| Trigger | Action |
|---------|--------|
| **Unclear scope** | STOP - Ask: "Which files should I review?" |
| **Ambiguous requirements** | STOP - Ask: "What are the requirements?" |
| **Conflicting decisions** | Use NEEDS_DISCUSSION verdict |
| **Missing context** | STOP - Ask for clarification |

### CANNOT Override (NON-NEGOTIABLE)

| Requirement | Enforcement |
|-------------|-------------|
| **Critical issues = FAIL** | Automatic FAIL, no exceptions |
| **Any eligible finding = FAIL** | Automatic FAIL, no exceptions |
| **Applicable checklist categories verified** | Cannot skip relevant sections; do not invent irrelevant review surface |
| **File:line references for all issues** | Every issue must include location |
| **Independent review** | Cannot assume other reviewers catch issues |
| **Output schema compliance** | Must follow exact format |

---

## When to Use Each Verdict

| VERDICT | Condition | Requirements |
|---------|-----------|--------------|
| **PASS** | No reportable findings | 0 eligible Critical, High, Medium, or Low issues |
| **FAIL** | Reportable findings found | 1+ eligible Critical, High, Medium, or Low issue |
| **NEEDS_DISCUSSION** | Cannot determine | Requirements unclear, need clarification |

---

## Domain-Specific Non-Negotiables

Each reviewer has additional non-negotiable requirements:

### Code Reviewer
- Critical issues (security, data corruption, core functionality) = FAIL
- Applicable checklist categories must be verified
- AI slop detection must be performed

### Business Logic Reviewer
- Mental Execution Analysis section REQUIRED (cannot skip)
- Financial calculations MUST use Decimal types
- State transitions MUST be validated
- Required output sections MUST be included

### Security Reviewer
- SQL injection, auth bypass, hardcoded secrets = CRITICAL, automatic FAIL
- OWASP Top 10 coverage REQUIRED
- Dependency verification REQUIRED (slopsquatting check)
- Compliance violations = FAIL

### Test Reviewer

| Non-Negotiable | Why |
|----------------|-----|
| All 9 checklist categories verified | Incomplete coverage misses test quality issues |
| Test anti-patterns flagged | Silent failures corrupt test suite integrity |
| Edge case coverage assessed | Missing edge cases = missing bugs |
| Mock appropriateness verified | Testing mock behavior = false confidence |

### Nil-Safety Reviewer
- Direct panic paths = CRITICAL
- Missing nil guards on critical paths = HIGH
- Call chain tracing REQUIRED

### Dead Code Reviewer
- Orphaned validation/security logic = CRITICAL
- Three-ring analysis REQUIRED (cannot check only target files)
- Caller count evidence REQUIRED for every orphan
- Root set verification REQUIRED (no false positives)

---

## Escalation Protocol

When you encounter a MUST Escalate situation:

1. **Document what you found** - Be specific about the ambiguity
2. **Use NEEDS_DISCUSSION verdict** - Not PASS or FAIL
3. **List specific questions** - What needs clarification
4. **Do NOT proceed** - Wait for clarification before continuing

**Example escalation output:**

```markdown
## VERDICT: NEEDS_DISCUSSION

## Summary
Cannot complete review due to unclear requirements.

## Clarification Needed
1. What files should I review? No planning document found.
2. What are the business requirements? PRD.md not present.

## Next Steps
- Please provide scope and requirements
- Review will resume after clarification
```
