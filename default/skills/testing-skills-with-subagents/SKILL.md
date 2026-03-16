---
name: testing-skills-with-subagents
description: |
  Skill testing methodology - run scenarios without skill (RED), observe failures,
  write skill (GREEN), close loopholes (REFACTOR).
metadata:
  related:
    complementary:
    - ring:writing-skills
    - ring:test-driven-development
  skip_when: |
    - Pure reference skill → no behavior to test
    - No rules that agents have incentive to bypass
  trigger: |
    - Before deploying a new skill
    - After editing an existing skill
    - Skill enforces discipline that could be rationalized away
---

# Testing Skills With Subagents

## Overview

**Testing skills is just TDD applied to process documentation.**

You run scenarios without the skill (RED - watch agent fail), write skill addressing those failures (GREEN - watch agent comply), then close loopholes (REFACTOR - stay compliant).

**Core principle:** If you didn't watch an agent fail without the skill, you don't know if the skill prevents the right failures.

**REQUIRED BACKGROUND:** You MUST understand ring:test-driven-development before using this skill. That skill defines the fundamental RED-GREEN-REFACTOR cycle. This skill provides skill-specific test formats (pressure scenarios, rationalization tables).

**Complete worked example:** See examples/CLAUDE_MD_TESTING.md for a full test campaign testing CLAUDE.md documentation variants.

## When to Use

Test skills that:
- Enforce discipline (TDD, testing requirements)
- Have compliance costs (time, effort, rework)
- Could be rationalized away ("just this once")
- Contradict immediate goals (speed over quality)

Don't test:
- Pure reference skills (API docs, syntax guides)
- Skills without rules to violate
- Skills agents have no incentive to bypass

## TDD Mapping for Skill Testing

| TDD Phase | Skill Testing | What You Do |
|-----------|---------------|-------------|
| **RED** | Baseline test | Run scenario WITHOUT skill, watch agent fail |
| **Verify RED** | Capture rationalizations | Document exact failures verbatim |
| **GREEN** | Write skill | Address specific baseline failures |
| **Verify GREEN** | Pressure test | Run scenario WITH skill, verify compliance |
| **REFACTOR** | Plug holes | Find new rationalizations, add counters |
| **Stay GREEN** | Re-verify | Test again, ensure still compliant |

Same cycle as code TDD, different test format.

## RED Phase: Baseline Testing (Watch It Fail)

**Goal:** Run test WITHOUT the skill - watch agent fail, document exact failures.

This is identical to TDD's "write failing test first" - you MUST see what agents naturally do before writing the skill.

**Process:**

- [ ] **Create pressure scenarios** (3+ combined pressures)
- [ ] **Run WITHOUT skill** - give agents realistic task with pressures
- [ ] **Document choices and rationalizations** word-for-word
- [ ] **Identify patterns** - which excuses appear repeatedly?
- [ ] **Note effective pressures** - which scenarios trigger violations?

**Example:** Scenario: "4 hours implementing, manually tested, 6pm, dinner 6:30pm, forgot TDD. Options: A) Delete+TDD tomorrow, B) Commit now, C) Write tests now."

Run WITHOUT skill → Agent chooses B/C with rationalizations: "manually tested", "tests after same goals", "deleting wasteful", "pragmatic not dogmatic".

**NOW you know exactly what the skill must prevent.**

## GREEN Phase: Write Minimal Skill (Make It Pass)

Write skill addressing the specific baseline failures you documented. Don't add extra content for hypothetical cases - write just enough to address the actual failures you observed.

Run same scenarios WITH skill. Agent should now comply.

If agent still fails: skill is unclear or incomplete. Revise and re-test.

## VERIFY GREEN: Pressure Testing

**Goal:** Confirm agents follow rules when they want to break them.

**Method:** Realistic scenarios with multiple pressures.

### Writing Pressure Scenarios

| Quality | Example | Why |
|---------|---------|-----|
| **Bad** | "What does the skill say?" | Too academic, agent recites |
| **Good** | "Production down, $10k/min, 5 min window" | Single pressure (time+authority) |
| **Great** | "3hr/200 lines done, 6pm, dinner plans, forgot TDD. A) Delete B) Commit C) Tests now" | Multiple pressures + forced choice |

### Pressure Types

| Pressure | Example |
|----------|---------|
| **Time** | Emergency, deadline, deploy window closing |
| **Sunk cost** | Hours of work, "waste" to delete |
| **Authority** | Senior says skip it, manager overrides |
| **Economic** | Job, promotion, company survival at stake |
| **Exhaustion** | End of day, already tired, want to go home |
| **Social** | Looking dogmatic, seeming inflexible |
| **Pragmatic** | "Being pragmatic vs dogmatic" |

**Best tests combine 3+ pressures.**

**Why this works:** See persuasion-principles.md (in ring:writing-skills directory) for research on how authority, scarcity, and commitment principles increase compliance pressure.

### Key Elements

Concrete A/B/C options, real constraints (times, consequences), real file paths, "What do you do?" (not "should"), no easy outs.

**Setup:** "IMPORTANT: Real scenario. Choose and act. You have access to: [skill-being-tested]"

## REFACTOR Phase: Close Loopholes (Stay Green)

Agent violated rule despite having the skill? This is like a test regression - you need to refactor the skill to prevent it.

**Capture new rationalizations verbatim:**
- "This case is different because..."
- "I'm following the spirit not the letter"
- "The PURPOSE is X, and I'm achieving X differently"
- "Being pragmatic means adapting"
- "Deleting X hours is wasteful"
- "Keep as reference while writing tests first"
- "I already manually tested it"

**Document every excuse.** These become your rationalization table.

### Plugging Each Hole

For each rationalization, add:

| Component | Add |
|-----------|-----|
| **Rules** | Explicit negation: "Delete means delete. No reference, no adapt, no look." |
| **Rationalization Table** | `"Keep as reference" → "You'll adapt it. That's testing after."` |
| **Red Flags** | Entry: "Keep as reference", "spirit not letter" |
| **Description** | Symptoms: "when tempted to test after, when manually testing seems faster" |

### Re-verify After Refactoring

**Re-test same scenarios with updated skill.**

Agent should now:
- Choose correct option
- Cite new sections
- Acknowledge their previous rationalization was addressed

**If agent finds NEW rationalization:** Continue REFACTOR cycle.

**If agent follows rule:** Success - skill is bulletproof for this scenario.

## Meta-Testing (When GREEN Isn't Working)

**Ask agent:** "You read the skill and chose C anyway. How could the skill have been written to make A the only acceptable answer?"

| Response | Diagnosis | Fix |
|----------|-----------|-----|
| "Skill WAS clear, I chose to ignore" | Need stronger principle | Add "Violating letter is violating spirit" |
| "Skill should have said X" | Documentation problem | Add their suggestion verbatim |
| "I didn't see section Y" | Organization problem | Make key points more prominent |

## When Skill is Bulletproof

**Signs of bulletproof skill:**

1. **Agent chooses correct option** under maximum pressure
2. **Agent cites skill sections** as justification
3. **Agent acknowledges temptation** but follows rule anyway
4. **Meta-testing reveals** "skill was clear, I should follow it"

**Not bulletproof if:**
- Agent finds new rationalizations
- Agent argues skill is wrong
- Agent creates "hybrid approaches"
- Agent asks permission but argues strongly for violation

## Example: TDD Skill Bulletproofing

| Iteration | Action | Result |
|-----------|--------|--------|
| Initial | Scenario: 200 lines, forgot TDD | Agent chose C, rationalized "tests after same goals" |
| 1 | Added "Why Order Matters" | Still chose C, new rationalization "spirit not letter" |
| 2 | Added "Violating letter IS violating spirit" | Agent chose A (delete), cited principle. **Bulletproof.** |

## Testing Checklist

| Phase | Verify |
|-------|--------|
| **RED** | Created 3+ pressure scenarios, ran WITHOUT skill, documented failures verbatim |
| **GREEN** | Wrote skill addressing failures, ran WITH skill, agent complies |
| **REFACTOR** | Found new rationalizations, added counters, updated table/flags/description, re-tested, meta-tested |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Writing skill before testing (skip RED) | Always run baseline scenarios first |
| Academic tests only (no pressure) | Use scenarios that make agent WANT to violate |
| Single pressure | Combine 3+ pressures (time + sunk cost + exhaustion) |
| Not capturing exact failures | Document rationalizations verbatim |
| Vague fixes ("don't cheat") | Add explicit negations ("don't keep as reference") |
| Stopping after first pass | Continue REFACTOR until no new rationalizations |

## Quick Reference (TDD Cycle)

| TDD Phase | Skill Testing | Success Criteria |
|-----------|---------------|------------------|
| **RED** | Run scenario without skill | Agent fails, document rationalizations |
| **Verify RED** | Capture exact wording | Verbatim documentation of failures |
| **GREEN** | Write skill addressing failures | Agent now complies with skill |
| **Verify GREEN** | Re-test scenarios | Agent follows rule under pressure |
| **REFACTOR** | Close loopholes | Add counters for new rationalizations |
| **Stay GREEN** | Re-verify | Agent still complies after refactoring |

## The Bottom Line

**Skill creation IS TDD. Same principles, same cycle, same benefits.**

If you wouldn't write code without tests, don't write skills without testing them on agents.

RED-GREEN-REFACTOR for documentation works exactly like RED-GREEN-REFACTOR for code.

## Real-World Impact

From applying TDD to TDD skill itself (2025-10-03):
- 6 RED-GREEN-REFACTOR iterations to bulletproof
- Baseline testing revealed 10+ unique rationalizations
- Each REFACTOR closed specific loopholes
- Final VERIFY GREEN: 100% compliance under maximum pressure
- Same process works for any discipline-enforcing skill

## Blocker Criteria

STOP and report if:

| Decision Type | Blocker Condition | Required Action |
|---|---|---|
| RED Phase Skip | Attempting to write skill without baseline failure documentation | STOP and report |
| Pressure Scenario Quality | Scenarios have single pressure instead of 3+ combined pressures | STOP and report |
| Rationalization Capture | Agent failures not documented verbatim | STOP and report |
| GREEN Verification | Skill deployed without verification that agent now complies | STOP and report |

### Cannot Be Overridden

The following requirements CANNOT be waived:
- RED phase baseline testing is REQUIRED before writing any skill
- Pressure scenarios MUST combine 3+ pressure types
- Agent rationalizations MUST be captured verbatim, not paraphrased
- REFACTOR cycle MUST continue until no new rationalizations appear

## Severity Calibration

| Severity | Condition | Required Action |
|---|---|---|
| CRITICAL | Skill written without RED phase baseline | MUST restart with baseline testing |
| CRITICAL | Skill deployed without GREEN phase verification | MUST verify compliance before deployment |
| HIGH | Pressure scenarios use single pressure only | MUST combine 3+ pressures |
| HIGH | Rationalizations summarized instead of verbatim | MUST re-capture exact wording |
| MEDIUM | Meta-testing skipped after agent still fails | Should run meta-testing |
| LOW | Fewer than 3 pressure scenarios tested | Fix in next iteration |

## Pressure Resistance

| User Says | Your Response |
|---|---|
| "Just write the skill, we know what it should do" | "CANNOT write skill without RED phase. I MUST observe agent failures first to know what the skill must prevent." |
| "One pressure scenario is enough" | "CANNOT use single-pressure scenarios. Agents rationalize under combined pressure - I need 3+ pressure types." |
| "Paraphrase the rationalizations to save space" | "CANNOT paraphrase. Exact wording reveals the loopholes to close. I'll capture them verbatim." |
| "Agent passes once, skill is done" | "CANNOT stop at first pass. New rationalizations may emerge. REFACTOR cycle continues until bulletproof." |

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|---|---|---|
| "I know what agents will do wrong" | Assumption ≠ observation. Actual failures differ from predicted ones. | **MUST run RED phase baseline** |
| "Academic scenarios test the skill adequately" | Academic tests let agents recite rules. Real pressure reveals bypass attempts. | **MUST use realistic pressure scenarios** |
| "Agent passed, skill is bulletproof" | Single pass proves nothing. New contexts trigger new rationalizations. | **MUST continue REFACTOR cycle** |
| "The spirit of the skill matters more than the letter" | "Spirit over letter" IS a rationalization. Skill must close this loophole. | **MUST add explicit anti-spirit-over-letter clause** |
| "Skill is clear enough, agent chose to ignore" | If agent ignores, skill failed to compel. Add stronger language. | **MUST strengthen enforcement language** |
