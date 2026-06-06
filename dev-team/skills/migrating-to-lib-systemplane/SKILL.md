---
name: ring:migrating-to-lib-systemplane
description: "Migrating Lerian Go services from .env/YAML operational knobs (log levels, feature flags, rate limits, timeouts) to the lib-systemplane hot-reloadable runtime config client, wiring the migration-only make systemplane-ddl pipeline (runtime DDL forbidden in v1.6.0+). Orchestrates an 11-gate cycle dispatching ring:backend-go. Use when adding hot-reloadable config or migrating off v4 systemplane. Skip for non-Go or static-only config."
---

# Systemplane Migration (lib-systemplane)

## When to use
- User requests systemplane integration for a Go service
- User asks to add hot-reloadable runtime configuration
- Task mentions "systemplane", "runtime config", "hot reload", "LISTEN/NOTIFY config", "admin.Mount"
- User asks to migrate from v4 systemplane to v5

## Skip when
- Service is not a Go project
- Task does not involve runtime configuration
- Service has zero hot-reloadable knobs (everything is static env-var-at-startup config)
- Task is documentation-only or non-code


You orchestrate. Agents implement. NEVER use Edit/Write/Bash on Go source files.
All code changes go through `Task(subagent_type="ring:backend-go")`.
TDD mandatory for all implementation gates (RED → GREEN → REFACTOR).

## Systemplane Architecture

Three-step lifecycle:
1. `systemplane.NewPostgres` / `systemplane.NewMongoDB` — construct client (pass open `*sql.DB` or `*mongo.Client`)
2. `client.Register(namespace, key, defaultValue, opts...)` — declare every key BEFORE `Start`
3. `client.Start(ctx)` — begin listening; `Get*` for reads, `OnChange` for reactions

**Standards reference:** WebFetch `https://raw.githubusercontent.com/LerianStudio/lib-systemplane/main/doc.go`

**Canonical import paths:**

| Alias | Import Path | Purpose |
|-------|-------------|---------|
| `systemplane` | `github.com/LerianStudio/lib-systemplane` | Client, constructors, options, `SchemaSQL()` / `DefaultSeedSQL()` provisioning artifacts |
| `admin` | `github.com/LerianStudio/lib-systemplane/admin` | HTTP admin routes |
| `systemplanetest` | `github.com/LerianStudio/lib-systemplane/systemplanetest` | Contract test suite |

**Legacy paths are DELETED** — do not use `lib-commons/v4/...` or `lib-commons/v5/commons/systemplane` (extracted to its own module), and do not use `Supervisor`, `BundleFactory`, `ApplyBehavior`.

**Provisioning is migration-only.** lib-systemplane publishes `systemplane.SchemaSQL()` + `systemplane.DefaultSeedSQL()` as public artifacts and consumers MUST fold them into the service's own SQL migration pipeline via the `make systemplane-ddl` generator pattern (Gate 3.5). Runtime DDL provisioning is FORBIDDEN — least-privilege tenant-manager roles cannot run DDL anyway, and any boot-time `runSchema`-style hook is a CRITICAL deviation.

**Scope: operational knobs only** — values that can mutate in-place (log levels, feature flags, rate limits, timeouts, poll intervals).
NOT for settings requiring resource teardown: DSNs, TLS material, listen addresses → keep in env vars + restart.

**Redaction policies for `Register`:**

| Policy | Admin GET returns | Use for |
|--------|-------------------|---------|
| `RedactNone` (default) | Raw value | Log levels, feature flags, non-sensitive |
| `RedactMask` | Type-aware mask | Low-sensitivity values |
| `RedactFull` | null/omitted | Secrets, tokens, API keys |

Any key storing credentials MUST use `RedactFull`.

**Admin mount requires custom authorizer** (`admin.WithAuthorizer`) — default is DENY-ALL.

**Mandatory agent instruction (include in EVERY dispatch):**

> WebFetch `https://raw.githubusercontent.com/LerianStudio/lib-systemplane/main/doc.go`.
> Use only canonical `github.com/LerianStudio/lib-systemplane` import paths. v4 packages and the legacy `lib-commons/v5/commons/systemplane` path no longer exist.
> systemplane is for operational knobs only — not DSNs, TLS, or listen addresses.
> Provisioning is migration-only (Gate 3.5). Wire `cmd/generate-systemplane-ddl/` + `make systemplane-ddl` + `check-systemplane-ddl-drift` + `migrations/systemplane_ddl_manifest.json` and a bootstrap seam returning `[]SystemplaneSeedEntry`. NEVER call `SchemaSQL()` at boot. NEVER hand-edit generated `migrations/NNN_systemplane_*.sql`. See multi-tenant.md §27 "Cold-tenant resolution" for the canonical reference.
> TDD: RED → GREEN → REFACTOR for every gate.

## Related Skills

- [[using-lib-systemplane]] — adoption sweep + API reference for the lib-systemplane module
- [[using-lib-commons]] — non-observability lib-commons packages (lifecycle, outbox, tenancy)
- [[using-lib-observability]] — tracing, metrics, logging, assert, runtime, redaction
- For services running in **multi-tenant mode** (`MULTI_TENANT_ENABLED=true`), the consumer-side pattern (registration shape, no-fallback consumer reads, DI interface, `make systemplane-ddl` provisioning generator, Manager binding when available in the pinned lib version) is documented in `dev-team/docs/standards/golang/multi-tenant.md` §27 "Systemplane in MT mode — compliance pattern (MANDATORY)". Load that section — particularly the "Cold-tenant resolution — `make systemplane-ddl` generator" subsection — in addition to the general systemplane architecture below.

## Gate Overview

| Gate | Name | Condition | Agent |
|------|------|-----------|-------|
| 0 | Stack Detection + Compliance Audit | Always | Orchestrator |
| 1 | Codebase Analysis (config focus) | Always | ring:codebase-explorer |
| 1.5 | Implementation Preview | Always | ring:visualizing |
| 2 | lib-commons v5 Upgrade + v4 Removal | Skip only if v5 in go.mod AND zero v4 imports | ring:backend-go |
| 3 | Client Construction + Key Registration | Always | ring:backend-go |
| 3.5 | DDL Provisioning (`make systemplane-ddl`) | Always — STANDARD provisioning mechanism | ring:backend-go |
| 4 | OnChange Subscriptions | Always unless zero hot-reloadable keys (justify) | ring:backend-go |
| 5 | Config Bridge | Skip if no Config struct reads need live values | ring:backend-go |
| 6 | Admin HTTP Mount + Authorizer | Skip only if service has no admin surface (justify) | ring:backend-go |
| 7 | Wiring + Lifecycle + Backward Compat | Always — NEVER skippable | ring:backend-go |
| 8 | Tests | Always | ring:backend-go |
| 9 | Code Review | Always | 9 defaults + triggered specialists in parallel |
| 10 | User Validation | Always | User |
| 11 | Activation Guide | Always | Orchestrator |

Gates execute sequentially. Any existing v4 code = NON-COMPLIANT = gates cannot be skipped.

## Gate 0: Stack Detection

Orchestrator executes directly. Three phases:

**Phase 1: Stack Detection**
```bash
grep "lib-commons\|lib-systemplane" go.mod  # check legacy v4/v5 paths vs new module
grep -rn "systemplane" internal/             # existing usage
grep -rn "SYSTEMPLANE_" .                    # v4 env vars
grep "postgresql\|postgres" go.mod           # backend type
grep "mongodb\|mongo" go.mod
# Non-canonical:
grep -rn "fsnotify\|viper.Watch\|Supervisor\|BundleFactory\|ApplyBehavior" internal/
grep -rn "lib-commons/v5/commons/systemplane\|lib-commons/v4" internal/  # legacy paths
# DDL provisioning seam + manifest (Gate 3.5):
ls cmd/generate-systemplane-ddl/                              # generator presence
ls migrations/systemplane_ddl_manifest.json                    # append-only manifest
grep -n "systemplane-ddl\|check-systemplane-ddl-drift" Makefile  # make targets
grep -rn "SystemplaneSeedEntries\|buildSystemplaneRegistrations" internal/bootstrap/  # seam
# Runtime DDL anti-pattern (CRITICAL):
grep -rn "runSchema\|SchemaSQL()\|CREATE TABLE.*systemplane_entries" internal/  # MUST be migration-only
```

**Phase 2: Compliance Audit** (if systemplane code detected)
- No legacy imports (`lib-commons/v4/...`, `lib-commons/v5/commons/systemplane`)
- `Register` called before `Start`
- `OnChange` wired for hot-reloadable keys
- `admin.Mount` with `admin.WithAuthorizer`
- Lifecycle: `client.Start(ctx)` registered with `commons.Launcher`
- `cmd/generate-systemplane-ddl/` generator present AND `migrations/systemplane_ddl_manifest.json` committed
- `make systemplane-ddl` + `check-systemplane-ddl-drift` wired in Makefile and called from `check-generated-artifacts`
- Bootstrap exposes the seam `SystemplaneSeedEntries() ([]SystemplaneSeedEntry, error)` derived from the same `buildSystemplaneRegistrations` (or equivalent) the client uses at boot
- ZERO runtime DDL — no `runSchema`, no `SchemaSQL()` at boot, no `CREATE TABLE ... systemplane_entries` outside `migrations/`

**Phase 3: Non-Canonical Detection**
- Any `fsnotify` / `viper.WatchConfig` / `envconfig.Watch` for runtime config → MUST replace
- Any v4 sub-packages (`domain/`, `ports/`, `registry/`, `service/`, `bootstrap/`) → MUST remove
- Any `lib-commons/v5/commons/systemplane` imports → MUST migrate to `lib-systemplane`
- Runtime DDL provisioning (boot-time `SchemaSQL()` execution) → MUST replace with the `make systemplane-ddl` migration pipeline (Gate 3.5)
- Hand-written `migrations/NNN_systemplane_*.sql` files NOT emitted by the generator → MUST be re-emitted via `make systemplane-ddl` (drift-guarded)

## Severity Reference

| Severity | Criteria |
|----------|----------|
| CRITICAL | Legacy import (`lib-commons/v4/...` or `lib-commons/v5/commons/systemplane`); `admin.Mount` without authorizer; secret with `RedactNone`; runtime DDL provisioning (boot-time `SchemaSQL()` or `CREATE TABLE systemplane_entries` outside `migrations/`) |
| HIGH | No `Register` before `Start`; no `OnChange` for live key; `SYSTEMPLANE_*` env vars in code; missing `cmd/generate-systemplane-ddl/` generator or `systemplane_ddl_manifest.json`; `make systemplane-ddl` not wired into `check-generated-artifacts` |
| MEDIUM | Missing `WithLogger`/`WithTelemetry`; no validator on numeric range; hand-edited generated `migrations/NNN_systemplane_*.sql` (would fail the drift guard) |
| LOW | Missing `WithDescription`; inconsistent namespace naming |
