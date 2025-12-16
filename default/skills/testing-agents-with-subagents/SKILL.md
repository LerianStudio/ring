---
name: testing-agents-with-subagents
description: |
  Agent testing methodology - run agents with test inputs, observe outputs,
  iterate until outputs are accurate and well-structured.

trigger: |
  - Before deploying a new agent
  - After editing an existing agent
  - Agent produces structured outputs that must be accurate

skip_when: |
  - Agent is simple passthrough → minimal testing needed
  - Agent already tested for this use case

related:
  complementary: [test-driven-development]
---

# Testing Agents With Subagents

## Overview

**Testing agents is TDD applied to AI worker definitions.**

You run agents with known test inputs (RED - observe incorrect outputs), fix the agent definition (GREEN - outputs now correct), then handle edge cases (REFACTOR - robust under all conditions).

**Core principle:** If you didn't run an agent with test inputs and verify its outputs, you don't know if the agent works correctly.

**REQUIRED BACKGROUND:** You MUST understand `test-driven-development` before using this skill. That skill defines the fundamental RED-GREEN-REFACTOR cycle. This skill provides agent-specific test formats (test inputs, output verification, accuracy metrics).

**Key difference from testing-skills-with-subagents:**
- **Skills** = instructions that guide behavior; test if agent follows rules under pressure
- **Agents** = separate Claude instances via Task tool; test if they produce correct outputs

## The Iron Law

```
NO AGENT DEPLOYMENT WITHOUT RED-GREEN-REFACTOR TESTING FIRST
```

About to deploy an agent without completing the test cycle? You have ONLY one option:

### STOP. TEST FIRST. THEN DEPLOY.

**You CANNOT:**
- ❌ "Deploy and monitor for issues"
- ❌ "Test with first real usage"
- ❌ "Quick smoke test is enough"
- ❌ "Tested manually in Claude UI"
- ❌ "One test case passed"
- ❌ "Agent prompt looks correct"
- ❌ "Based on working template"
- ❌ "Deploy now, test in parallel"
- ❌ "Production is down, no time to test"

**ZERO exceptions. Simple agent, expert confidence, time pressure, production outage - NONE override testing.**

**Why this is absolute:** Untested agents fail in production. Every time. The question is not IF but WHEN and HOW BADLY. A 20-minute test suite prevents hours of debugging and lost trust.

## When to Use

Test agents that:
- Analyze code/designs and produce findings (reviewers)
- Generate structured outputs (planners, analyzers)
- Make decisions or categorizations (severity, priority)
- Have defined output schemas that must be followed
- Are used in parallel workflows where consistency matters

**Test exemptions require explicit human partner approval:**
- Simple pass-through agents (just reformatting) - **only if human partner confirms**
- Agents without structured outputs - **only if human partner confirms**
- **You CANNOT self-determine test exemption**
- **When in doubt → TEST**

## TDD Mapping for Agent Testing

| TDD Phase | Agent Testing | What You Do |
|-----------|---------------|-------------|
| **RED** | Run with test inputs | Dispatch agent, observe incorrect/incomplete outputs |
| **Verify RED** | Document failures | Capture exact output issues verbatim |
| **GREEN** | Fix agent definition | Update prompt/schema to address failures |
| **Verify GREEN** | Re-run tests | Agent now produces correct outputs |
| **REFACTOR** | Test edge cases | Ambiguous inputs, empty inputs, complex scenarios |
| **Stay GREEN** | Re-verify all | Previous tests still pass after changes |

Same cycle as code TDD, different test format.

## RED Phase: Baseline Testing (Observe Failures)

**Goal:** Run agent with known test inputs - observe what's wrong, document exact failures.

This is identical to TDD's "write failing test first" - you MUST see what the agent actually produces before fixing the definition.

**Process:**

- [ ] **Create test inputs** (known issues, edge cases, clean inputs)
- [ ] **Run agent** - dispatch via Task tool with test inputs
- [ ] **Compare outputs** - expected vs actual
- [ ] **Document failures** - missing findings, wrong severity, bad format
- [ ] **Identify patterns** - which input types cause failures?

### Test Input Categories

| Category | Purpose | Example |
|----------|---------|---------|
| **Known Issues** | Verify agent finds real problems | Code with SQL injection, hardcoded secrets |
| **Clean Inputs** | Verify no false positives | Well-written code with no issues |
| **Edge Cases** | Verify robustness | Empty files, huge files, unusual patterns |
| **Ambiguous Cases** | Verify judgment | Code that could go either way |
| **Severity Calibration** | Verify severity accuracy | Mix of critical, high, medium, low issues |

### Minimum Test Suite Requirements

Before deploying ANY agent, you MUST have:

| Agent Type | Minimum Test Cases | Required Coverage |
|------------|-------------------|-------------------|
| **Reviewer agents** | 6 tests | 2 known issues, 2 clean, 1 edge case, 1 ambiguous |
| **Analyzer agents** | 5 tests | 2 typical, 1 empty, 1 large, 1 malformed |
| **Decision agents** | 4 tests | 2 clear cases, 2 boundary cases |
| **Planning agents** | 5 tests | 2 standard, 1 complex, 1 minimal, 1 edge case |

**Fewer tests = incomplete testing = DO NOT DEPLOY.**

One test case proves nothing. Three tests are suspicious. Six tests are minimum for confidence.

### Example Test Suite for Code Reviewer

| Test | Input | Expected |
|------|-------|----------|
| SQL Injection | String concatenation in SQL | CRITICAL, OWASP A03:2021 |
| Clean Auth | Proper JWT validation | No findings or LOW only |
| Ambiguous Error | Caught but only logged | MEDIUM silent failure |
| Empty File | Empty source | Graceful handling |

### Running the Test

Dispatch via Task tool with test input → **Document exact output verbatim** (don't summarize).

## GREEN Phase: Fix Agent Definition (Make Tests Pass)

Write/update agent definition addressing specific failures documented in RED phase.

**Common fixes:**

| Failure Type | Fix Approach |
|--------------|--------------|
| Missing findings | Add explicit instructions to check for X |
| Wrong severity | Add severity calibration examples |
| Bad output format | Add output schema with examples |
| False positives | Add "don't flag X when Y" instructions |
| Incomplete analysis | Add "always check A, B, C" checklist |

### Example Fix: Severity Calibration

**RED Failure:** Agent marked hardcoded password as MEDIUM instead of CRITICAL

**GREEN Fix:** Add severity calibration: CRITICAL (hardcoded secrets, SQL injection, auth bypass), HIGH (missing validation, error exposure), MEDIUM (rate limiting, verbose errors), LOW (headers, deps)

### Re-run Tests

After fixing, re-run ALL test cases. If any fail → continue fixing, re-test.

## VERIFY GREEN: Output Verification

**Goal:** Confirm agent produces correct, well-structured outputs consistently.

### Accuracy Metrics

| Metric | Target |
|--------|--------|
| True Positives | 100% |
| False Positives | <10% |
| False Negatives | <5% |
| Severity Accuracy | >90% |
| Schema Compliance | 100% |

### Consistency Testing

Run same input 3 times → outputs should be identical. Inconsistency indicates ambiguous agent definition.

## REFACTOR Phase: Edge Cases and Robustness

Agent passes basic tests? Now test edge cases.

### Edge Case Categories

| Category | Test Cases |
|----------|------------|
| **Empty/Null** | Empty file, null input, whitespace only |
| **Large** | 10K line file, deeply nested code |
| **Unusual** | Minified code, generated code, config files |
| **Multi-language** | Mixed JS/TS, embedded SQL, templates |
| **Ambiguous** | Code that could be good or bad depending on context |

### Stress Testing

Test edge cases: Large file (5000 lines, 20 issues), Complex nesting (15-level deep). Verify all issues found with reasonable response time.

### Ambiguity Testing

Test context-dependent cases (e.g., hardcoded password with "local dev" comment). Agent should flag but acknowledge context.

### Plugging Holes

For each edge case failure, add explicit handling to agent definition:
- Empty files: Return "No code to review" with PASS
- Large files: Focus on high-risk patterns first
- Minified code: Note limitations
- Context comments: Consider but don't use to dismiss issues
## Testing Parallel Agent Workflows

When agents run in parallel (like 3 reviewers), test combined workflow:
- **Parallel Consistency**: Same input to all reviewers → check findings overlap appropriately, no contradictions
- **Aggregation Testing**: Same issue found by multiple reviewers → severity should be consistent; fix misalignments

## Agent Testing Checklist

**RED Phase:** Create test inputs (known issues, clean, edge cases) → Run agent → Document failures verbatim

**GREEN Phase:** Update agent definition → Re-run tests → All pass

**REFACTOR Phase:** Test edge cases → Test stress scenarios → Add explicit handling → Verify consistency (3+ runs) → Test parallel integration (if applicable) → Re-run ALL tests after each change

**Metrics (reviewer agents):** True positive >95%, False positive <10%, False negative <5%, Severity accuracy >90%, Schema compliance 100%, Consistency >95%

## Prohibited Testing Shortcuts

**You CANNOT substitute proper testing with:**

| Shortcut | Why It Fails |
|----------|--------------|
| Reading agent definition carefully | Reading ≠ executing. Must run agent with inputs. |
| Manual testing in Claude UI | Ad-hoc ≠ reproducible. No baseline documented. |
| "Looks good to me" review | Visual inspection misses runtime failures. |
| Basing on proven template | Templates need validation for YOUR use case. |
| Expert prompt engineering knowledge | Expertise doesn't prevent bugs. Tests do. |
| Testing after first production use | Production is not QA. Test before deployment. |
| Monitoring production for issues | Reactive ≠ proactive. Catch issues before users do. |
| Deploy now, test in parallel | Parallel testing still means untested code in production. |

**ALL require running agent with documented test inputs and comparing outputs.**

## Testing Agent Modifications

**EVERY agent edit requires re-running the FULL test suite:**

| Change Type | Required Action |
|-------------|-----------------|
| Prompt wording changes | Full re-test |
| Severity calibration updates | Full re-test |
| Output schema modifications | Full re-test |
| Adding edge case handling | Full re-test |
| "Small" one-line changes | Full re-test |
| Typo fixes in prompt | Full re-test |

**"Small change" is not an exception.** One-line prompt changes can completely alter LLM behavior. Re-test always.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Testing only "happy path" inputs | Include ambiguous + edge cases |
| Not documenting exact outputs | Capture verbatim, compare to expected |
| Fixing without re-running all tests | Re-run entire suite after each change |
| Testing single agent in isolation (parallel workflow) | Test parallel dispatch + aggregation |
| Not testing consistency | Run same input 3+ times |
| Skipping severity calibration | Add explicit severity examples |
| Not testing edge cases | Test empty, large, unusual, ambiguous |
| Single test case validation | Minimum 4-6 test cases per agent type |
| Manual UI testing as substitute | Document all test inputs and expected outputs |
| Skipping re-test for "small" changes | Re-run full suite after ANY modification |


## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "Agent prompt is obviously correct" | Obvious prompts fail in practice. Test proves correctness. |
| "Tested manually in Claude UI" | Ad-hoc ≠ reproducible. No baseline documented. |
| "One test case passed" | Sample size = 1 proves nothing. Need 4-6 cases minimum. |
| "Will test after first production use" | Production is not QA. Test before deployment. Always. |
| "Reading prompt is sufficient review" | Reading ≠ executing. Must run agent with inputs. |
| "Changes are small, re-test unnecessary" | Small changes cause big failures. Re-run full suite. |
| "Based agent on proven template" | Templates need validation for your use case. Test anyway. |
| "Expert in prompt engineering" | Expertise doesn't prevent bugs. Tests do. |
| "Production is down, no time to test" | Deploying untested fix may make outage worse. Test first. |
| "Deploy now, test in parallel" | Untested code in production = unknown behavior. Unacceptable. |
| "Quick smoke test is enough" | Smoke test misses edge cases. Full suite required. |
| "Simple pass-through agent" | You cannot self-determine exemptions. Get human approval. |

## Red Flags - STOP and Test Now

If you catch yourself thinking ANY of these, STOP. You're about to violate the Iron Law:

- Agent edited but tests not re-run
- "Looks good" without execution
- Single test case only
- No documented baseline
- No edge case testing
- Manual verification only
- "Will test in production"
- "Based on template, should work"
- "Just a small prompt change"
- "No time to test properly"
- "One quick test is enough"
- "Agent is simple, obviously works"
- "Expert intuition says it's fine"
- "Production is down, skip testing"
- "Deploy now, test in parallel"

**All of these mean: STOP. Run full RED-GREEN-REFACTOR cycle NOW.**

## Quick Reference (TDD Cycle for Agents)

| TDD Phase | Agent Testing | Success Criteria |
|-----------|---------------|------------------|
| **RED** | Run with test inputs | Document exact output failures |
| **Verify RED** | Capture verbatim | Have specific issues to fix |
| **GREEN** | Fix agent definition | All basic tests pass |
| **Verify GREEN** | Re-run all tests | No regressions |
| **REFACTOR** | Test edge cases | Robust under all conditions |
| **Stay GREEN** | Full test suite | All tests pass, metrics met |

## Example: Testing a New Reviewer Agent

### Step 1: Create Test Suite

| Test | Input | Expected |
|------|-------|----------|
| SQL Injection | `"SELECT * FROM users WHERE id = " + user_id` | CRITICAL, OWASP A03:2021 |
| Parameterized (Clean) | `db.execute(query, [user_id])` | No findings |
| Hardcoded Secret | `API_KEY = "sk-1234..."` | CRITICAL |
| Env Variable (Clean) | `os.environ.get("API_KEY")` | No findings |
| Empty File | (empty) | Graceful handling |
| Ambiguous | `password = "dev123"  # Local dev` | Flag with context |

**Step 2: RED Phase** - Run tests, document failures: Test 1 marked HIGH not CRITICAL, Test 3 missed, Test 5 errored, Test 6 dismissed.

**Step 3: GREEN Phase** - Fix definition: Add severity calibration (SQL=CRITICAL), hardcoded secrets pattern, empty file handling, "context comments dont dismiss issues".

**Step 4: Re-run** - All tests pass with correct severities and handling.

**Step 5: REFACTOR** - Add edge cases: minified code, 10K line file, mixed languages, nested vulnerabilities. Run, fix, repeat.


## The Bottom Line

**Agent testing IS TDD. Same principles, same cycle, same benefits.**

If you wouldn't deploy code without tests, don't deploy agents without testing them.

RED-GREEN-REFACTOR for agents works exactly like RED-GREEN-REFACTOR for code:
1. **RED:** See what's wrong (run with test inputs)
2. **GREEN:** Fix it (update agent definition)
3. **REFACTOR:** Make it robust (edge cases, consistency)

**Evidence before deployment. Always.**
