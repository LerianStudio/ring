---
name: dev-testing
description: |
  Development cycle testing gate (Gate 5) - ensures unit test coverage for all
  acceptance criteria using TDD methodology (RED-GREEN-REFACTOR).
  Focus: Unit tests only. Integration/E2E tests handled separately in CI/CD.

trigger: |
  - After implementation complete (Gate 3/4)
  - Task has acceptance criteria requiring test coverage
  - Need to verify implementation meets requirements

skip_when: |
  - No acceptance criteria defined -> request criteria first
  - Implementation not started -> complete Gate 3 first
  - Already has full test coverage verified -> proceed to review

sequence:
  after: [dev-implementation, dev-devops-setup]
  before: [dev-review]

related:
  complementary: [ring-default:test-driven-development, ring-dev-team:qa-analyst]
---

# Dev Testing (Gate 5)

## Overview

Ensure every acceptance criterion has at least one **unit test** proving it works. Follow TDD methodology: RED (failing test) -> GREEN (minimal implementation) -> REFACTOR (clean up).

**Core principle:** Untested acceptance criteria are unverified claims. Each criterion MUST map to at least one executable unit test.

**Scope:** This gate focuses on unit tests. Integration and E2E tests are handled separately (CI/CD pipeline, QA phase).

## Prerequisites

Before starting this gate:
- Implementation code exists (Gate 3 complete)
- Acceptance criteria are clearly defined
- Test framework is configured and working

## Step 1: Map Acceptance Criteria to Unit Tests

Create a traceability matrix linking each criterion to tests:

```markdown
## Test Coverage Matrix

| ID | Acceptance Criterion | Test File | Test Function | Status |
|----|---------------------|-----------|---------------|--------|
| AC-1 | User can login with valid credentials | auth_test.go | TestAuthService_Login_WithValidCredentials | Pending |
| AC-2 | Invalid password returns error | auth_test.go | TestAuthService_Login_WithInvalidPassword | Pending |
| AC-3 | Empty email returns validation error | auth_test.go | TestAuthService_Login_WithEmptyEmail | Pending |
| AC-4 | Password must be at least 8 chars | user_test.go | TestUserService_CreateUser_ShortPassword | Pending |
```

**Rule:** Every row MUST have at least one unit test. No criterion left untested.

## Step 2: Identify Testable Units

For each criterion, identify the unit to test:

| Criterion Type | Testable Unit | Mock Dependencies |
|----------------|---------------|-------------------|
| Business logic | Service methods | Repository, external APIs |
| Validation | Validators, DTOs | None (pure functions) |
| Domain rules | Entity methods | None |
| Error handling | Service methods | Force error conditions |
| Calculations | Domain services | None |

## Step 3: Execute TDD Cycle

For each acceptance criterion, follow strict TDD:

### 3.1 RED Phase - Write Failing Test

```bash
# Write test that describes expected behavior
# Run test - MUST fail with expected error
go test -run TestAuthService_Login_WithValidCredentials ./...
```

**Verify failure output shows:**
- Test runs (no syntax errors)
- Failure is for right reason (feature missing, not typo)
- Error message indicates expected behavior

**Paste actual failure output:**
```
--- FAIL: TestAuthService_Login_WithValidCredentials (0.00s)
    auth_test.go:25: expected token, got nil
FAIL
```

### 3.2 GREEN Phase - Minimal Implementation

Write only enough code to make the test pass:

```bash
# Implement minimal code
# Run test - MUST pass
go test -run TestAuthService_Login_WithValidCredentials ./...
```

**Verify pass output:**
```
--- PASS: TestAuthService_Login_WithValidCredentials (0.00s)
PASS
```

### 3.3 REFACTOR Phase - Clean Up

Improve code quality while keeping tests green:

- Remove duplication
- Improve naming
- Extract helpers
- Simplify logic

```bash
# After refactoring - MUST still pass
go test -run TestAuthService_Login_WithValidCredentials ./...
```

## Step 4: Dispatch QA Analyst for Unit Tests

Dispatch `ring-dev-team:qa-analyst` for unit test design:

```
Task tool:
  subagent_type: "ring-dev-team:qa-analyst"
  prompt: |
    Create unit tests for the following acceptance criteria:

    TASK_ID: [task identifier]
    ACCEPTANCE_CRITERIA:
    - AC-1: [criterion description]
    - AC-2: [criterion description]

    IMPLEMENTATION_FILES:
    - [file paths with key functions/methods]

    Requirements:
    1. One test per acceptance criterion minimum
    2. Test edge cases and error conditions
    3. Use mocks for external dependencies (repos, APIs)
    4. Follow naming: Test{Unit}_{Method}_{Scenario}_{Expected}
    5. Use table-driven tests where appropriate

    Focus: Unit tests ONLY. Do not write integration or E2E tests.
```

## Step 5: Execute Full Test Suite

Run all unit tests and verify coverage:

```bash
# Run full test suite with coverage
go test ./... -cover

# Or language-specific:
# TypeScript: npm test -- --coverage
# Python: pytest --cov=src
```

**Required output verification:**

```
ok      internal/service    0.015s  coverage: 87.3%
ok      internal/handler    0.012s  coverage: 82.1%
ok      internal/domain     0.008s  coverage: 95.0%

Total coverage: 85.3%
```

## Step 6: Update Traceability Matrix

Mark each criterion with test status:

```markdown
## Test Coverage Matrix (Updated)

| ID | Acceptance Criterion | Test File | Test Function | Status |
|----|---------------------|-----------|---------------|--------|
| AC-1 | User can login with valid credentials | auth_test.go:15 | TestAuthService_Login_WithValidCredentials | PASS |
| AC-2 | Invalid password returns error | auth_test.go:35 | TestAuthService_Login_WithInvalidPassword | PASS |
| AC-3 | Empty email returns validation error | auth_test.go:55 | TestAuthService_Login_WithEmptyEmail | PASS |
| AC-4 | Password must be at least 8 chars | user_test.go:22 | TestUserService_CreateUser_ShortPassword | PASS |
```

## Gate Exit Criteria

Before proceeding to Gate 6 (Review):

- [ ] Every acceptance criterion has at least one unit test
- [ ] All tests follow TDD cycle (RED verified before GREEN)
- [ ] Full test suite passes (0 failures)
- [ ] Coverage meets project threshold (typically 80%+)
- [ ] Traceability matrix complete and updated
- [ ] No skipped or pending tests for this task

## Handling Test Failures

If tests fail during execution:

1. **Do NOT proceed** to Gate 6
2. Identify root cause:
   - Implementation bug -> Return to Gate 3
   - Test bug -> Fix test, re-run TDD cycle
   - Missing requirement -> Document gap, consult stakeholder
3. Fix and re-run full suite
4. Update matrix with resolution

## Anti-Patterns

**Never:**
- Write tests after implementation without RED phase
- Mark tests as skipped to pass gate
- Assume passing tests mean criteria met (verify mapping)
- Copy-paste tests without understanding
- Mock the unit under test (only mock dependencies)
- Test implementation details instead of behavior

**Always:**
- Watch test fail before implementing (RED phase)
- Run full suite, not just new tests
- Verify test actually tests the criterion
- Use descriptive test names
- Test one behavior per test
- Clean up test state

## Execution Report

| Metric | Value |
|--------|-------|
| Duration | Xm Ys |
| Iterations | N |
| Unit Tests Written | X |
| Coverage | XX.X% |
| Criteria Covered | X/Y (100%) |
| Result | PASS/FAIL |

## Recovery Procedures

### Tests written without RED phase

1. Delete/comment implementation code
2. Run test - verify it fails
3. Restore implementation - verify it passes
4. If test passes without implementation -> test is wrong, rewrite

### Coverage below threshold

1. Identify uncovered lines/branches
2. Write additional unit tests targeting gaps
3. Re-run coverage report
4. Repeat until threshold met

### Acceptance criterion has no test

1. Stop proceeding
2. Write unit test for missing criterion
3. Follow full TDD cycle
4. Update traceability matrix
