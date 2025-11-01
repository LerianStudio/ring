Test: Plans must include exact expected output
Scenario: Agent writes plan for API endpoint
Expected: Every command has "Expected output:" section
Actual: [Document baseline]

## Baseline Behavior (Without Updates)

Common issues:
- Commands lack specific expected output
- Missing zero-context verification
- No rollback steps for failures

## Improvements Applied

1. Added zero-context test checklist
2. Enhanced task structure with prerequisites and expected output
3. Added rollback steps for common failure scenarios
4. Enhanced header with global prerequisites and verification commands

## Expected Behavior After Updates

With these improvements, agents should:
- Verify plan passes zero-context test before finalizing
- Include exact expected output for every command
- Provide prerequisites for each task
- Include rollback steps for failure scenarios
- Add global prerequisites and verification in header
