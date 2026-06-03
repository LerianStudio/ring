---
name: ring:using-lib-commons
description: Dual-mode skill for github.com/LerianStudio/lib-commons v5, Lerian's shared Go library — the non-observability surface. Sweep Mode dispatches parallel explorers to detect DIY implementations that should use lib-commons, with file:line replacement precision. Reference Mode catalogs lib-commons packages for lifecycle (Launcher), outbox repository, circuit breakers, tenant management, idempotency, security/TLS, database, messaging, HTTP toolkit. Observability (log, metrics, tracing, assertions, panic recovery, redaction) moved out of lib-commons into lib-observability v1.0.0 — see [[using-lib-observability]] and its sub-skills [[using-tracing]], [[using-runtime]], [[using-assert]]. Skip for non-Go code or Ring itself.
---

# ring:using-lib-commons

> **Scope note (lib-observability v1.0.0):** The observability layer — `log`, `metrics`, `tracing`, `zap`, `assert`, `runtime` (panic recovery), `redaction`, and OTel attribute constants — **moved out of lib-commons into `github.com/LerianStudio/lib-observability`** as of v1.0.0. lib-commons v5 keeps deprecated shims for back-compat, but this skill is no longer the canonical reference for those packages. For observability work, dispatch [[using-lib-observability]] (top-level) or its dedicated sub-skills [[using-tracing]] / [[using-runtime]] / [[using-assert]]. This skill now focuses on lib-commons's non-observability surface: lifecycle (`commons.Launcher`), outbox repository (writer side lives in [[using-lib-streaming]]), circuit breakers, tenant management, idempotency, security/TLS, database connections, messaging (RabbitMQ command queues; events go through [[using-lib-streaming]]), HTTP toolkit.

## When to use
Sweep mode:
- "Sweep the codebase for lib-commons opportunities"
- "Find where we could use lib-commons instead of DIY"
- "Audit this service for lib-commons compliance"
- "Identify lib-commons migration opportunities"

Reference mode:
- Need to understand what lib-commons provides
- Looking for the right package/API for a task
- Setting up a new service that uses lib-commons
- Need correct constructor/initialization patterns
- Working with multi-tenancy (tenant-manager subsystem)
- Working with event-driven tenant discovery

## Skip when
- Working on non-Go services
- Working on frontend code
- Target codebase is Ring itself (no lib-commons dependency)

## Related
**Similar:** ring:using-dev-team, ring:dev-refactor
**Observability layer (moved to lib-observability):** [[using-lib-observability]], [[using-tracing]], [[using-runtime]], [[using-assert]]
**Adjacent libs:** [[using-outbox]], [[using-lib-streaming]], [[using-lib-systemplane]]


## Mode Selection

| Request Shape | Mode |
|---|---|
| "Sweep / audit / find opportunities / migrate to lib-commons" | **Sweep** |
| "What does lib-commons provide for X?" | **Reference** |
| "How do I initialize Y from lib-commons?" | **Reference** |
| "Replace our DIY webhook delivery with lib-commons" | **Sweep** |

---

# SWEEP MODE

Orchestrate a 4-phase sweep. Each phase has a hard gate — do not proceed until the current phase produces its artifact.

```
Phase 1: Version Reconnaissance   → version-report.json
Phase 2: CHANGELOG Delta Analysis → delta-report.json
Phase 3: Multi-Angle DIY Sweep    → 22 × libcommons-sweep-{N}-{angle}.json
Phase 4: Consolidated Report      → libcommons-sweep-report.md + tasks.json
```

## Phase 1: Version Reconnaissance

1. Read `go.mod` — extract pinned version of `github.com/LerianStudio/lib-commons/vN`
2. WebFetch `https://api.github.com/repos/LerianStudio/lib-commons/releases/latest` — extract `tag_name`
3. Classify drift: up-to-date / minor-drift / moderate-drift / major-upgrade / module-mismatch
4. If v4.x detected: add major upgrade advisory flag
5. Emit `version-report.json`: `{pinned_version, latest_version, drift_classification, major_upgrade_required, module_path}`

## Phase 2: CHANGELOG Delta Analysis

1. WebFetch `https://raw.githubusercontent.com/LerianStudio/lib-commons/main/CHANGELOG.md`
2. Extract entries between pinned_version (exclusive) and latest_version (inclusive)
3. Classify each: `new-package` / `new-api` / `breaking-change` / `security-fix` / `performance` / `bugfix`
4. Emit `delta-report.json` with classified entries

## Phase 3: Multi-Angle DIY Sweep

Dispatch all 22 explorer angles in **3 batches** (8+8+6). Wait for each batch before next.

| Batch | Angles | Focus |
|---|---|---|
| 1 | 1–8 | Infrastructure + HTTP |
| 2 | 9–16 | Ergonomics + security + observability-shim detection |
| 3 | 17–22 | Resilience + multi-tenant + utilities |

### ⛔ STOP-CHECK BEFORE DISPATCH (each batch)

Before emitting any Task call in a batch, count the explorers you intend to launch in this turn.
- Count MUST equal the batch size declared above (8, 8, or 6).
- If your dispatch count diverges from the batch size → STOP and reconcile against the batch row.
- No substitutions, no omissions within a batch.

### ⛔ MUST NOT trickle-dispatch within a batch

All explorers in a batch leave in the SAME TURN, before reading any explorer output.

Forbidden sequences:
- Dispatch explorer 1 → read result → dispatch explorer 2
- Dispatch a subset of the batch → wait → dispatch the rest
- Dispatch follow-up explorers conditioned on partial output
- Loop sequentially over the batch's angle list

If you find yourself about to dispatch an explorer in a turn AFTER any explorer in the SAME batch has already returned a result → STOP. You violated parallel dispatch. Report the violation and mark the batch INCOMPLETE rather than completing the trickle. (Sequential batch ordering is intentional; trickle within a batch is not.)

### Self-verify after dispatch

After each batch's dispatch turn, verify all batched Task calls were emitted in that single turn. If fewer went out than the batch size, the batch did NOT execute correctly. Mark INCOMPLETE and surface the dispatch failure — do NOT silently continue with a partial batch.

### Parallel dispatch — atomic batch (within this batch)

Emit all Task calls for THIS BATCH in a SINGLE TURN, as one atomic batch. (Batches themselves remain sequential — do not dispatch batch N+1 until batch N has fully returned.)

**If your runtime exposes a `multi_tool_use.parallel` wrapper**, use it to dispatch the complete batch in one wrapped invocation. This is the canonical fan-out mechanism on OpenAI-style tool envelopes and on certain Anthropic SDK consumers — naming it explicitly activates parallel emission on runtimes where trickle-dispatch is the default behavior.

**If your runtime emits parallel tool_use blocks natively** (Claude Code with Claude models), `multi_tool_use.parallel` may not be needed — but naming it is harmless and serves as an enforcement anchor.

The STOP-CHECK, anti-trickle, and self-verify guards above remain binding regardless of which mechanism your runtime uses.

> **Observability angles (14, 15, 16) — scope shift:** these angles still run as part of this sweep, but their **detection logic now targets deprecated lib-commons shim imports** in addition to raw DIY. The canonical replacement is `lib-observability/*`, NOT `commons/zap`, `commons/runtime`, `commons/assert`. For a deep, dedicated audit of the observability layer, dispatch [[using-lib-observability]] (top-level) or [[using-tracing]] / [[using-runtime]] / [[using-assert]] instead — those produce richer findings than the breadth-first single-angle sweep here.

**Per-explorer dispatch** (`subagent_type: ring:codebase-explorer`):

```
## Target
<absolute path to target repo root>

## Your Angle
<angle number + name>

## Severity Calibration / DIY Patterns / Replacement / Migration Complexity / Version Context
<verbatim from sub-files/sweep-angles.md for this angle>

## Output
Write findings to: /tmp/libcommons-sweep-{N}-{angle-slug}.json
Schema: { angle_number, angle_name, severity, migration_complexity, findings: [{file, line, diy_pattern, replacement, evidence_snippet, notes}], summary, requires_major_upgrade }
If no findings: write file with empty findings array and summary "No DIY patterns detected for this angle".
```

Full angle specifications: `sub-files/sweep-angles.md`

## Phase 4: Consolidated Report

Dispatch synthesizer (`subagent_type: ring:codebase-explorer`):

```
Read /tmp/version-report.json, /tmp/delta-report.json, /tmp/libcommons-sweep-*.json (22 files).
Emit:
1. /tmp/libcommons-sweep-report.md — aggregate findings by severity
2. /tmp/libcommons-sweep-tasks.json — one task per DIY pattern cluster (same file/package = one task)

MUST NOT invent findings. MUST NOT omit explorer findings. MUST NOT reclassify severity without justification.
```

Surface report path + task count to user; offer handoff to `ring:dev-cycle`.

---

# REFERENCE MODE

Full API catalog in `sub-files/reference.md`. Load the relevant sections for your current task.

## Quick Navigation

| # | Section | What you'll find |
|---|---|---|
| 1 | Package Catalog | All packages by domain |
| 2 | Common Initialization Pattern | Typical service bootstrap |
| 3 | Database Connections | postgres, mongo, redis, rabbitmq |
| 4 | HTTP Toolkit | Middleware, rate limiting, pagination, idempotency |
| 5 | Observability *(moved)* | Logger, tracing, metrics, runtime, assert — now in [[using-lib-observability]] |
| 6 | Resilience & Utilities | Circuit breaker, backoff, safe math |
| 7 | Security | JWT, encryption, sensitive fields, TLS |
| 8 | Transaction Domain | Intent planning, balance posting, outbox |
| 9 | Tenant Manager | Full multi-tenancy subsystem |
| 10 | Webhook Delivery | SSRF-safe HMAC-signed delivery |
| 11 | Dead Letter Queue | Redis-backed DLQ with exponential backoff |
| 12 | Root Package & Utilities | App lifecycle, errors, UUID, env vars |
| 13 | Cross-Cutting Patterns | Shared patterns across packages |
| 14 | Which Package Do I Need? | Decision tree |
| 15 | Breaking Changes | Migration notes v4.2.0 → v5.x |

Read `sub-files/reference.md` for full API detail.
