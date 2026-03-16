---
name: linting-codebase
description: |
  Parallel lint fixing pattern - runs lint checks, groups issues into independent
  streams, and dispatches AI agents to fix all issues until the codebase is clean.
metadata:
  skip_when: |-
    - Single lint error → fix directly without agent dispatch
    - Lint already passes → nothing to do
    - User only wants to see lint output, not fix
  trigger: |
    - User runs /ring:lint command
    - Codebase has lint issues that need fixing
    - Multiple lint errors across different files/components
---

# Linting Codebase

## Overview

This skill runs lint checks on the codebase, analyzes the results to identify independent fix streams, and dispatches parallel AI agents to fix all issues. The process iterates until the codebase passes all lint checks.

**Core principle:** Group lint issues by file/component, dispatch one agent per independent stream, iterate until clean.

## ⛔ CRITICAL CONSTRAINTS

These constraints are NON-NEGOTIABLE and must be communicated to ALL dispatched agents:

```
┌─────────────────────────────────────────────────────────────────┐
│  🚫 DO NOT CREATE AUTOMATED SCRIPTS TO FIX LINT ISSUES         │
│  🚫 DO NOT CREATE DOCUMENTATION OR README FILES                 │
│  🚫 DO NOT ADD COMMENTS EXPLAINING THE FIXES                   │
│  ✅ FIX EACH ISSUE DIRECTLY BY EDITING THE SOURCE CODE         │
│  ✅ MAKE MINIMAL CHANGES - ONLY WHAT'S NEEDED FOR LINT         │
└─────────────────────────────────────────────────────────────────┘
```

## Phase 1: Lint Execution

### Step 1.1: Detect Lint Command

Priority: `make lint` → `npm run lint` → `yarn lint` → `pnpm lint` → `golangci-lint run` → `cargo clippy` → `ruff check .` → `eslint .`

### Step 1.2: Run Lint

`<lint_command> 2>&1 | tee /tmp/ring:lint-output.txt && echo "EXIT_CODE: $?"`

### Step 1.3: Parse Results

Extract: file path, line:column, error code/rule, message, severity (error/warning).

## Phase 2: Stream Analysis

### Step 2.1: Group Issues

Group lint issues into independent streams that can be fixed in parallel:

**Grouping strategies (choose based on issue count):**

| Issue Count | Grouping Strategy |
|-------------|-------------------|
| < 10 issues | Group by file |
| 10-50 issues | Group by directory |
| 50-100 issues | Group by error type/rule |
| > 100 issues | Group by component/module |

### Step 2.2: Identify Independence

A stream is independent if: files don't import/depend on each other, fixes won't conflict, agents can work without knowledge of other streams.

### Step 2.3: Create Stream Summary

Output format: Total issues, Streams (path, issue types, count, independence status), Recommended agents (one per stream).

## Phase 3: Parallel Agent Dispatch

### Step 3.1: Prepare Agent Prompts

Each agent receives: **Scope** (files/directories), **Issues** (file:line:col + message), **Constraints** (from Critical Constraints above), **Output** (files modified, issues fixed, issues unable to fix with reasons).

### Step 3.2: Dispatch Agents in Parallel

**CRITICAL: Single message with multiple Task tool calls** - one `general-purpose` agent per stream.

### Step 3.3: Await All Agents

Wait for all dispatched agents to complete before proceeding.

## Phase 4: Verification Loop

### Step 4.1: Re-run Lint

After all agents complete, run `<lint_command> 2>&1`.

### Step 4.2: Evaluate Results

| Result | Action |
|--------|--------|
| **Lint passes** | ✅ Done |
| **Same issues remain** | ⚠️ Investigate why fixes failed |
| **New issues appeared** | 🔄 Analyze + dispatch new agents |
| **Fewer issues remain** | 🔄 Create new streams, repeat |

### Step 4.3: Iterate If Needed

**Maximum iterations:** 5. If issues persist: report remaining, ask user, investigate (lint conflicts, auto-fix impossible).

## Agent Dispatch Rules

### DO dispatch when:
- 3+ files have lint issues
- Issues are in independent areas
- Fixes are mechanical (unused vars, formatting, etc.)

### DO NOT dispatch when:
- Single file has issues → fix directly
- Issues require architectural decisions
- Fixes would cause breaking changes

### Agent selection:

| Issue Type | Agent Type |
|------------|------------|
| TypeScript/JavaScript | `general-purpose` |
| Go | `general-purpose` or `ring:backend-engineer-golang` |
| Security lints | `ring:security-reviewer` for analysis first |
| Style/formatting | `general-purpose` |

## Output Format

**Success:** Initial issues, Streams processed, Agents dispatched, Iterations, Final status (all pass), Changes by stream (files, issues fixed).

**Partial:** Initial/fixed/remaining issues, Iterations (max reached), Remaining issues with reasons (e.g., requires external types, intentional usage), Recommended actions (manual review, lint exceptions, type definitions).

## Error Handling

| Error | Response |
|-------|----------|
| **Lint command not found** | Ask user to specify command |
| **Agent failure** | Options: retry stream, skip, investigate manually |
| **Conflicting changes** | Report file + lines, ask user to merge manually |

## Integration with Other Skills

| Skill | When to use |
|-------|-------------|
| `ring:dispatching-parallel-agents` | Pattern basis for this skill |
| `ring:systematic-debugging` | If lint errors indicate deeper issues |
| `ring:requesting-code-review` | After lint passes, before merge |

## Example Session

`/ring:lint` → Run lint → 16 issues in 3 areas → Analyze streams (API: 5, Services: 8, Utils: 3) → Dispatch 3 parallel agents → All complete → Re-run lint → ✅ All pass.

## Blocker Criteria

STOP and report if:

| Decision Type | Blocker Condition | Required Action |
|---|---|---|
| Lint Command | No lint command found (make lint, npm run lint, etc.) | STOP and ask user to specify lint command |
| Agent Dispatch | Unable to launch parallel agents for fix streams | STOP and report infrastructure issue |
| Max Iterations | 5 iterations completed without lint passing | STOP and report remaining issues - manual intervention needed |
| Conflicting Changes | Multiple agents edited same file with conflicts | STOP and report conflicts for manual merge |

### Cannot Be Overridden

The following requirements CANNOT be waived:
- MUST NOT create automated scripts to fix lint issues - direct source code edits only
- MUST NOT create documentation or README files during lint fixing
- MUST NOT add comments explaining the fixes - minimal changes only
- CANNOT skip re-verification after agent fixes - lint must be re-run

## Severity Calibration

| Severity | Condition | Required Action |
|---|---|---|
| CRITICAL | Lint errors indicate security vulnerabilities | MUST fix immediately and flag for security review |
| HIGH | Lint errors in production code paths | MUST fix before completing |
| MEDIUM | Lint warnings in non-critical code | Should fix in current iteration |
| LOW | Style-only lint issues | Fix if time permits |

## Pressure Resistance

| User Says | Your Response |
|---|---|
| "Just disable the lint rules that are failing" | "CANNOT disable lint rules to pass. I MUST fix the actual issues - disabling rules hides real problems." |
| "Write a script to auto-fix everything" | "CANNOT create automated scripts. I MUST make direct source code edits only - scripts can introduce unexpected changes." |
| "Skip the verification loop, the fixes should work" | "MUST re-run lint after all agent fixes. 'Should work' is not verification - actual lint output is required." |

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|---|---|---|
| "Creating a fix script is more efficient" | Scripts can cause unintended side effects. Direct edits are traceable and reversible. | **MUST make direct source code edits only** |
| "This lint rule is too strict, disable it" | Lint rules exist for reasons. Disabling hides real issues instead of fixing them. | **MUST fix issues, not disable rules** |
| "Agent fixed 15/16 issues, close enough" | Partial completion is not completion. All lint issues must be resolved or reported. | **MUST iterate until lint passes or max iterations reached** |
| "Adding explanatory comments helps future devs" | Scope is lint fixing only. Comments add noise and change file semantics. | **MUST NOT add comments - minimal changes only** |
