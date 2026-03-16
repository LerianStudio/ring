# Go Standards

This file defines the specific standards for Go development at Lerian Studio.

> **Project Rules**: Check if `docs/PROJECT_RULES.md` exists in the target project. If it exists, load it for project-specific technology choices and configurations. If it doesn't exist, ask the user: "Would you like me to create a PROJECT_RULES.md file using the Ring template? This helps document your project's specific tech stack, integrations, and deployment model."

---

## Table of Contents

| # | Section | Description |
|---|---------|-------------|
| 1 | [Version](#version) | Go version requirements |
| 2 | [Core Dependency: lib-commons](#core-dependency-lib-commons-mandatory) | Required foundation library (v4) |
| 3 | [Frameworks & Libraries](#frameworks--libraries) | Required packages and versions |
| 4 | [Configuration](#configuration) | Environment variable handling (nested structs) |
| 5 | [Observability](#observability) | OpenTelemetry integration |
| 6 | [Bootstrap](#bootstrap) | Application initialization (v4 patterns) |
| 7 | [Access Manager Integration](#access-manager-integration-mandatory) | Authentication and authorization with lib-auth |
| 8 | [License Manager Integration](#license-manager-integration-mandatory) | License validation with lib-license-go |
| 9 | [Data Transformation](#data-transformation-toentityfromentity-mandatory) | ToEntity/FromEntity patterns |
| 10 | [Error Codes Convention](#error-codes-convention-mandatory) | Service-prefixed error codes |
| 11 | [Error Handling](#error-handling) | Error wrapping and checking |
| 12 | [Function Design](#function-design-mandatory) | Single responsibility principle |
| 13 | [Pagination Patterns](#pagination-patterns) | Cursor and page-based pagination |
| 14 | [Testing](#testing) | Table-driven tests, edge cases |
| 15 | [Logging](#logging) | Structured logging with lib-commons v4 |
| 16 | [Linting](#linting) | golangci-lint configuration |
| 17 | [Architecture Patterns](#architecture-patterns) | Hexagonal architecture |
| 18 | [Directory Structure](#directory-structure) | Project layout (Lerian pattern) |
| 19 | [Concurrency Patterns](#concurrency-patterns) | Goroutines, channels, errgroup |
| 20 | [RabbitMQ Worker Pattern](#rabbitmq-worker-pattern) | Async message processing |
| 21 | [Safe Goroutines (cruntime)](#safe-goroutines-cruntime) | Safe goroutine management with panic recovery |
| 22 | [Assertions (cassert)](#assertions-cassert) | Domain validation (returns errors, never panics) |
| 23 | [Typed Metrics (cmetrics)](#typed-metrics-cmetrics) | Counter, Histogram metric definitions |
| 24 | [Safe Math (commons/safe)](#safe-math-commonssafe) | Panic-free financial calculations |
| 25 | [Crypto (commons/crypto)](#crypto-commonscrypto) | AES-GCM encryption, HMAC-SHA256 hashing |
| 26 | [Backoff (commons/backoff)](#backoff-commonsbackoff) | Exponential backoff with jitter |
| 27 | [Circuit Breaker](#circuit-breaker-mandatory-for-external-calls) | Circuit breakers for external service calls |
| 28 | [Outbox Pattern (commons/outbox)](#outbox-pattern-commonsoutbox) | Reliable event publishing |

**Meta-sections (not checked by agents):**
- [Standards Compliance Output Format](#standards-compliance-output-format) - Report format for ring:dev-refactor
- [Checklist](#checklist) - Self-verification before submitting code

---

## Version

- **Minimum**: Go 1.24
- **Recommended**: Latest stable release

---

## Core Dependency: lib-commons (MANDATORY)

All Lerian Studio Go projects **MUST** use `lib-commons/v4` as the foundation library. This ensures consistency across all services.

### Required Import (lib-commons v4)

```go
import (
    libCommons "github.com/LerianStudio/lib-commons/v4/commons"
    clog "github.com/LerianStudio/lib-commons/v4/commons/log"
    czap "github.com/LerianStudio/lib-commons/v4/commons/zap"
    cassert "github.com/LerianStudio/lib-commons/v4/commons/assert"
    cruntime "github.com/LerianStudio/lib-commons/v4/commons/runtime"
    cotel "github.com/LerianStudio/lib-commons/v4/commons/opentelemetry"
    cmetrics "github.com/LerianStudio/lib-commons/v4/commons/opentelemetry/metrics"
    chttp "github.com/LerianStudio/lib-commons/v4/commons/net/http"
    cpostgres "github.com/LerianStudio/lib-commons/v4/commons/postgres"
    cmongo "github.com/LerianStudio/lib-commons/v4/commons/mongo"
    credis "github.com/LerianStudio/lib-commons/v4/commons/redis"
)
```

> **Note:** v4 uses `c` prefix aliases (e.g., `clog`, `czap`, `cotel`) except for the root commons package which uses `libCommons`. This distinguishes lib-commons packages from standard library and other imports.

### What lib-commons v4 Provides

| Package | Alias | Purpose | Where Used |
|---------|-------|---------|------------|
| `commons` | `libCommons` | Config loading (`InitLocalEnvConfig`), UUID validation, safe math | Bootstrap, utilities |
| `commons/log` | `clog` | Logger interface, Level types, Field constructors | **Everywhere** |
| `commons/zap` | `czap` | Logger initialization/configuration | **Bootstrap only** |
| `commons/assert` | `cassert` | Domain validation (returns errors, NEVER panics) | Domain, config validation |
| `commons/runtime` | `cruntime` | Safe goroutine management with panic recovery | Bootstrap, workers, services |
| `commons/opentelemetry` | `cotel` | OpenTelemetry initialization, tracing | Bootstrap, middleware |
| `commons/opentelemetry/metrics` | `cmetrics` | Typed metric definitions (Counter, Histogram) | Telemetry, services |
| `commons/net/http` | `chttp` | HTTP telemetry middleware, pagination, responses | Routes, handlers |
| `commons/postgres` | `cpostgres` | PostgreSQL connection with migrations and replicas | Bootstrap, repositories |
| `commons/mongo` | `cmongo` | MongoDB connection with lazy-connect | Bootstrap, repositories |
| `commons/redis` | `credis` | Redis connection (standalone, sentinel, cluster) | Bootstrap, cache |
| `commons/rabbitmq` | `crabbitmq` | RabbitMQ connection with SSRF protection | Bootstrap, producers/consumers |
| `commons/crypto` | `ccrypto` | AES-GCM encryption, HMAC-SHA256 hashing | Sensitive data storage |
| `commons/safe` | `csafe` | Safe decimal math (no panic on zero division) | Financial calculations |
| `commons/backoff` | `cbackoff` | Exponential backoff with jitter | Retry logic |
| `commons/pointers` | `cpointers` | Pointer helper functions (`String()`, `Bool()`, etc.) | DTOs, optional fields |
| `commons/security` | `csecurity` | Sensitive field detection and obfuscation | Logging, auditing |
| `commons/outbox` | `coutbox` | Outbox pattern for reliable event publishing | Event-driven services |
| `commons/secretsmanager` | `csm` | AWS Secrets Manager for M2M credentials | Plugin multi-tenant |
| `commons/circuitbreaker` | `ccb` | Circuit breaker with health checks | External service calls |
| `commons/constants` | `cconst` | Standard HTTP headers, error codes, pagination defaults | Utilities |
| `commons/dispatch layer` | — | Multi-tenant middleware, DB routing, Redis key prefixing | See multi-tenant.md |

> **⛔ Version Gate:** The packages `cassert`, `cruntime`, `csafe`, `cbackoff`, and `coutbox` are introduced in lib-commons v4. Before using these, verify the project's `go.mod` declares `lib-commons/v4`. If the project uses v3 or v2, these packages will not compile. Check with: `grep 'lib-commons' go.mod`

---

## Frameworks & Libraries

### Required Versions (Minimum)

| Library | Minimum Version | Purpose |
|---------|-----------------|---------|
| `lib-commons` | v4.0.0 | Core infrastructure |
| `fiber/v2` | v2.52.0 | HTTP framework |
| `pgx/v5` | v5.7.0 | PostgreSQL driver |
| `go.opentelemetry.io/otel` | v1.42.0 | Telemetry |
| `testify` | v1.11.0 | Testing |
| `go-sqlmock` | v1.5.0 | Database mocking |
| `testcontainers-go` | v0.40.0 | Integration tests |
| `shopspring/decimal` | v1.4.0 | Monetary precision |
| `sony/gobreaker/v2` | v2.4.0 | Circuit breaker (direct use) |

### HTTP Framework

| Library | Use Case |
|---------|----------|
| **Fiber v2** | **Primary choice** - High-performance APIs |
| gRPC-Go | Service-to-service communication |

### Database

| Library | Use Case |
|---------|----------|
| **pgx/v5** | PostgreSQL (recommended) |
| sqlc | Type-safe SQL queries |
| GORM | ORM (when needed) |
| **go-redis/v9** | Redis client |
| **mongo-go-driver** | MongoDB |

### Testing

| Library | Use Case |
|---------|----------|
| testify | Assertions |
| GoMock | Interface mocking (MANDATORY for all mocks) |
| SQLMock | Database mocking |
| testcontainers-go | Integration tests |

---

## Configuration

All services **MUST** use `libCommons.InitLocalEnvConfig()` for configuration loading. v4 uses **nested config structs** that group related settings together.

### 1. Define Configuration Struct (Nested Pattern)

```go
// bootstrap/config.go
package bootstrap

const ApplicationName = "your-service-name"

// Config is the top level configuration struct for the entire application.
// v4 uses nested structs to group related configuration.
type Config struct {
    App   AppConfig   `envPrefix:""`
    DB    DBConfig    `envPrefix:"DB_"`
    Mongo MongoConfig `envPrefix:"MONGO_"`
    Redis RedisConfig `envPrefix:"REDIS_"`
    OTel  OTelConfig  `envPrefix:"OTEL_"`
    Auth  AuthConfig  `envPrefix:"PLUGIN_AUTH_"`
}

type AppConfig struct {
    EnvName       string `env:"ENV_NAME"`
    LogLevel      string `env:"LOG_LEVEL"`
    ServerAddress string `env:"SERVER_ADDRESS"`
}

type DBConfig struct {
    Host            string `env:"HOST"`
    User            string `env:"USER"`
    Password        string `env:"PASSWORD"`
    Name            string `env:"NAME"`
    Port            string `env:"PORT"`
    SSLMode         string `env:"SSLMODE"`
    ReplicaHost     string `env:"REPLICA_HOST"`
    ReplicaUser     string `env:"REPLICA_USER"`
    ReplicaPassword string `env:"REPLICA_PASSWORD"`
    ReplicaName     string `env:"REPLICA_NAME"`
    ReplicaPort     string `env:"REPLICA_PORT"`
    ReplicaSSLMode  string `env:"REPLICA_SSLMODE"`
    MaxOpenConns    int    `env:"MAX_OPEN_CONNS"`
    MaxIdleConns    int    `env:"MAX_IDLE_CONNS"`
}

type MongoConfig struct {
    URI        string `env:"URI"`
    Host       string `env:"HOST"`
    Name       string `env:"NAME"`
    User       string `env:"USER"`
    Password   string `env:"PASSWORD"`
    Port       string `env:"PORT"`
    Parameters string `env:"PARAMETERS"`
    MaxPool    int    `env:"MAX_POOL_SIZE"`
}

type RedisConfig struct {
    Host                        string `env:"HOST"`
    MasterName                  string `env:"MASTER_NAME" envDefault:""`
    Password                    string `env:"PASSWORD"`
    DB                          int    `env:"DB" envDefault:"0"`
    Protocol                    int    `env:"PROTOCOL" envDefault:"3"`
    TLS                         bool   `env:"TLS" envDefault:"false"`
    CACert                      string `env:"CA_CERT"`
    UseGCPIAM                   bool   `env:"USE_GCP_IAM" envDefault:"false"`
    ServiceAccount              string `env:"SERVICE_ACCOUNT" envDefault:""`
    GoogleApplicationCredentials string `env:"GOOGLE_APPLICATION_CREDENTIALS" envDefault:""`
    TokenLifeTime               int    `env:"TOKEN_LIFETIME" envDefault:"60"`
    TokenRefreshDuration        int    `env:"TOKEN_REFRESH_DURATION" envDefault:"45"`
}

type OTelConfig struct {
    ServiceName      string `env:"RESOURCE_SERVICE_NAME"`
    LibraryName      string `env:"LIBRARY_NAME"`
    ServiceVersion   string `env:"RESOURCE_SERVICE_VERSION"`
    DeploymentEnv    string `env:"RESOURCE_DEPLOYMENT_ENVIRONMENT"`
    ExporterEndpoint string `env:"EXPORTER_OTLP_ENDPOINT"`
    EnableTelemetry  bool   `env:"ENABLE_TELEMETRY"`
}

type AuthConfig struct {
    Enabled bool   `env:"ENABLED"`
    Address string `env:"ADDRESS"`
}
```

### 2. Load Configuration

```go
// bootstrap/config.go
func InitServersWithOptions(opts ...Option) (*Service, error) {
    // Load .env file for local development (no-op in production)
    libCommons.InitLocalEnvConfig()

    cfg := &Config{}
    if err := env.Parse(cfg); err != nil {
        return nil, fmt.Errorf("parse config: %w", err)
    }

    // Continue with initialization...
}
```

> **Note:** `libCommons.InitLocalEnvConfig()` loads `.env` files for local development. In production (containers), environment variables are injected directly and the function is a no-op. The `env.Parse()` call uses the `caarlos0/env` library to populate the struct from environment variables, respecting `envPrefix` tags for nested structs.

### Supported Types

| Go Type | Default Value | Example |
|---------|---------------|---------|
| `string` | `""` | `ServerAddress string \`env:"SERVER_ADDRESS"\`` |
| `bool` | `false` | `EnableTelemetry bool \`env:"ENABLE_TELEMETRY"\`` |
| `int`, `int8`, `int16`, `int32`, `int64` | `0` | `MaxPool int \`env:"MAX_POOL_SIZE"\`` |

### Environment Variable Naming Convention

| Category | Prefix | Example |
|----------|--------|---------|
| Application | None | `ENV_NAME`, `LOG_LEVEL`, `SERVER_ADDRESS` |
| PostgreSQL | `DB_` | `DB_HOST`, `DB_USER`, `DB_PASSWORD` |
| PostgreSQL Replica | `DB_REPLICA_` | `DB_REPLICA_HOST`, `DB_REPLICA_USER` |
| MongoDB | `MONGO_` | `MONGO_HOST`, `MONGO_NAME` |
| Redis | `REDIS_` | `REDIS_HOST`, `REDIS_PASSWORD` |
| OpenTelemetry | `OTEL_` | `OTEL_RESOURCE_SERVICE_NAME` |
| Auth Plugin | `PLUGIN_AUTH_` | `PLUGIN_AUTH_ENABLED`, `PLUGIN_AUTH_ADDRESS` |
| gRPC Services | `{SERVICE}_GRPC_` | `TRANSACTION_GRPC_ADDRESS` |

### What not to Do

```go
// FORBIDDEN: Manual os.Getenv calls scattered across code
host := os.Getenv("DB_HOST")  // DON'T do this

// FORBIDDEN: Configuration outside bootstrap
func NewService() *Service {
    dbHost := os.Getenv("DB_HOST")  // DON'T do this
}

// CORRECT: All configuration in nested Config struct, loaded once in bootstrap
type Config struct {
    DB DBConfig `envPrefix:"DB_"`
}
type DBConfig struct {
    Host string `env:"HOST"`  // Reads DB_HOST (prefix + field)
}

// Load with: libCommons.InitLocalEnvConfig() + env.Parse(&cfg)
```

---

## Observability

All services **MUST** integrate OpenTelemetry using lib-commons.

### Distributed Tracing Architecture

Understanding how traces propagate is critical for proper instrumentation.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        INCOMING HTTP REQUEST                                │
│                                                                             │
│  Headers: traceparent, tracestate (W3C Trace Context)                       │
│  - If present: child span created with remote parent (distributed trace)   │
│  - If absent: new root trace created                                        │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  MIDDLEWARE: OTel middleware from chttp - CREATES ROOT SPAN                  │
│                                                                             │
│  What the OTel middleware does:                                              │
│  1. Extracts traceparent/tracestate from incoming headers                    │
│     → Uses otel.GetTextMapPropagator().Extract() for W3C trace context      │
│     → If traceparent exists: creates child span of remote parent            │
│     → If no traceparent: creates new root span                              │
│  2. tracer.Start(ctx, "GET /api/resource") - creates HTTP ROOT SPAN         │
│  3. Sets span attributes: http.method, http.url, http.route, etc.           │
│  4. Injects tracer, logger, and metrics factory into context                │
│  5. c.SetUserContext(ctx) - makes enriched context available to handlers    │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  HANDLER LAYER (optional child spans - for complex handlers)                │
│                                                                             │
│  // Logger is dependency-injected; tracer via global wrapper                │
│  ctx, span := telemetry.StartSpan(ctx, "handler.create_tenant")             │
│  defer span.End()                                                           │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  SERVICE LAYER (MANDATORY child spans for all methods)                      │
│                                                                             │
│  // Logger is dependency-injected; tracer via global wrapper                │
│  ctx, span := telemetry.StartSpan(ctx, "service.tenant.create")             │
│  defer span.End()                                                           │
│                                                                             │
│  // Structured logging with fields (v4 pattern)                             │
│  s.logger.Log(ctx, clog.LevelInfo, "Creating tenant",                       │
│      clog.String("name", req.Name))                                         │
│                                                                             │
│  // Business errors → span status stays OK                                  │
│  telemetry.HandleSpanError(span, err) // for technical errors               │
│  telemetry.SetSpanSuccess(span)       // for success                        │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  REPOSITORY LAYER (optional - for complex database operations)              │
│                                                                             │
│  Same pattern as service layer                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  OUTGOING CALLS (HTTP, gRPC, Queue) - PROPAGATE TRACE CONTEXT               │
│                                                                             │
│  // HTTP Client: Inject traceparent/tracestate into outgoing headers        │
│  cotel.InjectHTTPContext(&req.Header, ctx)                                  │
│                                                                             │
│  // gRPC Client: Inject into outgoing metadata                              │
│  ctx = cotel.InjectGRPCContext(ctx)                                         │
│                                                                             │
│  // Queue/Message: Inject into message headers for async trace continuation │
│  headers := cotel.PrepareQueueHeaders(ctx, baseHeaders)                     │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Complete Telemetry Flow (Bootstrap to Shutdown)

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. BOOTSTRAP (config.go)                                        │
│    tl, err := cotel.NewTelemetry(cotel.TelemetryConfig{...})   │
│    tl.ApplyGlobals()                                            │
│    → Creates OpenTelemetry provider once at startup             │
│    → Sets global TextMapPropagator for W3C TraceContext         │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. ROUTER (routes.go)                                           │
│    Middleware chain:                                              │
│    recover → requestid → security headers → rate limiting        │
│    → CORS → sandbox → OTel → tenant → org validation → license  │
│    OTel middleware creates root span per request                  │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. any LAYER (handlers, services, repositories)                 │
│    // Logger is DI field; tracer via global wrapper              │
│    ctx, span := telemetry.StartSpan(ctx, "operation_name")      │
│    defer span.End()                                              │
│    s.logger.Log(ctx, clog.LevelInfo, "Processing...",           │
│        clog.String("key", "value"))                              │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. SERVER LIFECYCLE (service.go)                                 │
│    svc.Run(ctx) starts HTTP server via cruntime.SafeGo...       │
│    svc.Shutdown(ctx) flushes telemetry + drains connections      │
│    → main.go uses signal.NotifyContext for graceful shutdown     │
└─────────────────────────────────────────────────────────────────┘
```

---

### Service Method Instrumentation Checklist (MANDATORY)

**Every service method MUST implement these steps:**

| # | Step | Code Pattern | Purpose |
|---|------|--------------|---------|
| 1 | Logger as struct field | `s.logger clog.Logger` (dependency-injected) | Injected at construction time |
| 2 | Create child span | `ctx, span := telemetry.StartSpan(ctx, "service.{domain}.{operation}")` | Create traceable operation via global wrapper |
| 3 | Defer span end | `defer span.End()` | Ensure span closes even on panic |
| 4 | Use structured logger with fields | `s.logger.Log(ctx, clog.LevelInfo, "msg", clog.String("key", "val"))` | Logs correlated with trace |
| 5 | Handle business errors | `cotel.HandleSpanBusinessErrorEvent(&span, msg, err)` | Expected errors (validation, not found) |
| 6 | Handle technical errors | `cotel.HandleSpanError(&span, msg, err)` | Unexpected errors (DB, network) |
| 7 | Pass ctx downstream | All calls receive `ctx` with span | Trace propagation |

---

### Error Handling Classification

| Error Type | Examples | Handler Function | Span Status |
|------------|----------|------------------|-------------|
| **Business Error** | Validation failed, Resource not found, Conflict, Unauthorized | `cotel.HandleSpanBusinessErrorEvent` | OK (adds event) |
| **Technical Error** | DB connection failed, Timeout, Network error, Unexpected panic | `cotel.HandleSpanError` | ERROR (records error) |

**Why the distinction matters:**
- Business errors are expected and don't indicate system problems
- Technical errors indicate infrastructure issues requiring investigation
- Alerting systems typically trigger on ERROR status spans

---

### Complete Instrumented Service Method Template

```go
func (s *myService) DoSomething(ctx context.Context, req *Request) (*Response, error) {
    // 1. Logger is a struct field (dependency-injected at construction)
    // Core three is accessed via global wrapper (set by cotel.ApplyGlobals at bootstrap)

    // 2. Create child span for this operation
    ctx, span := telemetry.StartSpan(ctx, "service.my_service.do_something")
    defer span.End()

    // 3. Structured logging with typed fields (v4 pattern)
    s.logger.Log(ctx, clog.LevelInfo, "Processing request",
        clog.String("id", req.ID))

    // 4. Input validation - BUSINESS error (expected, span stays OK)
    if req.Name == "" {
        s.logger.Log(ctx, clog.LevelWarn, "Validation failed: empty name")
        cotel.HandleSpanBusinessErrorEvent(&span, "Validation failed", ErrInvalidInput)
        return nil, fmt.Errorf("%w: name is required", ErrInvalidInput)
    }

    // 5. External call - pass ctx to propagate trace context
    result, err := s.repo.Create(ctx, entity)
    if err != nil {
        // Check if it's a "not found" type error (business) vs DB failure (technical)
        if errors.Is(err, ErrNotFound) {
            s.logger.Log(ctx, clog.LevelWarn, "Entity not found",
                clog.String("id", req.ID))
            cotel.HandleSpanBusinessErrorEvent(&span, "Entity not found", err)
            return nil, err
        }

        // TECHNICAL error - unexpected failure, span marked ERROR
        s.logger.Log(ctx, clog.LevelError, "Failed to create entity",
            clog.Err(err))
        cotel.HandleSpanError(&span, "Repository create failed", err)
        return nil, fmt.Errorf("failed to create: %w", err)
    }

    s.logger.Log(ctx, clog.LevelInfo, "Entity created successfully",
        clog.String("id", result.ID))
    return result, nil
}
```

---

### Telemetry Wrapper Package (MANDATORY)

Every service MUST create a thin telemetry wrapper at `internal/shared/telemetry/tracer.go`. This wrapper accesses the global tracer (registered by `cotel.NewTelemetry()` + `tl.ApplyGlobals()` at bootstrap) and provides domain-specific helpers.

```go
// internal/shared/telemetry/tracer.go
package telemetry

import (
    "context"

    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/codes"
    "go.opentelemetry.io/otel/trace"
)

// tracerName identifies this service in distributed traces.
const tracerName = "github.com/LerianStudio/your-service"

// StartSpan creates a new span using the global tracer provider.
func StartSpan(ctx context.Context, name string, opts ...trace.SpanStartOption) (context.Context, trace.Span) {
    return otel.Core three(tracerName).Start(ctx, name, opts...)
}

// HandleSpanError records an error on the span and sets status to Error.
func HandleSpanError(span trace.Span, err error) {
    if span == nil || err == nil {
        return
    }
    span.RecordError(err)
    span.SetStatus(codes.Error, err.Error())
}

// SetSpanSuccess sets the span status to OK.
func SetSpanSuccess(span trace.Span) {
    if span == nil {
        return
    }
    span.SetStatus(codes.Ok, "")
}

// SpanFromContext returns the current span from context.
func SpanFromContext(ctx context.Context) trace.Span {
    return trace.SpanFromContext(ctx)
}
```

**Why a wrapper instead of direct `otel.Core three()` calls:**
- Single place to change the `tracerName` constant
- Domain-specific helpers (`HandleSpanError`, `SetSpanSuccess`) reduce boilerplate
- The wrapper uses the global provider set by `cotel.ApplyGlobals()` — no struct injection needed for tracer

**Span Naming Conventions:**

| Layer | Pattern | Examples |
|-------|---------|----------|
| HTTP Handler | `handler.{resource}.{action}` | `handler.tenant.create`, `handler.agent.list` |
| Service | `service.{domain}.{operation}` | `service.tenant.create`, `service.agent.register` |
| Repository | `repository.{entity}.{operation}` | `repository.tenant.get_by_id`, `repository.agent.list` |
| External Call | `external.{service}.{operation}` | `external.payment.process`, `external.auth.validate` |
| Queue Consumer | `consumer.{queue}.{operation}` | `consumer.balance_create.process` |

---

### Span Naming Conventions

| Layer | Pattern | Examples |
|-------|---------|----------|
| HTTP Handler | `handler.{resource}.{action}` | `handler.tenant.create`, `handler.agent.list` |
| Service | `service.{domain}.{operation}` | `service.tenant.create`, `service.agent.register` |
| Repository | `repository.{entity}.{operation}` | `repository.tenant.get_by_id`, `repository.agent.list` |
| External Call | `external.{service}.{operation}` | `external.payment.process`, `external.auth.validate` |
| Queue Consumer | `consumer.{queue}.{operation}` | `consumer.balance_create.process` |

---

### Distributed Tracing: Outgoing Calls (MANDATORY for service-to-service)

When making outgoing calls to other services, **MUST** inject trace context:

```go
// HTTP Client - Inject traceparent/tracestate headers
req, _ := http.NewRequestWithContext(ctx, "POST", url, body)
cotel.InjectHTTPContext(&req.Header, ctx)
resp, err := client.Do(req)

// gRPC Client - Inject into outgoing metadata
ctx = cotel.InjectGRPCContext(ctx)
resp, err := grpcClient.SomeMethod(ctx, req)

// Queue/Message Publisher - Inject into message headers
headers := cotel.PrepareQueueHeaders(ctx, map[string]any{
    "content-type": "application/json",
})
// Use headers when publishing to RabbitMQ/Kafka
```

**Why this matters:**
- Without injection, downstream services create new root traces
- Trace chain breaks, making debugging cross-service issues impossible
- Correlation IDs are lost across service boundaries

---

### Instrumentation Anti-Patterns (FORBIDDEN)

| Anti-Pattern | Problem | Correct Pattern |
|--------------|---------|-----------------|
| `import "go.opentelemetry.io/otel"` | Direct OTel usage bypasses lib-commons wrappers | Use dependency-injected `trace.Core three` from `cotel` |
| `import "go.opentelemetry.io/otel/trace"` | Direct tracer access without lib-commons | Use `cotel` package from lib-commons |
| `otel.Core three("name")` in service code | Scattered tracer creation, no single tracerName | Use `telemetry.StartSpan()` from shared wrapper package |
| `trace.SpanFromContext(ctx)` in service code | Raw OTel API, bypasses wrapper | Use `telemetry.SpanFromContext(ctx)` from shared wrapper |
| Custom error handler | Inconsistent error format across services | Use `chttp.HandleFiberError` in fiber.Config |
| Manual pagination logic | Reinvents cursor/offset pagination | Use `chttp.Pagination`, `chttp.CursorPagination` |
| Custom logging middleware | Inconsistent request logging | Use chttp OTel middleware |
| Manual telemetry middleware | Missing trace context injection | Use `chttp` OTel middleware |
| `log.Printf("[Service] msg")` | No trace correlation, no structured logging | `s.logger.Log(ctx, clog.LevelInfo, "msg")` |
| No span in service method | Operation not traceable | Always create child span |
| `return err` without span handling | Error not attributed to trace | Call `cotel.HandleSpanError` or `cotel.HandleSpanBusinessErrorEvent` |
| Hardcoded trace IDs | Breaks distributed tracing | Use context propagation |
| Missing `defer span.End()` | Span never closes, memory leak | Always defer immediately after Start |
| Using `_` to ignore tracer | No tracing capability | Use dependency-injected tracer |
| Calling downstream without ctx | Trace chain breaks | Pass ctx to all downstream calls |
| Not injecting trace context for outgoing HTTP/gRPC | Remote traces disconnected | Use `cotel.InjectHTTPContext` / `cotel.InjectGRPCContext` |
| `go func() { ... }()` | No panic recovery, no observability | Use `cruntime.SafeGoWithContextAndComponent` |
| `logger.Infof("msg: %s", val)` | v2 format-based logging | Use `s.logger.Log(ctx, level, "msg", clog.String(...))` |
| `libCommons.SetConfigFromEnvVars(&cfg)` | v2 config loading, removed in v4 | Use `libCommons.InitLocalEnvConfig()` + `env.Parse()` |
| `libOpentelemetry.InitializeTelemetry()` | v2 telemetry init, panics on error | Use `cotel.NewTelemetry()` + `tl.ApplyGlobals()` |
| `libZap.InitializeLogger()` | v2 logger init, no config options | Use `czap.New(czap.Config{...})` |
| `libCommons.NewTrackingFromContext(ctx)` | v2 context tracking, removed in v4 | Use dependency-injected logger |
| `libServer.StartWithGracefulShutdown()` | v2 lifecycle, removed in v4 | Use `Service.Run(ctx)` + `Service.Shutdown(ctx)` |
| `libCommons.NewLauncher(...)` | v2 app launcher, removed in v4 | Use `signal.NotifyContext` + `cruntime.SafeGoWithContextAndComponent` |

> **⛔ CRITICAL:** Direct imports of `go.opentelemetry.io/otel`, `go.opentelemetry.io/otel/trace`, `go.opentelemetry.io/otel/attribute`, or `go.opentelemetry.io/otel/codes` are **FORBIDDEN** in application code. All telemetry MUST go through lib-commons wrappers (`cotel`). The only exception is if lib-commons doesn't provide a required OTel feature - in that case, open an issue to add it to lib-commons.

> **⛔ CRITICAL:** Raw goroutines (`go func() { ... }()`) are **FORBIDDEN** in production code. All goroutines MUST use `cruntime.SafeGoWithContextAndComponent` for panic recovery and observability.

> **⛔ CRITICAL:** Direct Fiber response methods (`c.JSON()`, `c.Status().JSON()`, `c.SendString()`) are **FORBIDDEN**. All HTTP responses MUST use `chttp` wrappers (`chttp.OK()`, `chttp.Created()`, `chttp.WithError()`, etc.) to ensure consistent response format across all Lerian services.

### 1. Bootstrap Initialization

```go
// bootstrap/config.go
func InitServersWithOptions(opts ...Option) (*Service, error) {
    libCommons.InitLocalEnvConfig()

    cfg := &Config{}
    if err := env.Parse(cfg); err != nil {
        return nil, fmt.Errorf("parse config: %w", err)
    }

    // Initialize logger FIRST (czap for bootstrap only)
    logger, err := czap.New(czap.Config{
        Level:       cfg.App.LogLevel,
        Development: cfg.App.EnvName != "production",
    })
    if err != nil {
        return nil, fmt.Errorf("init logger: %w", err)
    }

    // Initialize telemetry with config
    tl, err := cotel.NewTelemetry(cotel.TelemetryConfig{
        ServiceName:    cfg.OTel.ServiceName,
        ServiceVersion: cfg.OTel.ServiceVersion,
        DeploymentEnv:  cfg.OTel.DeploymentEnv,
        ExporterEndpoint: cfg.OTel.ExporterEndpoint,
        InsecureExporter: cfg.App.EnvName != "production",
    })
    if err != nil {
        return nil, fmt.Errorf("init telemetry: %w", err)
    }
    if err = tl.ApplyGlobals(); err != nil {
        return nil, fmt.Errorf("apply telemetry globals: %w", err)
    }

    // Pass telemetry to router...
}
```

### 2. Router Middleware Setup

```go
// adapters/http/in/routes.go
import (
    clog "github.com/LerianStudio/lib-commons/v4/commons/log"
    chttp "github.com/LerianStudio/lib-commons/v4/commons/net/http"
    cotel "github.com/LerianStudio/lib-commons/v4/commons/opentelemetry"
    "github.com/gofiber/fiber/v2"
    "github.com/gofiber/fiber/v2/middleware/cors"
    "github.com/gofiber/fiber/v2/middleware/recover"
    "github.com/gofiber/fiber/v2/middleware/requestid"
)

func NewRouter(lg clog.Logger, tl *cotel.Telemetry, ...) *fiber.App {
    f := fiber.New(fiber.Config{
        DisableStartupMessage: true,
        ErrorHandler: func(ctx *fiber.Ctx, err error) error {
            return chttp.HandleFiberError(ctx, err)
        },
    })

    // Middleware setup - ORDER MATTERS (v4 chain)
    f.Use(recover.New())                           // 1. Panic recovery
    f.Use(requestid.New())                         // 2. Request ID
    // f.Use(securityHeaders())                    // 3. Security headers (if applicable)
    // f.Use(rateLimiting())                       // 4. Rate limiting (if applicable)
    f.Use(cors.New())                              // 5. CORS
    // f.Use(sandbox())                            // 6. Sandbox mode (if applicable)
    tm := chttp.NewTelemetryMiddleware(tl)
    f.Use(tm.WithTelemetry(tl, "/health"))         // 7. OpenTelemetry (creates root span)
    // f.Use(tenantMiddleware())                   // 8. Tenant resolution (if multi-tenant)
    // f.Use(orgValidation())                      // 9. Organization validation (if applicable)
    // f.Use(licenseMiddleware())                  // 10. License check (if applicable)

    // ... define routes ...

    // Health and version (no auth required)
    f.Get("/health", chttp.Ping)
    f.Get("/version", chttp.Version)

    return f
}
```

### HTTP Metrics (via chttp OTel Middleware)

The `chttp` OTel middleware from lib-commons v4 provides HTTP metrics collection alongside tracing. It uses standard OpenTelemetry semantic conventions.

**Metrics Collected:**

| Metric | Type | Description |
|--------|------|-------------|
| `http.server.duration` | Histogram | Request duration in milliseconds |
| `http.server.request.size` | Histogram | Request body size in bytes |
| `http.server.response.size` | Histogram | Response body size in bytes |
| `http.server.active_requests` | Gauge | Currently processing requests |

**Why lib-commons middleware over custom middleware:**
- Standard OpenTelemetry semantic conventions
- Automatic trace context propagation
- Consistent with lib-commons patterns
- Compatible with any OpenTelemetry backend (Jaeger, Zipkin, Grafana, etc.)

### 3. Using Logger & Core three (Any Layer)

```go
// any file in any layer (handler, service, repository)
// Logger is dependency-injected; tracer via global wrapper
type Service struct {
    logger clog.Logger
    repo   Repository
}

func (s *Service) ProcessEntity(ctx context.Context, id string) error {
    // Logger is a struct field (dependency-injected)
    // Core three via global wrapper

    // Create child span for this operation
    ctx, span := telemetry.StartSpan(ctx, "service.process_entity")
    defer span.End()

    // Structured logging with typed fields
    s.logger.Log(ctx, clog.LevelInfo, "Processing entity",
        clog.String("id", id))

    // Pass ctx to downstream calls - trace propagates automatically
    return s.repo.Update(ctx, id)
}
```

### 4. Error Handling with Spans

```go
// For technical errors (unexpected failures)
if err != nil {
    cotel.HandleSpanError(&span, "Failed to connect database", err)
    s.logger.Log(ctx, clog.LevelError, "Database error",
        clog.Err(err))
    return nil, err
}

// For business errors (expected validation failures)
if err != nil {
    cotel.HandleSpanBusinessErrorEvent(&span, "Validation failed", err)
    s.logger.Log(ctx, clog.LevelWarn, "Validation error",
        clog.Err(err))
    return nil, err
}
```

### 5. Server Lifecycle with Graceful Shutdown

```go
// bootstrap/service.go
// v4 uses signal.NotifyContext in main.go and Service.Run(ctx)/Shutdown(ctx)
// See the Bootstrap section for complete reference implementations.
func (svc *Service) Run(ctx context.Context) {
    cruntime.SafeGoWithContextAndComponent(
        ctx, svc.logger, "bootstrap", "http-server",
        cruntime.CrashProcess,
        func(goCtx context.Context) {
            if err := svc.app.Listen(svc.serverAddress); err != nil {
                svc.logger.Log(goCtx, clog.LevelError, "HTTP server failed",
                    clog.Err(err))
            }
        },
    )
}

func (svc *Service) Shutdown(ctx context.Context) {
    _ = svc.app.ShutdownWithContext(ctx)
    _ = svc.telemetry.Shutdown(ctx)
    _ = svc.logger.Sync(ctx)
}
```

### Required Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `OTEL_RESOURCE_SERVICE_NAME` | Service name in traces | `service-name` |
| `OTEL_LIBRARY_NAME` | Library identifier | `service-name` |
| `OTEL_RESOURCE_SERVICE_VERSION` | Service version | `1.0.0` |
| `OTEL_RESOURCE_DEPLOYMENT_ENVIRONMENT` | Environment | `production` |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | Collector endpoint | `http://otel-collector:4317` |
| `ENABLE_TELEMETRY` | Enable/disable | `true` |

---

## Bootstrap

All services **MUST** follow the bootstrap pattern for initialization. The bootstrap package is the single point of application assembly where all dependencies are wired together.

### Directory Structure

```text
/internal
  /bootstrap
    config.go          # Config struct + InitServers() - Main initialization logic
    service.go         # Service lifecycle, DI, Fiber setup
    grpc.server.go     # gRPC server (if needed)
    service.go         # Service struct wrapping servers + Run() method
```

### Reference Implementations

The following sections provide **complete, copy-pasteable** implementations for each bootstrap file. These are extracted from production repositories (plugin-br-bank-transfer-jd).

---

### config.go - Complete Reference

This is the main initialization file that wires all dependencies together.

```go
package bootstrap

import (
    "context"
    "fmt"
    "strings"
    "time"

    libCommons "github.com/LerianStudio/lib-commons/v4/commons"
    clog "github.com/LerianStudio/lib-commons/v4/commons/log"
    czap "github.com/LerianStudio/lib-commons/v4/commons/zap"
    cotel "github.com/LerianStudio/lib-commons/v4/commons/opentelemetry"
    cpostgres "github.com/LerianStudio/lib-commons/v4/commons/postgres"
    cmongo "github.com/LerianStudio/lib-commons/v4/commons/mongo"
    credis "github.com/LerianStudio/lib-commons/v4/commons/redis"
    cruntime "github.com/LerianStudio/lib-commons/v4/commons/runtime"

    "github.com/caarlos0/env/v11"

    // Internal imports
    httpin "github.com/LerianStudio/your-service/internal/adapters/http/in"
    "github.com/LerianStudio/your-service/internal/adapters/postgres/user"
    "github.com/LerianStudio/your-service/internal/services/command"
    "github.com/LerianStudio/your-service/internal/services/query"
)

// ApplicationName identifies this service in logs, traces, and metrics.
const ApplicationName = "your-service"

// Config is the top level configuration struct for the entire application.
// v4 uses nested structs with `envPrefix` tags for grouping.
type Config struct {
    App   AppConfig   `envPrefix:""`
    DB    DBConfig    `envPrefix:"DB_"`
    Mongo MongoConfig `envPrefix:"MONGO_"`
    Redis RedisConfig `envPrefix:"REDIS_"`
    OTel  OTelConfig  `envPrefix:"OTEL_"`
    Auth  AuthConfig  `envPrefix:"PLUGIN_AUTH_"`
}

// (See Configuration section above for nested struct definitions)

// InitServersWithOptions initializes all application components and returns a Service ready to run.
// This is the single point of dependency injection for the entire application.
// v4 returns error instead of panicking.
func InitServersWithOptions(opts ...Option) (*Service, error) {
    // 1. LOAD CONFIGURATION
    // InitLocalEnvConfig loads .env for local dev (no-op in production)
    libCommons.InitLocalEnvConfig()

    cfg := &Config{}
    if err := env.Parse(cfg); err != nil {
        return nil, fmt.Errorf("parse config: %w", err)
    }

    // 2. INITIALIZE LOGGER
    // Must be first after config - all subsequent components need logging
    logger, err := czap.New(czap.Config{
        Level:       cfg.App.LogLevel,
        Development: cfg.App.EnvName != "production",
    })
    if err != nil {
        return nil, fmt.Errorf("init logger: %w", err)
    }

    // 3. INITIALIZE TELEMETRY
    // OpenTelemetry provider for distributed tracing
    tl, err := cotel.NewTelemetry(cotel.TelemetryConfig{
        ServiceName:      cfg.OTel.ServiceName,
        ServiceVersion:   cfg.OTel.ServiceVersion,
        DeploymentEnv:    cfg.OTel.DeploymentEnv,
        ExporterEndpoint: cfg.OTel.ExporterEndpoint,
        InsecureExporter: cfg.App.EnvName != "production",
    })
    if err != nil {
        return nil, fmt.Errorf("init telemetry: %w", err)
    }
    if err = tl.ApplyGlobals(); err != nil {
        return nil, fmt.Errorf("apply telemetry globals: %w", err)
    }

    // 4. INITIALIZE DATABASE CONNECTIONS
    // PostgreSQL connection with primary/replica support
    postgreSourcePrimary := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=%s",
        cfg.DB.Host, cfg.DB.User, cfg.DB.Password,
        cfg.DB.Name, cfg.DB.Port, cfg.DB.SSLMode)

    postgreSourceReplica := postgreSourcePrimary
    if cfg.DB.ReplicaHost != "" {
        postgreSourceReplica = fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=%s",
            cfg.DB.ReplicaHost, cfg.DB.ReplicaUser, cfg.DB.ReplicaPassword,
            cfg.DB.ReplicaName, cfg.DB.ReplicaPort, cfg.DB.ReplicaSSLMode)
    }

    postgresConnection := &cpostgres.PostgresConnection{
        ConnectionStringPrimary: postgreSourcePrimary,
        ConnectionStringReplica: postgreSourceReplica,
        PrimaryDBName:           cfg.DB.Name,
        ReplicaDBName:           cfg.DB.ReplicaName,
        Component:               ApplicationName,
        Logger:                  logger,
        MaxOpenConnections:      cfg.DB.MaxOpenConns,
        MaxIdleConnections:      cfg.DB.MaxIdleConns,
    }

    // MongoDB connection (optional - include only if service uses MongoDB)
    mongoSource := fmt.Sprintf("%s://%s:%s@%s:%s/",
        cfg.Mongo.URI, cfg.Mongo.User, cfg.Mongo.Password, cfg.Mongo.Host, cfg.Mongo.Port)
    if cfg.Mongo.MaxPool <= 0 {
        cfg.Mongo.MaxPool = 100
    }
    if cfg.Mongo.Parameters != "" {
        mongoSource += "?" + cfg.Mongo.Parameters
    }
    mongoConnection := &cmongo.MongoConnection{
        ConnectionStringSource: mongoSource,
        Database:               cfg.Mongo.Name,
        Logger:                 logger,
        MaxPoolSize:            uint64(cfg.Mongo.MaxPool),
    }

    // Redis connection (optional - include only if service uses Redis)
    redisConnection := &credis.RedisConnection{
        Address:                      strings.Split(cfg.Redis.Host, ","),
        Password:                     cfg.Redis.Password,
        DB:                           cfg.Redis.DB,
        Protocol:                     cfg.Redis.Protocol,
        MasterName:                   cfg.Redis.MasterName,
        UseTLS:                       cfg.Redis.TLS,
        CACert:                       cfg.Redis.CACert,
        UseGCPIAMAuth:                cfg.Redis.UseGCPIAM,
        ServiceAccount:               cfg.Redis.ServiceAccount,
        GoogleApplicationCredentials: cfg.Redis.GoogleApplicationCredentials,
        TokenLifeTime:                time.Duration(cfg.Redis.TokenLifeTime) * time.Minute,
        RefreshDuration:              time.Duration(cfg.Redis.TokenRefreshDuration) * time.Minute,
        Logger:                       logger,
    }

    // 5. INITIALIZE REPOSITORIES (Adapters)
    userPostgreSQLRepository := user.NewUserPostgreSQLRepository(postgresConnection)
    // metadataMongoDBRepository := mongodb.NewMetadataMongoDBRepository(mongoConnection)
    // cacheRedisRepository := redis.NewCacheRepository(redisConnection)

    // 6. INITIALIZE USE CASES (Services/Business Logic)
    commandUseCase := &command.UseCase{
        UserRepo: userPostgreSQLRepository,
    }
    queryUseCase := &query.UseCase{
        UserRepo: userPostgreSQLRepository,
    }

    // 7. INITIALIZE HANDLERS
    userHandler := &httpin.UserHandler{
        Command: commandUseCase,
        Query:   queryUseCase,
    }

    // 8. CREATE ROUTER WITH MIDDLEWARE
    httpApp := httpin.NewRouter(logger, tl, userHandler)

    // 9. RETURN SERVICE
    // Service holds all components for lifecycle management
    return &Service{
        app:           httpApp,
        serverAddress: cfg.App.ServerAddress,
        logger:        logger,
        telemetry:     tl,
    }, nil
}
```

**Key Points:**
- `InitServersWithOptions()` returns `(*Service, error)` instead of panicking
- Uses nested config structs with `envPrefix` tags
- Uses `czap.New()` instead of `libZap.InitializeLogger()`
- Uses `cotel.NewTelemetry()` + `tl.ApplyGlobals()` instead of `libOpentelemetry.InitializeTelemetry()`
- Order matters: config → logger → telemetry → databases → repositories → services → handlers → router → service
- All database connections use lib-commons v4 packages

---

### service.go - Complete Reference

In v4, the `Service` struct manages the full lifecycle. There is no separate `Server` struct or `Launcher`.

```go
package bootstrap

import (
    "context"
    "fmt"

    clog "github.com/LerianStudio/lib-commons/v4/commons/log"
    cotel "github.com/LerianStudio/lib-commons/v4/commons/opentelemetry"
    cruntime "github.com/LerianStudio/lib-commons/v4/commons/runtime"
    "github.com/gofiber/fiber/v2"
)

// Service holds all components and manages application lifecycle.
type Service struct {
    app           *fiber.App
    serverAddress string
    logger        clog.Logger
    telemetry     *cotel.Telemetry
}

// Run starts all application components.
// Uses cruntime.SafeGoWithContextAndComponent for safe goroutine management.
func (svc *Service) Run(ctx context.Context) {
    svc.logger.Log(ctx, clog.LevelInfo, "Starting HTTP server",
        clog.String("address", svc.serverAddress))

    cruntime.SafeGoWithContextAndComponent(
        ctx,
        svc.logger,
        "bootstrap",
        "http-server",
        cruntime.CrashProcess,
        func(goCtx context.Context) {
            if err := svc.app.Listen(svc.serverAddress); err != nil {
                svc.logger.Log(goCtx, clog.LevelError, "HTTP server failed",
                    clog.Err(err))
            }
        },
    )
}

// Shutdown gracefully stops all components.
// Called when context is cancelled (SIGINT/SIGTERM).
func (svc *Service) Shutdown(ctx context.Context) {
    svc.logger.Log(ctx, clog.LevelInfo, "Shutting down...")

    if err := svc.app.ShutdownWithContext(ctx); err != nil {
        svc.logger.Log(ctx, clog.LevelError, "HTTP shutdown error",
            clog.Err(err))
    }

    if err := svc.telemetry.Shutdown(ctx); err != nil {
        svc.logger.Log(ctx, clog.LevelError, "Telemetry shutdown error",
            clog.Err(err))
    }

    _ = svc.logger.Sync(ctx)
}
```

**Key Points:**
- No more `libCommons.Launcher` or `libCommonsServer.NewServerManager`
- `Run(ctx)` uses `cruntime.SafeGoWithContextAndComponent` for safe goroutines
- `Shutdown(ctx)` flushes telemetry and syncs logger
- Signal handling is done in `main.go` via `signal.NotifyContext`

---

### Multiple Components (HTTP + gRPC + Worker)

For services with multiple components, start each in its own safe goroutine:

```go
func (svc *Service) Run(ctx context.Context) {
    // HTTP Server
    cruntime.SafeGoWithContextAndComponent(
        ctx, svc.logger, "bootstrap", "http-server",
        cruntime.CrashProcess,
        func(goCtx context.Context) {
            if err := svc.app.Listen(svc.serverAddress); err != nil {
                svc.logger.Log(goCtx, clog.LevelError, "HTTP server failed",
                    clog.Err(err))
            }
        },
    )

    // gRPC Server (if applicable)
    cruntime.SafeGoWithContextAndComponent(
        ctx, svc.logger, "bootstrap", "grpc-server",
        cruntime.CrashProcess,
        func(goCtx context.Context) {
            if err := svc.grpcServer.Serve(svc.grpcListener); err != nil {
                svc.logger.Log(goCtx, clog.LevelError, "gRPC server failed",
                    clog.Err(err))
            }
        },
    )

    // RabbitMQ Consumer (if applicable)
    cruntime.SafeGoWithContextAndComponent(
        ctx, svc.logger, "bootstrap", "rabbitmq-consumer",
        cruntime.CrashProcess,
        func(goCtx context.Context) {
            svc.consumer.RunConsumers(goCtx)
        },
    )
}
```

---

### main.go - Complete Reference

The main.go file uses `os.Exit(run())` pattern with `signal.NotifyContext` for graceful shutdown.

```go
package main

import (
    "context"
    "os"
    "os/signal"
    "syscall"
    "time"

    "github.com/LerianStudio/your-service/internal/bootstrap"
)

const shutdownTimeout = 10 * time.Second

func main() {
    os.Exit(run())
}

func run() int {
    // Create context that cancels on SIGINT/SIGTERM
    ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
    defer stop()

    // Initialize all components (returns error instead of panicking)
    svc, err := bootstrap.InitServersWithOptions()
    if err != nil {
        // Cannot use logger here - it failed to initialize
        os.Stderr.WriteString("failed to initialize: " + err.Error() + "\n")
        return 1
    }

    // Start all components (non-blocking)
    svc.Run(ctx)

    // Wait for signal
    <-ctx.Done()

    // Graceful shutdown with timeout
    shutdownCtx, cancel := context.WithTimeout(context.Background(), shutdownTimeout)
    defer cancel()

    svc.Shutdown(shutdownCtx)

    return 0
}
```

**Key Points:**
- `os.Exit(run())` ensures deferred functions run before exit
- `signal.NotifyContext` replaces manual signal handling
- `InitServersWithOptions()` returns `(*Service, error)` - no panics
- Graceful shutdown with configurable timeout

---

## Access Manager Integration (MANDATORY)

All services **MUST** integrate with the Access Manager system for authentication and authorization. Services use `lib-auth` to communicate with `plugin-auth`, which handles token validation and permission enforcement.

### Architecture Overview

```text
┌─────────────────────────────────────────────────────────────────────┐
│                         ACCESS MANAGER                               │
├─────────────────────────────────┬───────────────────────────────────┤
│  identity                       │  plugin-auth                      │
│  (CRUD: users, apps, groups,    │  (authn + authz)                  │
│   permissions)                  │                                   │
└─────────────────────────────────┴───────────────────────────────────┘
                                    ▲
                                    │ HTTP API
                                    │
┌───────────────────────────────────┴───────────────────────────────────┐
│                              lib-auth                                  │
│  (Go library - Fiber middleware for authorization)                     │
└───────────────────────────────────┬───────────────────────────────────┘
                                    │ import
                                    ▼
┌───────────────────────────────────────────────────────────────────────┐
│  Consumer Services (midaz, plugin-fees, reporter, etc.)               │
└───────────────────────────────────────────────────────────────────────┘
```

**Key Concepts:**
- **identity**: Manages Users, Applications, Groups, and Permissions (CRUD operations)
- **plugin-auth**: Handles authentication (authn) and authorization (authz) via token validation
- **lib-auth**: Go library that services import to integrate with plugin-auth

### Required Import

```go
import (
    authMiddleware "github.com/LerianStudio/lib-auth/v2/auth/middleware"
)
```

### Required Environment Variables

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `PLUGIN_AUTH_ADDRESS` | string | URL of plugin-auth service | `http://plugin-auth:4000` |
| `PLUGIN_AUTH_ENABLED` | bool | Enable/disable auth checks | `true` |

**For service-to-service authentication (optional):**

| Variable | Type | Description |
|----------|------|-------------|
| `CLIENT_ID` | string | OAuth2 client ID for this service |
| `CLIENT_SECRET` | string | OAuth2 client secret for this service |

### Configuration Struct

```go
// bootstrap/config.go
type Config struct {
    // ... other nested configs ...
    Auth AuthConfig `envPrefix:"PLUGIN_AUTH_"`
}

type AuthConfig struct {
    Enabled      bool   `env:"ENABLED"      envDefault:"false"`
    Address      string `env:"ADDRESS"`
    ClientID     string `env:"CLIENT_ID"`
    ClientSecret string `env:"CLIENT_SECRET" json:"-"`
}
```

### Bootstrap Integration

```go
// bootstrap/config.go
func InitServersWithOptions(opts ...Option) (*Service, error) {
    libCommons.InitLocalEnvConfig()

    cfg := &Config{}
    if err := env.Parse(cfg); err != nil {
        return nil, fmt.Errorf("parse config: %w", err)
    }

    logger, err := czap.New(czap.Config{...})
    // ... telemetry, database initialization ...

    // Initialize Access Manager client
    auth := authMiddleware.NewAuthClient(cfg.Auth.Address, cfg.Auth.Enabled, &logger)

    // Pass auth client to router
    httpApp := httpin.NewRouter(logger, tl, auth, handlers...)

    // ... rest of initialization ...
}
```

### Router Setup with Auth Middleware

```go
// adapters/http/in/routes.go
import (
    authMiddleware "github.com/LerianStudio/lib-auth/v2/auth/middleware"
)

const applicationName = "your-service-name"

func NewRouter(
    lg clog.Logger,
    tl *cotel.Telemetry,
    auth *authMiddleware.AuthClient,
    handler *YourHandler,
) *fiber.App {
    f := fiber.New(fiber.Config{
        DisableStartupMessage: true,
        ErrorHandler: func(ctx *fiber.Ctx, err error) error {
            return chttp.HandleFiberError(ctx, err)
        },
    })

    // Middleware setup (v4 chain)
    f.Use(recover.New())
    f.Use(cors.New())

    // Protected routes with authorization
    f.Post("/v1/resources", auth.Authorize(applicationName, "resources", "post"), handler.Create)
    f.Get("/v1/resources", auth.Authorize(applicationName, "resources", "get"), handler.List)
    f.Get("/v1/resources/:id", auth.Authorize(applicationName, "resources", "get"), handler.Get)
    f.Patch("/v1/resources/:id", auth.Authorize(applicationName, "resources", "patch"), handler.Update)
    f.Delete("/v1/resources/:id", auth.Authorize(applicationName, "resources", "delete"), handler.Delete)

    // Health and version (no auth required)
    f.Get("/health", chttp.Ping)
    f.Get("/version", chttp.Version)

    return f
}
```

### Authorize Middleware Parameters

```go
auth.Authorize(applicationName, resource, action)
```

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `applicationName` | string | Service identifier (must match identity registration) | `"midaz"`, `"plugin-fees"` |
| `resource` | string | Resource being accessed | `"ledgers"`, `"transactions"`, `"packages"` |
| `action` | string | HTTP method (lowercase) | `"get"`, `"post"`, `"patch"`, `"delete"` |

### Middleware Behavior

| Scenario | HTTP Response |
|----------|---------------|
| Auth disabled (`PLUGIN_AUTH_ENABLED=false`) | Skips check, calls `next()` |
| Missing Authorization header | `401 Unauthorized` |
| Token invalid or expired | `401 Unauthorized` |
| User lacks permission | `403 Forbidden` |
| User authorized | Calls `next()` |

### Service-to-Service Authentication

When a service needs to call another service (e.g., plugin-fees calling midaz), use `GetApplicationToken`:

```go
// pkg/net/http/external_service.go
import (
    "context"
    "os"
    authMiddleware "github.com/LerianStudio/lib-auth/v2/auth/middleware"
)

type ExternalServiceClient struct {
    authClient *authMiddleware.AuthClient
    baseURL    string
}

func (c *ExternalServiceClient) CallExternalService(ctx context.Context) (*Response, error) {
    // Get application token using client credentials flow
    token, err := c.authClient.GetApplicationToken(
        ctx,
        os.Getenv("CLIENT_ID"),
        os.Getenv("CLIENT_SECRET"),
    )
    if err != nil {
        return nil, fmt.Errorf("failed to get application token: %w", err)
    }

    // Create request with token
    req, _ := http.NewRequestWithContext(ctx, "GET", c.baseURL+"/v1/resource", nil)
    req.Header.Set("Authorization", "Bearer "+token)
    req.Header.Set("Content-Type", "application/json")

    // Inject trace context for distributed tracing
    cotel.InjectHTTPContext(&req.Header, ctx)

    resp, err := c.httpClient.Do(req)
    // ... handle response
}
```

### Common Headers

| Header | Purpose | Example |
|--------|---------|---------|
| `Authorization` | Bearer token for authentication | `Bearer eyJhbG...` |
| `X-Organization-Id` | Organization context for multi-tenancy | UUID |
| `X-Ledger-Id` | Ledger context (when applicable) | UUID |

### Organization ID Middleware Pattern

```go
// adapters/http/in/middlewares.go
const OrgIDHeaderParameter = "X-Organization-Id"

func ParseHeaderParameters(c *fiber.Ctx) error {
    headerParam := c.Get(OrgIDHeaderParameter)
    if headerParam == "" {
        return chttp.WithError(c, ErrMissingOrganizationID)
    }

    parsedUUID, err := uuid.Parse(headerParam)
    if err != nil {
        return chttp.WithError(c, ErrInvalidOrganizationID)
    }

    c.Locals(OrgIDHeaderParameter, parsedUUID)
    return c.Next()
}
```

### Complete Route Example with Headers

```go
// Route with auth + header parsing
f.Post("/v1/packages",
    auth.Authorize(applicationName, "packages", "post"),
    ParseHeaderParameters,
    handler.CreatePackage)
```

### What not to Do

```go
// FORBIDDEN: Hardcoded tokens
req.Header.Set("Authorization", "Bearer hardcoded-token-here")  // never

// FORBIDDEN: Skipping auth on protected endpoints
f.Post("/v1/sensitive-data", handler.Create)  // Missing auth.Authorize

// FORBIDDEN: Using wrong application name
auth.Authorize("wrong-app-name", "resource", "post")  // Must match identity registration

// FORBIDDEN: Direct calls to plugin-auth API
http.Post("http://plugin-auth:4000/v1/authorize", ...)  // Use lib-auth instead

// CORRECT: Always use lib-auth for auth operations
auth.Authorize(applicationName, "resource", "post")
token, _ := auth.GetApplicationToken(ctx, clientID, clientSecret)
```

### Testing with Auth Disabled

For local development and testing, disable auth via environment:

```bash
PLUGIN_AUTH_ENABLED=false
```

When disabled, `auth.Authorize()` middleware calls `next()` without validation.

---

## License Manager Integration (MANDATORY)

All licensed plugins/products **MUST** integrate with the License Manager system for license validation. Services use `lib-license-go` to validate licenses against the Lerian backend, with support for both global and multi-organization modes.

### Architecture Overview

```text
┌─────────────────────────────────────────────────────────────────────┐
│                       LICENSE MANAGER                               │
├─────────────────────────────────────────────────────────────────────┤
│  Lerian License Backend (AWS API Gateway)                           │
│  - Validates license keys                                           │
│  - Returns plugin entitlements                                      │
│  - Supports global and per-organization licenses                    │
└─────────────────────────────────────────────────────────────────────┘
                                    ▲
                                    │ HTTPS API
                                    │
┌───────────────────────────────────┴───────────────────────────────────┐
│                           lib-license-go                              │
│  (Go library - Fiber middleware + gRPC interceptors)                  │
│  - Ristretto in-memory cache                                          │
│  - Weekly background refresh                                          │
│  - Startup validation (fail-fast)                                     │
└───────────────────────────────────┬───────────────────────────────────┘
                                    │ import
                                    ▼
┌───────────────────────────────────────────────────────────────────────┐
│  Licensed Services (plugin-fees, reporter, etc.)                      │
└───────────────────────────────────────────────────────────────────────┘
```

**Key Concepts:**
- **Global Mode**: Single license key validates entire plugin (use `ORGANIZATION_IDS=global`)
- **Multi-Org Mode**: Per-organization license validation via `X-Organization-Id` header
- **Fail-Fast**: Service panics at startup if no valid license found

### Required Import

```go
import (
    libLicense "github.com/LerianStudio/lib-license-go/v2/middleware"
)
```

### Required Environment Variables

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `LICENSE_KEY` | string | License key for this plugin | `lic_xxxxxxxxxxxx` |
| `ORGANIZATION_IDS` | string | Comma-separated org IDs or "global" | `org1,org2` or `global` |

### Configuration Struct

```go
// bootstrap/config.go
type Config struct {
    // ... other fields ...

    // License Manager
    LicenseKey      string `env:"LICENSE_KEY"`
    OrganizationIDs string `env:"ORGANIZATION_IDS"`
}
```

### Bootstrap Integration

```go
// bootstrap/config.go
import (
    libLicense "github.com/LerianStudio/lib-license-go/v2/middleware"
)

func InitServersWithOptions(opts ...Option) (*Service, error) {
    libCommons.InitLocalEnvConfig()

    cfg := &Config{}
    if err := env.Parse(cfg); err != nil {
        return nil, fmt.Errorf("parse config: %w", err)
    }

    logger, err := czap.New(czap.Config{...})
    // ... telemetry, database initialization ...

    // Initialize License Manager client
    licenseClient := libLicense.NewLicenseClient(
        constant.ApplicationName,  // e.g., "plugin-fees"
        cfg.License.Key,
        cfg.License.OrganizationIDs,
        &logger,
    )

    // Pass license client to router
    httpApp := httpin.NewRouter(logger, tl, auth, licenseClient, handlers...)

    // ... rest of initialization ...
}
```

### Router Setup with License Middleware

```go
// adapters/http/in/routes.go
import (
    chttp "github.com/LerianStudio/lib-commons/v4/commons/net/http"
    libLicense "github.com/LerianStudio/lib-license-go/v2/middleware"
)

func NewRoutes(lg clog.Logger, tl *cotel.Telemetry, handler *YourHandler, lc *libLicense.LicenseClient) *fiber.App {
    f := fiber.New(fiber.Config{
        DisableStartupMessage: true,
        ErrorHandler: func(ctx *fiber.Ctx, err error) error {
            return chttp.HandleFiberError(ctx, err)
        },
    })

    // Middleware chain (v4 order)
    f.Use(recover.New())
    f.Use(cors.New())

    // License middleware - applies GLOBALLY (must be early in chain)
    f.Use(lc.Middleware())

    // Routes
    v1 := f.Group("/v1")
    v1.Post("/resources", handler.Create)
    v1.Get("/resources", handler.List)

    // Health and version (automatically skipped by license middleware)
    f.Get("/health", chttp.Ping)
    f.Get("/version", chttp.Version)

    return f
}
```

**Note:** License middleware should be applied early in the middleware chain. It automatically skips `/health`, `/version`, and `/swagger/` paths.

### Service Integration with License Shutdown

```go
// bootstrap/service.go
// License manager shutdown is integrated into Service.Shutdown()
func (svc *Service) Shutdown(ctx context.Context) {
    svc.logger.Log(ctx, clog.LevelInfo, "Shutting down...")

    if err := svc.app.ShutdownWithContext(ctx); err != nil {
        svc.logger.Log(ctx, clog.LevelError, "HTTP shutdown error",
            clog.Err(err))
    }

    // Stop license manager background refresh
    if svc.licenseClient != nil {
        svc.licenseClient.Stop()
    }

    if err := svc.telemetry.Shutdown(ctx); err != nil {
        svc.logger.Log(ctx, clog.LevelError, "Telemetry shutdown error",
            clog.Err(err))
    }

    _ = svc.logger.Sync(ctx)
}
```

### Default Skip Paths

The license middleware automatically skips validation for:

| Path | Reason |
|------|--------|
| `/health` | Health checks must always respond |
| `/version` | Version endpoint is public |
| `/swagger/` | API documentation is public |

### gRPC Integration (If Applicable)

```go
// For gRPC services
import (
    "google.golang.org/grpc"
    libLicense "github.com/LerianStudio/lib-license-go/v2/middleware"
)

func NewGRPCServer(licenseClient *libLicense.LicenseClient) *grpc.Server {
    server := grpc.NewServer(
        grpc.UnaryInterceptor(licenseClient.UnaryServerInterceptor()),
        grpc.StreamInterceptor(licenseClient.StreamServerInterceptor()),
    )

    // Register your services
    pb.RegisterYourServiceServer(server, &yourServiceImpl{})

    return server
}
```

### Middleware Behavior

| Mode | Startup | Per-Request |
|------|---------|-------------|
| Global (`ORGANIZATION_IDS=global`) | Validates license, panics if invalid | Skips validation, calls `next()` |
| Multi-Org | Validates all orgs, panics if none valid | Validates `X-Organization-Id` header |

### Error Codes

| Code | HTTP | Description |
|------|------|-------------|
| `LCS-0001` | 500 | Internal server error during validation |
| `LCS-0002` | 400 | No organization IDs configured |
| `LCS-0003` | 403 | No valid licenses found for any organization |
| `LCS-0010` | 400 | Missing `X-Organization-Id` header |
| `LCS-0011` | 400 | Unknown organization ID |
| `LCS-0012` | 403 | Failed to validate organization license |
| `LCS-0013` | 403 | Organization license is invalid or expired |

### What not to Do

```go
// FORBIDDEN: Hardcoded license keys
licenseClient := libLicense.NewLicenseClient(appName, "hardcoded-key", orgIDs, &logger)  // never

// FORBIDDEN: Skipping license middleware on licensed routes
f.Post("/v1/paid-feature", handler.Create)  // Missing lc.Middleware()

// FORBIDDEN: Not stopping license manager on shutdown
// svc.Shutdown(ctx) without calling licenseClient.Stop()

// CORRECT: Always use environment variables and integrate shutdown
licenseClient := libLicense.NewLicenseClient(appName, cfg.License.Key, cfg.License.OrganizationIDs, &logger)
// In Shutdown(): licenseClient.Stop()
```

### Testing with License Disabled

For local development without license validation, you can omit the license client initialization or use a mock. The service will panic at startup if `LICENSE_KEY` is set but invalid.

**Tip:** For development, either:
1. Use a valid development license key
2. Comment out the license middleware during local development
3. Use the development license server: `IS_DEVELOPMENT=true`

---

## Data Transformation: ToEntity/FromEntity (MANDATORY)

All database models **MUST** implement transformation methods to/from domain entities.

### Pattern

```go
// internal/adapters/postgres/user/user.postgresql.go

// UserPostgreSQLModel is the database representation
type UserPostgreSQLModel struct {
    ID        string         `db:"id"`
    Email     string         `db:"email"`
    Name      string         `db:"name"`
    Status    string         `db:"status"`
    CreatedAt time.Time      `db:"created_at"`
    UpdatedAt time.Time      `db:"updated_at"`
    DeletedAt sql.NullTime   `db:"deleted_at"`
}

// ToEntity converts database model to domain entity
func (m *UserPostgreSQLModel) ToEntity() *domain.User {
    var deletedAt *time.Time
    if m.DeletedAt.Valid {
        deletedAt = &m.DeletedAt.Time
    }

    return &domain.User{
        ID:        domain.UserID(m.ID),
        Email:     domain.Email(m.Email),
        Name:      m.Name,
        Status:    domain.UserStatus(m.Status),
        CreatedAt: m.CreatedAt,
        UpdatedAt: m.UpdatedAt,
        DeletedAt: deletedAt,
    }
}

// FromEntity converts domain entity to database model
func (m *UserPostgreSQLModel) FromEntity(u *domain.User) {
    m.ID = string(u.ID)
    m.Email = string(u.Email)
    m.Name = u.Name
    m.Status = string(u.Status)
    m.CreatedAt = u.CreatedAt
    m.UpdatedAt = u.UpdatedAt
    if u.DeletedAt != nil {
        m.DeletedAt = sql.NullTime{Time: *u.DeletedAt, Valid: true}
    }
}
```

### Why This Matters

- **Layer isolation**: Domain doesn't know about database concerns
- **Testability**: Domain entities can be tested without database
- **Flexibility**: Database schema can change without affecting domain
- **Type safety**: Explicit conversions prevent accidental mixing

---

## Error Codes Convention (MANDATORY)

Each service **MUST** define error codes with a service-specific prefix.

### Service Prefixes

| Service | Prefix | Example |
|---------|--------|---------|
| Lerian | LRN | LRN-0001 |
| Plugin-Fees | FEE | FEE-0001 |
| Plugin-Auth | AUT | AUT-0001 |
| Platform | PLT | PLT-0001 |

### Error Code Structure

```go
// pkg/constant/errors.go
package constant

const (
    ErrCodeInvalidInput     = "PLT-0001"
    ErrCodeNotFound         = "PLT-0002"
    ErrCodeUnauthorized     = "PLT-0003"
    ErrCodeForbidden        = "PLT-0004"
    ErrCodeConflict         = "PLT-0005"
    ErrCodeInternalError    = "PLT-0006"
    ErrCodeValidationFailed = "PLT-0007"
)

// Error definitions with messages
var (
    ErrInvalidInput = &BusinessError{
        Code:    ErrCodeInvalidInput,
        Message: "Invalid input provided",
    }
    ErrNotFound = &BusinessError{
        Code:    ErrCodeNotFound,
        Message: "Resource not found",
    }
)
```

### Business Error Type

```go
// pkg/errors.go
type BusinessError struct {
    Code    string `json:"code"`
    Message string `json:"message"`
    Details any    `json:"details,omitempty"`
}

func (e *BusinessError) Error() string {
    return fmt.Sprintf("[%s] %s", e.Code, e.Message)
}

func ValidateBusinessError(err *BusinessError, entityType string, args ...any) error {
    // Format error with entity context
    return &BusinessError{
        Code:    err.Code,
        Message: fmt.Sprintf(err.Message, args...),
        Details: map[string]string{"entity": entityType},
    }
}
```

---

## Error Handling

### Rules

```go
// always check errors
if err != nil {
    return fmt.Errorf("context: %w", err)
}

// always wrap errors with context
if err != nil {
    return fmt.Errorf("failed to create user %s: %w", userID, err)
}

// Use custom error types for domain errors
var ErrUserNotFound = errors.New("user not found")

// Check specific errors with errors.Is
if errors.Is(err, ErrUserNotFound) {
    return nil, status.Error(codes.NotFound, "user not found")
}
```

### Forbidden

```go
// never use panic for business logic
panic(err) // FORBIDDEN

// never ignore errors
result, _ := doSomething() // FORBIDDEN

// never return nil error without checking
return nil, nil // SUSPICIOUS - check if error is possible
```

---

## Function Design (MANDATORY)

**Single Responsibility Principle (SRP):** Each function MUST have exactly ONE responsibility.

### Rules

| Rule | Description |
|------|-------------|
| **One responsibility per function** | A function should do ONE thing and do it well |
| **Max 20-30 lines** | If longer, break into smaller functions |
| **One level of abstraction** | Don't mix high-level and low-level operations |
| **Descriptive names** | Function name should describe its single responsibility |

### Examples

```go
// ❌ BAD - Multiple responsibilities
func ProcessOrder(order Order) error {
    // Validate order
    if order.Items == nil {
        return errors.New("no items")
    }
    // Calculate total
    total := 0.0
    for _, item := range order.Items {
        total += item.Price * float64(item.Quantity)
    }
    // Apply discount
    if order.CouponCode != "" {
        total = total * 0.9
    }
    // Save to database
    db.Save(&order)
    // Send email
    sendEmail(order.CustomerEmail, "Order confirmed")
    return nil
}

// ✅ GOOD - Single responsibility per function
func ProcessOrder(order Order) error {
    if err := validateOrder(order); err != nil {
        return err
    }
    total := calculateTotal(order.Items)
    total = applyDiscount(total, order.CouponCode)
    if err := saveOrder(order, total); err != nil {
        return err
    }
    return notifyCustomer(order.CustomerEmail)
}

func validateOrder(order Order) error {
    if order.Items == nil || len(order.Items) == 0 {
        return errors.New("order must have items")
    }
    return nil
}

func calculateTotal(items []Item) float64 {
    total := 0.0
    for _, item := range items {
        total += item.Price * float64(item.Quantity)
    }
    return total
}

func applyDiscount(total float64, couponCode string) float64 {
    if couponCode != "" {
        return total * 0.9
    }
    return total
}
```

### Signs a Function Has Multiple Responsibilities

| Sign | Action |
|------|--------|
| Multiple `// section` comments | Split at comment boundaries |
| "and" in function name | Split into separate functions |
| More than 3 parameters | Consider parameter object or splitting |
| Nested conditionals > 2 levels | Extract inner logic to functions |
| Function does validation and processing | Separate validation function |

---

## Pagination Patterns

Lerian Studio supports multiple pagination patterns. This section provides **implementation details** for each pattern.

> **Note**: The pagination strategy should be decided during the **TRD (Technical Requirements Document)** phase, not during implementation. See the `ring:pre-dev-trd-creation` skill for the decision workflow. If no TRD exists, consult with the user before implementing.

### Quick Reference

| Pattern | Best For | Query Params | Response Fields |
|---------|----------|--------------|-----------------|
| Cursor-Based | High-volume data, real-time | `cursor`, `limit`, `sort_order` | `next_cursor`, `prev_cursor` |
| Page-Based | Low-volume data | `page`, `limit`, `sort_order` | `page`, `limit` |
| Page-Based + Total | UI needs "Page X of Y" | `page`, `limit`, `sort_order` | `page`, `limit`, `total` |

### Decision Guide (Reference Only)

```
Is this a high-volume entity (>10k records typical)?
├── YES → Use Cursor-Based Pagination
└── no  → Use Page-Based Pagination

Does the user need to jump to arbitrary pages?
├── YES → Use Page-Based Pagination
└── no  → Cursor-Based is fine

Does the UI need to show total count (e.g., "Page 1 of 10")?
├── YES → Use Page-Based with Total Count
└── no  → Standard Page-Based is sufficient
```

---

### Pattern 1: Cursor-Based Pagination (PREFERRED for high-volume)

Use for: Transactions, Operations, Balances, Audit logs, Events

**Query Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `cursor` | string | (none) | Base64-encoded cursor from previous response |
| `limit` | int | 10 | Items per page (max: 100) |
| `sort_order` | string | "asc" | Sort direction: "asc" or "desc" |
| `start_date` | datetime | (calculated) | Filter start date |
| `end_date` | datetime | now | Filter end date |

**Response Structure:**

```json
{
  "items": [...],
  "limit": 10,
  "next_cursor": "eyJpZCI6IjEyMzQ1Njc4Li4uIiwicG9pbnRzX25leHQiOnRydWV9",
  "prev_cursor": "eyJpZCI6IjEyMzQ1Njc4Li4uIiwicG9pbnRzX25leHQiOmZhbHNlfQ=="
}
```

**Handler Implementation:**

```go
func (h *Handler) GetAllTransactions(c *fiber.Ctx) error {
    ctx := c.UserContext()

    ctx, span := telemetry.StartSpan(ctx, "handler.get_all_transactions")
    defer span.End()

    // Parse and validate query parameters
    headerParams, err := chttp.ValidateParameters(c.Queries())
    if err != nil {
        cotel.HandleSpanBusinessErrorEvent(&span, "Invalid parameters", err)
        return chttp.WithError(c, err)
    }

    // Build pagination request (cursor-based)
    pagination := cpostgres.Pagination{
        Limit:     headerParams.Limit,
        SortOrder: headerParams.SortOrder,
        StartDate: headerParams.StartDate,
        EndDate:   headerParams.EndDate,
    }

    // Query with cursor pagination
    items, cursor, err := h.Query.GetAllTransactions(ctx, orgID, ledgerID, *headerParams)
    if err != nil {
        cotel.HandleSpanBusinessErrorEvent(&span, "Query failed", err)
        return chttp.WithError(c, err)
    }

    // Set response with cursor
    pagination.SetItems(items)
    pagination.SetCursor(cursor.Next, cursor.Prev)

    return chttp.OK(c, pagination)
}
```

**Repository Implementation:**

```go
func (r *Repository) FindAll(ctx context.Context, filter chttp.Pagination) ([]Entity, chttp.CursorPagination, error) {

    ctx, span := telemetry.StartSpan(ctx, "postgres.find_all")
    defer span.End()

    // Decode cursor if provided
    var decodedCursor chttp.Cursor
    isFirstPage := true

    if filter.Cursor != "" {
        isFirstPage = false
        decodedCursor, _ = chttp.DecodeCursor(filter.Cursor)
    }

    // Build query with cursor pagination
    query := squirrel.Select("*").From("table_name")
    query, orderUsed := chttp.ApplyCursorPagination(
        query,
        decodedCursor,
        strings.ToUpper(filter.SortOrder),
        filter.Limit,
    )

    // Execute query...
    rows, err := query.RunWith(db).QueryContext(ctx)
    // ... scan rows into items ...

    // Check if there are more items
    hasPagination := len(items) > filter.Limit

    // Paginate records (trim to limit, handle direction)
    items = chttp.PaginateRecords(
        isFirstPage,
        hasPagination,
        decodedCursor.PointsNext || isFirstPage,
        items,
        filter.Limit,
        orderUsed,
    )

    // Calculate cursors for response
    var firstID, lastID string
    if len(items) > 0 {
        firstID = items[0].ID
        lastID = items[len(items)-1].ID
    }

    cursor, _ := chttp.CalculateCursor(
        isFirstPage,
        hasPagination,
        decodedCursor.PointsNext || isFirstPage,
        firstID,
        lastID,
    )

    return items, cursor, nil
}
```

---

### Pattern 2: Page-Based (Offset) Pagination

Use for: Organizations, Ledgers, Assets, Portfolios, Accounts

**Query Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `page` | int | 1 | Page number (1-indexed) |
| `limit` | int | 10 | Items per page (max: 100) |
| `sort_order` | string | "asc" | Sort direction |
| `start_date` | datetime | (calculated) | Filter start date |
| `end_date` | datetime | now | Filter end date |

**Response Structure:**

```json
{
  "items": [...],
  "page": 1,
  "limit": 10
}
```

**Handler Implementation:**

```go
func (h *Handler) GetAllOrganizations(c *fiber.Ctx) error {
    ctx := c.UserContext()

    ctx, span := telemetry.StartSpan(ctx, "handler.get_all_organizations")
    defer span.End()

    headerParams, err := chttp.ValidateParameters(c.Queries())
    if err != nil {
        return chttp.WithError(c, err)
    }

    // Build page-based pagination
    pagination := cpostgres.Pagination{
        Limit:     headerParams.Limit,
        Page:      headerParams.Page,
        SortOrder: headerParams.SortOrder,
        StartDate: headerParams.StartDate,
        EndDate:   headerParams.EndDate,
    }

    // Query with offset pagination (uses ToOffsetPagination())
    items, err := h.Query.GetAllOrganizations(ctx, headerParams.ToOffsetPagination())
    if err != nil {
        return chttp.WithError(c, err)
    }

    pagination.SetItems(items)

    return chttp.OK(c, pagination)
}
```

**Repository Implementation:**

```go
func (r *Repository) FindAll(ctx context.Context, pagination http.Pagination) ([]Entity, error) {
    offset := (pagination.Page - 1) * pagination.Limit

    query := squirrel.Select("*").
        From("table_name").
        OrderBy("id " + pagination.SortOrder).
        Limit(uint64(pagination.Limit)).
        Offset(uint64(offset))

    // Execute query...
    return items, nil
}
```

---

### Pattern 3: Page-Based with Total Count

Use when: Client needs total count for pagination UI (showing "Page 1 of 10")

**Response Structure:**

```json
{
  "items": [...],
  "page": 1,
  "limit": 10,
  "total": 100
}
```

**Note:** Adds a COUNT query overhead. Only use if total is required.

---

### Shared Utilities from lib-commons v4

| Utility | Package (alias) | Purpose |
|---------|---------|---------|
| `Pagination` struct | `cpostgres` | Unified response structure |
| `Cursor` struct | `chttp` | Cursor encoding |
| `DecodeCursor` | `chttp` | Parse cursor from request |
| `ApplyCursorPagination` | `chttp` | Add cursor to SQL query |
| `PaginateRecords` | `chttp` | Trim results, handle direction |
| `CalculateCursor` | `chttp` | Generate next/prev cursors |

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MAX_PAGINATION_LIMIT` | 100 | Maximum allowed limit per request |
| `MAX_PAGINATION_MONTH_DATE_RANGE` | 1 | Default date range in months |

---

## Testing

### Table-Driven Tests (MANDATORY)

```go
func TestCreateUser(t *testing.T) {
    tests := []struct {
        name    string
        input   CreateUserInput
        want    *User
        wantErr error
    }{
        {
            name:  "valid user",
            input: CreateUserInput{Name: "John", Email: "john@example.com"},
            want:  &User{Name: "John", Email: "john@example.com"},
        },
        {
            name:    "invalid email",
            input:   CreateUserInput{Name: "John", Email: "invalid"},
            wantErr: ErrInvalidEmail,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := CreateUser(tt.input)

            if tt.wantErr != nil {
                require.ErrorIs(t, err, tt.wantErr)
                return
            }

            require.NoError(t, err)
            assert.Equal(t, tt.want.Name, got.Name)
        })
    }
}
```

### Test Naming Convention

```text
Test{Unit}_{Scenario}_{ExpectedResult}

Examples:
- TestOrderService_CreateOrder_WithValidItems_ReturnsOrder
- TestOrderService_CreateOrder_WithEmptyItems_ReturnsError
- TestMoney_Add_SameCurrency_ReturnsSum
```

### Edge Case Coverage (MANDATORY)

**Every acceptance criterion MUST have edge case tests beyond the happy path.**

| AC Type | Required Edge Cases | Minimum Count |
|---------|---------------------|---------------|
| Input validation | nil, empty string, boundary values, invalid format, special chars, max length | 3+ |
| CRUD operations | not found, duplicate key, concurrent modification, large payload | 3+ |
| Business logic | zero value, negative numbers, overflow, boundary conditions, invalid state | 3+ |
| Error handling | context timeout, connection refused, invalid response, retry exhausted | 2+ |
| Authentication | expired token, invalid signature, missing claims, revoked token | 2+ |

**Table-Driven Edge Cases Pattern:**

```go
func TestUserService_CreateUser(t *testing.T) {
    tests := []struct {
        name    string
        input   CreateUserInput
        wantErr error
    }{
        // Happy path
        {name: "valid user", input: validInput(), wantErr: nil},
        
        // Edge cases (MANDATORY - minimum 3)
        {name: "nil input", input: CreateUserInput{}, wantErr: ErrInvalidInput},
        {name: "empty email", input: CreateUserInput{Name: "John", Email: ""}, wantErr: ErrEmailRequired},
        {name: "invalid email format", input: CreateUserInput{Name: "John", Email: "invalid"}, wantErr: ErrInvalidEmail},
        {name: "email too long", input: CreateUserInput{Name: "John", Email: strings.Repeat("a", 256) + "@test.com"}, wantErr: ErrEmailTooLong},
        {name: "name with special chars", input: CreateUserInput{Name: "<script>", Email: "test@test.com"}, wantErr: ErrInvalidName},
    }
    // ... test execution
}
```

**Anti-Pattern (FORBIDDEN):**

```go
// ❌ WRONG: Only happy path
func TestUserService_CreateUser(t *testing.T) {
    result, err := service.CreateUser(validInput())
    require.NoError(t, err)  // No edge cases = incomplete test
}
```

### Mock Generation (GoMock - MANDATORY)

```go
// GoMock is the MANDATORY mock framework for all Go projects
//go:generate mockgen -source=repository.go -destination=mocks/mock_repository.go -package=mocks

// For interface in external package:
//go:generate mockgen -destination=mocks/mock_service.go -package=mocks github.com/example/pkg Service
```

---

## Logging

**HARD GATE:** All Go services MUST use lib-commons structured logging. Unstructured logging is FORBIDDEN.

### FORBIDDEN Logging Patterns (CRITICAL - Automatic FAIL)

| Pattern | Why FORBIDDEN | Detection Command |
|---------|---------------|-------------------|
| `fmt.Println()` | No structure, no trace correlation, unsearchable | `grep -rn "fmt.Println" --include="*.go"` |
| `fmt.Printf()` | No structure, no trace correlation, unsearchable | `grep -rn "fmt.Printf" --include="*.go"` |
| `log.Println()` | Standard library logger lacks trace correlation | `grep -rn "log.Println" --include="*.go"` |
| `log.Printf()` | Standard library logger lacks trace correlation | `grep -rn "log.Printf" --include="*.go"` |
| `log.Fatal()` | Exits without graceful shutdown, breaks telemetry flush | `grep -rn "log.Fatal" --include="*.go"` |
| `println()` | Built-in, no structure, debugging only | `grep -rn "println(" --include="*.go"` |

**If any of these patterns are found in production code → REVIEW FAILS. no EXCEPTIONS.**

### Pre-Commit Check (MANDATORY)

Add to `.golangci.yml` or run manually before commit:

```bash
# MUST pass with zero matches before commit
grep -rn "fmt.Println\|fmt.Printf\|log.Println\|log.Printf\|log.Fatal\|println(" --include="*.go" ./internal ./cmd
# Expected output: (nothing - no matches)
```

### Using lib-commons Logger (REQUIRED Pattern)

```go
// CORRECT: Logger is dependency-injected (struct field)
// s.logger clog.Logger  (injected at construction time)

// CORRECT: Log with typed fields (v4 pattern)
s.logger.Log(ctx, clog.LevelInfo, "Processing entity",
    clog.String("entity_id", entityID))
s.logger.Log(ctx, clog.LevelWarn, "Rate limit approaching",
    clog.Int("current", current), clog.Int("limit", limit))
s.logger.Log(ctx, clog.LevelError, "Failed to save entity",
    clog.Err(err))
```

### Migration Examples

```go
// ❌ FORBIDDEN: fmt.Println
fmt.Println("Starting server...")

// ✅ REQUIRED: lib-commons logger with typed fields
s.logger.Log(ctx, clog.LevelInfo, "Starting server",
    clog.String("address", s.serverAddress))

// ❌ FORBIDDEN: fmt.Printf
fmt.Printf("Processing user: %s\n", userID)

// ✅ REQUIRED: lib-commons logger with typed fields
s.logger.Log(ctx, clog.LevelInfo, "Processing user",
    clog.String("user_id", userID))

// ❌ FORBIDDEN: log.Printf
log.Printf("[ERROR] Failed to connect: %v", err)

// ✅ REQUIRED: lib-commons logger with span error
s.logger.Log(ctx, clog.LevelError, "Failed to connect",
    clog.Err(err))
cotel.HandleSpanError(&span, "Connection failed", err)

// ❌ FORBIDDEN: log.Fatal (breaks graceful shutdown)
log.Fatal("Cannot start without config")

// ✅ REQUIRED: return error from InitServersWithOptions (v4 pattern)
return nil, fmt.Errorf("cannot start without config: %w", err)
```

### What not to Log (Sensitive Data)

```go
// FORBIDDEN - sensitive data in structured fields
s.logger.Log(ctx, clog.LevelInfo, "user login", clog.String("password", password))  // NEVER
s.logger.Log(ctx, clog.LevelInfo, "payment", clog.String("card_number", card))      // NEVER
s.logger.Log(ctx, clog.LevelInfo, "auth", clog.String("token", token))              // NEVER
s.logger.Log(ctx, clog.LevelInfo, "user", clog.String("cpf", cpf))                  // NEVER (PII)
```

### golangci-lint Custom Rule (RECOMMENDED)

Add to `.golangci.yml` to automatically fail CI on forbidden patterns:

```yaml
linters-settings:
  forbidigo:
    forbid:
      - p: ^fmt\.Print.*$
        msg: "FORBIDDEN: Use lib-commons logger instead of fmt.Print*"
      - p: ^log\.(Print|Fatal|Panic).*$
        msg: "FORBIDDEN: Use lib-commons logger instead of standard log package"
      - p: ^print$
        msg: "FORBIDDEN: Use lib-commons logger instead of print builtin"
      - p: ^println$
        msg: "FORBIDDEN: Use lib-commons logger instead of println builtin"

linters:
  enable:
    - forbidigo
```

---

## Linting

### golangci-lint Configuration

```yaml
# .golangci.yml
linters:
  enable:
    - errcheck      # Check error handling
    - govet         # Go vet
    - staticcheck   # Static analysis
    - gosimple      # Simplify code
    - ineffassign   # Unused assignments
    - unused        # Unused code
    - gofmt         # Formatting
    - goimports     # Import ordering
    - misspell      # Spelling
    - goconst       # Repeated strings
    - gosec         # Security issues
    - nilerr        # Return nil with non-nil error
```

### Format Commands

```bash
# Format code
gofmt -w .
goimports -w .

# Run linter
golangci-lint run ./...
```

---

## Architecture Patterns

### Hexagonal Architecture (Ports & Adapters)

```text
/internal
  /bootstrap         # Application initialization
    config.go
    service.go         # Service lifecycle, DI, Fiber setup
  /domain            # Business entities (no dependencies)
    user.go
    errors.go
  /services          # Application/Business logic
    /command         # Write operations
    /query           # Read operations
  /adapters          # Implementations (adapters)
    /http/in         # HTTP handlers + routes
    /grpc/in         # gRPC handlers
    /postgres        # PostgreSQL repositories
    /mongodb         # MongoDB repositories
    /redis           # Redis repositories
```

### Interface-Based Abstractions

```go
// Define interface in the package that USES it (not implements)
// /internal/services/command/usecase.go

type UserRepository interface {
    FindByID(ctx context.Context, id uuid.UUID) (*domain.User, error)
    Save(ctx context.Context, user *domain.User) error
}

type UseCase struct {
    UserRepo UserRepository  // Depend on interface
}
```

---

## Directory Structure

The directory structure follows the **Lerian pattern** - a simplified hexagonal architecture without explicit DDD folders.

```text
/cmd
  /app                   # Main application entry
    main.go
/internal
  /bootstrap             # Initialization (config, servers)
    config.go
    service.go           # Service lifecycle, DI, Fiber setup
    grpc.server.go       # (if service uses gRPC)
    rabbitmq.server.go   # (if service uses RabbitMQ)
  /services              # Business logic
    /command             # Write operations (use cases)
    /query               # Read operations (use cases)
  /adapters              # Infrastructure implementations
    /http/in             # HTTP handlers + routes
    /grpc/in             # gRPC handlers
    /grpc/out            # gRPC clients
    /postgres            # PostgreSQL repositories
    /mongodb             # MongoDB repositories
    /redis               # Redis repositories
    /rabbitmq            # RabbitMQ producers/consumers
/pkg
  /constant              # Constants and error codes
  /mmodel                # Shared models
  /net/http              # HTTP utilities
/api                     # OpenAPI/Swagger specs
/migrations              # Database migrations
```

**Key differences from traditional DDD:**
- **No `/internal/domain` folder** - Business entities live in `/pkg/mmodel` or within service files
- **Services are the core** - `/internal/services` contains all business logic (command/query pattern)
- **Adapters are flat** - Database repositories are organized by technology, not by domain

---

## Concurrency Patterns

### Goroutines with Context

```go
func processItems(ctx context.Context, items []Item) error {
    g, ctx := errgroup.WithContext(ctx)

    for _, item := range items {
        item := item // capture variable
        g.Go(func() error {
            select {
            case <-ctx.Done():
                return ctx.Err()
            default:
                return processItem(ctx, item)
            }
        })
    }

    return g.Wait()
}
```

> **When to use `errgroup` vs `cruntime`:**
> - **`errgroup.WithContext`**: Bounded concurrent operations within a single function scope (e.g., parallel processing of a batch). Short-lived, exits when all tasks complete.
> - **`cruntime.SafeGoWithContextAndComponent`**: Long-lived goroutines (HTTP servers, consumers, background polling, cache cleanup). Has panic recovery, crash policies, and observability.
> - The FORBIDDEN rule for raw `go func(){}()` applies to ALL production goroutines outside of errgroup.

### Channel Patterns

```go
// Worker pool
func workerPool(ctx context.Context, jobs <-chan Job, results chan<- Result) {
    for {
        select {
        case <-ctx.Done():
            return
        case job, ok := <-jobs:
            if !ok {
                return
            }
            results <- process(job)
        }
    }
}
```

---

## RabbitMQ Worker Pattern

When the application includes async processing (API+Worker or Worker Only), follow this pattern.

### Application Types

| Type | Characteristics | Components |
|------|----------------|------------|
| **API Only** | HTTP endpoints, no async processing | Handlers, Services, Repositories |
| **API + Worker** | HTTP endpoints + async message processing | All above + Consumers, Producers |
| **Worker Only** | No HTTP, only message processing | Consumers, Services, Repositories |

### Architecture Overview

```text
┌─────────────────────────────────────────────────────────────┐
│  Service Bootstrap                                          │
│  ├── HTTP Server (Fiber)         ← API endpoints           │
│  ├── RabbitMQ Consumer           ← Event-driven workers    │
│  └── Redis Consumer (optional)   ← Scheduled polling       │
└─────────────────────────────────────────────────────────────┘
```

### Core Components

```go
// ConsumerRoutes - Multi-queue consumer manager
type ConsumerRoutes struct {
    conn              *RabbitMQConnection
    routes            map[string]QueueHandlerFunc  // Queue name → Handler
    NumbersOfWorkers  int                          // Workers per queue (default: 5)
    NumbersOfPrefetch int                          // QoS prefetch (default: 10)
    Logger
    Telemetry
}

// Handler function signature
type QueueHandlerFunc func(ctx context.Context, body []byte) error
```

### Worker Configuration

| Config | Default | Purpose |
|--------|---------|---------|
| `RABBITMQ_NUMBERS_OF_WORKERS` | 5 | Concurrent workers per queue |
| `RABBITMQ_NUMBERS_OF_PREFETCH` | 10 | Messages buffered per worker |
| `RABBITMQ_CONSUMER_USER` | - | Separate credentials for consumer |
| `RABBITMQ_{QUEUE}_QUEUE` | - | Queue name per handler |

**Formula:** `Total buffered = Workers × Prefetch` (e.g., 5 × 10 = 50 messages)

### Handler Registration

```go
// Register handlers per queue
func (mq *MultiQueueConsumer) RegisterRoutes(routes *ConsumerRoutes) {
    routes.Register(os.Getenv("RABBITMQ_BALANCE_CREATE_QUEUE"), mq.handleBalanceCreate)
    routes.Register(os.Getenv("RABBITMQ_TRANSACTION_QUEUE"), mq.handleTransaction)
}
```

### Handler Implementation

```go
func (mq *MultiQueueConsumer) handleBalanceCreate(ctx context.Context, body []byte) error {
    // 1. Deserialize message
    var message QueueMessage
    if err := json.Unmarshal(body, &message); err != nil {
        return fmt.Errorf("unmarshal message: %w", err)
    }

    // 2. Execute business logic
    if err := mq.UseCase.CreateBalance(ctx, message); err != nil {
        return fmt.Errorf("create balance: %w", err)
    }

    // 3. Success → Ack automatically
    return nil
}
```

### Message Acknowledgment

| Result | Action | Effect |
|--------|--------|--------|
| `return nil` | `msg.Ack(false)` | Message removed from queue |
| `return err` | `msg.Nack(false, true)` | Message requeued |

### Worker Lifecycle

```text
RunConsumers()
├── For each registered queue:
│   ├── EnsureChannel() with exponential backoff
│   ├── Set QoS (prefetch)
│   ├── Start Consume()
│   └── Spawn N worker goroutines
│       └── startWorker(workerID, queue, handler, messages)

startWorker():
├── for msg := range messages:
│   ├── Extract/generate TraceID from headers
│   ├── Create context with HeaderID
│   ├── Start OpenTelemetry span
│   ├── Call handler(ctx, msg.Body)
│   ├── On success: msg.Ack(false)
│   └── On error: log + msg.Nack(false, true)
```

### Exponential Backoff with Jitter

```go
const (
    MaxRetries     = 5
    InitialBackoff = 500 * time.Millisecond
    MaxBackoff     = 10 * time.Second
    BackoffFactor  = 2.0
)

// Full jitter: random delay in [0, baseDelay]
func FullJitter(baseDelay time.Duration) time.Duration {
    jitter := time.Duration(rand.Float64() * float64(baseDelay))
    if jitter > MaxBackoff {
        return MaxBackoff
    }
    return jitter
}
```

### Producer Implementation

```go
func (p *ProducerRepository) Publish(ctx context.Context, exchange, routingKey string, message []byte) error {
    if err := p.EnsureChannel(); err != nil {
        return fmt.Errorf("ensure channel: %w", err)
    }

    headers := amqp.Table{
        "HeaderID": GetRequestID(ctx),
    }
    InjectTraceHeaders(ctx, &headers)

    return p.channel.Publish(
        exchange,
        routingKey,
        false,
        false,
        amqp.Publishing{
            ContentType:  "application/json",
            DeliveryMode: amqp.Persistent,
            Headers:      headers,
            Body:         message,
        },
    )
}
```

### Message Format

```go
type QueueMessage struct {
    OrganizationID uuid.UUID   `json:"organizationId"`
    LedgerID       uuid.UUID   `json:"ledgerId"`
    AuditID        uuid.UUID   `json:"auditId"`
    Data           []QueueData `json:"data"`
}

type QueueData struct {
    ID    uuid.UUID       `json:"id"`
    Value json.RawMessage `json:"value"`
}
```

### Service Bootstrap (API + Worker)

```go
type Service struct {
    app       *fiber.App
    consumer  *MultiQueueConsumer
    logger    clog.Logger
    telemetry *cotel.Telemetry
}

func (svc *Service) Run(ctx context.Context) {
    // HTTP Server
    cruntime.SafeGoWithContextAndComponent(
        ctx, svc.logger, "bootstrap", "http-server",
        cruntime.CrashProcess,
        func(goCtx context.Context) {
            if err := svc.app.Listen(svc.serverAddress); err != nil {
                svc.logger.Log(goCtx, clog.LevelError, "HTTP server failed",
                    clog.Err(err))
            }
        },
    )

    // RabbitMQ Consumer
    cruntime.SafeGoWithContextAndComponent(
        ctx, svc.logger, "bootstrap", "rabbitmq-consumer",
        cruntime.CrashProcess,
        func(goCtx context.Context) {
            svc.consumer.RunConsumers(goCtx)
        },
    )
}
```

### Directory Structure for Workers

```text
/internal
  /adapters
    /rabbitmq
      consumer.go      # ConsumerRoutes, worker pool
      producer.go      # ProducerRepository
      connection.go    # Connection management
  /bootstrap
    rabbitmq.server.go # MultiQueueConsumer, handler registration
    service.go         # Service orchestration
/pkg
  /utils
    jitter.go          # Backoff utilities
```

### Worker Checklist

- [ ] Handlers are idempotent (safe to process duplicates)
- [ ] Manual Ack enabled (`autoAck: false`)
- [ ] Error handling returns error (triggers Nack)
- [ ] Context propagation with HeaderID
- [ ] OpenTelemetry spans for tracing
- [ ] Exponential backoff for connection recovery
- [ ] Graceful shutdown respects context cancellation
- [ ] Separate credentials for consumer vs producer

---

## Safe Goroutines (cruntime)

All goroutines in production code **MUST** be launched via `cruntime.SafeGoWithContextAndComponent`. Raw `go func(){}()` is **FORBIDDEN**.

### MANDATORY Pattern

```go
cruntime.SafeGoWithContextAndComponent(
    ctx,
    logger,
    "component",       // e.g. "bootstrap", "auth", "worker"
    "goroutine-name",  // e.g. "server-runner", "cache-cleanup"
    cruntime.CrashProcess, // or cruntime.KeepRunning
    func(goCtx context.Context) {
        // goroutine body
    },
)
```

### Policies

| Policy | Behavior | Use When |
|--------|----------|----------|
| `cruntime.CrashProcess` | Logs panic + exits process | Critical goroutines (server, main loop) |
| `cruntime.KeepRunning` | Logs panic + continues | Background tasks (cache cleanup, polling) |

### FORBIDDEN vs CORRECT

```go
// FORBIDDEN: Raw goroutines in production code
go func() { ... }()  // No panic recovery, no context, no observability

// CORRECT: Always use cruntime
cruntime.SafeGoWithContextAndComponent(ctx, logger, "comp", "name", policy, fn)
```

---

## Assertions (cassert)

Domain validation **MUST** use `cassert` which returns errors and NEVER panics.

### Usage Pattern

```go
asserter := cassert.New(ctx, nil, constants.ApplicationName, "operation_name")

// Nil check
if err := asserter.NotNil(ctx, value, "field is required"); err != nil {
    return fmt.Errorf("validation: %w", err)
}

// Empty string check
if err := asserter.NotEmpty(ctx, strings.TrimSpace(field), "field must not be empty"); err != nil {
    return fmt.Errorf("validation: %w", err)
}

// Conditional assertion
if err := asserter.That(ctx, amount > 0, "amount must be positive"); err != nil {
    return fmt.Errorf("validation: %w", err)
}
```

### FORBIDDEN vs CORRECT

```go
// FORBIDDEN: panic for validation
if value == nil {
    panic("value is required")  // NEVER
}

// CORRECT: cassert returns error
if err := asserter.NotNil(ctx, value, "value is required"); err != nil {
    return err
}
```

---

## Typed Metrics (cmetrics)

Custom metrics **MUST** use `cmetrics` for typed metric definitions.

### Metric Definitions

```go
// Define metrics as package-level variables
var metricOperationTotal = cmetrics.Metric{
    Name:        "svc.operation.total",
    Unit:        "1",
    Description: "Total operations by outcome.",
}

var metricOperationLatency = cmetrics.Metric{
    Name:        "svc.operation.latency",
    Unit:        "ms",
    Description: "Operation latency in milliseconds.",
    Buckets:     []float64{10, 50, 100, 250, 500, 1000, 2500, 5000},
}
```

### Usage via MetricsFactory

```go
factory, err := cmetrics.NewMetricsFactory(meter, logger)

counter, err := factory.Counter(metricOperationTotal)
_ = counter.WithLabels(map[string]string{"outcome": "success"}).AddOne(ctx)

histogram, err := factory.Histogram(metricOperationLatency)
_ = histogram.WithLabels(map[string]string{"system": "db"}).Record(ctx, durationMs)
```

### Naming Convention

`{service-prefix}.{subsystem}.{metric_name}`

---

## Safe Math (commons/safe)

Financial calculations **MUST** use `csafe` to prevent panics on zero division.

```go
// MANDATORY for financial calculations
result, err := csafe.Divide(numerator, denominator)
if err != nil {
    // err == csafe.ErrDivisionByZero
}

// With rounding
result, err := csafe.DivideRound(numerator, denominator, 2)

// Fallback to zero (for display, not transactions)
result := csafe.DivideOrZero(numerator, denominator)
```

---

## Crypto (commons/crypto)

Sensitive data storage **MUST** use `ccrypto` for encryption and hashing.

```go
// AES-GCM encryption for sensitive fields
crypto := &ccrypto.Crypto{Key: os.Getenv("ENCRYPTION_KEY")}
if err := crypto.InitializeCipher(); err != nil {
    return err
}

encrypted, err := crypto.Encrypt(&plainText)
decrypted, err := crypto.Decrypt(&encrypted)

// HMAC-SHA256 hashing (for fingerprints, cache keys)
hash := crypto.GenerateHash(&value)
```

---

## Backoff (commons/backoff)

Retry logic **MUST** use `cbackoff` for exponential backoff with jitter.

```go
// Exponential backoff with jitter for retries
delay := cbackoff.Exponential(attempt, baseDelay, maxDelay)
jitteredDelay := cbackoff.FullJitter(delay)
```

---

## Circuit Breaker (MANDATORY for External Calls)

All outbound calls to external services **MUST** use circuit breakers to prevent cascading failures.

### Using sony/gobreaker (Recommended for Adapters)

```go
import "github.com/sony/gobreaker/v2"

// Initialize per-adapter circuit breaker
cb := gobreaker.NewCircuitBreaker[any](gobreaker.Settings{
    Name:        "midaz-ledger",
    MaxRequests: 3,                    // half-open: allow 3 test requests
    Interval:    30 * time.Second,     // closed: reset counts every 30s
    Timeout:     30 * time.Second,     // open → half-open after 30s
    ReadyToTrip: func(counts gobreaker.Counts) bool {
        return counts.ConsecutiveFailures >= 5
    },
})

// Wrap external calls
result, err := cb.Execute(func() (any, error) {
    return httpClient.Do(req)
})
if err != nil {
    if errors.Is(err, gobreaker.ErrOpenState) {
        // Circuit is open — fail fast, do not call external service
        return nil, fmt.Errorf("service unavailable (circuit open): %w", err)
    }
    return nil, fmt.Errorf("external call failed: %w", err)
}
```

### Using lib-commons Circuit Breaker Manager

```go
import ccb "github.com/LerianStudio/lib-commons/v4/commons/circuitbreaker"

// Create manager for multiple breakers
manager := ccb.NewManager(logger)

// Register breakers with preset configs
manager.Register("midaz", ccb.HTTPServiceConfig())
manager.Register("crm", ccb.ConservativeConfig())
manager.Register("jd-spb", ccb.AggressiveConfig())

// Execute with breaker
result, err := manager.Execute("midaz", func() (any, error) {
    return client.Call(ctx, req)
})
```

### Preset Configurations

| Preset | Max Failures | Timeout | Use When |
|--------|-------------|---------|----------|
| `DefaultConfig()` | 5 | 30s | General purpose |
| `AggressiveConfig()` | 3 | 15s | Fast failure detection (payment gateways) |
| `ConservativeConfig()` | 10 | 60s | High tolerance (batch jobs) |
| `HTTPServiceConfig()` | 5 | 30s | HTTP service-to-service calls |
| `DatabaseConfig()` | 3 | 45s | Database connections |

### Health Checker Integration

```go
// Automatic health probes with recovery
healthChecker := ccb.NewHealthChecker(manager, 10*time.Second, 5*time.Second, logger)
healthChecker.Register("midaz", func(ctx context.Context) error {
    return client.Ping(ctx)
})
healthChecker.Start(ctx)
defer healthChecker.Stop()
```

### Adapter Error Pattern

```go
// Convert breaker errors to domain-specific adapter errors
type AdapterError struct {
    AdapterName string
    Code        string // e.g. "SVC-1000" (service unavailable)
    Operation   string
    Err         error
}

func (e *AdapterError) Error() string {
    return fmt.Sprintf("[%s] %s %s: %s", e.Code, e.AdapterName, e.Operation, e.Err)
}

func (e *AdapterError) Unwrap() error { return e.Err }
```

### What not to Do

```go
// FORBIDDEN: External calls without circuit breaker
resp, err := http.Get("http://external-service/api")  // No protection

// FORBIDDEN: Global circuit breaker for all services
var globalBreaker = gobreaker.NewCircuitBreaker(...)  // Each service needs its own

// CORRECT: Per-adapter breaker with appropriate config
midazBreaker := gobreaker.NewCircuitBreaker[any](gobreaker.Settings{Name: "midaz", ...})
crmBreaker := gobreaker.NewCircuitBreaker[any](gobreaker.Settings{Name: "crm", ...})
```

---

## Outbox Pattern (commons/outbox)

Event-driven services **MUST** use the outbox pattern via `coutbox` for reliable event publishing.

```go
// Reliable event publishing via database-backed outbox
// Prevents message loss when broker is unavailable
outboxRepo := coutbox.NewPostgresRepository(db, coutbox.Config{
    SchemaName: "public",
    TableName:  "outbox_events",
})

event := coutbox.Event{
    AggregateType: "transfer",
    AggregateID:   transferID,
    EventType:     "transfer.completed",
    Payload:       payload,
}

if err := outboxRepo.Store(ctx, event); err != nil {
    return err
}
// Dispatcher polls outbox table and publishes to broker
```

---

## Standards Compliance Output Format

When producing a Standards Compliance report (used by ring:dev-refactor workflow), follow these output formats:

### If all Categories Are Compliant

```markdown
## Standards Compliance

### Lerian/Ring Standards Comparison

#### Bootstrap & Initialization
| Category | Current Pattern | Expected Pattern | Status | Evidence |
|----------|----------------|------------------|--------|----------|
| Config Struct | Nested `Config` struct with `envPrefix` tags | Nested structs with `envPrefix` tags | ✅ Compliant | `internal/bootstrap/config.go:15` |
| Config Loading | `libCommons.InitLocalEnvConfig()` + `env.Parse(&cfg)` | `libCommons.InitLocalEnvConfig()` + `env.Parse()` | ✅ Compliant | `internal/bootstrap/config.go:42` |
| Logger Init | `czap.New(czap.Config{...})` | `czap.New()` (bootstrap only) | ✅ Compliant | `internal/bootstrap/config.go:45` |
| Telemetry Init | `cotel.NewTelemetry()` + `tl.ApplyGlobals()` | `cotel.NewTelemetry()` + `ApplyGlobals()` | ✅ Compliant | `internal/bootstrap/config.go:48` |
| ... | ... | ... | ✅ Compliant | ... |

#### Context & Tracking
| Category | Current Pattern | Expected Pattern | Status | Evidence |
|----------|----------------|------------------|--------|----------|
| ... | ... | ... | ✅ Compliant | ... |

#### Infrastructure
| Category | Current Pattern | Expected Pattern | Status | Evidence |
|----------|----------------|------------------|--------|----------|
| ... | ... | ... | ✅ Compliant | ... |

#### Domain Patterns
| Category | Current Pattern | Expected Pattern | Status | Evidence |
|----------|----------------|------------------|--------|----------|
| ... | ... | ... | ✅ Compliant | ... |

### Verdict: ✅ FULLY COMPLIANT

No migration actions required. All categories verified against Lerian/Ring Go Standards.
```

### If any Category Is Non-Compliant

```markdown
## Standards Compliance

### Lerian/Ring Standards Comparison

#### Bootstrap & Initialization
| Category | Current Pattern | Expected Pattern | Status | File/Location |
|----------|----------------|------------------|--------|---------------|
| Config Struct | Scattered `os.Getenv()` calls | Nested structs with `envPrefix` tags | ⚠️ Non-Compliant | `cmd/api/main.go` |
| Config Loading | Manual env parsing | `libCommons.InitLocalEnvConfig()` + `env.Parse()` | ⚠️ Non-Compliant | `cmd/api/main.go:25` |
| Logger Init | `czap.New(czap.Config{...})` | `czap.New()` (bootstrap only) | ✅ Compliant | `cmd/api/main.go:30` |
| ... | ... | ... | ... | ... |

#### Context & Tracking
| Category | Current Pattern | Expected Pattern | Status | File/Location |
|----------|----------------|------------------|--------|---------------|
| ... | ... | ... | ... | ... |

### Verdict: ⚠️ NON-COMPLIANT (X of Y categories)

### Required Changes for Compliance

1. **Config Struct Migration**
   - Replace: Direct `os.Getenv()` calls scattered across files
   - With: Nested `Config` struct with `envPrefix` tags in `/internal/bootstrap/config.go`
   - Import: `libCommons "github.com/LerianStudio/lib-commons/v4/commons"`
   - Usage: `libCommons.InitLocalEnvConfig()` + `env.Parse(&cfg)`
   - Files affected: `cmd/api/main.go`, `internal/service/user.go`

2. **Logger Migration**
   - Replace: Custom logger or `log.Println()`
   - With: lib-commons v4 structured logger
   - Bootstrap import: `czap "github.com/LerianStudio/lib-commons/v4/commons/zap"` (initialization)
   - Application import: `clog "github.com/LerianStudio/lib-commons/v4/commons/log"` (interface for logging calls)
   - Bootstrap usage: `logger, err := czap.New(czap.Config{...})` (returns `clog.Logger` interface)
   - Application usage: `s.logger.Log(ctx, clog.LevelInfo, "msg", clog.String("key", "val"))`
   - Files affected: [list files]

3. **Telemetry Migration**
   - Replace: No tracing or custom tracing
   - With: OpenTelemetry integration via lib-commons v4
   - Import: `cotel "github.com/LerianStudio/lib-commons/v4/commons/opentelemetry"`
   - Usage: `tl, err := cotel.NewTelemetry(cotel.TelemetryConfig{...})` + `tl.ApplyGlobals()`
   - Files affected: [list files]

4. **[Next Category] Migration**
   - Replace: ...
   - With: ...
   - Import: ...
   - Usage: ...
```

**CRITICAL:** The comparison table is not optional. It serves as:
1. **Evidence** that each category was actually checked
2. **Documentation** for the codebase's compliance status
3. **Audit trail** for future refactors

---

## Checklist

Before submitting Go code, verify:

- [ ] Using lib-commons v4 for infrastructure
- [ ] Configuration loaded via `libCommons.InitLocalEnvConfig()` + `env.Parse()` with nested config structs
- [ ] Telemetry initialized via `cotel.NewTelemetry()` + `tl.ApplyGlobals()`
- [ ] Logger initialized via `czap.New()` and dependency-injected (not recovered from context)
- [ ] **No direct imports of `go.opentelemetry.io/otel/*` packages** (use lib-commons wrappers)
- [ ] **No raw goroutines** (`go func(){}()`) - use `cruntime.SafeGoWithContextAndComponent`
- [ ] Domain validation uses `cassert` (returns errors, NEVER panics)
- [ ] Structured logging uses `s.logger.Log(ctx, level, "msg", clog.String(...))` pattern
- [ ] All errors are checked and wrapped with context
- [ ] Error codes use service prefix (e.g., PLT-0001)
- [ ] No `panic()` in business logic - `InitServersWithOptions` returns errors
- [ ] Tests use table-driven pattern
- [ ] Database models have ToEntity/FromEntity methods
- [ ] Interfaces defined where they're used
- [ ] No global mutable state
- [ ] Context propagated through all calls
- [ ] Sensitive data not logged
- [ ] golangci-lint passes
- [ ] Pagination strategy defined in TRD (or confirmed with user if no TRD)
- [ ] Using `csafe.Divide()` for financial calculations (never raw division)
- [ ] Sensitive fields encrypted with `ccrypto` (AES-GCM)
- [ ] Retry logic uses `cbackoff.Exponential()` with jitter
- [ ] Custom metrics defined with `cmetrics.Metric` struct
- [ ] External service calls wrapped in circuit breakers
