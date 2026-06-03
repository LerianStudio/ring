---
name: ring:using-assert
description: Dual-mode skill for lib-observability/assert — Lerian's production-grade runtime assertion package. Sweep Mode dispatches 6 parallel explorers to find DIY invariant checks, zero-panic violations, hand-rolled domain predicates, and missing metric initialization. Reference Mode catalogs the full API (asserter lifecycle, domain predicates, observability trident, AssertionError unwrapping) and the panic-vs-assert-vs-error decision tree. Skip for non-Go or frontend code.
---

# ring:using-assert

## Moved from lib-commons

The canonical home for this package is now `github.com/LerianStudio/lib-observability/assert`. It lived in `github.com/LerianStudio/lib-commons/v4/commons/assert` and `github.com/LerianStudio/lib-commons/v5/commons/assert` through the v4 and v5 shim period; lib-commons v5 still re-exports every symbol via type aliases and thin wrappers for backward compatibility, but every type and function in `lib-commons/v5/commons/assert` is marked `Deprecated:` and delegates to `lib-observability/assert`. New code MUST import `github.com/LerianStudio/lib-observability/assert`. Existing imports continue to compile during the deprecation window — there are no behavior changes, only an import-path move.

## When to use
Sweep mode:
- "Sweep the codebase for lib-observability/assert opportunities"
- "Audit this service for zero-panic policy compliance"
- "Find panic()/log.Fatal violations"
- "Replace DIY invariant checks with lib-observability/assert"

Reference mode:
- "What's the signature for assert.DebitsEqualCredits?"
- "How do I initialize assertion metrics?"
- "Should I panic, assert, or return an error here?"
- "How do I unwrap AssertionError in a Fiber error handler?"

## Skip when
- Working on non-Go services
- Working on frontend code
- Target codebase is Ring itself

## Related
**Similar:** ring:using-lib-observability, ring:using-runtime
**Compatibility:** ring:using-lib-commons (covers the v5 deprecation shim and re-export aliases)


## Mode Selection

| Request Shape | Mode |
|---|---|
| "Sweep / audit for assert opportunities" | **Sweep** |
| "Find panic()/log.Fatal() violations" | **Sweep** |
| "What's the signature for X?" | **Reference** |
| "Should I panic, assert, or return error?" | **Reference** |

---

# SWEEP MODE

4-phase sweep. Each phase has a hard gate — do not proceed until the current phase produces its artifact.

```
Phase 1: Version Reconnaissance   → assert-version-report.json
Phase 2: CHANGELOG Delta Analysis → assert-delta-report.json
Phase 3: Multi-Angle DIY Sweep    → 6 × assert-sweep-{N}-{angle}.json
Phase 4: Consolidated Report      → assert-sweep-report.md + assert-sweep-tasks.json
```

## Phase 1: Version Reconnaissance

1. Read `go.mod` — extract pinned versions of `github.com/LerianStudio/lib-observability` and (if present) `github.com/LerianStudio/lib-commons/vN`. Either import path is valid: lib-observability is canonical; lib-commons/v5/commons/assert is a deprecation shim that re-exports the same symbols.
2. WebFetch `https://api.github.com/repos/LerianStudio/lib-observability/releases/latest` — extract `tag_name`. Also fetch the lib-commons release tag for shim consumers.
3. Classify drift: up-to-date / minor-drift / moderate-drift / major-upgrade / module-mismatch. Treat "imports lib-commons assert shim" as `module-mismatch` for new code — the recommended migration is to switch the import to `lib-observability/assert`.
4. Emit `/tmp/assert-version-report.json`: `{pinned_observability_version, pinned_commons_version, latest_observability_version, drift_classification, major_upgrade_required, module_path, uses_shim}`

## Phase 2: CHANGELOG Delta Analysis

1. WebFetch `https://raw.githubusercontent.com/LerianStudio/lib-observability/main/CHANGELOG.md`
2. Filter entries between pinned_observability_version and latest_observability_version that affect `assert`
3. Classify: `new-predicate` / `new-method` / `breaking-change` / `security-fix` / `bugfix`
4. Emit `/tmp/assert-delta-report.json`

## Phase 3: Multi-Angle DIY Sweep

### ⛔ STOP-CHECK BEFORE DISPATCH

Before emitting any Task call, count the explorers you intend to launch in this turn.
- Count MUST equal 6.
- If count < 6 → STOP. Do not partial-dispatch. Reconcile against the 6 angles below and try again.
- The 6 angles are the canonical sweep. No substitutions, no omissions.

### ⛔ MUST NOT trickle-dispatch

All 6 explorers leave in the SAME TURN, before reading any explorer output.

Forbidden sequences:
- Dispatch explorer 1 → read result → dispatch explorer 2
- Dispatch a subset → wait → dispatch the rest
- Dispatch follow-up explorers conditioned on partial output
- Loop sequentially over the angle list

If you find yourself about to dispatch an explorer in a turn AFTER any explorer has already returned a result → STOP. You violated parallel dispatch. Report the violation and mark the phase INCOMPLETE rather than completing the trickle.

### Self-verify after dispatch

After the dispatch turn, verify all 6 Task calls were emitted in that single turn. If fewer than 6 went out, the phase did NOT execute correctly. Mark INCOMPLETE and surface the dispatch failure — do NOT silently continue with a partial pool.

### Parallel dispatch — atomic batch

Emit all 6 Task calls in a SINGLE TURN, as one atomic batch.

**If your runtime exposes a `multi_tool_use.parallel` wrapper**, use it to dispatch the complete pool in one wrapped invocation. This is the canonical fan-out mechanism on OpenAI-style tool envelopes and on certain Anthropic SDK consumers — naming it explicitly activates parallel emission on runtimes where trickle-dispatch is the default behavior.

**If your runtime emits parallel tool_use blocks natively** (Claude Code with Claude models), `multi_tool_use.parallel` may not be needed — but naming it is harmless and serves as an enforcement anchor.

The STOP-CHECK, anti-trickle, and self-verify guards above remain binding regardless of which mechanism your runtime uses.

Dispatch all 6 explorer angles in **one parallel batch**. Wait for all before Phase 4.

**Per-explorer dispatch** (`subagent_type: ring:codebase-explorer`):

```
## Target: <absolute path>
## Your Angle: <angle number + name>
## Severity Calibration / DIY Patterns / Replacement / Migration Complexity / Version Context
<verbatim from sub-files/sweep-angles.md for this angle>

## Output
Write to: /tmp/assert-sweep-{N}-{angle-slug}.json
Schema: { angle_number, angle_name, severity, migration_complexity,
  findings: [{file, line, diy_pattern, replacement, evidence_snippet, notes}],
  summary, requires_major_upgrade }
If no findings: write file with empty findings array.
```

Full angle specifications: `sub-files/sweep-angles.md`

The 6 angles cover:
1. `panic()` in non-test code (CRITICAL)
2. Defensive nil/empty checks without metric emission (HIGH)
3. Hand-rolled domain predicates duplicating `assert.*` (HIGH)
4. Missing `InitAssertionMetrics` at startup (HIGH)
5. Financial invariants in tests only, not production (CRITICAL)
6. `AssertionError` not unwrapped in error boundaries (MEDIUM)

## Phase 4: Consolidated Report

Dispatch synthesizer to read all 6 explorer files and emit:
1. `/tmp/assert-sweep-report.md` — aggregate findings by severity
2. `/tmp/assert-sweep-tasks.json` — one task per DIY pattern cluster

Surface report path + task count; offer handoff to `ring:dev-cycle`.

---

# REFERENCE MODE

Full API reference in `sub-files/reference.md`. Load sections relevant to your task.

## Quick Navigation

| # | Section | What you'll find |
|---|---|---|
| 1 | API Surface | Exported symbols, signatures |
| 2 | Asserter Lifecycle | Scoping, naming, anti-patterns |
| 3 | Instance Methods | That / NotNil / NotEmpty / NoError / Never / Halt |
| 4 | Domain Predicate Catalog | Numeric / financial / state-machine / network / time |
| 5 | Composition Pattern | Pure predicates + observable asserter |
| 6 | Observability Trident | Log + span event + metric on every failure |
| 7 | AssertionError Unwrapping | Error boundary patterns |
| 8 | Decision Tree | panic vs assert vs error |
| 9 | Testing Patterns | Proving assertions fire |
| 10 | Anti-Pattern Catalog | Six anti-patterns |
| 11 | Bootstrap Order | InitAssertionMetrics placement |
| 12–14 | Cross-references, Patterns, Breaking Changes | v4→v5 delta |

Read `sub-files/reference.md` for full API detail.
