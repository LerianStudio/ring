# REFERENCE MODE

Sections 1–15 below catalog lib-commons latest v5.x packages, APIs, and initialization
patterns. Observability APIs are intentionally documented as the companion `github.com/LerianStudio/lib-observability` module, not as lib-commons packages. Resolve the actual latest lib-commons version at runtime via `gh api repos/LerianStudio/lib-commons/releases/latest --jq .tag_name`. Read the sections relevant to your current task. Sweep Mode explorers receive
extracts from these sections as context for their angle.

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
| `certificate` | `commons/certificate` | **v5.0.0**: Thread-safe TLS certificate manager with hot reload (PKCS#8/PKCS#1/EC keys, DER chain support, zero-downtime `Rotate`) |

### Observability & Runtime *(moved to lib-observability v1.0.0)*

| Package | New Home | Sub-skill |
|---|---|---|
| `log` (Logger interface) | `lib-observability/log` | [[using-lib-observability]] |
| `zap` (Logger implementation) | `lib-observability/zap` | [[using-lib-observability]] |
| `tracing` / OTel TracerProvider lifecycle | `lib-observability/tracing` | [[using-tracing]] |
| `metrics` (Counter / Gauge / Histogram factory) | `lib-observability/metrics` | [[using-lib-observability]] |
| `runtime` (SafeGo, panic recovery, production mode) | `lib-observability/runtime` | [[using-runtime]] |
| `assert` (production runtime assertions) | `lib-observability/assert` | [[using-assert]] |
| `redaction` (sensitive-value scrubbing) | `lib-observability/redaction` | [[using-lib-observability]] |
| OTel attribute / event name constants | `lib-observability/constants` | [[using-lib-observability]] |

lib-commons v5 still ships deprecated shims at the old import paths so existing code keeps compiling — but new code, refactors, and reviews MUST target the lib-observability paths. The detailed APIs for these packages live in those sub-skills, not here.

### Lifecycle (Still in lib-commons)

| Package | Import Path Suffix | Purpose |
|---|---|---|
| `server` | `commons/server` | HTTP (Fiber) + gRPC graceful shutdown manager with ordered teardown |
| `cron` | `commons/cron` | 5-field cron expression parser, computes next execution time |

### HTTP & Networking

| Package | Import Path Suffix | Purpose |
|---|---|---|
| `net/http` | `commons/net/http` | Fiber HTTP toolkit: CORS, basic auth, validation, 3 cursor pagination styles, health checks, SSRF-safe reverse proxy, ownership verification, response helpers, tenant-scoped ID parsing. Use `lib-observability/middleware` for logging and telemetry middleware. |
| `net/http/ratelimit` | `commons/net/http/ratelimit` | Redis-backed distributed fixed-window rate limiting with atomic Lua script, tiered presets, dynamic tier selection, identity extractors, fail-open/fail-closed policy, `X-RateLimit-*` headers |
| `net/http/idempotency` | `commons/net/http/idempotency` | **v5.0.0**: Fiber middleware for best-effort at-most-once request semantics via Redis SetNX, tenant-scoped keys, faithful response replay (status/headers/body), fail-open on Redis outage |

### Webhooks & Dead Letter Queue (New in v5.0.0)

| Package | Import Path Suffix | Purpose |
|---|---|---|
| `webhook` | `commons/webhook` | Secure webhook delivery engine: two-layer SSRF protection (pre-resolution IP check + DNS-pinned delivery), HMAC-SHA256 signing (v0 payload-only or v1 timestamp-bound for replay protection), exponential backoff with jitter, concurrent delivery with configurable semaphore |
| `dlq` | `commons/dlq` | Redis-backed dead letter queue with tenant-isolated keys, exponential backoff retry (AWS Full Jitter, 5s floor, 30s base), background `Consumer` polling, per-source `RetryFunc` callbacks, configurable `MaxRetries` |

### Resilience & Utilities

| Package | Import Path Suffix | Purpose |
|---|---|---|
| `circuitbreaker` | `commons/circuitbreaker` | Per-service circuit breakers (sony/gobreaker) with health checker, state metrics |
| `backoff` | `commons/backoff` | Exponential backoff with jitter, context-aware sleep |
| `errgroup` | `commons/errgroup` | Error group with first-error cancellation and panic-to-error recovery |
| `safe` | `commons/safe` | Panic-free division, bounds-checked slice access, cached regex compilation |
| `pointers` | `commons/pointers` | Pointer-to-literal helpers (`String`, `Bool`, `Time`, `Int64`, `Float64`) |
| `assert` *(moved)* | `lib-observability/assert` | Production runtime assertions — **moved to lib-observability**; see [[using-assert]] |
| `constants` *(partially moved)* | `commons/constants` (non-observability) + `lib-observability/constants` (OTel attribute/event names) | HTTP headers, error codes, pagination defaults stay in lib-commons; OTel attribute/event-name constants moved to lib-observability — see [[using-lib-observability]] |

### Multi-Tenancy (Major Subsystem)

| Package | Import Path Suffix | Purpose |
|---|---|---|
| `tenant-manager` | `commons/tenant-manager` | Complete database-per-tenant isolation system with sub-packages for each resource type |
| `tenant-manager/core` | `...core` | Shared types: TenantConfig, **variadic** context helpers (`ContextWithPG(ctx, pg, ...module)`, `GetPGContext(ctx, ...module)`) |
| `tenant-manager/client` | `...client` | HTTP client for Tenant Manager API with cache + circuit breaker. **v4.2.0+**: endpoint `/connections`, path prefix `/v1/associations/` |
| `tenant-manager/postgres` | `...postgres` | Per-tenant PostgreSQL connection pool manager with LRU eviction |
| `tenant-manager/mongo` | `...mongo` | Per-tenant MongoDB client manager |
| `tenant-manager/rabbitmq` | `...rabbitmq` | Per-tenant RabbitMQ connection manager (vhost isolation) |
| `tenant-manager/s3` | `...s3` | Tenant-aware S3 key namespacing (`{tenantID}/{key}`). **v4.6.0**: `GetS3KeyStorageContext` (renamed from `GetObjectStorageKeyForTenant`) |
| `tenant-manager/valkey` | `...valkey` | Tenant-aware Redis key namespacing (`tenant:{tenantID}:{key}`) |
| `tenant-manager/middleware` | `...middleware` | Fiber middleware: JWT-to-tenantId extraction, DB resolution, context injection. **v4.6.0**: unified `WithPG`/`WithMB` API (MultiPoolMiddleware removed) |
| `tenant-manager/consumer` | `...consumer` | Multi-tenant RabbitMQ consumer with dynamic tenant discovery, `EnsureConsumerStarted` / `StopConsumer` lifecycle |
| `tenant-manager/event` | `...event` | **v4.5.0**: Event-driven tenant discovery via Redis pub/sub. Events: `tenant.added`, `tenant.connections.updated`, `tenant.credentials.rotated`. `TenantEventListener` for HTTP-only services |
| `tenant-manager/redis` | `...redis` | **v4.6.0**: `NewTenantPubSubRedisClient` helper for Redis pub/sub with TLS support |
| `tenant-manager/tenantcache` | `...tenantcache` | **v4.6.0**: `TenantLoader` with `WithOnTenantLoaded` callback for event-driven tenant addition |
| `tenant-manager/cache` | `...cache` | **v5.0.0**: `ConfigCache` interface for tenant config caching; `InMemoryCache` default implementation. Passed into the TM client via `client.WithCache()` |
| `tenant-manager/log` | `...log` | **v5.0.0**: `TenantAwareLogger` wraps a `log.Logger` and automatically injects `tenant_id` from context into every log entry |

### Build & Shell Utilities

| Package | Import Path Suffix | Purpose |
|---|---|---|
| `shell` | `commons/shell` | Build/shell utilities — Makefiles, shell scripts, ASCII art banners for Lerian services |

---

## 2. Common Initialization Pattern

Most Lerian services follow this bootstrap sequence. The order matters — each layer depends on the previous one. **Observability bootstrap (steps 1–4) now lives in lib-observability** — the imports below come from `github.com/LerianStudio/lib-observability/...`. See [[using-lib-observability]] for the canonical reference.

```go
// 1. Logger — first because everything else logs (from lib-observability/zap)
logger, _ := zap.New(zap.Config{
    Environment:     zap.EnvironmentProduction,
    OTelLibraryName: "my-service",
})
defer logger.Sync(ctx)

// 2. Telemetry — second because DB/HTTP packages emit traces and metrics
//    (from lib-observability/tracing — see [[using-tracing]])
//    When CollectorExporterEndpoint is empty, noop global providers are registered
//    so trace/metric calls are no-ops instead of errors.
tl, _ := tracing.NewTelemetry(tracing.TelemetryConfig{
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

// 3. Runtime — panic metrics and production mode (from lib-observability/runtime — see [[using-runtime]])
runtime.InitPanicMetrics(tl.MetricsFactory, logger)
runtime.SetProductionMode(true)

// 4. Assert metrics — production assertions with OTel (from lib-observability/assert — see [[using-assert]])
assert.InitAssertionMetrics(tl.MetricsFactory)

// 5. PostgreSQL (lib-commons — stays here)
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
app.Use(middleware.WithHTTPLogging(middleware.WithCustomLogger(logger)))
tm := middleware.NewTelemetryMiddleware(tl)
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
- `tl.ApplyGlobals()` sets the global TracerProvider/MeterProvider for libraries that use `otel.Tracer()`.
- When `CollectorExporterEndpoint` is empty, noop providers are registered globally so code that calls `otel.Tracer()` or `otel.Meter()` does not error — it simply no-ops.

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
| Logging | `middleware.WithHTTPLogging(middleware.WithCustomLogger(logger))` | Request/response logging |
| Telemetry | `middleware.NewTelemetryMiddleware(tl).WithTelemetry(tl, skipPaths...)` | OTel span creation, metrics |
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

### Idempotency (`net/http/idempotency`) — v5.0.0

**Added in v5.0.0.** Fiber middleware for best-effort at-most-once request semantics using Redis SetNX. Fails open on Redis outages to preserve availability; callers needing strict guarantees must pair with application-level safeguards.

#### Quick Setup

```go
import "github.com/LerianStudio/lib-commons/v5/commons/net/http/idempotency"

idem := idempotency.New(redisConn,
    idempotency.WithKeyPrefix("idempotency:"),   // default: "idempotency:"
    idempotency.WithKeyTTL(7*24*time.Hour),       // default: 7 days
    idempotency.WithMaxKeyLength(256),            // default: 256
    idempotency.WithMaxBodyCache(1<<20),          // default: 1 MB
    idempotency.WithRedisTimeout(500*time.Millisecond),
    idempotency.WithLogger(logger),
)

// Apply to specific mutating routes — GET/HEAD/OPTIONS pass through unconditionally
app.Post("/orders", idem.Check(), createOrderHandler)
app.Patch("/orders/:id", idem.Check(), updateOrderHandler)
```

#### Request Header

Clients opt in per request by sending `X-Idempotency: <unique-key>`. Keys are client-generated (UUIDs are typical). The header constant is `constants.IdempotencyKey`.

#### Key Composition

Composite Redis key format: `<prefix><tenantID>:<idempotencyKey>`

- Tenant ID is extracted from tenant-manager context (`tmcore.GetTenantIDContext`)
- When no tenant is in context, the **middleware bypasses idempotency** (mutating requests proceed normally) — this prevents collapsing all tenantless requests onto a shared key space, which would break isolation
- A companion `:response` key caches the replay payload

#### Behavior Branches (in order)

| Condition | Behavior |
|---|---|
| Method is GET/HEAD/OPTIONS | Pass through (idempotency not applied to safe methods) |
| No `X-Idempotency` header | Pass through (idempotency is opt-in per request) |
| No tenant in context | Pass through (preserves tenant isolation) |
| Key > `maxKeyLength` | Rejected handler invoked; default 400 with code `VALIDATION_ERROR` |
| Redis unavailable | Fail-open — request proceeds, WARN logged |
| Duplicate key, response cached | Faithful replay: status, headers (Location, ETag, Set-Cookie), content-type, body — with `X-Idempotency-Replayed: true` |
| Duplicate key, still processing | 409 Conflict with code `IDEMPOTENCY_CONFLICT` |
| Duplicate key, complete but body oversized | 200 OK with code `IDEMPOTENT` |
| Handler success | Response cached via Redis pipeline; key marked `complete` |
| Handler failure | Lock + response keys deleted so client can retry with same key |

#### Response Replay Headers Preserved

Cached responses preserve `Location`, `ETag`, `Set-Cookie`, and other headers so a replayed response is indistinguishable from the original to the client. `X-Idempotency-Replayed: true` is added to signal a replay.

#### Nil Safety

`idempotency.New(nil)` returns `nil`. A nil `*Middleware` returns a pass-through handler from `Check()`, so bootstrap code that conditionally configures Redis won't crash.

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

## 5. Observability *(moved to lib-observability)*

**Moved to lib-observability** — the entire observability surface (Logger, Tracing, Metrics, Panic Recovery, Assertions, Redaction, OTel attribute constants) is now documented in dedicated skills:

| Concern | Package | Skill |
|---|---|---|
| Logger interface + zap implementation | `lib-observability/log`, `lib-observability/zap` | [[using-lib-observability]] |
| OTel TracerProvider lifecycle | `lib-observability/tracing` | [[using-tracing]] |
| Metrics factory (Counter / Gauge / Histogram) | `lib-observability/metrics` | [[using-lib-observability]] |
| Panic recovery (`SafeGo`, `RecoverWithPolicy`, panic-metric trident) | `lib-observability/runtime` | [[using-runtime]] |
| Production runtime assertions (`assert.New`, domain predicates, observability trident) | `lib-observability/assert` | [[using-assert]] |
| Sensitive-value redaction | `lib-observability/redaction` | [[using-lib-observability]] |
| OTel attribute / event name constants | `lib-observability/constants` | [[using-lib-observability]] |

lib-commons v5 still ships deprecated shims at `commons/log`, `commons/zap`, `commons/opentelemetry`, `commons/runtime`, `commons/assert` so existing services compile. New code, refactors, and reviews MUST target `github.com/LerianStudio/lib-observability/...`. The Sweep Mode angles for panic handling (Angle 15), observability setup (Angle 14), and assertions (Angle 16) now flag both raw DIY **and** continued use of the deprecated lib-commons shim paths.

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

### Constants (`commons/constants` + `lib-observability/constants`)

Shared constants used across Lerian services. Split across two libraries as of lib-observability v1.0.0:

**Still in `commons/constants`** (lib-commons):
- HTTP headers (e.g., `X-Request-ID`, `X-Tenant-ID`)
- Error codes
- Pagination defaults

**Moved to `lib-observability/constants`** — see [[using-lib-observability]]:
- OTel attribute keys (span/metric/log attribute names)
- OTel event names

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

### TLS Certificate Hot-Reload (`commons/certificate`) — v5.0.0

**Added in v5.0.0.** Thread-safe X.509 certificate manager with zero-downtime rotation — load PEM files, serve them via TLS config, and swap them atomically without restarting the process.

#### Constructor

```go
m, err := certificate.NewManager("server.crt", "server.key")
if err != nil {
    return err
}

// Both paths empty → returns an unconfigured manager (useful when TLS is optional)
m, _ := certificate.NewManager("", "")
```

If exactly one of `certPath` / `keyPath` is provided, `NewManager` returns `ErrIncompleteConfig`.

#### Key Formats

Private keys are parsed in order: **PKCS#8 → PKCS#1 (RSA) → EC (SEC 1)**. Supported key types: RSA, ECDSA, Ed25519. At load time, the manager validates that the certificate's public key matches the private key (`ErrKeyMismatch` otherwise).

#### Hot Rotation

```go
// Pre-flight: load the new pair before touching the manager
cert, signer, chain, err := certificate.LoadFromFilesWithChain("new.crt", "new.key")
if err != nil {
    logger.Errorf("pre-flight validation failed: %v", err)
    return
}

// Rotate includes a full chain (leaf + intermediates)
if err := m.Rotate(cert, signer, chain[1:]...); err != nil {
    logger.Errorf("certificate rotation failed: %v", err)
}
```

`Rotate` rejects expired certificates (`ErrExpired`), not-yet-valid certificates, nil cert/key, and key-mismatches. It deep-copies the certificate DER to prevent aliasing caller-owned memory.

#### TLS Integration

```go
tlsConfig := &tls.Config{
    GetCertificate: m.GetCertificateFunc(), // live closure — respects subsequent Rotates
}
```

`GetCertificateFunc` on a nil `*Manager` returns a closure that always returns `ErrNilManager`, so bootstrap code that conditionally configures TLS won't crash.

#### Accessors (all Nil-Receiver Safe)

| Method | Returns |
|---|---|
| `GetCertificate()` | `*x509.Certificate` (leaf) |
| `GetSigner()` | `crypto.Signer` (private key) |
| `PublicKey()` | leaf's public key |
| `TLSCertificate()` | `tls.Certificate` (leaf + chain + signer) |
| `ExpiresAt()` | `time.Time` (leaf's `NotAfter`) |
| `DaysUntilExpiry()` | `int` (days from `time.Now()`) |

Read accessors on a nil `*Manager` return zero values without panicking.

#### Sentinel Errors

`ErrNilManager`, `ErrCertRequired`, `ErrKeyRequired`, `ErrExpired`, `ErrNoPEMBlock`, `ErrKeyParseFailure`, `ErrNotSigner`, `ErrKeyMismatch`, `ErrIncompleteConfig`.

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

The tenant-manager subsystem provides complete database-per-tenant isolation. This is a major subsystem with its own middleware, connection pool managers, consumer infrastructure, and **event-driven tenant discovery** (v4.5.0+).

### Architecture Flow

```
HTTP request
  → JWT middleware (extract tenantId from token)
    → tenant-manager client (fetch tenant config from TM API)
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
tmClient, _ := client.NewClient("https://tenant-manager:8080", logger,
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
import tmevent "github.com/LerianStudio/lib-commons/v5/commons/tenant-manager/event"

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
import tmredis "github.com/LerianStudio/lib-commons/v5/commons/tenant-manager/redis"

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
import "github.com/LerianStudio/lib-commons/v5/commons/tenant-manager/tenantcache"

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

### Cache Abstraction (v5.0.0 — `tenant-manager/cache`)

v5.0.0 extracted the tenant-config cache into its own interface so services can plug in Redis or a custom implementation instead of the default in-memory cache:

```go
import "github.com/LerianStudio/lib-commons/v5/commons/tenant-manager/cache"

// Default: process-local in-memory cache with TTL
inMem := cache.NewInMemoryCache()

tmClient, _ := client.NewClient("https://tenant-manager:8080", logger,
    client.WithCache(inMem),
    client.WithCacheTTL(5*time.Minute),
)
```

The `ConfigCache` interface (`Get(ctx, key)` / `Set(ctx, key, val, ttl)` / `Del(ctx, key)`) returns `cache.ErrCacheMiss` on miss or expiry. Implementations must be safe for concurrent use.

### Tenant-Aware Logger (v5.0.0 — `tenant-manager/log`)

Wraps any `log.Logger` to auto-inject `tenant_id` from context into every log entry:

```go
import tmlog "github.com/LerianStudio/lib-commons/v5/commons/tenant-manager/log"

baseLogger, _ := zap.New(zap.Config{...})
logger := tmlog.NewTenantAwareLogger(baseLogger)

// Every log call now carries tenant_id when the context has one
logger.Log(ctx, log.LevelInfo, "transaction processed", log.String("txn_id", id))
// → fields include tenant_id=<tenant-from-ctx> automatically
```

This removes the need for every call site to pass `tenant_id` manually, and guarantees the field is present in multi-tenant log aggregators even when handlers forget to add it.

---

## 10. Webhook Delivery

**Added in v5.0.0.** `commons/webhook` is a secure webhook delivery engine with SSRF protection, HMAC-SHA256 signing, and exponential-backoff retries. Construct one `Deliverer` per service and reuse it — the internal HTTP client maintains a connection pool.

### Core Types

| Type | Purpose |
|---|---|
| `Endpoint` | `{ID, URL, Secret, Active}` — the receiver. `Secret` can be plaintext or `"enc:<ciphertext>"` (decrypted via `WithSecretDecryptor`). |
| `Event` | `{Type, Payload, Timestamp}` — the message to deliver. `Payload` is the JSON-encoded body; `Timestamp` is Unix-epoch seconds. |
| `EndpointLister` | Interface: `ListActiveEndpoints(ctx) ([]Endpoint, error)` — typically backed by a DB query filtered by tenant ID. |
| `DeliveryResult` | `{EndpointID, StatusCode, Success, Error, Attempts}` |
| `DeliveryMetrics` | Interface: `RecordDelivery(ctx, endpointID, success, statusCode, attempts)` |
| `SecretDecryptor` | `func(encrypted string) (string, error)` for decrypting `"enc:"`-prefixed secrets. |

### Constructor

```go
import "github.com/LerianStudio/lib-commons/v5/commons/webhook"

d := webhook.NewDeliverer(lister,
    webhook.WithLogger(logger),
    webhook.WithTracer(tracer),
    webhook.WithMetrics(metrics),
    webhook.WithMaxConcurrency(20),             // default: 20
    webhook.WithMaxRetries(3),                  // default: 3
    webhook.WithHTTPClient(customClient),       // redirects always blocked for SSRF safety
    webhook.WithSecretDecryptor(decryptor),     // optional — fail-closed if "enc:" secrets appear without one
    webhook.WithSignatureVersion(webhook.SignatureV1), // default: SignatureV0
)
```

`NewDeliverer(nil, ...)` returns `nil` — Deliverer methods are nil-safe.

### SSRF Protection (Two Layers)

Webhook URLs are user-controlled, so the package defends against SSRF aggressively:

1. **Pre-resolution IP validation** — hostname resolved, resolved IPs checked against RFC 1918 private ranges, loopback, link-local, and multicast before the connection is opened
2. **DNS-pinned delivery** — the resolved IP is pinned for the actual connection, preventing DNS rebinding between validation and connect
3. **Redirects always blocked** — even a user-supplied `*http.Client` is cloned with `CheckRedirect = http.ErrUseLastResponse` so an attacker cannot bounce the request via a 302 to a private IP

### HMAC Signatures — Two Versions

| Version | Format | Replay Protection |
|---|---|---|
| `SignatureV0` (default, backward-compatible) | `sha256=<hex(HMAC(payload, secret))>` | **None** — receivers must implement their own (event-ID tracking, etc.) |
| `SignatureV1` (recommended for new deployments) | `v1,sha256=<hex(HMAC("v1:<timestamp>.<payload>", secret))>` | **Yes** — timestamp is bound into the HMAC input |

The default is V0 to avoid breaking existing consumers. Migration path:

1. Update all receivers to use `VerifySignature` (auto-detects both formats)
2. Switch senders to `SignatureV1` via `WithSignatureVersion`
3. Optionally enforce V1-only after the transition window

### Receiver-Side Verification

```go
// Auto-detects v0 or v1 from the signature string
if err := webhook.VerifySignature(payload, timestamp, secret, receivedSig); err != nil {
    return http.StatusUnauthorized
}

// For v1 signatures: verify + enforce freshness in one call
if err := webhook.VerifySignatureWithFreshness(payload, timestamp, secret, receivedSig, 5*time.Minute); err != nil {
    // rejects on signature mismatch OR stale timestamp
    return http.StatusUnauthorized
}
```

### Delivery Headers (Sent by Deliverer)

| Header | Purpose |
|---|---|
| `X-Webhook-Signature` | HMAC signature (v0 or v1 format) |
| `X-Webhook-Timestamp` | Decimal Unix epoch seconds (informational in v0, HMAC-covered in v1) |
| `Content-Type` | `application/json` |

### Retry Behavior

- Exponential backoff with jitter (1s base, 2x doubling)
- Up to `maxRetries` attempts per endpoint (default 3)
- Concurrent delivery across endpoints, bounded by `maxConcurrency` semaphore (default 20)
- Response body drain capped at 64 KiB so the TCP connection can be reused

### Credential Hygiene

URL query parameters and userinfo (`user:pass@host`) are stripped from log output before emission to prevent credential leakage into log aggregators.

---

## 11. Dead Letter Queue

**Added in v5.0.0.** `commons/dlq` is a Redis-backed DLQ for messages that failed processing. Tenant-isolated keys, exponential-backoff retry, and a background `Consumer` that polls for retryable messages.

### Core Types

| Type | Purpose |
|---|---|
| `FailedMessage` | `{Source, OriginalData, ErrorMessage, RetryCount, MaxRetries, CreatedAt, NextRetryAt, TenantID}` |
| `Handler` | Enqueue/dequeue interface on top of Redis lists |
| `Consumer` | Background poller that invokes a `RetryFunc` per message |
| `RetryFunc` | `func(ctx, *FailedMessage) error` — return nil to discard, error to re-enqueue |
| `DLQMetrics` | Interface: `RecordRetried` / `RecordExhausted` / `RecordLost` |

### Handler

```go
import "github.com/LerianStudio/lib-commons/v5/commons/dlq"

h := dlq.New(redisConn, "dlq:", 3,              // keyPrefix, maxRetries
    dlq.WithLogger(logger),
    dlq.WithTracer(tracer),
    dlq.WithMetrics(metrics),
    dlq.WithModule("transaction-outbound"),
)

// Enqueue a failed message — TenantID is resolved from context if not already set.
// On initial enqueue, msg.MaxRetries=0 is overwritten with the handler's configured value.
err := h.Enqueue(ctx, &dlq.FailedMessage{
    Source:       "outbound",
    OriginalData: payload,
    ErrorMessage: originalErr.Error(),
})
```

`dlq.New(nil, ...)` returns `nil` — `Handler` methods are nil-safe and return `ErrNilHandler`.

### Key Composition

Keys are tenant-scoped to prevent cross-tenant mixing:

| Context | Redis Key |
|---|---|
| Tenant present | `dlq:<tenantID>:<source>` |
| No tenant | `dlq:<source>` (global) |

Invalid tenant IDs (containing `:`, `*`, `?`, `[`, `]`, `\`) are **rejected fail-closed** — the Enqueue returns an error rather than falling back to the global key, which would corrupt isolation.

### Consumer

```go
consumer, err := dlq.NewConsumer(handler, retryFn,
    dlq.WithConsumerLogger(logger),
    dlq.WithConsumerTracer(tracer),
    dlq.WithConsumerMetrics(metrics),
    dlq.WithConsumerModule("transaction-outbound"),
    dlq.WithPollInterval(30*time.Second),  // default: 30s
    dlq.WithBatchSize(10),                  // default: 10
    dlq.WithSources("outbound", "inbound"),
)

// Start blocks until ctx is canceled — run under a Launcher or SafeGo
runtime.SafeGoWithContextAndComponent(ctx, logger, "my-service", "dlq-consumer",
    runtime.KeepRunning, func(ctx context.Context) {
        _ = consumer.Start(ctx)
    },
)
```

### Retry Function Contract

```go
retryFn := func(ctx context.Context, msg *dlq.FailedMessage) error {
    // ctx automatically carries the TenantID from msg.TenantID via tmcore.
    switch msg.Source {
    case "outbound":
        return resendWebhook(ctx, msg.OriginalData)
    case "inbound":
        return reprocessEvent(ctx, msg.OriginalData)
    }
    return errors.New("unknown source")
}
```

- Return `nil` → message is discarded (`RecordRetried`)
- Return `error` → message is re-enqueued with incremented `RetryCount` and updated `NextRetryAt`
- `RetryCount >= MaxRetries` → message is discarded as permanently failed (`RecordExhausted`)

### Backoff

30s base with AWS Full Jitter (via `commons/backoff`), floored at 5s so attempt 0 gets genuine jitter spread over `[5s, 30s)` rather than always resolving to exactly 30s.

### Integration with RabbitMQ Consumers

The typical pattern: a RabbitMQ consumer that fails to process a message Enqueues to the DLQ, Acks the original, and the DLQ Consumer retries it later out-of-band. This moves slow retries off the main consumer loop and off the broker, which is particularly useful for multi-tenant deployments where per-tenant retries on the broker can cause head-of-line blocking.

---

## 12. Root Package & Utilities

The root `commons` package (`github.com/LerianStudio/lib-commons/v5/commons`) provides foundational utilities used across all Lerian services. These are building blocks that other packages and services depend on.

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
normalized := commons.RemoveAccents("café")  // returns "cafe"

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

## 13. Cross-Cutting Patterns

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

## 14. Which Package Do I Need?

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
| Consume messages from RabbitMQ (multi-tenant) | `rabbitmq` + `tenant-manager/consumer` |
| **HTTP** | |
| Add HTTP middleware (CORS/basic auth/validation) | `net/http` |
| Add HTTP logging/telemetry middleware | `lib-observability/middleware` |
| Rate-limit HTTP endpoints | `net/http/ratelimit` |
| Enforce idempotency on mutating endpoints | `net/http/idempotency` (v5.0.0) |
| Paginate API responses | `net/http` (offset, UUID cursor, timestamp cursor, sort cursor) |
| Validate HTTP request bodies | `net/http` (`ParseBodyAndValidate`, `ValidateStruct`) |
| Send consistent API responses | `net/http` (`Respond`, `RespondStatus`, `RespondError`, `RenderError`) |
| Add health checks | `net/http` (`HealthWithDependencies`) |
| Parse and verify tenant-scoped IDs | `net/http` (`ParseAndVerifyTenantScopedID`, `ParseAndVerifyResourceScopedID`) |
| **Resilience** | |
| Add circuit breakers | `circuitbreaker` |
| Add retry logic with backoff | `backoff` (compute delay) + your own loop |
| Launch goroutines safely | `lib-observability/runtime` (`SafeGo`) — see [[using-runtime]] |
| Run concurrent tasks with error handling | `errgroup` (panic-safe, first-error cancellation) |
| Do safe math (no panics) | `safe` (DivideOrZero, First, CachedRegexp) |
| **Security** | |
| Handle JWTs | `jwt` (Parse, Sign, ValidateTimeClaims) |
| Encrypt/decrypt data | `crypto` (AES-GCM encrypt/decrypt, HMAC hash) |
| Check if a field name is sensitive | `security` (`IsSensitiveField`) |
| Fetch AWS secrets for M2M auth | `secretsmanager` (`GetM2MCredentials`) |
| Handle license validation | `license` (fail-open/fail-closed policies) |
| Manage TLS certs with hot reload | `certificate` (v5.0.0 — `NewManager`, `Rotate`, `GetCertificateFunc`) |
| **Multi-Tenancy** | |
| Add multi-tenancy (database-per-tenant) | `tenant-manager` (full isolation system) |
| Discover tenants via events (HTTP services) | `tenant-manager/event` (`TenantEventListener`) |
| Discover tenants via events (consumer services) | `tenant-manager/consumer` (built-in event support) |
| Create Redis pub/sub client for tenant events | `tenant-manager/redis` (`NewTenantPubSubRedisClient`) |
| Cache tenants with load callback | `tenant-manager/tenantcache` (`TenantLoader` with `WithOnTenantLoaded`) |
| Get tenant-scoped PG/MB from context | `tenant-manager/core` (`GetPGContext(ctx, ...module)`, `GetMBContext(ctx, ...module)`) |
| Plug a custom cache into the TM client | `tenant-manager/cache` (v5.0.0 — `ConfigCache` interface, `InMemoryCache`) |
| Auto-inject `tenant_id` into every log line | `tenant-manager/log` (v5.0.0 — `TenantAwareLogger`) |
| **Webhooks & DLQ** | |
| Deliver webhooks with SSRF protection + HMAC signing | `webhook` (v5.0.0) |
| Verify incoming webhook signatures | `webhook` (v5.0.0 — `VerifySignature`, `VerifySignatureWithFreshness`) |
| Route failed messages to a retry queue | `dlq` (v5.0.0 — `Handler.Enqueue` + `Consumer`) |
| **Transactions** | |
| Process financial transactions | `transaction` (intent planning, balance posting) |
| Implement transactional outbox | `outbox` + `outbox/postgres` |
| **Observability** *(moved to lib-observability — see [[using-lib-observability]])* | |
| Add structured logging | `lib-observability/log` (interface) + `lib-observability/zap` (implementation) |
| Set up OpenTelemetry | `lib-observability/tracing` (tracer, meter, logger providers) — see [[using-tracing]] |
| Build custom metrics | `lib-observability/metrics` (Counter, Gauge, Histogram builders) |
| Add production-safe assertions | `lib-observability/assert` — see [[using-assert]] |
| Manage graceful shutdown | `commons/server` (ServerManager) — stays in lib-commons |
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

## 15. Breaking Changes

This section documents breaking changes across lib-commons releases. Consult when upgrading.

### lib-observability v1.0.0 extraction *(post-v5)*

The observability surface was extracted from lib-commons into a new module: `github.com/LerianStudio/lib-observability`. Affected packages: `log`, `zap`, `opentelemetry` (renamed to `tracing`), `opentelemetry/metrics` (now `metrics`), `runtime`, `assert`, `redaction`, and the OTel attribute/event-name subset of `constants`.

| Change | Migration |
|---|---|
| Observability imports | Replace `github.com/LerianStudio/lib-commons/v5/commons/{log,zap,opentelemetry,opentelemetry/metrics,runtime,assert}` with `github.com/LerianStudio/lib-observability/{log,zap,tracing,metrics,runtime,assert}`. Deprecated shims remain in lib-commons v5 for back-compat — `go vet` / staticcheck will surface the deprecations. |
| OTel attribute constants | Move OTel attribute/event-name imports from `commons/constants` to `lib-observability/constants`. HTTP headers, error codes, pagination defaults stay in `commons/constants`. |
| `opentelemetry.NewTelemetry` | Now `tracing.NewTelemetry` — same config struct, new package. See [[using-tracing]]. |
| Reference | Use [[using-lib-observability]] (top-level) and the sub-skills [[using-tracing]] / [[using-runtime]] / [[using-assert]] as the canonical references for these packages — not this skill. |

### v5.0.2

Patch release — no API changes. Hotfixes:

- `commons/rabbitmq`: Close leaked connections on concurrent reconnect in `EnsureChannelContext`
- `lib-observability/middleware` telemetry: Copy Fiber context strings before `c.Next()` to prevent `UnsafeString` race (caused corrupted span attributes like `GET` → `GETT`)

### v5.0.1

Patch release — no API changes. Internal test improvements and minor fixes.

### v5.0.0

**Major release.** Module path bump + several new packages.

#### Module Path

| Change | Migration |
|---|---|
| **Go module major version bump** | Replace all `github.com/LerianStudio/lib-commons/v4/...` imports with `github.com/LerianStudio/lib-commons/v5/...`. Update `go.mod` to require the latest v5.x tag (resolve via `gh api repos/LerianStudio/lib-commons/releases/latest --jq .tag_name`). Run `go mod tidy`. |
| **Minimum Go version** | Now `go 1.25` — update your service's `go.mod` if it was on an older Go toolchain. |

#### New Packages

| Package | Purpose |
|---|---|
| `commons/certificate` | TLS certificate manager with hot reload |
| `commons/dlq` | Redis-backed dead letter queue with exponential-backoff retry |
| `commons/webhook` | SSRF-safe HMAC-signed webhook delivery engine (includes SSRF validation — does **not** live in a separate `ssrf` package) |
| `commons/net/http/idempotency` | Fiber idempotency middleware with Redis SetNX, tenant-scoped keys, faithful response replay |
| `commons/tenant-manager/cache` | `ConfigCache` interface + `InMemoryCache` default implementation for the TM client |
| `commons/tenant-manager/log` | `TenantAwareLogger` — wraps a `log.Logger` and auto-injects `tenant_id` from context |

No non-observability packages were renamed. No public APIs changed signatures for the v5 lib-commons core (postgres, mongo, redis, rabbitmq, tenant-manager middleware/consumer/event/core, etc.) after the module-path bump. Observability packages should be imported from `github.com/LerianStudio/lib-observability`.

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
