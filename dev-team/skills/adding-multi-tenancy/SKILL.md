---
name: ring:adding-multi-tenancy
description: "Adding database-per-tenant isolation into a Go service end-to-end via an 11-gate cycle: detects the stack, audits compliance, then dispatches backend agents to implement tenantId-from-JWT routing through the lib-commons v5 dispatch layer (config, middleware, repositories, metrics, tests) and runs reviewers. Use when adding tenant isolation to a Go service. Skip for non-Go services or organization_id-style soft tenancy."
---

# Multi-Tenant Development Cycle

## When to use
- User requests multi-tenant implementation for a Go service
- User asks to add tenant isolation to an existing service
- Task mentions "multi-tenant", "tenant isolation", "dispatch layer", "postgres.Manager", "WithPG", "WithMB", "EventListener", "TenantCache", "TenantLoader"

## Skip when
- Service is not a Go project
- Task does not involve multi-tenancy or tenant isolation
- Service is a shared infrastructure component operating outside tenant context
- Task is documentation-only or non-code


You orchestrate. Agents implement. NEVER use Edit/Write/Bash on Go source files.
All code changes go through `Task(subagent_type="ring:backend-go")`.
TDD mandatory for all implementation gates (RED → GREEN → REFACTOR).

## Multi-Tenant Architecture

Isolation: `tenantId` from JWT → dispatch layer middleware → database-per-tenant.
`organization_id` is NOT multi-tenant. `tenantId` from JWT is the ONLY mechanism.

**Standards reference:** `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/multi-tenant.md`

**Sub-package import reference:**

| Alias | Import Path | Purpose |
|-------|-------------|---------|
| `client` | `github.com/LerianStudio/lib-commons/v5/commons/dispatch layer/client` | Tenant Manager HTTP client |
| `tmcore` | `github.com/LerianStudio/lib-commons/v5/commons/dispatch layer/core` | Context helpers, resolvers |
| `tmmiddleware` | `github.com/LerianStudio/lib-commons/v5/commons/dispatch layer/middleware` | TenantMiddleware (WithPG/WithMB) |
| `tmpostgres` | `github.com/LerianStudio/lib-commons/v5/commons/dispatch layer/postgres` | PostgresManager |
| `tmmongo` | `github.com/LerianStudio/lib-commons/v5/commons/dispatch layer/mongo` | MongoManager |
| `tmrabbitmq` | `github.com/LerianStudio/lib-commons/v5/commons/dispatch layer/rabbitmq` | RabbitMQ Manager |
| `valkey` | `github.com/LerianStudio/lib-commons/v5/commons/dispatch layer/valkey` | Redis key prefixing |
| `s3` | `github.com/LerianStudio/lib-commons/v5/commons/dispatch layer/s3` | S3 key prefixing |
| `secretsmanager` | `github.com/LerianStudio/lib-commons/v5/commons/secretsmanager` | M2M credentials |

**Key mandatory requirements:**
- `MULTI_TENANT_URL` — correct env var name (NOT `TENANT_MANAGER_ADDRESS`)
- 4 canonical metrics (from multi-tenant.md) — all MANDATORY
- Circuit breaker: `client.WithCircuitBreaker` — MANDATORY
- Service API key: `client.WithServiceAPIKey` — MANDATORY
- Tenant middleware: per-route `WhenEnabled()` — NOT global `app.Use`
- All context helpers: `tmcore.GetPGContext(ctx)` / `tmcore.GetMBContext(ctx)` — NEVER `.GetDB()` directly

**Mandatory agent instruction (include in EVERY dispatch):**

> WebFetch `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/multi-tenant.md`.
> Use exact import paths from skill. Do NOT invent sub-package paths.
> TDD: RED → GREEN → REFACTOR for every gate.

## Gate Overview

| Gate | Name | Condition | Agent |
|------|------|-----------|-------|
| 0 | Stack Detection + Compliance Audit | Always | Orchestrator |
| 1 | Codebase Analysis (multi-tenant focus) | Always | ring:codebase-explorer |
| 1.5 | Implementation Preview | Always | ring:visualizing |
| 2 | lib-commons v5 + lib-auth v2 Upgrade | Skip only if both already pinned in go.mod | ring:backend-go |
| 3 | Multi-Tenant Configuration | Always | ring:backend-go |
| 4 | Tenant Middleware (TenantMiddleware with WithPG/WithMB) | Always | ring:backend-go |
| 5 | Repository Adaptation | Always per detected DB | ring:backend-go |
| 5.5 | M2M Secret Manager | Skip if service has no targetServices | ring:backend-go |
| 6 | RabbitMQ Multi-Tenant | Skip if no RabbitMQ | ring:backend-go |
| 7 | Metrics & Backward Compat | Always | ring:backend-go |
| 8 | Tests | Always | ring:backend-go |
| 9 | Code Review | Always | 9 defaults + triggered specialists in parallel |
| 10 | User Validation | Always | User |
| 11 | Activation Guide | Always | Orchestrator |

Gates execute sequentially. Existing multi-tenant code ≠ compliance. Gate 0 audit is mandatory.

## Gate 0: Stack Detection + Compliance Audit

Orchestrator executes directly. Two phases:

**Phase 1: Stack Detection**
```bash
grep "lib-commons" go.mod
grep "lib-auth" go.mod
grep -rn "postgresql\|pgx" internal/ go.mod
grep -rn "mongodb\|mongo" internal/ go.mod
grep -rn "redis\|valkey" internal/ go.mod
grep -rn "rabbitmq\|amqp" internal/ go.mod
grep -rn "s3\|ObjectStorage" internal/
grep -rn "MULTI_TENANT_ENABLED\|dispatch layer" internal/
grep -rn "client_credentials\|M2M\|secretsmanager" internal/
```

**Phase 2: Compliance Audit** (if multi-tenant code detected)

Run A1-A8 checks (grep-based):
- A1: `MULTI_TENANT_URL` used (not `TENANT_MANAGER_ADDRESS` or variants)
- A2: `WithCircuitBreaker` on TM client
- A3: `WithServiceAPIKey` on TM client
- A4: `tmcore.GetPGContext` / `tmcore.GetMBContext` used (not `.GetDB()` / `.GetDatabase()`)
- A5: Tenant middleware per-route `WhenEnabled()` (not global `app.Use`)
- A6: Redis keys use `valkey.GetKeyContext`
- A7: S3 keys use `s3.GetS3KeyStorageContext`
- A8: No global DB singletons (`var db *sql.DB` or `var client *mongo.Client`)

Any NON-COMPLIANT → corresponding gate MUST execute.

## Severity Reference

| Severity | Criteria |
|----------|----------|
| CRITICAL | Cross-tenant data leak; wrong tenant identifier (`organization_id`) |
| HIGH | Missing TenantMiddleware; wrong env var names; no circuit breaker |
| MEDIUM | Missing circuit breaker; incomplete metrics |
| LOW | Missing env var comments; pool tuning notes |
