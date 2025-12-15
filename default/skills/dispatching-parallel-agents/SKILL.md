---
name: ring-default:dispatching-parallel-agents
description: |
  Concurrent investigation pattern - dispatches multiple AI agents to investigate
  and fix independent problems simultaneously.

trigger: |
  - 3+ failures in different test files/subsystems
  - Problems are independent (no shared state)
  - Each can be investigated without context from others

skip_when: |
  - Failures are related/connected → single investigation
  - Shared state between problems → sequential investigation
  - <3 failures → investigate directly
---

# Dispatching Parallel Agents

## Overview

When you have multiple unrelated failures (different test files, different subsystems, different bugs), investigating them sequentially wastes time. Each investigation is independent and can happen in parallel.

**Core principle:** Dispatch one agent per independent problem domain. Let them work concurrently.

## When to Use

**Decision flow:** Multiple failures? → Are they independent? (No → single agent) | Independent? → Can work in parallel? (No/shared state → sequential) | Yes → **Parallel dispatch**

**Use when:** 3+ test files with different root causes | Multiple subsystems broken independently | Each problem understood without others | No shared state

**Don't use when:** Failures related (fix one might fix others) | Need full system state | Agents would interfere

## The Pattern

**1. Identify Independent Domains:** Group failures by what's broken (File A: approval flow, File B: batch behavior, File C: abort). Each domain independent.

**2. Create Focused Agent Tasks:** Each agent gets: specific scope (one file/subsystem), clear goal (make tests pass), constraints (don't change other code), expected output (summary of findings/fixes).

**3. Dispatch in Parallel:** `Task("Fix agent-tool-abort.test.ts")` + `Task("Fix batch-completion.test.ts")` + `Task("Fix tool-approval-races.test.ts")` - all concurrent.

**4. Review and Integrate:** Read summaries → verify no conflicts → run full test suite → integrate all changes.

## Agent Prompt Structure

Good prompts are: **Focused** (one problem domain), **Self-contained** (all context included), **Specific output** (what to return).

**Example:** "Fix 3 failing tests in agent-tool-abort.test.ts: [list tests + expected behavior]. Timing/race issues. Read tests → identify root cause → fix (event-based waiting, not timeout increases). Return: Summary of findings and fixes."

## Common Mistakes

| ❌ Bad | ✅ Good |
|--------|---------|
| Too broad: "Fix all tests" | Specific: "Fix agent-tool-abort.test.ts" |
| No context: "Fix race condition" | Context: Paste error messages + test names |
| No constraints: Agent refactors everything | Constraints: "Do NOT change production code" |
| Vague output: "Fix it" | Specific: "Return summary of root cause and changes" |

## When NOT to Use

Related failures (fix one might fix others) | Need full context | Exploratory debugging | Shared state (same files/resources)

## Real Example

**Scenario:** 6 failures across 3 files after refactoring.
**Decision:** Independent domains → parallel dispatch.
**Results:** Agent 1 (timeouts → events), Agent 2 (event structure bug), Agent 3 (async wait). All independent, no conflicts, suite green. **3 problems solved in time of 1.**

## Key Benefits

**Parallelization** (simultaneous) | **Focus** (narrow scope) | **Independence** (no interference) | **Speed** (3 → 1 time unit)

## Verification

After agents return: Review summaries → check for conflicts → run full suite → spot check for systematic errors.
