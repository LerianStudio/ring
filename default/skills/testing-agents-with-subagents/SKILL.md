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

**REQUIRED BACKGROUND:** You MUST understand `ring:test-driven-development` before using this skill. That skill defines the fundamental RED-GREEN-REFACTOR cycle. This skill provides agent-specific test formats (test inputs, output verification, accuracy metrics).

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

```markdown
## Test Case 1: Known SQL Injection
**Input:** Function with string concatenation in SQL query
**Expected:** CRITICAL finding, references OWASP A03:2021
**Actual:** [Run agent, record output]

## Test Case 2: Clean Authentication
**Input:** Well-implemented JWT validation with proper error handling
**Expected:** No findings or LOW-severity suggestions only
**Actual:** [Run agent, record output]

## Test Case 3: Ambiguous Error Handling
**Input:** Error caught but only logged, not re-thrown
**Expected:** MEDIUM finding about silent failures
**Actual:** [Run agent, record output]

## Test Case 4: Empty File
**Input:** Empty source file
**Expected:** Graceful handling, no crash, maybe LOW finding
**Actual:** [Run agent, record output]
```

### Running the Test

```markdown
Use Task tool to dispatch agent:

Task(
  subagent_type="ring:code-reviewer",
  prompt="""
  Review this code for security issues:

  ```python
  def get_user(user_id):
      query = "SELECT * FROM users WHERE id = " + user_id
      return db.execute(query)
  ```

  Provide findings with severity levels.
  """
)
```

**Document exact output.** Don't summarize - capture verbatim.

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

**RED Phase Failure:**
```
Agent marked hardcoded password as MEDIUM instead of CRITICAL
```

**GREEN Phase Fix (add to agent definition):**
```markdown
## Severity Calibration

**CRITICAL:** Immediate exploitation possible
- Hardcoded secrets (passwords, API keys, tokens)
- SQL injection with user input
- Authentication bypass

**HIGH:** Exploitation requires additional steps
- Missing input validation
- Improper error handling exposing internals

**MEDIUM:** Security weakness, not directly exploitable
- Missing rate limiting
- Verbose error messages

**LOW:** Best practice violations
- Missing security headers
- Outdated dependencies (no known CVEs)
```

### Re-run Tests

After fixing, re-run ALL test cases:

```markdown
## Test Results After Fix

| Test Case | Expected | Actual | Pass/Fail |
|-----------|----------|--------|-----------|
| SQL Injection | CRITICAL | CRITICAL |  PASS |
| Clean Auth | No findings | No findings |  PASS |
| Ambiguous Error | MEDIUM | MEDIUM |  PASS |
| Empty File | Graceful | Graceful |  PASS |
```

If any test fails: continue fixing, re-test.

## VERIFY GREEN: Output Verification

**Goal:** Confirm agent produces correct, well-structured outputs consistently.

### Output Schema Compliance

If agent has defined output schema, verify compliance:

```markdown
## Expected Schema
- Summary (1-2 sentences)
- Findings (array of {severity, location, description, recommendation})
- Overall assessment (PASS/FAIL with conditions)

## Actual Output Analysis
- Summary:  Present, correct format
- Findings:  Array, all fields present
- Overall assessment: L Missing conditions for FAIL
```

### Accuracy Metrics

Track agent accuracy across test suite:

| Metric | Target | Actual |
|--------|--------|--------|
| True Positives (found real issues) | 100% | [X]% |
| False Positives (flagged non-issues) | <10% | [X]% |
| False Negatives (missed real issues) | <5% | [X]% |
| Severity Accuracy | >90% | [X]% |
| Schema Compliance | 100% | [X]% |

### Consistency Testing

Run same test input 3 times. Outputs should be consistent:

```markdown
## Consistency Test: SQL Injection Input

Run 1: CRITICAL, SQL injection, line 3
Run 2: CRITICAL, SQL injection, line 3
Run 3: CRITICAL, SQL injection, line 3

Consistency:  100% (all runs identical findings)
```

Inconsistency indicates agent definition is ambiguous.

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

```markdown
## Stress Test: Large File

**Input:** 5000-line file with 20 known issues scattered throughout
**Expected:** All 20 issues found, reasonable response time
**Actual:** [Run agent, record output]

## Stress Test: Complex Nesting

**Input:** 15-level deep callback hell
**Expected:** Findings about complexity, maintainability
**Actual:** [Run agent, record output]
```

### Ambiguity Testing

```markdown
## Ambiguity Test: Context-Dependent Security

**Input:**
```python
# Internal admin tool, not exposed to users
password = "admin123"  # Default for local dev
```

**Expected:** Agent should note context but still flag
**Actual:** [Run agent, record output]

**Analysis:** Does agent handle nuance appropriately?
```

### Plugging Holes

For each edge case failure, add explicit handling:

**Before:**
```markdown
Review code for security issues.
```

**After:**
```markdown
Review code for security issues.

**Edge case handling:**
- Empty files: Return "No code to review" with PASS
- Large files (>5K lines): Focus on high-risk patterns first
- Minified code: Note limitations, review what's readable
- Context comments: Consider but don't use to dismiss issues
```

## Testing Parallel Agent Workflows

When agents run in parallel (like 3 reviewers), test the combined workflow:

### Parallel Consistency

```markdown
## Parallel Test: Same Input to All Reviewers

Input: Authentication module with mixed issues

| Reviewer | Findings | Overlap |
|----------|----------|---------|
| code-reviewer | 5 findings | - |
| business-logic-reviewer | 3 findings | 1 shared |
| security-reviewer | 4 findings | 2 shared |

Analysis:
- Total unique findings: 9
- Appropriate overlap (security issues found by both security and code reviewer)
- No contradictions
```

### Aggregation Testing

```markdown
## Aggregation Test: Severity Consistency

Same issue found by multiple reviewers:

| Reviewer | Finding | Severity |
|----------|---------|----------|
| code-reviewer | Missing null check | MEDIUM |
| business-logic-reviewer | Missing null check | HIGH |

Problem: Inconsistent severity for same issue
Fix: Align severity calibration across all reviewers
```

## Agent Testing Checklist

Before deploying agent, verify you followed RED-GREEN-REFACTOR:

**RED Phase:**
- [ ] Created test inputs (known issues, clean code, edge cases)
- [ ] Ran agent with test inputs
- [ ] Documented failures verbatim (missing findings, wrong severity, bad format)

**GREEN Phase:**
- [ ] Updated agent definition addressing specific failures
- [ ] Re-ran test inputs
- [ ] All basic tests now pass

**REFACTOR Phase:**
- [ ] Tested edge cases (empty, large, unusual, ambiguous)
- [ ] Tested stress scenarios (many issues, complex code)
- [ ] Added explicit edge case handling to definition
- [ ] Verified consistency (multiple runs produce same results)
- [ ] Verified schema compliance
- [ ] Tested parallel workflow integration (if applicable)
- [ ] Re-ran ALL tests after each change

**Metrics (for reviewer agents):**
- [ ] True positive rate: >95%
- [ ] False positive rate: <10%
- [ ] False negative rate: <5%
- [ ] Severity accuracy: >90%
- [ ] Schema compliance: 100%
- [ ] Consistency: >95%

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

**L Testing with only "happy path" inputs**
Agent works with obvious issues but misses subtle ones.
 Fix: Include ambiguous cases and edge cases in test suite.

**L Not documenting exact outputs**
"Agent was wrong" doesn't tell you what to fix.
 Fix: Capture agent output verbatim, compare to expected.

**L Fixing without re-running all tests**
Fix one issue, break another.
 Fix: Re-run entire test suite after each change.

**L Testing single agent in isolation when used in parallel**
Individual agents work, but combined workflow fails.
 Fix: Test parallel dispatch and output aggregation.

**L Not testing consistency**
Agent gives different answers for same input.
 Fix: Run same input 3+ times, verify consistent output.

**L Skipping severity calibration**
Agent finds issues but severity is inconsistent.
 Fix: Add explicit severity examples to agent definition.

**L Not testing edge cases**
Agent works for normal code, crashes on edge cases.
 Fix: Test empty, large, unusual, and ambiguous inputs.

**Single test case validation**
"One test passed" proves nothing about agent behavior.
Fix: Minimum 4-6 test cases per agent type.

**Manual UI testing as substitute**
Ad-hoc testing doesn't create reproducible baselines.
Fix: Document all test inputs and expected outputs.

**Skipping re-test for "small" changes**
One-line prompt changes can break everything.
Fix: Re-run full suite after ANY modification.

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

```markdown
# security-reviewer Test Suite

## Test 1: SQL Injection (Known Critical)
Input: `query = "SELECT * FROM users WHERE id = " + user_id`
Expected: CRITICAL, SQL injection, OWASP A03:2021

## Test 2: Parameterized Query (Clean)
Input: `query = "SELECT * FROM users WHERE id = ?"; db.execute(query, [user_id])`
Expected: No security findings

## Test 3: Hardcoded Secret (Known Critical)
Input: `API_KEY = "sk-1234567890abcdef"`
Expected: CRITICAL, hardcoded secret

## Test 4: Environment Variable (Clean)
Input: `API_KEY = os.environ.get("API_KEY")`
Expected: No security findings (or LOW suggestion for validation)

## Test 5: Empty File
Input: (empty)
Expected: Graceful handling

## Test 6: Ambiguous - Internal Tool
Input: `password = "dev123"  # Local development only`
Expected: Flag but acknowledge context
```

### Step 2: Run RED Phase

```
Test 1: L Found issue but marked HIGH not CRITICAL
Test 2:  No findings
Test 3: L Missed entirely
Test 4:  No findings
Test 5: L Error: "No code provided"
Test 6: L Dismissed due to comment
```

### Step 3: GREEN Phase - Fix Definition

Add to agent:
1. Severity calibration with SQL injection = CRITICAL
2. Explicit check for hardcoded secrets pattern
3. Empty file handling instruction
4. "Context comments don't dismiss security issues"

### Step 4: Re-run Tests

```
Test 1:  CRITICAL
Test 2:  No findings
Test 3:  CRITICAL
Test 4:  No findings
Test 5:  "No code to review"
Test 6:  Flagged with context acknowledgment
```

### Step 5: REFACTOR - Edge Cases

Add tests for: minified code, 10K line file, mixed languages, nested vulnerabilities.

Run, fix, repeat until all pass.

## The Bottom Line

**Agent testing IS TDD. Same principles, same cycle, same benefits.**

If you wouldn't deploy code without tests, don't deploy agents without testing them.

RED-GREEN-REFACTOR for agents works exactly like RED-GREEN-REFACTOR for code:
1. **RED:** See what's wrong (run with test inputs)
2. **GREEN:** Fix it (update agent definition)
3. **REFACTOR:** Make it robust (edge cases, consistency)

**Evidence before deployment. Always.**
