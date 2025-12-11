---
name: dev-validation
description: |
  Development cycle validation gate (Gate 5) - validates all acceptance criteria are met
  and requires explicit user approval before completion.

trigger: |
  - After review gate passes (Gate 4)
  - Implementation and tests complete
  - Need user sign-off on acceptance criteria

skip_when: |
  - Review not passed -> complete Gate 4 first
  - Already validated and approved -> proceed to completion
  - No acceptance criteria defined -> request criteria first

sequence:
  after: [ring-dev-team:dev-review]

related:
  complementary: [ring-default:verification-before-completion]

verification:
  automated:
    - command: "go test ./... 2>&1 | grep -c PASS"
      description: "All tests pass"
      success_pattern: "[1-9][0-9]*"
    - command: "cat .ring/dev-team/current-cycle.json | jq '.gates[4].verdict'"
      description: "Review gate passed"
      success_pattern: "PASS"
  manual:
    - "User has provided explicit APPROVED or REJECTED decision"
    - "All acceptance criteria have verified evidence"
    - "Validation checklist presented to user"

examples:
  - name: "Successful validation"
    context: "4 acceptance criteria, all tests pass"
    expected_flow: |
      1. Gather evidence for each criterion
      2. Build validation checklist with evidence types
      3. Present to user with APPROVED/REJECTED options
      4. User selects APPROVED
      5. Document approval, proceed to feedback loop
  - name: "Validation rejection"
    context: "AC-3 not met (response time too slow)"
    expected_flow: |
      1. Present validation checklist
      2. User identifies AC-3 failure
      3. User selects REJECTED with reason
      4. Create remediation task
      5. Return to Gate 0 for fixes
---

# Dev Validation (Gate 5)

## Overview

Final validation gate requiring explicit user approval. Present evidence that each acceptance criterion is met and obtain APPROVED or REJECTED decision.

**Core principle:** Passing tests and code review do not guarantee requirements are met. User validation confirms implementation matches intent.

## Pressure Resistance

**Gate 5 (Validation) requires EXPLICIT user approval. Pressure scenarios and required responses:**

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| **User Busy** | "User is busy, assume approval" | "CANNOT assume approval. Wait for explicit response. Document pending status." |
| **Tests Pass** | "Tests pass, validation redundant" | "Tests verify code works. Validation verifies it meets REQUIREMENTS. Different concerns." |
| **Minor Issues** | "Fix issues after approval" | "No partial approval. REJECTED with issues, fix first, then re-validate." |
| **Implied Approval** | "User didn't object" | "Silence ≠ approval. Require explicit 'APPROVED' or 'REJECTED: reason'." |

**Non-negotiable principle:** User MUST respond with "APPROVED" or "REJECTED: [reason]". No other responses accepted.

## Self-Approval Prohibition

**HARD GATE:** The agent that implemented code CANNOT approve validation for that same code.

| Scenario | Allowed? | Action |
|----------|----------|--------|
| Different agent/human approves | YES | Proceed with approval |
| Same agent self-approves | NO | STOP - requires external approval |
| User explicitly approves | YES | User approval always valid |

**If you implemented the code, you CANNOT approve it. Wait for user or different reviewer.**

**Important:** "Different agent" means different human/entity. The same human using different agent roles (backend-engineer → code-reviewer) is STILL self-approval and PROHIBITED.

## Common Rationalizations - REJECTED

| Excuse | Reality |
|--------|---------|
| "User is unavailable" | Unavailability ≠ approval. STOP and wait. Document pending. |
| "Tests prove it works" | Tests verify behavior. User validates requirements alignment. |
| "Minor issues can wait" | No partial approval. Fix issues, then revalidate. |
| "User seemed happy" | Seeming ≠ approval. Require explicit response. |
| "Implicit approval after demo" | Demo ≠ approval. Ask for explicit decision. |
| "User approved similar before" | Past ≠ present. Each validation requires fresh approval. |
| "Async over sync - work in parallel" | Validation is a GATE, not async task. STOP means STOP. |
| "Continue other tasks while waiting" | Other tasks may conflict. Validation blocks ALL related work. |
| "Cost of waiting is too high" | Cost of wrong approval is higher. Wait is investment. |
| "Send message and continue" | Message sent ≠ waiting for response. STOP until APPROVED. |
| "Looks good" = approval | "Looks good" is ambiguous. Require explicit APPROVED. |
| "User said 'sure'" | "Sure" is ambiguous. Require explicit APPROVED. |
| "No objections raised" | Lack of objection ≠ approval. Require explicit response. |
| "User delegated approval to X" | Delegation ≠ stakeholder approval. Only original requester can approve. |
| "Emergency production issue" | Emergency ≠ gate bypass. Validation protects production. |
| "Reduced scope, easier to approve" | Reduced scope ≠ auto-approval. User must validate actual delivery. |
| "APPROVED if X (X is true)" | Conditional approval ≠ approval. Verify X, then re-request. |

## Red Flags - STOP

If you catch yourself thinking ANY of these, STOP immediately:

- "User is busy, I'll assume approval"
- "Tests pass, validation is redundant"
- "These minor issues can be fixed later"
- "User didn't say no, so it's approved"
- "User seemed satisfied with the demo"
- "Previous similar work was approved"
- "I'll work on other tasks while waiting"
- "Async over sync - don't block"
- "Send message and continue"
- "Cost of waiting is too high"
- "'Looks good' means approved"
- "User said 'sure'"
- "No objections = approved"
- "User delegated approval authority to someone else"
- "This is an emergency, skip validation"
- "We implemented less than requested, so it's easier to approve"
- "I'm switching roles to approve this"

**All of these indicate Gate 5 violation. Wait for explicit "APPROVED" or "REJECTED".**

## Ambiguous Response Handling

**User responses that are NOT valid approvals:**

| Response | Status | Action Required |
|----------|--------|-----------------|
| "Looks good" | ❌ AMBIGUOUS | "To confirm, please respond with APPROVED or REJECTED: [reason]" |
| "Sure" / "Ok" / "Fine" | ❌ AMBIGUOUS | Ask for explicit APPROVED |
| "👍" / "✅" | ❌ AMBIGUOUS | Emojis are not formal approval. Ask for APPROVED. |
| "Go ahead" | ❌ AMBIGUOUS | Ask for explicit APPROVED |
| "Ship it" | ❌ AMBIGUOUS | Ask for explicit APPROVED |
| "APPROVED" | ✅ VALID | Proceed to next gate |
| "REJECTED: [reason]" | ✅ VALID | Document reason, return to Gate 0 |
| "APPROVED if X" | ❌ CONDITIONAL | Not approved until X is verified. Status = PENDING. |
| "APPROVED with caveats" | ❌ CONDITIONAL | Not approved. List caveats, verify each, then re-ask. |
| "APPROVED but fix Y later" | ❌ CONDITIONAL | Not approved. Y must be addressed first. |

**When user gives ambiguous response:**
```
"Thank you for the feedback. For formal validation, please confirm with:
- APPROVED - to proceed with completion
- REJECTED: [reason] - to return for fixes

Which is your decision?"
```

**Never interpret intent. Require explicit keyword.**

## Awaiting Approval - STOP ALL WORK

**When validation request is presented:**

1. **STOP ALL WORK** on this feature, module, and related code
2. **DO NOT** proceed to documentation, refactoring, or "quick fixes"
3. **DO NOT** work on "unrelated" tasks in the same codebase
4. **WAIT** for explicit user response

**User unavailability is NOT permission to:**
- Assume approval
- Work on "low-risk" next steps
- Redefine criteria as "already met"
- Proceed with "we'll fix issues later"

**Document pending status and WAIT.**

## Approval Format - MANDATORY

**User MUST respond with exactly one of:**

✅ **"APPROVED"** - All criteria verified, proceed to next gate
✅ **"REJECTED: [specific reason]"** - Issues found, fix and revalidate

**NOT acceptable:**
- ❌ "Looks good" (vague)
- ❌ "👍" (ambiguous)
- ❌ Silence (not a response)
- ❌ "Approved with minor issues" (partial = REJECTED)

**If user provides ambiguous response, ask for explicit APPROVED or REJECTED.**

## Prerequisites

Before starting this gate:
- All tests pass (Gate 3 verified)
- Code review passed (Gate 4 VERDICT: PASS)
- Implementation is complete and stable

## Steps 1-4: Evidence Collection and Validation

| Step | Action | Output |
|------|--------|--------|
| **1. Gather Evidence** | Collect proof per criterion | Table: Criterion, Evidence Type (Test/Demo/Log/Manual/Metric), Location, Status |
| **2. Verify** | Execute verification (automated: `npm test --grep "AC-X"`, manual: documented steps with Result + Screenshot) | VERIFIED/FAILED per criterion |
| **3. Build Checklist** | For each AC: Status + Evidence list + Verification method | Validation Checklist |
| **4. Present Request** | Task Summary + Validation Table + Test Results + Review Summary + Artifacts | USER DECISION block with APPROVED/REJECTED options |

**Validation Request format:**
```
VALIDATION REQUEST - [TASK-ID]
Task: [title], [description], [date]
Criteria: Table (Criterion | Status | Evidence)
Tests: Total/Passed/Failed/Coverage
Review: VERDICT + issue counts
Artifacts: Code, Tests, Docs links

USER DECISION REQUIRED:
[ ] APPROVED - proceed
[ ] REJECTED - specify: which criterion, what's missing, what's wrong
```

## Steps 5-6: Handle Decision and Document

| Decision | Actions | Documentation |
|----------|---------|---------------|
| **APPROVED** | 1. Document (Task, Approver, Date, Notes) → 2. Update status → 3. Proceed to feedback loop | Validation Approved record |
| **REJECTED** | 1. Document (Task, Rejector, Date, Criterion failed, Issue, Expected vs Actual) → 2. Create remediation task → 3. Return to Gate 0 → 4. After fix: restart from Gate 3 → 5. Track in feedback loop | Validation Rejected + Remediation Required records |

**Validation Record format:** Date, Validator, Decision, Criteria Summary (X/Y), Evidence Summary (tests/manual/perf), Decision Details, Next Steps

## Validation Best Practices

| Category | Strong Evidence | Weak Evidence (avoid) |
|----------|-----------------|----------------------|
| **Evidence Quality** | Automated test + assertion, Screenshot/recording, Log with exact values, Metrics within threshold | "Works on my machine", "Tested manually" (no details), "Should be fine", Indirect evidence |
| **Verifiable Criteria** | "User can login" → test login + verify session | "System is fast" → needs specific metric |
| | "Page loads <2s" → measure + show metric | "UX is good" → needs measurable criteria |

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

| Scenario | Action |
|----------|--------|
| **User Unavailable** | Document pending → Do NOT proceed → Set escalation → Block task completion |
| **Criterion Ambiguity** | STOP → Ask user to clarify → Update AC → Re-verify with new understanding |
| **New Requirements** | Document as new req → Complete current validation on original AC → Create new task → NO scope creep |
