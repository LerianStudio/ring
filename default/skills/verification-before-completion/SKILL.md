---
name: verification-before-completion
description: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always
when_to_use: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always
---

# Verification Before Completion

## Overview

Claiming work is complete without verification is dishonesty, not efficiency.

**Core principle:** Evidence before claims, always.

**Violating the letter of this rule is violating the spirit of this rule.**

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you haven't run the verification command in this message, you cannot claim it passes.

## The Gate Function

```
BEFORE claiming any status or expressing satisfaction:

1. IDENTIFY: What command proves this claim?
2. RUN: Execute the FULL command (fresh, complete)
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
5. ONLY THEN: Make the claim

Skip any step = lying, not verifying
```

## The Command-First Rule

**EVERY completion message structure:**

1. FIRST: Run verification command
2. SECOND: Paste complete output
3. THIRD: State what output proves
4. ONLY THEN: Make your claim

**Example structure:**
```
Let me verify the implementation:

$ npm test
[PASTE FULL OUTPUT]

The tests show 15/15 passing. Implementation is complete.
```

**Wrong structure (violation):**
```
Implementation is complete! Let me verify:
[This is backwards - claimed before verifying]
```

## Common Failures

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Tests pass | Test command output: 0 failures | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Build succeeds | Build command: exit 0 | Linter passing, logs look good |
| Bug fixed | Test original symptom: passes | Code changed, assumed fixed |
| Regression test works | Red-green cycle verified | Test passes once |
| Agent completed | VCS diff shows changes | Agent reports "success" |
| Requirements met | Line-by-line checklist | Tests passing |

## Red Flags - STOP

- Using "should", "probably", "seems to"
- Expressing satisfaction before verification ("Great!", "Perfect!", "Done!", etc.)
- About to commit/push/PR without verification
- Trusting agent success reports
- Relying on partial verification
- Thinking "just this once"
- Tired and wanting work over
- **ANY wording implying success without having run verification**

## Banned Phrases (Automatic Violation)

**NEVER use these without evidence:**
- "appears to" / "seems to" / "looks like"
- "should be working" / "is now working"
- "implementation complete" (without test output)
- "successfully" (without command output)
- "properly" / "correctly" (without verification)
- "all good" / "works great" (without evidence)
- ANY positive adjective before verification

**Using these = lying, not verifying**

## The False Positive Trap

**About to say "all tests pass"?**

Check:
- Did you run tests THIS message? (Not last message)
- Did you paste the output? (Not just claim)
- Does output show 0 failures? (Not assumed)

**No to any = you're lying**

"I ran them earlier" = NOT verification
"They should pass now" = NOT verification
"The previous output showed" = NOT verification

**Run. Paste. Then claim.**

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification |
| "I'm confident" | Confidence ≠ evidence |
| "Just this once" | No exceptions |
| "Linter passed" | Linter ≠ compiler |
| "Agent said success" | Verify independently |
| "I'm tired" | Exhaustion ≠ excuse |
| "Partial check is enough" | Partial proves nothing |
| "Different words so rule doesn't apply" | Spirit over letter |

## Key Patterns

**Tests:**
```
✅ [Run test command] [See: 34/34 pass] "All tests pass"
❌ "Should pass now" / "Looks correct"
```

**Regression tests (TDD Red-Green):**
```
✅ Write → Run (pass) → Revert fix → Run (MUST FAIL) → Restore → Run (pass)
❌ "I've written a regression test" (without red-green verification)
```

**Build:**
```
✅ [Run build] [See: exit 0] "Build passes"
❌ "Linter passed" (linter doesn't check compilation)
```

**Requirements:**
```
✅ Re-read plan → Create checklist → Verify each → Report gaps or completion
❌ "Tests pass, phase complete"
```

**Agent delegation:**
```
✅ Agent reports success → Check VCS diff → Verify changes → Report actual state
❌ Trust agent report
```

## Required Patterns

This skill uses these universal patterns:
- **State Tracking:** See `skills/shared-patterns/state-tracking.md`
- **Failure Recovery:** See `skills/shared-patterns/failure-recovery.md`
- **Exit Criteria:** See `skills/shared-patterns/exit-criteria.md`
- **TodoWrite:** See `skills/shared-patterns/todowrite-integration.md`

Apply ALL patterns when using this skill.

---

## When You Violate This Skill

### Violation: Claimed complete without running verification

**How to detect:**
- Said "implementation is complete"
- No command output shown
- Used words like "should work" or "appears correct"

**Recovery procedure:**
1. Don't mark task complete yet
2. Run actual verification commands
3. Paste complete output
4. Only then claim completion

**Why recovery matters:**
Claims without evidence create false confidence. Silent failures go undetected until production.

---

### Violation: Ran command but didn't paste output

**How to detect:**
- Mentioned running tests/build
- No output shown in response
- Said "tests passed" without proof

**Recovery procedure:**
1. Re-run the command
2. Copy FULL output
3. Paste output in response
4. Then make completion claim

**Why recovery matters:**
"I ran tests and they passed" is a claim, not evidence. Paste the output to prove it.

---

### Violation: Used banned phrases before verification

**How to detect:**
- Said "appears to work" / "should be fixed" / "looks correct"
- Expressed satisfaction: "Great!", "Perfect!", "Done!"
- Implied success without evidence

**Recovery procedure:**
1. Recognize the violation immediately
2. Stop and run verification
3. Paste complete output
4. Replace banned phrase with evidence-based claim

**Why recovery matters:**
Banned phrases are cognitive shortcuts that bypass verification. They signal you're claiming success without proof, which is lying to your partner.

---

## Why This Matters

From 24 failure memories:
- your human partner said "I don't believe you" - trust broken
- Undefined functions shipped - would crash
- Missing requirements shipped - incomplete features
- Time wasted on false completion → redirect → rework
- Violates: "Honesty is a core value. If you lie, you'll be replaced."

## When To Apply

**ALWAYS before:**
- ANY variation of success/completion claims
- ANY expression of satisfaction
- ANY positive statement about work state
- Committing, PR creation, task completion
- Moving to next task
- Delegating to agents

**Rule applies to:**
- Exact phrases
- Paraphrases and synonyms
- Implications of success
- ANY communication suggesting completion/correctness

## The Bottom Line

**No shortcuts for verification.**

Run the command. Read the output. THEN claim the result.

This is non-negotiable.
