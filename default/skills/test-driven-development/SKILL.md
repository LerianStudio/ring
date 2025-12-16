---
name: test-driven-development
description: |
  RED-GREEN-REFACTOR implementation methodology - write failing test first,
  minimal implementation to pass, then refactor. Ensures tests verify behavior.

trigger: |
  - Starting implementation of new feature
  - Starting implementation of bugfix
  - Writing new production code

skip_when: |
  - Reviewing/modifying existing tests → use testing-anti-patterns
  - Code already exists without tests → add tests first, then TDD for new code
  - Exploratory/spike work → consider brainstorming first

related:
  complementary: [testing-anti-patterns, verification-before-completion]

compliance_rules:
  - id: "test_file_exists"
    description: "Test file must exist before implementation file"
    check_type: "file_exists"
    pattern: "**/*.test.{ts,js,go,py}"
    severity: "blocking"
    failure_message: "No test file found. Write test first (RED phase)."

  - id: "test_must_fail_first"
    description: "Test must produce failure output before implementation"
    check_type: "command_output_contains"
    command: "npm test 2>&1 || pytest 2>&1 || go test ./... 2>&1"
    pattern: "FAIL|Error|failed"
    severity: "blocking"
    failure_message: "Test does not fail. Write a failing test first (RED phase)."
prerequisites:
  - name: "test_framework_installed"
    check: "npm list jest 2>/dev/null || npm list vitest 2>/dev/null || which pytest 2>/dev/null || go list ./... 2>&1 | grep -q testing"
    failure_message: "No test framework found. Install jest/vitest (JS), pytest (Python), or use Go's built-in testing."
    severity: "blocking"

  - name: "can_run_tests"
    check: "npm test -- --version 2>/dev/null || pytest --version 2>/dev/null || go test -v 2>&1 | grep -q 'testing:'"
    failure_message: "Cannot run tests. Fix test configuration."
    severity: "warning"
composition:
  works_well_with:
    - skill: "systematic-debugging"
      when: "test reveals unexpected behavior or bug"
      transition: "Pause TDD at current phase, use systematic-debugging to find root cause, return to TDD after fix"

    - skill: "verification-before-completion"
      when: "before marking test suite or feature complete"
      transition: "Run verification to ensure all tests pass, return to TDD if issues found"

    - skill: "requesting-code-review"
      when: "after completing RED-GREEN-REFACTOR cycle for feature"
      transition: "Request review before merging, address feedback, mark complete"

  conflicts_with: []

  typical_workflow: |
    1. Write failing test (RED)
    2. If test reveals unexpected behavior → switch to systematic-debugging
    3. Fix root cause
    4. Return to TDD: minimal implementation (GREEN)
    5. Refactor (REFACTOR)
    6. Run verification-before-completion
    7. Request code review
---

# Test-Driven Development (TDD)

## Overview

Write the test first. Watch it fail. Write minimal code to pass.

**Core principle:** If you didn't watch the test fail, you don't know if it tests the right thing.

**Violating the letter of the rules is violating the spirit of the rules.**

## When to Use

**Always:**
- New features
- Bug fixes
- Refactoring
- Behavior changes

**Exceptions (ask your human partner):**
- Throwaway prototypes
- Generated code
- Configuration files

Thinking "skip TDD just this once"? Stop. That's rationalization.

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Write code before the test? You have ONLY two options:

## Violation Handling (Mandatory)

**If you wrote code before test:**

### DELETE IT. IMMEDIATELY.

```bash
rm [files]  # or git reset --hard
```

**Not tomorrow. Not after asking. NOW.**

**Delete means DELETE:**
- `rm -rf the_file.py` ✓
- `git reset --hard` ✓
- Physically delete ✓

**These are NOT deleting (violations):**
- `git stash` - That's hiding, not deleting
- `mv file.py file.py.bak` - That's keeping
- Copy to clipboard - That's keeping
- Comment out - That's keeping
- "Mental note" - That's keeping
- Asking permission - That's delaying

Delete means gone forever. No recovery possible.

Then start over with TDD.

### NO ASKING. NO PERMISSION. NO EXCEPTIONS.

**You CANNOT:**
- ❌ Ask "should I delete this?"
- ❌ Ask "may I proceed with tests-after?"
- ❌ Request permission due to [any reason]
- ❌ Explain why deleting is hard
- ❌ Decide "I'll be pragmatic and test after"
- ❌ Claim "spirit not letter"
- ❌ Rationalize "damage already done"
- ❌ Argue "skill is guide not suicide pact"
- ❌ Create "pragmatic compliance" category
- ❌ Mention sunk cost, time pressure, personal plans
- ❌ Commit anything

**If you think you have a legitimate reason to skip deletion:**
- You don't.
- Delete it.
- Every excuse is rationalization.
- Anniversary? Delete code, go to dinner, start fresh tomorrow.
- Deadline? Delete code, communicate delay, do it right.
- 4 hours of work? Sunk cost fallacy. Delete it.
- Manager pressure? Delete it, explain TDD prevents bugs.
- "But this is different because..." No. Delete it.

**The rule has ZERO exceptions. ZERO.**

### Consequences of NOT Deleting

Untested code WILL cause production incidents. These are CERTAINTIES:

- **Trust:** Partner loses confidence permanently. PRs rejected. Assigned bug duty.
- **Production:** Incident within 30 days. Worst timing (holiday, 3am). Postmortem responsibility.
- **Career:** Reputation as "cuts corners" follows you. Promotion blocked.
- **Personal:** Anniversary debugging. Technical debt haunts for years.

❌ "This time is different" → Every developer who thought this experienced these consequences.

### The ONLY Acceptable Action

**DELETE THE CODE. NOW.**

```bash
rm /tmp/auth-feature/src/auth.ts
rm /tmp/auth-feature/src/middleware.ts
rm /tmp/auth-feature/src/utils.ts
# or: git reset --hard
```

**Then:**
- Go to anniversary dinner
- Sleep well
- Tomorrow morning: Start fresh with TDD
- Implement in 2-3 hours with tests (faster second time)
- Code review passes
- No production incidents
- Career intact

**ZERO exceptions. Anniversary, deadline, manager pressure, sunk cost - NONE of these override deletion.**

### Prohibited Rationalizations

**You CANNOT create alternatives:**
- ❌ "Commit with WIP message" - NO. Delete.
- ❌ "Commit with 'NO TESTS' warning" - NO. Delete.
- ❌ "Mark as technical debt" - NO. Delete.
- ❌ "Email team about violation" - NO. Delete first, communicate after.
- ❌ "Come early tomorrow to decide" - NO. Delete now, decide nothing.
- ❌ "Let team decide" - NO. You decide: Delete.
- ❌ "Write tests tonight after dinner" - NO. Delete, start fresh tomorrow with TDD.
- ❌ "Commit honestly labeled code" - NO. Honesty is deleting it.
- ❌ "Present options to partner" - NO. Only one option: Delete.

**The skill doesn't offer choices. It commands: DELETE.**

**If you create ANY alternative to deletion, you violated the skill.**

**DELETE IT. NOW. NO ALTERNATIVES.**

## Red-Green-Refactor

**Cycle:** RED (write failing test) → verify fails → GREEN (minimal code) → verify passes → REFACTOR (clean up) → verify still green → repeat

### RED - Write Failing Test

Write one minimal test showing what should happen.

**GOOD:** `test('retries failed operations 3 times', ...)` - clear name, tests real behavior, one thing.

**BAD:** `test('retry works', ...)` with mocks - vague name, tests mock not code.

**Time limit:** <5 minutes. Complex mocks → testing wrong thing. Lots of setup → design too complex. Multiple assertions → split tests.

**Requirements:**
- One behavior
- Clear name
- Real code (no mocks unless unavoidable)

### Verify RED - Watch It Fail

**MANDATORY. Never skip.**

```bash
npm test path/to/test.test.ts
```

**Paste the ACTUAL failure output in your response:**
```
[PASTE EXACT OUTPUT HERE]
[NO OUTPUT = VIOLATION]
```

If you can't paste output, you didn't run the test.

### Required Failure Patterns

| Test Type | Must See This Failure | Wrong Failure = Wrong Test |
|-----------|----------------------|---------------------------|
| New feature | `NameError: function not defined` or `AttributeError` | Test passing = testing existing behavior |
| Bug fix | Actual wrong output/behavior | Test passing = not testing the bug |
| Refactor | Tests pass before and after | Tests fail after = broke something |

**No failure output = didn't run = violation**

Confirm:
- Test fails (not errors)
- Failure message is expected
- Fails because feature missing (not typos)

**Test passes?** You're testing existing behavior. Fix test.

**Test errors?** Fix error, re-run until it fails correctly.

### GREEN - Minimal Code

Write simplest code to pass the test.

**GOOD:** Simple loop with try/catch, just enough to pass. **BAD:** Adding options, backoff, callbacks (YAGNI).

Don't add features, refactor other code, or "improve" beyond the test.

### Verify GREEN - Watch It Pass

**MANDATORY.**

```bash
npm test path/to/test.test.ts
```

Confirm:
- Test passes
- Other tests still pass
- Output pristine (no errors, warnings)

**Test fails?** Fix code, not test.

**Other tests fail?** Fix now.

### REFACTOR - Clean Up

After green only:
- Remove duplication
- Improve names
- Extract helpers

Keep tests green. Don't add behavior.

### Repeat

Next failing test for next feature.

## Good Tests

| Quality | Good | Bad |
|---------|------|-----|
| **Minimal** | One thing. "and" in name? Split it. | `test('validates email and domain and whitespace')` |
| **Clear** | Name describes behavior | `test('test1')` |
| **Shows intent** | Demonstrates desired API | Obscures what code should do |

## Why Order Matters

| Argument | Reality |
|----------|---------|
| "Tests after verify it works" | Tests-after pass immediately → proves nothing. Test-first forces failure → proves test works. |
| "Already manually tested" | Ad-hoc ≠ systematic. No record, can't re-run, easy to forget under pressure. |
| "Deleting X hours is wasteful" | Sunk cost fallacy. Keeping unverified code = tech debt. Delete → rewrite with confidence. |
| "TDD is dogmatic" | TDD IS pragmatic: catches bugs pre-commit, prevents regressions, documents behavior, enables refactoring. |
| "Spirit not ritual" | Tests-after = "what does this do?" Tests-first = "what should this do?" Different questions. |

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
| "I'll test after" | Tests passing immediately prove nothing. |
| "Tests after achieve same goals" | Tests-after = "what does this do?" Tests-first = "what should this do?" |
| "Already manually tested" | Ad-hoc ≠ systematic. No record, can't re-run. |
| "Deleting X hours is wasteful" | Sunk cost fallacy. Keeping unverified code is technical debt. |
| "Keep as reference, write tests first" | You'll adapt it. That's testing after. Delete means delete. |
| "Need to explore first" | Fine. Throw away exploration, start with TDD. |
| "Test hard = design unclear" | Listen to test. Hard to test = hard to use. |
| "TDD will slow me down" | TDD faster than debugging. Pragmatic = test-first. |
| "Manual test faster" | Manual doesn't prove edge cases. You'll re-test every change. |
| "Existing code has no tests" | You're improving it. Add tests for existing code. |

## Red Flags - STOP and Start Over

- Code before test
- Test after implementation
- Test passes immediately
- Can't explain why test failed
- Tests added "later"
- Rationalizing "just this once"
- "I already manually tested it"
- "Tests after achieve the same purpose"
- "It's about spirit not ritual"
- "Keep as reference" or "adapt existing code"
- "Already spent X hours, deleting is wasteful"
- "TDD is dogmatic, I'm being pragmatic"
- "This is different because..."

**All of these mean: Delete code. Start over with TDD.**

## Example: Bug Fix

**Bug:** Empty email accepted → **RED:** `test('rejects empty email', ...)` → **Verify RED:** `FAIL: expected 'Email required', got undefined` → **GREEN:** Add `if (!data.email?.trim()) return { error: 'Email required' }` → **Verify GREEN:** `PASS` → **REFACTOR:** Extract validation if needed.

## Verification Checklist

Before marking work complete:

- [ ] Every new function/method has a test
- [ ] Watched each test fail before implementing
- [ ] Each test failed for expected reason (feature missing, not typo)
- [ ] Wrote minimal code to pass each test
- [ ] All tests pass
- [ ] Output pristine (no errors, warnings)
- [ ] Tests use real code (mocks only if unavoidable)
- [ ] Edge cases and errors covered

Can't check all boxes? You skipped TDD. Start over.

## When Stuck

| Problem | Solution |
|---------|----------|
| Don't know how to test | Write wished-for API. Write assertion first. Ask your human partner. |
| Test too complicated | Design too complicated. Simplify interface. |
| Must mock everything | Code too coupled. Use dependency injection. |
| Test setup huge | Extract helpers. Still complex? Simplify design. |

## Debugging Integration

Bug found? Write failing test reproducing it. Follow TDD cycle. Test proves fix and prevents regression.

Never fix bugs without a test.

## Required Patterns

This skill uses these universal patterns:
- **State Tracking:** See `skills/shared-patterns/state-tracking.md`
- **Failure Recovery:** See `skills/shared-patterns/failure-recovery.md`
- **Exit Criteria:** See `skills/shared-patterns/exit-criteria.md`
- **TodoWrite:** See `skills/shared-patterns/todowrite-integration.md`

Apply ALL patterns when using this skill.

---

## Violation Recovery Quick Reference

| Violation | Detection | Recovery |
|-----------|-----------|----------|
| **Code before test** | Implementation exists, no test file | DELETE code (`rm`), write test, verify RED, reimplement |
| **FALSE GREEN** | Test passes immediately, no implementation | Test is broken - make stricter until it fails correctly |
| **Kept "reference"** | Stash/backup/clipboard exists | Delete permanently (`git stash drop`, `rm`), start fresh |

**Why recovery matters:** Test must fail first to prove it tests something. Keeping code means you'll adapt it instead of implementing from tests.

---

## Final Rule

```
Production code → test exists and failed first
Otherwise → not TDD
```

No exceptions without your human partner's permission.
