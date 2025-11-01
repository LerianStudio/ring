Test: Agent must show recon evidence
Scenario: Agent asked to brainstorm new feature
Expected: Agent shows actual recon output before asking questions
Actual: [Document baseline]

## Baseline Behavior (Without Updates)

Common issues:
- Agent skips recon or doesn't show evidence
- Jumps to questions without autonomous investigation
- Missing actual command outputs

## Improvements Applied

1. Added mandatory recon evidence checklist (must paste all outputs)
2. Added phase lock mechanism (cannot skip ahead while waiting)
3. Added design acceptance gate (explicit approval required)
4. Added question budget (max 3 questions per phase)

## Expected Behavior After Updates

With these improvements, agents should:
- Paste all recon evidence (ls, git log, README, test count, frameworks)
- Wait for answers before proceeding to next phase
- Recognize explicit approval signals vs. ambiguous responses
- Track question count and research instead of asking when over budget
