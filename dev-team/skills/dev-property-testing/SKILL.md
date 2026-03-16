---
name: dev-property-testing
title: Development cycle property-based testing (Gate 5)
category: development-cycle
tier: 1
when_to_use: |
  Use after fuzz testing (Gate 4) is complete.
  MANDATORY for all development tasks - verifies domain invariants always hold.
description: |
  Gate 5 of development cycle - ensures property-based tests exist
  to verify domain invariants hold for all randomly generated inputs.

trigger: |
  - After fuzz testing complete (Gate 4)
  - MANDATORY for all development tasks
  - Verifies domain invariants via testing/quick package

NOT_skip_when: |
  - "Unit tests verify logic" - Property tests verify INVARIANTS across all inputs.
  - "No domain invariants" - Every domain has invariants. Find them.
  - "Too abstract" - Properties are concrete: "balance never negative", "IDs always unique".

sequence:
  after: [ring:dev-fuzz-testing]
  before: [ring:dev-integration-testing]

related:
  complementary: [ring:dev-cycle, ring:dev-fuzz-testing, ring:qa-analyst]

input_schema:
  required:
    - name: unit_id
      type: string
      description: "Task or subtask identifier"
    - name: implementation_files
      type: array
      items: string
      description: "Files from Gate 0 implementation"
    - name: language
      type: string
      enum: [go]
      description: "Programming language"
  optional:
    - name: domain_invariants
      type: array
      items: string
      description: "Domain invariants to verify"
    - name: gate4_handoff
      type: object
      description: "Full handoff from Gate 4 (fuzz testing)"

output_schema:
  format: markdown
  required_sections:
    - name: "Property Testing Summary"
      pattern: "^## Property Testing Summary"
      required: true
    - name: "Properties Report"
      pattern: "^## Properties Report"
      required: true
    - name: "Handoff to Next Gate"
      pattern: "^## Handoff to Next Gate"
      required: true
  metrics:
    - name: result
      type: enum
      values: [PASS, FAIL]
    - name: properties_tested
      type: integer
    - name: properties_passed
      type: integer
    - name: counterexamples_found
      type: integer
    - name: iterations
      type: integer

verification:
  automated:
    - command: "grep -rn 'TestProperty_' --include='*_test.go' ."
      description: "Property test functions exist"
      success_pattern: "TestProperty_"
    - command: "grep -rn 'quick.Check' --include='*_test.go' ."
      description: "quick.Check used"
      success_pattern: "quick.Check"
  manual:
    - "Properties follow TestProperty_{Subject}_{Property} naming"
    - "At least one property per domain entity"
    - "No counterexamples found"

examples:
  - name: "Property tests for money calculations"
    input:
      unit_id: "task-001"
      implementation_files: ["internal/domain/money.go"]
      language: "go"
      domain_invariants: ["Amount never negative", "Currency always valid"]
    expected_output: |
      ## Property Testing Summary
      **Status:** PASS
      **Properties Tested:** 3
      **Properties Passed:** 3
      **Counterexamples Found:** 0

      ## Properties Report
      | Property | Subject | Status |
      |
----------|---------|--------|
      | TestProperty_Money_AmountNeverNegative | Money | PASS |
      | TestProperty_Money_CurrencyAlwaysValid | Money | PASS |
      | TestProperty_Money_AdditionCommutative | Money | PASS |

      ## Handoff to Next Gate
      - Ready for Gate 6 (Integration Testing): YES
---

# Dev Property Testing (Gate 5)

## Overview

Ensure domain logic has **property-based tests** to verify invariants hold for all randomly generated inputs.

**Core principle:** Property tests verify universal truths about your domain. If "balance is never negative" is a rule, test it with thousands of random inputs.

<block_condition>
- No property functions = FAIL
- Any counterexample found = FAIL (fix and re-run)
- No quick.Check usage = FAIL
</block_condition>

## CRITICAL: Role Clarification

**This skill ORCHESTRATES. QA Analyst Agent (property mode) EXECUTES.**

| Who | Responsibility |
|-----|----------------|
| **This Skill** | Gather requirements, dispatch agent, track iterations |
| **QA Analyst Agent** | Write property tests, run quick.Check, report counterexamples |

---

## Standards Reference

**MANDATORY:** Load testing-property.md standards via WebFetch.

<fetch_required>
https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/testing-property.md
</fetch_required>

---

## Step 1: Validate Input

```text
REQUIRED INPUT:
- unit_id: [task/subtask being tested]
- implementation_files: [files from Gate 0]
- language: [go]

OPTIONAL INPUT:
- domain_invariants: [list of invariants to verify]
- gate4_handoff: [full Gate 4 output]

if any REQUIRED input is missing:
  → STOP and report: "Missing required input: [field]"
```

## Step 2: Dispatch QA Analyst Agent (Property Mode)

```text
Task tool:
  subagent_type: "ring:qa-analyst"
  prompt: |
    **MODE:** PROPERTY-BASED TESTING (Gate 5)

    **Standards:** Load testing-property.md

    **Input:**
    - Unit ID: {unit_id}
    - Implementation Files: {implementation_files}
    - Language: {language}
    - Domain Invariants: {domain_invariants}

    **Requirements:**
    1. Identify domain invariants from code
    2. Create property functions (TestProperty_{Subject}_{Property} naming)
    3. Use testing/quick.Check for verification
    4. Report any counterexamples found

    **Output Sections Required:**
    - ## Property Testing Summary
    - ## Properties Report
    - ## Handoff to Next Gate
```

## Step 3: Evaluate Results

```text
Parse agent output:

if "Status: PASS" in output:
  → Gate 5 PASSED
  → Return success with metrics

if "Status: FAIL" in output:
  → Dispatch fix to implementation agent
  → Re-run property tests (max 3 iterations)
  → If still failing: ESCALATE to user
```

## Step 4: Generate Output

```text
## Property Testing Summary
**Status:** {PASS|FAIL}
**Properties Tested:** {count}
**Properties Passed:** {count}
**Counterexamples Found:** {count}

## Properties Report
| Property | Subject | Status |
|----------|---------|--------|
| {property_name} | {subject} | {PASS|FAIL} |

## Handoff to Next Gate
- Ready for Gate 6 (Integration Testing): {YES|NO}
- Iterations: {count}
```

---

## Common Properties to Test

| Domain | Example Properties |
|--------|-------------------|
| Money/Currency | Amount never negative, currency always valid, addition commutative |
| User/Account | Email always valid format, password meets policy, status transitions valid |
| Order/Transaction | Total equals sum of items, quantity always positive, state machine valid |
| Date/Time | Start before end, duration always positive, timezone valid |

---

## Severity Calibration

| Severity | Criteria | Examples |
|----------|----------|----------|
| **CRITICAL** | Counterexample found, invariant violated | quick.Check finds input that breaks property |
| **HIGH** | No property tests, missing quick.Check | Zero TestProperty_ functions, no testing/quick usage |
| **MEDIUM** | Incomplete properties, naming issues | Missing domain invariants, non-standard names |
| **LOW** | Documentation, optimization | Missing property descriptions, generator tuning |

Report all severities. CRITICAL = immediate fix (invariant broken). HIGH = fix before gate pass. MEDIUM = fix in iteration. LOW = document.

---

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Unit tests verify logic" | Unit tests verify SPECIFIC cases. Properties verify ALL cases. | **Write property tests** |
| "No domain invariants" | Every domain has rules. "ID is unique", "amount > 0", etc. | **Identify and test invariants** |
| "Too abstract" | Properties are concrete: "user.age >= 0 for all users". | **Write property tests** |
| "quick.Check is slow" | Milliseconds to find bugs that would take hours to discover. | **Write property tests** |

---
