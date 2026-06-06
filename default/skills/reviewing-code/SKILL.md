---
name: ring:reviewing-code
description: "Reviewing code by dispatching the default reviewer subagents in parallel (plus conditional specialists for lib-observability, lib-systemplane, or lib-streaming when the diff triggers them), then aggregating findings by severity into a report. Use as Gate 8 of ring:running-dev-cycle at epic cadence over the cumulative diff, or before merging. Report-only. Skip for a single-command Go pre-merge verdict (use ring:verifying-code)."
---

# Code Review (Gate 8)

## When to use
- Gate 8 of development cycle
- After completing major feature implementation
- Before merge to main branch
- After completing complex bug work

## Skip when
- Task is purely conversational or informational with no code changes
- Changes are limited to documentation or comments with zero logic modifications
- Code has not been modified since the last completed review cycle

## Sequence
**Runs after:** ring:implementing-tasks
**Runs before:** ring:validating-acceptance-criteria

## Related
**Complementary:** ring:running-dev-cycle, ring:implementing-tasks

Dispatch the 9 default reviewer subagents in **parallel**, plus any triggered conditional specialists. Dispatch count is dynamic: 9 + triggered specialists, max 12. Do not say or imply all 12 always dispatch.

**Announce at start:** "Using ring:reviewing-code to dispatch 9 default reviewers plus triggered conditional specialists."

**Report-only boundary:** This skill does not remediate findings, dispatch implementation work, write comments into source files, generate external artifacts, invoke secondary review tools, or re-run reviewers automatically. It only dispatches the selected reviewers once and reports their findings in the current session.

## Default Reviewers (Hard Gate)

| # | Agent | Focus |
|---|-------|-------|
| 1 | `ring:code-reviewer` | Architecture, design patterns, code quality |
| 2 | `ring:logic-reviewer` | Domain correctness, business rules, edge cases |
| 3 | `ring:security-reviewer` | Vulnerabilities, authentication, OWASP risks |
| 4 | `ring:test-reviewer` | Test quality, coverage, edge cases, anti-patterns |
| 5 | `ring:nil-reviewer` | Nil/null pointer safety for Go and TypeScript |
| 6 | `ring:dead-code-reviewer` | Orphaned code detection, reachability analysis |
| 7 | `ring:perf-reviewer` | Performance hotspots, allocations, goroutine leaks, N+1 |
| 8 | `ring:tenancy-reviewer` | Multi-tenant patterns, tenantId propagation, DB isolation |
| 9 | `ring:commons-reviewer` | lib-commons package usage and reinvented-wheel opportunities |

Base hard gate: all 9 default reviewers must PASS.

## Conditional Specialist Reviewers

Run these only when the diff matches their trigger. If triggered, include the specialist in aggregation and require PASS for overall PASS.

| Agent | Trigger |
|-------|---------|
| `ring:obs-reviewer` | Diff touches tracing, metrics, logging, runtime recovery/panic safety, redaction, observability constants, or goroutines with recover/SafeGo implications. |
| `ring:systemplane-reviewer` | Diff touches runtime config, hot-reload knobs, admin config surface, tenant-scoped settings, or systemplane imports/config. |
| `ring:streaming-reviewer` | Diff touches business events, outbox, event producers, broker publishing, CloudEvents, or event manifests/catalogs. |

## Role Clarification

| Who | Responsibility |
|-----|----------------|
| **This Skill** | Select triggered specialists, dispatch reviewers once, aggregate findings, report all severities in-session |
| **Reviewer Agents** | Analyze code, report issues with severity |

## Step 1: Gather Context (Auto-Detect if Not Provided)

Auto-detect: `unit_id` (generate if missing), `base_sha` (git merge-base HEAD main), `head_sha` (git rev-parse HEAD), `implementation_files` (git diff --name-only), `implementation_summary` (git log --oneline).

Display context banner before dispatching.

## Step 2: Select Reviewers and Initialize Review State

Start with the 9 default reviewers. Inspect changed files and diff content to decide which conditional specialists are triggered. Track unit_id, base/head SHA, selected reviewer list, reviewer verdicts, and aggregated issues by severity: Critical, High, Medium, Low.

## Step 3: Dispatch Selected Reviewers in Parallel

### STOP-CHECK BEFORE DISPATCH

Before emitting any Task call, count the reviewers you intend to launch in this turn.
- Count MUST equal `9 + triggered_specialists`.
- Count MUST be at least 9 and at most 12.
- If count < 9 or count does not include every triggered specialist -> STOP. Reconcile against the default reviewer table and trigger table above.

### MUST NOT trickle-dispatch

All selected reviewers leave in the SAME TURN, before reading any reviewer output.

Forbidden sequences:
- Dispatch reviewer 1 -> read result -> dispatch reviewer 2
- Dispatch a subset -> wait -> dispatch the rest
- Dispatch conditional specialists after partial reviewer output
- Loop sequentially over the reviewer list

If you find yourself about to dispatch a reviewer in a turn AFTER any reviewer has already returned a result -> STOP. You violated parallel dispatch. Report the violation to the user and mark the gate INCOMPLETE rather than completing the trickle.

### Self-verify after dispatch

After the dispatch turn, verify all selected Task calls were emitted in that single turn. If fewer than selected reviewers went out, the gate did NOT execute correctly. Mark the run INCOMPLETE and surface the dispatch failure.

### Parallel dispatch — atomic batch

Emit all selected Task calls in a SINGLE TURN, as one atomic batch.

If your runtime exposes a `multi_tool_use.parallel` wrapper, use it to dispatch the complete selected pool in one wrapped invocation. The STOP-CHECK, anti-trickle, and self-verify guards remain binding regardless of runtime.

Read `reviewers/dispatch-prompts.md` for the prompt templates. Inject:
- Epic-level scope header (when `scope=epic`)
- `base_sha` / `head_sha` from cumulative_diff_range when epic-level
- Ring standards slice (cache-first per `shared-patterns/standards-cache-protocol.md`)
- Explicit instruction that reviewers must report findings only and must not modify files

## Step 4: Wait and Parse Output

Parse `VERDICT` and Issues for all selected reviewers. Normalize every issue into one of four severity buckets: Critical, High, Medium, Low.

For each issue, preserve:
- Severity
- Title or short description
- File:line when provided
- Reviewer
- Evidence or reasoning
- Recommendation

If a reviewer returns `COSMETIC`, map it to Low.

## Step 5: Report Results In Session

Produce a detailed Markdown report in the current session. The report must include all Critical, High, Medium, and Low issues.

Do not dispatch any follow-up agent to remediate findings. Do not edit files. Do not create reports on disk. Do not open a browser. Report back only.

## Completion Rules

- Complete after all selected reviewer outputs are collected and summarized.
- `PASS` means all 9 default reviewers completed with zero issues, and every triggered specialist also completed with zero issues.
- `ISSUES_FOUND` means at least one Critical, High, Medium, or Low issue was reported by any selected reviewer.
- `INCOMPLETE` means one or more selected reviewers did not return a parseable result.
- Low issues are still reported; never omit them from the session report.
- No automatic remediation, source-file changes, reviewer reruns, external artifacts, or secondary validation tools are part of this skill.

## Red Flags — STOP

- You are about to dispatch any non-reviewer agent.
- You are about to edit source files.
- You are about to create or open a separate report artifact.
- You are about to invoke a secondary review or validation tool.
- You are about to re-run reviewers without an explicit new user request.

All of these mean: stop and produce the session report instead.

## Output Format

```markdown
## Review Summary
**Status:** [PASS|ISSUES_FOUND|INCOMPLETE]
**Unit ID:** [unit_id]
**Base:** [base_sha]
**Head:** [head_sha]
**Scope:** [epic|branch|provided]
**Reviewers Dispatched:** [9-12]
**Conditional Specialists Triggered:** [none|list]

## Issues by Severity
| Severity | Count |
|----------|-------|
| Critical | N |
| High     | N |
| Medium   | N |
| Low      | N |

## Critical Issues
[List every Critical issue. If none: None.]

| Issue | File:Line | Reviewer | Evidence | Recommendation |
|-------|-----------|----------|----------|----------------|
| [actual issue description] | [file:line] | [ring:xxx-reviewer] | [why it matters] | [recommended action] |

## High Issues
[List every High issue. If none: None.]

## Medium Issues
[List every Medium issue. If none: None.]

## Low Issues
[List every Low issue. If none: None.]

## Reviewer Verdicts
| Reviewer | Verdict | Issues |
|----------|---------|--------|
| ring:code-reviewer | PASS/FAIL/INCOMPLETE | N |
[...selected reviewer rows]

## Report Boundary
No files were changed. No remediation agents were dispatched. No external report artifacts were generated.
```
