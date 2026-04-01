---
name: ring:dev-fuzz-testing
title: Development cycle fuzz testing (Gate 4)
category: development-cycle
tier: 1
when_to_use: |
  Use after unit testing (Gate 3) is complete.
  MANDATORY for all development tasks - discovers edge cases and crashes.
description: |
  Gate 4 of development cycle - ensures fuzz tests exist with proper seed corpus
  to discover edge cases, crashes, and unexpected input handling.

trigger: |
  - After unit testing complete (Gate 3)
  - MANDATORY for all development tasks
  - Discovers crashes and edge cases via random input generation

NOT_skip_when: |
  - "Unit tests cover edge cases" - Fuzz tests find cases you didn't think of.
  - "No time for fuzz testing" - Fuzz tests catch crashes before production.
  - "Code is simple" - Simple code can still crash on unexpected input.

sequence:
  after: [ring:dev-unit-testing]
  before: [ring:dev-property-testing]

related:
  complementary: [ring:dev-cycle, ring:dev-unit-testing, ring:qa-analyst]

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
      description: "Programming language (Go only for native fuzz)"
  optional:
    - name: gate3_handoff
      type: object
      description: "Full handoff from Gate 3 (unit testing)"

output_schema:
  format: markdown
  required_sections:
    - name: "Fuzz Testing Summary"
      pattern: "^## Fuzz Testing Summary"
      required: true
    - name: "Corpus Report"
      pattern: "^## Corpus Report"
      required: true
    - name: "Handoff to Next Gate"
      pattern: "^## Handoff to Next Gate"
      required: true
  metrics:
    - name: result
      type: enum
      values: [PASS, FAIL]
    - name: fuzz_functions
      type: integer
    - name: corpus_entries
      type: integer
    - name: crashes_found
      type: integer
    - name: iterations
      type: integer

verification:
  automated:
    - command: "grep -rn 'func Fuzz' --include='*_test.go' ."
      description: "Fuzz functions exist"
      success_pattern: "func Fuzz"
    - command: "grep -rn 'f.Add' --include='*_test.go' ."
      description: "Seed corpus entries exist"
      success_pattern: "f.Add"
  manual:
    - "Fuzz functions follow FuzzXxx naming convention"
    - "Seed corpus has at least 5 entries per function"
    - "No crashes found during 30s fuzz run"

examples:
  - name: "Fuzz tests for parser"
    input:
      unit_id: "task-001"
      implementation_files: ["internal/parser/json.go"]
      language: "go"
    expected_output: |
      ## Fuzz Testing Summary
      **Status:** PASS
      **Fuzz Functions:** 2
      **Corpus Entries:** 12
      **Crashes Found:** 0

      ## Corpus Report
      | Function | Entries | Crashes |
      |
----------|---------|---------|
      | FuzzParseJSON | 6 | 0 |
      | FuzzParseConfig | 6 | 0 |

      ## Handoff to Next Gate
      - Ready for Gate 5 (Property Testing): YES
---

# Dev Fuzz Testing (Gate 4)

## Overview

Ensure critical parsing and input handling code has **fuzz tests** to discover crashes and edge cases through random input generation.

**Core principle:** Fuzz tests find bugs you didn't think to test for. They're mandatory for all code that handles external input.

<block_condition>
- No fuzz functions = FAIL
- Seed corpus < 5 entries = FAIL
- Any crash found = FAIL (fix and re-run)
</block_condition>

## CRITICAL: Role Clarification

**This skill ORCHESTRATES. QA Analyst Agent (fuzz mode) EXECUTES.**

| Who | Responsibility |
|-----|----------------|
| **This Skill** | Gather requirements, dispatch agent, track iterations |
| **QA Analyst Agent** | Write fuzz tests, generate corpus, run fuzz |

---

## Standards Reference

**MANDATORY:** Load testing-fuzz.md standards via WebFetch.

<fetch_required>
https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/testing-fuzz.md
</fetch_required>

---

## Step 1: Validate Input

```text
REQUIRED INPUT:
- unit_id: [task/subtask being tested]
- implementation_files: [files from Gate 0]
- language: [go only for native fuzz]

OPTIONAL INPUT:
- gate3_handoff: [full Gate 3 output]

if any REQUIRED input is missing:
  → STOP and report: "Missing required input: [field]"

if language != "go":
  → STOP and report: "Native fuzz testing only supported for Go (Go 1.18+)"
```

## Step 2: Dispatch QA Analyst Agent (Fuzz Mode)

```text
Task tool:
  subagent_type: "ring:qa-analyst"
  prompt: |
    **MODE:** FUZZ TESTING (Gate 4)

    **Standards:** Load testing-fuzz.md

    **Input:**
    - Unit ID: {unit_id}
    - Implementation Files: {implementation_files}
    - Language: {language}

    **Requirements:**
    1. Create fuzz functions (FuzzXxx naming)
    2. Add seed corpus (minimum 5 entries per function)
    3. Run fuzz tests for 30 seconds
    4. Report any crashes found

    **Output Sections Required:**
    - ## Fuzz Testing Summary
    - ## Corpus Report
    - ## Handoff to Next Gate
```

## Step 3: Evaluate Results

```text
Parse agent output:

if "Status: PASS" in output:
  → Gate 4 PASSED
  → Return success with metrics

if "Status: FAIL" in output:
  → Dispatch fix to implementation agent
  → Re-run fuzz tests (max 3 iterations)
  → If still failing: ESCALATE to user
```

## Step 4: Generate Output

```text
## Fuzz Testing Summary
**Status:** {PASS|FAIL}
**Fuzz Functions:** {count}
**Corpus Entries:** {count}
**Crashes Found:** {count}

## Corpus Report
| Function | Entries | Crashes |
|----------|---------|---------|
| {function_name} | {count} | {count} |

## Handoff to Next Gate
- Ready for Gate 5 (Property Testing): {YES|NO}
- Iterations: {count}
```

---

## Severity Calibration

| Severity | Criteria | Examples |
|----------|----------|----------|
| **CRITICAL** | Crash found, security vulnerability discovered | Panic on input, buffer overflow, memory corruption |
| **HIGH** | No fuzz functions, missing corpus | Zero FuzzXxx functions, empty seed corpus |
| **MEDIUM** | Insufficient corpus, naming issues | Less than 5 corpus entries, non-standard function names |
| **LOW** | Coverage gaps, optimization | Missing edge case seeds, fuzz duration improvements |

Report all severities. CRITICAL = immediate fix and re-fuzz. HIGH = fix before gate pass. MEDIUM = fix in iteration. LOW = document.

---

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Unit tests cover edge cases" | You can't test what you don't think of. Fuzz finds unknowns. | **Write fuzz tests** |
| "Code is too simple for fuzz" | Simple code can still crash on malformed input. | **Write fuzz tests** |
| "Fuzz testing is slow" | 30 seconds per function. Crashes in production are slower. | **Write fuzz tests** |
| "We validate input anyway" | Validation can have bugs too. Fuzz tests the validators. | **Write fuzz tests** |

---
