---
name: systematic-debugging
description: Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes - four-phase framework (root cause investigation, pattern analysis, hypothesis testing, implementation) that ensures understanding before attempting solutions
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

**MUST complete ALL before Phase 2:**

```
Phase 1 Investigation:
□ Error message copied verbatim: ___________
□ Reproduction confirmed: [steps documented]
□ Recent changes reviewed: [git diff output]
□ Evidence from ALL components: [list components checked]
□ Data flow traced: [origin → error location]
```

**Copy this checklist to TodoWrite.**

1. **Read Error Messages**
   - Stack traces completely
   - Line numbers, file paths, error codes
   - Don't skip past warnings

2. **Reproduce Consistently**
   - Exact steps to trigger
   - Happens every time? If not → gather more data

3. **Check Recent Changes**
   - `git diff`, recent commits
   - New dependencies, config changes

4. **Multi-Component Systems**

   **Add diagnostic instrumentation at EACH boundary:**
   ```bash
   # For each layer, log:
   - What enters component
   - What exits component
   - Environment/config state
   ```

   Run once, analyze evidence, identify failing layer.

5. **Trace Data Flow**

   Error deep in stack? **Use ring:root-cause-tracing skill.**

   Quick version:
   - Where does bad value originate?
   - Trace up call stack to source
   - Fix at source, not symptom

**Phase 1 Summary (write before Phase 2):**
```
FINDINGS:
- Error: [exact error]
- Reproduces: [steps]
- Recent changes: [commits]
- Component evidence: [what each shows]
- Data origin: [where bad data starts]
```

### Phase 2: Pattern Analysis

1. **Find Working Examples**
   - Similar working code in codebase
   - What works that's similar to what's broken?

2. **Compare Against References**
   - Read reference implementation COMPLETELY
   - Don't skim - understand fully

3. **Identify Differences**
   - List EVERY difference (working vs broken)
   - Don't assume "that can't matter"

4. **Understand Dependencies**
   - What components, config, environment needed?
   - What assumptions does it make?

### Phase 3: Hypothesis Testing

1. **Form Single Hypothesis**
   - "I think X is root cause because Y"
   - Be specific

2. **Test Minimally**
   - SMALLEST possible change
   - One variable at a time

3. **Verify and Track**
   ```
   Hypothesis #1: [what] → [result]
   Hypothesis #2: [what] → [result]
   Hypothesis #3: [what] → [STOP if fails]
   ```

   **If 3 hypotheses fail:**
   - STOP immediately
   - "3 hypotheses failed, architecture review required"
   - Discuss with partner before more attempts

4. **When You Don't Know**
   - Say "I don't understand X"
   - Ask for help
   - Research more

### Phase 4: Implementation

**Fix root cause, not symptom:**

1. **Create Failing Test**
   - Simplest reproduction
   - **Use ring:test-driven-development skill**

2. **Implement Single Fix**
   - Address root cause only
   - ONE change at a time
   - No "while I'm here" improvements

3. **Verify Fix**
   - Test passes?
   - No other tests broken?
   - Issue resolved?

4. **If Fix Doesn't Work**
   - Count fixes attempted
   - If < 3: Return to Phase 1
   - **If ≥ 3: STOP → Architecture review required**

5. **If 3+ Fixes Failed: Question Architecture**

   Pattern indicating architectural problem:
   - Each fix reveals new problem elsewhere
   - Fixes require massive refactoring
   - Each fix creates new symptoms

   **STOP and discuss:** Is architecture sound? Should we refactor vs. fix?

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
- **test-driven-development** - For failing test case (Phase 4, Step 1)

**Complementary:**
- **defense-in-depth** - Add validation after finding root cause
- **verification-before-completion** - Verify fix worked before claiming success

## Required Patterns

This skill uses these universal patterns:
- **State Tracking:** See `skills/shared-patterns/state-tracking.md`
- **Failure Recovery:** See `skills/shared-patterns/failure-recovery.md`
- **Exit Criteria:** See `skills/shared-patterns/exit-criteria.md`
- **TodoWrite:** See `skills/shared-patterns/todowrite-integration.md`

Apply ALL patterns when using this skill.
