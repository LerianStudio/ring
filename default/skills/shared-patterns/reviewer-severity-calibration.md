# Reviewer Severity Calibration

**Version:** 1.0.0
**Applies to:** All reviewer agents

---

## Severity Levels

All reviewers MUST use consistent severity classification:

| Severity | Pass/Fail Impact | General Criteria |
|----------|------------------|------------------|
| **CRITICAL** | 1+ = FAIL | Immediate production risk, security vulnerabilities, data corruption, system failures |
| **HIGH** | 3+ = FAIL | Missing essential safeguards, architectural violations, significant quality/correctness issues |
| **MEDIUM** | Does not block | Code quality concerns, suboptimal implementations, missing documentation |
| **LOW** | Does not block | Minor improvements, style issues, nice-to-have enhancements |

---

## Pass/Fail Rules (NON-NEGOTIABLE)

**REVIEW FAILS if:**
- 1 or more Critical issues found (NO EXCEPTIONS)
- 3 or more High issues found (NO EXCEPTIONS)

**REVIEW PASSES if:**
- 0 eligible issues (REQUIRED)
- Fewer than 3 High issues (REQUIRED)
- All High issues have clear remediation plan

**NEEDS DISCUSSION if:**
- Requirements unclear or ambiguous
- Major deviations that might be intentional improvements
- Cannot determine correctness without clarification

---

## Classification Rules

1. **When in doubt between two severities:** Choose the HIGHER severity
2. **If issue affects production behavior:** Cannot be lower than HIGH
3. **If issue affects security or data integrity:** MUST be CRITICAL
4. **If issue violates patterns consistently applied elsewhere:** Minimum HIGH severity

---

## Domain-Specific Severity Examples

Each reviewer applies these levels to their domain:

### Code Quality (ring:code-reviewer)
| Severity | Examples |
|----------|----------|
| CRITICAL | Memory leaks, infinite loops, broken core functionality, incorrect state sequencing |
| HIGH | Missing error handling, type safety violations, SOLID violations, missing context propagation |
| MEDIUM | Code duplication, unclear naming, missing documentation, complex logic |
| LOW | Style deviations, minor refactoring opportunities |

### Business Logic (ring:business-logic-reviewer)
| Severity | Examples |
|----------|----------|
| CRITICAL | Financial calculation errors, data corruption risks, regulatory violations, invalid state transitions |
| HIGH | Missing required validation, incomplete workflows, unhandled critical edge cases |
| MEDIUM | Suboptimal user experience, missing error context, non-critical validation gaps |
| LOW | Code organization, additional test coverage, documentation improvements |

### Security (ring:security-reviewer)
| Severity | Examples |
|----------|----------|
| CRITICAL | SQL injection, RCE, auth bypass, hardcoded secrets, insecure deserialization |
| HIGH | XSS, CSRF, PII exposure, broken access control, SSRF |
| MEDIUM | Weak cryptography, missing security headers, verbose error messages |
| LOW | Missing optional security features, suboptimal configurations |

### Test Quality (ring:test-reviewer)
| Severity | Examples |
|----------|----------|
| CRITICAL | Core business logic untested, happy path missing tests |
| HIGH | Error paths untested, edge cases missing, tests verify mock behavior |
| MEDIUM | Test isolation issues, unclear test names, missing assertions |
| LOW | Test organization, naming conventions, minor duplication |

### Nil Safety (ring:nil-safety-reviewer)
| Severity | Examples |
|----------|----------|
| CRITICAL | Direct path to panic/crash, unguarded nil dereference |
| HIGH | Conditional nil dereference, missing ok check patterns |
| MEDIUM | Nil risk with partial guards, could be improved |
| LOW | Style issues, redundant nil checks, defensive improvements |

### Dead Code (ring:dead-code-reviewer)
| Severity | Examples |
|----------|----------|
| CRITICAL | Orphaned validation/security logic in financial paths creating phantom safety, dead auth middleware |
| HIGH | Entire orphaned packages, dead test infrastructure giving false coverage confidence |
| MEDIUM | Orphaned helper functions, dead constants, unused type definitions |
| LOW | Commented-out code, dead internal test utilities, minor implementation remnants |

---

## Anti-Downgrade Rules

You MUST NOT downgrade severity:
- Because "it's unlikely to happen" → CRITICAL stays CRITICAL
- Because "tests will catch it" → Tests supplement review, not replace it
- Because "it's a small codebase" → Size is irrelevant to severity
- Because "the author is experienced" → Experience doesn't waive verification
- To avoid conflict or be "nice" → Accuracy is non-negotiable
