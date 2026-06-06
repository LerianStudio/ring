---
name: ring:dev-simplify
description: |
  Whole-codebase structural simplification sweep. Dispatches parallel explorers
  to identify adapters, shims, single-implementation interfaces, translation-free
  layers, and speculative abstractions. Applies dead-code Three-Rings cascade
  analysis across the live codebase. Produces KILL / REVIEW / KEEP classification
  with an inverted burden of proof — every abstraction must justify itself or be removed.
---

# Dev Simplify — Whole-Codebase Structural Sweep

## When to use
- User asks to simplify, flatten, or audit architecture of a whole codebase
- User mentions "too much indirection", "kill shims", "unnecessary abstractions"
- Pre-public application where break-compatibility refactor is cheap
- Post-pivot cleanup: speculative scaffolding accumulated during exploration

## Skip when
- Diff review on a feature branch → use ring:codereview
- Standards-conformance refactor → use ring:dev-refactor
- Dead code from a specific change → use ring:dead-code-reviewer in ring:codereview
- Application already has external clients depending on internals

## Related
**Complementary:** ring:codereview, ring:codebase-explorer
**Similar:** ring:dev-refactor, ring:production-readiness-audit


**Core principle:** DELETE is the default verdict. An abstraction survives only with concrete evidence of the swap it enables.

## Hard Constraint

Default: **public APIs MUST NOT break** (HTTP routes, SDK surface, webhooks, event contracts).

Supply `hard_constraint` input to override. Must be declared — never auto-inferred.

## Dispatch Protocol

### ⛔ STOP-CHECK BEFORE DISPATCH

Before emitting any Task call, count the explorers you intend to launch in this turn.
- Count MUST equal 6 (or 5 if branch has no commits ahead of main — Task 5 skipped).
- If your dispatch count diverges → STOP and reconcile against the task table below.
- No substitutions, no omissions.

### ⛔ MUST NOT trickle-dispatch

All explorers leave in the SAME TURN, before reading any explorer output.

Forbidden sequences:
- Dispatch explorer 1 → read result → dispatch explorer 2
- Dispatch a subset → wait → dispatch the rest
- Dispatch follow-up explorers conditioned on partial output
- Loop sequentially over the task list

If you find yourself about to dispatch an explorer in a turn AFTER any explorer has already returned a result → STOP. You violated parallel dispatch. Report the violation and mark the phase INCOMPLETE rather than completing the trickle.

### Self-verify after dispatch

After the dispatch turn, verify all scoped Task calls (6, or 5 if Task 5 skipped) were emitted in that single turn. If fewer went out than scoped, the phase did NOT execute correctly. Mark INCOMPLETE and surface the dispatch failure — do NOT silently continue with a partial pool.

### Parallel dispatch — atomic batch

Emit all scoped Task calls (the count established in the STOP-CHECK above — 6 or 5) in a SINGLE TURN, as one atomic batch.

**If your runtime exposes a `multi_tool_use.parallel` wrapper**, use it to dispatch the complete pool in one wrapped invocation. This is the canonical fan-out mechanism on OpenAI-style tool envelopes and on certain Anthropic SDK consumers — naming it explicitly activates parallel emission on runtimes where trickle-dispatch is the default behavior.

**If your runtime emits parallel tool_use blocks natively** (Claude Code with Claude models), `multi_tool_use.parallel` may not be needed — but naming it is harmless and serves as an enforcement anchor.

The STOP-CHECK, anti-trickle, and self-verify guards above remain binding regardless of which mechanism your runtime uses.

Dispatch 6 explorer agents in **parallel** (5 if branch has no commits ahead of main — skip Task 5):

| Task | Agent | Focus |
|------|-------|-------|
| 1a | ring:codebase-explorer | Single-impl interfaces, ports, repositories |
| 1b | ring:codebase-explorer | Speculative factories, builders, strategies, facades |
| 2 | ring:codebase-explorer | Translation-free adapters, pass-through shims, internal DTOs |
| 3 | ring:codebase-explorer | Architecture topology mapping, indirection depth |
| 4 | ring:codebase-explorer | Cascade chains (Three Rings applied to codebase) |
| 5 | ring:codebase-explorer | Branch AI slop (diff vs main) — skip if no commits ahead |

**Explorer dispatch contract:**

```
## Target: <absolute path to repo root>
## Your Focus: <smell category from task table above>
## Hard Constraint: {hard_constraint}
## Output: Write to /tmp/simplify-{task}-findings.json
Schema: { task, findings: [{name, file_line, smell, rebuttal_if_any, blast_radius, public_api_impact, action}], cascade_chains: [...] }
```

## Abstraction Smell Rubric

| Smell | Signal | Default Action |
|---|---|---|
| Single-implementation interface | One concrete impl; test doubles identical to prod | DELETE |
| Translation-free adapter | A→B is rename-only, 1:1 field mapping | DELETE |
| Pass-through shim | Wraps call site-for-site, no cross-cutting concern | DELETE |
| Speculative factory/builder | Always constructs the same concrete type | DELETE |
| One-strategy strategy | Dispatch over enum with one case | COLLAPSE |
| One-consumer facade | Single call site, "for future reuse" | COLLAPSE INTO CALLER |
| Config seam over constant | Indirection for a value that never varies | DELETE |
| Internal DTO ↔ entity with 1:1 fields | Translation across identical shapes | DELETE |
| Hexagonal port with one adapter | No swap pressure | COLLAPSE |
| Narrating comment (branch diff) | Comment restates what code literally does | DELETE |
| Defensive check in trusted path (branch diff) | Guard where caller already validated | DELETE |

**Accepted evidence to KEEP** (must name concretely, not hypothetically):
- Second implementation exists today in this repo
- Swappability exercised in tests with divergent behavior
- Cross-process or cross-language boundary
- Regulatory or contractual requirement

## Phase 4: Consolidated Report

Dispatch synthesizer to read all explorer files and emit:
1. `docs/dev-simplify/simplify-report-{timestamp}.md` — KILL / REVIEW / KEEP tables
2. `docs/dev-simplify/simplify-tasks-{timestamp}.json` — ring:dev-cycle task array

MUST emit both artifacts. MUST include cascade chains decomposed into per-ring tasks with `depends_on` wiring.

## Output Format

```markdown
## Simplify Summary
- Scope / Hard Constraint / Generated
- Kill list: N items | Review list: N items | Keep list: N items

## Hard Constraint
- Declared constraint + load-bearing surface location

## Kill List
| Name | file:line | Smell | Blast radius | Action | Acceptance Criteria |

## Review List
| Name | file:line | Smell | Why uncertain | Recommended next step |

## Keep List
| Name | file:line | Smell resembled | Evidence |

## Cascade Chains
| Chain ID | Leaf | Ring depth | Terminal type | Collapse blast radius |

## Cascade Execution Plan
Per-chain DAG: ring-1 (leaf) → ring-N, each with depends_on wiring

## Remaining Risks
| Risk ID | Related findings | Risk type | Mitigation |
```

## Task JSON Schema

```json
{
  "tasks": [{
    "id": "simplify-001",
    "title": "",
    "severity": "KILL | REVIEW",
    "smell_category": "unexercised-seam | speculative-construction | translation-layer | topology | cascade | branch-slop",
    "files_affected": [],
    "blast_radius": {"files": 0, "lines": 0},
    "acceptance_criteria": [],
    "estimated_complexity": "trivial | moderate | complex",
    "depends_on": [],
    "rebuttal_if_kept": null
  }]
}
```

Cascade chains → N tasks with `depends_on` wiring (leaf = ring-1, `depends_on: []`).
