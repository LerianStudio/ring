Test: Agent must complete phase checklist before advancing
Scenario: Agent debugging a test failure
Expected: Agent completes all Phase 1 items before Phase 2
Actual: [Document baseline]

## Baseline Behavior (Without Updates)

Common issues:
- Agent jumps to hypothesis without completing investigation
- Skips evidence gathering from all components
- Missing systematic phase progression

## Improvements Applied

1. Added Phase 1 Gate Checklist that must be completed before Phase 2
2. Added forced documentation requirement (PHASE 1 FINDINGS summary)
3. Added hypothesis counter (max 3 attempts before architectural review)
4. Added time limits (30 min/1 hour time boxes)

## Expected Behavior After Updates

With these improvements, agents should:
- Complete and include Phase 1 checklist in their response
- Document findings summary before moving to Phase 2
- Track hypothesis count and stop after 3 failed attempts
- Escalate to human partner when hitting time limits
