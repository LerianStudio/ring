---
name: ring:implementing-readyz
description: "Implementing the canonical /readyz readiness-probe contract across Go, TypeScript, and Next.js via a 12-gate cycle: detects stack, audits compliance, then dispatches agents to build the dependency probe, url.Parse TLS detection, ValidateSaaSTLS enforcement, metrics, startup self-probe, and graceful drain, then runs reviewers. Use when a service lacks or has incomplete /readyz. Skip for libraries, CLI tools, or batch jobs."
---

# Readyz & Self-Probe Development Cycle

## When to use
- New service being created
- Service has external dependencies (DB, cache, queue, HTTP upstreams)
- Service lacks /readyz or has incomplete dependency checks
- Service missing startup self-probe, SaaS TLS enforcement, or metrics

## Skip when
- Pure library package with no deployable service or HTTP server
- Task is documentation-only, configuration-only, or non-code
- Service has no external dependencies AND no network listeners
- CLI tool or batch job that does not serve HTTP traffic


You orchestrate. Agents implement. NEVER use Edit/Write/Bash on source files.
All code changes go through `Task(subagent_type="ring:backend-go")` or `Task(subagent_type="ring:backend-ts")` (by language).
TDD mandatory for all implementation gates (RED → GREEN → REFACTOR).

**Agents:**

| Who | Responsibility |
|-----|----------------|
| ring:backend-go | Go services |
| ring:backend-ts | TypeScript backend/BFF |
| ring:bff-ts | Next.js BFF |
| ring:codebase-explorer | Gate 1 analysis |
| ring:visualizing | Gate 1.5 HTML preview |
| 9 defaults + triggered specialists | Gate 9 |

## Readiness Architecture

`/readyz` — runtime dependency probe for K8s readinessProbe. `/health` — liveness probe gated by startup self-probe.

**Standards references (WebFetch by implementation agents):**

| Resource | URL |
|----------|-----|
| Ring SRE standards | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/sre.md` |
| Go bootstrap standards | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/bootstrap.md` |
| This skill (authoritative) | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/skills/implementing-readyz/SKILL.md` |

**Canonical response contract:**

```json
{
  "status": "healthy",
  "checks": {
    "postgres": { "status": "up", "latency_ms": 2, "tls": true },
    "redis":    { "status": "skipped", "reason": "REDIS_ENABLED=false" },
    "upstream_fees": { "status": "degraded", "breaker_state": "half-open", "latency_ms": 12 }
  },
  "version": "1.2.3",
  "deployment_mode": "saas"
}
```

**Status vocabulary:** `up` / `down` / `degraded` / `skipped` / `n/a` — no others.

**Aggregation rule:** top-level `"unhealthy"` + HTTP 503 if ANY check is `down` or `degraded`.

**Probe logging contract (MANDATORY):**

Kubernetes hits `/readyz` every 5s (≈17,280 calls/day per pod). Per-iteration INFO logging drowns log pipelines.

| Outcome | Log level |
|---------|-----------|
| Success (all checks `up`) | DEBUG |
| Failure (any check `down`/`degraded`) | WARN |

INFO/ERROR are not used by the probe handler. Steady-state observability is the job of `readyz_check_status` / `readyz_check_duration` metrics (Gate 5) — logs are diagnostic only. Access-log middleware MUST exclude `/readyz`, `/health`, `/metrics` from request logging — `lib-observability` applies this by default (`defaultLogExcludedRoutes` in `middleware/logging.go`); use `middleware.WithExcludedRoutes(...)` to append more paths. Services not on `lib-observability` must keep an explicit `skipTelemetryPaths` filter.

**Endpoint paths:**

| Stack | Readiness | Liveness |
|-------|-----------|----------|
| Go API | `/readyz` | `/health` |
| TypeScript API | `/readyz` | `/health` |
| Next.js | `/api/admin/health/readyz` | same |

**Forbidden anti-patterns** (block progression in Gate 0):
1. Response caching in front of /readyz
2. `/ready` alias (not `/readyz`)
3. `/health/live` + `/health/ready` split
4. `strings.Contains(uri, "tls=true")` — use `url.Parse`
5. Reflection on `*amqp.Connection` for TLS state
6. Inline TLS checks at each connection site — use `ValidateSaaSTLS()`
7. `process.exit()` in Next.js `instrumentation.ts` on probe failure
8. INFO log on probe success — see Probe logging contract; success is DEBUG, failure is WARN

**Mandatory agent instruction (include in EVERY dispatch):**

> WebFetch `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/skills/implementing-readyz/SKILL.md` and `sre.md`.
> Follow the canonical response contract exactly. Five-value status vocabulary.
> Aggregation: 503 iff any check is `down` or `degraded`.
> Probe logging: success at DEBUG, failure at WARN. No INFO from the probe handler.
> Forbidden anti-patterns 1-8: MUST NOT introduce any.
> TDD: RED → GREEN → REFACTOR.

## Gate Overview

| Gate | Name | Condition | Agent |
|------|------|-----------|-------|
| 0 | Stack Detection + /readyz Compliance Audit | Always | Orchestrator |
| 1 | Codebase Analysis | Always | ring:codebase-explorer |
| 1.5 | Implementation Preview (HTML report) | Always | ring:visualizing |
| 2 | /readyz Endpoint Implementation | Always | ring:backend-go / ring:backend-ts (by language) |
| 3 | TLS Detection (url.Parse) | Always | ring:backend-go / ring:backend-ts (by language) |
| 4 | SaaS TLS Enforcement (ValidateSaaSTLS) | Always | ring:backend-go / ring:backend-ts (by language) |
| 5 | Metrics Emission | Always | ring:backend-go / ring:backend-ts (by language) |
| 6 | Circuit Breaker + Multi-Tenant Carve-Out | Skip only if no breakers AND single-tenant | ring:backend-go / ring:backend-ts (by language) |
| 7 | Startup Self-Probe + /health + Graceful Drain | Always — NEVER skippable | ring:backend-go / ring:backend-ts (by language) |
| 8 | Tests | Always | ring:backend-go / ring:backend-ts (by language) |
| 9 | Code Review | Always | 9 defaults + triggered specialists in parallel |
| 10 | User Validation | Always | User |
| 11 | Activation Guide | Always | Orchestrator |

Gates execute sequentially. Existing /readyz code ≠ compliance. Gate 0 Phase 2 audit is mandatory.

## Gate 0: Stack Detection + Audit

Orchestrator executes directly. Three phases:

**Phase 1: Stack Detection**
```bash
grep -rn "postgresql\|pgx" internal/ go.mod
grep -rn "mongodb\|mongo" internal/ go.mod
grep -rn "redis\|valkey" internal/ go.mod
grep -rn "rabbitmq\|amqp" internal/ go.mod
grep -rn "http.Client\|upstream" internal/
grep -rn "circuitbreaker\|gobreaker" internal/
grep "DEPLOYMENT_MODE\|saas" .env* internal/
```

**Phase 2: Compliance Audit (S1-S10)** (if /readyz code detected)
- S1: Response contract shape (all required fields present)
- S2: Status vocabulary (only 5 valid values)
- S3: Aggregation rule (503 on down/degraded)
- S4: Endpoint path (exact `/readyz`, not `/ready`)
- S5: No response caching
- S6: TLS detection uses `url.Parse`, not `strings.Contains`
- S7: `ValidateSaaSTLS()` called at bootstrap for SaaS mode
- S8: Three readyz metrics emitted
- S9: Startup self-probe gates `/health`
- S10: Probe logging follows the contract (success = DEBUG, failure = WARN; no INFO from probe handler; `/readyz`, `/health`, `/metrics` excluded from access log — automatic on `lib-observability`, manual `skipTelemetryPaths` otherwise)

**Phase 3: Anti-Pattern Detection**
Check for each of the 8 forbidden anti-patterns. Any match = COMPLIANT: false.

## Severity Reference

| Severity | Criteria |
|----------|----------|
| CRITICAL | `DEPLOYMENT_MODE=saas` without ValidateSaaSTLS; TLS reflection; response caching |
| HIGH | Wrong status vocabulary; aggregation rule wrong; metrics not emitted; self-probe missing; INFO logging on probe success |
| MEDIUM | Missing `reason` on skipped/n/a; drain grace too short |
| LOW | Missing per-dep description; inconsistent version string |
