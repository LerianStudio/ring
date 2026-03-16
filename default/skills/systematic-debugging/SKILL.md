---
name: systematic-debugging
description: |
  Four-phase debugging framework - root cause investigation, pattern analysis,
  hypothesis testing, implementation. Ensures understanding before attempting fixes.
metadata:
  related:
    complementary:
    - root-cause-tracing
  skip_when: |
    - Root cause already known → just fix it
    - Error deep in call stack, need to trace backward → use root-cause-tracing
    - Issue obviously caused by your last change → quick verification first
  trigger: |
    - Bug reported or test failure observed
    - Unexpected behavior or error message
    - Root cause unknown
    - Previous fix attempt didn't work
---

# Systematic Debugging

**Core principle:** NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST.

## When to Use

Use for ANY technical issue: test failures, bugs, unexpected behavior, performance problems, build failures, integration issues.

**Especially when:**
- Under time pressure (emergencies make guessing tempting)
- "Just one quick fix" seems obvious
- Previous fix didn't work
- You don't fully understand the issue

## The Four Phases

Complete each phase before proceeding to the next.

### Phase 1: Root Cause Investigation

**MUST complete ALL before Phase 2 (copy to TodoWrite):**
□ Error message copied verbatim | □ Reproduction confirmed | □ Recent changes reviewed (`git diff`) | □ Evidence from ALL components | □ Data flow traced (origin → error)

1. **Read Error Messages** - Stack traces completely, line numbers, file paths, error codes. Don't skip warnings.
2. **Reproduce Consistently** - Exact steps to trigger. Intermittent → gather more data.
3. **Check Recent Changes** - `git diff`, recent commits, new dependencies, config changes.
4. **Multi-Component Systems** - Log at each boundary: what enters, what exits, env/config state. Run once, analyze, identify failing layer.
5. **Trace Data Flow** - Error deep in stack? **Use root-cause-tracing skill.** Quick: Where does bad value originate? Trace up call stack, fix at source not symptom.

**Phase 1 Summary:** Error: [exact] | Reproduces: [steps] | Recent changes: [commits] | Component evidence: [each] | Data origin: [source]

### Phase 2: Pattern Analysis

1. **Find Working Examples** - Similar working code in codebase. What works that's similar to what's broken?
2. **Compare Against References** - Read reference implementation COMPLETELY. Don't skim - understand fully.
3. **Identify Differences** - List EVERY difference (working vs broken). Don't assume "that can't matter."
4. **Understand Dependencies** - What components, config, environment needed? What assumptions does it make?

### Phase 3: Hypothesis Testing

1. **Form Single Hypothesis** - "I think X is root cause because Y" - Be specific.
2. **Test Minimally** - SMALLEST possible change. One variable at a time.
3. **Verify and Track** - `H#1: [what] → [result] | H#2: [what] → [result] | H#3: [what] → [STOP if fails]`
   **If 3 hypotheses fail:** STOP immediately → "3 hypotheses failed, architecture review required" → Discuss with partner before more attempts.
4. **When You Don't Know** - Say "I don't understand X." Ask for help. Research more.

### Phase 4: Implementation

**Fix root cause, not symptom:**

1. **Create Failing Test** - Simplest reproduction. **Use ring:test-driven-development skill.**
2. **Implement Single Fix** - Address root cause only. ONE change at a time. No "while I'm here" improvements.
3. **Verify Fix** - Test passes? No other tests broken? Issue resolved?
4. **If Fix Doesn't Work** - Count fixes. If < 3: Return to Phase 1. **If ≥ 3: STOP → Architecture review required.**
5. **After Fix Verified** - Test passes and issue resolved? Move to post-completion review.
6. **If 3+ Fixes Failed** - Pattern: each fix reveals new problem elsewhere, requires massive refactoring, creates new symptoms. **STOP and discuss:** Is architecture sound? Should we refactor vs. fix?

## Time Limits

**Debugging time boxes:**
- 30 min without root cause → Escalate
- 3 failed fixes → Architecture review
- 1 hour total → Stop, document, ask for guidance

## Red Flags

**STOP and return to Phase 1 if thinking:**
- "Quick fix for now, investigate later"
- "Just try changing X and see if it works"
- "Add multiple changes, run tests"
- "Skip the test, I'll manually verify"
- "It's probably X, let me fix that"
- "I don't fully understand but this might work"
- "One more fix attempt" (when already tried 2+)
- "Each fix reveals new problem" (architecture issue)

**User signals you're wrong:**
- "Is that not happening?" → You assumed without verifying
- "Stop guessing" → You're proposing fixes without understanding
- "We're stuck?" → Your approach isn't working

**When you see these: STOP. Return to Phase 1.**

## Quick Reference

| Phase | Key Activities | Success Criteria |
|-------|---------------|------------------|
| **1. Root Cause** | Read errors, reproduce, check changes, gather evidence, trace data flow | Understand WHAT and WHY |
| **2. Pattern** | Find working examples, compare differences, understand dependencies | Identify what's different |
| **3. Hypothesis** | Form theory, test minimally, verify one at a time | Confirmed or new hypothesis |
| **4. Implementation** | Create test, fix root cause, verify | Bug resolved, tests pass |

**Circuit breakers:**
- 3 hypotheses fail → STOP, architecture review
- 3 fixes fail → STOP, question fundamentals
- 30 min no root cause → Escalate

## Integration with Other Skills

**Required sub-skills:**
- **root-cause-tracing** - When error is deep in call stack (Phase 1, Step 5)
- **ring:test-driven-development** - For failing test case (Phase 4, Step 1)

**Complementary:**
- **defense-in-depth** - Add validation after finding root cause
- **verification-before-completion** - Verify fix worked before claiming success

## Blocker Criteria

STOP and report if:

| Decision Type | Blocker Condition | Required Action |
|---|---|---|
| Cannot reproduce issue | Bug is intermittent and no consistent reproduction steps | STOP and gather more data before proceeding |
| 3 hypotheses failed | Three consecutive hypotheses tested and all failed | STOP and escalate for architecture review |
| 3 fixes failed | Three fix attempts made but issue persists | STOP and question fundamental assumptions |
| 30 minutes without root cause | Extended investigation without identifying root cause | STOP and escalate for help |
| Fix reveals new problem | Each attempted fix creates different symptoms | STOP and request architecture review |

### Cannot Be Overridden

The following requirements CANNOT be waived:
- MUST complete Phase 1 (Root Cause Investigation) before any code changes
- MUST form evidence-based hypothesis before attempting fixes
- CANNOT skip creating a failing test in Phase 4
- MUST stop and escalate after 3 failed hypotheses or fixes
- CANNOT claim fix is complete without fresh verification

## Severity Calibration

| Severity | Condition | Required Action |
|---|---|---|
| CRITICAL | Production system affected | MUST prioritize and escalate immediately |
| CRITICAL | Data corruption or loss risk | MUST stop other work and focus exclusively |
| HIGH | User-facing functionality broken | MUST investigate before other tasks |
| HIGH | Tests failing on main branch | MUST resolve before merging new code |
| MEDIUM | Non-critical feature affected | Should investigate within current session |
| LOW | Minor behavior deviation | Fix in next iteration if time permits |

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Quick fix for now, investigate later" | Later never comes. Quick fixes mask root causes. | **MUST complete Phase 1 before any code change** |
| "Just try changing X and see" | Guessing wastes time and introduces new bugs | **MUST form hypothesis with evidence first** |
| "I'm confident this is the issue" | Confidence without evidence is guessing | **MUST verify with reproduction steps** |
| "One more fix attempt" (after 2+) | Pattern indicates architecture issue, not bug | **STOP and escalate for architecture review** |
| "Each fix reveals new problem" | Symptom of deeper structural issue | **STOP: architecture review REQUIRED** |
| "I don't fully understand but this might work" | Partial understanding = partial fix = new bugs | **MUST understand root cause before fixing** |
| "Skip the test, I'll manually verify" | Manual verification is unreliable and non-repeatable | **MUST create failing test (Phase 4, Step 1)** |
| "Previous run showed it works" | Stale evidence is not evidence | **MUST re-verify with fresh execution** |

## Pressure Resistance

| User Says | Your Response |
|-----------|---------------|
| "Just fix it quickly, we don't have time" | "MUST follow the phases - skipping investigation causes more delays through repeated fixes" |
| "Try this change, I think it'll work" | "I'll add that as a hypothesis and test it properly in Phase 3" |
| "We've tried 5 fixes, try one more" | "CANNOT proceed - 3+ failed fixes requires architecture review before more attempts" |
| "Skip the investigation, the cause is obvious" | "MUST verify the obvious before acting - obvious causes are often wrong" |

## Required Patterns

This skill uses these universal patterns:
- **State Tracking:** See `skills/shared-patterns/state-tracking.md`
- **Failure Recovery:** See `skills/shared-patterns/failure-recovery.md`
- **Exit Criteria:** See `skills/shared-patterns/exit-criteria.md`
- **TodoWrite:** See `skills/shared-patterns/todowrite-integration.md`

Apply ALL patterns when using this skill.
