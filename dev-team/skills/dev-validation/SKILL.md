---
name: ring:dev-validation
description: |
  Development cycle validation gate (Gate 5) — validates all acceptance criteria are met
  and requires explicit user approval before completion. Runs at task cadence.
---

# Validation Gate (Gate 5)

## When to use
- After review gate passes (Gate 4)
- Implementation and tests complete
- Need user sign-off on acceptance criteria

## Skip when
- Not inside a development cycle (ring:dev-cycle or ring:dev-cycle-frontend)
- Task is documentation-only, configuration-only, or non-code
- No implementation or tests were produced

## Sequence
**Runs after:** ring:codereview

## Related
**Complementary:** ring:dev-cycle, ring:codereview


Validates acceptance criteria and requires explicit user approval.

**Self-approval PROHIBITED.** If you implemented the code, you CANNOT approve it. Wait for user or different reviewer.

## Approval Authority

| Who | Can Approve? |
|-----|-------------|
| User (original requester) | ✅ YES |
| Different agent/human | ✅ YES |
| Same agent that implemented | ❌ NO — self-approval prohibited |

## Step 1: Build Validation Report

Map each acceptance criterion to evidence (tests, PRs, manual verification):

```markdown
## Validation Results

| AC # | Criterion | Evidence | Status | Severity |
|------|-----------|----------|--------|----------|
| AC-1 | {criterion} | {tests pass / file:line / manual} | MET / NOT MET / PARTIAL | - / HIGH / MEDIUM / LOW |
```

Severity calibration:
- CRITICAL: acceptance criterion completely unmet
- HIGH: criterion partially met or performance degraded
- MEDIUM: edge case or non-critical gap (main path works)
- LOW: code works but quality suboptimal

## Step 2: Present to User

```markdown
## Gate 5: Validation

### Summary
- Task: {unit_id}
- ACs: {N}/{total} met
- Recommendation: APPROVED / REJECTED

### Validation Table
{validation_table from Step 1}

### Issues (if any)
| Severity | AC # | Description | Recommendation |
|----------|------|-------------|----------------|

### Decision Required
Reply with one of:
- APPROVED — proceed to completion
- REJECTED — return to Gate 0 with comments
- FIX {AC#} then APPROVED — fix specific items first
```

## Step 3: Interpret Response

Explicit approval keywords: `APPROVED`, `YES`, `GO AHEAD`, `SHIP IT`, `PROCEED`, `LOOKS GOOD`.
Explicit rejection keywords: `REJECTED`, `REWORK`, `FIX`, `NEEDS CHANGES`.

Ambiguous responses (👍, "ok", "sure") → Ask for clarification:
> "To confirm: are you APPROVING this for completion, or requesting changes?"

## Step 4: Handle Decision

**APPROVED:**
- Record approval with timestamp + approver identity
- Proceed to next gate

**REJECTED:**
- Record rejection with specific feedback
- Return to Gate 0 with explicit gap list
- Track iteration count (max 3 cycles before escalation)

## Output Format

```markdown
## Validation Summary
- unit_id / ACs met: X/Y / recommendation / decision

## Acceptance Criteria Status
{validation table}

## Decision
APPROVED by {approver} at {timestamp}
OR
REJECTED: {feedback} → returning to Gate 0
```
