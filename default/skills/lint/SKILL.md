---
name: ring:lint
description: |
  Parallel lint fixing pattern - runs lint checks, groups issues into independent
  streams, and dispatches AI agents to fix all issues until the codebase is clean.
---

# Linting Codebase

## When to use
- User runs /ring:lint command
- Codebase has lint issues that need fixing
- Multiple lint errors across different files/components

## Skip when
- Single lint error → fix directly without agent dispatch
- Lint already passes → nothing to do
- User only wants to see lint output, not fix

Run lint checks, group issues into independent streams, dispatch parallel agents, iterate until clean.

## ⛔ Critical Constraints (communicate to ALL dispatched agents)

- DO NOT create automated scripts to fix lint issues
- DO NOT create documentation or README files
- DO NOT add comments explaining the fixes
- Fix each issue directly by editing source code
- Minimal changes — only what's needed for lint

## Phase 1: Run Lint

**Detect command:** `make lint` → `npm run lint` → `yarn lint` → `pnpm lint` → `golangci-lint run` → `cargo clippy` → `ruff check .` → `eslint .`

```bash
<lint_command> 2>&1 | tee /tmp/lint-output.txt; echo "EXIT_CODE: ${PIPESTATUS[0]}"
```

If `EXIT_CODE` is non-zero, lint failed. Report failure clearly before proceeding to grouping.

Parse: file path, line:column, error code/rule, message, severity.

## Phase 2: Group into Streams

| Issue Count | Grouping Strategy |
|-------------|-------------------|
| < 10 | By file |
| 10-50 | By directory |
| 50-100 | By error type/rule |
| > 100 | By component/module |

A stream is independent if: files don't import each other, fixes won't conflict, agents can work without knowledge of other streams.

## Phase 3: Parallel Agent Dispatch

### ⛔ STOP-CHECK BEFORE DISPATCH

Before emitting any Task call, count the agents you intend to launch in this turn.
- Count MUST equal the number of independent streams you identified in Phase 2.
- If your dispatch count diverges from your stream count → STOP and reconcile against the Phase 2 grouping.
- One agent per stream. No substitutions, no omissions.

### ⛔ MUST NOT trickle-dispatch

All stream agents leave in the SAME TURN, before reading any agent output.

Forbidden sequences:
- Dispatch agent 1 → read result → dispatch agent 2
- Dispatch a subset → wait → dispatch the rest
- Dispatch follow-up agents conditioned on partial output
- Loop sequentially over the stream list

If you find yourself about to dispatch a stream agent in a turn AFTER any agent has already returned a result → STOP. You violated parallel dispatch. Report the violation and mark the phase INCOMPLETE rather than completing the trickle. (The verification loop in Phase 4 may dispatch a fresh round; that round is itself bound by the same rule.)

### Self-verify after dispatch

After the dispatch turn, verify all stream Task calls were emitted in that single turn. If fewer went out than scoped streams, the phase did NOT execute correctly. Mark INCOMPLETE and surface the dispatch failure — do NOT silently continue with a partial pool.

### Parallel dispatch — atomic batch

Emit all scoped Task calls (the count established in the STOP-CHECK above) in a SINGLE TURN, as one atomic batch.

**If your runtime exposes a `multi_tool_use.parallel` wrapper**, use it to dispatch the complete pool in one wrapped invocation. This is the canonical fan-out mechanism on OpenAI-style tool envelopes and on certain Anthropic SDK consumers — naming it explicitly activates parallel emission on runtimes where trickle-dispatch is the default behavior.

**If your runtime emits parallel tool_use blocks natively** (Claude Code with Claude models), `multi_tool_use.parallel` may not be needed — but naming it is harmless and serves as an enforcement anchor.

The STOP-CHECK, anti-trickle, and self-verify guards above remain binding regardless of which mechanism your runtime uses.

**Single turn with multiple Task calls** — one `ring:general-purpose` agent per stream.

Each agent receives: scope (files/dirs), issues (file:line:col + message), constraints (from above).

Dispatch when: 3+ files have issues, issues are in independent areas, fixes are mechanical.

Skip dispatch when: single file → fix directly, issues require architectural decisions, fixes would break things.

## Phase 4: Verification Loop (max 5 iterations)

Re-run lint after all agents complete:

| Result | Action |
|--------|--------|
| Lint passes | ✅ Done |
| Same issues remain | ⚠️ Investigate why fixes failed |
| New issues appeared | 🔄 Analyze + dispatch new agents |
| Fewer issues remain | 🔄 New streams, repeat |

After 5 iterations: report remaining issues and ask user.

## Output

**Success:** Initial issues, streams processed, agents dispatched, iterations, all pass, changes by stream.

**Partial:** Remaining issues with reasons (e.g., requires external types, intentional usage), recommended actions.

## Agent Selection

| Issue Type | Agent |
|------------|-------|
| TypeScript/JavaScript | `ring:general-purpose` |
| Go | `ring:backend-engineer-golang` |
| Security lints | `ring:security-reviewer` for report/analysis only — security findings are **not auto-fixed**; escalate to human review |
| Style/formatting | `ring:general-purpose` |
