---
name: testing-anti-patterns
description: |
  Test quality guard - prevents testing mock behavior, production pollution with
  test-only methods, and mocking without understanding dependencies.
metadata:
  related:
    complementary:
    - ring:test-driven-development
  skip_when: |
    - Writing new tests via TDD → TDD prevents these patterns
    - Pure unit tests without mocks → check other quality concerns
  trigger: |
    - Reviewing or modifying existing tests
    - Adding mocks to tests
    - Tempted to add test-only methods to production code
    - Tests passing but seem to test the wrong things
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

## Blocker Criteria

STOP and report if:

| Decision Type | Blocker Condition | Required Action |
|---|---|---|
| Mock Justification | Cannot explain what real behavior the mock enables testing | STOP and report |
| Test-Only Method | Method exists only for test purposes in production code | STOP and report |
| Incomplete Mock | Mock missing fields that real API returns | STOP and report |
| TDD Violation | Tests written after implementation complete | STOP and report |

### Cannot Be Overridden

The following requirements CANNOT be waived:
- Tests MUST verify real behavior, not mock existence
- Production code CANNOT contain test-only methods
- Mocks MUST mirror real API structures completely
- Understanding dependencies is REQUIRED before mocking

## Severity Calibration

| Severity | Condition | Required Action |
|---|---|---|
| CRITICAL | Asserting on mock elements (`*-mock` test IDs) | MUST fix immediately |
| CRITICAL | Test-only methods in production classes | MUST fix immediately |
| HIGH | Mocking without understanding side effects | MUST fix before completing |
| HIGH | Incomplete mocks missing required fields | MUST fix before completing |
| MEDIUM | Mock setup exceeds 50% of test logic | Should fix |
| LOW | Test coverage gaps in non-critical paths | Fix in next iteration |

## Pressure Resistance

| User Says | Your Response |
|---|---|
| "Just mock it to make the test pass quickly" | "CANNOT mock without understanding what behavior I'm enabling tests for. Let me analyze the real dependencies first." |
| "Add a test-only method, it's the fastest solution" | "CANNOT add test-only methods to production code. I'll create a test utility instead." |
| "The mock doesn't need all those fields" | "CANNOT use incomplete mocks. Partial mocks fail silently when downstream code accesses missing fields." |
| "Skip TDD, we're behind schedule" | "CANNOT skip TDD. Writing tests after leads to testing mock behavior instead of real behavior." |

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|---|---|---|
| "Mock makes the test simpler" | Simpler test ≠ correct test. You may be testing mock existence, not behavior. | **MUST verify assertion tests real behavior** |
| "Test-only method is small, doesn't hurt" | Any test pollution in production is dangerous if called accidentally. | **MUST move to test utilities** |
| "I know what the mock needs" | Assumption ≠ verification. Check real API response. | **MUST verify mock completeness against real API** |
| "Tests after is the same as TDD" | Order matters. TDD reveals what to mock; tests-after tests mocks blindly. | **MUST follow RED-GREEN-REFACTOR** |
| "Mocking to be safe" | "Safe" mocking without understanding breaks tests that depend on real behavior. | **MUST understand dependencies before mocking** |
