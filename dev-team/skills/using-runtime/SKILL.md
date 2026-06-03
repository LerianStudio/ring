---
name: ring:using-runtime
description: Dual-mode skill for lib-observability/runtime — the panic observability trident that turns silent goroutine deaths into production signal. Sweep Mode dispatches 6 parallel explorers to find naked goroutines, unobservable defer recover(), and missing panic-metric init. Reference Mode catalogs the API (SafeGo, RecoverWithPolicy, InitPanicMetrics) and framework integrations (Fiber, gRPC, RabbitMQ). Skip for non-Go or frontend code.
---

# ring:using-runtime

## Moved from lib-commons

The `runtime` package lived in `lib-commons` through v4 and the v5 shim period.
Its canonical home is now **`github.com/LerianStudio/lib-observability/runtime`** (v1.0.0+).
`lib-commons` v5 keeps a deprecated compatibility shim at
`github.com/LerianStudio/lib-commons/v5/commons/runtime` that re-exports every symbol
from lib-observability — existing imports keep compiling, but the shim is marked
`Deprecated:` in package docs and will be removed in a future lib-commons major. New
code MUST import from `lib-observability/runtime` directly; sweeps SHOULD also flag
imports still pointing at the lib-commons shim as a follow-up migration.

## When to use
Sweep mode:
- "Sweep / audit panic handling"
- "Find naked goroutines"
- "Migrate this service to lib-observability/runtime"
- "Are our defer recover() calls observable?"

Reference mode:
- "Which SafeGo variant do I use for X?"
- "How does the observability trident fire on panic?"
- "Show me the policy decision tree"
- "How do I wire runtime into Fiber / gRPC / RabbitMQ?"

## Skip when
- Working on non-Go services
- Working on frontend code

## Related
**Parent:** ring:using-lib-observability (canonical home of the `runtime` package)
**Similar:** ring:using-lib-commons (lifecycle / App glue still lives there), ring:using-assert


Extends `ring:using-lib-observability` panic-handling coverage into 6 focused sub-angles
with deeper detection patterns, full API reference, policy decision tree, and framework integrations.
Also extends `ring:using-lib-commons` Angle 15 (Panic handling DIY) for codebases still
on the v5 shim path. Use when panic handling is the primary concern or when the parent
sweep surfaced significant findings.

## Mode Selection

| Request Shape | Mode |
|---|---|
| "Sweep / audit panic handling / find naked goroutines" | **Sweep** |
| "Which SafeGo variant do I use?" | **Reference** |
| "Policy decision tree" | **Reference** |
| "Framework integration (Fiber/gRPC/RabbitMQ)" | **Reference** |

---

# SWEEP MODE

4-phase sweep. Each phase has a hard gate.

```
Phase 1: Version Reconnaissance   → runtime-version-report.json
Phase 2: CHANGELOG Delta Analysis → runtime-delta-report.json
Phase 3: Multi-Angle DIY Sweep    → 6 × runtime-sweep-{N}-{angle}.json
Phase 4: Consolidated Report      → runtime-sweep-report.md + runtime-sweep-tasks.json
```

## Phase 1: Version Reconnaissance

1. Read `go.mod` — extract pinned version of `github.com/LerianStudio/lib-observability`
   (canonical) AND any pinned `github.com/LerianStudio/lib-commons/vN` (shim path)
2. WebFetch `https://api.github.com/repos/LerianStudio/lib-observability/releases/latest`
   — extract `tag_name` for the canonical library
3. If the target imports `lib-commons/v5/commons/runtime` (deprecated shim), record
   `shim_import_detected: true` — this is itself a follow-up migration finding
4. Classify drift; emit `/tmp/runtime-version-report.json`

## Phase 2: CHANGELOG Delta Analysis

1. WebFetch `https://raw.githubusercontent.com/LerianStudio/lib-observability/main/CHANGELOG.md`
2. Filter entries affecting the `runtime` package
3. If `shim_import_detected` from Phase 1, also WebFetch
   `https://raw.githubusercontent.com/LerianStudio/lib-commons/main/CHANGELOG.md` and
   filter for `commons/runtime` shim-deprecation entries
4. Emit `/tmp/runtime-delta-report.json`

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
## Severity / DIY Patterns / Replacement / Migration Complexity / Version Context
<verbatim from sub-files/sweep-angles.md for this angle>

## Output
Write to: /tmp/runtime-sweep-{N}-{angle-slug}.json
Schema: { angle_number, angle_name, severity, migration_complexity,
  findings: [{file, line, diy_pattern, replacement, evidence_snippet, notes}],
  summary, requires_major_upgrade }
If no findings: write file with empty findings array.
```

Full angle specifications: `sub-files/sweep-angles.md`

The 6 angles cover:
1. Naked goroutine launches (CRITICAL)
2. Unobservable `defer recover()` (CRITICAL)
3. Missing `InitPanicMetrics` at startup (HIGH)
4. Missing `SetProductionMode(true)` in production (HIGH)
5. Framework panic handlers bypassing `HandlePanicValue` (HIGH)
6. Policy mismatch — KeepRunning vs CrashProcess (MEDIUM)

## Phase 4: Consolidated Report

Dispatch synthesizer to read all 6 files and emit:
1. `/tmp/runtime-sweep-report.md`
2. `/tmp/runtime-sweep-tasks.json`

Surface report path + task count; offer handoff to `ring:dev-cycle`.

---

# REFERENCE MODE

Full API reference in `sub-files/reference.md`. Load sections relevant to your task.

## Quick Navigation

| # | Section | What you'll find |
|---|---|---|
| 1 | API Surface | SafeGo / RecoverWithPolicy / HandlePanicValue / Init / SetProductionMode |
| 2 | Policy Decision Tree | KeepRunning vs CrashProcess |
| 3 | Pattern Catalog | Consumer loops, fan-out, tickers, Fiber/gRPC/RabbitMQ |
| 4 | Observability Trident | Log + span event + metric on panic |
| 5 | Testing Patterns | Proving recovery fires |
| 6 | Anti-Pattern Catalog | Six failure modes |
| 7 | Bootstrap Order | Where runtime setup fits in init |
| 8–10 | Cross-Cutting, Breaking Changes, Cross-References | v4→v5 delta |

Read `sub-files/reference.md` for full API detail.
