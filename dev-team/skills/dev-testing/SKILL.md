---
name: dev-testing
description: |
  Development cycle testing gate (Gate 3) - ensures unit test coverage for all
  acceptance criteria using TDD methodology (RED-GREEN-REFACTOR).
  Focus: Unit tests only. Integration/E2E tests handled separately in CI/CD.

trigger: |
  - After implementation and SRE complete (Gate 0/1/2)
  - Task has acceptance criteria requiring test coverage
  - Need to verify implementation meets requirements

skip_when: |
  - No acceptance criteria defined -> request criteria first
  - Implementation not started -> complete Gate 0 first
  - Already has full test coverage verified -> proceed to review

sequence:
  after: [ring-dev-team:dev-implementation, ring-dev-team:dev-devops, ring-dev-team:dev-sre]
  before: [ring-dev-team:dev-review]

related:
  complementary: [ring-default:test-driven-development, ring-dev-team:qa-analyst]

verification:
  automated:
    - command: "go test ./... -covermode=atomic -coverprofile=coverage.out 2>&1 && go tool cover -func=coverage.out | grep -E 'total:|PASS|FAIL'"
      description: "Go tests pass with branch coverage (atomic mode)"
      success_pattern: "PASS.*total:.*[8-9][0-9]|100"
      failure_pattern: "FAIL|total:.*[0-7][0-9]"
    - command: "npm test -- --coverage 2>&1 | grep -E 'Tests:|Coverage'"
      description: "TypeScript tests pass with coverage"
      success_pattern: "Tests:.*passed|Coverage.*[8-9][0-9]|100"
      failure_pattern: "failed|Coverage.*[0-7][0-9]"
  manual:
    - "Every acceptance criterion has at least one test in traceability matrix"
    - "RED phase failure output was captured before GREEN phase"
    - "No skipped or pending tests for this task"

examples:
  - name: "TDD for auth service"
    context: "AC-1: User can login with valid credentials"
    expected_flow: |
      1. Write TestAuthService_Login_WithValidCredentials
      2. Run test - FAIL (no implementation)
      3. Implement Login method
      4. Run test - PASS
      5. Update traceability matrix: AC-1 -> auth_test.go:15
  - name: "Coverage gap fix"
    context: "Coverage at 72%, need 80%"
    expected_flow: |
      1. Identify uncovered lines
      2. Write tests for edge cases
      3. Re-run coverage report
      4. Verify 80%+ achieved
---

# Dev Testing (Gate 3)

See [CLAUDE.md](https://raw.githubusercontent.com/LerianStudio/ring/main/CLAUDE.md) for canonical testing requirements.

## Overview

Ensure every acceptance criterion has at least one **unit test** proving it works. Follow TDD methodology: RED (failing test) -> GREEN (minimal implementation) -> REFACTOR (clean up).

**Core principle:** Untested acceptance criteria are unverified claims. Each criterion MUST map to at least one executable unit test.

**Scope:** This gate focuses on unit tests. Integration and E2E tests are handled separately (CI/CD pipeline, QA phase).

## Pressure Resistance

**Gate 3 (Testing) enforces MANDATORY unit test coverage. Pressure scenarios and required responses:**

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| **Manual Testing** | "I manually tested everything" | "Manual tests are not executable, not repeatable. Write unit tests." |
| **Close Enough** | "83% coverage, close to 85%" | "85% is MINIMUM, not target. 83% = FAIL. Write more tests." |
| **Integration** | "My integration tests cover this" | "Gate 3 = unit tests only. Integration tests are separate scope." |
| **Time** | "Tests will slow us down" | "Tests prevent rework. No tests = more time debugging later." |

**Non-negotiable principle:** Coverage threshold is MANDATORY minimum, not aspirational target. Below threshold = FAIL.

## Common Rationalizations - REJECTED

| Excuse | Reality |
|--------|---------|
| "Manual testing validates all criteria" | Manual tests are not executable, not repeatable, not automatable. Gate 3 requires unit tests. |
| "Coverage is 83%, close enough to 85%" | Threshold is mandatory minimum. 83% = FAIL. No exceptions. |
| "Integration tests are better verification" | Gate 3 scope is unit tests only. Integration tests are different gate. |
| "We can add tests later in CI/CD" | Gate 3 exit criteria require tests NOW. Later = never. |
| "These mocks make it a unit test" | If you hit DB/API/filesystem, it's integration. Mock the interface. |
| "All criteria tested, coverage low" | Write edge case tests until threshold met. |
| "Coverage % is vanity metric" | Coverage is GATE metric. Vanity or not, below threshold = FAIL. |
| "Integration tests compensate low coverage" | Different scope. Integration tests are NOT unit test substitute. |
| "Edge cases are obscure/unlikely" | Edge cases cause production incidents. Test them. |
| "Time spent on edge cases not worth it" | Time spent debugging production incidents is worse. Test now. |
| "84% with AC tested is defensible" | Defensible ≠ passing. Threshold is 85%. Period. |
| "PROJECT_RULES.md says 70% is OK" | Ring minimum is 85%. PROJECT_RULES.md can raise, not lower. |
| "Team decided lower threshold" | Team decisions don't override Ring gates. 85% is non-negotiable. |
| "This module is simple, 60% enough" | Module complexity doesn't lower threshold. 85% everywhere. |

## Red Flags - STOP

If you catch yourself thinking ANY of these, STOP immediately:

- "Manual testing already validated this"
- "Close enough to coverage threshold"
- "These integration tests prove it better"
- "We can add tests after review"
- "All criteria covered, percentage doesn't matter"
- "Tests slow down development"
- "Coverage % is vanity metric"
- "Integration tests compensate"
- "Edge cases are unlikely"
- "Time spent not worth it for 4%"
- "76% is defensible"
- "PROJECT_RULES.md allows lower"
- "Team agreed to 70%"

**All of these indicate Gate 3 violation. Write unit tests until threshold met.**

## Coverage Threshold Governance

**Ring establishes MINIMUM thresholds. PROJECT_RULES.md can only ADD constraints:**

| Source | Can Raise? | Can Lower? |
|--------|-----------|-----------|
| Ring Standard (85%) | N/A (baseline) | N/A (baseline) |
| PROJECT_RULES.md | ✅ YES (e.g., 90%) | ❌ NO |
| Team Decision | ✅ YES (e.g., 95%) | ❌ NO |
| Manager Override | ❌ NO | ❌ NO |

## Coverage Measurement Rules (HARD GATE)

**Coverage tool output is the SOURCE OF TRUTH. No adjustments allowed:**

### Dead Code Handling

| Scenario | Allowed? | Required Action |
|----------|----------|-----------------|
| Exclude dead code from measurement | ❌ NO | **Delete the dead code** |
| Use `// coverage:ignore` annotations | ⚠️ ONLY with justification | Must document WHY in PR |
| "Mental math" adjustments | ❌ NO | Use actual tool output |
| Different tools show different % | Use lowest | Conservative approach |

**Valid exclusion annotations (must be documented):**
- Generated code (protobuf, swagger) - excluded by default
- Unreachable panic handlers (already tested by unit tests)
- Platform-specific code not running in CI

**INVALID exclusion reasons:**
- ❌ "It's boilerplate"
- ❌ "Trivial getters/setters"
- ❌ "Will never be called in production"
- ❌ "Too hard to test"

### Tool Dispute Resolution

**If you believe the coverage tool is wrong:**

| Step | Action | Why |
|------|--------|-----|
| 1 | Document the discrepancy | "Tool shows 83%, I expect 90%" |
| 2 | Investigate root cause | Missing test? Tool bug? Config issue? |
| 3 | Fix the issue | Add test OR fix tool config |
| 4 | Re-run coverage | Get new measurement |
| 5 | Use NEW measurement | No mental math on old number |

**You CANNOT proceed with "the tool is wrong, real coverage is higher."**

### Anti-Rationalization for Coverage

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Tool shows 83% but real is 90%" | Tool output IS real. Your belief is not. | **Fix issue, re-measure** |
| "Excluding dead code gets us to 85%" | Delete dead code, don't exclude it. | **Delete dead code** |
| "Test files lower the average" | Test files should be excluded by tool config. | **Fix tool configuration** |
| "Generated code tanks coverage" | Generated code should be excluded by pattern. | **Add exclusion pattern** |
| "84.5% rounds to 85%" | Rounding is not allowed. 84.5% < 85%. | **Write more tests** |
| "Close enough with all AC tested" | "Close enough" is not a passing grade. | **Meet exact threshold** |

**If PROJECT_RULES.md specifies < 85%:**
1. That specification is INVALID
2. Ring minimum (85% branch coverage) still applies
3. Report as blocker: "PROJECT_RULES.md coverage threshold (X%) below Ring minimum (85%)"
4. Do NOT proceed with lower threshold

## Unit Test vs Integration Test

**Gate 3 requires UNIT tests. Know the difference:**

| Type | Characteristics | Gate 3? |
|------|----------------|---------|
| **Unit** ✅ | Mocks all external dependencies, tests single function | YES |
| **Integration** ❌ | Hits real database/API/filesystem | NO - separate scope |

**If you're thinking "but my test needs the database":**
- That's an integration test
- Mock the repository interface
- Test the business logic, not the database

**"Mocking the database driver" is still integration. Mock the INTERFACE.**

## Prerequisites

Before starting this gate:
- Implementation code exists (Gate 0 complete)
- Acceptance criteria are clearly defined
- Test framework is configured and working

## Step 1: Map Acceptance Criteria to Unit Tests

Create traceability matrix: | ID | Criterion | Test File | Test Function | Status (Pending/PASS) |

**Rule:** Every criterion MUST have at least one unit test. No criterion left untested.

## Step 2: Identify Testable Units

| Criterion Type | Testable Unit | Mock Dependencies |
|----------------|---------------|-------------------|
| Business logic | Service methods | Repository, external APIs |
| Validation | Validators, DTOs | None (pure functions) |
| Domain rules | Entity methods | None |
| Error handling | Service methods | Force error conditions |

## Step 3: Execute TDD Cycle

| Phase | Action | Verify |
|-------|--------|--------|
| **RED** | Write test describing expected behavior | Test runs + fails for right reason (feature missing, not typo) + paste failure output |
| **GREEN** | Write minimal code to pass | Test passes |
| **REFACTOR** | Remove duplication, improve naming, extract helpers | Tests still pass |

## Step 4: Dispatch QA Analyst for Unit Tests

**Dispatch:** `Task(subagent_type: "ring-dev-team:qa-analyst")` with TASK_ID, ACCEPTANCE_CRITERIA, IMPLEMENTATION_FILES. Requirements: 1+ test/criterion, edge cases, mock deps, naming: `Test{Unit}_{Method}_{Scenario}`. Unit tests ONLY.

## Step 5: Execute Full Test Suite

Run: `go test ./... -covermode=atomic -coverprofile=coverage.out && go tool cover -func=coverage.out` (or `npm test -- --coverage`, `pytest --cov=src`). Verify coverage ≥85%.

## Step 6: Update Traceability Matrix

Update matrix with line numbers and PASS status for each criterion.

## Gate Exit Criteria

Before proceeding to Gate 4 (Review):

- [ ] Every acceptance criterion has at least one unit test
- [ ] All tests follow TDD cycle (RED verified before GREEN)
- [ ] Full test suite passes (0 failures)
- [ ] **Coverage MUST meet 85% branch coverage minimum** (or project-defined threshold in PROJECT_RULES.md). This is MANDATORY, not aspirational.
  - Below threshold = FAIL
  - No exceptions for "close enough"
  - All acceptance criteria MUST have executable tests
- [ ] Traceability matrix complete and updated
- [ ] No skipped or pending tests for this task
- [ ] **QA Analyst VERDICT = PASS** (mandatory for gate progression)

## QA Verdict Handling

QA Analyst returns **VERDICT: PASS** or **VERDICT: FAIL**.

```
PASS (coverage ≥ threshold) → Proceed to Gate 4 (Review)
FAIL (coverage < threshold) → Return to Gate 0 (Implementation)
```

### On FAIL

1. QA provides gap analysis (what needs tests)
2. Dev-cycle returns to Gate 0 with this analysis
3. Implementation agent adds the missing tests
4. Gate 3 re-runs
5. **Max 3 attempts**, then escalate to user

### Iteration Tracking

The dev-cycle orchestrator tracks iteration count in state:

```json
{
  "testing": {
    "iteration": 1,
    "verdict": "FAIL",
    "coverage_actual": 72.5,
    "coverage_threshold": 85
  }
}
```

**Enforcement rules:**
- Increment `iteration` on each Gate 3 entry
- After 3rd FAIL: STOP, do NOT return to Gate 0
- Present gap analysis to user for manual resolution
- User must decide: fix manually, adjust threshold (if allowed), or abort task

## Handling Test Failures

If tests fail during execution:

1. **Do NOT proceed** to Gate 3
2. Identify root cause:
   - Implementation bug -> Return to Gate 0
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

| Issue | Recovery Steps |
|-------|---------------|
| **Tests without RED phase** | Delete impl → Run test (must fail) → Restore impl (must pass) → If passes without impl: test is wrong, rewrite |
| **Coverage below threshold** | Identify uncovered lines → Write unit tests for gaps → Re-run coverage → Repeat until ≥85% |
| **Criterion has no test** | STOP → Write unit test → Full TDD cycle → Update matrix |
