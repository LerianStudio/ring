# Go Standards

> **⚠️ MAINTENANCE:** This file is indexed in `dev-team/skills/shared-patterns/standards-coverage-table.md`.
> When adding/removing `## ` sections, update the coverage table AND agent files per THREE-FILE UPDATE RULE in CLAUDE.md.

This file defines the specific standards for Go development at Lerian Studio.

> **Reference**: Always consult `docs/PROJECT_RULES.md` for common project standards.

---

## Table of Contents

| # | Section | Description |
|---|---------|-------------|
| 1 | [Version](#version) | Go version requirements |
| 2 | [Core Dependency: lib-commons](#core-dependency-lib-commons-mandatory) | Required foundation library |
| 3 | [Frameworks & Libraries](#frameworks--libraries) | Required packages and versions |
| 4 | [Configuration Loading](#configuration-loading-mandatory) | Environment variable handling |
| 5 | [Telemetry & Observability](#telemetry--observability-mandatory) | OpenTelemetry integration |
| 6 | [Bootstrap Pattern](#bootstrap-pattern-mandatory) | Application initialization |
| 7 | [Access Manager Integration](#access-manager-integration-mandatory) | Authentication and authorization with lib-auth |
| 8 | [License Manager Integration](#license-manager-integration-mandatory) | License validation with lib-license-go |
| 9 | [Data Transformation](#data-transformation-toentityfromentity-mandatory) | ToEntity/FromEntity patterns |
| 10 | [Error Codes Convention](#error-codes-convention-mandatory) | Service-prefixed error codes |
| 11 | [Error Handling](#error-handling) | Error wrapping and checking |
| 12 | [Function Design](#function-design-mandatory) | Single responsibility principle |
| 13 | [Pagination Patterns](#pagination-patterns) | Cursor and page-based pagination |
| 14 | [Testing Patterns](#testing-patterns) | Table-driven tests, edge cases |
| 15 | [Logging Standards](#logging-standards) | Structured logging with lib-commons |
| 16 | [Linting](#linting) | golangci-lint configuration |
| 17 | [Architecture Patterns](#architecture-patterns) | Hexagonal architecture |
| 18 | [Directory Structure](#directory-structure) | Project layout (Midaz pattern) |
| 19 | [Concurrency Patterns](#concurrency-patterns) | Goroutines, channels, errgroup |
| 20 | [RabbitMQ Worker Pattern](#rabbitmq-worker-pattern) | Async message processing |

**Meta-sections (not checked by agents):**
- [Standards Compliance Output Format](#standards-compliance-output-format) - Report format for dev-refactor
- [Checklist](#checklist) - Self-verification before submitting code

---

## Version

- **Minimum**: Go 1.24
- **Recommended**: Latest stable release

---

## Core Dependency: lib-commons (MANDATORY)

All Lerian Studio Go projects **MUST** use `lib-commons/v2` as the foundation library. This ensures consistency across all services.

### Required Import (lib-commons v2)

```go
import (
    libCommons "github.com/LerianStudio/lib-commons/v2/commons"
    libZap "github.com/LerianStudio/lib-commons/v2/commons/zap"           // Logger initialization (config/bootstrap only)
    libLog "github.com/LerianStudio/lib-commons/v2/commons/log"           // Logger interface (services, routes, consumers)
    libOpentelemetry "github.com/LerianStudio/lib-commons/v2/commons/opentelemetry"
    libServer "github.com/LerianStudio/lib-commons/v2/commons/server"
    libHTTP "github.com/LerianStudio/lib-commons/v2/commons/net/http"
    libPostgres "github.com/LerianStudio/lib-commons/v2/commons/postgres"
    libMongo "github.com/LerianStudio/lib-commons/v2/commons/mongo"
    libRedis "github.com/LerianStudio/lib-commons/v2/commons/redis"
)
```

> **Note:** v2 uses `lib` prefix aliases (e.g., `libCommons`, `libZap`, `libLog`) to distinguish lib-commons packages from standard library and other imports.

### What lib-commons Provides

| Package | Purpose | Where Used |
|---------|---------|------------|
| `commons` | Core utilities, config loading, tracking context | Everywhere |
| `commons/zap` | Logger initialization/configuration | **Config/bootstrap files only** |
| `commons/log` | Logger interface (`log.Logger`) for logging operations | Services, routes, consumers, handlers |
| `commons/postgres` | PostgreSQL connection management, pagination | Bootstrap, repositories |
| `commons/mongo` | MongoDB connection management | Bootstrap, repositories |
| `commons/redis` | Redis connection management | Bootstrap, repositories |
| `commons/opentelemetry` | OpenTelemetry initialization and helpers | Bootstrap, middleware |
| `commons/net/http` | HTTP utilities, telemetry middleware, pagination | Routes, handlers |
| `commons/server` | Server lifecycle with graceful shutdown | Bootstrap |

---

## Frameworks & Libraries

### Required Versions (Minimum)

| Library | Minimum Version | Purpose |
|---------|-----------------|---------|
| `lib-commons` | v2.0.0 | Core infrastructure |
| `fiber/v2` | v2.52.0 | HTTP framework |
| `pgx/v5` | v5.7.0 | PostgreSQL driver |
| `go.opentelemetry.io/otel` | v1.38.0 | Telemetry |
| `zap` | v1.27.0 | Logging implementation (internal to lib-commons) |
| `testify` | v1.10.0 | Testing |
| `mockery` | v2.50.0 | Mock generation |
| `mongo-driver` | v1.17.0 | MongoDB driver |
| `go-redis/v9` | v9.7.0 | Redis client |
| `validator/v10` | v10.26.0 | Input validation |

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
| testify | Assertions, mocks |
| GoMock | Interface mocking (check if lib-commons already has a mock) |
| SQLMock | Database mocking |
| testcontainers-go | Integration tests |

---

## Configuration Loading (MANDATORY)

All services **MUST** use `libCommons.SetConfigFromEnvVars` for configuration loading.

### 1. Define Configuration Struct

```go
// bootstrap/config.go
package bootstrap

const ApplicationName = "your-service-name"

// Config is the top level configuration struct for the entire application.
type Config struct {
    // Application
    EnvName       string `env:"ENV_NAME"`
    LogLevel      string `env:"LOG_LEVEL"`
    ServerAddress string `env:"SERVER_ADDRESS"`

    // Database - Primary
    PrimaryDBHost     string `env:"DB_HOST"`
    PrimaryDBUser     string `env:"DB_USER"`
    PrimaryDBPassword string `env:"DB_PASSWORD"`
    PrimaryDBName     string `env:"DB_NAME"`
    PrimaryDBPort     string `env:"DB_PORT"`
    PrimaryDBSSLMode  string `env:"DB_SSLMODE"`

    // Database - Replica (for read scaling)
    ReplicaDBHost     string `env:"DB_REPLICA_HOST"`
    ReplicaDBUser     string `env:"DB_REPLICA_USER"`
    ReplicaDBPassword string `env:"DB_REPLICA_PASSWORD"`
    ReplicaDBName     string `env:"DB_REPLICA_NAME"`
    ReplicaDBPort     string `env:"DB_REPLICA_PORT"`
    ReplicaDBSSLMode  string `env:"DB_REPLICA_SSLMODE"`

    // Database - Connection Pool
    MaxOpenConnections int `env:"DB_MAX_OPEN_CONNS"`
    MaxIdleConnections int `env:"DB_MAX_IDLE_CONNS"`

    // MongoDB (if needed)
    MongoDBHost       string `env:"MONGO_HOST"`
    MongoDBName       string `env:"MONGO_NAME"`
    MongoDBUser       string `env:"MONGO_USER"`
    MongoDBPassword   string `env:"MONGO_PASSWORD"`
    MongoDBPort       string `env:"MONGO_PORT"`
    MongoDBParameters string `env:"MONGO_PARAMETERS"`
    MaxPoolSize       int    `env:"MONGO_MAX_POOL_SIZE"`

    // Redis
    RedisHost     string `env:"REDIS_HOST"`
    RedisPassword string `env:"REDIS_PASSWORD"`
    RedisDB       int    `env:"REDIS_DB"`
    RedisPoolSize int    `env:"REDIS_POOL_SIZE"`

    // OpenTelemetry
    OtelServiceName         string `env:"OTEL_RESOURCE_SERVICE_NAME"`
    OtelLibraryName         string `env:"OTEL_LIBRARY_NAME"`
    OtelServiceVersion      string `env:"OTEL_RESOURCE_SERVICE_VERSION"`
    OtelDeploymentEnv       string `env:"OTEL_RESOURCE_DEPLOYMENT_ENVIRONMENT"`
    OtelColExporterEndpoint string `env:"OTEL_EXPORTER_OTLP_ENDPOINT"`
    EnableTelemetry         bool   `env:"ENABLE_TELEMETRY"`

    // Auth
    AuthEnabled bool   `env:"PLUGIN_AUTH_ENABLED"`
    AuthHost    string `env:"PLUGIN_AUTH_HOST"`

    // External Services (gRPC)
    ExternalServiceAddress string `env:"EXTERNAL_SERVICE_GRPC_ADDRESS"`
    ExternalServicePort    string `env:"EXTERNAL_SERVICE_GRPC_PORT"`
}
```

### 2. Load Configuration

```go
// bootstrap/config.go
func InitServers() *Service {
    cfg := &Config{}

    // Load all environment variables into config struct
    if err := libCommons.SetConfigFromEnvVars(cfg); err != nil {
        panic(err)
    }

    // Validate required fields
    if cfg.PrimaryDBHost == "" || cfg.PrimaryDBName == "" {
        panic("DB_HOST and DB_NAME must be configured")
    }

    // Continue with initialization...
}
```

### Supported Types

| Go Type | Default Value | Example |
|---------|---------------|---------|
| `string` | `""` | `ServerAddress string \`env:"SERVER_ADDRESS"\`` |
| `bool` | `false` | `EnableTelemetry bool \`env:"ENABLE_TELEMETRY"\`` |
| `int`, `int8`, `int16`, `int32`, `int64` | `0` | `MaxPoolSize int \`env:"MONGO_MAX_POOL_SIZE"\`` |

### Environment Variable Naming Convention

| Category | Prefix | Example |
|----------|--------|---------|
| Application | None | `ENV_NAME`, `LOG_LEVEL`, `SERVER_ADDRESS` |
| PostgreSQL | `DB_` | `DB_HOST`, `DB_USER`, `DB_PASSWORD` |
| PostgreSQL Replica | `DB_REPLICA_` | `DB_REPLICA_HOST`, `DB_REPLICA_USER` |
| MongoDB | `MONGO_` | `MONGO_HOST`, `MONGO_NAME` |
| Redis | `REDIS_` | `REDIS_HOST`, `REDIS_PASSWORD` |
| OpenTelemetry | `OTEL_` | `OTEL_RESOURCE_SERVICE_NAME` |
| Auth Plugin | `PLUGIN_AUTH_` | `PLUGIN_AUTH_ENABLED`, `PLUGIN_AUTH_HOST` |
| gRPC Services | `{SERVICE}_GRPC_` | `TRANSACTION_GRPC_ADDRESS` |

### What NOT to Do

```go
// FORBIDDEN: Manual os.Getenv calls scattered across code
host := os.Getenv("DB_HOST")  // DON'T do this

// FORBIDDEN: Configuration outside bootstrap
func NewService() *Service {
    dbHost := os.Getenv("DB_HOST")  // DON'T do this
}

// CORRECT: All configuration in Config struct, loaded once in bootstrap
type Config struct {
    PrimaryDBHost string `env:"DB_HOST"`  // Centralized
}

// Load with: libCommons.SetConfigFromEnvVars(&cfg)
```

---

## Telemetry & Observability (MANDATORY)

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
│  MIDDLEWARE: f.Use(tlMid.WithTelemetry(tl)) - CREATES ROOT SPAN             │
│                                                                             │
│  What WithTelemetry does:                                                   │
│  1. ExtractHTTPContext(c) - extracts traceparent/tracestate from headers    │
│     → Uses otel.GetTextMapPropagator().Extract() for W3C trace context      │
│     → If traceparent exists: creates child span of remote parent            │
│     → If no traceparent: creates new root span                              │
│  2. tracer.Start(ctx, "GET /api/resource") - creates HTTP ROOT SPAN         │
│  3. Sets span attributes: http.method, http.url, http.route, etc.           │
│  4. ContextWithTracer(ctx, tracer) - injects tracer into context            │
│  5. ContextWithMetricFactory(ctx, factory) - injects metrics factory        │
│  6. c.SetUserContext(ctx) - makes enriched context available to handlers    │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  HANDLER LAYER (optional child spans - for complex handlers)                │
│                                                                             │
│  logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)             │
│  ctx, span := tracer.Start(ctx, "handler.create_tenant")                    │
│  defer span.End()                                                           │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  SERVICE LAYER (MANDATORY child spans for all methods)                      │
│                                                                             │
│  logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)             │
│  ctx, span := tracer.Start(ctx, "service.tenant.create")                    │
│  defer span.End()                                                           │
│                                                                             │
│  // Structured logging (automatically correlated with trace via context)    │
│  logger.Infof("Creating tenant: name=%s", req.Name)                         │
│                                                                             │
│  // Business errors → AddEvent (span status stays OK)                       │
│  libOpentelemetry.HandleSpanBusinessErrorEvent(&span, "Validation", err)    │
│                                                                             │
│  // Technical errors → SetStatus ERROR + RecordError                        │
│  libOpentelemetry.HandleSpanError(&span, "DB connection failed", err)       │
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
│  libOpentelemetry.InjectHTTPContext(&req.Header, ctx)                       │
│                                                                             │
│  // gRPC Client: Inject into outgoing metadata                              │
│  ctx = libOpentelemetry.InjectGRPCContext(ctx)                              │
│                                                                             │
│  // Queue/Message: Inject into message headers for async trace continuation │
│  headers := libOpentelemetry.PrepareQueueHeaders(ctx, baseHeaders)          │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Complete Telemetry Flow (Bootstrap to Shutdown)

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. BOOTSTRAP (config.go)                                        │
│    telemetry := libOpentelemetry.InitializeTelemetry(&config)   │
│    → Creates OpenTelemetry provider once at startup             │
│    → Sets global TextMapPropagator for W3C TraceContext         │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. ROUTER (routes.go)                                           │
│    tlMid := libHTTP.NewTelemetryMiddleware(tl)                  │
│    f.Use(tlMid.WithTelemetry(tl))      ← Creates root span      │
│    ...routes...                                                  │
│    f.Use(tlMid.EndTracingSpans)        ← Closes root spans      │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. ANY LAYER (handlers, services, repositories)                 │
│    logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)│
│    ctx, span := tracer.Start(ctx, "operation_name")             │
│    defer span.End()                                              │
│    logger.Infof("Processing...")   ← Logger from same context   │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. SERVER LIFECYCLE (fiber.server.go)                           │
│    libServer.NewServerManager(nil, &s.telemetry, s.logger)      │
│        .WithHTTPServer(s.app, s.serverAddress)                  │
│        .StartWithGracefulShutdown()                             │
│    → Handles signal trapping + telemetry flush + clean shutdown │
└─────────────────────────────────────────────────────────────────┘
```

---

### Service Method Instrumentation Checklist (MANDATORY)

**Every service method MUST implement these steps:**

| # | Step | Code Pattern | Purpose |
|---|------|--------------|---------|
| 1 | Extract tracking from context | `logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)` | Get logger/tracer injected by middleware |
| 2 | Create child span | `ctx, span := tracer.Start(ctx, "service.{domain}.{operation}")` | Create traceable operation |
| 3 | Defer span end | `defer span.End()` | Ensure span closes even on panic |
| 4 | Use structured logger | `logger.Infof/Errorf/Warnf(...)` | Logs correlated with trace |
| 5 | Handle business errors | `libOpentelemetry.HandleSpanBusinessErrorEvent(&span, msg, err)` | Expected errors (validation, not found) |
| 6 | Handle technical errors | `libOpentelemetry.HandleSpanError(&span, msg, err)` | Unexpected errors (DB, network) |
| 7 | Pass ctx downstream | All calls receive `ctx` with span | Trace propagation |

---

### Error Handling Classification

| Error Type | Examples | Handler Function | Span Status |
|------------|----------|------------------|-------------|
| **Business Error** | Validation failed, Resource not found, Conflict, Unauthorized | `HandleSpanBusinessErrorEvent` | OK (adds event) |
| **Technical Error** | DB connection failed, Timeout, Network error, Unexpected panic | `HandleSpanError` | ERROR (records error) |

**Why the distinction matters:**
- Business errors are expected and don't indicate system problems
- Technical errors indicate infrastructure issues requiring investigation
- Alerting systems typically trigger on ERROR status spans

---

### Complete Instrumented Service Method Template

```go
func (s *myService) DoSomething(ctx context.Context, req *Request) (*Response, error) {
    // 1. Extract logger and tracer from context (injected by WithTelemetry middleware)
    logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)

    // 2. Create child span for this operation
    ctx, span := tracer.Start(ctx, "service.my_service.do_something")
    defer span.End()

    // 3. Structured logging (automatically correlated with trace via context)
    logger.Infof("Processing request: id=%s", req.ID)

    // 4. Input validation - BUSINESS error (expected, span stays OK)
    if req.Name == "" {
        logger.Warn("Validation failed: empty name")
        libOpentelemetry.HandleSpanBusinessErrorEvent(&span, "Validation failed", ErrInvalidInput)
        return nil, fmt.Errorf("%w: name is required", ErrInvalidInput)
    }

    // 5. External call - pass ctx to propagate trace context
    result, err := s.repo.Create(ctx, entity)
    if err != nil {
        // Check if it's a "not found" type error (business) vs DB failure (technical)
        if errors.Is(err, ErrNotFound) {
            logger.Warnf("Entity not found: %s", req.ID)
            libOpentelemetry.HandleSpanBusinessErrorEvent(&span, "Entity not found", err)
            return nil, err
        }

        // TECHNICAL error - unexpected failure, span marked ERROR
        logger.Errorf("Failed to create entity: %v", err)
        libOpentelemetry.HandleSpanError(&span, "Repository create failed", err)
        return nil, fmt.Errorf("failed to create: %w", err)
    }

    logger.Infof("Entity created successfully: id=%s", result.ID)
    return result, nil
}
```

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
libOpentelemetry.InjectHTTPContext(&req.Header, ctx)
resp, err := client.Do(req)

// gRPC Client - Inject into outgoing metadata
ctx = libOpentelemetry.InjectGRPCContext(ctx)
resp, err := grpcClient.SomeMethod(ctx, req)

// Queue/Message Publisher - Inject into message headers
headers := libOpentelemetry.PrepareQueueHeaders(ctx, map[string]any{
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
| `import "go.opentelemetry.io/otel"` | Direct OTel usage bypasses lib-commons wrappers | Use `libCommons.NewTrackingFromContext(ctx)` |
| `import "go.opentelemetry.io/otel/trace"` | Direct tracer access without lib-commons | Use `libOpentelemetry` package from lib-commons |
| `otel.Tracer("name")` | Creates standalone tracer, no context integration | Use tracer from `NewTrackingFromContext(ctx)` |
| `trace.SpanFromContext(ctx)` | Raw OTel API, inconsistent with lib-commons | Use `libCommons.NewTrackingFromContext(ctx)` |
| `c.JSON(status, data)` | Direct Fiber response, no standard format | Use `libHTTP.OK(c, data)` or `libHTTP.Created(c, data)` |
| `c.Status(code).JSON(err)` | Inconsistent error responses | Use `libHTTP.WithError(c, err)` |
| Custom error handler | Inconsistent error format across services | Use `libHTTP.HandleFiberError` in fiber.Config |
| Manual pagination logic | Reinvents cursor/offset pagination | Use `libHTTP.Pagination`, `libHTTP.CursorPagination` |
| `c.SendString()` / `c.Send()` | No standard response wrapper | Use `libHTTP.OK()`, `libHTTP.Created()`, `libHTTP.NoContent()` |
| Custom logging middleware | Inconsistent request logging | Use `libHTTP.WithHTTPLogging(libHTTP.WithCustomLogger(lg))` |
| Manual telemetry middleware | Missing trace context injection | Use `libHTTP.NewTelemetryMiddleware(tl).WithTelemetry(tl)` |
| `log.Printf("[Service] msg")` | No trace correlation, no structured logging | `logger.Infof("msg")` from context |
| No span in service method | Operation not traceable | Always create child span |
| `return err` without span handling | Error not attributed to trace | Call `HandleSpanError` or `HandleSpanBusinessErrorEvent` |
| Hardcoded trace IDs | Breaks distributed tracing | Use context propagation |
| Missing `defer span.End()` | Span never closes, memory leak | Always defer immediately after Start |
| Using `_` to ignore tracer | No tracing capability | Extract and use tracer from context |
| Calling downstream without ctx | Trace chain breaks | Pass ctx to all downstream calls |
| Not injecting trace context for outgoing HTTP/gRPC | Remote traces disconnected | Use `InjectHTTPContext` / `InjectGRPCContext` |

> **⛔ CRITICAL:** Direct imports of `go.opentelemetry.io/otel`, `go.opentelemetry.io/otel/trace`, `go.opentelemetry.io/otel/attribute`, or `go.opentelemetry.io/otel/codes` are **FORBIDDEN** in application code. All telemetry MUST go through lib-commons wrappers (`libCommons`, `libOpentelemetry`). The only exception is if lib-commons doesn't provide a required OTel feature - in that case, open an issue to add it to lib-commons.

> **⛔ CRITICAL:** Direct Fiber response methods (`c.JSON()`, `c.Status().JSON()`, `c.SendString()`) are **FORBIDDEN**. All HTTP responses MUST use `libHTTP` wrappers (`libHTTP.OK()`, `libHTTP.Created()`, `libHTTP.WithError()`, etc.) to ensure consistent response format, proper error handling, and telemetry integration across all Lerian services.

### 1. Bootstrap Initialization

```go
// bootstrap/config.go
func InitServers() *Service {
    cfg := &Config{}
    if err := libCommons.SetConfigFromEnvVars(cfg); err != nil {
        panic(err)
    }

    // Initialize logger FIRST (zap package for initialization in bootstrap)
    logger := libZap.InitializeLogger()

    // Initialize telemetry with config
    telemetry := libOpentelemetry.InitializeTelemetry(&libOpentelemetry.TelemetryConfig{
        LibraryName:               cfg.OtelLibraryName,
        ServiceName:               cfg.OtelServiceName,
        ServiceVersion:            cfg.OtelServiceVersion,
        DeploymentEnv:             cfg.OtelDeploymentEnv,
        CollectorExporterEndpoint: cfg.OtelColExporterEndpoint,
        EnableTelemetry:           cfg.EnableTelemetry,
        Logger:                    logger,
    })

    // Pass telemetry to router...
}
```

### 2. Router Middleware Setup

```go
// adapters/http/in/routes.go
import (
    libLog "github.com/LerianStudio/lib-commons/v2/commons/log"
    libHTTP "github.com/LerianStudio/lib-commons/v2/commons/net/http"
    libOpentelemetry "github.com/LerianStudio/lib-commons/v2/commons/opentelemetry"
    "github.com/gofiber/contrib/otelfiber/v2"
    "github.com/gofiber/fiber/v2"
    "github.com/gofiber/fiber/v2/middleware/cors"
    "github.com/gofiber/fiber/v2/middleware/recover"
)

// skipTelemetryPaths returns true for paths that should not be instrumented.
func skipTelemetryPaths(c *fiber.Ctx) bool {
    switch c.Path() {
    case "/health", "/ready", "/metrics":
        return true
    default:
        return false
    }
}

func NewRouter(lg libLog.Logger, tl *libOpentelemetry.Telemetry, ...) *fiber.App {
    f := fiber.New(fiber.Config{
        DisableStartupMessage: true,
        ErrorHandler: func(ctx *fiber.Ctx, err error) error {
            return libHTTP.HandleFiberError(ctx, err)
        },
    })

    // Create telemetry middleware
    tlMid := libHTTP.NewTelemetryMiddleware(tl)

    // Middleware setup - ORDER MATTERS
    f.Use(tlMid.WithTelemetry(tl))                                    // 1. Must be first - injects tracer+logger into context
    f.Use(recover.New())                                              // 2. Panic recovery
    f.Use(cors.New())                                                 // 3. CORS
    f.Use(otelfiber.Middleware(otelfiber.WithNext(skipTelemetryPaths))) // 4. OpenTelemetry metrics
    f.Use(libHTTP.WithHTTPLogging(libHTTP.WithCustomLogger(lg)))      // 5. HTTP logging

    // ... define routes ...

    // Version endpoint
    f.Get("/version", libHTTP.Version)

    // MUST be last middleware - closes root spans
    f.Use(tlMid.EndTracingSpans)

    return f
}
```

### otelfiber Metrics Middleware (MANDATORY)

All Fiber services **MUST** use `otelfiber` for HTTP metrics collection. This provides standard OpenTelemetry metrics without custom implementation.

**Installation:**
```bash
go get github.com/gofiber/contrib/otelfiber/v2
```

**Metrics Collected:**

| Metric | Type | Description |
|--------|------|-------------|
| `http.server.duration` | Histogram | Request duration in milliseconds |
| `http.server.request.size` | Histogram | Request body size in bytes |
| `http.server.response.size` | Histogram | Response body size in bytes |
| `http.server.active_requests` | Gauge | Currently processing requests |

**Configuration Options:**

| Option | Purpose |
|--------|---------|
| `WithNext(func)` | Skip instrumentation for certain paths |
| `WithTracerProvider(tp)` | Custom tracer provider |
| `WithMeterProvider(mp)` | Custom meter provider |
| `WithSpanNameFormatter(func)` | Custom span naming |

**Why otelfiber over custom middleware:**
- Standard OpenTelemetry semantic conventions
- Automatic trace context propagation
- No custom code to maintain
- Compatible with any OpenTelemetry backend (Jaeger, Zipkin, Grafana, etc.)

### 3. Recovering Logger & Tracer (Any Layer)

```go
// ANY file in ANY layer (handler, service, repository)
func (s *Service) ProcessEntity(ctx context.Context, id string) error {
    // Single call recovers BOTH logger AND tracer from context
    logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)

    // Create child span for this operation
    ctx, span := tracer.Start(ctx, "service.process_entity")
    defer span.End()

    // Logger is automatically correlated with trace
    logger.Infof("Processing entity: %s", id)

    // Pass ctx to downstream calls - trace propagates automatically
    return s.repo.Update(ctx, id)
}
```

### 4. Error Handling with Spans

```go
// For technical errors (unexpected failures)
if err != nil {
    libOpentelemetry.HandleSpanError(&span, "Failed to connect database", err)
    logger.Errorf("Database error: %v", err)
    return nil, err
}

// For business errors (expected validation failures)
if err != nil {
    libOpentelemetry.HandleSpanBusinessErrorEvent(&span, "Validation failed", err)
    logger.Warnf("Validation error: %v", err)
    return nil, err
}
```

### 5. Server Lifecycle with Graceful Shutdown

```go
// bootstrap/fiber.server.go
type Server struct {
    app           *fiber.App
    serverAddress string
    logger        libLog.Logger
    telemetry     libOpentelemetry.Telemetry
}

func (s *Server) Run(l *libCommons.Launcher) error {
    libServer.NewServerManager(nil, &s.telemetry, s.logger).
        WithHTTPServer(s.app, s.serverAddress).
        StartWithGracefulShutdown()  // Handles: SIGINT/SIGTERM, telemetry flush, connections close
    return nil
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

## Bootstrap Pattern (MANDATORY)

All services **MUST** follow the bootstrap pattern for initialization. The bootstrap package is the single point of application assembly where all dependencies are wired together.

### Directory Structure

```text
/internal
  /bootstrap
    config.go          # Config struct + InitServers() - Main initialization logic
    fiber.server.go    # HTTP server with graceful shutdown (or server.go)
    grpc.server.go     # gRPC server (if needed)
    service.go         # Service struct wrapping servers + Run() method
```

### Reference Implementations

The following sections provide **complete, copy-pasteable** implementations for each bootstrap file. These are extracted from production repositories (midaz, plugin-auth, plugin-fees).

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

    libCommons "github.com/LerianStudio/lib-commons/v2/commons"
    libMongo "github.com/LerianStudio/lib-commons/v2/commons/mongo"
    libOpentelemetry "github.com/LerianStudio/lib-commons/v2/commons/opentelemetry"
    libPostgres "github.com/LerianStudio/lib-commons/v2/commons/postgres"
    libRedis "github.com/LerianStudio/lib-commons/v2/commons/redis"
    libZap "github.com/LerianStudio/lib-commons/v2/commons/zap"

    // Internal imports
    httpin "github.com/LerianStudio/your-service/internal/adapters/http/in"
    "github.com/LerianStudio/your-service/internal/adapters/postgres/user"
    "github.com/LerianStudio/your-service/internal/services/command"
    "github.com/LerianStudio/your-service/internal/services/query"
)

// ApplicationName identifies this service in logs, traces, and metrics.
const ApplicationName = "your-service"

// Config is the top level configuration struct for the entire application.
// All fields are populated from environment variables via `env:` tags.
type Config struct {
    // Application
    EnvName       string `env:"ENV_NAME"`
    ServerAddress string `env:"SERVER_ADDRESS"`
    LogLevel      string `env:"LOG_LEVEL"`

    // Database - Primary
    PrimaryDBHost      string `env:"DB_HOST"`
    PrimaryDBUser      string `env:"DB_USER"`
    PrimaryDBPassword  string `env:"DB_PASSWORD"`
    PrimaryDBName      string `env:"DB_NAME"`
    PrimaryDBPort      string `env:"DB_PORT"`
    PrimaryDBSSLMode   string `env:"DB_SSLMODE"`

    // Database - Replica (optional, for read scaling)
    ReplicaDBHost     string `env:"DB_REPLICA_HOST"`
    ReplicaDBUser     string `env:"DB_REPLICA_USER"`
    ReplicaDBPassword string `env:"DB_REPLICA_PASSWORD"`
    ReplicaDBName     string `env:"DB_REPLICA_NAME"`
    ReplicaDBPort     string `env:"DB_REPLICA_PORT"`
    ReplicaDBSSLMode  string `env:"DB_REPLICA_SSLMODE"`

    // Database - Connection Pool
    MaxOpenConnections int `env:"DB_MAX_OPEN_CONNS"`
    MaxIdleConnections int `env:"DB_MAX_IDLE_CONNS"`

    // MongoDB (if needed)
    MongoURI          string `env:"MONGO_URI"`
    MongoDBHost       string `env:"MONGO_HOST"`
    MongoDBName       string `env:"MONGO_NAME"`
    MongoDBUser       string `env:"MONGO_USER"`
    MongoDBPassword   string `env:"MONGO_PASSWORD"`
    MongoDBPort       string `env:"MONGO_PORT"`
    MongoDBParameters string `env:"MONGO_PARAMETERS"`
    MaxPoolSize       int    `env:"MONGO_MAX_POOL_SIZE"`

    // Redis (if needed)
    RedisHost                    string `env:"REDIS_HOST"`
    RedisMasterName              string `env:"REDIS_MASTER_NAME" default:""`
    RedisPassword                string `env:"REDIS_PASSWORD"`
    RedisDB                      int    `env:"REDIS_DB" default:"0"`
    RedisProtocol                int    `env:"REDIS_PROTOCOL" default:"3"`
    RedisTLS                     bool   `env:"REDIS_TLS" default:"false"`
    RedisCACert                  string `env:"REDIS_CA_CERT"`
    RedisUseGCPIAM               bool   `env:"REDIS_USE_GCP_IAM" default:"false"`
    RedisServiceAccount          string `env:"REDIS_SERVICE_ACCOUNT" default:""`
    GoogleApplicationCredentials string `env:"GOOGLE_APPLICATION_CREDENTIALS" default:""`
    RedisTokenLifeTime           int    `env:"REDIS_TOKEN_LIFETIME" default:"60"`
    RedisTokenRefreshDuration    int    `env:"REDIS_TOKEN_REFRESH_DURATION" default:"45"`

    // OpenTelemetry
    OtelServiceName         string `env:"OTEL_RESOURCE_SERVICE_NAME"`
    OtelLibraryName         string `env:"OTEL_LIBRARY_NAME"`
    OtelServiceVersion      string `env:"OTEL_RESOURCE_SERVICE_VERSION"`
    OtelDeploymentEnv       string `env:"OTEL_RESOURCE_DEPLOYMENT_ENVIRONMENT"`
    OtelColExporterEndpoint string `env:"OTEL_EXPORTER_OTLP_ENDPOINT"`
    EnableTelemetry         bool   `env:"ENABLE_TELEMETRY"`

    // Auth (if using plugin-auth)
    AuthEnabled bool   `env:"PLUGIN_AUTH_ENABLED"`
    AuthHost    string `env:"PLUGIN_AUTH_HOST"`
}

// InitServers initializes all application components and returns a Service ready to run.
// This is the single point of dependency injection for the entire application.
func InitServers() *Service {
    // 1. LOAD CONFIGURATION
    // All environment variables are loaded into the Config struct
    cfg := &Config{}
    if err := libCommons.SetConfigFromEnvVars(cfg); err != nil {
        panic(err)
    }

    // 2. INITIALIZE LOGGER
    // Must be first after config - all subsequent components need logging
    logger := libZap.InitializeLogger()

    // 3. INITIALIZE TELEMETRY
    // OpenTelemetry provider for distributed tracing
    telemetry := libOpentelemetry.InitializeTelemetry(&libOpentelemetry.TelemetryConfig{
        LibraryName:               cfg.OtelLibraryName,
        ServiceName:               cfg.OtelServiceName,
        ServiceVersion:            cfg.OtelServiceVersion,
        DeploymentEnv:             cfg.OtelDeploymentEnv,
        CollectorExporterEndpoint: cfg.OtelColExporterEndpoint,
        EnableTelemetry:           cfg.EnableTelemetry,
        Logger:                    logger,
    })

    // 4. INITIALIZE DATABASE CONNECTIONS
    // PostgreSQL connection with primary/replica support
    postgreSourcePrimary := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=%s",
        cfg.PrimaryDBHost, cfg.PrimaryDBUser, cfg.PrimaryDBPassword,
        cfg.PrimaryDBName, cfg.PrimaryDBPort, cfg.PrimaryDBSSLMode)

    postgreSourceReplica := postgreSourcePrimary
    if cfg.ReplicaDBHost != "" {
        postgreSourceReplica = fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=%s",
            cfg.ReplicaDBHost, cfg.ReplicaDBUser, cfg.ReplicaDBPassword,
            cfg.ReplicaDBName, cfg.ReplicaDBPort, cfg.ReplicaDBSSLMode)
    }

    postgresConnection := &libPostgres.PostgresConnection{
        ConnectionStringPrimary: postgreSourcePrimary,
        ConnectionStringReplica: postgreSourceReplica,
        PrimaryDBName:           cfg.PrimaryDBName,
        ReplicaDBName:           cfg.ReplicaDBName,
        Component:               ApplicationName,
        Logger:                  logger,
        MaxOpenConnections:      cfg.MaxOpenConnections,
        MaxIdleConnections:      cfg.MaxIdleConnections,
    }

    // MongoDB connection (optional - include only if service uses MongoDB)
    mongoSource := fmt.Sprintf("%s://%s:%s@%s:%s/",
        cfg.MongoURI, cfg.MongoDBUser, cfg.MongoDBPassword, cfg.MongoDBHost, cfg.MongoDBPort)
    if cfg.MaxPoolSize <= 0 {
        cfg.MaxPoolSize = 100
    }
    if cfg.MongoDBParameters != "" {
        mongoSource += "?" + cfg.MongoDBParameters
    }
    mongoConnection := &libMongo.MongoConnection{
        ConnectionStringSource: mongoSource,
        Database:               cfg.MongoDBName,
        Logger:                 logger,
        MaxPoolSize:            uint64(cfg.MaxPoolSize),
    }

    // Redis connection (optional - include only if service uses Redis)
    redisConnection := &libRedis.RedisConnection{
        Address:                      strings.Split(cfg.RedisHost, ","),
        Password:                     cfg.RedisPassword,
        DB:                           cfg.RedisDB,
        Protocol:                     cfg.RedisProtocol,
        MasterName:                   cfg.RedisMasterName,
        UseTLS:                       cfg.RedisTLS,
        CACert:                       cfg.RedisCACert,
        UseGCPIAMAuth:                cfg.RedisUseGCPIAM,
        ServiceAccount:               cfg.RedisServiceAccount,
        GoogleApplicationCredentials: cfg.GoogleApplicationCredentials,
        TokenLifeTime:                time.Duration(cfg.RedisTokenLifeTime) * time.Minute,
        RefreshDuration:              time.Duration(cfg.RedisTokenRefreshDuration) * time.Minute,
        Logger:                       logger,
    }

    // 5. INITIALIZE REPOSITORIES (Adapters)
    // Each repository uses the appropriate database connection
    userPostgreSQLRepository := user.NewUserPostgreSQLRepository(postgresConnection)
    // metadataMongoDBRepository := mongodb.NewMetadataMongoDBRepository(mongoConnection)
    // cacheRedisRepository := redis.NewCacheRepository(redisConnection)

    // 6. INITIALIZE USE CASES (Services/Business Logic)
    // Command use case for write operations
    commandUseCase := &command.UseCase{
        UserRepo: userPostgreSQLRepository,
        // MetadataRepo: metadataMongoDBRepository,
        // CacheRepo: cacheRedisRepository,
    }
    // Query use case for read operations
    queryUseCase := &query.UseCase{
        UserRepo: userPostgreSQLRepository,
        // MetadataRepo: metadataMongoDBRepository,
    }

    // 7. INITIALIZE HANDLERS
    // HTTP handlers receive use cases for request processing
    userHandler := &httpin.UserHandler{
        Command: commandUseCase,
        Query:   queryUseCase,
    }

    // 8. CREATE ROUTER WITH MIDDLEWARE
    // NewRouter sets up Fiber with telemetry middleware, logging, and routes
    httpApp := httpin.NewRouter(logger, telemetry, userHandler)

    // 9. CREATE SERVER
    // Server wraps the Fiber app with graceful shutdown support
    serverAPI := NewServer(cfg, httpApp, logger, telemetry)

    // 10. RETURN SERVICE
    // Service orchestrates server lifecycle
    return &Service{
        Server: serverAPI,
        Logger: logger,
    }
}
```

**Key Points:**
- `InitServers()` is the ONLY place where dependencies are wired together
- Order matters: config → logger → telemetry → databases → repositories → services → handlers → router → server
- All database connections use lib-commons packages
- The function returns a `*Service` that is ready to run

---

### fiber.server.go - Complete Reference

This file defines the HTTP server with graceful shutdown support.

```go
package bootstrap

import (
    libCommons "github.com/LerianStudio/lib-commons/v2/commons"
    libLog "github.com/LerianStudio/lib-commons/v2/commons/log"
    libOpentelemetry "github.com/LerianStudio/lib-commons/v2/commons/opentelemetry"
    libCommonsServer "github.com/LerianStudio/lib-commons/v2/commons/server"
    "github.com/gofiber/fiber/v2"
)

// Server represents the HTTP server for the service.
type Server struct {
    app           *fiber.App
    serverAddress string
    logger        libLog.Logger
    telemetry     libOpentelemetry.Telemetry
}

// ServerAddress returns the server's listen address.
func (s *Server) ServerAddress() string {
    return s.serverAddress
}

// NewServer creates a new Server instance.
func NewServer(cfg *Config, app *fiber.App, logger libLog.Logger, telemetry *libOpentelemetry.Telemetry) *Server {
    return &Server{
        app:           app,
        serverAddress: cfg.ServerAddress,
        logger:        logger,
        telemetry:     *telemetry,
    }
}

// Run starts the HTTP server with graceful shutdown.
// This method is called by the Launcher and handles:
// - Signal trapping (SIGINT, SIGTERM)
// - Telemetry flush on shutdown
// - Connection draining
func (s *Server) Run(l *libCommons.Launcher) error {
    libCommonsServer.NewServerManager(nil, &s.telemetry, s.logger).
        WithHTTPServer(s.app, s.serverAddress).
        StartWithGracefulShutdown()

    return nil
}
```

**Key Points:**
- `Run(*libCommons.Launcher)` signature is required for the Launcher
- `libCommonsServer.NewServerManager` handles all graceful shutdown logic
- Telemetry is passed to ensure spans are flushed before shutdown

---

### service.go - Complete Reference

This file defines the Service struct that orchestrates the application lifecycle.

```go
package bootstrap

import (
    libCommons "github.com/LerianStudio/lib-commons/v2/commons"
    libLog "github.com/LerianStudio/lib-commons/v2/commons/log"
)

// Service is the application glue where we put all top level components to be used.
type Service struct {
    *Server
    libLog.Logger
}

// Run starts the application.
// This is the only necessary code to run an app in main.go
func (app *Service) Run() {
    libCommons.NewLauncher(
        libCommons.WithLogger(app.Logger),
        libCommons.RunApp("Fiber Server", app.Server),
    ).Run()
}
```

**Key Points:**
- Service embeds `*Server` and `libLog.Logger`
- `Run()` uses `libCommons.NewLauncher` to manage application lifecycle
- For multiple servers (HTTP + gRPC + Worker), add multiple `RunApp` calls:

```go
func (app *Service) Run() {
    libCommons.NewLauncher(
        libCommons.WithLogger(app.Logger),
        libCommons.RunApp("HTTP Server", app.HTTPServer),
        libCommons.RunApp("gRPC Server", app.GRPCServer),
        libCommons.RunApp("RabbitMQ Consumer", app.Consumer),
    ).Run()
}
```

---

### main.go - Complete Reference

The main.go file should be minimal, delegating to bootstrap.

```go
package main

import "github.com/LerianStudio/your-service/internal/bootstrap"

func main() {
    bootstrap.InitServers().Run()
}
```

**That's it.** All complexity is encapsulated in bootstrap.

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
    // ... other fields ...

    // Access Manager
    AuthAddress string `env:"PLUGIN_AUTH_ADDRESS"`
    AuthEnabled bool   `env:"PLUGIN_AUTH_ENABLED"`

    // Service-to-Service Auth (optional)
    ClientID     string `env:"CLIENT_ID"`
    ClientSecret string `env:"CLIENT_SECRET"`
}
```

### Bootstrap Integration

```go
// bootstrap/config.go
func InitServers() *Service {
    cfg := &Config{}
    if err := libCommons.SetConfigFromEnvVars(cfg); err != nil {
        panic(err)
    }

    logger := libZap.InitializeLogger()

    // ... telemetry, database initialization ...

    // Initialize Access Manager client
    auth := authMiddleware.NewAuthClient(cfg.AuthAddress, cfg.AuthEnabled, &logger)

    // Pass auth client to router
    httpApp := httpin.NewRouter(logger, telemetry, auth, handlers...)

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
    lg libLog.Logger,
    tl *libOpentelemetry.Telemetry,
    auth *authMiddleware.AuthClient,
    handler *YourHandler,
) *fiber.App {
    f := fiber.New(fiber.Config{
        DisableStartupMessage: true,
        ErrorHandler:          libHTTP.HandleFiberError,
    })

    // Middleware setup
    tlMid := libHTTP.NewTelemetryMiddleware(tl)
    f.Use(tlMid.WithTelemetry(tl))
    f.Use(recover.New())
    f.Use(cors.New())

    // Protected routes with authorization
    f.Post("/v1/resources", auth.Authorize(applicationName, "resources", "post"), handler.Create)
    f.Get("/v1/resources", auth.Authorize(applicationName, "resources", "get"), handler.List)
    f.Get("/v1/resources/:id", auth.Authorize(applicationName, "resources", "get"), handler.Get)
    f.Patch("/v1/resources/:id", auth.Authorize(applicationName, "resources", "patch"), handler.Update)
    f.Delete("/v1/resources/:id", auth.Authorize(applicationName, "resources", "delete"), handler.Delete)

    // Health and version (no auth required)
    f.Get("/health", libHTTP.Health)
    f.Get("/version", libHTTP.Version)

    f.Use(tlMid.EndTracingSpans)

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
    libOpentelemetry.InjectHTTPContext(&req.Header, ctx)

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
        return libHTTP.WithError(c, ErrMissingOrganizationID)
    }

    parsedUUID, err := uuid.Parse(headerParam)
    if err != nil {
        return libHTTP.WithError(c, ErrInvalidOrganizationID)
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

### What NOT to Do

```go
// FORBIDDEN: Hardcoded tokens
req.Header.Set("Authorization", "Bearer hardcoded-token-here")  // NEVER

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

func InitServers() *Service {
    cfg := &Config{}
    if err := libCommons.SetConfigFromEnvVars(cfg); err != nil {
        panic(err)
    }

    logger := libZap.InitializeLogger()

    // ... telemetry, database initialization ...

    // Initialize License Manager client
    licenseClient := libLicense.NewLicenseClient(
        constant.ApplicationName,  // e.g., "plugin-fees"
        cfg.LicenseKey,
        cfg.OrganizationIDs,
        &logger,
    )

    // Pass license client to router and server
    httpApp := httpin.NewRouter(logger, telemetry, auth, licenseClient, handlers...)
    serverAPI := NewServer(cfg, httpApp, logger, telemetry, licenseClient)

    // ... rest of initialization ...
}
```

### Router Setup with License Middleware

```go
// adapters/http/in/routes.go
import (
    libHTTP "github.com/LerianStudio/lib-commons/v2/commons/net/http"
    libLicense "github.com/LerianStudio/lib-license-go/v2/middleware"
)

func NewRoutes(lg log.Logger, tl *opentelemetry.Telemetry, handler *YourHandler, lc *libLicense.LicenseClient) *fiber.App {
    f := fiber.New(fiber.Config{
        DisableStartupMessage: true,
        ErrorHandler: func(ctx *fiber.Ctx, err error) error {
            return libHTTP.HandleFiberError(ctx, err)
        },
    })
    tlMid := libHTTP.NewTelemetryMiddleware(tl)

    // License middleware - applies GLOBALLY (must be early in chain)
    f.Use(lc.Middleware())

    // Other middleware
    f.Use(tlMid.WithTelemetry(tl))
    f.Use(cors.New())
    f.Use(libHTTP.WithHTTPLogging(libHTTP.WithCustomLogger(lg)))

    // Routes
    v1 := f.Group("/v1")
    v1.Post("/resources", handler.Create)
    v1.Get("/resources", handler.List)

    // Health and version (automatically skipped by license middleware)
    f.Get("/health", libHTTP.Ping)
    f.Get("/version", libHTTP.Version)

    f.Use(tlMid.EndTracingSpans)

    return f
}
```

**Note:** License middleware should be applied early in the middleware chain. It automatically skips `/health`, `/version`, and `/swagger/` paths.

### Server Integration with Graceful Shutdown

```go
// bootstrap/server.go
import (
    libCommonsLicense "github.com/LerianStudio/lib-commons/v2/commons/license"
    libLicense "github.com/LerianStudio/lib-license-go/v2/middleware"
)

type Server struct {
    app           *fiber.App
    serverAddress string
    license       *libCommonsLicense.ManagerShutdown
    logger        libLog.Logger
    telemetry     libOpentelemetry.Telemetry
}

func NewServer(cfg *Config, app *fiber.App, logger libLog.Logger, telemetry *libOpentelemetry.Telemetry, licenseClient *libLicense.LicenseClient) *Server {
    return &Server{
        app:           app,
        serverAddress: cfg.ServerAddress,
        license:       licenseClient.GetLicenseManagerShutdown(),
        logger:        logger,
        telemetry:     *telemetry,
    }
}

func (s *Server) Run(l *libCommons.Launcher) error {
    // License manager integrated into graceful shutdown
    libCommonsServer.NewServerManager(s.license, &s.telemetry, s.logger).
        WithHTTPServer(s.app, s.serverAddress).
        StartWithGracefulShutdown()

    return nil
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

### What NOT to Do

```go
// FORBIDDEN: Hardcoded license keys
licenseClient := libLicense.NewLicenseClient(appName, "hardcoded-key", orgIDs, &logger)  // NEVER

// FORBIDDEN: Skipping license middleware on licensed routes
f.Post("/v1/paid-feature", handler.Create)  // Missing lc.Middleware()

// FORBIDDEN: Not integrating shutdown manager
libCommonsServer.NewServerManager(nil, &s.telemetry, s.logger)  // Missing license shutdown

// CORRECT: Always use environment variables and integrate shutdown
licenseClient := libLicense.NewLicenseClient(appName, cfg.LicenseKey, cfg.OrganizationIDs, &logger)
libCommonsServer.NewServerManager(s.license, &s.telemetry, s.logger)
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
| Midaz | MDZ | MDZ-0001 |
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
// ALWAYS check errors
if err != nil {
    return fmt.Errorf("context: %w", err)
}

// ALWAYS wrap errors with context
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
// NEVER use panic for business logic
panic(err) // FORBIDDEN

// NEVER ignore errors
result, _ := doSomething() // FORBIDDEN

// NEVER return nil error without checking
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
| Function does validation AND processing | Separate validation function |

---

## Pagination Patterns

Lerian Studio supports multiple pagination patterns. This section provides **implementation details** for each pattern.

> **Note**: The pagination strategy should be decided during the **TRD (Technical Requirements Document)** phase, not during implementation. See the `pre-dev-trd-creation` skill for the decision workflow. If no TRD exists, consult with the user before implementing.

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
└── NO  → Use Page-Based Pagination

Does the user need to jump to arbitrary pages?
├── YES → Use Page-Based Pagination
└── NO  → Cursor-Based is fine

Does the UI need to show total count (e.g., "Page 1 of 10")?
├── YES → Use Page-Based with Total Count
└── NO  → Standard Page-Based is sufficient
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
    logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)

    ctx, span := tracer.Start(ctx, "handler.get_all_transactions")
    defer span.End()

    // Parse and validate query parameters
    headerParams, err := libHTTP.ValidateParameters(c.Queries())
    if err != nil {
        libOpentelemetry.HandleSpanBusinessErrorEvent(&span, "Invalid parameters", err)
        return libHTTP.WithError(c, err)
    }

    // Build pagination request (cursor-based)
    pagination := libPostgres.Pagination{
        Limit:     headerParams.Limit,
        SortOrder: headerParams.SortOrder,
        StartDate: headerParams.StartDate,
        EndDate:   headerParams.EndDate,
    }

    // Query with cursor pagination
    items, cursor, err := h.Query.GetAllTransactions(ctx, orgID, ledgerID, *headerParams)
    if err != nil {
        libOpentelemetry.HandleSpanBusinessErrorEvent(&span, "Query failed", err)
        return libHTTP.WithError(c, err)
    }

    // Set response with cursor
    pagination.SetItems(items)
    pagination.SetCursor(cursor.Next, cursor.Prev)

    return libHTTP.OK(c, pagination)
}
```

**Repository Implementation:**

```go
func (r *Repository) FindAll(ctx context.Context, filter libHTTP.Pagination) ([]Entity, libHTTP.CursorPagination, error) {
    logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)

    ctx, span := tracer.Start(ctx, "postgres.find_all")
    defer span.End()

    // Decode cursor if provided
    var decodedCursor libHTTP.Cursor
    isFirstPage := true

    if filter.Cursor != "" {
        isFirstPage = false
        decodedCursor, _ = libHTTP.DecodeCursor(filter.Cursor)
    }

    // Build query with cursor pagination
    query := squirrel.Select("*").From("table_name")
    query, orderUsed := libHTTP.ApplyCursorPagination(
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
    items = libHTTP.PaginateRecords(
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

    cursor, _ := libHTTP.CalculateCursor(
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
    logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)

    ctx, span := tracer.Start(ctx, "handler.get_all_organizations")
    defer span.End()

    headerParams, err := libHTTP.ValidateParameters(c.Queries())
    if err != nil {
        return libHTTP.WithError(c, err)
    }

    // Build page-based pagination
    pagination := libPostgres.Pagination{
        Limit:     headerParams.Limit,
        Page:      headerParams.Page,
        SortOrder: headerParams.SortOrder,
        StartDate: headerParams.StartDate,
        EndDate:   headerParams.EndDate,
    }

    // Query with offset pagination (uses ToOffsetPagination())
    items, err := h.Query.GetAllOrganizations(ctx, headerParams.ToOffsetPagination())
    if err != nil {
        return libHTTP.WithError(c, err)
    }

    pagination.SetItems(items)

    return libHTTP.OK(c, pagination)
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

### Shared Utilities from lib-commons

| Utility | Package | Purpose |
|---------|---------|---------|
| `Pagination` struct | `lib-commons/commons/postgres` | Unified response structure |
| `Cursor` struct | `lib-commons/commons/net/http` | Cursor encoding |
| `DecodeCursor` | `lib-commons/commons/net/http` | Parse cursor from request |
| `ApplyCursorPagination` | `lib-commons/commons/net/http` | Add cursor to SQL query |
| `PaginateRecords` | `lib-commons/commons/net/http` | Trim results, handle direction |
| `CalculateCursor` | `lib-commons/commons/net/http` | Generate next/prev cursors |

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MAX_PAGINATION_LIMIT` | 100 | Maximum allowed limit per request |
| `MAX_PAGINATION_MONTH_DATE_RANGE` | 1 | Default date range in months |

---

## Testing Patterns

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

### Mock Generation

```go
// Using mockery
//go:generate mockery --name=OrderRepository --output=mocks --outpkg=mocks

// Using GoMock
//go:generate mockgen -source=repository.go -destination=mocks/mock_repository.go -package=mocks
```

---

## Logging Standards

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

**If ANY of these patterns are found in production code → REVIEW FAILS. NO EXCEPTIONS.**

### Pre-Commit Check (MANDATORY)

Add to `.golangci.yml` or run manually before commit:

```bash
# MUST pass with zero matches before commit
grep -rn "fmt.Println\|fmt.Printf\|log.Println\|log.Printf\|log.Fatal\|println(" --include="*.go" ./internal ./cmd
# Expected output: (nothing - no matches)
```

### Using lib-commons Logger (REQUIRED Pattern)

```go
// CORRECT: Recover logger from context
logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)

// CORRECT: Log with context correlation
logger.Infof("Processing entity: %s", entityID)
logger.Warnf("Rate limit approaching: %d/%d", current, limit)
logger.Errorf("Failed to save entity: %v", err)
```

### Migration Examples

```go
// ❌ FORBIDDEN: fmt.Println
fmt.Println("Starting server...")

// ✅ REQUIRED: lib-commons logger
logger.Info("Starting server")

// ❌ FORBIDDEN: fmt.Printf  
fmt.Printf("Processing user: %s\n", userID)

// ✅ REQUIRED: lib-commons logger
logger.Infof("Processing user: %s", userID)

// ❌ FORBIDDEN: log.Printf
log.Printf("[ERROR] Failed to connect: %v", err)

// ✅ REQUIRED: lib-commons logger with span error
logger.Errorf("Failed to connect: %v", err)
libOpentelemetry.HandleSpanError(&span, "Connection failed", err)

// ❌ FORBIDDEN: log.Fatal (breaks graceful shutdown)
log.Fatal("Cannot start without config")

// ✅ REQUIRED: panic in bootstrap ONLY (caught by recovery middleware)
panic(fmt.Errorf("cannot start without config: %w", err))
```

### What NOT to Log (Sensitive Data)

```go
// FORBIDDEN - sensitive data
logger.Info("user login", "password", password)  // NEVER
logger.Info("payment", "card_number", card)      // NEVER
logger.Info("auth", "token", token)              // NEVER
logger.Info("user", "cpf", cpf)                  // NEVER (PII)
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
    fiber.server.go
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

The directory structure follows the **Midaz pattern** - a simplified hexagonal architecture without explicit DDD folders.

```text
/cmd
  /app                   # Main application entry
    main.go
/internal
  /bootstrap             # Initialization (config, servers)
    config.go
    fiber.server.go
    grpc.server.go       # (if service uses gRPC)
    rabbitmq.server.go   # (if service uses RabbitMQ)
    service.go
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
    OrganizationID uuid.UUID   `json:"organization_id"`
    LedgerID       uuid.UUID   `json:"ledger_id"`
    AuditID        uuid.UUID   `json:"audit_id"`
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
    *Server              // HTTP server (Fiber)
    *MultiQueueConsumer  // RabbitMQ consumer
    Logger
}

func (s *Service) Run() {
    launcher := libCommons.NewLauncher(
        libCommons.WithLogger(s.Logger),
        libCommons.RunApp("HTTP Server", s.Server),
        libCommons.RunApp("RabbitMQ Consumer", s.MultiQueueConsumer),
    )
    launcher.Run() // All components run concurrently
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

## Standards Compliance Output Format

When producing a Standards Compliance report (used by dev-refactor workflow), follow these output formats:

### If ALL Categories Are Compliant

```markdown
## Standards Compliance

### Lerian/Ring Standards Comparison

#### Bootstrap & Initialization
| Category | Current Pattern | Expected Pattern | Status | Evidence |
|----------|----------------|------------------|--------|----------|
| Config Struct | `Config` struct with `env` tags | Single struct with `env` tags | ✅ Compliant | `internal/bootstrap/config.go:15` |
| Config Loading | `libCommons.SetConfigFromEnvVars(&cfg)` | `libCommons.SetConfigFromEnvVars(&cfg)` | ✅ Compliant | `internal/bootstrap/config.go:42` |
| Logger Init | `libZap.InitializeLogger()` | `libZap.InitializeLogger()` (bootstrap only) | ✅ Compliant | `internal/bootstrap/config.go:45` |
| Telemetry Init | `libOpentelemetry.InitializeTelemetry()` | `libOpentelemetry.InitializeTelemetry()` | ✅ Compliant | `internal/bootstrap/config.go:48` |
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

### If ANY Category Is Non-Compliant

```markdown
## Standards Compliance

### Lerian/Ring Standards Comparison

#### Bootstrap & Initialization
| Category | Current Pattern | Expected Pattern | Status | File/Location |
|----------|----------------|------------------|--------|---------------|
| Config Struct | Scattered `os.Getenv()` calls | Single struct with `env` tags | ⚠️ Non-Compliant | `cmd/api/main.go` |
| Config Loading | Manual env parsing | `libCommons.SetConfigFromEnvVars(&cfg)` | ⚠️ Non-Compliant | `cmd/api/main.go:25` |
| Logger Init | `libZap.InitializeLogger()` | `libZap.InitializeLogger()` (bootstrap only) | ✅ Compliant | `cmd/api/main.go:30` |
| ... | ... | ... | ... | ... |

#### Context & Tracking
| Category | Current Pattern | Expected Pattern | Status | File/Location |
|----------|----------------|------------------|--------|---------------|
| ... | ... | ... | ... | ... |

### Verdict: ⚠️ NON-COMPLIANT (X of Y categories)

### Required Changes for Compliance

1. **Config Struct Migration**
   - Replace: Direct `os.Getenv()` calls scattered across files
   - With: Single `Config` struct with `env` tags in `/internal/bootstrap/config.go`
   - Import: `libCommons "github.com/LerianStudio/lib-commons/v2/commons"`
   - Usage: `libCommons.SetConfigFromEnvVars(&cfg)`
   - Files affected: `cmd/api/main.go`, `internal/service/user.go`

2. **Logger Migration**
   - Replace: Custom logger or `log.Println()`
   - With: lib-commons structured logger
   - Bootstrap import: `libZap "github.com/LerianStudio/lib-commons/v2/commons/zap"` (initialization)
   - Application import: `libLog "github.com/LerianStudio/lib-commons/v2/commons/log"` (interface for logging calls)
   - Bootstrap usage: `logger := libZap.InitializeLogger()` (returns `libLog.Logger` interface)
   - Application usage: Use `libLog.Logger` interface for all logging calls
   - Files affected: [list files]

3. **Telemetry Migration**
   - Replace: No tracing or custom tracing
   - With: OpenTelemetry integration
   - Import: `libOpentelemetry "github.com/LerianStudio/lib-commons/v2/commons/opentelemetry"`
   - Usage: `telemetry := libOpentelemetry.InitializeTelemetry(&libOpentelemetry.TelemetryConfig{...})`
   - Files affected: [list files]

4. **[Next Category] Migration**
   - Replace: ...
   - With: ...
   - Import: ...
   - Usage: ...
```

**CRITICAL:** The comparison table is NOT optional. It serves as:
1. **Evidence** that each category was actually checked
2. **Documentation** for the codebase's compliance status
3. **Audit trail** for future refactors

---

## Checklist

Before submitting Go code, verify:

- [ ] Using lib-commons v2 for infrastructure
- [ ] Configuration loaded via `SetConfigFromEnvVars`
- [ ] Telemetry initialized and middleware configured
- [ ] Logger/tracer recovered from context via `NewTrackingFromContext`
- [ ] **No direct imports of `go.opentelemetry.io/otel/*` packages** (use lib-commons wrappers)
- [ ] **No direct Fiber responses** (`c.JSON()`, `c.Send()`) - use `libHTTP.OK()`, `libHTTP.WithError()`
- [ ] All errors are checked and wrapped with context
- [ ] Error codes use service prefix (e.g., PLT-0001)
- [ ] No `panic()` outside of `main.go` or `InitServers`
- [ ] Tests use table-driven pattern
- [ ] Database models have ToEntity/FromEntity methods
- [ ] Interfaces defined where they're used
- [ ] No global mutable state
- [ ] Context propagated through all calls
- [ ] Sensitive data not logged
- [ ] golangci-lint passes
- [ ] Pagination strategy defined in TRD (or confirmed with user if no TRD)
