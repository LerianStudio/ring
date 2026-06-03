# Code Example Standards Pattern

This file defines MANDATORY rules for code examples in pre-dev documents (PRDs, TRDs, task breakdowns, subtasks).

---

## ⛔ HARD GATE: Lerian Libraries First (Go Projects)

MUST use the canonical Lerian libraries instead of creating custom utilities when generating Go code examples. Four libraries cover the surface:

- **lib-commons** (v5) — HTTP, DB drivers, idempotency, security/TLS, lifecycle, outbox, tenant management, RabbitMQ command queues
- **lib-observability** (v1.0.0) — logging, metrics, tracing, OTel constants, assertions, panic recovery (see [[using-lib-observability]], [[using-tracing]])
- **lib-systemplane** — hot-reloadable runtime config (Postgres LISTEN/NOTIFY + MongoDB change streams) (see [[using-lib-systemplane]])
- **lib-streaming** — past-tense, durable, tenant-scoped business event emission (CloudEvents, outbox-backed) (see [[using-lib-streaming]], [[using-outbox]])

> **Deprecated shims:** `lib-commons/v5/commons/{opentelemetry,zap,log,metrics,assert,runtime,systemplane}` still compile but now route through their canonical homes. New code MUST import the canonical library directly.

### What These Libraries Already Provide (do not recreate)

| Category | Canonical Package | What It Provides |
|----------|-------------------|------------------|
| **Logging interface** | `libLog "github.com/LerianStudio/lib-observability/log"` | Logger interface for all logging |
| **Logger init** | `libZap "github.com/LerianStudio/lib-observability/zap"` | Logger initialization (bootstrap only) |
| **Tracing** | `libTracing "github.com/LerianStudio/lib-observability/tracing"` | Tracer + meter + propagator setup, span helpers |
| **Metrics** | `libMetrics "github.com/LerianStudio/lib-observability/metrics"` | Thread-safe OTel metric factory with fluent builders |
| **OTel constants** | `libConstants "github.com/LerianStudio/lib-observability/constants"` | Canonical attribute/metric/event name strings + label sanitizer |
| **Assertions** | `libAssert "github.com/LerianStudio/lib-observability/assert"` | Runtime invariant checks with panic-or-error policy |
| **Panic recovery** | `libRuntime "github.com/LerianStudio/lib-observability/runtime"` | `SafeGo`, `RecoverWithPolicy`, panic metrics |
| **Runtime config** | `libSystemplane "github.com/LerianStudio/lib-systemplane"` | Hot-reloadable config via Postgres LISTEN/NOTIFY or Mongo change streams |
| **Event emission** | `libStreaming "github.com/LerianStudio/lib-streaming"` | Past-tense business events to per-tenant SaaS subscribers (CloudEvents, outbox-backed) |
| **Config loader** | `libCommons "github.com/LerianStudio/lib-commons/v5/commons"` | `SetConfigFromEnvVars()` |
| **HTTP** | `libHTTP "github.com/LerianStudio/lib-commons/v5/commons/net/http"` | Router, middleware, responses |
| **PostgreSQL** | `libPostgres "github.com/LerianStudio/lib-commons/v5/commons/postgres"` | Connection, pagination |
| **MongoDB** | `libMongo "github.com/LerianStudio/lib-commons/v5/commons/mongo"` | Connection management |
| **Redis** | `libRedis "github.com/LerianStudio/lib-commons/v5/commons/redis"` | Connection management |
| **Server lifecycle** | `libServer "github.com/LerianStudio/lib-commons/v5/commons/server"` | Lifecycle, graceful shutdown |
| **RabbitMQ commands** | `libRabbit "github.com/LerianStudio/lib-commons/v5/commons/rabbitmq"` | Command-queue producers/consumers (NOT business events — those use lib-streaming) |
| **Outbox** | `libOutbox "github.com/LerianStudio/lib-commons/v5/commons/outbox"` | Transactional outbox repository (consumed by lib-streaming) |
| **Context** | `libCommons.TrackingContext` | Request context propagation |

### Verification Before Writing Code Examples

```text
Before writing any Go code example in subtasks:

[ ] 1. Does this example need logging?           → Use libLog.Logger (lib-observability/log)
[ ] 2. Does this example need config loading?    → Use libCommons.SetConfigFromEnvVars()
[ ] 3. Does this example need hot-reloadable config? → Use libSystemplane (lib-systemplane)
[ ] 4. Does this example need HTTP handling?     → Use libHTTP helpers
[ ] 5. Does this example need DB connection?     → Use libPostgres/libMongo/libRedis
[ ] 6. Does this example need tracing?           → Use libTracing (lib-observability/tracing)
[ ] 7. Does this example need metrics?           → Use libMetrics (lib-observability/metrics)
[ ] 8. Does this example need server setup?      → Use libServer
[ ] 9. Does this example emit business events?   → Use libStreaming (lib-streaming) — past-tense, tenant-scoped, outbox-backed
[ ] 10. Does this example dispatch commands?     → Use libRabbit (lib-commons/v5/commons/rabbitmq) — command queues only

If yes to any → Use the canonical library. Do not create custom helpers.
```

---

## ⛔ FORBIDDEN Patterns in Code Examples

### ❌ NEVER Create Custom Loggers

```go
// ❌ FORBIDDEN in code examples
package utils

import "go.uber.org/zap"

func NewLogger() *zap.Logger {
    logger, _ := zap.NewProduction()
    return logger
}

// ❌ FORBIDDEN: Custom log wrapper
func LogInfo(msg string, fields ...zap.Field) {
    logger.Info(msg, fields...)
}
```

**✅ CORRECT: Use lib-observability**

```go
import (
    libZap "github.com/LerianStudio/lib-observability/zap"
    libLog "github.com/LerianStudio/lib-observability/log"
)

// Bootstrap only
logger := libZap.NewLogger()

// In services/handlers - use the interface
func NewService(logger libLog.Logger) *Service {
    return &Service{logger: logger}
}
```

### ❌ NEVER Create Custom Config Loaders

```go
// ❌ FORBIDDEN in code examples
package config

import "os"

func LoadConfig() *Config {
    return &Config{
        PrimaryHost: os.Getenv("POSTGRES_HOST"),
        PrimaryPort: os.Getenv("POSTGRES_PORT"),
    }
}
```

**✅ CORRECT: Use lib-commons**

```go
import libCommons "github.com/LerianStudio/lib-commons/v5/commons"

type Config struct {
    PrimaryHost string `env:"POSTGRES_HOST"`
    PrimaryPort string `env:"POSTGRES_PORT"`
}

cfg := &Config{}
if err := libCommons.SetConfigFromEnvVars(cfg); err != nil {
    return nil, fmt.Errorf("failed to load config: %w", err)
}
```

### ❌ NEVER Create Custom HTTP Helpers

```go
// ❌ FORBIDDEN in code examples
package utils

func JSONResponse(c *fiber.Ctx, status int, data interface{}) error {
    return c.Status(status).JSON(data)
}

func ErrorResponse(c *fiber.Ctx, err error) error {
    return c.Status(500).JSON(map[string]string{"error": err.Error()})
}
```

**✅ CORRECT: Use lib-commons HTTP utilities**

```go
import libHTTP "github.com/LerianStudio/lib-commons/v5/commons/net/http"

// Use lib-commons response helpers and middleware
```

### ❌ NEVER Create Custom Telemetry Wrappers

```go
// ❌ FORBIDDEN in code examples
package telemetry

import (
    "context"

    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/trace"
)

func StartSpan(ctx context.Context, name string) (context.Context, trace.Span) {
    tracer := otel.GetTracerProvider().Tracer("my-service")
    return tracer.Start(ctx, name)
}
```

**✅ CORRECT: Use lib-observability**

```go
import (
    libTracing "github.com/LerianStudio/lib-observability/tracing"
    libMetrics "github.com/LerianStudio/lib-observability/metrics"
)

// Initialize in bootstrap
tel, err := libTracing.NewTelemetry(cfg) // tracer + meter + propagator
if err != nil {
    return nil, fmt.Errorf("init telemetry: %w", err)
}

// Use standard otel APIs with lib-observability provider
factory := libMetrics.NewFactory(tel.Meter())
```

---

## When Custom Code IS Allowed in Examples

| Scenario | Allowed? | Condition |
|----------|----------|-----------|
| Infrastructure utilities (logging, config, HTTP, DB) | ❌ NO | Use lib-commons for non-observability infrastructure and lib-observability for logging/telemetry |
| Domain-specific business logic | ✅ YES | Business rules are project-specific |
| Service layer code | ✅ YES | Uses lib-commons/lib-observability for infrastructure |
| Repository implementations | ✅ YES | Uses libPostgres/libMongo for connections |
| API handlers | ✅ YES | Uses libHTTP for middleware |
| Validation logic | ✅ YES | Domain validation is project-specific |
| Data transformation (ToEntity/FromEntity) | ✅ YES | Domain mapping is project-specific |

---

## Anti-Rationalization Table

| Rationalization | Why it's wrong | Required Action |
|-----------------|----------------|-----------------|
| "Custom helper is simpler for this example" | Examples teach patterns. Teach the right pattern (lib-commons/lib-observability). | **Use standard modules** in example |
| "lib-commons/lib-observability import is too verbose" | Verbosity is intentional for clarity. Don't hide dependencies. | **Show full imports** |
| "I don't know if lib-commons has this" | Check before writing. Observability belongs in lib-observability. | **Verify the standard module first** |
| "The example is just pseudocode" | Pseudocode with custom helpers trains wrong patterns. | **Use real lib-commons calls** |
| "Engineers will replace with lib-commons later" | Later = never. Show correct pattern from start. | **Use standard modules now** |
| "This is just a quick example" | Quick examples become production code. Do it right. | **Use standard modules** |
| "Custom utils are easier to understand" | Understanding wrong patterns is worse than not understanding. | **Use standard modules** |

---

## Integration with Subtask Creation

When creating subtasks with code examples (Gate 8), apply these rules:

1. **Step 1 (Write failing test)**: Tests can use custom test helpers
2. **Step 3 (Write implementation)**: Implementation MUST use lib-commons for non-observability infrastructure and lib-observability for logging/telemetry
3. **Imports**: Always show complete lib-commons/lib-observability imports with `lib` prefix aliases

**Example subtask code block:**

```go
// Step 3: Implement the service

// internal/service/user_service.go
package service

import (
    "context"

    libLog "github.com/LerianStudio/lib-observability/log"

    "github.com/your-org/your-service/internal/domain"
    "github.com/your-org/your-service/internal/repository"
)

type UserService struct {
    repo   repository.UserRepository
    logger libLog.Logger  // ✅ lib-observability logger interface
}

func NewUserService(repo repository.UserRepository, logger libLog.Logger) *UserService {
    return &UserService{
        repo:   repo,
        logger: logger,
    }
}

func (s *UserService) CreateUser(ctx context.Context, input domain.CreateUserInput) (*domain.User, error) {
    s.logger.Info("Creating user", "email", input.Email)  // ✅ Using lib-observability logger
    // ... implementation
}
```

---

## Checklist for Code Example Review

Before finalizing any document with Go code examples:

```text
[ ] 1. No custom logger creation (use libLog/libZap from lib-observability)
[ ] 2. No custom config loader (use libCommons.SetConfigFromEnvVars)
[ ] 3. No custom HTTP helpers (use libHTTP)
[ ] 4. No custom tracing/metrics wrapper (use libTracing/libMetrics from lib-observability)
[ ] 5. No custom DB connection helpers (use libPostgres/libMongo/libRedis)
[ ] 6. No custom server lifecycle (use libServer)
[ ] 7. No custom event-emission helpers (use libStreaming from lib-streaming for past-tense business events)
[ ] 8. No custom hot-reload config (use libSystemplane from lib-systemplane)
[ ] 9. No deprecated shim imports (lib-commons/v5/commons/{opentelemetry,zap,log,metrics,assert,runtime,systemplane})
[ ] 10. All imports show full canonical paths with lib prefix aliases

If any checkbox is unchecked → Fix code example before publishing.
```
