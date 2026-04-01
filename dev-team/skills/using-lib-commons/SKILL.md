---
name: ring:using-lib-commons
description: |
  Comprehensive reference for lib-commons v4.6.0 — Lerian's shared Go library providing
  35+ packages across database connections, messaging, multi-tenancy, runtime configuration,
  observability, security, resilience, HTTP tooling, and event-driven tenant discovery.
  Load this skill to discover available APIs, find the right package, and learn correct
  initialization patterns.

trigger: |
  - Need to understand what lib-commons provides
  - Looking for the right package/API for a task
  - Setting up a new service that uses lib-commons
  - Need to know correct constructor/initialization patterns
  - Working with multi-tenancy (dispatch layer)
  - Working with event-driven tenant discovery
  - Working with runtime configuration (systemplane)
  - Need database, messaging, or infrastructure patterns
  - Need rate limiting, context helpers, or string utilities
  - Migrating from older lib-commons versions

skip_when: |
  - Already know which package to use and how
  - Working on non-Go services
  - Working on frontend code

related:
  similar: [ring:using-dev-team, ring:using-ring]
---

# Using lib-commons v4.6.0 — Developer Reference

lib-commons v4.6.0 is Lerian's foundational Go library. Every Lerian Go microservice depends on it for infrastructure, observability, security, multi-tenancy, event-driven tenant discovery, and runtime configuration.

- **Module path**: `github.com/LerianStudio/lib-commons/v4`
- **All packages live under**: `commons/`
- **Scope**: Everything a Lerian Go microservice needs from boot to shutdown

This skill is a comprehensive catalog and quick-reference. Use it to discover which package solves your problem, understand initialization order, and learn the correct constructor patterns.

---

## Table of Contents

| # | Section | What You'll Find |
|---|---------|-----------------|
| 1 | [Package Catalog](#1-package-catalog-quick-reference) | All 35+ packages organized by domain |
| 2 | [Common Initialization Pattern](#2-common-initialization-pattern) | Typical service bootstrap sequence |
| 3 | [Database Connections](#3-database-connections) | postgres, mongo, redis, rabbitmq deep-dive |
| 4 | [HTTP Toolkit](#4-http-toolkit-nethttp) | Middleware, rate limiting, pagination, validation, response helpers, health checks |
| 5 | [Observability](#5-observability) | Logger, tracing, metrics, **runtime** (panic pipeline), **assert** (observability trident) |
| 6 | [Resilience & Utilities](#6-resilience--utilities) | Circuit breaker, backoff, safe math, pointers |
| 7 | [Security](#7-security) | JWT, encryption, sensitive fields, AWS secrets |
| 8 | [Transaction Domain](#8-transaction-domain) | Intent planning, balance posting, outbox |
| 9 | [Tenant Manager](#9-dispatch layer-deep-reference) | Full multi-tenancy subsystem with event-driven discovery |
| 10 | [Systemplane](#10-systemplane-deep-reference) | Runtime configuration subsystem |
| 11 | [Root Package & Utilities](#11-root-package--utilities) | App lifecycle, context helpers, business errors, string utilities, env vars |
| 12 | [Cross-Cutting Patterns](#12-cross-cutting-patterns) | Patterns shared across all packages |
| 13 | [Which Package Do I Need?](#13-which-package-do-i-need) | Decision tree for package selection |
| 14 | [Breaking Changes](#14-breaking-changes) | Migration notes for v4.2.0 through v4.6.0 |

---

## 1. Package Catalog (Quick Reference)

### Root Package

| Package | Import Path Suffix | Purpose |
|---|---|---|
| `commons` | `commons` | App lifecycle (`Launcher`), request-scoped context helpers, business error mapping, UUID generation, struct-to-JSON, metrics, string utilities, date/time validation, env var helpers |

### Database & Data

| Package | Import Path Suffix | Purpose |
|---|---|---|
| `postgres` | `commons/postgres` | PostgreSQL primary/replica connections with lazy connect, migrations, connection pooling |
| `mongo` | `commons/mongo` | MongoDB client with lazy reconnect, TLS, idempotent index creation |
| `redis` | `commons/redis` | Redis/Valkey with 3 topologies (standalone/sentinel/cluster), GCP IAM auth, distributed locks (RedLock) |
| `rabbitmq` | `commons/rabbitmq` | RabbitMQ AMQP 0-9-1 with confirmable publisher, auto-recovery, DLQ topology |
| `transaction` | `commons/transaction` | Financial transaction intent planning, balance posting, share/amount/remainder allocation |
| `outbox` | `commons/outbox` | Transactional outbox pattern — event model, dispatcher, handler registry, multi-tenant support |
| `outbox/postgres` | `commons/outbox/postgres` | PostgreSQL outbox repository with schema-per-tenant and column-per-tenant strategies |

### Security & Auth

| Package | Import Path Suffix | Purpose |
|---|---|---|
| `jwt` | `commons/jwt` | HMAC JWT signing/verification (HS256/384/512), constant-time comparison, algorithm allowlist |
| `crypto` | `commons/crypto` | AES-256-GCM encryption + HMAC-SHA256 hashing with credential redaction |
| `security` | `commons/security` | Sensitive field detection (90+ patterns) for log/trace obfuscation |
| `secretsmanager` | `commons/secretsmanager` | AWS Secrets Manager M2M credential fetching with path traversal protection |
| `license` | `commons/license` | License validation failure handling with fail-open/fail-closed policies |

### Observability & Runtime

| Package | Import Path Suffix | Purpose |
|---|---|---|
| `log` | `commons/log` | Logger interface (`Logger`) — the universal logging contract across all packages |
| `zap` | `commons/zap` | Zap-backed Logger implementation with OTel log bridge, runtime level adjustment. **v4.3.0+**: timestamp field changed from `"ts"` (Unix epoch) to `"timestamp"` (ISO 8601) |
| `opentelemetry` | `commons/opentelemetry` | Full OTel lifecycle — Core threeProvider, MeterProvider, LoggerProvider, OTLP exporters, redaction. Registers noop global providers when collector endpoint is empty |
| `opentelemetry/metrics` | `commons/opentelemetry/metrics` | Thread-safe metrics factory with builders (Counter, Gauge, Histogram) |
| `runtime` | `commons/runtime` | Safe goroutine launching, panic recovery, production mode, error reporter integration |
| `server` | `commons/server` | HTTP (Fiber) + gRPC graceful shutdown manager with ordered teardown |
| `cron` | `commons/cron` | 5-field cron expression parser, computes next execution time |

### HTTP & Networking

| Package | Import Path Suffix | Purpose |
|---|---|---|
| `net/http` | `commons/net/http` | Fiber HTTP toolkit: middleware (CORS, logging, telemetry, basic auth), validation, 3 cursor pagination styles, health checks, SSRF-safe reverse proxy, ownership verification, response helpers, tenant-scoped ID parsing |
| `net/http/ratelimit` | `commons/net/http/ratelimit` | Redis-backed distributed fixed-window rate limiting with atomic Lua script, tiered presets, dynamic tier selection, identity extractors, fail-open/fail-closed policy, `X-RateLimit-*` headers |

### Resilience & Utilities

| Package | Import Path Suffix | Purpose |
|---|---|---|
| `circuitbreaker` | `commons/circuitbreaker` | Per-service circuit breakers (sony/gobreaker) with health checker, state metrics |
| `backoff` | `commons/backoff` | Exponential backoff with jitter, context-aware sleep |
| `errgroup` | `commons/errgroup` | Error group with first-error cancellation and panic-to-error recovery |
| `safe` | `commons/safe` | Panic-free division, bounds-checked slice access, cached regex compilation |
| `pointers` | `commons/pointers` | Pointer-to-literal helpers (`String`, `Bool`, `Time`, `Int64`, `Float64`) |
| `assert` | `commons/assert` | Production runtime assertions with OTel span events + metrics on failure |
| `constants` | `commons/constants` | Shared constants (headers, error codes, pagination defaults, OTel attributes) |

### Multi-Tenancy (Major Subsystem)

| Package | Import Path Suffix | Purpose |
|---|---|---|
| `dispatch layer` | `commons/dispatch layer` | Complete database-per-tenant isolation system with sub-packages for each resource type |
| `dispatch layer/core` | `...core` | Shared types: TenantConfig, **variadic** context helpers (`ContextWithPG(ctx, pg, ...module)`, `GetPGContext(ctx, ...module)`) |
| `dispatch layer/client` | `...client` | HTTP client for Tenant Manager API with cache + circuit breaker. **v4.2.0+**: endpoint `/connections`, path prefix `/v1/associations/` |
| `dispatch layer/postgres` | `...postgres` | Per-tenant PostgreSQL connection pool manager with LRU eviction |
| `dispatch layer/mongo` | `...mongo` | Per-tenant MongoDB client manager |
| `dispatch layer/rabbitmq` | `...rabbitmq` | Per-tenant RabbitMQ connection manager (vhost isolation) |
| `dispatch layer/s3` | `...s3` | Tenant-aware S3 key namespacing (`{tenantID}/{key}`). **v4.6.0**: `GetS3KeyStorageContext` (renamed from `GetObjectStorageKeyForTenant`) |
| `dispatch layer/valkey` | `...valkey` | Tenant-aware Redis key namespacing (`tenant:{tenantID}:{key}`) |
| `dispatch layer/middleware` | `...middleware` | Fiber middleware: JWT-to-tenantId extraction, DB resolution, context injection. **v4.6.0**: unified `WithPG`/`WithMB` API (MultiPoolMiddleware removed) |
| `dispatch layer/consumer` | `...consumer` | Multi-tenant RabbitMQ consumer with dynamic tenant discovery, `EnsureConsumerStarted` / `StopConsumer` lifecycle |
| `dispatch layer/event` | `...event` | **v4.5.0**: Event-driven tenant discovery via Redis pub/sub. Events: `tenant.added`, `tenant.connections.updated`, `tenant.credentials.rotated`. `TenantEventListener` for HTTP-only services |
| `dispatch layer/redis` | `...redis` | **v4.6.0**: `NewTenantPubSubRedisClient` helper for Redis pub/sub with TLS support |
| `dispatch layer/tenantcache` | `...tenantcache` | **v4.6.0**: `TenantLoader` with `WithOnTenantLoaded` callback for event-driven tenant addition |

### Runtime Configuration (Major Subsystem)

| Package | Import Path Suffix | Purpose |
|---|---|---|
| `systemplane` | `commons/systemplane` | Database-backed, hot-reloadable runtime configuration with hexagonal architecture |
| `systemplane/domain` | `...domain` | Core types: Entry, Snapshot, KeyDef, Target, ApplyBehavior, ValueType |
| `systemplane/ports` | `...ports` | Port interfaces: Store, HistoryStore, ChangeFeed, BundleFactory, BundleReconciler |
| `systemplane/service` | `...service` | Manager (read/write configs/settings), Supervisor (bundle lifecycle), SnapshotBuilder |
| `systemplane/registry` | `...registry` | Thread-safe key definition registry |
| `systemplane/bootstrap` | `...bootstrap` | Env-var-based config loading, backend factory registration |
| `systemplane/bootstrap/builtin` | `...bootstrap/builtin` | Ready-to-use entry point (registers PostgreSQL + MongoDB backends) |
| `systemplane/adapters/store/postgres` | `...adapters/store/postgres` | PostgreSQL store with pg_notify change signals |
| `systemplane/adapters/store/mongodb` | `...adapters/store/mongodb` | MongoDB store with transaction-based writes |
| `systemplane/adapters/store/secretcodec` | `...adapters/store/secretcodec` | AES-256-GCM encryption for secret config values |
| `systemplane/adapters/changefeed/postgres` | `...adapters/changefeed/postgres` | LISTEN/NOTIFY change feed with missed-signal resync |
| `systemplane/adapters/changefeed/mongodb` | `...adapters/changefeed/mongodb` | Change stream or polling change feed |
| `systemplane/adapters/http/fiber` | `...adapters/http/fiber` | REST API for config/settings CRUD with optimistic concurrency |

### Build & Shell Utilities

| Package | Import Path Suffix | Purpose |
|---|---|---|
| `shell` | `commons/shell` | Build/shell utilities — Makefiles, shell scripts, ASCII art banners for Lerian services |

---

## 2. Common Initialization Pattern

Most Lerian services follow this bootstrap sequence. The order matters — each layer depends on the previous one.

```go
// 1. Logger — first because everything else logs
logger, _ := zap.New(zap.Config{
    Environment:     zap.EnvironmentProduction,
    OTelLibraryName: "my-service",
})
defer logger.Sync(ctx)

// 2. Telemetry — second because DB/HTTP packages emit traces and metrics
//    When CollectorExporterEndpoint is empty, noop global providers are registered
//    so trace/metric calls are no-ops instead of errors.
tl, _ := opentelemetry.NewTelemetry(opentelemetry.TelemetryConfig{
    LibraryName:               "my-service",
    ServiceName:               "my-service",
    ServiceVersion:            "1.0.0",
    DeploymentEnv:             "production",
    CollectorExporterEndpoint: "otel-collector:4317",
    EnableTelemetry:           true,
    Logger:                    logger,
})
_ = tl.ApplyGlobals()
defer tl.ShutdownTelemetry()

// 3. Runtime — panic metrics and production mode
runtime.InitPanicMetrics(tl.MetricsFactory, logger)
runtime.SetProductionMode(true)

// 4. Assert metrics — production assertions with OTel
assert.InitAssertionMetrics(tl.MetricsFactory)

// 5. PostgreSQL
pgClient, _ := postgres.New(postgres.Config{
    PrimaryDSN:     os.Getenv("PRIMARY_DSN"),
    ReplicaDSN:     os.Getenv("REPLICA_DSN"),
    Logger:         logger,
    MetricsFactory: tl.MetricsFactory,
})
defer pgClient.Close()

// 6. MongoDB (if needed)
mongoClient, _ := mongo.NewClient(ctx, mongo.Config{
    URI:            os.Getenv("MONGO_URI"),
    Database:       "mydb",
    Logger:         logger,
    MetricsFactory: tl.MetricsFactory,
})
defer mongoClient.Close(ctx)

// 7. Redis
redisClient, _ := redis.New(ctx, redis.Config{
    Topology: redis.Topology{
        Standalone: &redis.StandaloneTopology{Address: "redis:6379"},
    },
    Auth: redis.Auth{
        StaticPassword: &redis.StaticPasswordAuth{Password: os.Getenv("REDIS_PASS")},
    },
    Logger:         logger,
    MetricsFactory: tl.MetricsFactory,
})
defer redisClient.Close()

// 8. RabbitMQ
rmqConn := &rabbitmq.RabbitMQConnection{
    Host:           "rabbitmq",
    Port:           "5672",
    User:           "guest",
    Pass:           "guest",
    Logger:         logger,
    MetricsFactory: tl.MetricsFactory,
}
_ = rmqConn.Connect()
defer rmqConn.Close()

// 9. Fiber App with middleware
app := fiber.New(fiber.Config{ErrorHandler: http.FiberErrorHandler})
app.Use(http.WithCORS())
app.Use(http.WithHTTPLogging(http.WithCustomLogger(logger)))
tm := http.NewTelemetryMiddleware(tl)
app.Use(tm.WithTelemetry(tl, "/health", "/version"))
app.Get("/health", http.HealthWithDependencies(...))
app.Get("/version", http.Version)

// 10. Graceful shutdown
sm := server.NewServerManager(nil, tl, logger).
    WithHTTPServer(app, ":3000").
    WithShutdownTimeout(30 * time.Second)
sm.StartWithGracefulShutdown()
```

**Key observations:**

- Logger and telemetry are always first — every subsequent package accepts them as dependencies.
- All `defer` calls run in LIFO order, so the server shuts down before DB connections close.
- Every infrastructure client accepts `MetricsFactory` (optional, nil disables metrics).
- `tl.ApplyGlobals()` sets the global Core threeProvider/MeterProvider for libraries that use `otel.Core three()`.
- When `CollectorExporterEndpoint` is empty, noop providers are registered globally so code that calls `otel.Core three()` or `otel.Meter()` does not error — it simply no-ops.

### Alternative: Using the `Launcher` (Root Package)

For services that want concurrent lifecycle management, the root `commons` package provides a `Launcher`:

```go
launcher := commons.NewLauncher(logger)
launcher.Add("http-server", func(ctx context.Context) error {
    return sm.StartWithGracefulShutdown()
})
launcher.Add("consumer", func(ctx context.Context) error {
    return consumer.Run(ctx)
})
// Launcher starts all components concurrently, cancels all on first error
err := launcher.Run(ctx)
```

---

## 3. Database Connections

### PostgreSQL (`commons/postgres`)

**Constructor**: `postgres.New(config)` returns a `*postgres.Client` with primary and optional replica.

**Key config fields:**

| Field | Type | Purpose |
|-------|------|---------|
| `PrimaryDSN` | `string` | Primary database connection string |
| `ReplicaDSN` | `string` | Read-replica connection string (optional) |
| `MaxOpenConns` | `int` | Maximum open connections (default: 25) |
| `MaxIdleConns` | `int` | Maximum idle connections (default: 25) |
| `ConnMaxLifetime` | `time.Duration` | Connection maximum lifetime |
| `ConnMaxIdleTime` | `time.Duration` | Connection maximum idle time |
| `Logger` | `log.Logger` | Logger instance |
| `MetricsFactory` | `metrics.Factory` | Metrics factory (nil = no metrics) |

**Key interface**: `dbresolver.DB` — provides `Exec`, `Query`, `QueryRow`, `BeginTx` with automatic primary/replica routing.

**Lazy connect**: The first call to `Resolver()` triggers the actual TCP connection. This means `postgres.New()` never blocks on DNS or TCP.

**Migrations**: `pgClient.RunMigrations(migrationsFS)` applies embedded SQL migrations.

### MongoDB (`commons/mongo`)

**Constructor**: `mongo.NewClient(ctx, config)` returns a `*mongo.Client`.

**Lazy reconnect**: `ResolveClient()` and `ResolveDatabase()` use double-checked locking — read-lock fast path for the common case, write-lock slow path with backoff for reconnection.

**TLS**: Configured via `TLSConfig` field. Supports custom CA certificates.

**Indexes**: `EnsureIndexes(ctx, collection, indexes)` is idempotent — safe to call on every startup.

### Redis (`commons/redis`)

**Constructor**: `redis.New(ctx, config)` returns a `*redis.Connection`.

**Three topologies:**

| Topology | Config Field | Use Case |
|----------|-------------|----------|
| Standalone | `Topology.Standalone` | Development, single-node |
| Sentinel | `Topology.Sentinel` | High availability with failover |
| Cluster | `Topology.Cluster` | Horizontal scaling |

**Authentication modes:**

| Mode | Config Field | Use Case |
|------|-------------|----------|
| Static password | `Auth.StaticPassword` | Standard Redis AUTH |
| GCP IAM | `Auth.GCPIAMAuth` | Google Cloud Memorystore |

**Distributed locks**: `redis.NewRedisLockManager(client, logger)` provides RedLock-based distributed locking via `AcquireLock` / `ReleaseLock`.

**Key interface**: `redis.UniversalClient` — works across all three topologies.

### RabbitMQ (`commons/rabbitmq`)

**Constructor**: Create a `rabbitmq.RabbitMQConnection` struct, then call `Connect()`.

**Confirmable publisher**: `rabbitmq.NewConfirmablePublisher(conn)` enables publisher confirms — every message is ACKed by the broker before `Publish` returns.

**Auto-recovery**: On connection loss, the client reconnects with exponential backoff (capped at 30s).

**DLQ topology**: `rabbitmq.SetupDLQTopology(channel, exchangeName, queueName)` creates the exchange, queue, DLQ exchange, and DLQ queue in one call.

**Credential sanitization**: Connection errors automatically strip usernames and passwords from error messages.

---

## 4. HTTP Toolkit (`net/http`)

### Middleware Stack

The recommended middleware order (outermost first):

```
CORS → Logging → Telemetry → Rate Limit → Auth → Handler
```

| Middleware | Constructor | Purpose |
|-----------|------------|---------|
| CORS | `http.WithCORS()` | Cross-origin resource sharing |
| Logging | `http.WithHTTPLogging(http.WithCustomLogger(logger))` | Request/response logging |
| Telemetry | `http.NewTelemetryMiddleware(tl).WithTelemetry(tl, skipPaths...)` | OTel span creation, metrics |
| Rate Limit | `ratelimit.WithDefaultRateLimit(redisConn)` | Distributed rate limiting (one-liner setup) |
| Basic Auth | `http.WithBasicAuth(username, password)` | HTTP Basic authentication |

### Rate Limiting (`net/http/ratelimit`) — Deep Reference

**Added in v4.2.0.** Redis-backed distributed fixed-window rate limiting with atomic Lua script (INCR + PEXPIRE in a single round-trip).

#### Quick Setup (One-Liner)

```go
// WithDefaultRateLimit sets up rate limiting with sensible defaults.
// Returns nil middleware (no-op) when RATE_LIMIT_ENABLED != "true".
app.Use(ratelimit.WithDefaultRateLimit(redisConn))
```

#### Full Setup (Custom Configuration)

```go
// New returns *RateLimiter (nil when disabled — all methods are nil-safe)
rl := ratelimit.New(redisConn,
    ratelimit.WithTier(ratelimit.AggressiveTier()),
    ratelimit.WithIdentityExtractor(ratelimit.IdentityFromIPAndHeader("X-API-Key")),
    ratelimit.WithFailPolicy(ratelimit.FailOpen),
    ratelimit.WithOnLimited(func(ctx *fiber.Ctx, identity string) {
        logger.Warn("rate limited", "identity", identity, "path", ctx.Path())
    }),
)

// Static tier — same limits for all requests
app.Use(rl.WithRateLimit(ratelimit.DefaultTier()))

// Dynamic tier — different limits based on request characteristics
app.Use(rl.WithDynamicRateLimit(func(ctx *fiber.Ctx) ratelimit.Tier {
    if ctx.Method() == "GET" {
        return ratelimit.RelaxedTier()
    }
    return ratelimit.DefaultTier()
}))

// Method-based tier selector (convenience for write-vs-read split)
app.Use(rl.WithDynamicRateLimit(ratelimit.MethodTierSelector))
```

#### Preset Tiers

All tiers are configurable via environment variables:

| Tier | Default Max | Default Window | Env Override (Max) | Env Override (Window) |
|------|------------|---------------|--------------------|-----------------------|
| `DefaultTier()` | 100 | 60s | `RATE_LIMIT_MAX` | `RATE_LIMIT_WINDOW_SEC` |
| `AggressiveTier()` | 30 | 60s | `RATE_LIMIT_AGGRESSIVE_MAX` | `RATE_LIMIT_AGGRESSIVE_WINDOW_SEC` |
| `RelaxedTier()` | 500 | 60s | `RATE_LIMIT_RELAXED_MAX` | `RATE_LIMIT_RELAXED_WINDOW_SEC` |

#### Identity Extractors

Determine who is being rate-limited:

| Extractor | Identifies By | Use Case |
|-----------|--------------|----------|
| `IdentityFromIP` | Client IP address | Public APIs |
| `IdentityFromHeader(name)` | Specific header value | API key-based limiting |
| `IdentityFromIPAndHeader(name)` | IP + header combined | Defense-in-depth |

#### Fail Policies

| Policy | On Redis Error | Use Case |
|--------|---------------|----------|
| `FailOpen` | Allow request through | Availability-first services |
| `FailClosed` | Reject request (429) | Security-first services |

#### Response Headers

When rate limiting is active, responses include:

| Header | Value | Description |
|--------|-------|-------------|
| `X-RateLimit-Limit` | Max requests | Tier's maximum requests per window |
| `X-RateLimit-Remaining` | Remaining | Requests remaining in current window |
| `X-RateLimit-Reset` | Unix timestamp | When the current window resets |
| `Retry-After` | Seconds | Seconds until next request allowed (only on 429) |

#### Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `RATE_LIMIT_ENABLED` | `"false"` | Master switch — `"true"` to enable |
| `RATE_LIMIT_MAX` | `100` | Default tier max requests per window |
| `RATE_LIMIT_WINDOW_SEC` | `60` | Default tier window in seconds |
| `RATE_LIMIT_AGGRESSIVE_MAX` | `30` | Aggressive tier max |
| `RATE_LIMIT_AGGRESSIVE_WINDOW_SEC` | `60` | Aggressive tier window |
| `RATE_LIMIT_RELAXED_MAX` | `500` | Relaxed tier max |
| `RATE_LIMIT_RELAXED_WINDOW_SEC` | `60` | Relaxed tier window |

#### Third-Party Middleware Integration (`RedisStorage`)

For integrating with other middleware that needs a rate-limit storage backend:

```go
storage := ratelimit.NewRedisStorage(redisConn)
// Use storage with third-party rate-limit middleware that accepts a storage interface
```

### Response Helpers

Standard response helpers for consistent API responses:

| Helper | Purpose | Example |
|--------|---------|---------|
| `http.Respond(ctx, statusCode, body)` | Send JSON response with status code | `http.Respond(ctx, 200, entity)` |
| `http.RespondStatus(ctx, statusCode)` | Send status-only response (no body) | `http.RespondStatus(ctx, 204)` |
| `http.RespondError(ctx, err)` | Send error response with appropriate status | `http.RespondError(ctx, err)` |
| `http.RenderError(ctx, statusCode, msg)` | Send error with custom status and message | `http.RenderError(ctx, 400, "invalid input")` |

### Request Validation

`http.ParseBodyAndValidate(ctx, &request)` parses the Fiber request body and runs struct tag validation.

**Additional validation helpers:**

| Helper | Purpose | Example |
|--------|---------|---------|
| `http.ValidateStruct(v)` | Validate any struct against its tags | `http.ValidateStruct(request)` |
| `http.ValidateSortDirection(dir)` | Validate sort direction ("asc"/"desc") | `http.ValidateSortDirection(query.Sort)` |
| `http.ValidateLimit(limit)` | Validate pagination limit is within bounds | `http.ValidateLimit(query.Limit)` |

**Custom validation tags:**

| Tag | Purpose | Example |
|-----|---------|---------|
| `positive_decimal` | Decimal > 0 | Amount fields |
| `positive_amount` | Amount > 0 | Transaction values |
| `nonnegative_amount` | Amount >= 0 | Balance fields |

### Context & Ownership Verification

| Helper | Purpose |
|--------|---------|
| `http.ParseAndVerifyTenantScopedID(ctx, paramName)` | Parse ID from path param and verify it belongs to the authenticated tenant |
| `http.ParseAndVerifyResourceScopedID(ctx, paramName, ownerID)` | Parse ID and verify it belongs to the specified resource owner |
| `http.VerifyOwnership(ctx, expectedOwnerID)` | Check that the authenticated user owns the requested resource (403 if not) |

### Pagination (Three Styles)

| Style | Use Case | Cursor Type |
|-------|----------|-------------|
| Offset/Limit | Simple lists | Page number + size |
| Keyset (UUID) | UUID-based cursor | Last-seen UUID |
| Timestamp | Time-ordered data | Last-seen timestamp |
| Sort Cursor | Custom sort orders | Encoded sort position |

All pagination helpers return a standard `CursorPagination` response with `next` / `previous` links.

### Health Checks

`http.HealthWithDependencies(deps...)` returns a handler that checks all dependencies and reports circuit breaker state.

`http.Version` returns the service version from build-time variables.

### SSRF-Safe Reverse Proxy

`http.ServeReverseProxy(target, ctx)` proxies requests with DNS rebinding prevention — the target hostname is resolved and validated before the connection is established.

---

## 5. Observability

### Logger (`commons/log` + `commons/zap`)

**Interface**: Always program against `log.Logger`. This is the universal logging contract — every package in lib-commons accepts it.

**Implementation**: Use `zap.New(config)` for production. It provides:

- Structured JSON logging
- OTel log bridge (logs appear as OTel log records)
- Runtime level adjustment (`logger.SetLevel("debug")`)
- `logger.Sync(ctx)` flushes buffered logs on shutdown
- **v4.3.0+**: Timestamp field changed from `"ts"` (Unix epoch float) to `"timestamp"` (ISO 8601 string). If you parse logs programmatically, update your parsers.
- **Multi-tenant**: In multi-tenant contexts, `tenant_id` is automatically injected into log entries when the tenant context is present.

### Tracing (`commons/opentelemetry`)

Every I/O package in lib-commons auto-creates OTel spans. You rarely need to create spans manually.

**Error recording**: Use `opentelemetry.HandleSpanError(&span, err)` to record errors on spans. This sets the span status and adds the error as an event.

**Redaction**: The OTel setup automatically redacts sensitive fields from span attributes using the `security` package.

**Noop providers**: When `CollectorExporterEndpoint` is empty, `NewTelemetry` registers noop global Core threeProvider, MeterProvider, and LoggerProvider. This means services can always call `otel.Core three()` and `otel.Meter()` without checking whether telemetry is configured — calls simply no-op.

### Metrics (`commons/opentelemetry/metrics`)

`tl.MetricsFactory` provides thread-safe builders:

| Builder | Method | Use Case |
|---------|--------|----------|
| Counter | `metrics.NewCounter(name, desc)` | Monotonic counts (requests, errors) |
| Gauge | `metrics.NewGauge(name, desc)` | Point-in-time values (connections, queue depth) |
| Histogram | `metrics.NewHistogram(name, desc)` | Distributions (latency, payload sizes) |

**Pre-defined metrics** (emitted by various packages):

- `*_connection_failures_total` — every infrastructure package
- `runtime_panic_recovered_total` — `runtime.SafeGo`
- `assertion_failures_total` — `assert`

### Panic Recovery (`commons/runtime`) — Defense-in-Depth Crown Jewel

The `runtime` package is not just "safe goroutine launching" — it's a **complete panic observability pipeline** that ensures no panic ever goes unnoticed in production. Every recovered panic triggers a three-layer response:

1. **Structured log** with stack trace, goroutine name, component label
2. **OTel span event** (`panic.recovered`) on the active trace, with sanitized value + stack + component attributes, span status set to `Error`
3. **Metric increment** on `panic_recovered_total` counter, labeled by component and goroutine name
4. **Error reporter callback** (optional, e.g., Sentry) via `SetErrorReporter`

**MUST launch goroutines with `runtime.SafeGo`**:

```go
// Context-aware variant (preferred) — carries trace context into the goroutine
runtime.SafeGoWithContextAndComponent(ctx, logger, "transaction-service", "balance-updater",
    runtime.KeepRunning, func(ctx context.Context) {
        // your goroutine logic — ctx carries the parent trace
    },
)

// Simple variant
runtime.SafeGo(logger, "worker-name", runtime.KeepRunning, func() {
    // your goroutine logic
})
```

**Panic Policies** — choose per goroutine:

| Policy | Behavior | Use When |
|--------|----------|----------|
| `runtime.KeepRunning` | Recover, log, continue | HTTP/gRPC handlers, background workers |
| `runtime.CrashProcess` | Recover, log, re-panic | Critical invariant violations where continuing is unsafe |

**For defer-based recovery** (inside your own goroutines or framework handlers):

```go
func handleRequest(ctx context.Context) {
    defer runtime.RecoverWithPolicyAndContext(ctx, logger, "api", "handleRequest", runtime.KeepRunning)
    // ... handler logic
}
```

**For framework integration** (Fiber, gRPC interceptors that recover panics themselves):

```go
// Fiber's recover.New() catches the panic — pass the recovered value into the pipeline
app.Use(recover.New(recover.Config{
    EnableStackTrace: true,
    StackTraceHandler: func(c *fiber.Ctx, e interface{}) {
        runtime.HandlePanicValue(c.UserContext(), logger, e, "api", c.Path())
    },
}))
```

**Production mode** — controls data sensitivity:

```go
runtime.SetProductionMode(true)
// Effect: panic values are replaced with "panic recovered (details redacted)"
// in span events and logs. Stack traces are truncated to 4096 bytes.
// Sensitive patterns (password=, token=, api_key=) are always redacted regardless of mode.
```

**Error reporter integration** — plug in external error tracking (Sentry, Bugsnag, etc.):

```go
runtime.SetErrorReporter(mySentryReporter) // implements ErrorReporter interface
// Every panic now also calls: reporter.CaptureException(ctx, err, tags)
```

**Startup initialization** (required once, after telemetry is set up):

```go
runtime.InitPanicMetrics(tl.MetricsFactory, logger)
runtime.SetProductionMode(true)
runtime.SetErrorReporter(myReporter) // optional
```

### Assertions (`commons/assert`) — Defense-in-Depth Crown Jewel

The `assert` package provides **production-grade runtime assertions** — not test assertions, not debug-only checks. These assertions are designed to remain **permanently enabled in production** and fire a **three-layer observability trident** on every failure:

1. **Structured log** with assertion type, message, component, operation, and key-value context
2. **OTel span event** (`assertion.failed`) on the active trace with all attributes
3. **Metric increment** on `assertion_failed_total` counter, labeled by component, operation, and assertion type

Assertions **never panic** — they return errors, making them safe for production hot paths.

**Creating an asserter** — scoped to a component and operation for observability labeling:

```go
a := assert.New(ctx, logger, "transaction-service", "create-posting")
```

**Assertion methods** — each fires the full observability trident on failure:

```go
// General condition check
if err := a.That(ctx, amount.IsPositive(), "amount must be positive",
    "amount", amount.String(), "account_id", accountID); err != nil {
    return err
}

// Nil check (handles typed nils via reflect — catches (*MyStruct)(nil) in interfaces)
if err := a.NotNil(ctx, dbConn, "database connection is nil",
    "tenant_id", tenantID); err != nil {
    return err
}

// Empty string check
if err := a.NotEmpty(ctx, tenantID, "tenant ID is empty"); err != nil {
    return err
}

// Error check — auto-includes error type in context
if err := a.NoError(ctx, dbErr, "database query failed",
    "query", "SELECT balance", "account_id", accountID); err != nil {
    return err
}

// Unreachable code — always fails, use for impossible states
if err := a.Never(ctx, "reached impossible branch",
    "status", status, "operation", op); err != nil {
    return err
}

// Goroutine halt — calls runtime.Goexit() (defers still run, other goroutines unaffected)
a.Halt(err) // only halts if err != nil
```

**Domain predicates** — composable pure functions for financial validations:

```go
// Numeric
assert.Positive(n)                    // int64 > 0
assert.NonNegative(n)                 // int64 >= 0
assert.InRange(n, min, max)           // min <= n <= max

// Financial (shopspring/decimal)
assert.PositiveDecimal(amount)        // amount > 0
assert.NonNegativeDecimal(amount)     // amount >= 0
assert.ValidAmount(amount)            // exponent in [-18, 18]
assert.ValidScale(scale)              // 0 <= scale <= 18
assert.DebitsEqualCredits(d, c)       // double-entry bookkeeping invariant
assert.NonZeroTotals(d, c)            // both sides are non-zero
assert.BalanceSufficientForRelease(onHold, releaseAmt)

// Transaction state machine
assert.ValidTransactionStatus(status)             // CREATED, APPROVED, PENDING, CANCELED, NOTED
assert.TransactionCanTransitionTo(current, target) // e.g., PENDING → APPROVED OK, APPROVED → CREATED NOT OK
assert.TransactionCanBeReverted(status, hasParent) // only APPROVED + no parent
assert.TransactionHasOperations(ops)
assert.TransactionOperationsContain(ops, allowed)  // subset check

// Network / infrastructure
assert.ValidUUID(s)
assert.ValidPort(port)                // "1" to "65535"
assert.ValidSSLMode(mode)             // PostgreSQL SSL modes

// Time
assert.DateNotInFuture(date)
assert.DateAfter(date, reference)
```

**Composing predicates with assertions** — the predicates return `bool`, the asserter provides observability:

```go
a := assert.New(ctx, logger, "ledger", "post-transaction")

if err := a.That(ctx, assert.DebitsEqualCredits(totalDebits, totalCredits),
    "double-entry violation: debits != credits",
    "debits", totalDebits.String(), "credits", totalCredits.String(),
    "transaction_id", txnID); err != nil {
    return err // observability trident already fired
}

if err := a.That(ctx, assert.TransactionCanTransitionTo(currentStatus, targetStatus),
    "invalid status transition",
    "from", currentStatus, "to", targetStatus); err != nil {
    return err
}
```

**How the observability trident works** — a single assertion failure produces:

```
// 1. Structured log:
ERROR assertion failed: double-entry violation: debits != credits
  component=ledger operation=post-transaction assertion=That
  debits=150.00 credits=149.50 transaction_id=abc-123

// 2. OTel span event (on the active trace):
Event: assertion.failed
  assertion.type = "That"
  assertion.message = "double-entry violation: debits != credits"
  assertion.component = "ledger"
  assertion.operation = "post-transaction"
  // + all key-value pairs as attributes

// 3. Metric:
assertion_failed_total{component="ledger", operation="post-transaction", assertion="That"} += 1
```

**Production mode behavior:**
- Stack traces are **suppressed** in assertion failure logs and span events (controlled by `runtime.SetProductionMode(true)` or `ENV=production`)
- In development mode, stack traces are included for debugging

**The `AssertionError` type** — rich, unwrappable error:

```go
var assertErr *assert.AssertionError
if errors.As(err, &assertErr) {
    fmt.Println(assertErr.Component)  // "ledger"
    fmt.Println(assertErr.Operation)  // "post-transaction"
    fmt.Println(assertErr.Assertion)  // "That"
}
// Also: errors.Is(err, assert.ErrAssertionFailed) == true
```

**Why this matters for every Lerian service:**
- Every `nil` receiver in lib-commons fires an assertion — so nil-pointer bugs are visible in metrics dashboards before they become incidents
- Financial invariants (debits == credits, valid status transitions) are continuously verified in production, not just in tests
- The metric `assertion_failed_total` is an early warning system — a spike means a code path hit an unexpected state

**Startup initialization** (required once, after telemetry is set up):

```go
assert.InitAssertionMetrics(tl.MetricsFactory)
```

---

## 6. Resilience & Utilities

### Circuit Breaker (`commons/circuitbreaker`)

```go
manager := circuitbreaker.NewManager(logger)
result, err := manager.Execute("service-name", func() (interface{}, error) {
    return callExternalService()
})
```

**Pre-built configurations:**

| Config | Threshold | Timeout | Use Case |
|--------|-----------|---------|----------|
| `Default` | 5 failures | 60s | General purpose |
| `Aggressive` | 3 failures | 30s | Fast-fail services |
| `Conservative` | 10 failures | 120s | Tolerant services |
| `HTTPService` | 5 failures | 60s | HTTP backends |
| `Database` | 3 failures | 30s | Database connections |

The manager tracks per-service state and emits health check data consumable by `http.HealthWithDependencies`.

### Backoff (`commons/backoff`)

```go
delay := backoff.ExponentialWithJitter(100*time.Millisecond, attempt)
```

Uses the AWS Full Jitter strategy: `sleep = random_between(0, min(cap, base * 2^attempt))`.

Context-aware: `backoff.SleepWithContext(ctx, delay)` cancels the sleep if the context is done.

### Safe Math (`commons/safe`)

| Function | Purpose | Example |
|----------|---------|---------|
| `safe.DivideOrZero(a, b)` | Division that returns 0 instead of panicking | `safe.DivideOrZero(100, 0)` returns `0` |
| `safe.First(slice)` | Returns `(T, error)` instead of panicking on empty | `val, err := safe.First(items)` |
| `safe.CachedRegexp(pattern)` | Compile-once regex | `re := safe.CachedRegexp(`\d+`)` |

### Error Group (`commons/errgroup`)

```go
g := errgroup.New(ctx)
g.Go(func() error { return task1() })
g.Go(func() error { return task2() })
err := g.Wait() // returns first error, cancels remaining
```

Difference from `golang.org/x/sync/errgroup`: panics in goroutines are recovered and converted to errors instead of crashing the process.

### Pointers (`commons/pointers`)

Literal-to-pointer helpers for struct initialization:

```go
entity := &Entity{
    Name:      pointers.String("example"),
    Active:    pointers.Bool(true),
    CreatedAt: pointers.Time(time.Now()),
    Count:     pointers.Int64(42),
    Rate:      pointers.Float64(0.95),
}
```

### Constants (`commons/constants`)

Shared constants used across Lerian services:

- HTTP headers (e.g., `X-Request-ID`, `X-Tenant-ID`)
- Error codes
- Pagination defaults
- OTel attribute keys

---

## 7. Security

### JWT (`commons/jwt`)

**Parse + verify in one call:**

```go
claims, err := jwt.ParseAndValidate(tokenString, secretKey, []string{"HS256"})
```

- Supports HS256, HS384, HS512
- Constant-time signature comparison
- Algorithm allowlist prevents algorithm confusion attacks
- `jwt.ValidateTimeClaims(claims)` checks `exp`, `nbf`, `iat`

**Sign:**

```go
token, err := jwt.Sign(claims, secretKey, "HS256")
```

### Encryption (`commons/crypto`)

```go
c := &crypto.Crypto{
    HashSecretKey:    "hmac-secret",
    EncryptSecretKey: "hex-encoded-32-byte-key",
}
_ = c.InitializeCipher()

encrypted, _ := c.Encrypt("sensitive data")
decrypted, _ := c.Decrypt(encrypted)
hashed       := c.Hash("data to hash")
```

- AES-256-GCM for encryption (authenticated encryption)
- HMAC-SHA256 for hashing
- Credential redaction in error messages

### Sensitive Field Detection (`commons/security`)

```go
isSensitive := security.IsSensitiveField("password")    // true
isSensitive = security.IsSensitiveField("userName")       // false
isSensitive = security.IsSensitiveField("credit_card")    // true
```

Matches 90+ patterns, case-insensitive, supports both camelCase and snake_case. Used internally by the OTel redaction layer and log sanitization.

### AWS Secrets Manager (`commons/secretsmanager`)

```go
creds, err := secretsmanager.GetM2MCredentials(
    ctx, awsClient, "production", tenantOrgID, "my-app", "target-service",
)
```

- Path traversal protection (rejects `../` in inputs)
- Returns structured credentials (client ID, client secret, endpoint)
- Used by plugins for per-tenant M2M authentication with product APIs

---

## 8. Transaction Domain

### Intent Planning (`commons/transaction`)

```go
plan, err := transaction.BuildIntentPlan(input, status)
```

Supports three allocation strategies:

| Strategy | Description | Example |
|----------|-------------|---------|
| **Amount** | Fixed amount per entry | `{Amount: 100.00}` |
| **Share** | Percentage-based allocation | `{Share: 50}` means 50% |
| **Remainder** | Gets whatever is left | One entry per side |

### Balance Validation

```go
err := transaction.ValidateBalanceEligibility(plan, balances)
```

Checks:
- Sufficient funds for debits
- Account eligibility for the operation type
- Cross-scope validation (no mixing incompatible accounts)

### Posting

```go
updatedBalance, err := transaction.ApplyPosting(balance, posting)
```

Implements the operation/status state machine:

| Operation | Status | Effect |
|-----------|--------|--------|
| `DEBIT` | `ACTIVE` | Decreases available balance |
| `CREDIT` | `ACTIVE` | Increases available balance |
| `ON_HOLD` | `ACTIVE` | Moves funds to on-hold |
| `RELEASE` | `ACTIVE` | Releases held funds back to available |

### Outbox Pattern (`commons/outbox`)

**Repository:**

```go
repo := outboxpg.NewRepository(pgClient, tenantResolver, tenantDiscoverer)
```

**Dispatcher:**

```go
dispatcher := outbox.NewDispatcher(repo, handlers, logger, tracer, opts...)
dispatcher.Run(launcher)
```

**Event lifecycle**: `PENDING` -> `PROCESSING` -> `PUBLISHED` (success) or `FAILED` -> `INVALID` (after max attempts).

**Multi-tenant strategies:**

| Strategy | How It Works | Config |
|----------|-------------|--------|
| Schema-per-tenant | Each tenant has its own PostgreSQL schema | `SchemaResolver` |
| Column-per-tenant | Shared table with `tenant_id` column filter | `ColumnResolver` |

**Sensitive data**: Error messages are sanitized before storage — URLs, tokens, and card numbers are redacted automatically.

---

## 9. Tenant Manager (Deep Reference)

The dispatch layer subsystem provides complete database-per-tenant isolation. This is a major subsystem with its own middleware, connection pool managers, consumer infrastructure, and **event-driven tenant discovery** (v4.5.0+).

### Architecture Flow

```
HTTP request
  → JWT middleware (extract tenantId from token)
    → dispatch layer client (fetch tenant config from TM API)
      → per-tenant connection pool (get or create DB connection)
        → context injection (db available via ctx)
          → repository layer (uses ctx to get tenant-scoped DB)

Event-driven flow (v4.5.0+):
  Redis pub/sub → TenantEventListener → callback
    → tenant.added: provision new tenant connections
    → tenant.connections.updated: refresh connection pools
    → tenant.credentials.rotated: rotate credentials in pools
```

### Setup Pattern

```go
// 1. Create the TM client
//    v4.2.0+: endpoint is /connections, path prefix is /v1/associations/
tmClient, _ := client.NewClient("https://dispatch layer:8080", logger,
    client.WithServiceAPIKey(os.Getenv("TM_API_KEY")),
    client.WithCache(cache.NewInMemoryCache()),
    client.WithCacheTTL(5*time.Minute),
    client.WithCircuitBreaker(5, 30*time.Second),
)

// 2. Create per-resource managers
pgManager := tmpostgres.NewManager(tmClient, "my-service",
    tmpostgres.WithLogger(logger),
    tmpostgres.WithModule("transaction"),
    tmpostgres.WithMaxTenantPools(100),
)

mongoManager := tmmongo.NewManager(tmClient, "my-service",
    tmmongo.WithLogger(logger),
    tmmongo.WithModule("transaction"),
)

// 3. Attach middleware
//    v4.6.0: Use unified WithPG/WithMB API (MultiPoolMiddleware removed)
//    WithPG/WithMB accept optional module parameter for multi-module services
mw := middleware.NewTenantMiddleware(
    middleware.WithPG(pgManager),
    middleware.WithMB(mongoManager),
    middleware.WithTenantCache(tenantCache),
    middleware.WithTenantLoader(tenantLoader),
)
app.Use(mw.WithTenantDB)

// 4. In repositories, access tenant-scoped connections
//    v4.6.0: Context functions are variadic — module parameter is optional
func (r *Repo) Get(ctx context.Context, id string) (*Entity, error) {
    db := tmcore.GetPGContext(ctx)  // no module = default
    if db == nil {
        return nil, fmt.Errorf("tenant postgres connection missing from context")
    }
    // use db for queries — automatically scoped to the tenant's database
}

// For multi-module services, pass the module name:
func (r *Repo) GetFromAudit(ctx context.Context, id string) (*AuditEntry, error) {
    db := tmcore.GetPGContext(ctx, "audit")  // specific module
    if db == nil {
        return nil, fmt.Errorf("audit postgres connection missing from context")
    }
    // ...
}
```

### Variadic Context API (v4.6.0)

The context functions now use variadic module parameters instead of separate per-module functions:

| Old API (pre-v4.6.0) | New API (v4.6.0) |
|----------------------|-------------------|
| `ContextWithTenantPG(ctx, pg)` | `ContextWithPG(ctx, pg)` (default module) |
| `ContextWithTenantPG(ctx, pg)` for module X | `ContextWithPG(ctx, pg, "moduleX")` (specific module) |
| `GetPGContext(ctx)` | `GetPGContext(ctx)` (default module) |
| Per-module context function | `GetPGContext(ctx, "moduleX")` (specific module) |
| `ContextWithTenantMB(ctx, mb)` | `ContextWithMB(ctx, mb)` (default module) |
| Per-module MB context function | `GetMBContext(ctx, "moduleX")` (specific module) |

### Event-Driven Tenant Discovery (v4.5.0+)

**Replaces the watcher-based model** (watcher removed in v4.5.0). Tenants are discovered via Redis pub/sub events instead of polling.

#### Events

| Event | Channel | Payload | When |
|-------|---------|---------|------|
| `tenant.added` | `tenant-events` | Tenant config JSON | New tenant registered in TM |
| `tenant.connections.updated` | `tenant-events` | Updated connection info | Tenant DB connection changed |
| `tenant.credentials.rotated` | `tenant-events` | Rotation metadata | Credentials rotated (scheduled or emergency) |

#### TenantEventListener (HTTP-Only Services)

For services that only handle HTTP requests (no RabbitMQ consumer), use `TenantEventListener`:

```go
import tmevent "github.com/LerianStudio/lib-commons/v4/commons/dispatch layer/event"

listener := tmevent.NewTenantEventListener(redisClient, logger,
    tmevent.WithOnTenantAdded(func(ctx context.Context, tenant TenantConfig) {
        // Provision connections for new tenant
        pgManager.Provision(ctx, tenant.ID)
        mongoManager.Provision(ctx, tenant.ID)
        logger.Info("new tenant provisioned", "tenant_id", tenant.ID)
    }),
    tmevent.WithOnConnectionsUpdated(func(ctx context.Context, tenant TenantConfig) {
        // Refresh connection pools with new connection info
        pgManager.Refresh(ctx, tenant.ID)
        mongoManager.Refresh(ctx, tenant.ID)
    }),
    tmevent.WithOnCredentialsRotated(func(ctx context.Context, tenant TenantConfig) {
        // Rotate credentials in existing pools
        pgManager.RotateCredentials(ctx, tenant.ID)
    }),
)

// Start listening (blocks — run in a goroutine or via Launcher)
runtime.SafeGoWithContextAndComponent(ctx, logger, "my-service", "tenant-listener",
    runtime.KeepRunning, func(ctx context.Context) {
        listener.Listen(ctx)
    },
)
```

#### NewTenantPubSubRedisClient (v4.6.0)

Helper for creating a Redis client specifically configured for tenant pub/sub with TLS:

```go
import tmredis "github.com/LerianStudio/lib-commons/v4/commons/dispatch layer/redis"

pubsubClient := tmredis.NewTenantPubSubRedisClient(
    os.Getenv("MULTI_TENANT_REDIS_HOST"),
    os.Getenv("MULTI_TENANT_REDIS_PORT"),
    os.Getenv("MULTI_TENANT_REDIS_PASSWORD"),
    logger,
)
// Use pubsubClient with TenantEventListener or consumer
```

**Environment variable**: `MULTI_TENANT_REDIS_TLS` — set to `"true"` to enable TLS for the pub/sub Redis connection.

#### TenantLoader with Callback (v4.6.0 — `tenantcache` package)

The `tenantcache` package provides `TenantLoader` with a callback for event-driven tenant addition:

```go
import "github.com/LerianStudio/lib-commons/v4/commons/dispatch layer/tenantcache"

loader := tenantcache.NewTenantLoader(tmClient, logger,
    tenantcache.WithOnTenantLoaded(func(ctx context.Context, tenant TenantConfig) {
        // Called for each tenant loaded — useful for provisioning side effects
        logger.Info("tenant loaded into cache", "tenant_id", tenant.ID)
    }),
)
```

### Isolation Modes

| Mode | How It Works | When to Use |
|------|-------------|-------------|
| `isolated` (default) | Separate database per tenant | Maximum isolation, regulatory compliance |
| `schema` | Shared database, separate PostgreSQL schemas | Lower overhead, acceptable isolation |

### S3 and Valkey (Key Namespacing)

These packages do not manage connection pools — they provide key namespacing utilities:

**S3:**
```go
// v4.6.0: Renamed from GetObjectStorageKeyForTenant
key := s3.GetS3KeyStorageContext(ctx, "my-file.pdf")
// returns "{tenantID}/my-file.pdf"
```

**Valkey (Redis):**
```go
key := valkey.GetKeyContext(ctx, "session:abc")
// returns "tenant:{tenantID}:session:abc"
```

### Multi-Tenant Consumer (RabbitMQ)

For processing messages across tenants with automatic tenant context injection:

```go
consumer, _ := consumer.NewMultiTenantConsumerWithError(
    rmqManager, redisClient, config, logger,
    consumer.WithPG(pgManager),
    consumer.WithMB(mongoManager),
)

consumer.Register("my-queue", func(ctx context.Context, d amqp.Delivery) error {
    db := tmcore.GetPGContext(ctx)                     // auto-resolved for this tenant
    if db == nil {
        return fmt.Errorf("tenant postgres connection missing from context")
    }
    // process message with tenant-scoped database
    return nil
})

// EnsureConsumerStarted starts the consumer if not already running
consumer.EnsureConsumerStarted(ctx)

// StopConsumer gracefully stops the consumer
defer consumer.StopConsumer(ctx)
```

The consumer dynamically discovers tenants and creates per-tenant connections on demand.

### Unified Middleware API (v4.6.0)

**MultiPoolMiddleware has been removed.** Use the unified `WithPG`/`WithMB` options on `NewTenantMiddleware`:

```go
// v4.6.0 — unified API with optional module parameter
mw := middleware.NewTenantMiddleware(
    middleware.WithPG(pgManager),              // default module
    middleware.WithPG(auditPGManager, "audit"), // named module
    middleware.WithMB(mongoManager),            // default module
)
app.Use(mw.WithTenantDB)
```

In request handlers, retrieve the correct connection by module:

```go
defaultDB := tmcore.GetPGContext(ctx)          // default module
auditDB := tmcore.GetPGContext(ctx, "audit")    // "audit" module
defaultMB := tmcore.GetMBContext(ctx)           // default module
```

---

## 10. Systemplane (Deep Reference)

The systemplane is a database-backed, hot-reloadable runtime configuration system. Services register key definitions at startup, read config/settings from a snapshot (lock-free atomic pointer), and react to changes via a change feed that triggers bundle rebuilds.

### Key Concepts

| Concept | Description |
|---------|-------------|
| **Config** (`Kind = "config"`) | Service-level settings (DB pool sizes, feature flags). One global scope. |
| **Setting** (`Kind = "setting"`) | Can be global or per-tenant. |
| **KeyDef** | Registry entry with type, default, validator, secret flag, redact policy, apply behavior, mutability. |
| **ApplyBehavior** | Controls reaction to changes (see table below). |
| **Snapshot** | Immutable point-in-time view. Read via `supervisor.Snapshot()` — lock-free atomic pointer load. |
| **RuntimeBundle** | Application-defined struct holding live infrastructure (DB pools, rate limiters, etc.). |
| **Supervisor** | Manages the bundle lifecycle — build, reconcile, atomic swap, close previous. |

### ApplyBehavior Values

| Behavior | When Changed... | Use Case |
|----------|----------------|----------|
| `LiveRead` | Re-read from snapshot on next access | Feature flags, simple thresholds |
| `WorkerReconcile` | Run registered reconcilers | Rate limiter adjustments |
| `BundleRebuild` | Rebuild entire RuntimeBundle | DB pool size changes |
| `BootstrapOnly` | Immutable at runtime (restart required) | Listen addresses, TLS certs |

### Setup Pattern

```go
// 1. Bootstrap backend (reads SYSTEMPLANE_* env vars)
cfg, _ := bootstrap.LoadFromEnv()
resources, _ := builtin.NewBackendFromConfig(ctx, cfg)
defer resources.Closer.Close()

// 2. Registry — declare all config keys
reg := registry.New()
reg.MustRegister(domain.KeyDef{
    Key:             "db.pool.max_open",
    Kind:            domain.KindConfig,
    AllowedScopes:   []domain.Scope{domain.ScopeGlobal},
    ValueType:       domain.ValueTypeInt,
    DefaultValue:    25,
    MutableAtRuntime: true,
    ApplyBehavior:   domain.ApplyBundleRebuild,
    Component:       "postgres",
    Description:     "Max open DB connections",
})

// 3. Supervisor + Manager
builder, _ := service.NewSnapshotBuilder(reg, resources.Store)
sup, _ := service.NewSupervisor(service.SupervisorConfig{
    Builder:      builder,
    Factory:      myBundleFactory,
    Reconcilers:  myReconcilers,
})
mgr, _ := service.NewManager(service.ManagerConfig{
    Registry:   reg,
    Store:      resources.Store,
    History:    resources.History,
    Supervisor: sup,
    Builder:    builder,
})

// 4. Initial load — builds the first snapshot and RuntimeBundle
_ = sup.Reload(ctx, "startup")

// 5. HTTP API — CRUD for config/settings with optimistic concurrency
handler, _ := fiberhttp.NewHandler(mgr, identityResolver, authorizer)
handler.Mount(app)

// 6. Change feed — hot-reload on config changes
go resources.ChangeFeed.Subscribe(ctx, func(signal ports.ChangeSignal) {
    _ = mgr.ApplyChangeSignal(ctx, signal)
})
```

### Environment Variables

| Variable | Values | Purpose |
|----------|--------|---------|
| `SYSTEMPLANE_BACKEND` | `postgres`, `mongodb` | Which database backend to use |
| `SYSTEMPLANE_POSTGRES_DSN` | DSN string | PostgreSQL connection string |
| `SYSTEMPLANE_MONGODB_URI` | URI string | MongoDB connection string |
| `SYSTEMPLANE_MONGODB_DATABASE` | Database name | MongoDB database name |
| `SYSTEMPLANE_SECRET_KEY` | Hex-encoded key | AES-256-GCM key for secret values |

### Snapshot Reading

Reading configuration is lock-free and allocation-free:

```go
snap := supervisor.Snapshot()
maxOpen, _ := snap.GetInt("db.pool.max_open", domain.ScopeGlobal, "")
featureEnabled, _ := snap.GetBool("feature.new_ui", domain.ScopeGlobal, "")
tenantLimit, _ := snap.GetInt("rate.limit", domain.ScopeTenant, tenantID)
```

---

## 11. Root Package & Utilities

The root `commons` package (`github.com/LerianStudio/lib-commons/v4/commons`) provides foundational utilities used across all Lerian services. These are building blocks that other packages and services depend on.

### App Lifecycle (`app.go`)

The `Launcher` provides concurrent app component lifecycle management:

```go
launcher := commons.NewLauncher(logger)

// Add components — each runs concurrently
launcher.Add("http-server", func(ctx context.Context) error {
    return sm.StartWithGracefulShutdown()
})
launcher.Add("consumer", func(ctx context.Context) error {
    return consumer.Run(ctx)
})
launcher.Add("event-listener", func(ctx context.Context) error {
    return listener.Listen(ctx)
})

// Run blocks until all complete or first error — cancels remaining on error
err := launcher.Run(ctx)
```

### Request-Scoped Context Helpers (`context.go`)

Context utilities for carrying request-scoped data:

```go
// Attach values to context
ctx = commons.ContextWithRequestID(ctx, requestID)
ctx = commons.ContextWithTenantID(ctx, tenantID)
ctx = commons.ContextWithUserID(ctx, userID)

// Retrieve values from context
requestID := commons.GetRequestID(ctx)
tenantID := commons.GetTenantID(ctx)

// Safe timeout — creates a derived context with timeout, returning cancel func
ctx, cancel := commons.WithTimeoutSafe(ctx, 30*time.Second)
defer cancel()
```

### Business Error Mapping (`errors.go`)

Maps domain-level errors to HTTP status codes consistently:

```go
// ValidateBusinessError checks an error against known business error patterns
// and returns the appropriate HTTP status code and user-friendly message
statusCode, message := commons.ValidateBusinessError(err)

// Common mappings:
// ErrNotFound → 404
// ErrConflict → 409
// ErrValidation → 422
// ErrUnauthorized → 401
// ErrForbidden → 403
```

### UUID Generation (`utils.go`)

```go
// Generate a UUIDv7 (time-ordered, sortable)
id := commons.GenerateUUIDv7()
```

**Why UUIDv7**: Time-ordered UUIDs improve database index locality and make natural ordering possible without additional timestamp columns.

### Struct-to-JSON & Metrics Helpers (`utils.go`)

```go
// Convert any struct to JSON bytes (convenience wrapper)
jsonBytes, err := commons.StructToJSON(entity)

// Metrics registration helpers used internally by other packages
```

### String Utilities (`stringUtils.go`)

```go
// Remove accents from strings (useful for search normalization)
normalized := commons.RemoveAccents("caf\u00e9")  // returns "cafe"

// Case conversion
snake := commons.ToSnakeCase("myFieldName")   // returns "my_field_name"
camel := commons.ToCamelCase("my_field_name")  // returns "myFieldName"

// Hashing utilities
hash := commons.HashString("input-data")
```

### Date/Time Validation (`time.go`)

```go
// Validate date strings
valid := commons.IsValidDate("2026-03-28")  // true
valid = commons.IsValidDate("not-a-date")    // false

// Parse dates with known formats
t, err := commons.ParseDate("2026-03-28")

// Validate and parse datetime
t, err := commons.ParseDateTime("2026-03-28T10:30:00Z")
```

### Environment Variable Helpers (`os.go`)

```go
// Get environment variable with fallback default
value := commons.GetenvOrDefault("PORT", "3000")

// Set struct fields from environment variables using struct tags
type Config struct {
    Port     string `env:"PORT" default:"3000"`
    LogLevel string `env:"LOG_LEVEL" default:"info"`
    Debug    bool   `env:"DEBUG" default:"false"`
}

cfg := &Config{}
commons.SetConfigFromEnvVars(cfg)
```

---

## 12. Cross-Cutting Patterns

These patterns appear consistently across all lib-commons packages. Understanding them helps predict how any package behaves.

### 1. Nil-Receiver Safety with Telemetry

Every exported method on a struct guards against nil receiver. Before returning a sentinel error, the method fires an OTel assertion so the nil-receiver call is observable in traces and metrics.

### 2. Lazy Connect with Double-Checked Locking

Database packages (`postgres.Resolver()`, `mongo.ResolveClient()`, `redis.GetClient()`) defer the actual TCP connection to first use. The pattern:

- **Read-lock fast path**: If already connected, return immediately (no write lock contention).
- **Write-lock slow path**: If not connected, acquire write lock, check again (double-check), connect with backoff.

This means constructors (`postgres.New`, `mongo.NewClient`, `redis.New`) never block on DNS or TCP.

### 3. Create-Verify-Swap

When reconnecting, new connections are created and pinged before old ones are closed. This ensures there is no availability gap during reconnection — the old connection serves requests until the new one is verified healthy.

### 4. Credential Sanitization

All infrastructure packages strip credentials from error messages automatically:

- PostgreSQL DSNs: Regex-based password removal
- MongoDB URIs: `url.Redacted()` built-in
- RabbitMQ: Username/password stripped
- Redis: Password removed from connection strings

### 5. OTel Tracing on All I/O

Every exported method that performs I/O starts an OTel span. This means you get distributed tracing for free — database queries, HTTP calls, message publishing, and cache operations all appear in your trace waterfall without manual instrumentation.

### 6. Metrics via MetricsFactory

All connection packages accept a `MetricsFactory` (optional — nil disables metrics). Standard metric emitted by all: `{package}_connection_failures_total` counter. Additional package-specific metrics are documented per-package.

### 7. Exponential Backoff with Jitter

Used for reconnect rate-limiting in `postgres`, `mongo`, `redis`, and `rabbitmq`. The backoff cap is 30 seconds. The jitter strategy is AWS Full Jitter: `sleep = random_between(0, min(cap, base * 2^attempt))`.

### 8. Event-Driven Tenant Discovery (v4.5.0+)

Instead of polling the Tenant Manager API for new tenants (watcher model, removed in v4.5.0), services now subscribe to Redis pub/sub events. This provides:

- **Lower latency**: New tenants are discovered in milliseconds, not at the next poll interval
- **Lower load**: No periodic HTTP calls to the Tenant Manager API
- **Consistency**: All services receive tenant events simultaneously

The pattern: `TenantEventListener` subscribes to Redis pub/sub, receives `tenant.added`, `tenant.connections.updated`, and `tenant.credentials.rotated` events, and invokes the registered callbacks.

### 9. Variadic Context Pattern (v4.6.0)

Context functions for tenant-scoped resources use variadic module parameters instead of separate per-module functions:

```go
// Without module — uses default
db := tmcore.GetPGContext(ctx)

// With module — explicit module scope
db := tmcore.GetPGContext(ctx, "audit")
```

This pattern applies to both PG and MB context functions. The variadic approach allows a single middleware to inject multiple module-scoped connections, and repositories to retrieve the correct one without coupling to module-specific function names.

---

## 13. Which Package Do I Need?

Use this decision tree to find the right package quickly:

| I need to... | Package |
|-------------|---------|
| **Database** | |
| Connect to PostgreSQL | `postgres` |
| Connect to MongoDB | `mongo` |
| Connect to Redis/Valkey | `redis` |
| Acquire a distributed lock | `redis` (RedisLockManager) |
| **Messaging** | |
| Publish messages to RabbitMQ | `rabbitmq` (ConfirmablePublisher) |
| Consume messages from RabbitMQ (multi-tenant) | `rabbitmq` + `dispatch layer/consumer` |
| **HTTP** | |
| Add HTTP middleware (CORS, logging, telemetry) | `net/http` |
| Rate-limit HTTP endpoints | `net/http/ratelimit` |
| Paginate API responses | `net/http` (offset, UUID cursor, timestamp cursor, sort cursor) |
| Validate HTTP request bodies | `net/http` (`ParseBodyAndValidate`, `ValidateStruct`) |
| Send consistent API responses | `net/http` (`Respond`, `RespondStatus`, `RespondError`, `RenderError`) |
| Add health checks | `net/http` (`HealthWithDependencies`) |
| Parse and verify tenant-scoped IDs | `net/http` (`ParseAndVerifyTenantScopedID`, `ParseAndVerifyResourceScopedID`) |
| **Resilience** | |
| Add circuit breakers | `circuitbreaker` |
| Add retry logic with backoff | `backoff` (compute delay) + your own loop |
| Launch goroutines safely | `runtime` (`SafeGo`) |
| Run concurrent tasks with error handling | `errgroup` (panic-safe, first-error cancellation) |
| Do safe math (no panics) | `safe` (DivideOrZero, First, CachedRegexp) |
| **Security** | |
| Handle JWTs | `jwt` (Parse, Sign, ValidateTimeClaims) |
| Encrypt/decrypt data | `crypto` (AES-GCM encrypt/decrypt, HMAC hash) |
| Check if a field name is sensitive | `security` (`IsSensitiveField`) |
| Fetch AWS secrets for M2M auth | `secretsmanager` (`GetM2MCredentials`) |
| Handle license validation | `license` (fail-open/fail-closed policies) |
| **Multi-Tenancy** | |
| Add multi-tenancy (database-per-tenant) | `dispatch layer` (full isolation system) |
| Discover tenants via events (HTTP services) | `dispatch layer/event` (`TenantEventListener`) |
| Discover tenants via events (consumer services) | `dispatch layer/consumer` (built-in event support) |
| Create Redis pub/sub client for tenant events | `dispatch layer/redis` (`NewTenantPubSubRedisClient`) |
| Cache tenants with load callback | `dispatch layer/tenantcache` (`TenantLoader` with `WithOnTenantLoaded`) |
| Get tenant-scoped PG/MB from context | `dispatch layer/core` (`GetPGContext(ctx, ...module)`, `GetMBContext(ctx, ...module)`) |
| **Configuration** | |
| Add hot-reloadable runtime config | `systemplane` (full config management plane) |
| **Transactions** | |
| Process financial transactions | `transaction` (intent planning, balance posting) |
| Implement transactional outbox | `outbox` + `outbox/postgres` |
| **Observability** | |
| Add structured logging | `log` (interface) + `zap` (implementation) |
| Set up OpenTelemetry | `opentelemetry` (tracer, meter, logger providers) |
| Build custom metrics | `opentelemetry/metrics` (Counter, Gauge, Histogram builders) |
| Add production-safe assertions | `assert` (with OTel observability) |
| Manage graceful shutdown | `server` (ServerManager) |
| **Root Package Utilities** | |
| Generate UUIDv7 | `commons` (`GenerateUUIDv7`) |
| Map business errors to HTTP status | `commons` (`ValidateBusinessError`) |
| Get env var with default | `commons` (`GetenvOrDefault`) |
| Set config from env vars | `commons` (`SetConfigFromEnvVars`) |
| Remove accents / convert case | `commons` (`RemoveAccents`, `ToSnakeCase`, `ToCamelCase`) |
| Validate/parse dates | `commons` (`IsValidDate`, `ParseDate`, `ParseDateTime`) |
| Manage concurrent app lifecycle | `commons` (`Launcher`) |
| Carry request-scoped context | `commons` (`ContextWith*`, `WithTimeoutSafe`) |
| **Other** | |
| Parse cron expressions | `cron` (parse expression, compute next time) |
| Create pointers from literals | `pointers` (String, Bool, Time, Int64, Float64) |
| Use shared constants | `constants` (headers, error codes, OTel attributes) |
| Build scripts, Makefiles, ASCII banners | `shell` |

---

## 14. Breaking Changes

This section documents breaking changes across lib-commons v4.x releases. Consult when upgrading.

### v4.6.0

| Change | Migration |
|--------|-----------|
| **MultiPoolMiddleware removed** | Use unified `WithPG`/`WithMB` API on `NewTenantMiddleware` with optional module parameter |
| **Context API unified (PG)** | `ContextWithTenantPG(ctx, pg)` → `ContextWithPG(ctx, pg, ...module)` (variadic) |
| **Context API unified (MB)** | `ContextWithTenantMB(ctx, mb)` → `ContextWithMB(ctx, mb, ...module)` (variadic) |
| **GetPGContext variadic** | `GetPGContext(ctx)` still works; for modules use `GetPGContext(ctx, "module")` |
| **GetMBContext variadic** | `GetMBContext(ctx)` still works; for modules use `GetMBContext(ctx, "module")` |
| **S3 key function renamed** | `GetObjectStorageKeyForTenant` → `GetS3KeyStorageContext` |
| **Settings option renamed** | `WithSettingsCheckInterval` → `WithConnectionsCheckInterval` |

### v4.5.0

| Change | Migration |
|--------|-----------|
| **Watcher removed** | Replace watcher-based tenant discovery with event-driven model using `TenantEventListener` (Redis pub/sub) |
| **New dependency**: Redis pub/sub | Services discovering tenants now need a Redis connection for pub/sub |

### v4.3.0

| Change | Migration |
|--------|-----------|
| **Zap timestamp format** | `"ts"` field (Unix epoch float) → `"timestamp"` field (ISO 8601 string). Update log parsers, Fluentd/Logstash configs, and Grafana queries |

### v4.2.0

| Change | Migration |
|--------|-----------|
| **TM client endpoint** | `/settings` → `/connections` |
| **TM client path prefix** | Added `/v1/associations/` prefix to all TM API calls |
| **Rate limiting added** | New package `net/http/ratelimit` — not a breaking change but new capability with env vars |
