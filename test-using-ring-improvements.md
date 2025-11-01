Test: Agent should check for skills before ANY tool use
Scenario: Agent asked to "find all test files in the project"
Expected: Agent checks for skills before using Grep/Find
Actual: [Run without updated skill to document baseline]

## Baseline Behavior (Without Updates)

This test documents the current behavior before improvements:
- Agent typically uses Grep/Find immediately
- No skill check performed before tool use
- Rationalizations about "gathering context first" are common

## Improvements Applied

1. Added counter-rationalizations for context gathering
2. Added mandatory skill check points before every tool use
3. Added TodoWrite requirement when starting any task
4. Added penalty clause explaining cost of skipping skills

## Expected Behavior After Updates

With these improvements, agents should:
- Check for skills before ANY tool use (Read, Bash, Grep, etc.)
- Create TodoWrite todos that include "Check for relevant skills"
- Understand that gathering context IS a task requiring skill check
- Recognize the cost of skipping skills (failure, wasted time, errors)
