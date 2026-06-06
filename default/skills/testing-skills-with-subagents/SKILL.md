---
name: ring:testing-skills-with-subagents
description: "Hardening a skill so it resists rationalization under pressure: run combined-pressure scenarios on a subagent without the skill (RED), capture excuses verbatim, write/edit the skill (GREEN), then plug loopholes (REFACTOR) until compliance holds. Use when deploying or editing a discipline-enforcing skill that an agent could rationalize away. Skip for pure reference skills with no rules to violate."
---

# Testing Skills With Subagents

## When to use
- Before deploying a new skill
- After editing an existing skill
- Skill enforces discipline that could be rationalized away

## Skip when
- Pure reference skill → no behavior to test
- No rules that agents have incentive to bypass

## Related
**Complementary:** ring:writing-skills, ring:test-driven-development

**Testing skills is TDD applied to process documentation.**

Run scenarios without the skill (RED — watch agent fail), write skill addressing those failures (GREEN), then close loopholes (REFACTOR).

**Prerequisite:** Understand `ring:test-driven-development` first. Complete worked example: `examples/CLAUDE_MD_TESTING.md`.

## When to Test

Test skills that: enforce discipline (TDD, testing requirements), have compliance costs (time, effort, rework), could be rationalized away ("just this once"), or contradict immediate goals (speed over quality).

**Skip:** Pure reference skills (API docs), skills without rules to violate.

## TDD Mapping

| TDD Phase | Skill Testing | What You Do |
|-----------|---------------|-------------|
| RED | Baseline test | Run scenario WITHOUT skill, watch agent fail |
| Verify RED | Capture rationalizations | Document exact failures verbatim |
| GREEN | Write skill | Address specific baseline failures |
| Verify GREEN | Pressure test | Run WITH skill, verify compliance under pressure |
| REFACTOR | Plug holes | Find new rationalizations, add counters |

## RED Phase: Watch It Fail

Run 3+ combined-pressure scenarios WITHOUT the skill. Document agent choices and rationalizations **word-for-word**.

**Why verbatim?** Exact wording reveals the loopholes to close.

### Writing Pressure Scenarios

| Quality | Example |
|---------|---------|
| Bad | "What does the skill say?" — agent recites |
| Good | "Production down, $10k/min, 5min window" — single pressure |
| Great | "3hr/200 lines done, 6pm, dinner plans, forgot TDD. A) Delete B) Commit C) Tests now" — multi-pressure + forced choice |

**Pressure types:** Time (deadline), sunk cost (hours invested), authority (senior says skip), economic (job at stake), exhaustion (end of day), pragmatic ("being realistic").

**Best tests combine 3+ pressures.**

## GREEN Phase: Write Minimal Skill

Address the specific failures documented in RED. Don't add hypothetical content — write just enough to address actual observed failures. Re-run same scenarios WITH skill; agent should now comply.

## REFACTOR Phase: Close Loopholes

Agent still violated rule despite having the skill? Capture new rationalizations verbatim:
- "This case is different because..."
- "I'm following the spirit not the letter"
- "Being pragmatic means adapting"

For each rationalization, add: explicit negation rule, rationalization table entry, red flag entry.

**Meta-test:** "You read the skill and chose wrong anyway. How could the skill have been written to make the right answer the only acceptable one?"

**Continue REFACTOR until no new rationalizations appear.**

## Signs of Bulletproof Skill

- Agent chooses correct option under maximum pressure
- Agent cites skill sections as justification
- Agent acknowledges temptation but follows rule anyway
- Meta-test reveals "skill was clear, I should follow it"

## Real-World Impact

From applying TDD to TDD skill itself:
- 6 RED-GREEN-REFACTOR iterations to bulletproof
- 10+ unique rationalizations discovered
- Each REFACTOR closed specific loopholes
- Final: 100% compliance under maximum pressure
