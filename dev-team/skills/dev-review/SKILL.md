---
name: dev-review
description: |
  Development cycle review gate (Gate 4) - executes parallel code review with 3 specialized
  reviewers, aggregates findings, and determines VERDICT for gate passage.

trigger: |
  - After testing gate complete (Gate 3)
  - Implementation ready for review
  - Before validation gate

skip_when: |
  - Tests not passing -> complete Gate 3 first
  - Already reviewed with no changes since -> proceed to validation

NOT_skip_when: |
  - "Trivial change" → Security issues fit in 1 line. ALL changes require review. No exceptions.
  - "Only N lines" → Line count is irrelevant. AI doesn't negotiate. Review ALL changes.

sequence:
  after: [ring-dev-team:dev-testing]
  before: [ring-dev-team:dev-validation]

related:
  complementary: [ring-default:requesting-code-review, ring-default:receiving-code-review]

verification:
  automated:
    - command: "cat .ring/dev-team/current-cycle.json | jq '.gates[4].code_reviewer.verdict'"
      description: "Code reviewer verdict captured"
      success_pattern: "PASS|FAIL|NEEDS_DISCUSSION"
    - command: "cat .ring/dev-team/current-cycle.json | jq '.gates[4].aggregate_verdict'"
      description: "Aggregate verdict determined"
      success_pattern: "PASS|FAIL"
  manual:
    - "All 3 reviewers dispatched in parallel (single message with 3 Task calls)"
    - "Critical/High issues addressed before PASS verdict"
    - "Review findings documented with file:line references"

examples:
  - name: "Clean review pass"
    context: "Implementation with no security issues"
    expected_flow: |
      1. Dispatch 3 reviewers in parallel
      2. Code reviewer: PASS (2 Low)
      3. Business logic reviewer: PASS (0 issues)
      4. Security reviewer: PASS (0 issues)
      5. Aggregate VERDICT: PASS
      6. Proceed to Gate 5
  - name: "Review with critical finding"
    context: "SQL injection vulnerability found"
    expected_flow: |
      1. Dispatch 3 reviewers in parallel
      2. Security reviewer: FAIL (1 Critical)
      3. Aggregate VERDICT: FAIL
      4. Return to Gate 0 for fixes
      5. Re-run review after fix
---

# Dev Review (Gate 4)

## Overview

See [CLAUDE.md](./CLAUDE.md) and [ring-default:requesting-code-review](./default/skills/requesting-code-review/SKILL.md) for canonical review requirements. This skill orchestrates Gate 4 execution.

Execute comprehensive code review using 3 specialized reviewers IN PARALLEL. Aggregate findings and determine VERDICT for gate passage.

**Core principle:** Three perspectives catch more bugs than one. Parallel execution = 3x faster feedback.

## Pressure Resistance

**Gate 4 (Review) requires ALL 3 reviewers in parallel. Pressure scenarios and required responses:**

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| **One Reviewer** | "One reviewer is enough" | "3 reviewers catch different issues. Code=architecture, Business=logic, Security=vulnerabilities. All required." |
| **Cosmetic Only** | "Only cosmetic issues, skip fixes" | "Cosmetic issues affect maintainability. Fix or document with FIXME. No silent ignoring." |
| **Skip Re-review** | "Passed first time, skip re-review" | "After ANY fix, re-run ALL 3 reviewers. Fixes can introduce new issues." |
| **Time** | "Review takes too long" | "3 parallel reviewers = 10 min total. Sequential = 30 min. Parallel is faster." |
| **Authority Override** | "Manager/VP approved skip" | "Management approval ≠ technical review. HARD GATES cannot be waived by authority. Running all 3 reviewers." |
| **Emergency** | "Production down, skip review" | "Emergencies need review MORE, not less. Parallel review = 10 minutes. Deploying unreviewed code creates bigger emergencies." |

### Combined Pressure Scenarios (MOST DANGEROUS)

| Scenario | Agent Response |
|----------|----------------|
| "CEO watching + 11 PM + 2-line fix + already tested" | "Gate 4 is NON-NEGOTIABLE. Parallel review takes 10 minutes. Running all 3 reviewers now." |
| "VP approved + emergency + only CSS + sprint ends today" | "I cannot override HARD GATES regardless of authority or urgency. Dispatching 3 reviewers in parallel." |
| "First reviewer passed + exhausted + small fix + senior dev approved" | "ALL 3 reviewers REQUIRED in parallel. One PASS ≠ complete review. Dispatching remaining 2 now." |
| "Production down + $10K/min loss + 2-line obvious fix" | "Emergencies need review MORE, not less. Parallel review = 10 minutes. Deploying unreviewed code creates bigger emergencies." |

**Non-negotiable principle:** ALL 3 reviewers MUST run in a SINGLE message with 3 Task tool calls. Sequential = violation.

## Staged Parallel Execution - FORBIDDEN

**FORBIDDEN Pattern:** Dispatching reviewers in stages (e.g., code reviewer first, then others based on result)

**Why This Is Wrong:**
- Delays full feedback picture - all perspectives needed simultaneously
- Creates false dependency (code review "must pass" before security review)
- Wastes time - if security finds blocker, code review was pointless
- Violates parallel execution requirement

**Examples of FORBIDDEN Staged Patterns:**
```markdown
❌ WRONG: Stage 1 - Code Reviewer First
1. Dispatch: ring-default:code-reviewer
2. Wait for result
3. If PASS → Dispatch: business-logic-reviewer + security-reviewer
4. If FAIL → Return to Gate 0

❌ WRONG: Stage 1 - Code + Business, Stage 2 - Security
1. Dispatch: code-reviewer + business-logic-reviewer (2 agents)
2. Wait for results
3. If both PASS → Dispatch: security-reviewer
4. Aggregate

✅ CORRECT: All 3 in ONE Message
1. Dispatch ALL 3 in single message:
   - Task(ring-default:code-reviewer)
   - Task(ring-default:business-logic-reviewer)
   - Task(ring-default:security-reviewer)
2. Wait for all results
3. Aggregate findings
```

**Detection:**
- If you see "wait for result" before dispatching remaining reviewers → STAGED (forbidden)
- If dispatch count < 3 in initial message → STAGED (forbidden)
- If "based on first reviewer result" logic exists → STAGED (forbidden)

**Required Pattern:** ALL 3 Task calls in ONE message = TRUE parallel execution

## Re-Review After Fixes - Clarification

**When Re-Review Is REQUIRED:**
- ✅ After fixing ANY Critical issue → Re-run ALL 3 reviewers
- ✅ After fixing ANY High issue → Re-run ALL 3 reviewers
- ✅ After fixing ANY Medium issue → Re-run ALL 3 reviewers

**When Re-Review May Be Optional (Context-Dependent):**
- ⚠️ After fixing ONLY Low issues → Depends on change scope
  - **If Low fix touches <5 lines in 1 file:** May skip re-review if Senior Dev approves
  - **If Low fix touches multiple files/areas:** Re-run ALL 3 reviewers (ripple effect risk)
  - **If unsure:** Default to re-running ALL 3 reviewers (safer)

**NEVER Skip Re-Review For:**
- Critical fixes (ALWAYS re-review)
- High fixes (ALWAYS re-review)
- Medium fixes (ALWAYS re-review)
- Low fixes touching >5 lines or >1 file
- Low fixes you're unsure about

**Default Rule:** When in doubt, re-run ALL 3 reviewers. Better safe than sorry.

## NEEDS_DISCUSSION Verdict Handling

**NEEDS_DISCUSSION Verdict:** Reviewer is uncertain, requires human decision

**When Reviewers Return NEEDS_DISCUSSION:**
1. **Identify the question:** What is the reviewer uncertain about?
2. **Present to user:** Show reviewer's question/concern with options
3. **User decides:** User provides guidance or makes architectural decision
4. **Re-run reviewer:** After user decision, re-run that reviewer with clarification
5. **If still NEEDS_DISCUSSION:** Escalate to senior engineer or architect

**Examples:**
- Reviewer: "NEEDS_DISCUSSION: Should we use pessimistic or optimistic locking?"
  - → Ask user, they decide, re-run reviewer with decision
- Reviewer: "NEEDS_DISCUSSION: Error handling approach A vs B - both valid"
  - → Ask user for preference, re-run with choice
- Reviewer: "NEEDS_DISCUSSION: Performance vs readability tradeoff"
  - → User makes call based on requirements

**Aggregate Verdict When NEEDS_DISCUSSION Exists:**
- 1+ reviewers return NEEDS_DISCUSSION → Overall VERDICT: NEEDS_DISCUSSION
- Cannot proceed to Gate 5 until all reviewers return PASS or FAIL
- User must resolve all NEEDS_DISCUSSION items

**Do NOT:**
- ❌ Treat NEEDS_DISCUSSION as PASS (it's not - it's blocked)
- ❌ Make the decision yourself (reviewer is asking USER, not orchestrator)
- ❌ Skip that reviewer (must re-run after user decides)
- ❌ Aggregate as FAIL (it's uncertainty, not failure)

## Common Rationalizations - REJECTED

| Excuse | Reality |
|--------|---------|
| "Trivial change, skip review" | Security vulnerabilities fit in 1 line. ALL changes require ALL 3 reviewers. |
| "Only N lines changed" | Line count is irrelevant. SQL injection is 1 line. Review ALL changes. |
| "Code reviewer covers security" | Code reviewer checks architecture. Security reviewer checks OWASP. Different expertise. |
| "Only found LOW issues" | LOW issues accumulate into technical debt. Document in TODO or fix. |
| "Small fix, no re-review needed" | Small fixes can have big impacts. Re-run ALL reviewers after ANY change. |
| "One reviewer said PASS" | PASS requires ALL 3 reviewers. One PASS + one FAIL = overall FAIL. |
| "Business logic is tested" | Tests check behavior. Review checks intent, edge cases, requirements alignment. |
| "Security scan passed" | Security scanners miss logic flaws. Human reviewer required. |
| "Run code reviewer first, then others" | Staged execution is FORBIDDEN. All 3 in ONE message (parallel). |
| "Use general-purpose instead of code-reviewer" | Generic agents lack specialized review expertise. Only ring-default reviewers allowed. |
| "NEEDS_DISCUSSION is basically PASS" | NO. NEEDS_DISCUSSION = blocked until user decides. Cannot proceed to Gate 5. |
| "CSS can't have security issues" | CSS can have XSS (user-controlled classes), clickjacking (z-index manipulation), data exfiltration (CSS injection). ALL code needs security review. |
| "Only MEDIUM issues, can proceed" | MEDIUM issues MUST be fixed. No FIXME, no deferral, no silent ignoring. |
| "Document MEDIUM and ship" | Documentation ≠ resolution. MEDIUM means FIX NOW and re-run all 3 reviewers. |
| "Risk-accept MEDIUM issues" | Risk acceptance requires explicit user approval, not agent decision. |
| "User said skip review" | User cannot override HARD GATES. Review is mandatory. Proceed with review. |
| "Manager approved without review" | Management approval ≠ technical review. Run all 3 reviewers. |
| "Emergency deployment" | Emergencies need review MORE. Run parallel review (10 min). |
| "Deploy while reviews run" | CANNOT deploy until ALL 3 reviewers complete. Gate 4 BEFORE deployment, not during. |
| "Run one reviewer first, evaluate" | Staged execution = sequential execution = violation. ALL 3 in SINGLE message. |
| "Architect reviewed, counts as code review" | Informal reviews ≠ formal reviewers. The 3 specified agents MUST run. No substitutions. |
| "Similar pattern already reviewed" | Code similarity ≠ review completion. Each change requires fresh review by ALL 3 reviewers. |
| "Fix some MEDIUMs, FIXME others" | ALL MEDIUMs require same treatment. Cannot mix approaches without explicit user approval for EACH. |
| "Only frontend changes" | Frontend code requires ALL 3 reviewers. JavaScript has logic (business), CSS has security risks, architecture matters. |
| "Create draft PR, defer review" | Gate 4 completes BEFORE proceeding. Draft/deferral = gate violation. Complete ALL reviews now. |

## Red Flags - STOP

If you catch yourself thinking ANY of these, STOP immediately:

- "This change is too trivial for review"
- "Only N lines, skip review"
- "One reviewer found nothing, skip the others"
- "These are just cosmetic issues"
- "Small fix doesn't need re-review"
- "Sequential reviews are fine this time"
- "Security scanner covers security review"
- "Business tests cover business review"
- "CSS can't have security issues"
- "Only MEDIUM issues, not blocking"
- "Risk-accept these findings"

**All of these indicate Gate 4 violation. Run ALL 3 reviewers in parallel.**

## MEDIUM Issue Protocol (MANDATORY - ABSOLUTE REQUIREMENT)

**Gate 4 requires ALL issues CRITICAL/HIGH/MEDIUM to be FIXED before PASS verdict.**

**Severity mapping is absolute (matches dev-cycle Gate 4 policy):**
- **CRITICAL** → Fix NOW, re-run all 3 reviewers
- **HIGH** → Fix NOW, re-run all 3 reviewers
- **MEDIUM** → Fix NOW, re-run all 3 reviewers
- **LOW** → Add TODO(review): comment with description
- **Cosmetic** → Add FIXME(nitpick): comment (optional)

**MEDIUM Issue Response Protocol:**

1. **STOP immediately** when MEDIUM issues found
2. **Present MEDIUM issues to user**
3. **REQUIRED ACTION:** Fix the issues and re-run all 3 reviewers
4. **CANNOT PASS** with unfixed MEDIUM issues
5. **No FIXME option** for MEDIUM - MEDIUM means mandatory fix

**Anti-Rationalization:** "Only 3 MEDIUM findings, can track with FIXME" → WRONG. MEDIUM = Fix NOW. No deferral, no tracking, no exceptions.

**MEDIUM issues handling:**

| MEDIUM Issue Response | Allowed? | Action Required |
|----------------------|----------|-----------------|
| Fix immediately | ✅ REQUIRED | Fix, re-run all 3 reviewers |
| Add FIXME with issue link | ❌ NO | MEDIUM must be FIXED |
| Ignore silently | ❌ NO | This is a violation |
| "Risk accept" without user | ❌ NO | User must explicitly approve |
| Document in commit msg only | ❌ NO | Must be in code as FIXME |

## Pre-Dispatch Verification (MANDATORY)

**BEFORE dispatching reviewers, verify you are NOT about to:**
- ❌ Run one reviewer "to see if others are needed"
- ❌ Run reviewers in separate messages
- ❌ Skip any reviewer based on change type
- ❌ Use previous review results instead of fresh dispatch

**The ONLY valid action is:** Open Task tool 3 times in THIS message, one for each reviewer.

If you catch yourself planning sequential execution → STOP → Re-plan as parallel.

## Agent Prefix Validation (HARD GATE)

**Before dispatching reviewers, VERIFY agent names:**

**REQUIRED Format:** `ring-default:{reviewer-name}`

**Valid Reviewers:**
- ✅ `ring-default:code-reviewer`
- ✅ `ring-default:business-logic-reviewer`
- ✅ `ring-default:security-reviewer`

**FORBIDDEN (Wrong Prefix/Name):**
- ❌ `code-reviewer` (missing prefix)
- ❌ `ring:code-reviewer` (wrong prefix)
- ❌ `ring-dev-team:code-reviewer` (wrong plugin)
- ❌ `general-purpose` (generic agent, not specialized reviewer)
- ❌ `Explore` (not a reviewer)

**Validation Rule:**
```
IF agent_name does NOT start with "ring-default:"
   AND agent_name is NOT in [code-reviewer, business-logic-reviewer, security-reviewer]
THEN STOP - Invalid agent prefix
```

**If validation fails:**
1. STOP before dispatch
2. Report error: "Invalid reviewer agent: {name}. Must use ring-default:{reviewer-name}"
3. Correct the agent name
4. Re-validate before dispatching

**Why This Is Critical:**
- Wrong agents lack specialized review expertise
- Generic agents miss domain-specific issues
- Invalid names cause Task tool errors

## Parallel Execution - MANDATORY

**You MUST dispatch all 3 reviewers in a SINGLE message:**

```
Task tool #1: ring-default:code-reviewer
Task tool #2: ring-default:business-logic-reviewer
Task tool #3: ring-default:security-reviewer
```

**VIOLATIONS:**
- ❌ Running reviewers one at a time
- ❌ Running 2 reviewers, skipping 1
- ❌ Running reviewers in separate messages
- ❌ Skipping re-review after fixes

**The ONLY acceptable pattern is 3 Task tools in 1 message.**

**If you already dispatched reviewers sequentially (separate messages):**
1. STOP immediately - this is a violation
2. Discard sequential results (they're incomplete context)
3. Re-dispatch ALL 3 reviewers in a SINGLE message with 3 Task tool calls
4. Sequential dispatch wastes time AND misses cross-domain insights

## Gate 4 Violation Consequences

**If you violate Gate 4 protocol (skip reviewers, sequential dispatch, silent MEDIUM acceptance):**

1. The development cycle is INVALID
2. ALL work must be discarded and restarted from Gate 0
3. Cycle metadata marked as violated
4. User notified of violation

**You CANNOT "fix" a violation by re-running reviews. The entire cycle is compromised.**

## Prerequisites

Before starting this gate:
- All tests pass (Gate 3 complete)
- Implementation is feature-complete
- Code is committed (or ready to diff)

## Reviewer Specializations

| Reviewer | Focus Area | Catches |
|----------|------------|---------|
| `ring-default:code-reviewer` | Architecture, patterns, maintainability | Design flaws, code smells, DRY violations |
| `ring-default:business-logic-reviewer` | Correctness, requirements, edge cases | Logic errors, missing cases, requirement gaps |
| `ring-default:security-reviewer` | OWASP, auth, input validation | Vulnerabilities, injection risks, auth bypasses |

## Step 1: Prepare Review Context

Gather: `BASE_SHA=$(git merge-base HEAD main)`, `HEAD_SHA=$(git rev-parse HEAD)`, `git diff --name-only $BASE_SHA $HEAD_SHA`

**Review context:** WHAT_WAS_IMPLEMENTED, PLAN_OR_REQUIREMENTS, ACCEPTANCE_CRITERIA (AC-1, AC-2...), BASE_SHA, HEAD_SHA, FILES_CHANGED

## Step 2: Dispatch All 3 Reviewers IN PARALLEL

**CRITICAL: Single message with 3 Task tool calls:**

| Task | Agent | Prompt |
|------|-------|--------|
| #1 | `ring-default:code-reviewer` | Review context (WHAT_WAS_IMPLEMENTED, PLAN, ACs, SHAs) |
| #2 | `ring-default:business-logic-reviewer` | Same context |
| #3 | `ring-default:security-reviewer` | Same context |

**Wait for ALL three to complete before proceeding.**

## Step 3: Collect Individual Findings

Each reviewer returns: VERDICT (PASS/FAIL/NEEDS_DISCUSSION), Summary, Issues (by severity), What Was Done Well, Next Steps.

Extract per reviewer: VERDICT + Critical/High/Medium/Low issue lists.

## Step 4: Aggregate Findings

Combine all findings by severity with source attribution: Critical (MUST fix), High (MUST fix), Medium (MUST fix), Low (track as TODO).

## Step 5: Determine VERDICT

| Condition | VERDICT | Action |
|-----------|---------|--------|
| All 3 reviewers PASS, no Critical/High/Medium | **PASS** | Proceed to Gate 5 |
| Any Critical finding | **FAIL** | Return to Gate 0 |
| Any High finding | **FAIL** | Return to Gate 0 |
| Any Medium finding | **FAIL** | Return to Gate 0 |
| Only Low findings | **PASS** | Track issues, proceed |

## Step 6: Handle VERDICT

| VERDICT | Actions |
|---------|---------|
| **PASS** | Document → Add `// TODO(review):` for Low → Proceed to Gate 5 |
| **FAIL** | Document Critical/High/Medium → Create fix tasks → Return to Gate 0 → Re-run ALL 3 reviewers after fixes |

## Step 7: Document Review Outcome

**Review Summary contents:** Task ID, Date, Reviewers (all 3), VERDICT, Individual Verdicts, Findings Summary (Critical/High/Medium/Low counts), Actions Taken, Next Steps.

## Re-Review Protocol

**After fixing Critical/High:** Re-run ALL 3 reviewers (fixes may introduce new issues in other domains). Do NOT cherry-pick reviewers.

| Iteration | Duration | Max iterations: 3 |
|-----------|----------|------------------|
| 1st-3rd review | 3-5 min each | Total: ~15-20 min including fixes |

**If FAIL after 3 iterations:** STOP → Request human intervention → Document recurring pattern → Consider architectural changes → Escalate.

## Anti-Patterns

**Never:**
- Run reviewers sequentially (wastes time)
- Skip a reviewer because "domain doesn't apply"
- Proceed with Critical/High issues unfixed
- Cherry-pick which reviewers to re-run
- Argue with valid feedback without evidence
- Mark Low issues as "won't fix" without tracking

**Always:**
- Launch all 3 reviewers in single message
- Wait for all to complete before aggregating
- Fix Critical/High/Medium immediately
- Track Low with TODO comments
- Re-run full review after fixes
- Document reviewer disagreements

## Execution Report

| Metric | Value |
|--------|-------|
| Duration | Xm Ys |
| Review Iterations | N |
| Reviewers | 3 (parallel) |
| Findings | X Critical, Y High, Z Medium, W Low |
| Fixes Applied | N |
| VERDICT | PASS/FAIL/NEEDS_DISCUSSION |
| Result | Gate passed / Returned to Gate 0 / Awaiting decision |

## Pushing Back on Reviewers

**When feedback is incorrect:** (1) Provide technical evidence (code, tests, docs) (2) Explain why implementation is correct (3) Reference requirements/architecture (4) Request clarification for ambiguous feedback (5) Security concerns need extra scrutiny before dismissing

**Example:** Reviewer says "SQL injection" → Response: "Using parameterized query on line 45: `db.Query(..., $1, userID)`. Test in auth_test.go:78 verifies."
