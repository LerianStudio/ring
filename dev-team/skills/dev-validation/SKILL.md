---
name: dev-validation
description: |
  Development cycle validation gate (Gate 4) - validates all acceptance criteria are met
  and requires explicit user approval before completion.

trigger: |
  - After review gate passes (Gate 3)
  - Implementation and tests complete
  - Need user sign-off on acceptance criteria

skip_when: |
  - Review not passed -> complete Gate 3 first
  - Already validated and approved -> proceed to completion
  - No acceptance criteria defined -> request criteria first

sequence:
  after: [dev-review]

related:
  complementary: [ring-default:verification-before-completion]
---

# Dev Validation (Gate 4)

## Overview

Final validation gate requiring explicit user approval. Present evidence that each acceptance criterion is met and obtain APPROVED or REJECTED decision.

**Core principle:** Passing tests and code review do not guarantee requirements are met. User validation confirms implementation matches intent.

## Prerequisites

Before starting this gate:
- All tests pass (Gate 2 verified)
- Code review passed (Gate 3 VERDICT: PASS)
- Implementation is complete and stable

## Step 1: Gather Validation Evidence

Collect proof for each acceptance criterion:

```markdown
## Evidence Collection

| Criterion | Evidence Type | Location | Verified |
|-----------|---------------|----------|----------|
| AC-1: User can login | Test + Demo | auth.test.ts:15, /login page | Pending |
| AC-2: Invalid password returns 401 | Test | auth.test.ts:28 | Pending |
| AC-3: Session expires after 30min | Test + Log | session.test.ts:12, session_log.txt | Pending |
```

Evidence types:
- **Test**: Automated test that verifies criterion
- **Demo**: Visual demonstration or screenshot
- **Log**: System log showing expected behavior
- **Manual**: Manual verification steps performed
- **Metric**: Performance/load test results

## Step 2: Verify Each Criterion

For each acceptance criterion, execute verification:

### Automated Verification

```bash
# Run specific test for criterion
npm test -- --grep "AC-1"

# Capture output as evidence
npm test -- --grep "AC-1" > evidence/ac-1-test-output.txt
```

### Manual Verification

For criteria requiring user interaction:

```markdown
## Manual Verification Steps - AC-4

1. Navigate to /login
2. Enter valid credentials
3. Verify redirect to /dashboard
4. Verify user name displayed in header

**Result:** [VERIFIED/FAILED]
**Screenshot:** [link or inline]
```

## Step 3: Build Validation Checklist

Present checklist to user with evidence for each criterion:

```markdown
## Validation Checklist - [TASK-ID]

### Acceptance Criteria Status

#### AC-1: User can login with valid credentials
- Status: VERIFIED
- Evidence:
  - Test `auth.test.ts:15` - PASS
  - Manual demo at /login - SUCCESS
- Verification method: Automated test + manual walkthrough

#### AC-2: Invalid password returns 401 error
- Status: VERIFIED
- Evidence:
  - Test `auth.test.ts:28` - PASS
  - API response captured in `evidence/ac-2-response.json`
- Verification method: Automated test

#### AC-3: Session expires after 30 minutes of inactivity
- Status: VERIFIED
- Evidence:
  - Test `session.test.ts:12` - PASS (uses time mocking)
  - Integration test with real timer in CI
- Verification method: Automated test with time simulation

#### AC-4: Login page loads under 2 seconds
- Status: VERIFIED
- Evidence:
  - Performance test: avg 1.2s, p95 1.8s
  - Lighthouse score: 92
- Verification method: Performance test suite
```

## Step 4: Present for User Approval

Format the validation request:

```markdown
---
## VALIDATION REQUEST - [TASK-ID]

### Task Summary
**Title:** [Task title]
**Description:** [Brief description]
**Implementation Date:** YYYY-MM-DD

### Validation Summary

| Criterion | Status | Evidence |
|-----------|--------|----------|
| AC-1: User can login | VERIFIED | Test + Demo |
| AC-2: Invalid password returns 401 | VERIFIED | Test + API log |
| AC-3: Session expires 30min | VERIFIED | Test (time mock) |
| AC-4: Page loads <2s | VERIFIED | Perf test: 1.2s avg |

### Test Results
- Total tests: 47
- Passed: 47
- Failed: 0
- Coverage: 87.3%

### Code Review
- VERDICT: PASS
- Critical issues: 0
- High issues: 0

### Artifacts
- Code: [branch/commit link]
- Tests: [test file locations]
- Documentation: [doc links]

---

### USER DECISION REQUIRED

Please review the evidence above and provide your decision:

[ ] **APPROVED** - All criteria met, proceed to completion
[ ] **REJECTED** - Criteria not met (provide reason below)

**If REJECTED, specify:**
- Which criterion failed?
- What evidence is missing?
- What behavior is incorrect?

---
```

## Step 5: Handle User Decision

### Decision: APPROVED

1. Document approval:
   ```markdown
   ## Validation Approved

   **Task:** [TASK-ID]
   **Approved by:** [User]
   **Date:** YYYY-MM-DD HH:MM
   **Notes:** [Any user comments]
   ```

2. Update task status
3. Proceed to feedback loop
4. Trigger feedback loop for metrics

### Decision: REJECTED

1. Document rejection with reason:
   ```markdown
   ## Validation Rejected

   **Task:** [TASK-ID]
   **Rejected by:** [User]
   **Date:** YYYY-MM-DD HH:MM

   **Rejection Reason:**
   - Criterion: [Which AC failed]
   - Issue: [What's wrong]
   - Expected: [What user expected]
   - Actual: [What was delivered]
   ```

2. Create remediation task:
   ```markdown
   ## Remediation Required

   **Original Task:** [TASK-ID]
   **Issue:** [Description of gap]

   **Required Actions:**
   1. [Specific fix needed]
   2. [Additional test needed]
   3. [Documentation update]

   **Return to:** Gate 0 (Implementation)
   ```

3. Return to Gate 0 with rejection details
4. After remediation, restart from Gate 2 (Testing)
5. Track rejection in feedback loop (assertiveness penalty)

## Step 6: Document Validation Outcome

Create validation record:

```markdown
## Validation Record - [TASK-ID]

**Date:** YYYY-MM-DD
**Validator:** [User name/role]
**Decision:** APPROVED/REJECTED

### Criteria Summary
- Total criteria: X
- Verified: Y
- Failed: Z

### Evidence Summary
- Automated tests: X passing
- Manual verifications: Y completed
- Performance tests: Z within threshold

### Decision Details
[APPROVED: No issues]
OR
[REJECTED: Criterion AC-X failed because...]

### Next Steps
[Proceed to completion]
OR
[Return to Gate 0 for: ...]
```

## Validation Best Practices

### Evidence Quality

**Strong evidence:**
- Automated test with clear assertion
- Screenshot/recording of expected behavior
- Log output showing exact values
- Performance metrics within threshold

**Weak evidence (avoid):**
- "It works on my machine"
- "I tested it manually" (without details)
- "Should be fine"
- Indirect evidence (test for different criterion)

### Criterion Verification

**Verifiable criterion:**
- "User can login with valid credentials" -> Test login flow, verify session created
- "Page loads under 2 seconds" -> Measure load time, show metric

**Hard to verify (rewrite needed):**
- "System is fast" -> Define specific metric
- "User experience is good" -> Define measurable criteria
- "Code is clean" -> Code review already covers this

## Handling Partial Validation

If some criteria pass but others fail:

1. **Do NOT partially approve**
2. Mark entire validation as REJECTED
3. Document which criteria passed (won't need re-verification)
4. Document which criteria failed (need fixes)
5. After fixes, re-verify only failed criteria
6. Present updated checklist for approval

## Anti-Patterns

**Never:**
- Skip validation because "tests pass"
- Auto-approve without user decision
- Assume criterion is met without evidence
- Accept vague approval ("looks good")
- Proceed while awaiting decision
- Reuse old evidence for new changes

**Always:**
- Present evidence for EVERY criterion
- Require explicit APPROVED/REJECTED decision
- Document rejection reason in detail
- Track validation metrics
- Re-verify after any changes

## Execution Report

| Metric | Value |
|--------|-------|
| Duration | Xm Ys |
| Criteria Validated | X/Y |
| Evidence Collected | X automated, Y manual |
| User Decision | APPROVED/REJECTED |
| Rejection Reason | [if applicable] |
| Result | Gate passed / Returned to Gate 0 |

## Edge Cases

### User Unavailable

If user cannot provide decision within SLA:
1. Document pending status
2. Do NOT proceed without approval
3. Set reminder/escalation
4. Block task from completion

### Criterion Ambiguity

If criterion interpretation is unclear:
1. Stop validation
2. Ask user to clarify criterion
3. Update acceptance criteria with clarification
4. Re-verify with updated understanding

### New Requirements During Validation

If user requests additional features during validation:
1. Document as new requirement
2. Complete current validation (APPROVED/REJECTED on original criteria)
3. Create new task for additional requirements
4. Do NOT scope-creep current task
