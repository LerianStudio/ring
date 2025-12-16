---
name: verification-before-completion
description: |
  Evidence-first completion gate - requires running verification commands and
  confirming output before making any success claims.

trigger: |
  - About to claim "work is complete"
  - About to claim "tests pass"
  - About to claim "bug is fixed"
  - Before committing or creating PRs

skip_when: |
  - Just ran verification command with passing output → proceed
  - Still in development (not claiming completion) → continue working

sequence:
  before: [finishing-a-development-branch, requesting-code-review]
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

| Type | ✅ CORRECT | ❌ WRONG |
|------|-----------|---------|
| Tests | Run command, see "34/34 pass", then claim | "Should pass now" |
| Regression (TDD) | Write → pass → revert → MUST FAIL → restore → pass | "Written regression test" (no red-green) |
| Build | Run build, see exit 0, then claim | "Linter passed" (linter ≠ compiler) |
| Requirements | Re-read plan → checklist → verify each | "Tests pass, phase complete" |
| Agent delegation | Check VCS diff → verify changes | Trust agent report |

## Required Patterns

This skill uses these universal patterns:
- **State Tracking:** See `skills/shared-patterns/state-tracking.md`
- **Failure Recovery:** See `skills/shared-patterns/failure-recovery.md`
- **Exit Criteria:** See `skills/shared-patterns/exit-criteria.md`
- **TodoWrite:** See `skills/shared-patterns/todowrite-integration.md`

Apply ALL patterns when using this skill.

---

## Violation Recovery

| Violation | Detection | Recovery |
|-----------|-----------|----------|
| Claimed complete without verification | "complete" with no command output, "should work" | Run verification → paste output → then claim |
| Ran command but didn't paste | Mentioned running tests, no output shown | Re-run → copy FULL output → paste → then claim |
| Used banned phrases | "appears to work", "Great!", "Done!" before evidence | Stop → run verification → paste output → evidence-based claim |

**Why recovery matters:** Claims without evidence = false confidence. Silent failures go undetected until production.

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
