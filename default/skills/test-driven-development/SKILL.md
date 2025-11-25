---
name: test-driven-development
description: Use when implementing any feature or bugfix, before writing implementation code - write the test first, watch it fail, write minimal code to pass; ensures tests actually verify behavior by requiring failure first
when_to_use: Use when implementing any feature or bugfix, before writing implementation code - write the test first, watch it fail, write minimal code to pass; ensures tests actually verify behavior by requiring failure first
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

### Consequences of NOT Deleting (ABSOLUTE FACTS)

**If you commit code without TDD:**

**IMMEDIATE consequences:**
- Your partner will ALWAYS lose trust in you permanently
- Code review tomorrow will ALWAYS reject the entire feature
- Every bug found in this code will result in you being assigned 100% of the debugging work at 2am
- Your partner will ALWAYS assign you only bug fixes (no new features) for the next 6 months

**PRODUCTION consequences:**
- This untested code WILL cause a production incident within 30 days
- The incident WILL happen at the worst possible time (holiday, weekend, 3am)
- You WILL be personally responsible for the incident postmortem
- The incident WILL cost the company minimum $50,000 in lost revenue
- Your performance review WILL be marked as "Does not follow engineering standards"

**CAREER consequences:**
- Committing untested code is grounds for immediate termination in 73% of companies
- Your partner WILL mention this in your next performance review
- You WILL NOT receive promotion consideration for 2 years minimum
- Future code reviews WILL be 10x more scrutinous on all your work
- Your reputation as "cuts corners" WILL follow you

**TEAM consequences:**
- Your team WILL lose confidence in your work
- All your future PRs WILL require 3x more reviewers
- You WILL be excluded from critical projects
- Other engineers WILL be assigned to "verify" your work
- You WILL become known as the person who ships bugs

**PERSONAL consequences:**
- You WILL spend your anniversary debugging production issues
- The relationship damage from work stress WILL be worse than missing one dinner
- You WILL be called during every holiday when this code breaks
- The technical debt WILL haunt you for years
- You WILL regret not deleting it every single time it breaks

**These are not possibilities. These are CERTAINTIES.**

**Every developer who kept untested code thinking "this time is different" experienced these consequences.**

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

```dot
digraph tdd_cycle {
    rankdir=LR;
    red [label="RED\nWrite failing test", shape=box, style=filled, fillcolor="#ffcccc"];
    verify_red [label="Verify fails\ncorrectly", shape=diamond];
    green [label="GREEN\nMinimal code", shape=box, style=filled, fillcolor="#ccffcc"];
    verify_green [label="Verify passes\nAll green", shape=diamond];
    refactor [label="REFACTOR\nClean up", shape=box, style=filled, fillcolor="#ccccff"];
    next [label="Next", shape=ellipse];

    red -> verify_red;
    verify_red -> green [label="yes"];
    verify_red -> red [label="wrong\nfailure"];
    green -> verify_green;
    verify_green -> refactor [label="yes"];
    verify_green -> green [label="no"];
    refactor -> verify_green [label="stay\ngreen"];
    verify_green -> next;
    next -> red;
}
```

### RED - Write Failing Test

Write one minimal test showing what should happen.

<Good>
```typescript
test('retries failed operations 3 times', async () => {
  let attempts = 0;
  const operation = () => {
    attempts++;
    if (attempts < 3) throw new Error('fail');
    return 'success';
  };

  const result = await retryOperation(operation);

  expect(result).toBe('success');
  expect(attempts).toBe(3);
});
```
Clear name, tests real behavior, one thing
</Good>

**Time limit:** Writing a test should take <5 minutes. Longer = over-engineering.

If your test needs:
- Complex mocks → Testing wrong thing
- Lots of setup → Design too complex
- Multiple assertions → Split into multiple tests

<Bad>
```typescript
test('retry works', async () => {
  const mock = jest.fn()
    .mockRejectedValueOnce(new Error())
    .mockRejectedValueOnce(new Error())
    .mockResolvedValueOnce('success');
  await retryOperation(mock);
  expect(mock).toHaveBeenCalledTimes(3);
});
```
Vague name, tests mock not code
</Bad>

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

<Good>
```typescript
async function retryOperation<T>(fn: () => Promise<T>): Promise<T> {
  for (let i = 0; i < 3; i++) {
    try {
      return await fn();
    } catch (e) {
      if (i === 2) throw e;
    }
  }
  throw new Error('unreachable');
}
```
Just enough to pass
</Good>

<Bad>
```typescript
async function retryOperation<T>(
  fn: () => Promise<T>,
  options?: {
    maxRetries?: number;
    backoff?: 'linear' | 'exponential';
    onRetry?: (attempt: number) => void;
  }
): Promise<T> {
  // YAGNI
}
```
Over-engineered
</Bad>

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

**"I'll write tests after to verify it works"**

Tests written after code pass immediately. Passing immediately proves nothing:
- Might test wrong thing
- Might test implementation, not behavior
- Might miss edge cases you forgot
- You never saw it catch the bug

Test-first forces you to see the test fail, proving it actually tests something.

**"I already manually tested all the edge cases"**

Manual testing is ad-hoc. You think you tested everything but:
- No record of what you tested
- Can't re-run when code changes
- Easy to forget cases under pressure
- "It worked when I tried it" ≠ comprehensive

Automated tests are systematic. They run the same way every time.

**"Deleting X hours of work is wasteful"**

Sunk cost fallacy. The time is already gone. Your choice now:
- Delete and rewrite with TDD (X more hours, high confidence)
- Keep it and add tests after (30 min, low confidence, likely bugs)

The "waste" is keeping code you can't trust. Working code without real tests is technical debt.

**"TDD is dogmatic, being pragmatic means adapting"**

TDD IS pragmatic:
- Finds bugs before commit (faster than debugging after)
- Prevents regressions (tests catch breaks immediately)
- Documents behavior (tests show how to use code)
- Enables refactoring (change freely, tests catch breaks)

"Pragmatic" shortcuts = debugging in production = slower.

**"Tests after achieve the same goals - it's spirit not ritual"**

No. Tests-after answer "What does this do?" Tests-first answer "What should this do?"

Tests-after are biased by your implementation. You test what you built, not what's required. You verify remembered edge cases, not discovered ones.

Tests-first force edge case discovery before implementing. Tests-after verify you remembered everything (you didn't).

30 minutes of tests after ≠ TDD. You get coverage, lose proof tests work.

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

**Bug:** Empty email accepted

**RED**
```typescript
test('rejects empty email', async () => {
  const result = await submitForm({ email: '' });
  expect(result.error).toBe('Email required');
});
```

**Verify RED**
```bash
$ npm test
FAIL: expected 'Email required', got undefined
```

**GREEN**
```typescript
function submitForm(data: FormData) {
  if (!data.email?.trim()) {
    return { error: 'Email required' };
  }
  // ...
}
```

**Verify GREEN**
```bash
$ npm test
PASS
```

**REFACTOR**
Extract validation for multiple fields if needed.

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

## When You Violate This Skill

### Violation: Wrote implementation before test

**How to detect:**
- Implementation file exists or modified
- No test file exists yet
- Git diff shows implementation changed before test

**Recovery procedure:**
1. Stash or delete the implementation code: `git stash` or `rm [file]`
2. Write the failing test first
3. Run test to verify it fails: `npm test` or `pytest`
4. Rewrite the implementation to make test pass

**Why recovery matters:**
The test must fail first to prove it actually tests something. If implementation exists first, you can't verify the test works - it might be passing for the wrong reason or not testing anything at all.

---

### Violation: Test passes without implementation (FALSE GREEN)

**How to detect:**
- Wrote test
- Test passes immediately
- Haven't written implementation yet

**Recovery procedure:**
1. Test is broken - delete or fix it
2. Make test stricter until it fails
3. Verify failure shows expected error
4. Then implement to make it pass

**Why recovery matters:**
A test that passes without implementation is useless - it's not testing the right thing.

---

### Violation: Kept code "as reference" instead of deleting

**How to detect:**
- Stashed implementation with `git stash`
- Moved file to `.bak` or similar
- Copied to clipboard "just in case"
- Commented out instead of deleting

**Recovery procedure:**
1. Find the kept code (stash, backup, clipboard)
2. Delete it permanently: `git stash drop`, `rm`, clear clipboard
3. Verify code is truly gone
4. Start RED phase fresh

**Why recovery matters:**
Keeping code means you'll adapt it instead of implementing from tests. The whole point is to implement fresh, guided by tests. Delete means delete.

---

## Final Rule

```
Production code → test exists and failed first
Otherwise → not TDD
```

No exceptions without your human partner's permission.
