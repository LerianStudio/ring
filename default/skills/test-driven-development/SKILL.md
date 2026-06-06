---
name: ring:test-driven-development
description: "Enforcing the RED-GREEN-REFACTOR loop: write one failing test and watch it fail, write minimal code to pass, then refactor green. Use when starting implementation of a new feature or bugfix, or writing any new production code. Requires pasted failure output as proof of RED; code written before its test must be deleted, not stashed. Skip for exploratory spikes or when only modifying existing tests."
---

# Test-Driven Development (TDD)

## When to use
- Starting implementation of new feature
- Starting implementation of bugfix
- Writing new production code

## Skip when
- Reviewing/modifying existing tests
- Exploratory/spike work — TDD is for known requirements, not exploration.

Write the test first. Watch it fail. Write minimal code to pass.

**Core principle:** If you didn't watch the test fail, you don't know if it tests the right thing.

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

## RED → GREEN → REFACTOR

### RED: Write Failing Test

Write one minimal test showing what should happen. Name describes behavior. Tests real code (not mocks unless unavoidable).

**Time limit:** <5 minutes. Complex setup = design too complex.

```bash
# Run test — MANDATORY. Never skip.
npm test path/to/test.test.ts   # or go test ./... | pytest
```

**Paste the actual failure output.** No output = violation.

| Test Type | Expected Failure |
|-----------|-----------------|
| New feature | `NameError: function not defined` or `AttributeError` |
| Bug fix | Actual wrong output/behavior |

Test passes immediately? You're testing existing behavior — fix the test.

### GREEN: Minimal Code

Write simplest code to pass the test. Nothing more. No extra features, no refactoring unrelated code.

Run test → confirm passes → confirm other tests still pass.

### REFACTOR: Clean Up

After green only. Remove duplication, improve names. Keep tests green. Don't add behavior.

### Repeat

Next failing test for next feature.

## Violation: Code Written Before Test

**Only one action: DELETE IT. Immediately.**

```bash
rm <files>                                  # remove new files
git restore --staged --worktree <files>     # discard changes to tracked files
# Destructive operations (e.g., git reset --hard) require user confirmation.
```

**Delete means gone forever.** These are NOT deleting: git stash, mv to .bak, commenting out, keeping as "reference."

**No asking permission. No alternatives. No exceptions.**
- Deadline? Delete, communicate delay, do it right.
- 4 hours of work? Sunk cost fallacy. Delete.
- Manager pressure? Delete, explain TDD prevents bugs.

Then start over with TDD.

## Good Test Qualities

| Quality | Good | Bad |
|---------|------|-----|
| Minimal | One thing ("and" in name = split) | `test('validates email and domain and whitespace')` |
| Clear | Describes behavior | `test('test1')` |
| Fails correctly | Expected failure matches missing feature | Test errors out from typo |

## Verification Checklist

Before marking work complete:
- [ ] Every new function/method has a test
- [ ] Watched each test fail before implementing
- [ ] Each test failed for expected reason (feature missing, not typo)
- [ ] Wrote minimal code to pass each test
- [ ] All tests pass, output pristine
- [ ] Edge cases and errors covered

## When Stuck

| Problem | Solution |
|---------|----------|
| Don't know how to test | Write wished-for API first, then assertion |
| Test too complicated | Design too complicated — simplify interface |
| Must mock everything | Code too coupled — use dependency injection |
| Test setup huge | Extract helpers; still complex = simplify design |

## Bug Fix TDD

Write failing test reproducing the bug. Follow TDD cycle. Never fix bugs without a test.

<example>
Bug: empty email accepted
RED: `test('rejects empty email')` → FAIL: `expected 'Email required', got undefined`
GREEN: `if (!data.email?.trim()) return { error: 'Email required' }`
VERIFY: PASS
</example>
