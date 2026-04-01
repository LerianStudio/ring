# Go Standards - Multi-Tenant

> **Module:** multi-tenant.md | **Sections:** §27 | **Parent:** [index.md](index.md)

This module covers multi-tenant patterns with Tenant Manager.

---

## Table of Contents

| # | Section | Description |
|---|---------|-------------|
| 1 | [Multi-Tenant Patterns (CONDITIONAL)](#multi-tenant-patterns-conditional) | Configuration, Tenant Manager API, middleware, context injection, repository adaptation |
| 1a | [Generic TenantMiddleware (Standard Pattern)](#generic-tenantmiddleware-standard-pattern) | Single-module services (CRM, plugins, reporter) |
| 1b | [Multi-module middleware (TenantMiddleware with multi-module)](#multi-module-middleware-tenantmiddleware-with-multi-module) | Multi-module unified services (midaz ledger) |
| 2 | [Tenant Isolation Verification (⚠️ CONDITIONAL)](#tenant-isolation-verification-conditional) | Database-per-tenant verification, context-based connection checks |
| 3 | [Route-Level Auth-Before-Tenant Ordering (MANDATORY)](#route-level-auth-before-tenant-ordering-mandatory) | Auth MUST validate JWT before tenant middleware calls Tenant Manager API |
| 24 | [Multi-Tenant Message Queue Consumers](#multi-tenant-message-queue-consumers) | Multi-tenant consumer initialization, on-demand connection, exponential backoff, cache invalidation, consumer lifecycle (StopConsumer) |
| 25 | [M2M Credentials via Secret Manager](#m2m-credentials-via-secret-manager) | AWS Secrets Manager integration for service-to-service authentication per tenant |
| 26 | [Service Authentication (MANDATORY)](#service-authentication-mandatory) | API key authentication for dispatch layer /settings endpoint via X-API-Key header |

---

## Multi-Tenant Patterns (CONDITIONAL)

**CONDITIONAL:** Only implement if `MULTI_TENANT_ENABLED=true` is required for your service.

### HARD GATE: Canonical Model Compliance

**Existence ≠ Compliance.** A service that has "some multi-tenant code" is NOT considered multi-tenant unless every component matches the canonical patterns defined in this document exactly.

MUST replace multi-tenant implementations that use custom middleware, manual DB switching, non-standard env var names, or any mechanism other than the lib-commons v4 dispatch layer sub-packages — they are **non-compliant**. Not patched, not adapted, **replaced**.

The only valid multi-tenant implementation uses:
- `tenantId` from JWT via `TenantMiddleware` with `WithPG`/`WithMB` options (from `lib-commons/v4/commons/dispatch layer/middleware`), registered per-route using a local `WhenEnabled` helper
- `tmcore.GetPGContext(ctx)` / `tmcore.GetPGContext(ctx, module)` / `tmcore.GetMBContext(ctx)` / `tmcore.GetMBContext(ctx, module)` for database resolution (from `lib-commons/v4/commons/dispatch layer/core`)
- `valkey.GetKeyContext` for Redis key prefixing (from `lib-commons/v4/commons/dispatch layer/valkey`)
- `s3.GetS3KeyStorageContext` for S3 key prefixing (from `lib-commons/v4/commons/dispatch layer/s3`)
- `tmrabbitmq.Manager` for RabbitMQ vhost isolation (from `lib-commons/v4/commons/dispatch layer/rabbitmq`)
- The 13 canonical `MULTI_TENANT_*` environment variables with correct names and defaults
- `client.WithCircuitBreaker` on the Tenant Manager HTTP client
- `client.WithServiceAPIKey` on the Tenant Manager HTTP client for `/settings` endpoint authentication
- pgManager handles settings revalidation internally via `WithConnectionsCheckInterval` — PostgreSQL only, MongoDB excluded

MUST correct any deviation from these patterns before the service can be considered multi-tenant.

**Any file outside this canonical set that claims to handle multi-tenant logic (custom tenant resolvers, manual pool managers, wrapper middleware, etc.) is non-compliant and MUST NOT be considered part of the multi-tenant implementation.** Only files following the patterns below are valid.

### Canonical File Map

These are the only files that require multi-tenant changes. The exact paths follow the standard Go project layout used across Lerian services. Files not listed here MUST NOT contain multi-tenant logic.

**Always modified (every service):**

| File | Gate | What Changes |
|------|------|-------------|
| `go.mod` | 2 | lib-commons v4, lib-auth v2 |
| `internal/bootstrap/config.go` | 3 | 13 canonical `MULTI_TENANT_*` env vars in Config struct |
| `internal/bootstrap/service.go` (or equivalent init file) | 4 | Conditional initialization: Tenant Manager client, connection managers, middleware creation. Branch on `cfg.MultiTenantEnabled` |
| `internal/bootstrap/routes.go` (or equivalent router file) | 4 | Per-route composition via `WhenEnabled(ttHandler)` — auth validates JWT before tenant resolves DB. Each project implements the `WhenEnabled` helper locally. See [Route-Level Auth-Before-Tenant Ordering](#route-level-auth-before-tenant-ordering-mandatory) |

**Per detected database/storage (Gate 5):**

| File Pattern | Stack | What Changes |
|-------------|-------|-------------|
| `internal/adapters/postgres/**/*.postgresql.go` | PostgreSQL | `r.connection.GetDB()` → `tmcore.GetPGContext(ctx, module)` / `tmcore.GetPGContext(ctx)` with fallback to `r.connection` |
| `internal/adapters/mongodb/**/*.mongodb.go` | MongoDB | Static mongo connection → `tmcore.GetMBContext(ctx, module)` / `tmcore.GetMBContext(ctx)` with fallback to `r.connection` |
| `internal/adapters/redis/**/*.redis.go` | Redis | Every key operation → `valkey.GetKeyContext(ctx, key)` (including Lua script `KEYS[]` and `ARGV[]`) |
| `internal/adapters/storage/**/*.go` (or S3 adapter) | S3 | Every object key → `s3.GetS3KeyStorageContext(ctx, key)` |

**Conditional — services with targetServices (Gate 5.5):**

| File | Condition | What Changes |
|------|-----------|-------------|
| `internal/adapters/product/client.go` (or equivalent target service API client) | Service with targetServices declared | M2M authenticator with per-tenant credential caching via `secretsmanager.GetM2MCredentials` |
| `internal/bootstrap/service.go` | Service with targetServices | Conditional M2M wiring: `if cfg.MultiTenantEnabled` → AWS Secrets Manager client + M2M provider |

**Conditional — RabbitMQ only (Gate 6):**

| File Pattern | What Changes |
|-------------|-------------|
| `internal/adapters/rabbitmq/producer*.go` | Dual constructor: single-tenant (direct connection) + multi-tenant (`tmrabbitmq.Manager.GetChannel`). `X-Tenant-ID` header injection |
| `internal/adapters/rabbitmq/consumer*.go` (or `internal/bootstrap/`) | `tmconsumer.MultiTenantConsumer` with on-demand initialization. `X-Tenant-ID` header extraction |

**Tests (Gate 7-8):**

| File Pattern | What Tests |
|-------------|------------|
| `internal/bootstrap/*_test.go` | `TestMultiTenant_BackwardCompatibility` — validates single-tenant mode works unchanged |
| `internal/adapters/**/*_test.go` | Unit tests with mock tenant context, tenant isolation tests (two tenants, data separation) |
| `internal/service/*_test.go` (or integration test dir) | Integration tests with two distinct tenants verifying cross-tenant isolation |

**Output artifacts (Gate 11):**

| File | What |
|------|------|
| `docs/multi-tenant-guide.md` | Activation guide: env vars, how to enable/disable, verification steps |
| `docs/multi-tenant-preview.html` | Visual implementation preview (generated at Gate 1.5, kept for reference) |

**HARD GATE: Files outside this map that contain multi-tenant logic are non-compliant.** If a service has custom files like `internal/tenant/resolver.go`, `internal/middleware/tenant_middleware.go`, `pkg/multitenancy/pool.go` or similar — these MUST be removed and replaced with the canonical lib-commons v4 dispatch layer sub-packages wired through the files listed above.

### Required lib-commons Version

Multi-tenant support requires **lib-commons v4** (`github.com/LerianStudio/lib-commons/v4`). The `dispatch layer` package does not exist in v2.

| lib-commons version | Multi-tenant support | Package path |
|--------------------|-----------------------|-------------|
| **v2** (`lib-commons/v2`) | Not available | N/A — no `dispatch layer` package |
| **v3** (`lib-commons/v3`) | Legacy | Same sub-packages as v4 but without `dispatch layer/cache`. Upgrade to v4. |
| **v4** (`lib-commons/v4`) | Full support (current) | `github.com/LerianStudio/lib-commons/v4/commons/dispatch layer/...` (sub-packages: `core`, `client`, `cache`, `postgres`, `mongo`, `middleware`, `rabbitmq`, `consumer`, `valkey`, `s3`). The `middleware` sub-package contains `TenantMiddleware` with `WithPG`/`WithMB` variadic options that handle both single-module and multi-module services. Route-level composition uses a local `WhenEnabled` helper (not from lib-commons). |

**Migration to v4:**

Services on lib-commons v2 or v3 MUST upgrade to v4 before implementing multi-tenant. The upgrade involves:

1. Update `go.mod` to the latest v4 tag
2. Update all import paths to v4
3. Add the `dispatch layer` package imports where needed

```bash
# Check latest v4 tag
git ls-remote --tags https://github.com/LerianStudio/lib-commons.git | grep "v4" | sort -V | tail -1

# Update go.mod
go get github.com/LerianStudio/lib-commons/v4@v4.5.0

# Update import paths across the codebase (portable — works on macOS and Linux)
# From v2:
find . -name "*.go" -exec perl -pi -e 's|lib-commons/v2|lib-commons/v4|g' {} +
# From v3:
find . -name "*.go" -exec perl -pi -e 's|lib-commons/v3|lib-commons/v4|g' {} +

# Verify build
go build ./...
```

### When to Use Multi-Tenant Mode

| Scenario | Mode | Configuration |
|----------|------|---------------|
| Single customer deployment | Single-tenant | `MULTI_TENANT_ENABLED=false` (default) |
| SaaS with shared infrastructure | Multi-tenant | `MULTI_TENANT_ENABLED=true` |
| Multiple isolated databases per customer | Multi-tenant | Requires Tenant Manager |

### Environment Variables

| Env Var | Description | Default | Required |
|---------|-------------|---------|----------|
| `APPLICATION_NAME` | Service name for Tenant Manager API (`/tenants/{id}/services/{service}/settings`) | - | Yes |
| `MULTI_TENANT_ENABLED` | Enable multi-tenant mode | `false` | Yes |
| `MULTI_TENANT_URL` | Tenant Manager service URL | - | If multi-tenant |
| `MULTI_TENANT_REDIS_HOST` | Redis host for Pub/Sub event-driven tenant discovery (same Redis as dispatch layer) | - | If multi-tenant |
| `MULTI_TENANT_REDIS_PORT` | Redis port for Pub/Sub | `6379` | If multi-tenant |
| `MULTI_TENANT_REDIS_PASSWORD` | Redis password for Pub/Sub | - | If multi-tenant |
| `MULTI_TENANT_REDIS_TLS` | Enable TLS for Pub/Sub Redis connection (AWS ElastiCache/Valkey) | `false` | If multi-tenant |
| `MULTI_TENANT_MAX_TENANT_POOLS` | Soft limit for tenant connection pools (LRU eviction) | `100` | No |
| `MULTI_TENANT_IDLE_TIMEOUT_SEC` | Seconds before idle tenant connection is eviction-eligible | `300` | No |
| `MULTI_TENANT_TIMEOUT` | HTTP client timeout for dispatch layer API calls (seconds). Passed to `tmclient.WithTimeout`. | `30` | No |
| `MULTI_TENANT_CIRCUIT_BREAKER_THRESHOLD` | Consecutive failures before circuit breaker opens | `5` | Yes |
| `MULTI_TENANT_CIRCUIT_BREAKER_TIMEOUT_SEC` | Seconds before circuit breaker resets (half-open) | `30` | Yes |
| `MULTI_TENANT_SERVICE_API_KEY` | API key for authenticating with dispatch layer `/settings` endpoint. Generated via service catalog. | - | If multi-tenant |
| `MULTI_TENANT_CACHE_TTL_SEC` | In-memory cache TTL for tenant config. Passed to the tenant client. | `120` | Yes |
| `MULTI_TENANT_CONNECTIONS_CHECK_INTERVAL_SEC` | pgManager async settings revalidation interval (via `WithConnectionsCheckInterval`). | `30` | Yes |


**Example `.env` for multi-tenant:**
```bash
MULTI_TENANT_ENABLED=true
MULTI_TENANT_URL=http://dispatch layer:4003
MULTI_TENANT_REDIS_HOST=redis
MULTI_TENANT_REDIS_PORT=6379
MULTI_TENANT_REDIS_PASSWORD=
MULTI_TENANT_REDIS_TLS=false
MULTI_TENANT_MAX_TENANT_POOLS=100
MULTI_TENANT_IDLE_TIMEOUT_SEC=300
MULTI_TENANT_TIMEOUT=30
MULTI_TENANT_CIRCUIT_BREAKER_THRESHOLD=5
MULTI_TENANT_CIRCUIT_BREAKER_TIMEOUT_SEC=30
MULTI_TENANT_SERVICE_API_KEY=your-service-api-key-here
MULTI_TENANT_CACHE_TTL_SEC=120
MULTI_TENANT_CONNECTIONS_CHECK_INTERVAL_SEC=30
```

### Configuration

```go
// internal/bootstrap/config.go
type Config struct {
    ApplicationName string `env:"APPLICATION_NAME"`

    // Multi-Tenant Configuration
    MultiTenantEnabled                  bool   `env:"MULTI_TENANT_ENABLED" default:"false"`
    MultiTenantURL                      string `env:"MULTI_TENANT_URL"`
    MultiTenantRedisHost                string `env:"MULTI_TENANT_REDIS_HOST"`
    MultiTenantRedisPort                string `env:"MULTI_TENANT_REDIS_PORT" default:"6379"`
    MultiTenantRedisPassword            string `env:"MULTI_TENANT_REDIS_PASSWORD"`
    MultiTenantRedisTLS                 bool   `env:"MULTI_TENANT_REDIS_TLS"`
    MultiTenantMaxTenantPools           int    `env:"MULTI_TENANT_MAX_TENANT_POOLS" default:"100"`
    MultiTenantIdleTimeoutSec           int    `env:"MULTI_TENANT_IDLE_TIMEOUT_SEC" default:"300"`
    MultiTenantTimeout                  int    `env:"MULTI_TENANT_TIMEOUT" default:"30"`
    MultiTenantCircuitBreakerThreshold  int    `env:"MULTI_TENANT_CIRCUIT_BREAKER_THRESHOLD" default:"5"`
    MultiTenantCircuitBreakerTimeoutSec int    `env:"MULTI_TENANT_CIRCUIT_BREAKER_TIMEOUT_SEC" default:"30"`
    MultiTenantServiceAPIKey            string `env:"MULTI_TENANT_SERVICE_API_KEY"`
    MultiTenantCacheTTLSec              int    `env:"MULTI_TENANT_CACHE_TTL_SEC" default:"120"`
    MultiTenantConnectionsCheckIntervalSec int    `env:"MULTI_TENANT_CONNECTIONS_CHECK_INTERVAL_SEC" default:"30"`

    // PostgreSQL Primary (used as default connection in single-tenant mode)
    PrimaryDBHost     string `env:"DB_HOST"`
    PrimaryDBUser     string `env:"DB_USER"`
    PrimaryDBPassword string `env:"DB_PASSWORD"`
    PrimaryDBName     string `env:"DB_NAME"`
    PrimaryDBPort     string `env:"DB_PORT"`
    PrimaryDBSSLMode  string `env:"DB_SSLMODE"`
}
```

### Service Name Resolution

The `service` parameter in `NewManager` maps to the Tenant Manager API path: `/tenants/{id}/services/{service}/settings`. Use `cfg.ApplicationName` (env `APPLICATION_NAME`):

```go
pgMgr := tmpostgres.NewManager(tmClient, cfg.ApplicationName,
    tmpostgres.WithModule("onboarding"),  // module = component name constant
    tmpostgres.WithLogger(logger),
)
```

| Parameter | Source | Purpose | Example |
|-----------|--------|---------|---------|
| `service` (2nd arg) | `cfg.ApplicationName` (env `APPLICATION_NAME`) | Tenant Manager API path | `"ledger"`, `"reporter"` |
| `module` (WithModule) | Component constant | Key in `TenantConfig.Databases[module]` | `"onboarding"`, `"transaction"`, `"manager"` |

### Manager Wiring

**TenantMiddleware (single-module):** Managers are passed via `WithPG`/`WithMB` options:

```go
mongoManager := tmmongo.NewManager(tmClient, cfg.ApplicationName, ...)
ttMid := tmmiddleware.NewTenantMiddleware(
    tmmiddleware.WithMB(mongoManager),
)
```

**TenantMiddleware (multi-module):** Use named `WithPG`/`WithMB` options for each module:

```go
middleware := tmmiddleware.NewTenantMiddleware(
    tmmiddleware.WithPG(onboardingPGManager, "onboarding"),
    tmmiddleware.WithPG(transactionPGManager, "transaction"),
    tmmiddleware.WithMB(onboardingMongoManager, "onboarding"),
    tmmiddleware.WithMB(transactionMongoManager, "transaction"),
    tmmiddleware.WithTenantCache(tenantCache),
    tmmiddleware.WithTenantLoader(tenantLoader),
)
```

### Tenant Manager Service API

The Tenant Manager is an external service that stores database credentials per tenant. All connection managers in lib-commons call this API to resolve tenant-specific connections.

**Endpoints:**

| Method | Path | Returns | Purpose |
|--------|------|---------|---------|
| `GET` | `/tenants/{tenantID}/services/{service}/settings` | `TenantConfig` | Full tenant configuration with DB credentials |
| `GET` | `/tenants/active?service={service}` | `[]*TenantSummary` | List of active tenants (fallback for discovery) |

**Tenant Discovery (for consumer mode):**
1. Primary: Redis `SMEMBERS "dispatch layer:tenants:active"` (fast, <1ms)
2. Fallback: HTTP `GET /tenants/active?service={service}` (slower, network call)

### TenantConfig Data Model

The Tenant Manager returns this structure for each tenant. The `Databases` map is keyed by **module name** (e.g., `"onboarding"`, `"transaction"`).

```go
type TenantConfig struct {
    ID            string                         // Tenant UUID
    TenantSlug    string                         // Human-readable slug
    IsolationMode string                         // "isolated" (default) or "schema"
    Databases     map[string]DatabaseConfig       // module -> config
    Messaging     *MessagingConfig               // RabbitMQ config (optional)
}

type DatabaseConfig struct {
    PostgreSQL         *PostgreSQLConfig
    PostgreSQLReplica  *PostgreSQLConfig    // Read replica (optional)
    MongoDB            *MongoDBConfig
    ConnectionSettings *ConnectionSettings  // Per-tenant pool overrides (optional)
}

// ConnectionSettings holds per-tenant database connection pool settings.
// When present, these values override the global defaults on PostgresManager/MongoManager.
// If nil (e.g., older tenant associations), global defaults apply.
type ConnectionSettings struct {
    MaxOpenConns int `json:"maxOpenConns"`
    MaxIdleConns int `json:"maxIdleConns"`
}
```

**Isolation Modes:**

| Mode | Database | Schema | Connection String | When to Use |
|------|----------|--------|-------------------|-------------|
| `isolated` (default) | Separate database per tenant | Default `public` schema | Standard connection | Strong isolation, recommended |
| `schema` | Shared database | Schema per tenant | Adds `options=-csearch_path="{schema}"` | Cost optimization, weaker isolation |

### Connection Pool Management

All connection managers (PostgreSQL, MongoDB, RabbitMQ) use **LRU eviction with soft limits**:

- **Soft limit** (`WithMaxTenantPools`): When the pool reaches this size and a new tenant needs a connection, only connections idle longer than the timeout are evicted. If all connections are active, the pool grows beyond the limit.
- **Idle timeout** (`WithIdleTimeout`): Connections not accessed within this window become eligible for eviction. Default: 5 minutes.
- **Connection health**: Cached connections are pinged before reuse (3s timeout). Stale connections are recreated transparently.

The Tenant Manager HTTP client MUST enable the **circuit breaker** (`WithCircuitBreaker`):
- After N consecutive failures, the circuit opens and requests fail fast with `ErrCircuitBreakerOpen`
- After the timeout, the circuit enters half-open state and allows one request through
- On success, the circuit resets to closed

### JWT Tenant Extraction

**Claim key:** `tenantId` (camelCase, hardcoded)

<cannot_skip>

**⛔ CRITICAL: `tenantId` from JWT is the ONLY multi-tenant mechanism.**

The `tenantId` identifies the client/customer. The lib-commons `TenantMiddleware` extracts it from the JWT, resolves the tenant-specific database connection via Tenant Manager API, and stores it in context. Each tenant has its own database — tenant A cannot query tenant B's database.

**`organization_id` is NOT part of multi-tenant isolation.** It is a separate concern (entity within a domain). Adding `organization_id` filters to queries does NOT provide tenant isolation. Multi-tenant isolation comes exclusively from `tenantId` → `TenantConnectionManager` → database-per-tenant.

**Anti-Rationalization:**

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Adding organization_id filters = multi-tenant" | organization_id does NOT route to different databases. All data still in ONE database. | **MUST implement tenantId → TenantConnectionManager** |
| "The codebase already has organization_id wiring" | organization_id is irrelevant for multi-tenant. tenantId from JWT is the mechanism. | **Implement TenantMiddleware with JWT tenantId extraction** |
| "Core one uses organization_id for tenant isolation" | WRONG. Core one has ZERO organization_id in WHERE clauses. It uses tenantId → tmcore.GetPGContext(ctx, module). | **Follow the actual pattern: tenantId → context → database routing** |

</cannot_skip>

```go
// internal/bootstrap/middleware.go
func extractTenantIDFromToken(c *fiber.Ctx) (string, error) {
    // Use lib-commons helper for token extraction
    accessToken := libHTTP.ExtractTokenFromHeader(c)
    if accessToken == "" {
        return "", errors.New("no authorization token provided")
    }

    // Parse without validation (validation done by auth middleware)
    token, _, err := new(jwt.Parser).ParseUnverified(accessToken, jwt.MapClaims{})
    if err != nil {
        return "", err
    }

    claims, ok := token.Claims.(jwt.MapClaims)
    if !ok {
        return "", errors.New("invalid token claims format")
    }

    // Extract tenantId (camelCase only - no fallbacks)
    tenantID, ok := claims["tenantId"].(string)
    if !ok || tenantID == "" {
        return "", errors.New("tenantId claim not found in token")
    }

    return tenantID, nil
}
```

### Generic TenantMiddleware (Standard Pattern)

**This is the standard pattern for all services.** The lib-commons `TenantMiddleware` handles JWT extraction, tenant resolution, and context injection automatically.

```go
// internal/bootstrap/config.go
import (
    "github.com/LerianStudio/lib-commons/v4/commons/dispatch layer/client"
    tmpostgres "github.com/LerianStudio/lib-commons/v4/commons/dispatch layer/postgres"
    tmmongo "github.com/LerianStudio/lib-commons/v4/commons/dispatch layer/mongo"
    "github.com/LerianStudio/lib-commons/v4/commons/dispatch layer/middleware"
)

func initService(cfg *Config) {
    // 1. Create Tenant Manager HTTP client (with circuit breaker — MANDATORY)
    var clientOpts []client.ClientOption
    if cfg.MultiTenantCircuitBreakerThreshold > 0 {
        clientOpts = append(clientOpts,
            client.WithCircuitBreaker(
                cfg.MultiTenantCircuitBreakerThreshold,
                time.Duration(cfg.MultiTenantCircuitBreakerTimeoutSec)*time.Second,
            ),
        )
    }
    if cfg.MultiTenantTimeout > 0 {
        clientOpts = append(clientOpts,
            client.WithTimeout(time.Duration(cfg.MultiTenantTimeout)*time.Second),
        )
    }
    clientOpts = append(clientOpts,
        client.WithServiceAPIKey(cfg.MultiTenantServiceAPIKey),
    )
    tmClient, err := client.NewClient(cfg.MultiTenantURL, logger, clientOpts...)
    if err != nil {
        return fmt.Errorf("creating dispatch layer client: %w", err)
    }

    idleTimeout := time.Duration(cfg.MultiTenantIdleTimeoutSec) * time.Second

    // 2. Create PostgreSQL manager (one per service or per module)
    pgManager := tmpostgres.NewManager(tmClient, "my-service",
        tmpostgres.WithModule("my-module"),
        tmpostgres.WithLogger(logger),
        tmpostgres.WithMaxTenantPools(cfg.MultiTenantMaxTenantPools),
        tmpostgres.WithIdleTimeout(idleTimeout),
    )

    // 3. Create MongoDB manager (optional)
    mongoManager := tmmongo.NewManager(tmClient, "my-service",
        tmmongo.WithModule("my-module"),
        tmmongo.WithLogger(logger),
        tmmongo.WithMaxTenantPools(cfg.MultiTenantMaxTenantPools),
        tmmongo.WithIdleTimeout(idleTimeout),
    )

    // 4. Create middleware (do NOT register globally — use per-route with WhenEnabled)
    ttMid := middleware.NewTenantMiddleware(
        middleware.WithPG(pgManager),
        middleware.WithMB(mongoManager),  // optional
        middleware.WithTenantCache(tenantCache),
        middleware.WithTenantLoader(tenantLoader),
    )
    // Pass ttMid.WithTenantDB as the ttHandler to routes.go.
    // In routes.go, register per-route using WhenEnabled(ttHandler).
    // When MULTI_TENANT_ENABLED=false, pass nil instead — WhenEnabled handles it.
    // See "Route-Level Auth-Before-Tenant Ordering" section
}
```

**What the middleware does internally:**
1. Extracts `Authorization: Bearer {token}` header
2. Parses JWT (unverified — auth middleware already validated it)
3. Extracts `tenantId` claim
4. Calls `PostgresManager.GetConnection(ctx, tenantID)` to resolve tenant-specific DB
5. Stores tenant ID and DB connection in context
6. If MongoDB manager is set, resolves and stores MongoDB connection
7. Calls `c.Next()`

**In repositories, use context-based getters:**

```go
import (
    tmcore "github.com/LerianStudio/lib-commons/v4/commons/dispatch layer/core"
    "github.com/LerianStudio/lib-commons/v4/commons/dispatch layer/valkey"
)

// Single-module service: use generic getter
db := tmcore.GetPGContext(ctx)

// Multi-module service: use module-specific getter
db := tmcore.GetPGContext(ctx, constant.ModuleOnboarding)

// MongoDB (single-module)
mongoDB := tmcore.GetMBContext(ctx)

// MongoDB (multi-module)
mongoDB := tmcore.GetMBContext(ctx, constant.ModuleOnboarding)

// Redis key prefixing
key := valkey.GetKeyContext(ctx, "cache-key")
// -> "tenant:{tenantId}:cache-key"

// Get tenant ID directly
tenantID := tmcore.GetTenantIDContext(ctx)
```

### Multi-module middleware (TenantMiddleware with multi-module)

**When to use:** Services that serve multiple modules on a single port with different databases per module. For example, midaz ledger serves onboarding and transaction modules in a single process, each with its own PostgreSQL and MongoDB pools.

**Most services do NOT need multi-module.** If your service has a single database (CRM, plugin-auth, reporter, etc.), use the standard `TenantMiddleware` above with unnamed `WithPG`/`WithMB`. Only use named module options when you have multiple database pools per type.

**Import:**

```go
import (
    tmmiddleware "github.com/LerianStudio/lib-commons/v4/commons/dispatch layer/middleware"
)
```

**Key types:**

| Type | Purpose |
|------|---------|
| `TenantMiddleware` | Unified middleware that handles both single-module and multi-module services via `WithPG`/`WithMB` variadic options |
| `TenantMiddlewareOption` | Functional option for configuring `TenantMiddleware` |

**Available options:**

| Option | Purpose | Required |
|--------|---------|----------|
| `WithPG(manager)` | Register a PostgreSQL manager (single-module, no name) | At least one PG or MB |
| `WithPG(manager, "module")` | Register a named PostgreSQL manager (multi-module) | At least one PG or MB |
| `WithMB(manager)` | Register a MongoDB manager (single-module, no name) | No |
| `WithMB(manager, "module")` | Register a named MongoDB manager (multi-module) | No |
| `WithTenantCache(cache)` | In-memory tenant cache (12h TTL, shared with EventListener) | Yes (event-driven) |
| `WithTenantLoader(loader)` | Lazy-load tenant config from dispatch layer API on cache miss | Yes (event-driven) |

#### Multi-module service example

```go
// config.go - Multi-module service (e.g., unified ledger with onboarding + transaction)
import (
    tmmiddleware "github.com/LerianStudio/lib-commons/v4/commons/dispatch layer/middleware"
)

middleware := tmmiddleware.NewTenantMiddleware(
    tmmiddleware.WithPG(onboardingPGManager, "onboarding"),
    tmmiddleware.WithPG(transactionPGManager, "transaction"),
    tmmiddleware.WithMB(onboardingMongoManager, "onboarding"),
    tmmiddleware.WithMB(transactionMongoManager, "transaction"),
    tmmiddleware.WithTenantCache(tenantCache),
    tmmiddleware.WithTenantLoader(tenantLoader),
)

// Pass middleware.WithTenantDB to routes.go — register per-route using WhenEnabled:
// See "Route-Level Auth-Before-Tenant Ordering" section
```

**What the middleware does internally:**
1. Extracts `Authorization: Bearer {token}` header and parses JWT
2. Extracts `tenantId` claim from JWT
3. Checks `TenantCache` for tenant config — if miss, calls `TenantLoader` to lazy-load from dispatch layer API
4. For each registered PG manager, resolves connection via `manager.GetConnection(ctx, tenantID)` and stores it using module-scoped context keys (via `ContextWithPG`)
5. For each registered MB manager, resolves MongoDB connection and stores it (via `ContextWithMB`)
6. Calls `c.Next()`

**In repositories for multi-module services, use module-scoped getters:**

```go
import tmcore "github.com/LerianStudio/lib-commons/v4/commons/dispatch layer/core"

// Multi-module: use module-specific getter
db := tmcore.GetPGContext(ctx, constant.ModuleTransaction)
db := tmcore.GetPGContext(ctx, constant.ModuleOnboarding)
```

#### Simple single-module service example

```go
// config.go - Single-module service (e.g., CRM, plugin, reporter)
// Use TenantMiddleware with unnamed WithPG/WithMB
import (
    tmmiddleware "github.com/LerianStudio/lib-commons/v4/commons/dispatch layer/middleware"
)

ttMid := tmmiddleware.NewTenantMiddleware(
    tmmiddleware.WithPG(pgManager),
    tmmiddleware.WithMB(mongoManager),  // optional
    tmmiddleware.WithTenantCache(tenantCache),
    tmmiddleware.WithTenantLoader(tenantLoader),
)
// Pass ttMid.WithTenantDB to routes.go — register per-route using WhenEnabled:
// See "Route-Level Auth-Before-Tenant Ordering" section
```

#### Single-module vs Multi-module

| Feature | Single-module | Multi-module |
|---------|--------------|-------------|
| PG option | `WithPG(manager)` | `WithPG(manager, "module")` |
| MB option | `WithMB(manager)` | `WithMB(manager, "module")` |
| Context getter (PG) | `tmcore.GetPGContext(ctx)` | `tmcore.GetPGContext(ctx, module)` |
| Context getter (MB) | `tmcore.GetMBContext(ctx)` | `tmcore.GetMBContext(ctx, module)` |
| When to use | Single-module services | Multi-module unified services |

**Rule of thumb:** If your service has one database module, use `WithPG(manager)` / `WithMB(manager)` (unnamed). If your service combines multiple modules with different databases behind one HTTP port, use `WithPG(manager, "module")` / `WithMB(manager, "module")` (named).

#### Multi-Tenant Error Responses

Each service implements its own error mapper using lib-commons error types:

| Scenario | HTTP Status | Error Type |
|----------|-------------|------------|
| Tenant suspended/purged | 403 | `*tmcore.TenantSuspendedError` |
| Tenant not found | 404 | `tmcore.ErrTenantNotFound` |
| DB schema not initialized | 422 | `tmcore.IsTenantNotProvisionedError(err)` |
| Tenant-manager unavailable | 503 | Network/connection error |

### Database Connection in Repositories

Repositories use a `getDB` helper that checks context for tenant connections with fallback to the static connection:

```go
// internal/adapters/postgres/entity/entity.postgresql.go

// getDB resolves the database connection from tenant context with fallback to static connection.
func (r *EntityPostgreSQLRepository) getDB(ctx context.Context) (dbresolver.DB, error) {
    // Multi-module: check module-specific context first
    if db := tmcore.GetPGContext(ctx, constant.ModuleOnboarding); db != nil {
        return db, nil
    }
    // Single-module: check generic context
    if db := tmcore.GetPGContext(ctx); db != nil {
        return db, nil
    }
    // Fallback to static connection (single-tenant mode)
    if r.requireTenant {
        return nil, fmt.Errorf("tenant postgres connection missing from context")
    }
    if r.connection == nil {
        return nil, fmt.Errorf("postgres connection not available")
    }
    return r.connection.Resolver(ctx)
}

func (r *EntityPostgreSQLRepository) Create(ctx context.Context, entity *mmodel.Entity) (*mmodel.Entity, error) {
    logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)

    ctx, span := tracer.Start(ctx, "postgres.create_entity")
    defer span.End()

    // Get tenant-specific connection from context
    db, err := r.getDB(ctx)
    if err != nil {
        libOpentelemetry.HandleSpanError(&span, "Failed to get database connection", err)
        logger.Errorf("Failed to get database connection: %v", err)
        return nil, err
    }

    record := &EntityPostgreSQLModel{}
    record.FromEntity(entity)

    // Use db for queries - automatically scoped to tenant's database
    // ...
}
```

### Redis Key Prefixing

```go
// internal/adapters/redis/repository.go
func (r *RedisRepository) Set(ctx context.Context, key, value string, ttl time.Duration) error {
    logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)

    ctx, span := tracer.Start(ctx, "redis.set")
    defer span.End()

    // Tenant-aware key prefixing (adds tenant:{tenantId}: prefix if multi-tenant)
    key = valkey.GetKeyContext(ctx, key)

    rds, err := r.conn.GetConnection(ctx)
    if err != nil {
        return err
    }

    return rds.Set(ctx, key, value, ttl).Err()
}
```

### S3/Object Storage Key Prefixing

Services that store files in S3 MUST prefix object keys with the tenant ID for tenant isolation. The bucket is configured per service via environment variable. Tenant separation is by directory within the bucket.

```go
// In any service/adapter that uploads, downloads, or deletes files from S3:
func (r *StorageRepository) Upload(ctx context.Context, originalKey, contentType string, data io.Reader) error {
    // Tenant-aware key prefixing: {tenantId}/{originalKey} in multi-tenant, {originalKey} in single-tenant
    key := s3.GetS3KeyStorageContext(ctx, originalKey)

    return r.s3Client.Upload(ctx, key, data, contentType)
}

func (r *StorageRepository) Download(ctx context.Context, originalKey string) (io.ReadCloser, error) {
    // MUST use the same prefixed key for reads and writes
    key := s3.GetS3KeyStorageContext(ctx, originalKey)

    return r.s3Client.Download(ctx, key)
}
```

**Storage structure:**
```
Bucket: {service-name}  (env var: OBJECT_STORAGE_BUCKET)
  └── {tenantId}/
       └── {resource}/{path}
```

**Backward compatibility:** When no tenant is in context (single-tenant mode), the key is returned unchanged — no prefix added.

### RabbitMQ Multi-Tenant: Two-Layer Isolation Model

RabbitMQ multi-tenant requires **two complementary layers** — both are mandatory:

| Layer | Mechanism | Purpose |
|-------|-----------|---------|
| **1. Vhost Isolation** | `tmrabbitmq.Manager` → `GetChannel(ctx, tenantID)` | **Isolation.** Each tenant gets its own RabbitMQ vhost. Queues, exchanges, and connections are fully separated. |
| **2. X-Tenant-ID Header** | `headers["X-Tenant-ID"] = tenantID` | **Audit + context propagation.** Enables distributed tracing, log correlation, and downstream tenant resolution. Does NOT provide isolation. |

**⛔ Layer 2 alone is NOT multi-tenant compliant.** A shared connection with `X-Tenant-ID` headers provides traceability but zero isolation — a poison message or traffic spike from one tenant affects all tenants.

**⛔ Layer 1 alone is incomplete.** Vhosts isolate but the `X-Tenant-ID` header is needed for log correlation, distributed tracing, and downstream context propagation across services.

### RabbitMQ Multi-Tenant Producer

```go
// internal/adapters/rabbitmq/producer.go
type ProducerRepository struct {
    conn            *libRabbitmq.RabbitMQConnection
    rabbitMQManager *tmrabbitmq.Manager
    multiTenantMode bool
}

// Single-tenant constructor
func NewProducer(conn *libRabbitmq.RabbitMQConnection) *ProducerRepository {
    return &ProducerRepository{
        conn:            conn,
        multiTenantMode: false,
    }
}

// Multi-tenant constructor
func NewProducerMultiTenant(pool *tmrabbitmq.Manager) *ProducerRepository {
    return &ProducerRepository{
        rabbitMQManager: pool,
        multiTenantMode: true,
    }
}

func (p *ProducerRepository) Publish(ctx context.Context, exchange, key string, message []byte) error {
    // Inject tenant ID header
    tenantID := tmcore.GetTenantIDContext(ctx)
    headers := amqp.Table{}
    if tenantID != "" {
        headers["X-Tenant-ID"] = tenantID
    }

    if p.multiTenantMode {
        if tenantID == "" {
            return fmt.Errorf("tenant ID is required in multi-tenant mode")
        }

        // Get tenant-specific channel from pool
        channel, err := p.rabbitMQManager.GetChannel(ctx, tenantID)
        if err != nil {
            return err
        }

        return channel.PublishWithContext(ctx, exchange, key, false, false,
            amqp.Publishing{
                ContentType:  "application/json",
                DeliveryMode: amqp.Persistent,
                Headers:      headers,
                Body:         message,
            })
    }

    // Single-tenant: use static connection
    return p.conn.Channel.Publish(exchange, key, false, false,
        amqp.Publishing{Body: message, Headers: headers})
}
```

### MongoDB Multi-Tenant Repository

```go
// internal/adapters/mongodb/metadata.go
type MetadataMongoDBRepository struct {
    connection *libMongo.MongoConnection
    dbName     string
}

func NewMetadataMongoDBRepository(conn *libMongo.MongoConnection, dbName string) *MetadataMongoDBRepository {
    return &MetadataMongoDBRepository{connection: conn, dbName: dbName}
}

// getMongoDB resolves the MongoDB database from tenant context with fallback to static connection.
func (r *MetadataMongoDBRepository) getMongoDB(ctx context.Context) (*mongo.Database, error) {
    // Multi-module: check module-specific context first
    if db := tmcore.GetMBContext(ctx, constant.ModuleOnboarding); db != nil {
        return db, nil
    }
    // Single-module: check generic context
    if db := tmcore.GetMBContext(ctx); db != nil {
        return db, nil
    }
    // Fallback to static connection (single-tenant mode)
    if r.connection == nil {
        return nil, fmt.Errorf("mongo connection not available")
    }
    return r.connection.GetDB(ctx), nil
}

func (r *MetadataMongoDBRepository) Create(ctx context.Context, collection string, metadata *Metadata) error {
    logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)

    ctx, span := tracer.Start(ctx, "mongodb.create_metadata")
    defer span.End()

    // Get tenant-specific database from context
    tenantDB, err := r.getMongoDB(ctx)
    if err != nil {
        libOpentelemetry.HandleSpanError(&span, "Failed to get database connection", err)
        return err
    }

    // Use tenant's database for operations
    coll := tenantDB.Collection(strings.ToLower(collection))

    record := &MetadataMongoDBModel{}
    if err := record.FromEntity(metadata); err != nil {
        return err
    }

    _, err = coll.InsertOne(ctx, record)
    if err != nil {
        libOpentelemetry.HandleSpanError(&span, "Failed to insert metadata", err)
        return err
    }

    return nil
}
```

### Event-Driven Tenant Discovery

**Replaces polling-based discovery.** Consumer services boot with an empty tenant map and discover tenants via:
1. **Redis Pub/Sub events** from dispatch layer (12 lifecycle events)
2. **Lazy-load on first HTTP request** via `GET /tenants/{orgId}/associations/{service}/connections`

**Components:**

| Component | Purpose |
|-----------|---------|
| `EventListener` | Standalone Redis Pub/Sub subscriber (`PSUBSCRIBE tenant-events:*`) |
| `TenantCache` | Shared in-memory cache (12h TTL) |
| `TenantLoader` | Lazy-load from dispatch layer API on cache miss |
| `EventDispatcher` | Routes events to handlers (evict, reload, start consumer) |

**Redis client for Pub/Sub (MANDATORY: use `NewTenantPubSubRedisClient`):**

```go
import tmredis "github.com/LerianStudio/lib-commons/v4/commons/dispatch layer/redis"

tmRedisClient, err := tmredis.NewTenantPubSubRedisClient(ctx, tmredis.TenantPubSubRedisConfig{
    Host:     cfg.MultiTenantRedisHost,
    Port:     cfg.MultiTenantRedisPort,
    Password: cfg.MultiTenantRedisPassword,
    TLS:      cfg.MultiTenantRedisTLS,
})
```

Do NOT build `redis.UniversalClient` manually — use the centralized helper above. NON-COMPLIANT if manual `libRedis.Config` setup is used instead.

**Event listener initialization (MANDATORY: use `NewTenantEventListener`):**

```go
import tmevent "github.com/LerianStudio/lib-commons/v4/commons/dispatch layer/event"

eventListener, err := tmevent.NewTenantEventListener(
    tmRedisClient,
    dispatcher.HandleEvent,
    tmevent.WithListenerLogger(logger),
    tmevent.WithService(tenantServiceName),
)
```

NON-COMPLIANT if `NewTenantEventListener` is not wired with the `NewTenantPubSubRedisClient` output. Both are required for event-driven tenant discovery.

**Callbacks (ordering is MANDATORY):**

- `WithOnTenantAdded` — (1) invalidates pmClient cache first (prevent stale config), then (2) starts RabbitMQ consumer goroutine
- `WithOnTenantRemoved` — (1) stops consumer goroutine first (prevent retry loops), then (2) closes ALL infrastructure connections, then (3) invalidates pmClient cache
- `TenantLoader.SetOnTenantLoaded` — starts RabbitMQ consumer after lazy-load (covers service restart)

```go
// OnTenantAdded: invalidate cache BEFORE starting consumer
tmevent.WithOnTenantAdded(func(ctx context.Context, tenantID string) {
    if tenantClient != nil {
        _ = tenantClient.InvalidateConfig(ctx, tenantID, tenantServiceName)
    }
    if consumer != nil {
        consumer.EnsureConsumerStarted(ctx, tenantID)
    }
})

// OnTenantRemoved: stop consumer FIRST, then close connections, then invalidate cache
tmevent.WithOnTenantRemoved(func(ctx context.Context, tenantID string) {
    if consumer != nil {
        consumer.StopConsumer(tenantID)
    }
    _ = onboardingPGManager.CloseConnection(ctx, tenantID)
    _ = transactionPGManager.CloseConnection(ctx, tenantID)
    _ = onboardingMongoManager.CloseConnection(ctx, tenantID)
    _ = transactionMongoManager.CloseConnection(ctx, tenantID)
    _ = rabbitmqManager.CloseConnection(ctx, tenantID)
    if tenantClient != nil {
        _ = tenantClient.InvalidateConfig(ctx, tenantID, tenantServiceName)
    }
})

// OnTenantLoaded: start consumer after lazy-load (covers service restart)
tenantLoader.SetOnTenantLoaded(func(ctx context.Context, tenantID string) {
    if consumer != nil {
        consumer.EnsureConsumerStarted(ctx, tenantID)
    }
})
```

**Event types reference:**

| Event | When | Consumer Action |
|-------|------|-----------------|
| `tenant.created` | Tenant created | No-op (lazy-load on first request) |
| `tenant.updated` | Metadata changed | Refresh TTL |
| `tenant.suspended` | Tenant suspended | Evict cache, close pools |
| `tenant.activated` | Tenant reactivated | Refresh TTL |
| `tenant.deleted` | Tenant deleted | Evict cache, close pools |
| `tenant.service.associated` | Service provisioned | Add to cache, start consumer |
| `tenant.service.disassociated` | Service removed | Evict cache, close pools, stop consumer |
| `tenant.service.suspended` | Service suspended | Evict cache, close pools |
| `tenant.service.purged` | Credentials revoked | Evict cache, close pools |
| `tenant.service.reactivated` | Service reactivated | Re-add to cache with jitter |
| `tenant.credentials.rotated` | M2M credentials rotated | Close pools, eager reload via /connections |
| `tenant.connections.updated` | Pool settings changed | Apply new settings |

Event envelope uses **snake_case** keys and **WorkOS org ID** as `tenant_id`.

### RabbitMQ Consumer Goroutine Startup

RabbitMQ consumer goroutines start on-demand in two scenarios:

| Scenario | Trigger | Callback |
|----------|---------|----------|
| Pub/Sub event (`tenant.service.associated`) | `OnTenantAdded` on dispatcher | `tenantClient.InvalidateConfig` then `consumer.EnsureConsumerStarted` |
| HTTP request lazy-load (after restart) | `onTenantLoaded` on loader | `consumer.EnsureConsumerStarted` |

`EnsureConsumerStarted` is idempotent — no-op if consumer already running.

After service restart, the first HTTP request for a tenant triggers lazy-load, the consumer starts, and pending messages in the queue are processed.

**Consumer teardown** happens in `OnTenantRemoved`:

| Step | Action | Why |
|------|--------|-----|
| 1 | `consumer.StopConsumer(tenantID)` | Stop goroutine and prevent retry loops BEFORE closing connections |
| 2 | Close all infrastructure connections (PG, Mongo, RabbitMQ) | Release resources |
| 3 | `tenantClient.InvalidateConfig(ctx, tenantID, serviceName)` | Prevent stale 200 responses allowing evicted tenant to reconnect |

**`onTenantLoaded` wiring** covers the restart scenario where no Pub/Sub event fires but the tenant is discovered via lazy-load:

```go
tenantLoader.SetOnTenantLoaded(func(ctx context.Context, tenantID string) {
    if consumer != nil {
        consumer.EnsureConsumerStarted(ctx, tenantID)
    }
})
```

### HTTP Client Transport

All HTTP clients that make concurrent requests (auth middleware, pmClient) must use custom `http.Transport` with `ForceAttemptHTTP2: false` to prevent Go stdlib HTTP/2 hpack panic under concurrent goroutine access.

lib-commons `pmClient` and lib-auth `sharedHTTPClient` already implement this. New HTTP clients must follow the same pattern:

```go
&http.Client{
    Timeout: 30 * time.Second,
    Transport: &http.Transport{
        Proxy:                 http.ProxyFromEnvironment,
        ForceAttemptHTTP2:     false,
        MaxIdleConns:          100,
        MaxIdleConnsPerHost:   10,
        IdleConnTimeout:       90 * time.Second,
        TLSHandshakeTimeout:  10 * time.Second,
        ExpectContinueTimeout: 1 * time.Second,
    },
}
```

### Conditional Initialization

The initialization path depends on whether the service runs a single module or combines multiple modules:

```go
// internal/bootstrap/service.go
func InitService(cfg *Config) (*Service, error) {
    // ttHandler starts as nil — WhenEnabled(nil) is a no-op (single-tenant passthrough)
    var ttHandler fiber.Handler

    if cfg.MultiTenantEnabled && cfg.MultiTenantURL != "" {
        if isUnifiedService {
            // Multi-module: use named WithPG/WithMB options
            // See "Multi-module middleware (TenantMiddleware with multi-module)" section above
            ttMid := tmmiddleware.NewTenantMiddleware(
                tmmiddleware.WithPG(onboardingPGManager, "onboarding"),
                tmmiddleware.WithPG(transactionPGManager, "transaction"),
                tmmiddleware.WithMB(onboardingMongoManager, "onboarding"),
                tmmiddleware.WithMB(transactionMongoManager, "transaction"),
                tmmiddleware.WithTenantCache(tenantCache),
                tmmiddleware.WithTenantLoader(tenantLoader),
            )
            ttHandler = ttMid.WithTenantDB
        } else {
            // Single-module: use unnamed WithPG/WithMB options
            // See "Generic TenantMiddleware (Standard Pattern)" section above
            ttMid := tmmiddleware.NewTenantMiddleware(
                tmmiddleware.WithPG(pgManager),
                tmmiddleware.WithTenantCache(tenantCache),
                tmmiddleware.WithTenantLoader(tenantLoader),
            )
            ttHandler = ttMid.WithTenantDB
        }
        // Do NOT register globally with app.Use() — register per-route in routes.go
        // using WhenEnabled(ttHandler). See "Route-Level Auth-Before-Tenant Ordering" section.

        logger.Infof("Multi-tenant mode enabled with Tenant Manager URL: %s", cfg.MultiTenantURL)
    } else {
        logger.Info("Running in SINGLE-TENANT MODE")
        // ttHandler remains nil — WhenEnabled(nil) calls c.Next() immediately
    }

    // Pass ttHandler to NewRoutes — routes use WhenEnabled(ttHandler) per-route
    // ...
}
```

**Most services follow the single-module path.** Only unified services like midaz ledger need the multi-module path with named `WithPG`/`WithMB` options.

### Testing Multi-Tenant Code

#### Unit Tests with Mock Tenant Context

```go
// internal/service/user_service_test.go
func TestUserService_Create_WithTenantContext(t *testing.T) {
    // Setup tenant context
    tenantID := "tenant-123"
    ctx := core.ContextWithTenantID(context.Background(), tenantID)

    // Mock database connection
    mockDB := setupMockDB(t)
    ctx = tmcore.ContextWithPG(ctx, mockDB)

    // Create service with mock dependencies
    repo := repository.NewUserRepository()
    service := service.NewUserService(repo, logger)

    // Execute
    input := &CreateUserInput{Name: "John", Email: "john@example.com"}
    result, err := service.Create(ctx, input)

    // Assert
    require.NoError(t, err)
    assert.Equal(t, "John", result.Name)
}
```

#### Testing Tenant Isolation

```go
func TestRepository_Create_TenantIsolation(t *testing.T) {
    tests := []struct {
        name     string
        tenantID string
        input    *Entity
        wantErr  bool
    }{
        {
            name:     "tenant-1 creates entity",
            tenantID: "tenant-1",
            input:    &Entity{Name: "Entity A"},
            wantErr:  false,
        },
        {
            name:     "tenant-2 creates same entity (isolated)",
            tenantID: "tenant-2",
            input:    &Entity{Name: "Entity A"},
            wantErr:  false, // Different tenant = different database = allowed
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            // Inject tenant-specific context
            ctx := core.ContextWithTenantID(context.Background(), tt.tenantID)
            ctx = tmcore.ContextWithPG(ctx, mockDB)

            _, err := repo.Create(ctx, tt.input)

            if tt.wantErr {
                require.Error(t, err)
            } else {
                require.NoError(t, err)
            }
        })
    }
}
```

#### Integration Tests with Tenant Isolation

```go
// tests/integration/multi_tenant_test.go
func TestMultiTenant_TenantIsolation(t *testing.T) {
    if !h.IsMultiTenantEnabled() {
        t.Skip("Multi-tenant mode is not enabled")
    }

    env := h.LoadEnvironment()
    ctx := context.Background()
    client := h.NewHTTPClient(env.ServerURL, env.HTTPTimeout)

    // Define two distinct tenants
    tenantA := "tenant-a-" + h.RandString(6)
    tenantB := "tenant-b-" + h.RandString(6)

    headersTenantA := h.TenantAuthHeaders(h.RandHex(8), tenantA)
    headersTenantB := h.TenantAuthHeaders(h.RandHex(8), tenantB)

    // Step 1: Tenant A creates organization
    codeA, bodyA, _ := client.Request(ctx, "POST", "/v1/organizations", headersTenantA, orgPayload)
    require.Equal(t, 201, codeA)

    var orgA struct{ ID string `json:"id"` }
    json.Unmarshal(bodyA, &orgA)

    // Step 2: Tenant B creates organization
    codeB, bodyB, _ := client.Request(ctx, "POST", "/v1/organizations", headersTenantB, orgPayload)
    require.Equal(t, 201, codeB)

    var orgB struct{ ID string `json:"id"` }
    json.Unmarshal(bodyB, &orgB)

    // Step 3: Verify Tenant A cannot see Tenant B's data
    code, body, _ := client.Request(ctx, "GET", "/v1/organizations", headersTenantA, nil)
    require.Equal(t, 200, code)

    var list struct{ Items []struct{ ID string `json:"id"` } `json:"items"` }
    json.Unmarshal(body, &list)

    for _, item := range list.Items {
        assert.NotEqual(t, orgB.ID, item.ID, "ISOLATION VIOLATION: Tenant A can see Tenant B's data")
    }
}
```

#### Testing Error Cases

```go
func TestMiddleware_WithTenantDB_ErrorCases(t *testing.T) {
    tests := []struct {
        name           string
        setupContext   func(*fiber.Ctx)
        expectedStatus int
        expectedCode   string
    }{
        {
            name: "missing JWT token",
            setupContext: func(c *fiber.Ctx) {
                // No Authorization header
            },
            expectedStatus: 401,
            expectedCode:   "TENANT_ID_REQUIRED",
        },
        {
            name: "JWT without tenantId claim",
            setupContext: func(c *fiber.Ctx) {
                token := createJWTWithoutTenantClaim()
                c.Request().Header.Set("Authorization", "Bearer "+token)
            },
            expectedStatus: 401,
            expectedCode:   "TENANT_ID_REQUIRED",
        },
        {
            name: "tenant not found in Tenant Manager",
            setupContext: func(c *fiber.Ctx) {
                token := createJWT(map[string]interface{}{"tenantId": "unknown-tenant"})
                c.Request().Header.Set("Authorization", "Bearer "+token)
            },
            expectedStatus: 404,
            expectedCode:   "TENANT_NOT_FOUND",
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            app := fiber.New()
            ctx := app.AcquireCtx(&fasthttp.RequestCtx{})
            defer app.ReleaseCtx(ctx)

            tt.setupContext(ctx)

            err := middleware.WithTenantDB(ctx)

            require.Error(t, err)
            fiberErr, ok := err.(*fiber.Error)
            require.True(t, ok)
            assert.Equal(t, tt.expectedStatus, fiberErr.Code)
        })
    }
}
```

#### Testing RabbitMQ Multi-Tenant Consumer

```go
func TestRabbitMQConsumer_MultiTenant(t *testing.T) {
    t.Run("injects tenant context from X-Tenant-ID header", func(t *testing.T) {
        tenantID := "tenant-456"

        // Create message with tenant header
        message := amqp.Delivery{
            Headers: amqp.Table{
                "X-Tenant-ID": tenantID,
            },
            Body: []byte(`{"action": "create"}`),
        }

        // Setup consumer
        consumer := NewMultiTenantConsumer(pool, logger)

        // Process message
        ctx, err := consumer.injectTenantDBConnections(
            context.Background(),
            tenantID,
            logger,
        )

        // Assert tenant context injected
        require.NoError(t, err)
        extractedTenant := tmcore.GetTenantIDContext(ctx)
        assert.Equal(t, tenantID, extractedTenant)
    })
}
```

#### Testing Redis Key Prefixing

```go
func TestRedisRepository_MultiTenant_KeyPrefixing(t *testing.T) {
    t.Run("prefixes keys with tenant ID", func(t *testing.T) {
        tenantID := "tenant-789"
        ctx := core.ContextWithTenantID(context.Background(), tenantID)

        repo := NewRedisRepository(redisConn)

        err := repo.Set(ctx, "user:session", "value123", 3600)
        require.NoError(t, err)

        // Verify key was prefixed
        key := valkey.GetKeyContext(ctx, "user:session")
        assert.Equal(t, "tenant:tenant-789:user:session", key)
    })

    t.Run("single-tenant mode does not prefix keys", func(t *testing.T) {
        ctx := context.Background()

        key := valkey.GetKeyContext(ctx, "user:session")
        assert.Equal(t, "user:session", key)
    })
}
```

### Error Handling

| Error | HTTP Status | Code | When |
|-------|-------------|------|------|
| Missing tenantId claim | 401 | `TENANT_ID_REQUIRED` | JWT doesn't have tenantId |
| Tenant not found | 404 | `TENANT_NOT_FOUND` | Tenant not registered in Tenant Manager |
| Tenant not provisioned | 422 | `TENANT_NOT_PROVISIONED` | Database schema not initialized (SQLSTATE 42P01) |
| Tenant suspended | 403 | service-specific | Tenant status is suspended or purged (use `errors.As(err, &core.TenantSuspendedError{})`) |
| Service not configured | 503 | service-specific | Tenant exists but has no config for this service/module (`core.ErrServiceNotConfigured`) |
| Schema mode error | 422 | service-specific | Invalid schema configuration for tenant database |
| Connection error | 503 | service-specific | Failed to get or establish tenant connection |
| Manager closed | 503 | service-specific | Connection manager has been shut down (`core.ErrManagerClosed`) |
| Circuit breaker open | 503 | service-specific | Tenant Manager client tripped after consecutive failures (`core.ErrCircuitBreakerOpen`) |
| Tenant config rate limited | 503 | service-specific | Too many concurrent requests for the same tenant config — retry after brief delay |

### Tenant Isolation Verification (⚠️ CONDITIONAL)

Multi-tenant applications MUST verify tenant isolation to prevent data leakage between tenants.

**⛔ CONDITIONAL:** This section applies ONLY if `MULTI_TENANT_ENABLED=true`. If single-tenant, mark as N/A.

**Detection Question:** Is this a multi-tenant service?

```bash
# Check if multi-tenant mode is enabled
grep -rn "MULTI_TENANT_ENABLED\|MultiTenantEnabled" internal/ --include="*.go"

# If 0 matches OR always set to false: Mark N/A
# If found AND can be true: Apply this section
```

#### Isolation Architecture

Multi-tenant isolation uses a **database-per-tenant** model. The `tenantId` from JWT determines which database the request connects to. Each tenant has its own database — tenant A cannot query tenant B's database.

| Mechanism | How It Works | Protection |
|-----------|-------------|------------|
| **JWT `tenantId` extraction** | `TenantMiddleware` extracts `tenantId` claim from JWT | Identifies the tenant |
| **Database routing** | `TenantConnectionManager` resolves tenant-specific DB connection | Tenant A → Database A, Tenant B → Database B |
| **Context injection** | Connection stored in request context | Repositories use `tmcore.GetPGContext(ctx)` / `tmcore.GetPGContext(ctx, module)` / `tmcore.GetMBContext(ctx)` / `tmcore.GetMBContext(ctx, module)` |
| **Single-tenant passthrough** | `IsMultiTenant() == false` → `c.Next()` immediately | Backward compatibility |

#### Why Tenant Isolation Verification Is MANDATORY

| Attack | Without Verification | With Verification |
|--------|----------------------|-------------------|
| Cross-tenant data access | Tenant A accesses Tenant B's database | Connection-level isolation prevents it |
| Data exfiltration | Cross-tenant data leakage | Separate databases per tenant |

#### Detection Commands (MANDATORY)

```bash
# MANDATORY: Run before every PR in multi-tenant services
# Verify all repositories use context-based connections (not static)
grep -rn "GetPGContext\|GetMBContext" internal/adapters/ --include="*.go"

# Verify no repositories use static/hardcoded connections when multi-tenant is enabled
# Excludes tenant-aware variables (tenantDB, tenantmanager) to avoid false positives
grep -rn "\.DB\.\|\.Database\." internal/adapters/ --include="*.go" | grep -v "_test.go" | grep -v "tenantmanager\|tenantDB"

# Expected: All repositories should use dispatch layer context getters (core, valkey, s3 packages)
```

#### Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Static connection works fine" | Static connection goes to ONE database. All tenants share it. No isolation. | **Use tmcore.GetPGContext(ctx) / tmcore.GetPGContext(ctx, module) / tmcore.GetMBContext(ctx) / tmcore.GetMBContext(ctx, module)** |
| "We only have one customer" | Requirements change. Multi-tenant is easy to add now, hard later. | **Design for multi-tenant, deploy as single** |
| "organization_id filtering = tenant isolation" | organization_id does NOT route to different databases. It is NOT multi-tenant. | **Use tenantId from JWT → TenantConnectionManager** |

### Context Functions

lib-commons provides two sets of context functions for database resolution. Use module-specific getters for multi-module services and generic getters for single-module services.

**Context getters (used by repository code):**

| Function | Use When |
|----------|----------|
| `tmcore.GetPGContext(ctx)` | Single-module — returns generic PG connection |
| `tmcore.GetPGContext(ctx, module)` | Multi-module — returns module-specific PG connection |
| `tmcore.GetMBContext(ctx)` | Single-module — returns generic MongoDB |
| `tmcore.GetMBContext(ctx, module)` | Multi-module — returns module-specific MongoDB |

```go
// Single-module: use generic getter
db := tmcore.GetPGContext(ctx)

// Multi-module: use module-specific getter
db := tmcore.GetPGContext(ctx, constant.ModuleOnboarding)
```

**Context setters (used by middleware, not by service code):**
- `tmcore.ContextWithTenantID(ctx, tenantID)` — stores tenant ID
- `tmcore.ContextWithPG(ctx, db)` — generic PG connection (set by TenantMiddleware for single-module)
- `tmcore.ContextWithPG(ctx, db, module)` — module-specific PG (when service has multiple DB modules; also sets generic)
- `tmcore.ContextWithMB(ctx, db)` — generic MongoDB connection
- `tmcore.ContextWithMB(ctx, db, module)` — module-specific MongoDB (also sets generic)

### Tenant ID Validation

lib-commons validates tenant IDs to prevent path traversal and injection:

```go
const maxTenantIDLength = 256
var validTenantIDPattern = regexp.MustCompile(`^[a-zA-Z0-9][a-zA-Z0-9_-]*$`)
```

Rules:
- Must start with alphanumeric character
- Only alphanumeric, underscore, and hyphen allowed
- Maximum 256 characters
- Empty strings rejected

### Redis Key Prefixing for Lua Scripts

Beyond simple `Set/Get` operations, Redis Lua scripts require special attention. ALL keys passed as `KEYS[]` and `ARGV[]` to Lua scripts MUST be pre-prefixed in Go **before** the script execution:

```go
// ✅ CORRECT: Prefix keys in Go before Lua execution
prefixedBackupQueue := valkey.GetKeyContext(ctx, TransactionBackupQueue)
prefixedTransactionKey := valkey.GetKeyContext(ctx, transactionKey)
prefixedBalanceSyncKey := valkey.GetKeyContext(ctx, utils.BalanceSyncScheduleKey)

// Also prefix ARGV values that are used as keys inside the Lua script
prefixedInternalKey := valkey.GetKeyContext(ctx, blcs.InternalKey)

result, err := script.Run(ctx, rds,
    []string{prefixedBackupQueue, prefixedTransactionKey, prefixedBalanceSyncKey},
    finalArgs...).Result()
```

```go
// ❌ FORBIDDEN: Hardcoded keys inside Lua script
-- Lua script must NEVER reference keys by name
local key = "balance:lock"  -- WRONG: not tenant-prefixed

// ✅ CORRECT: Lua script uses only KEYS[] and ARGV[]
local backupQueue = KEYS[1]  -- Already prefixed by Go caller
local txKey = KEYS[2]        -- Already prefixed by Go caller
```

This pattern also ensures Redis Cluster compatibility (all keys in `KEYS[]` must be in the same hash slot for atomic operations).

### Multi-Tenant Metrics

Services implementing multi-tenant MUST expose these metrics:

| Metric | Type | Description |
|--------|------|-------------|
| `tenant_connections_total` | Counter | Total tenant connections created |
| `tenant_connection_errors_total` | Counter | Connection failures per tenant |
| `tenant_consumers_active` | Gauge | Active message consumers |
| `tenant_messages_processed_total` | Counter | Messages processed per tenant |

### Responsibility Split: lib-commons vs Service

| Responsibility | lib-commons handles | Service MUST implement |
|---------------|--------------------|-----------------------|
| **Connection pooling** | Cache per tenant, double-check locking | - |
| **Credential fetching** | HTTP call to Tenant Manager API | - |
| **JWT parsing** | Extract `tenantId` from token (both middlewares) | - |
| **Tenant discovery** | Redis -> API fallback, sync loop | - |
| **Consumer lifecycle** | On-demand spawn, backoff, degraded tracking | - |
| **Multi-module connection injection** | `TenantMiddleware` resolves PG/MB for all registered modules | - |
| **Error mapping** | Default error mapper in middleware | - |
| **Middleware registration** | - | Register `TenantMiddleware` with `WithPG`/`WithMB` on routes |
| **Repository adaptation** | - | Use `tmcore.GetPGContext(ctx)` / `tmcore.GetPGContext(ctx, module)` / `tmcore.GetMBContext(ctx)` / `tmcore.GetMBContext(ctx, module)` instead of global DB |
| **Redis key prefixing** | - | Call `valkey.GetKeyContext(ctx, key)` for every Redis operation |
| **S3 key prefixing** | Tenant-aware key prefix (`s3.GetS3KeyStorageContext`) | Call `s3.GetS3KeyStorageContext(ctx, key)` for every S3 operation |
| **Consumer setup** | - | Register handlers, call `consumer.Run(ctx)` at startup |
| **Settings revalidation (PostgreSQL only)** | pgManager handles internally via `WithConnectionsCheckInterval`, `ApplyConnectionSettings()` | Pass `WithConnectionsCheckInterval` when creating pgManager. MongoDB excluded (driver cannot resize pools). |
| **Error handling** | Return sentinel errors | Map errors to HTTP status codes (or provide custom `ErrorMapper`) |

### Anti-Rationalization Table (General)

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Service already has multi-tenant code" | Existence ≠ compliance. Code that doesn't match the Ring canonical model (lib-commons v4 dispatch layer sub-packages) is non-compliant and MUST be replaced entirely. | **STOP. Run compliance audit against this document. Replace every non-compliant component.** |
| "Our custom multi-tenant approach works" | Working ≠ compliant. Custom implementations create drift, block lib-commons upgrades, prevent standardized tooling, and cannot be validated by automated compliance checks. | **STOP. Replace with canonical lib-commons v4 implementation.** |
| "Just need to adapt/patch the existing code" | Non-standard implementations cannot be patched into compliance. The patterns are structurally different (context-based resolution vs static connections, lib-commons middleware vs custom middleware). | **STOP. Replace, do not patch.** |
| "We only have one customer" | Requirements change. Multi-tenant is easy to add now, hard later. | **Design for multi-tenant, deploy as single** |
| "Tenant Manager adds complexity" | Complexity is in connection management anyway. Tenant Manager standardizes it. | **Use Tenant Manager for multi-tenant** |
| "JWT parsing is expensive" | Parse once in middleware, use from context everywhere. | **Extract tenant once, propagate via context** |
| "We'll add tenant isolation later" | Retrofitting tenant isolation is a rewrite. | **Build tenant-aware from the start** |

### Final Step: Single-Tenant Backward Compatibility Validation (MANDATORY)

**HARD GATE: This is the LAST step of every multi-tenant implementation.** CANNOT merge or deploy without completing this validation.

If the service was already running as single-tenant before multi-tenant was added, it MUST continue working unchanged with `MULTI_TENANT_ENABLED=false` (the default). Multi-tenant is opt-in. Single-tenant is the baseline. Breaking it is a production incident for all existing deployments.

#### How the Backward Compatibility Mechanism Works

The middleware checks `pool.IsMultiTenant()` at the start of every request. When `MULTI_TENANT_ENABLED=false`:
- `IsMultiTenant()` returns `false`
- Middleware returns `c.Next()` immediately — zero tenant logic applied
- No JWT parsing, no Tenant Manager calls, no pool routing
- The service uses its default database connection as before

```go
// Single-tenant mode: pass through if pool is not multi-tenant
if !pool.IsMultiTenant() {
    return c.Next()  // No tenant logic applied — service works as before
}
```

#### Validation Steps (execute in order)

**Step 1 — Remove all multi-tenant env vars and start the service:**
```bash
# Unset ALL multi-tenant variables
unset MULTI_TENANT_ENABLED MULTI_TENANT_URL
unset MULTI_TENANT_MAX_TENANT_POOLS MULTI_TENANT_IDLE_TIMEOUT_SEC
unset MULTI_TENANT_CIRCUIT_BREAKER_THRESHOLD MULTI_TENANT_CIRCUIT_BREAKER_TIMEOUT_SEC

# Start the service — MUST start without errors, without Tenant Manager running
go run cmd/app/main.go
# Expected log: "Running in SINGLE-TENANT MODE"
```

**Step 2 — Run the full existing test suite (single-tenant):**
```bash
# ALL pre-existing tests MUST pass with multi-tenant disabled
MULTI_TENANT_ENABLED=false go test ./...
```

**Step 3 — Run backward compatibility integration test:**
```go
func TestMultiTenant_BackwardCompatibility(t *testing.T) {
    // MUST skip when multi-tenant is enabled — this test validates single-tenant only
    if h.IsMultiTenantEnabled() {
        t.Skip("Skipping backward compatibility test - multi-tenant mode is enabled")
    }

    // Create resources WITHOUT tenant context — MUST work in single-tenant mode
    code, body, err := client.Request(ctx, "POST", "/v1/organizations", headers, orgPayload)
    require.Equal(t, 201, code, "single-tenant CRUD must work without tenant context")

    // List resources — MUST return data normally
    code, body, err = client.Request(ctx, "GET", "/v1/organizations", headers, nil)
    require.Equal(t, 200, code, "single-tenant list must work without tenant context")

    // Health endpoints — MUST work without any auth or tenant context
    code, _, _ = client.Request(ctx, "GET", "/health", nil, nil)
    require.Equal(t, 200, code, "health endpoint must work in single-tenant mode")
}
```

**Step 4 — Validate against this checklist:**

| # | Check | How to Verify | Pass Criteria |
|---|-------|--------------|---------------|
| 1 | Service starts without `MULTI_TENANT_*` vars | Remove all vars, start service | Starts normally, logs "SINGLE-TENANT MODE" |
| 2 | Service starts without Tenant Manager | Don't run Tenant Manager, start service | No connection errors, no panics |
| 3 | All existing CRUD operations work | Run pre-existing integration tests | All pass with same behavior as before |
| 4 | Health/version/swagger endpoints work | `GET /health`, `GET /version` | 200 OK without any auth headers |
| 5 | Default DB connection is used | Check DB queries go to the configured `DB_HOST` | Queries hit single-tenant database |
| 6 | No new required env vars break startup | Start with only the env vars the service had before | Service starts without errors |

**Step 5 — Run multi-tenant test suite (both modes work):**
```bash
# Confirm multi-tenant mode also works
MULTI_TENANT_ENABLED=true MULTI_TENANT_URL=http://dispatch layer:4003 go test ./... -run "MultiTenant"
```

#### Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Nobody uses single-tenant anymore" | Existing deployments depend on it. Breaking them is a production incident for every customer running self-hosted. | **STOP. Run the validation steps.** |
| "We tested multi-tenant, that's enough" | Multi-tenant tests exercise a DIFFERENT code path (`IsMultiTenant()=true`). Single-tenant (`IsMultiTenant()=false`) is a separate path that needs separate verification. | **STOP. Run both test suites.** |
| "The passthrough is trivial, it can't break" | Config struct changes, new required env vars, middleware ordering changes, import side effects — all of these can silently break the passthrough path. | **STOP. Verify with actual requests.** |
| "I'll test single-tenant later" | Later never comes. Once merged, the damage is done. Existing CI may not catch it if tests assume multi-tenant. | **STOP. Test now, before merge.** |

### Checklist

**Environment Variables:**
- [ ] `MULTI_TENANT_ENABLED` in config struct (default: `false`)
- [ ] `MULTI_TENANT_URL` in config struct (required if multi-tenant)
- [ ] `MULTI_TENANT_REDIS_HOST` in config struct (required if multi-tenant)
- [ ] `MULTI_TENANT_REDIS_PORT` in config struct (default: `6379`)
- [ ] `MULTI_TENANT_REDIS_PASSWORD` in config struct
- [ ] `MULTI_TENANT_REDIS_TLS` in config struct (default: `false`)
- [ ] `MULTI_TENANT_MAX_TENANT_POOLS` in config struct (default: `100`)
- [ ] `MULTI_TENANT_IDLE_TIMEOUT_SEC` in config struct (default: `300`)
- [ ] `MULTI_TENANT_CIRCUIT_BREAKER_THRESHOLD` in config struct (default: `5`)
- [ ] `MULTI_TENANT_CIRCUIT_BREAKER_TIMEOUT_SEC` in config struct (default: `30`)
- [ ] `MULTI_TENANT_SERVICE_API_KEY` in config struct (required)
- [ ] `MULTI_TENANT_CACHE_TTL_SEC` in config struct (default: `120`)
- [ ] `MULTI_TENANT_CONNECTIONS_CHECK_INTERVAL_SEC` in config struct (default: `30`)

**Event-Driven Discovery (required if multi-tenant):**
- [ ] `tmredis.NewTenantPubSubRedisClient(ctx, cfg)` used to create Redis client (NOT manual `libRedis.Config`)
- [ ] `tmevent.NewTenantEventListener(tmRedisClient, dispatcher.HandleEvent, ...)` wired with Pub/Sub Redis client
- [ ] All 14 canonical `MULTI_TENANT_*` envs declared in `.env.example` (commented out with defaults)

**Architecture:**
- [ ] `client.NewClient(url, logger, opts...)` returns `(*Client, error)` — handle error for fail-fast
- [ ] `client.WithServiceAPIKey(cfg.MultiTenantServiceAPIKey)` always passed (lib-commons validates internally)
- [ ] `tmpostgres.NewManager(client, service, WithModule(...), WithLogger(...), WithMaxTenantPools(...), WithIdleTimeout(...))` for PostgreSQL pool
- [ ] Each manager has `Stats()`, `IsMultiTenant()`, and `ApplyConnectionSettings()` methods

**Middleware — choose one:**
- [ ] For single-module services: `tmmiddleware.NewTenantMiddleware(WithPG(...), WithTenantCache(...), WithTenantLoader(...))` registered in routes via `WhenEnabled`
- [ ] For multi-module services: `tmmiddleware.NewTenantMiddleware(WithPG(..., "module"), WithMB(..., "module"), WithTenantCache(...), WithTenantLoader(...))` registered in routes via `WhenEnabled`
- [ ] `WhenEnabled` helper implemented locally in the routes file (nil check → `c.Next()`)
- [ ] Tenant middleware passed as nil when `MULTI_TENANT_ENABLED=false` (single-tenant passthrough via `WhenEnabled` nil check)

**Middleware & Context:**
- [ ] JWT tenant extraction (claim key: `tenantId`)
- [ ] `core.ContextWithTenantID()` in middleware
- [ ] Public endpoints (`/health`, `/version`, `/swagger`) bypass tenant middleware
- [ ] `core.ErrTenantNotFound` → 404, `core.ErrManagerClosed` → 503, `core.ErrServiceNotConfigured` → 503
- [ ] `core.IsTenantNotProvisionedError()` in error handler → 422
- [ ] `core.ErrTenantContextRequired` handled in repositories

**Repositories:**
- [ ] `tmcore.GetPGContext(ctx)` or `tmcore.GetPGContext(ctx, module)` in PostgreSQL repositories
- [ ] `valkey.GetKeyContext(ctx, key)` for ALL Redis keys (including Lua script KEYS[] and ARGV[])
- [ ] `tmcore.GetMBContext(ctx)` or `tmcore.GetMBContext(ctx, module)` in MongoDB repositories (if using MongoDB)
- [ ] `s3.GetS3KeyStorageContext(ctx, key)` for ALL S3 operations (if using S3/object storage)

**Async Processing:**
- [ ] Tenant ID header (`X-Tenant-ID`) in RabbitMQ messages
- [ ] `consumer.NewMultiTenantConsumer` with `consumer.WithPG` and `consumer.WithMB`
- [ ] `consumer.Register(queueName, handler)` for each queue
- [ ] `consumer.Run(ctx)` at startup (non-blocking, <1s)

**Testing:**
- [ ] Unit tests with mock tenant context
- [ ] Tenant isolation tests (verify data separation between tenants)
- [ ] Error case tests (missing tenant, invalid tenant, tenant not found)
- [ ] Integration tests with two distinct tenants verifying cross-tenant isolation
- [ ] RabbitMQ consumer tests (X-Tenant-ID header extraction)
- [ ] Redis key prefixing tests (verify tenant prefix applied, including Lua scripts)

**Single-Tenant Backward Compatibility (MANDATORY):**
- [ ] All existing tests pass with `MULTI_TENANT_ENABLED=false` (default)
- [ ] Service starts without any `MULTI_TENANT_*` environment variables
- [ ] Service starts without Tenant Manager running
- [ ] All CRUD operations work in single-tenant mode
- [ ] Backward compatibility integration test exists (`TestMultiTenant_BackwardCompatibility`)
- [ ] Health/version endpoints work without tenant context

---

## Route-Level Auth-Before-Tenant Ordering (MANDATORY)

**MANDATORY:** When using multi-tenant middleware, auth MUST validate the JWT **before** tenant middleware resolves the database connection. This ordering is a security requirement, not a performance optimization.

### Why This Matters

| Concern | Impact Without Auth-Before-Tenant |
|---------|-----------------------------------|
| **SECURITY** | Forged or expired JWTs trigger Tenant Manager API calls before token signature validation. Any request with a `tenantId` claim — valid or not — causes a network round-trip to resolve tenant DB credentials. |
| **PERFORMANCE** | Unauthenticated requests trigger unnecessary Tenant Manager API round-trips (~50ms+ each). At scale, this adds significant latency and load to the Tenant Manager service. |
| **DoS VECTOR** | Attackers can flood the Tenant Manager API with crafted tokens containing valid-looking `tenantId` claims. Since tenant resolution happens before auth rejects the token, every malicious request costs a TM API call. |

### The WRONG Pattern (Anti-Pattern)

```go
// ❌ WRONG: Tenant middleware runs before auth on ALL routes
app.Use(tenantMid.WithTenantDB)  // Runs first — calls TM API before auth validates JWT
app.Post("/v1/resources", auth.Authorize("app", "resource", "post"), handler.Create)
```

In this pattern, `WithTenantDB` executes for **every request** before `auth.Authorize` validates the JWT. A request with a forged JWT containing `tenantId: "victim-tenant"` triggers a full Tenant Manager resolution — fetching credentials, opening connections — before auth rejects it.

### The CORRECT Pattern: WhenEnabled

**MUST use `WhenEnabled` — a simple helper function that each project implements locally — to conditionally apply tenant middleware per-route.** Auth is listed before `WhenEnabled` in the handler chain, guaranteeing auth runs first. Tenant resolution runs only for authenticated requests.

**`WhenEnabled` implementation (each project implements this locally):**

```go
// WhenEnabled is a helper that conditionally applies a middleware if it's not nil.
// When multi-tenant is disabled, the middleware passed is nil and WhenEnabled calls c.Next().
func WhenEnabled(middleware fiber.Handler) fiber.Handler {
    return func(c *fiber.Ctx) error {
        if middleware == nil {
            return c.Next()
        }

        return middleware(c)
    }
}
```

**Route registration:**

```go
// ✅ CORRECT: Auth validates JWT FIRST, then tenant resolves DB
// ttHandler is nil when MULTI_TENANT_ENABLED=false (single-tenant passthrough)
f.Post("/v1/resources", auth.Authorize("app", "resource", "post"), WhenEnabled(ttHandler), handler.Create)
f.Get("/v1/resources", auth.Authorize("app", "resource", "get"), WhenEnabled(ttHandler), handler.GetAll)
f.Get("/v1/resources/:id", auth.Authorize("app", "resource", "get"), WhenEnabled(ttHandler), handler.GetByID)
```

**How it works:**
1. `auth.Authorize(...)` is the first handler — validates JWT before anything else
2. `WhenEnabled(ttHandler)` runs second — if `ttHandler` is nil (single-tenant mode), it calls `c.Next()` immediately; if non-nil, it executes the tenant middleware
3. The business handler runs last
4. If auth rejects the request, tenant middleware never runs — no TM API call
5. If `MULTI_TENANT_ENABLED=false`, `ttHandler` is nil and `WhenEnabled` is a no-op — zero overhead

### Detection Commands (MANDATORY)

```bash
# MANDATORY: Run before every PR in multi-tenant services
# Check for global tenant middleware registration (anti-pattern)
grep -rn "app\.Use(.*WithTenantDB\|app\.Use(.*tenantMid" internal/ --include="*.go"
# Expected: 0 matches. Tenant middleware MUST NOT be registered globally.

# Check for correct per-route composition: auth.Authorize BEFORE WhenEnabled on same route
grep -rnE '^\s*(app|f)\.(Get|Post|Put|Patch|Delete)\(.*auth\.Authorize\(.*WhenEnabled\(' internal/ --include="*.go"
# Expected: 1+ matches in routes.go — auth appears before WhenEnabled on protected routes.

```

### Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Auth middleware is already global, so order doesn't matter" | Global middleware ordering is implicit and fragile — a refactor can silently break it. Different routes may need different auth handlers. | **MUST use explicit per-route composition: `auth, WhenEnabled(tenant), handler`** |
| "Tenant resolution is fast, no harm running it first" | TM API calls are network round-trips (~50ms+). At scale, unauthorized traffic amplifies cost. Every unauthenticated request wastes a TM API call. | **MUST authenticate before any TM API call** |
| "We'll just register auth middleware before tenant in app.Use()" | Global ordering provides no guarantee per-route. Different routes may need different auth handlers. A single `app.Use()` reorder silently breaks security for all routes. | **MUST compose auth+tenant per-route using WhenEnabled** |
| "Only internal services call this endpoint, no DoS risk" | Internal networks are not trusted by default. Compromised services, misconfigured proxies, or lateral movement can generate unauthorized traffic. | **MUST enforce auth-before-tenant regardless of network topology** |
| "We already validate tokens at the API gateway" | Defense in depth. Gateway validation can be bypassed, misconfigured, or removed. Service-level auth is the last line of defense. | **MUST validate auth at service level before tenant resolution** |

---

## Multi-Tenant Message Queue Consumers

### When to Use

**CONDITIONAL:** Only applies if your service:
- Processes messages from a message broker (RabbitMQ, SQS, etc.)
- Uses per-tenant message isolation (dedicated vhosts or queues per tenant)
- Has 10+ tenants where startup time is a concern

**If single-tenant or <10 tenants:** Multi-tenant mode overhead may be unnecessary. Consider single-tenant architecture.

---

### Problem: Startup Time Scales with Tenant Count

In multi-tenant services consuming messages, connecting to ALL tenant vhosts at startup causes:

```
Startup Time = N tenants × 500ms per connection
10 tenants  = 5 seconds
100 tenants = 50 seconds  ← Unacceptable for autoscaling/deployments
```

**Symptoms:**
- Slow deployments (rolling updates wait for each pod to connect)
- Poor autoscaling responsiveness (new pods take 30-60s to become ready)
- Wasted resources (connections to inactive tenants)

---

### Solution: On-Demand Consumer Initialization

**Pattern:** Decouple tenant discovery from consumer connection.

```
Startup (MultiTenantConsumer.Run):
  1. Discover tenant list (Redis/API) - lightweight, <1s
  2. Track discovered tenants in memory (knownTenants map)
  3. Start background sync loop (periodic re-discovery)
  4. Return immediately (startup complete)

On-Demand Consumer Spawn (internal):
  1. Background sync discovers new tenant
  2. Calls EnsureConsumerStarted(ctx, tenantID) internally
  3. Consumer spawns on-demand (first time: ~500ms)
  4. Connection cached for reuse
  5. Subsequent calls: fast path (<1ms)
```

**Result:** Startup time O(1) regardless of tenant count, resources scale with active tenants only.

---

### Architecture Components

#### 1. Tenant Discovery Service

**Responsibility:** Provide list of active tenants without connection overhead.

**Implementation:**
- **Primary:** Cache (Redis SET: `dispatch layer:tenants:active`)
- **Fallback:** HTTP API (`GET /tenants/active?service={serviceName}`)

**Response format (API):**
```json
[
  {"id": "tenant-001", "name": "Tenant A", "status": "active"},
  {"id": "tenant-002", "name": "Tenant B", "status": "active"}
]
```

**Endpoint characteristics:**
- Returns minimal info (id, name, status only)
- Supports optional filtering by service (query param: `?service={serviceName}`)

#### 2. Consumer Manager (lib-commons)

**Responsibility:** Manage lifecycle of message consumers across tenants with on-demand initialization.

**Key methods:**
```go
type MultiTenantConsumer struct {
    mu sync.RWMutex                      // Protects knownTenants and activeTenants maps
    knownTenants map[string]bool        // Discovered tenants
    activeTenants map[string]CancelFunc // Running consumers
    consumerLocks sync.Map               // Per-tenant mutexes
    retryState sync.Map                  // Failure tracking
}

// Discover tenants without connecting (non-blocking, <1s)
func (c *MultiTenantConsumer) Run(ctx context.Context) error

// Ensure consumer is active for tenant (idempotent, thread-safe, fire-and-forget)
func (c *MultiTenantConsumer) EnsureConsumerStarted(ctx context.Context, tenantID string)

// Stop consumer goroutine and clean up all state for a tenant.
// Cancels context, removes from activeTenants/knownTenants/retryState/consumerLocks.
// Prevents orphaned retry loops after tenant eviction.
func (c *MultiTenantConsumer) StopConsumer(tenantID string)

// Check if tenant has failed repeatedly
func (c *MultiTenantConsumer) IsDegraded(tenantID string) bool

// Get runtime statistics
func (c *MultiTenantConsumer) Stats() ConsumerStats
```

#### 3. Service Bootstrap Trigger

**Responsibility:** Trigger consumer spawn for tenants during service initialization and via background sync.

**Implementation pattern:**
```go
// In bootstrap/config.go
tmConsumer := consumer.NewMultiTenantConsumer(...)
if err := tmConsumer.Run(ctx); err != nil {
    logger.Errorf("tenant manager startup failed: %v", err)
    // Startup continues - consumer will retry tenant discovery in background
}
```

The `MultiTenantConsumer.Run()` method discovers tenants and starts a background sync loop that spawns consumers for newly discovered tenants. Individual tenant consumers are started on-demand via `EnsureConsumerStarted()` which is called internally by the consumer manager.

---

### Implementation Steps

#### Step 1: Update Shared Library

Implement on-demand consumer initialization in your message queue consumer library:

1. **Add state tracking:**
```go
knownTenants map[string]bool        // Discovered via API/cache
activeTenants map[string]CancelFunc // Actually running
consumerLocks sync.Map               // Prevent duplicate spawns
```

2. **Non-blocking discovery:**
```go
func (c *Consumer) Run(ctx context.Context) error {
    // Discover tenants (timeout: 500ms, soft failure)
    c.discoverTenants(ctx)

    // Start background sync loop (for tenant add/remove)
    go c.runSyncLoop(ctx)

    return nil  // Return immediately
}
```

3. **On-demand spawning with double-check locking:**
```go
func (c *Consumer) EnsureConsumerStarted(ctx context.Context, tenantID string) {
    // Fast path: check if already active (read lock)
    c.mu.RLock()
    if _, exists := c.activeTenants[tenantID]; exists {
        c.mu.RUnlock()
        return  // Already running
    }
    c.mu.RUnlock()

    // Slow path: acquire per-tenant mutex (prevent thundering herd)
    mutex := c.getPerTenantMutex(tenantID)
    mutex.Lock()
    defer mutex.Unlock()

    // Double-check after acquiring lock
    c.mu.RLock()
    if _, exists := c.activeTenants[tenantID]; exists {
        c.mu.RUnlock()
        return  // Another goroutine created it
    }
    c.mu.RUnlock()

    // Spawn consumer (fire-and-forget, errors logged internally)
    c.startTenantConsumer(ctx, tenantID)
}
```

#### Step 2: Add Tenant Discovery Endpoint

In your tenant management service:

```go
// GET /tenants/active?service={serviceName}
func GetActiveTenants(c *fiber.Ctx) error {
    service := c.Query("service")

    // Query active tenants (filter by service if provided)
    tenants, err := repo.ListActiveTenants(service)
    if err != nil {
        return libHTTP.InternalServerError(c, "TENANT_LIST_FAILED", err)
    }

    // Return minimal info (no credentials)
    response := []TenantSummary{}
    for _, t := range tenants {
        response = append(response, TenantSummary{
            ID: t.ID,
            Name: t.Name,
            Status: t.Status,
        })
    }

    return libHTTP.OK(c, response)
}

// Register as PUBLIC endpoint (no auth)
app.Get("/tenants/active", GetActiveTenants)
```

#### Step 3: Wire Consumer in Service Bootstrap

In each service consuming messages:

```go
// In bootstrap/config.go
func InitServers() {
    // Create multi-tenant consumer
    tmConsumer := consumer.NewMultiTenantConsumer(
        consumer.WithPG(pgManager),
        consumer.WithMB(mongoManager),
    )

    // Register message handlers
    tmConsumer.Register("queue-name", handler)

    // Start consumer (discovers tenants, starts background sync)
    if err := tmConsumer.Run(ctx); err != nil {
        logger.Errorf("tenant manager startup failed: %v", err)
        // Note: startup continues - consumer will retry tenant discovery in background
    }
}
```

---

### Failure Resilience Pattern

**Exponential Backoff:**
```go
func backoffDelay(retryCount int) time.Duration {
    delays := []time.Duration{5*time.Second, 10*time.Second, 20*time.Second, 40*time.Second}
    if retryCount >= len(delays) {
        return delays[len(delays)-1]  // Cap at 40s
    }
    return delays[retryCount]
}
```

**Per-Tenant Retry State:**
```go
type retryState struct {
    count    int
    degraded bool  // True after 3 failures
}

retryState sync.Map  // Key: tenantID, Value: *retryState
```

**Degraded Tenant Handling:**
```go
if consumer.IsDegraded(tenantID) {
    logger.Errorf("Tenant %s is degraded (3+ connection failures)", tenantID)
    return errors.New("tenant degraded")
}
```

---

### Observability Pattern

**Enhanced Stats API:**
```go
type ConsumerStats struct {
    ConnectionMode   string   `json:"connectionMode"`    // "on-demand"
    ActiveTenants    int      `json:"activeTenants"`     // Connected
    KnownTenants     int      `json:"knownTenants"`      // Discovered
    PendingTenants   []string `json:"pendingTenants"`    // Known but not active
    DegradedTenants  []string `json:"degradedTenants"`   // Failed 3+ times
}
```

**Structured Logs:**
- `connection_mode=on-demand` at startup
- `on-demand consumer start for tenant: {id}` when spawning
- `connecting to vhost: tenant={id}` when connecting
- `tenant {id} marked degraded` after max retries

---

### Testing Strategy

**Unit Tests:**
- Startup completes in <1s (0, 100, 500 tenants)
- Concurrent EnsureConsumerStarted spawns exactly 1 consumer
- Exponential backoff sequence (5s, 10s, 20s, 40s)
- Degraded tenant detection after 3 failures

**Integration Tests:**
- Discovery fallback (Redis → API)
- On-demand connection with testcontainers
- Tenant removal cleanup (<30s)

---

### When to Use Multi-Tenant Consumer

| Scenario | Recommended | Rationale |
|----------|-------------|-----------|
| **10+ tenants** | ✅ Yes | Startup time becomes significant with many tenants |
| **<10 tenants** | ⚠️ Consider | Overhead may not justify complexity |
| **Most tenants inactive** | ✅ Yes | Resources scale with active count only |
| **All tenants active** | ✅ Yes | Still faster startup, resources scale proportionally |
| **Frequent deployments** | ✅ Yes | Fast startup critical for CI/CD velocity |
| **Latency-sensitive** | ✅ Yes* | *First request per tenant: +500ms (acceptable trade-off) |

---

### Cache Invalidation (MANDATORY)

The pmClient (dispatch layer HTTP client) has an internal HTTP response cache (1h TTL). When a tenant is added or removed, the cache MUST be invalidated via `tenantClient.InvalidateConfig(ctx, tenantID, serviceName)` to prevent:

- **On add:** stale 404 or partial responses from before provisioning completed
- **On remove:** stale 200 responses allowing evicted tenants to reconnect and re-establish infrastructure

Invalidation happens in BOTH callbacks:

| Callback | When to Invalidate | Why |
|----------|-------------------|-----|
| `OnTenantAdded` | **Before** `EnsureConsumerStarted` | Consumer needs fresh config to connect to newly provisioned vhost |
| `OnTenantRemoved` | **After** closing connections | Stale cached 200 would let evicted tenant pass middleware and trigger lazy-load reconnection |

```go
// InvalidateConfig signature
func (c *TenantClient) InvalidateConfig(ctx context.Context, tenantID, serviceName string) error
```

**Without invalidation:** A removed tenant's cached config (200 OK) survives for up to 1 hour, during which any HTTP request for that tenant passes middleware validation, triggers lazy-load, and re-establishes all infrastructure connections — effectively undoing the eviction.

### Common Pitfalls

**❌ Don't:** Start consumers in discovery loop (defeats on-demand purpose)
**✅ Do:** Populate knownTenants only, defer connection to trigger

**❌ Don't:** Use global mutex for all tenants (contention)
**✅ Do:** Per-tenant mutex via sync.Map (fine-grained locking)

**❌ Don't:** Fail HTTP request if consumer spawn fails
**✅ Do:** Log warning, let background sync retry

**❌ Don't:** Forget to cleanup on tenant removal
**✅ Do:** Call `StopConsumer` first, then close connections, then invalidate cache

**❌ Don't:** Retry indefinitely on connection failure
**✅ Do:** Mark degraded after 3 failures, stop retrying

**❌ Don't:** Skip cache invalidation on tenant add/remove
**✅ Do:** Call `tenantClient.InvalidateConfig` in both `OnTenantAdded` and `OnTenantRemoved`

**❌ Don't:** Close connections before stopping consumer (causes retry storms)
**✅ Do:** Stop consumer goroutine FIRST, then close infrastructure connections

---

### Single-Tenant vs Multi-Tenant Mode

```go
// Support both single-tenant and multi-tenant deployments
if !config.MultiTenantEnabled {
    // Single-tenant: static RabbitMQ connection (no tenant isolation)
    consumer = initSingleTenantConsumer(...)
} else {
    // Multi-tenant: per-tenant vhosts with on-demand initialization
    consumer = initMultiTenantConsumer(...)
}
```

**Note:** Single-tenant uses a different consumer implementation without tenant isolation. Multi-tenant consumers use on-demand initialization for optimal startup performance.

---

## M2M Credentials via Secret Manager

**CONDITIONAL:** Only implement if the service has **targetServices** declared (i.e., it calls other service APIs per tenant). Any service — plugin or product — that has targetServices needs M2M credential retrieval.

### When This Applies

| Service Type | `MULTI_TENANT_ENABLED` | Needs M2M? | Reason |
|-------------|------------------------|------------|--------|
| Any service **with** `targetServices` | `true` | ✅ YES | Service must authenticate with target service APIs per tenant |
| Any service **with** `targetServices` | `false` | ❌ NO | Single-tenant — service uses existing static auth, no Secrets Manager calls |
| Any service **without** `targetServices` | any | ❌ NO | No cross-service API calls requiring per-tenant credentials |

**⛔ Backward Compatibility:** When `MULTI_TENANT_ENABLED=false` (the default), the service MUST continue working with its existing authentication mechanism — no AWS Secrets Manager calls, no M2M credential fetching. The Secret Manager path is activated **only** when multi-tenant mode is enabled. This follows the same conditional pattern as all other dispatch layer resources (PostgreSQL, MongoDB, Redis, S3, RabbitMQ).

### How It Works

When `MULTI_TENANT_ENABLED=true`, each tenant has its own M2M credentials stored in **AWS Secrets Manager**. When a service needs to call a target service API (e.g., ledger, plugin-fees), it must:

1. Extract `tenantOrgID` from the JWT context (already available via tenant middleware)
2. Call `secretsmanager.GetM2MCredentials()` to fetch `clientId` + `clientSecret` for that tenant
3. Pass the credentials to the existing Plugin Access Manager integration (which handles JWT acquisition)

**Note:** The service already handles JWT token acquisition via Plugin Access Manager. This section only covers **how to retrieve M2M credentials** from AWS Secrets Manager — not how to exchange them for tokens.

### Required lib-commons Package

```go
import (
    secretsmanager "github.com/LerianStudio/lib-commons/v4/commons/secretsmanager"
)
```

### Secret Path Convention

Credentials are stored in AWS Secrets Manager following this path:

```
tenants/{env}/{tenantOrgID}/{applicationName}/m2m/{targetService}/credentials
```

| Segment | Source | Example |
|---------|--------|---------|
| `env` | `ENV_NAME` env var | `staging`, `production` |
| `tenantOrgID` | JWT `owner` claim via `auth.GetTenantID(ctx)` | `org_01KHVKQQP6D2N4RDJK0ADEKQX1` |
| `applicationName` | Service's own name constant | `plugin-pix`, `midaz`, `ledger` |
| `targetService` | The target service being called | `ledger`, `midaz`, `plugin-fees` |

### Environment Variables (M2M)

In addition to the 13 canonical multi-tenant env vars, plugins MUST add:

| Env Var | Description | Default | Required |
|---------|-------------|---------|----------|
| `AWS_REGION` | AWS region for Secrets Manager | - | Yes (for services with targetServices) |
| `M2M_TARGET_SERVICE` | Target service name | - | Yes (for services with targetServices) |

### Implementation Pattern

#### 1. Fetching M2M Credentials

```go
package m2m

import (
    "context"
    "fmt"

    awsconfig "github.com/aws/aws-sdk-go-v2/config"
    awssm "github.com/aws/aws-sdk-go-v2/service/secretsmanager"
    secretsmanager "github.com/LerianStudio/lib-commons/v4/commons/secretsmanager"
)

// FetchCredentials retrieves M2M credentials from AWS Secrets Manager for a specific tenant.
func FetchCredentials(ctx context.Context, env, tenantOrgID, applicationName, targetService string) (*secretsmanager.M2MCredentials, error) {
    cfg, err := awsconfig.LoadDefaultConfig(ctx)
    if err != nil {
        return nil, fmt.Errorf("loading AWS config: %w", err)
    }

    client := awssm.NewFromConfig(cfg)

    creds, err := secretsmanager.GetM2MCredentials(ctx, client, env, tenantOrgID, applicationName, targetService)
    if err != nil {
        return nil, fmt.Errorf("fetching M2M credentials for tenant %s: %w", tenantOrgID, err)
    }

    return creds, nil
}
```

#### 2. Credential Caching (MANDATORY)

**MUST cache credentials using a two-level cache architecture.** Hitting AWS Secrets Manager on every request is expensive and adds latency.

##### Cache Architecture

| Level | Store | TTL | Purpose |
|-------|-------|-----|---------|
| L1 | In-memory (`sync.Map`) | Fixed 30s | Fast path, avoids Redis round-trip per request |
| L2 | Redis/Valkey (distributed) | Service-defined (e.g., 300s) | Source of truth, shared across all pods |

**Fallback:** If Redis is not available (dev, single-tenant), in-memory becomes the only level (current behavior preserved). Mode is auto-detected — no configuration needed.

##### Redis Key Structure

```
tenant:{tenantOrgID}:m2m:{targetService}:credentials
```

Key prefixing uses `valkey.GetKeyContext(ctx, baseKey)` from lib-commons, which automatically applies the tenant prefix (e.g., `tenant:{tenantId}:m2m:{targetService}:credentials`). This is the same pattern used by all other Redis operations in the codebase.

##### Cache-Bust on Auth Failure (401)

When the token exchange (`client_credentials` grant) returns 401:
1. Delete the entry from L2 (Redis) — propagates to all pods
2. Delete the entry from L1 (local) — immediate effect on current pod
3. Re-fetch from AWS Secrets Manager on next request

This eliminates the up-to-5-minute window of using revoked credentials across pods.

##### Implementation

```go
package m2m

import (
    "context"
    "encoding/json"
    "fmt"
    "sync"
    "time"

    libRedis "github.com/LerianStudio/lib-commons/v4/commons/redis"
    secretsmanager "github.com/LerianStudio/lib-commons/v4/commons/secretsmanager"
    "github.com/LerianStudio/lib-commons/v4/commons/dispatch layer/valkey"
)

// l1CacheTTL is a fixed internal constant — not configurable via env var.
const l1CacheTTL = 30 * time.Second

type cachedCredentials struct {
    creds     *secretsmanager.M2MCredentials
    expiresAt time.Time
}

// M2MCredentialProvider handles per-tenant M2M credential retrieval with two-level caching.
// L1 (in-memory) provides fast path; L2 (Redis/Valkey via lib-commons) provides cross-pod consistency.
// Token acquisition is handled by Plugin Access Manager — this only provides credentials.
type M2MCredentialProvider struct {
    smClient        secretsmanager.SecretsManagerClient
    env             string
    applicationName string
    targetService   string
    credCacheTTL    time.Duration // L2 TTL (service-defined)

    credCache sync.Map // L1: map[tenantOrgID]*cachedCredentials

    // L2: lib-commons Redis connection (nil = local-only mode)
    redisConn *libRedis.Connection
}

// NewM2MCredentialProvider creates a credential provider with two-level cache.
// Pass nil for redisConn to use local-only mode (single-tenant or dev).
func NewM2MCredentialProvider(
    smClient secretsmanager.SecretsManagerClient,
    env, applicationName, targetService string,
    credCacheTTL time.Duration,
    redisConn *libRedis.Connection,
) *M2MCredentialProvider {
    return &M2MCredentialProvider{
        smClient:        smClient,
        env:             env,
        applicationName: applicationName,
        targetService:   targetService,
        credCacheTTL:    credCacheTTL,
        redisConn:       redisConn,
    }
}

// m2mRedisKey returns the tenant-prefixed Redis key for M2M credentials.
// Uses valkey.GetKeyContext when ctx has tenant info, otherwise builds manually.
func (p *M2MCredentialProvider) m2mRedisKey(ctx context.Context, tenantOrgID string) string {
    baseKey := fmt.Sprintf("m2m:%s:credentials", p.targetService)
    // Use valkey.GetKeyContext to apply tenant prefix consistently
    return valkey.GetKeyContext(ctx, baseKey)
}

// GetCredentials returns M2M credentials for the given tenant using two-level cache.
// Lookup order: L1 (memory) → L2 (Redis via lib-commons) → AWS Secrets Manager.
// The caller (Plugin Access Manager integration) handles token acquisition.
func (p *M2MCredentialProvider) GetCredentials(ctx context.Context, tenantOrgID string) (*secretsmanager.M2MCredentials, error) {
    // L1: Check in-memory cache (fast path)
    if cached, ok := p.credCache.Load(tenantOrgID); ok {
        cc := cached.(*cachedCredentials)
        if time.Now().Before(cc.expiresAt) {
            return cc.creds, nil
        }
    }

    // L2: Check distributed cache (Redis/Valkey via lib-commons)
    if p.redisConn != nil {
        rds, err := p.redisConn.GetConnection(ctx)
        if err == nil {
            key := p.m2mRedisKey(ctx, tenantOrgID)
            val, err := rds.Get(ctx, key).Bytes()
            if err == nil {
                var creds secretsmanager.M2MCredentials
                if json.Unmarshal(val, &creds) == nil {
                    // Populate L1 with short TTL
                    p.credCache.Store(tenantOrgID, &cachedCredentials{
                        creds:     &creds,
                        expiresAt: time.Now().Add(l1CacheTTL),
                    })
                    return &creds, nil
                }
            }
        }
    }

    // Source: Fetch from AWS Secrets Manager (authoritative source)
    creds, err := secretsmanager.GetM2MCredentials(ctx, p.smClient, p.env, tenantOrgID, p.applicationName, p.targetService)
    if err != nil {
        return nil, fmt.Errorf("fetching M2M credentials for tenant %s: %w", tenantOrgID, err)
    }

    // Store in L2 (distributed via lib-commons)
    if p.redisConn != nil {
        if rds, err := p.redisConn.GetConnection(ctx); err == nil {
            key := p.m2mRedisKey(ctx, tenantOrgID)
            if data, err := json.Marshal(creds); err == nil {
                _ = rds.Set(ctx, key, data, p.credCacheTTL).Err()
            }
        }
    }

    // Store in L1 (local)
    p.credCache.Store(tenantOrgID, &cachedCredentials{
        creds:     creds,
        expiresAt: time.Now().Add(l1CacheTTL),
    })

    return creds, nil
}

// InvalidateCredentials removes cached credentials for a tenant from both cache levels.
// Call this when a 401 is received during token exchange (credential revocation).
func (p *M2MCredentialProvider) InvalidateCredentials(ctx context.Context, tenantOrgID string) {
    // Delete from L1 (local — immediate effect)
    p.credCache.Delete(tenantOrgID)

    // Delete from L2 (distributed — propagates to all pods via lib-commons)
    if p.redisConn != nil {
        if rds, err := p.redisConn.GetConnection(ctx); err == nil {
            key := p.m2mRedisKey(ctx, tenantOrgID)
            _ = rds.Del(ctx, key).Err()
        }
    }
}
```

#### 3. Single-Tenant vs Multi-Tenant: Conditional Flow

This is the core pattern. The service MUST work in both modes — the `M2MCredentialProvider` is **nil** in single-tenant mode.

**Few-shot 1 — Bootstrap wiring (picks the right path at startup):**

```go
// In bootstrap/config.go or bootstrap/dependencies.go

var m2mProvider *m2m.M2MCredentialProvider // nil = single-tenant mode

if cfg.MultiTenantEnabled {
    // MULTI-TENANT: create credential provider that fetches from AWS Secrets Manager
    awsCfg, err := awsconfig.LoadDefaultConfig(ctx)
    if err != nil {
        return nil, fmt.Errorf("failed to load AWS config for M2M: %w", err)
    }
    smClient := awssm.NewFromConfig(awsCfg)

    m2mProvider = m2m.NewM2MCredentialProvider(
        smClient,
        cfg.EnvName,
        constant.ApplicationName,
        cfg.M2MTargetService,
        time.Duration(cfg.M2MCredentialCacheTTLSec) * time.Second,
    )
}
// SINGLE-TENANT: m2mProvider stays nil — no AWS calls, no Secret Manager

// Both modes use the same client — it checks internally if m2mProvider is nil
productClient := product.NewClient(cfg.ProductURL, m2mProvider)
```

**Few-shot 2 — Product client (handles both modes transparently):**

```go
// internal/adapters/product/client.go

type Client struct {
    baseURL     string
    m2mProvider *m2m.M2MCredentialProvider // nil in single-tenant mode
    httpClient  *http.Client
}

func NewClient(baseURL string, m2mProvider *m2m.M2MCredentialProvider) *Client {
    return &Client{
        baseURL:     baseURL,
        m2mProvider: m2mProvider,
        httpClient:  &http.Client{Timeout: 30 * time.Second},
    }
}

func (c *Client) CreateTransaction(ctx context.Context, input TransactionInput) (*TransactionOutput, error) {
    req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.baseURL+"/v1/transactions", marshal(input))
    if err != nil {
        return nil, err
    }

    if c.m2mProvider != nil {
        // MULTI-TENANT: fetch per-tenant credentials from Secret Manager
        tenantOrgID := auth.GetTenantID(ctx)
        creds, err := c.m2mProvider.GetCredentials(ctx, tenantOrgID)
        if err != nil {
            return nil, fmt.Errorf("fetching M2M credentials for tenant %s: %w", tenantOrgID, err)
        }
        req.SetBasicAuth(creds.ClientID, creds.ClientSecret)
    }
    // SINGLE-TENANT: no credentials injected — plugin uses existing auth
    // (e.g., static token from env var, already set in headers by middleware, etc.)

    resp, err := c.httpClient.Do(req)
    if err != nil {
        return nil, fmt.Errorf("calling product API: %w", err)
    }
    defer resp.Body.Close()

    // ... handle response
}
```

**Few-shot 3 — Service layer (no branching needed, client handles it):**

```go
func (uc *ProcessPaymentUseCase) Execute(ctx context.Context, input PaymentInput) error {
    // Works in both modes:
    // - Single-tenant: client calls product API with existing static auth
    // - Multi-tenant: client fetches per-tenant creds from Secret Manager first
    resp, err := uc.ledgerClient.CreateTransaction(ctx, input.Transaction)
    if err != nil {
        return fmt.Errorf("creating transaction in ledger: %w", err)
    }

    return nil
}
```

**The pattern:** The conditional logic lives in the **client/adapter layer**, not in the service/use-case layer. The service layer calls the same method regardless of mode — it doesn't know or care whether credentials came from Secret Manager or static config.

### Error Handling

The `secretsmanager` package provides sentinel errors for precise error handling:

```go
import (
    "errors"
    secretsmanager "github.com/LerianStudio/lib-commons/v4/commons/secretsmanager"
)

creds, err := secretsmanager.GetM2MCredentials(ctx, client, env, tenantOrgID, appName, target)
if err != nil {
    switch {
    case errors.Is(err, secretsmanager.ErrM2MCredentialsNotFound):
        // Tenant not provisioned yet — return 503 or queue for retry
    case errors.Is(err, secretsmanager.ErrM2MVaultAccessDenied):
        // IAM permissions missing or token expired — alert ops
    case errors.Is(err, secretsmanager.ErrM2MInvalidCredentials):
        // Secret exists but clientId/clientSecret missing — alert ops
    default:
        // Infrastructure error — retry with backoff
    }
}
```

### AWS IAM Permissions

The plugin's IAM role (or ECS task role / EKS service account) MUST have permission to read the tenant secrets. Minimal policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "arn:aws:secretsmanager:*:*:secret:tenants/*/m2m/*/credentials-*"
    }
  ]
}
```

For tighter scoping, replace wildcards with specific values:

| Wildcard | Scoped Example |
|----------|---------------|
| First `*` (env) | `production` or `staging` |
| Second `*` (target) | `ledger` or `midaz` |
| Trailing `-*` | Required — AWS appends a random suffix to secret ARNs |

**MUST NOT** grant `secretsmanager:*` — only `GetSecretValue` is needed.

### Testing Guidance

The `secretsmanager.SecretsManagerClient` is an interface, so it can be mocked in unit tests without hitting AWS.

#### Mocking the client

```go
type mockSMClient struct {
    getSecretValueFunc func(ctx context.Context, input *awssm.GetSecretValueInput, opts ...func(*awssm.Options)) (*awssm.GetSecretValueOutput, error)
}

func (m *mockSMClient) GetSecretValue(ctx context.Context, input *awssm.GetSecretValueInput, opts ...func(*awssm.Options)) (*awssm.GetSecretValueOutput, error) {
    return m.getSecretValueFunc(ctx, input, opts...)
}
```

#### Testing credential cache TTL

```go
func TestCredentialCacheExpiry(t *testing.T) {
    callCount := 0
    mock := &mockSMClient{
        getSecretValueFunc: func(_ context.Context, _ *awssm.GetSecretValueInput, _ ...func(*awssm.Options)) (*awssm.GetSecretValueOutput, error) {
            callCount++
            secret := `{"clientId":"id","clientSecret":"secret"}`
            return &awssm.GetSecretValueOutput{SecretString: &secret}, nil
        },
    }

    provider := NewM2MCredentialProvider(mock, "test", "plugin-pix", "ledger", 1*time.Second)

    // First call — fetches from AWS
    _, err := provider.GetCredentials(context.Background(), "tenant-1")
    require.NoError(t, err)
    assert.Equal(t, 1, callCount)

    // Second call — served from cache
    _, err = provider.GetCredentials(context.Background(), "tenant-1")
    require.NoError(t, err)
    assert.Equal(t, 1, callCount) // still 1

    // Wait for cache expiry
    time.Sleep(1100 * time.Millisecond)

    // Third call — cache expired, fetches again
    _, err = provider.GetCredentials(context.Background(), "tenant-1")
    require.NoError(t, err)
    assert.Equal(t, 2, callCount)
}
```

#### Testing error scenarios

Test each sentinel error path (`ErrM2MCredentialsNotFound`, `ErrM2MVaultAccessDenied`, `ErrM2MInvalidCredentials`) by returning the corresponding error from the mock.

### Observability & Metrics (MANDATORY)

Instrument `M2MCredentialProvider` to track credential retrieval health. These 6 metrics are **mandatory** — without them, diagnosing per-tenant M2M issues in production is not feasible.

| Metric | Type | Where to Increment | Description |
|--------|------|-------------------|-------------|
| `m2m_credential_l1_cache_hits` | Counter | `GetCredentials` — L1 (memory) hit | Credential served from in-memory cache |
| `m2m_credential_l2_cache_hits` | Counter | `GetCredentials` — L2 (Redis) hit | Credential served from distributed cache |
| `m2m_credential_cache_misses` | Counter | `GetCredentials` — both L1 and L2 miss | Full miss, fetching from AWS Secrets Manager |
| `m2m_credential_fetch_errors` | Counter | `GetCredentials` — error return | AWS Secrets Manager call failed |
| `m2m_credential_fetch_duration_seconds` | Histogram | `GetCredentials` — around `GetM2MCredentials` call | Latency of AWS Secrets Manager requests |
| `m2m_credential_invalidations` | Counter | `InvalidateCredentials` — on 401 | Credential cache-bust triggered by auth failure |

Labels: `tenant_org_id`, `target_service`, `environment`.

**MUST NOT** include `clientId` or `clientSecret` in metric labels or log fields.

### Security Considerations

1. **MUST NOT log credentials** — never log `clientId` or `clientSecret` values
2. **MUST NOT store credentials in environment variables** — always fetch from Secrets Manager at runtime
3. **MUST use two-level cache** — L1 (in-memory) for fast path, L2 (Redis) for cross-pod consistency
4. **MUST handle credential rotation** — cache TTL ensures stale credentials are refreshed automatically
5. **MUST invalidate on 401** — call `InvalidateCredentials()` when token exchange returns 401 to propagate cache-bust across all pods

### Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "This service doesn't need M2M" | Correct if it has no targetServices declared. | **Skip this gate for services without targetServices** |
| "We can hardcode credentials per tenant" | Hardcoded creds don't scale and are a security risk. | **MUST use Secrets Manager** |
| "Caching is optional, we'll add it later" | Every request hitting AWS adds ~50-100ms latency + cost. | **MUST implement caching from day one** |
| "We'll use env vars for client credentials" | Env vars are shared across tenants. M2M is per-tenant. | **MUST use Secrets Manager per tenant** |
| "Single-tenant plugins don't need this" | Correct if MULTI_TENANT_ENABLED=false. | **Skip when single-tenant** |
| "In-memory cache is good enough" | In-memory cache is per-pod — credential rotation or revocation won't propagate to other pods for up to 5 minutes. | **MUST use distributed cache (Redis) as L2** |
| "Cache-bust on 401 is overkill" | Without it, revoked credentials remain cached for the full TTL, causing repeated auth failures across pods. | **MUST invalidate on 401** |

---

## Service Authentication (MANDATORY)

Consumer services that call the Tenant Manager `/settings` endpoint MUST authenticate using an API key sent via the `X-API-Key` HTTP header. Without this header, the Tenant Manager rejects requests to protected endpoints.

### How It Works

1. **Key generation:** API keys are generated per-service via the service catalog endpoint `POST /services/:name/api-keys`.
2. **Key limit:** Maximum 2 keys per environment per service, enabling zero-downtime rotation (create new key, roll out, revoke old key).
3. **Header injection:** The lib-commons Tenant Manager HTTP client sends the `X-API-Key` header automatically when configured with `client.WithServiceAPIKey()`.
4. **Consumer configuration:** Consumer services set the `MULTI_TENANT_SERVICE_API_KEY` environment variable. The bootstrap code passes it to the client via `WithServiceAPIKey`.

### Configuration

Add `MULTI_TENANT_SERVICE_API_KEY` to the Config struct (see [Environment Variables](#environment-variables)):

```go
MultiTenantServiceAPIKey string `env:"MULTI_TENANT_SERVICE_API_KEY"`
```

Wire it when creating the Tenant Manager HTTP client:

```go
clientOpts = append(clientOpts,
    client.WithServiceAPIKey(cfg.MultiTenantServiceAPIKey),
)
tmClient, err := client.NewClient(cfg.MultiTenantURL, logger, clientOpts...)
if err != nil {
    return fmt.Errorf("creating dispatch layer client: %w", err)
}
```

> **Fail-fast:** `NewClient` returns `core.ErrServiceAPIKeyRequired` if the API key is empty. The service refuses to start with a clear error instead of failing with runtime 401 errors on `/settings` calls.

### Key Rotation

Zero-downtime rotation flow:

1. Generate a new API key: `POST /services/:name/api-keys`
2. Deploy the new key to the consumer service (`MULTI_TENANT_SERVICE_API_KEY`)
3. Verify the service authenticates successfully with the new key
4. Revoke the old key: `DELETE /services/:name/api-keys/:keyId`

The service catalog enforces a maximum of 2 active keys per environment, so both old and new keys work simultaneously during the rollout window.

### Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "We don't need API key auth for internal services" | The `/settings` endpoint returns database credentials. Unauthenticated access is a security risk. | **MUST configure `WithServiceAPIKey`** |
| "We'll add the API key later" | Without authentication, the Tenant Manager rejects `/settings` requests. The service cannot resolve tenant connections. | **MUST configure before enabling multi-tenant** |
| "We can use a shared API key across services" | Each service MUST have its own API key for audit trail and independent revocation. | **MUST generate per-service keys via service catalog** |