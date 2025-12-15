---
name: ring-default:testing-anti-patterns
description: |
  Test quality guard - prevents testing mock behavior, production pollution with
  test-only methods, and mocking without understanding dependencies.

trigger: |
  - Reviewing or modifying existing tests
  - Adding mocks to tests
  - Tempted to add test-only methods to production code
  - Tests passing but seem to test the wrong things

skip_when: |
  - Writing new tests via TDD → TDD prevents these patterns
  - Pure unit tests without mocks → check other quality concerns

related:
  complementary: [test-driven-development]
---

# Testing Anti-Patterns

## Overview

Tests must verify real behavior, not mock behavior. Mocks are a means to isolate, not the thing being tested.

**Core principle:** Test what the code does, not what the mocks do.

**Following strict TDD prevents these anti-patterns.**

## The Iron Laws

```
1. NEVER test mock behavior
2. NEVER add test-only methods to production classes
3. NEVER mock without understanding dependencies
```

## Anti-Pattern 1: Testing Mock Behavior

**BAD:** `expect(screen.getByTestId('sidebar-mock')).toBeInTheDocument()` - testing mock exists, not real behavior.

**GOOD:** `expect(screen.getByRole('navigation')).toBeInTheDocument()` - test real component or don't mock.

**Gate:** Before asserting on mock element → "Am I testing real behavior or mock existence?" If mock → delete assertion or unmock.

## Anti-Pattern 2: Test-Only Methods in Production

**BAD:** `session.destroy()` method only used in tests - pollutes production, dangerous if called.

**GOOD:** `cleanupSession(session)` in test-utils/ - keeps production clean.

**Gate:** "Is this method only used by tests?" → Put in test utilities. "Does this class own this lifecycle?" → If no, wrong class.

## Anti-Pattern 3: Mocking Without Understanding

**BAD:** Mocking `discoverAndCacheTools` breaks config write test depends on - test passes for wrong reason.

**GOOD:** Mock only the slow part (`MCPServerManager`), preserve behavior test needs.

**Gate:** Before mocking → (1) What side effects does real method have? (2) Does test depend on them? If yes → mock at lower level. **Red flags:** "Mock to be safe", "might be slow", mocking without understanding.

## Anti-Pattern 4: Incomplete Mocks

**BAD:** Partial mock missing `metadata` field - breaks when downstream code accesses `response.metadata.requestId`.

**GOOD:** Complete mock mirroring real API - ALL fields real API returns.

**Iron Rule:** Mock COMPLETE data structure, not just fields your test uses. Partial mocks fail silently.

**Gate:** Before mock → Check real API response, include ALL fields. If uncertain → include all documented fields.

## Anti-Pattern 5: Integration Tests as Afterthought

**BAD:** "Implementation complete" without tests. **FIX:** TDD cycle: write test → implement → refactor → claim complete.

## When Mocks Become Too Complex

**Warning signs:** Mock setup longer than test logic, mocking everything, mocks missing methods real components have. **Consider:** Integration tests with real components often simpler than complex mocks.

## TDD Prevents These Anti-Patterns

TDD forces: (1) Think about what you're testing, (2) Watch fail confirms real behavior not mocks, (3) See what test needs before mocking. **If testing mock behavior, you violated TDD.**

## Quick Reference

| Anti-Pattern | Fix |
|--------------|-----|
| Assert on mock elements | Test real component or unmock it |
| Test-only methods in production | Move to test utilities |
| Mock without understanding | Understand dependencies first, mock minimally |
| Incomplete mocks | Mirror real API completely |
| Tests as afterthought | TDD - tests first |
| Over-complex mocks | Consider integration tests |

## Red Flags

- Assertion checks for `*-mock` test IDs
- Methods only called in test files
- Mock setup is >50% of test
- Test fails when you remove mock
- Can't explain why mock is needed
- Mocking "just to be safe"

## The Bottom Line

**Mocks are tools to isolate, not things to test.**

If TDD reveals you're testing mock behavior, you've gone wrong.

Fix: Test real behavior or question why you're mocking at all.
